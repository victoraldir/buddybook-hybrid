// lib/core/utils/string_extensions.dart

extension StringExtensions on String {
  /// Check if email is valid
  bool isValidEmail() {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(this);
  }

  /// Check if string is a valid ISBN
  bool isValidISBN() {
    final isbn = replaceAll('-', '').replaceAll(' ', '');
    return (isbn.length == 10 || isbn.length == 13) && int.tryParse(isbn) != null;
  }

  /// Check if string is a valid URL
  bool isValidURL() {
    try {
      Uri.parse(this);
      return startsWith('http://') || startsWith('https://');
    } catch (e) {
      return false;
    }
  }

  /// Capitalize first letter
  String capitalize() {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1);
  }

  /// Truncate string with ellipsis
  String truncate(int maxLength, {String ellipsis = '...'}) {
    if (length <= maxLength) return this;
    return substring(0, maxLength) + ellipsis;
  }
}
