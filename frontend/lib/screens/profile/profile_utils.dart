/// Extracts the avatar initial from a user's name.
/// Returns the first character uppercased, or '?' if name is empty.
String avatarInitial(String name) {
  if (name.isEmpty) return '?';
  return name[0].toUpperCase();
}

/// Computes the number of days between [createdAt] and [now].
int daysActive(DateTime createdAt, DateTime now) {
  return now.difference(createdAt).inDays;
}

/// Formats a DateTime as "MMM yyyy" (e.g., "Mar 2025").
String formatMemberSince(DateTime date) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${months[date.month - 1]} ${date.year}';
}
