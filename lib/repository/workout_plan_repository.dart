import 'dart:math';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/workout_plan.dart';

class WorkoutPlanRepository {
  WorkoutPlanRepository({required this.supabase});

  final SupabaseClient supabase;
  static const List<String> _detailExerciseIdColumnCandidates = <String>[
    'exercise_id',
    'exerciseId',
    'id_exercise',
  ];

  Future<void> createPlanWithDetails({
    required int userId,
    required String planName,
    String? description,
    required List<WorkoutPlanDetailInput> details,
  }) async {
    final header = await supabase
        .from('Exercise_Plan')
        .insert(<String, dynamic>{
          'user_id': userId,
          'plan_name': planName,
          'description': description,
          'created_at': DateTime.now().toUtc().toIso8601String(),
        })
        .select('plan_id')
        .single();

    final planId = (header['plan_id'] ?? '').toString();
    if (planId.isEmpty || details.isEmpty) {
      return;
    }

    await _insertDetailsWithFallbackColumns(
      planId: planId,
      userId: userId,
      details: details,
    );
  }

  Future<void> _insertDetailsWithFallbackColumns({
    required String planId,
    required int userId,
    required List<WorkoutPlanDetailInput> details,
  }) async {
    PostgrestException? lastError;

    for (final exerciseIdColumn in _detailExerciseIdColumnCandidates) {
      final payload = details
          .map(
            (detail) {
              final row = detail.toInsertMap(
                planId,
                userId: userId,
                exerciseIdColumn: exerciseIdColumn,
              );
              row['detail_id'] = _generateUuidV4();
              return row;
            },
          )
          .toList();

      try {
        await supabase.from('Exercise_Plan_Details').insert(payload);
        return;
      } on PostgrestException catch (error) {
        lastError = error;
        if (!_isMissingColumnError(error, exerciseIdColumn)) {
          rethrow;
        }
      }
    }

    throw PostgrestException(
      message:
          'Unable to insert Exercise_Plan_Details. Missing exercise id column. Tried: ${_detailExerciseIdColumnCandidates.join(', ')}. Last error: ${lastError?.message ?? 'unknown'}',
      code: lastError?.code,
      details: lastError?.details,
      hint: lastError?.hint,
    );
  }

  Future<List<WorkoutPlan>> getPlansForUser(int userId) async {
    final planResponse = await supabase
        .from('Exercise_Plan')
        .select('plan_id, user_id, plan_name, description, created_at')
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    final planRows = List<Map<String, dynamic>>.from(planResponse as List);
    if (planRows.isEmpty) {
      return const <WorkoutPlan>[];
    }

    final planIds = planRows
        .map((row) => (row['plan_id'] ?? '').toString())
        .where((id) => id.isNotEmpty)
        .toList();

    if (planIds.isEmpty) {
      return const <WorkoutPlan>[];
    }

    final detailResponse = await supabase
        .from('Exercise_Plan_Details')
        .select('*')
        .inFilter('plan_id', planIds)
        .order('order_index', ascending: true);

    final detailRows = List<Map<String, dynamic>>.from(detailResponse as List);

    final allExerciseIds = detailRows
        .map((row) => _readTextByKeys(row, _detailExerciseIdColumnCandidates))
        .where((id) => id.isNotEmpty)
        .toSet();

    final exerciseNameMap = await _loadExerciseNames(allExerciseIds);

    final detailsByPlan = <String, List<WorkoutPlanExercise>>{};
    for (final row in detailRows) {
      final planId = (row['plan_id'] ?? '').toString();
      final exerciseId = _readTextByKeys(row, _detailExerciseIdColumnCandidates);
      if (planId.isEmpty || exerciseId.isEmpty) {
        continue;
      }
      final orderIndex = _toInt(row['order_index']);
      final exerciseName = exerciseNameMap[exerciseId] ?? exerciseId;

      detailsByPlan.putIfAbsent(planId, () => <WorkoutPlanExercise>[]).add(
            WorkoutPlanExercise(
              exerciseId: exerciseId,
              exerciseName: exerciseName,
              orderIndex: orderIndex,
            ),
          );
    }

    return planRows.map((row) {
      final planId = (row['plan_id'] ?? '').toString();
      final parsedCreatedAt = DateTime.tryParse((row['created_at'] ?? '').toString());
      final exercises = List<WorkoutPlanExercise>.from(detailsByPlan[planId] ?? const []);
      exercises.sort((a, b) => a.orderIndex.compareTo(b.orderIndex));

      return WorkoutPlan(
        planId: planId,
        userId: _toInt(row['user_id']),
        planName: (row['plan_name'] ?? 'Untitled Plan').toString(),
        description: _nullableText(row['description']),
        createdAt: parsedCreatedAt,
        exercises: exercises,
      );
    }).toList();
  }

