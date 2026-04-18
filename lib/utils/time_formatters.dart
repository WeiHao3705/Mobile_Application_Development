String formatRelativeTime(DateTime? value, {DateTime? now}) {
  if (value == null) {
    return '--';
  }

  final reference = now ?? DateTime.now();
  final referenceClock = DateTime(
    reference.year,
    reference.month,
    reference.day,
    reference.hour,
    reference.minute,
    reference.second,
    reference.millisecond,
    reference.microsecond,
  );
  final targetClock = DateTime(
    value.year,
    value.month,
    value.day,
    value.hour,
    value.minute,
    value.second,
    value.millisecond,
    value.microsecond,
  );
  final diff = referenceClock.difference(targetClock);

  if (diff.isNegative) {
    final ahead = diff.abs();
    if (ahead.inSeconds < 30) {
      return 'just now';
    }
    if (ahead.inMinutes < 60) {
      return 'in ${ahead.inMinutes} min${ahead.inMinutes == 1 ? '' : 's'}';
    }
    if (ahead.inHours < 24) {
      return 'in ${ahead.inHours} hour${ahead.inHours == 1 ? '' : 's'}';
    }
    return 'in ${ahead.inDays} day${ahead.inDays == 1 ? '' : 's'}';
  }

  if (diff.inSeconds < 30) {
    return 'just now';
  }
  if (diff.inMinutes < 1) {
    return '${diff.inSeconds}s ago';
  }
  if (diff.inMinutes < 60) {
    return '${diff.inMinutes} min${diff.inMinutes == 1 ? '' : 's'} ago';
  }
  if (diff.inHours < 24) {
    return '${diff.inHours} hour${diff.inHours == 1 ? '' : 's'} ago';
  }
  if (diff.inDays < 7) {
    return '${diff.inDays} day${diff.inDays == 1 ? '' : 's'} ago';
  }

  final day = targetClock.day.toString().padLeft(2, '0');
  final month = targetClock.month.toString().padLeft(2, '0');
  final year = targetClock.year.toString();
  return '$day/$month/$year';
}

String formatDateTimeCompact(DateTime? value) {
  if (value == null) {
    return '--';
  }
  final day = value.day.toString().padLeft(2, '0');
  final month = value.month.toString().padLeft(2, '0');
  final year = value.year.toString();
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  return '$day/$month/$year $hour:$minute';
}
