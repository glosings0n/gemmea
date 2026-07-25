class TextSanitizer {
  /// Cleans up raw LaTeX expressions, chemical formulas, emojis, and broken escaping
  /// to convert them into clean, professional plain text for farmers.
  static String cleanLatexAndFormatting(String input) {
    if (input.isEmpty) return input;
    String text = input;

    // 1. Strip all Unicode emojis and non-standard symbol glyphs
    text = text.replaceAll(
      RegExp(
        r'[\u{1F600}-\u{1F64F}' // Emoticons
        r'\u{1F300}-\u{1F5FF}' // Misc Symbols and Pictographs
        r'\u{1F680}-\u{1F6FF}' // Transport and Map
        r'\u{1F700}-\u{1F77F}' // Alchemical Symbols
        r'\u{1F780}-\u{1F7FF}' // Geometric Shapes Extended
        r'\u{1F800}-\u{1F8FF}' // Supplemental Arrows-C
        r'\u{1F900}-\u{1F9FF}' // Supplemental Symbols and Pictographs
        r'\u{1FA00}-\u{1FA6F}' // Chess Symbols
        r'\u{1FA70}-\u{1FAFF}' // Symbols and Pictographs Extended-A
        r'\u{2600}-\u{26FF}'   // Misc Symbols (like 🌧️, ☀️, ☔)
        r'\u{2700}-\u{27BF}'   // Dingbats (like 📌, ✂️, ✏️, 🔍)
        r'\u{FE00}-\u{FE0F}'   // Variation Selectors
        r'\u{1F1E6}-\u{1F1FF}' // Flags
        r']',
        unicode: true,
      ),
      '',
    );

    // 2. Replace common chemical LaTeX formulas and escape artifacts
    text = text.replaceAll(
      RegExp(r'\$?\\?text\{NaHCO\}_?\{?3\}?\\?\$?|\$?\\?text\{NaHCO3\}\\?\$?|\$NaHCO_3\\?\$?', caseSensitive: false),
      'Bicarbonate de soude (NaHCO3)',
    );
    text = text.replaceAll(
      RegExp(r'\$?\\?text\{H\}_?\{?2\}?\\?text\{O\}\\?\$?|\$H_2O\\?\$?', caseSensitive: false),
      'eau (H2O)',
    );
    text = text.replaceAll(
      RegExp(r'\$?\\?text\{CO\}_?\{?2\}\\?\$?|\$CO_2\\?\$?', caseSensitive: false),
      'dioxyde de carbone (CO2)',
    );
    text = text.replaceAll(
      RegExp(r'\$?\\?text\{N\}\\?\$?', caseSensitive: false),
      'Azote (N)',
    );
    text = text.replaceAll(
      RegExp(r'\$?\\?text\{P\}\\?\$?', caseSensitive: false),
      'Phosphore (P)',
    );
    text = text.replaceAll(
      RegExp(r'\$?\\?text\{K\}\\?\$?', caseSensitive: false),
      'Potassium (K)',
    );

    // 3. Remove LaTeX \text{...}, \mathrm{...}, \mathbf{...} wrappers
    text = text.replaceAllMapped(
      RegExp(r'\\(?:text|mathrm|mathbf)\{([^}]+)\}'),
      (match) => match.group(1) ?? '',
    );

    // 4. Remove subscript braces/underscores in chemical formulas (e.g. NaHCO_3 -> NaHCO3)
    text = text.replaceAllMapped(
      RegExp(r'([A-Za-z]+)_\{?(\d+)\}?'),
      (match) => '${match.group(1)}${match.group(2)}',
    );

    // 5. Remove inline dollar sign math syntax $xyz$
    text = text.replaceAllMapped(
      RegExp(r'\$([^\$]+)\$'),
      (match) {
        final inner = match.group(1) ?? '';
        return inner.replaceAll(RegExp(r'[\{_\}\\]'), '');
      },
    );

    // 6. Clean remaining dollar signs and unescaped LaTeX backslashes except newlines
    text = text.replaceAll(r'$', '');
    text = text.replaceAll(RegExp(r'\\(?![nN])'), '');

    // 6. Clean up multiple spaces and blank lines
    text = text.replaceAll(RegExp(r' {2,}'), ' ');
    text = text.replaceAll(RegExp(r'\n{3,}'), '\n\n');

    return text.trim();
  }
}
