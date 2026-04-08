import 'dart:math';

import 'package:supabase_flutter/supabase_flutter.dart';

class WorkoutRecordDetailInput {
  const WorkoutRecordDetailInput({
    required this.exerciseName,
    required this.orderIndex,
    required this.sets,
    required this.reps,
    required this.weight,
    required this.notes,
  });

  final String exerciseName;
  final int orderIndex;
  final int sets;
  final int reps;
  final int weight;
  final String notes;
}

class WorkoutRecordSummary {
  const WorkoutRecordSummary({
    required this.recordId,
    required this.userId,
    required this.recordTitle,
    required this.recordImage,
    required this.createdAt,
    required this.duration,
    required this.trainingVolume,
    required this.numOfSets,
  });

  final String recordId;
  final int userId;
  final String recordTitle;
  final String? recordImage;
  final DateTime createdAt;
  final int duration;
  final int trainingVolume;
  final int numOfSets;
}

class WorkoutRecordDetailRow {
  const WorkoutRecordDetailRow({
    required this.detailId,
    required this.recordId,
    required this.exerciseName,
    required this.orderIndex,
    required this.sets,
    required this.reps,
    required this.weight,
    required this.notes,
  });

  final String detailId;
  final String recordId;
  final String exerciseName;
  final int orderIndex;
  final int sets;
  final int reps;
  final int weight;
  final String notes;
}

class WorkoutRecordWithDetails {
  const WorkoutRecordWithDetails({
    required this.summary,
    required this.details,
  });

  final WorkoutRecordSummary summary;
  final List<WorkoutRecordDetailRow> details;
}

class WorkoutRecordRepository {
  WorkoutRecordRepository({required this.supabase});

  final SupabaseClient supabase;
  static const String _recordImageBucket = 'exercise_record_image';

  Future<void> createRecordWithDetails({
    required int userId,
    required String title,
    required String? image,
    required DateTime createdAt,
    required int duration,
    required int trainingVolume,
    required int numOfSets,
    required List<WorkoutRecordDetailInput> details,
  }) async {
    final recordId = _generateUuidV4();

    await supabase.from('Exercise_Record').insert(<String, dynamic>{
      'record_id': recordId,
      'user_id': userId,
      'record_title': title,
      'record_image': image,
      'created_at': createdAt.toUtc().toIso8601String(),
      'duration': duration,
      'training_volume': trainingVolume,
      'num_of_sets': numOfSets,
    });

    if (details.isEmpty) {
      return;
    }

    final detailPayload = details
        .map(
          (detail) => <String, dynamic>{
            'detail_id': _generateUuidV4(),
            'record_id': recordId,
            'exercise_name': detail.exerciseName,
            'order_index': detail.orderIndex,
            'sets': detail.sets,
            'reps': detail.reps,
            'weight': detail.weight,
            'notes': detail.notes,
          },
        )
        .toList();

    await supabase.from('Exercise_Record_Details').insert(detailPayload);
  }

  Future<WorkoutRecordSummary?> getLatestRecordForUser(int userId) async {
    final response = await supabase
        .from('Exercise_Record')
        .select('*')
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(1);

    final rows = List<Map<String, dynamic>>.from(response as List);
    if (rows.isEmpty) {
      return null;
    }

    return _summaryFromRow(rows.first);
  }

  Future<WorkoutRecordWithDetails?> getRecordWithDetails(String recordId) async {
    final recordResponse = await supabase
        .from('Exercise_Record')
        .select('*')
        .eq('record_id', recordId)
        .limit(1);

    final recordRows = List<Map<String, dynamic>>.from(recordResponse as List);
    if (recordRows.isEmpty) {
      return null;
    }

    final detailResponse = await supabase
        .from('Exercise_Record_Details')
        .select('*')
        .eq('record_id', recordId)
        .order('order_index', ascending: true);

    final detailRows = List<Map<String, dynamic>>.from(detailResponse as List);

    return WorkoutRecordWithDetails(
      summary: _summaryFromRow(recordRows.first),
      details: detailRows.map(_detailFromRow).toList(),
    );
  }

  Future<void> deleteRecord(String recordId) async {
    await supabase.from('Exercise_Record_Details').delete().eq('record_id', recordId);
    await supabase.from('Exercise_Record').delete().eq('record_id', recordId);
  }

  Future<List<WorkoutRecordDetailRow>> getRecordDetails(String recordId) async {
    final response = await supabase
        .from('Exercise_Record_Details')
        .select('*')
        .eq('record_id', recordId)
        .order('order_index', ascending: true);

    return List<Map<String, dynamic>>.from(response as List).map(_detailFromRow).toList();
  }