  Future<Map<String, String>> _loadExerciseNames(Set<String> exerciseIds) async {
    if (exerciseIds.isEmpty) {
      return const <String, String>{};
    }

    final response = await supabase
        .from('Exercise')
        .select('*')
        .inFilter('exercise_id', exerciseIds.toList());

    final rows = List<Map<String, dynamic>>.from(response as List);
    final nameMap = <String, String>{};

    for (final row in rows) {
      final key = (row['exercise_id'] ?? '').toString().trim();
      final displayName = _readExerciseDisplayName(row);
      if (key.isEmpty || displayName.isEmpty) {
        continue;
      }
      nameMap[key] = displayName;
    }

    return nameMap;
  }

  String _readExerciseDisplayName(Map<String, dynamic> row) {
    final candidates = <dynamic>[
      row['exercise_name'],
      row['name'],
      row['title'],
    ];

    for (final value in candidates) {
      final text = (value ?? '').toString().trim();
      if (text.isNotEmpty) {
        return text;
      }
    }
    return '';
  }

  String? _nullableText(dynamic value) {
    final text = (value ?? '').toString().trim();
    return text.isEmpty ? null : text;
  }

  int _toInt(dynamic value) {
    if (value is int) {
      return value;
    }
    return int.tryParse((value ?? '').toString()) ?? 0;
  }

  bool _isMissingColumnError(PostgrestException error, String columnName) {
    final message = error.message.toLowerCase();
    return (message.contains('could not find') ||
            message.contains('schema cache') ||
            message.contains('column')) &&
        message.contains(columnName.toLowerCase());
  }

  String _readTextByKeys(Map<String, dynamic> row, List<String> keys) {
    for (final key in keys) {
      final text = (row[key] ?? '').toString().trim();
      if (text.isNotEmpty) {
        return text;
      }
    }
    return '';
  }

  String _generateUuidV4() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;

    String toHex(int value) => value.toRadixString(16).padLeft(2, '0');

    final hex = bytes.map(toHex).join();
    return '${hex.substring(0, 8)}-'
        '${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-'
        '${hex.substring(16, 20)}-'
        '${hex.substring(20)}';
  }

  Future<void> renamePlan({
    required String planId,
    required String planName,
  }) async {
    await supabase
        .from('Exercise_Plan')
        .update(<String, dynamic>{'plan_name': planName})
        .eq('plan_id', planId);
  }

  Future<void> deletePlan(String planId) async {
    await supabase
        .from('Exercise_Plan_Details')
        .delete()
        .eq('plan_id', planId);

    await supabase
        .from('Exercise_Plan')
        .delete()
        .eq('plan_id', planId);
  }

  Future<void> duplicatePlan({
    required int userId,
    required String sourcePlanId,
  }) async {
    final sourcePlan = await supabase
        .from('Exercise_Plan')
        .select('plan_name, description')
        .eq('plan_id', sourcePlanId)
        .maybeSingle();

    if (sourcePlan == null) {
      return;
    }

    final planName = (sourcePlan['plan_name'] ?? 'Untitled Plan').toString();
    final duplicatedHeader = await supabase
        .from('Exercise_Plan')
        .insert(<String, dynamic>{
          'user_id': userId,
          'plan_name': '$planName (Copy)',
          'description': sourcePlan['description'],
        })
        .select('plan_id')
        .single();

    final duplicatedPlanId = (duplicatedHeader['plan_id'] ?? '').toString();
    if (duplicatedPlanId.isEmpty) {
      return;
    }

    final detailResponse = await supabase
        .from('Exercise_Plan_Details')
        .select('*')
        .eq('plan_id', sourcePlanId)
        .order('order_index', ascending: true);

    final sourceDetails = List<Map<String, dynamic>>.from(detailResponse as List);
    if (sourceDetails.isEmpty) {
      return;
    }

    final payload = sourceDetails.map((row) {
      final copiedRow = Map<String, dynamic>.from(row)
        ..remove('detail_id')
        ..['detail_id'] = _generateUuidV4()
        ..['plan_id'] = duplicatedPlanId
        ..['user_id'] = userId;
      return copiedRow;
    }).toList();

    await supabase.from('Exercise_Plan_Details').insert(payload);
  }

  Future<void> updatePlanWithDetails({
    required String planId,
    required int userId,
    required String planName,
    String? description,
    required List<WorkoutPlanDetailInput> details,
  }) async {
    await supabase
        .from('Exercise_Plan')
        .update(<String, dynamic>{
          'plan_name': planName,
          'description': description,
        })
        .eq('plan_id', planId);

    await supabase
        .from('Exercise_Plan_Details')
        .delete()
        .eq('plan_id', planId);

    if (details.isEmpty) {
      return;
    }

    await _insertDetailsWithFallbackColumns(
      planId: planId,
      userId: userId,
      details: details,
    );
  }
}
