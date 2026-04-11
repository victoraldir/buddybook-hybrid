// lib/core/errors/exceptions.dart

class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalException;

  AppException({
    required this.message,
    this.code,
    this.originalException,
  });

  @override
  String toString() => message;
}

class FirebaseException extends AppException {
  FirebaseException({
    required super.message,
    super.code,
    super.originalException,
  });
}

class NetworkException extends AppException {
  NetworkException({
    required super.message,
    super.code,
    super.originalException,
  });
}

class AuthException extends AppException {
  AuthException({
    required super.message,
    super.code,
    super.originalException,
  });
}

class ValidationException extends AppException {
  ValidationException({
    required super.message,
    super.code,
    super.originalException,
  });
}

class ServerException extends AppException {
  ServerException({
    required super.message,
    super.code,
    super.originalException,
  });
}

class CacheException extends AppException {
  CacheException({
    required super.message,
    super.code,
    super.originalException,
  });
}

class UnknownException extends AppException {
  UnknownException({
    required super.message,
    super.code,
    super.originalException,
  });
}

/// Thrown when a user record does not exist in the database.
/// This is distinct from a parse error or other Firebase error.
class UserNotFoundException extends FirebaseException {
  UserNotFoundException({
    required super.message,
  });
}
