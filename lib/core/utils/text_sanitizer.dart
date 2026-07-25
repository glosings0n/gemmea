class TextSanitizer {
  /// Cleans up raw LaTeX expressions, chemical formulas, and broken escaping
  /// to convert them into clean, human-readable plain text for farmers.
  static String cleanLatexAndFormatting(String input) {
    if (input.isEmpty) return input;
    String text = input;

    // 1. Replace common chemical LaTeX formulas
    text = text.replaceAll(
      RegExp(r'\$\\text\{NaHCO\}_3\\?\$|\$\\text\{NaHCO3\}\$|\\text\{NaHCO_3\}|\$NaHCO_3\$', caseSensitive: false),
      'Bicarbonate de soude (NaHCO3)',
    );
    text = text.replaceAll(
      RegExp(r'\$\\text\{H\}_2\\text\{O\}\$|\\text\{H2O\}|\$H_2O\$', caseSensitive: false),
      'eau (H2O)',
    );
    text = text.replaceAll(
      RegExp(r'\$\\text\{CO\}_2\$|\\text\{CO2\}|\$CO_2\$', caseSensitive: false),
      'dioxyde de carbone (CO2)',
    );
    text = text.replaceAll(
      RegExp(r'\$\\text\{N\}\$|\\text\{N\}', caseSensitive: false),
      'Azote (N)',
    );
    text = text.replaceAll(
      RegExp(r'\$\\text\{P\}\$|\\text\{P\}', caseSensitive: false),
      'Phosphore (P)',
    );
    text = text.replaceAll(
      RegExp(r'\$\\text\{K\}\$|\\text\{K\}', caseSensitive: false),
      'Potassium (K)',
    );

    // 2. Remove LaTeX \text{...} wrappers
    text = text.replaceAllMapped(
      RegExp(r'\\text\{([^}]+)\}'),
      (match) => match.group(1) ?? '',
    );

    // 3. Remove inline dollar sign math syntax $xyz$
    text = text.replaceAllMapped(
      RegExp(r'\$([^\$]+)\$'),
      (match) {
        final inner = match.group(1) ?? '';
        return inner.replaceAll(RegExp(r'[\{_\}\\]'), '');
      },
    );

    // 4. Remove unescaped LaTeX backslashes except newlines
    text = text.replaceAll(RegExp(r'\\(?![nN])'), '');

    // 5. Clean up multiple trailing blank lines
    text = text.replaceAll(RegExp(r'\n{3,}'), '\n\n');

    return text.trim();
  }
}
