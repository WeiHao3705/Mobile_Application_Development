import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../controllers/auth_controller.dart';
import '../models/water_intake.dart';
import '../repository/water_intake_repository.dart';
import '../services/auth_session_storage.dart';
import '../utils/time_formatters.dart';
import 'water_intake_history_page.dart';

class AddWaterIntakePage extends StatefulWidget {
  const AddWaterIntakePage({super.key, required this.authController});

  final AuthController authController;

  @override
  State<AddWaterIntakePage> createState() => _AddWaterIntakePageState();
}

class _AddWaterIntakePageState extends State<AddWaterIntakePage> {
  static const double _defaultTargetAmount = 2000;

  final TextEditingController _amountController = TextEditingController();
  final AuthSessionStorage _sessionStorage = AuthSessionStorage();

  late final WaterIntakeRepository _waterIntakeRepository;

  WaterIntake? _waterIntake;
  int? _resolvedUserId;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _didChange = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _waterIntakeRepository = WaterIntakeRepository(
      supabase: Supabase.instance.client,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadWaterIntake();
      }
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _loadWaterIntake() async {
    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    try {
      final userId = await _resolveUserId();
      if (userId == null) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _errorText = 'No active user session found.';
        });
        return;
      }

      final intake = await _waterIntakeRepository.getOrCreateByUserIdAndDate(
        userId: userId,
        day: DateTime.now(),
        defaultTargetAmount: _defaultTargetAmount,
      );

      if (!mounted) return;
      setState(() {
        _resolvedUserId = userId;
        _waterIntake = intake;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorText = 'Failed to load water intake.';
      });
      debugPrint('Water intake load error: $error');
    }
  }

  Future<int?> _resolveUserId() async {
    final id = widget.authController.currentUser?.id;
    if (id is int) {
      return id;
    }

    final parsedFromController = int.tryParse(id?.toString() ?? '');
    if (parsedFromController != null) {
      return parsedFromController;
    }

    final sessionUser = await _sessionStorage.read();
    final sessionId = sessionUser?.id;
    if (sessionId is int) {
      return sessionId;
    }

    return int.tryParse(sessionId?.toString() ?? '');
  }

  Future<void> _quickAdd(double amount) async {
    if (_waterIntake == null || _isSaving) {
      return;
    }

    await _applyAddAmount(amount);
  }

  Future<void> _submitCustomAmount() async {
    final parsed = double.tryParse(_amountController.text.trim());
    if (parsed == null || parsed <= 0) {
      setState(() {
        _errorText = 'Enter a valid water amount in ml.';
      });
      return;
    }

    await _applyAddAmount(parsed);
  }

  Future<void> _applyAddAmount(double amount) async {
    if (_waterIntake == null) {
      return;
    }

    setState(() {
      _isSaving = true;
      _errorText = null;
    });

    try {
      final now = DateTime.now();
      final updated = await _waterIntakeRepository.save(
        _waterIntake!.copyWith(
          currentAmount: _waterIntake!.currentAmount + amount,
          lastUpdated: now,
          date: now,
        ),
      );

      if (!mounted) return;
      setState(() {
        _waterIntake = updated;
        _isSaving = false;
        _didChange = true;
      });
      _amountController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Added ${amount.toStringAsFixed(0)} ml')),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _errorText = 'Failed to update water intake.';
      });
      debugPrint('Water intake save error: $error');
    }
  }

  void _closePage() {
    Navigator.of(context).pop(_didChange);
  }

  Future<void> _openHistoryPage() async {
    final userId = _resolvedUserId;
    if (userId == null) {
      setState(() {
        _errorText = 'Unable to open history without a user session.';
      });
      return;
    }

    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => WaterIntakeHistoryPage(userId: userId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final intake = _waterIntake;
    final lastUpdatedRelative = formatRelativeTime(intake?.lastUpdated);
    final lastUpdatedExact = formatDateTimeCompact(intake?.lastUpdated);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _closePage();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Water Intake Tracker'),
          actions: [
            IconButton(
              tooltip: 'History',
              onPressed: _isLoading ? null : _openHistoryPage,
              icon: const Icon(Icons.history),
            ),
          ],
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _closePage,
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Card(
                        color: theme.colorScheme.surface,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Hydration Progress',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 10),
                              LinearProgressIndicator(
                                value: (intake?.progressRatio ?? 0).clamp(
                                  0.0,
                                  1.0,
                                ),
                                minHeight: 10,
                                color: Colors.blue,
                                backgroundColor: Colors.white.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${(intake?.currentAmount ?? 0).toStringAsFixed(0)} ml / ${(intake?.targetAmount ?? 0).toStringAsFixed(0)} ml (${(intake?.progressPercent ?? 0).toStringAsFixed(1)}%)',
                                style: theme.textTheme.bodyMedium,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Last updated: $lastUpdatedRelative',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              Text(
                                lastUpdatedExact,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant
                                      .withValues(alpha: 0.75),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _amountController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Water intake (ml)',
                          hintText: 'e.g. 250',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _submitCustomAmount,
                          child: _isSaving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Add Intake'),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          OutlinedButton(
                            onPressed: _isSaving ? null : () => _quickAdd(250),
                            child: const Text('+250 ml'),
                          ),
                          OutlinedButton(
                            onPressed: _isSaving ? null : () => _quickAdd(500),
                            child: const Text('+500 ml'),
                          ),
                          OutlinedButton(
                            onPressed: _isSaving ? null : () => _quickAdd(750),
                            child: const Text('+750 ml'),
                          ),
                        ],
                      ),
                      if (_errorText != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          _errorText!,
                          style: TextStyle(
                            color: theme.colorScheme.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}

