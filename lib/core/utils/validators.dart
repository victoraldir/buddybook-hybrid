// lib/core/utils/validators.dart

class Validators {
  /// Validate email
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
        .hasMatch(value)) {
      return 'Please enter a valid email';
    }
    return null;
  }

  /// Validate password
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  /// Validate username
  static String? validateUsername(String? value) {
    if (value == null || value.isEmpty) {
      return 'Username is required';
    }
    if (value.length < 3) {
      return 'Username must be at least 3 characters';
    }
    if (value.length > 50) {
      return 'Username must be less than 50 characters';
    }
    return null;
  }

  /// Validate folder name
  static String? validateFolderName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Folder name is required';
    }
    if (value.length > 100) {
      return 'Folder name must be less than 100 characters';
    }
    return null;
  }

  /// Validate book title
  static String? validateBookTitle(String? value) {
    if (value == null || value.isEmpty) {
      return 'Title is required';
    }
    if (value.length > 500) {
      return 'Title must be less than 500 characters';
    }
    return null;
  }

  /// Validate ISBN
  static String? validateISBN(String? value) {
    if (value == null || value.isEmpty) {
      return null; // ISBN is optional
    }
    final isbn = value.replaceAll('-', '').replaceAll(' ', '');
    if (isbn.length != 10 && isbn.length != 13) {
      return 'ISBN must be 10 or 13 digits';
    }
    if (!RegExp(r'^[0-9]+$').hasMatch(isbn)) {
      return 'ISBN must contain only digits';
    }
    return null;
  }

  /// Validate annotation/notes
  static String? validateAnnotation(String? value) {
    if (value != null && value.length > 10000) {
      return 'Notes must be less than 10000 characters';
    }
    return null;
  }

  /// Validate receiver email for lending
  static String? validateReceiverEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Receiver email is required';
    }
    return validateEmail(value);
  }
}
