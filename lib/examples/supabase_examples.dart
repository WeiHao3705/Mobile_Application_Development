import 'package:flutter/material.dart';
import 'package:mobile_application_development/services/supabase_service.dart';

/// Example: Advanced Supabase Integration
/// This file shows various ways to use the SupabaseService
///
/// You can use this as a reference for implementing more complex
/// database operations in your Flutter app.

class SupabaseExamplePage extends StatefulWidget {
  const SupabaseExamplePage({super.key});

  @override
  State<SupabaseExamplePage> createState() => _SupabaseExamplePageState();
}

class _SupabaseExamplePageState extends State<SupabaseExamplePage> {
  final _supabaseService = SupabaseService();
  List<Map<String, dynamic>> _counters = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCounters();
  }

  Future<void> _loadCounters() async {
    setState(() => _isLoading = true);
    try {
      final counters = await _supabaseService.getAllCounters();
      setState(() => _counters = counters);
    } catch (e) {
      _showError('Failed to load counters: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addCounter(int value) async {
    try {
      await _supabaseService.saveCounter(value);
      _loadCounters(); // Refresh the list
      _showSuccess('Counter saved!');
    } catch (e) {
      _showError('Failed to save counter: $e');
    }
  }

  Future<void> _deleteCounter(int id) async {
    try {
      await _supabaseService.deleteCounter(id);
      _loadCounters(); // Refresh the list
      _showSuccess('Counter deleted!');
    } catch (e) {
      _showError('Failed to delete counter: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Supabase Counter History'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _counters.isEmpty
              ? Center(
                  child: Text(
                    'No counters saved yet',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                )
              : ListView.builder(
                  itemCount: _counters.length,
                  itemBuilder: (context, index) {
                    final counter = _counters[index];
                    return ListTile(
                      title: Text('Value: ${counter['value']}'),
                      subtitle: Text('ID: ${counter['id']}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _deleteCounter(counter['id']),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addCounter(42),
        tooltip: 'Add Counter',
        child: const Icon(Icons.add),
      ),
    );
  }
}

/// ============================================
/// Usage Examples
/// ============================================

/// Example 1: Simple save and fetch
void example1_SimpleOperations() async {
  final service = SupabaseService();

  // Save a counter
  await service.saveCounter(10);

  // Fetch all counters
  final counters = await service.getAllCounters();
  print('Total counters: ${counters.length}');

  // Get the latest counter
  final latest = await service.getLatestCounter();
  print('Latest counter value: $latest');
}

/// Example 2: Update and delete operations
void example2_UpdateAndDelete() async {
  final service = SupabaseService();

  // Update a counter (assuming ID = 1)
  await service.updateCounter(1, 100);

  // Delete a counter
  await service.deleteCounter(1);
}

/// Example 3: Error handling
void example3_ErrorHandling() async {
  final service = SupabaseService();

  try {
    await service.saveCounter(50);
  } on Exception catch (e) {
    print('Error occurred: $e');
    // Handle error appropriately
  }
}

/// Example 4: Using with Flutter state management
class CounterWithProvider extends StatelessWidget {
  const CounterWithProvider({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<int?>(
      future: SupabaseService().getLatestCounter(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        }

        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }

        final value = snapshot.data ?? 0;
        return Text('Latest Counter: $value');
      },
    );
  }
}

