/// The note to keep for [text]: the text as written, or null when it is
/// blank, so a note of spaces alone is no note. The memo of a day and the
/// notes of a visit keep their text by this one rule.
String? noteOf(String? text) =>
    text == null || text.trim().isEmpty ? null : text;
