/// The name to keep for [text]: the text without surrounding spaces, or null
/// when it is blank, since a blank item cannot be told apart. Kept apart from
/// any one feature so that what the person names anywhere follows one rule.
String? nameOf(String text) {
  final trimmed = text.trim();
  return trimmed.isEmpty ? null : trimmed;
}
