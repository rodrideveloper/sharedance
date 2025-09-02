class ServerException implements Exception {
  final String message;
  const ServerException(this.message);
}

class NetworkException implements Exception {
  final String message;
  const NetworkException(this.message);
}

class AuthException implements Exception {
  final String message;
  const AuthException(this.message);
}

class ValidationException implements Exception {
  final String message;
  const ValidationException(this.message);
}

class CacheException implements Exception {
  final String message;
  const CacheException(this.message);
}

class FirestoreException implements Exception {
  final String message;
  const FirestoreException(this.message);
}

class InsufficientCreditsException implements Exception {
  final String message;
  const InsufficientCreditsException(this.message);
}

class ClassFullException implements Exception {
  final String message;
  const ClassFullException(this.message);
}
