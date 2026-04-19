import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../controllers/auth_controller.dart';
import '../models/auth_user.dart';
import '../repository/weight_log_repository.dart';
import '../services/auth_session_storage.dart';

class AddWeightLogPage extends StatefulWidget {
  const AddWeightLogPage({
    super.key,
    required this.authController,
    this.initialWeight,
  });

  final AuthController authController;
  final double? initialWeight;

  @override
  State<AddWeightLogPage> createState() => _AddWeightLogPageState();
}

class _AddWeightLogPageState extends State<AddWeightLogPage> {
  final _formKey = GlobalKey<FormState>();
  final _weightController = TextEditingController();
  final _sessionStorage = AuthSessionStorage();

  late final WeightLogRepository _weightLogRepository;

  DateTime _selectedDate = DateTime.now();
  int? _resolvedUserId;
  LoginUser? _sessionUser;
  bool _isSaving = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _weightLogRepository = WeightLogRepository(
      supabase: Supabase.instance.client,
    );

    final initial =
        widget.initialWeight ??
        _toDouble(widget.authController.currentUser?.currentWeight) ??
        0;
    if (initial > 0) {
      _weightController.text = initial.toStringAsFixed(1);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadSessionContext();
      }
    });
  }

  @override
  void dispose() {
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _loadSessionContext() async {
    final sessionUser =
        widget.authController.currentUser ?? await _sessionStorage.read();
    final userId = _toInt(sessionUser?.id);

    if (!mounted) {
      return;
    }

    setState(() {
      _sessionUser = sessionUser;
      _resolvedUserId = userId;
      if (userId == null) {
        _errorText = 'No active user session found.';
      }
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveWeightLog() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final userId = _resolvedUserId;
    if (userId == null) {
      setState(() {
        _errorText = 'No active user session found.';
      });
      return;
    }

    final weight = double.parse(_weightController.text.trim());

    setState(() {
      _isSaving = true;
      _errorText = null;
    });

    try {
      final inserted = await _weightLogRepository.insertLog(
        userId: userId,
        weight: weight,
        date: _selectedDate,
      );

      // Keep local session state aligned with the synced user current_weight.
      final activeUser = widget.authController.currentUser ?? _sessionUser;
      if (activeUser != null) {
        final updatedUser = activeUser.copyWith(currentWeight: inserted.weight);
        await widget.authController.updateSessionUser(updatedUser);
        _sessionUser = updatedUser;
      }

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Weight log saved.')));
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorText = 'Failed to save weight log.';
        _isSaving = false;
      });
    }
  }

  double? get _enteredWeight {
    final parsed = double.tryParse(_weightController.text.trim());
    if (parsed == null || parsed <= 0) {
      return null;
    }
    return parsed;
  }

  double? get _bmi {
    final weight = _enteredWeight;
    final heightRaw = _toDouble(_sessionUser?.height);
    if (weight == null || heightRaw == null || heightRaw <= 0) {
      return null;
    }

    final heightMeters = heightRaw > 3 ? heightRaw / 100.0 : heightRaw;
    if (heightMeters <= 0) {
      return null;
    }

    return weight / (heightMeters * heightMeters);
  }

  String get _goalRecommendation {
    final target = _toDouble(_sessionUser?.targetWeight);
    final current = _enteredWeight;

    if (target == null || current == null) {
      return 'Set your weight and target to see recommendation.';
    }

    final diff = current - target;
    if (diff.abs() <= 0.3) {
      return 'Great! You are near your target weight.';
    }
    if (diff > 0) {
      return 'You are above target by ${diff.toStringAsFixed(1)} kg. Focus on fat loss.';
    }
    return 'You are below target by ${diff.abs().toStringAsFixed(1)} kg. Focus on healthy gain.';
  }

  int? _toInt(dynamic value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(value?.toString() ?? '');
  }

  double? _toDouble(dynamic value) {
    if (value is double) {
      return value;
    }
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value?.toString() ?? '');
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$day/$month/$year';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bmi = _bmi;

    return Scaffold(
      appBar: AppBar(title: const Text('Add Weight Log')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Track your weight over time',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _weightController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Weight (kg)',
                  border: OutlineInputBorder(),
                ),
                onChanged: (_) => setState(() {}),
                validator: (value) {
                  final parsed = double.tryParse((value ?? '').trim());
                  if (parsed == null || parsed <= 0) {
                    return 'Enter a valid weight in kg.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(8),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Date',
                    border: OutlineInputBorder(),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 18),
                      const SizedBox(width: 8),
                      Text(_formatDate(_selectedDate)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'BMI',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        bmi == null ? '--' : bmi.toStringAsFixed(1),
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _goalRecommendation,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
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
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveWeightLog,
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save Weight Log'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
