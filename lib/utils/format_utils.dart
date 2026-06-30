// Shared formatter for any comma-separated per-set value (weight or reps).
// "20kg,22.5kg,25kg" -> "set 1: 20kg  set 2: 22.5kg  set 3: 25kg"
// "25kg,25kg,25kg"   -> "25kg"   (all sets identical -> no redundancy)
// "25kg"             -> "25kg"
String formatPerSetValue(String raw) {
  final parts = raw.split(',');
  if (parts.length <= 1) return raw;
  final unique = parts.map((p) => p.trim()).toSet();
  if (unique.length == 1) return unique.first;
  return parts.asMap().entries.map((e) => 'set ${e.key + 1}: ${e.value.trim()}').join('  ');
}

// strips a "kg" unit suffix from a raw value — used when seeding an input
// field's text (the field itself shows the "kg" via its suffixText, so the
// editable text shouldn't duplicate it).
String stripWeightUnit(String raw) {
  return raw.replaceAll(RegExp(r'\s*kg', caseSensitive: false), '');
}
