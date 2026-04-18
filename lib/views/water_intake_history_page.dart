import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/water_intake.dart';
import '../repository/water_intake_repository.dart';
import '../utils/time_formatters.dart';

class WaterIntakeHistoryPage extends StatefulWidget {
  const WaterIntakeHistoryPage({super.key, required this.userId});

  final int userId;

  @override
  State<WaterIntakeHistoryPage> createState() => _WaterIntakeHistoryPageState();
}

class _WaterIntakeHistoryPageState extends State<WaterIntakeHistoryPage> {
  late final WaterIntakeRepository _repository;
  bool _isLoading = true;
  String? _errorText;
  List<WaterIntake> _history = const [];

  @override
  void initState() {
    super.initState();
    _repository = WaterIntakeRepository(supabase: Supabase.instance.client);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadHistory();
      }
    });
  }

  Future<void> _loadHistory() async {
    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    try {
      final rows = await _repository.getHistoryByUserId(widget.userId);
      if (!mounted) return;
      setState(() {
        _history = rows;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorText = 'Failed to load history.';
      });
      debugPrint('Water history load error: $error');
    }
  }

  String _formatDay(DateTime? value) {
    if (value == null) {
      return '--';
    }
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    final year = value.year.toString();
    return '$day/$month/$year';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Water Intake History')),
      body: RefreshIndicator(
        onRefresh: _loadHistory,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorText != null
            ? ListView(
                children: [
                  const SizedBox(height: 24),
                  Center(
                    child: Text(
                      _errorText!,
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: TextButton.icon(
                      onPressed: _loadHistory,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ),
                ],
              )
            : _history.isEmpty
            ? ListView(
                children: const [
                  SizedBox(height: 24),
                  Center(child: Text('No water intake history yet.')),
                ],
              )
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _history.length,
                separatorBuilder: (_, index) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final item = _history[index];
                  final relative = formatRelativeTime(item.lastUpdated);
                  final exact = formatDateTimeCompact(item.lastUpdated);
                  final dayText = _formatDay(item.date ?? item.lastUpdated);

                  return Card(
                    child: ListTile(
                      leading: const Icon(Icons.water_drop, color: Colors.blue),
                      title: Text(
                        '$dayText • ${item.currentAmount.toStringAsFixed(0)} ml / ${item.targetAmount.toStringAsFixed(0)} ml',
                      ),
                      subtitle: Text('Updated $relative\n$exact'),
                      isThreeLine: true,
                    ),
                  );
                },
              ),
      ),
    );
  }
}