  Future<List<WorkoutRecordWithDetails>> getRecordsWithDetailsForUser(int userId) async {
    final recordResponse = await supabase
        .from('Exercise_Record')
        .select('*')
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    final recordRows = List<Map<String, dynamic>>.from(recordResponse as List);
    if (recordRows.isEmpty) {
      return [];
    }

    final recordIds = recordRows.map((r) => r['record_id']).toList();

    final detailResponse = await supabase
        .from('Exercise_Record_Details')
        .select('*')
        .inFilter('record_id', recordIds)
        .order('order_index', ascending: true);

    final detailRows = List<Map<String, dynamic>>.from(detailResponse as List);

    return recordRows.map((recordRow) {
      final summary = _summaryFromRow(recordRow);
      final details = detailRows
          .where((dr) => dr['record_id'] == summary.recordId)
          .map(_detailFromRow)
          .toList();
      return WorkoutRecordWithDetails(summary: summary, details: details);
    }).toList();
  }

  WorkoutRecordSummary _summaryFromRow(Map<String, dynamic> row) {
    final rawRecordImage = _readString(row, const ['record_image']);
    return WorkoutRecordSummary(
      recordId: _readString(row, const ['record_id']),
      userId: _readInt(row, const ['user_id']),
      recordTitle: _readString(row, const ['record_title'], fallback: 'Workout Record'),
      recordImage: rawRecordImage.isEmpty ? null : _normalizeRecordImage(rawRecordImage),
      createdAt: _readDateTime(row, const ['created_at']) ?? DateTime.now(),
      duration: _readInt(row, const ['duration']),
      trainingVolume: _readInt(row, const ['training_volume']),
      numOfSets: _readInt(row, const ['num_of_sets']),
    );
  }

  String _normalizeRecordImage(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return trimmed;
    }

    String? normalizeBucketObject(String bucketAndPath) {
      var normalized = bucketAndPath.trim();
      if (normalized.startsWith('/')) {
        normalized = normalized.substring(1);
      }

      if (normalized.startsWith('$_recordImageBucket/')) {
        normalized = normalized.substring('$_recordImageBucket/'.length);
      } else if (normalized.startsWith('Exercise_Record_Image/')) {
        normalized = normalized.substring('Exercise_Record_Image/'.length);
      } else {
        return null;
      }

      if (normalized.isEmpty) {
        return null;
      }

      final decoded = Uri.decodeComponent(normalized);
      return supabase.storage.from(_recordImageBucket).getPublicUrl(decoded);
    }

    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      final uri = Uri.tryParse(trimmed);
      final path = uri?.path ?? '';

      const knownPrefixes = <String>[
        '/storage/v1/object/public/',
        '/storage/v1/object/',
        '/v1/object/public/',
        '/v1/object/',
        '/object/public/',
      ];

      for (final prefix in knownPrefixes) {
        if (path.contains(prefix)) {
          final tail = path.split(prefix).last;
          final normalized = normalizeBucketObject(tail);
          if (normalized != null) {
            return normalized;
          }
        }
      }

      return trimmed.replaceAll('/Exercise_Record_Image/', '/$_recordImageBucket/');
    }

    final normalized = normalizeBucketObject(trimmed);
    if (normalized != null) {
      return normalized;
    }

    return supabase.storage.from(_recordImageBucket).getPublicUrl(Uri.decodeComponent(trimmed));
  }

  WorkoutRecordDetailRow _detailFromRow(Map<String, dynamic> row) {
    return WorkoutRecordDetailRow(
      detailId: _readString(row, const ['detail_id']),
      recordId: _readString(row, const ['record_id']),
      exerciseName: _readString(row, const ['exercise_name'], fallback: 'Exercise'),
      orderIndex: _readInt(row, const ['order_index']),
      sets: _readInt(row, const ['sets']),
      reps: _readInt(row, const ['reps']),
      weight: _readInt(row, const ['weight']),
      notes: _readString(row, const ['notes']),
    );
  }

  static String _readString(
    Map<String, dynamic> row,
    List<String> keys, {
    String fallback = '',
  }) {
    for (final key in keys) {
      final text = (row[key] ?? '').toString().trim();
      if (text.isNotEmpty) {
        return text;
      }
    }
    return fallback;
  }

  static int _readInt(Map<String, dynamic> row, List<String> keys) {
    for (final key in keys) {
      final value = row[key];
      if (value is int) {
        return value;
      }
      final parsed = int.tryParse((value ?? '').toString());
      if (parsed != null) {
        return parsed;
      }
    }
    return 0;
  }

  static DateTime? _readDateTime(Map<String, dynamic> row, List<String> keys) {
    for (final key in keys) {
      final value = row[key];
      if (value is DateTime) {
        return value;
      }
      final parsed = DateTime.tryParse((value ?? '').toString());
      if (parsed != null) {
        return parsed;
      }
    }
    return null;
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
}