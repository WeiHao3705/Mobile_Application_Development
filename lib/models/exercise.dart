class Exercise {
  const Exercise({
    required this.id,
    required this.name,
    required this.primaryMuscle,
    required this.muscleGroup,
    required this.equipment,
    required this.imageUrl,
    required this.secondaryMuscle,
    required this.howTo,
    this.videoUrl,
  });

  final String id;
  final String name;
  final String primaryMuscle;
  final String muscleGroup;
  final String equipment;
  final String imageUrl;
  final String secondaryMuscle;
  final String howTo;
  final String? videoUrl;

  factory Exercise.fromJson(Map<String, dynamic> json) {
    String readString(List<String> keys, {String fallback = ''}) {
      for (final key in keys) {
        final value = json[key];
        if (value != null && value.toString().trim().isNotEmpty) {
          return value.toString().trim();
        }
      }
      return fallback;
    }

    String readSecondaryMuscle(List<String> keys, {String fallback = ''}) {
      for (final key in keys) {
        final value = json[key];
        if (value == null) {
          continue;
        }

        if (value is List) {
          final cleaned = value
              .map((item) => item.toString().trim())
              .where((item) => item.isNotEmpty)
              .join(', ');
          if (cleaned.isNotEmpty) {
            return cleaned;
          }
          continue;
        }

        final cleaned = _cleanListLikeText(value.toString());
        if (cleaned.isNotEmpty) {
          return cleaned;
        }
      }
      return fallback;
    }

    String? readNullableString(List<String> keys) {
      for (final key in keys) {
        final value = json[key];
        if (value != null && value.toString().trim().isNotEmpty) {
          return value.toString().trim();
        }
      }
      return null;
    }

    final parsedPrimaryMuscle = readString(
      ['primary_muscle', 'primaryMuscle', 'muscle_group', 'target_muscle', 'muscle'],
      fallback: 'Unknown Muscle',
    );

    return Exercise(
      id: readString(['id', 'exercise_id'], fallback: '0'),
      name: readString(['name', 'exercise_name', 'title'], fallback: 'Unnamed Exercise'),
      primaryMuscle: parsedPrimaryMuscle,
      muscleGroup: readString(['muscle_group', 'target_muscle', 'muscle'], fallback: parsedPrimaryMuscle),
      equipment: readString(['equipment', 'equipment_name', 'tool'], fallback: 'Bodyweight'),
      imageUrl: readString(['image_url', 'image', 'thumbnail_url']),
      secondaryMuscle: readSecondaryMuscle(
        // Include common spellings plus the DB column `secondary_mescle` (varchar[])
        ['secondary_muscle', 'secondaryMescle', 'secondary_mescle', 'secondaryMuscle', 'secondary_muscles'],
        fallback: 'Not provided',
      ),
      howTo: readString(
        ['instruction', 'instructions', 'how_to_do', 'how_to', 'description'],
        fallback: 'No instructions provided.',
      ),
      videoUrl: readNullableString(['video_url', 'video', 'video_link']),
    );
  }

  static String _cleanListLikeText(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) {
      return '';
    }

    if (trimmed.startsWith('[') && trimmed.endsWith(']')) {
      final inner = trimmed.substring(1, trimmed.length - 1).trim();
      if (inner.isEmpty) {
        return '';
      }

      return inner
          .split(',')
          .map((item) => _stripWrappingQuotes(item.trim()))
          .where((item) => item.isNotEmpty)
          .join(', ');
    }

    return _stripWrappingQuotes(trimmed);
  }

  static String _stripWrappingQuotes(String value) {
    if (value.length >= 2) {
      final first = value[0];
      final last = value[value.length - 1];
      final isSingleQuoted = first == "'" && last == "'";
      final isDoubleQuoted = first == '"' && last == '"';
      if (isSingleQuoted || isDoubleQuoted) {
        return value.substring(1, value.length - 1).trim();
      }
    }
    return value;
  }
}