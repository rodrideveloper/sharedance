import 'package:firebase_auth/firebase_auth.dart';

enum UserRole { admin, instructor, student, unknown }

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get current user
  static User? getCurrentUser() {
    return _auth.currentUser;
  }

  /// Get current user role from custom claims
  static Future<UserRole> getCurrentUserRole() async {
    try {
      final user = getCurrentUser();
      if (user == null) return UserRole.unknown;

      final idTokenResult = await user.getIdTokenResult();
      final claims = idTokenResult.claims;

      final roleString = claims?['role'] as String?;

      switch (roleString) {
        case 'admin':
          return UserRole.admin;
        case 'instructor':
          return UserRole.instructor;
        case 'student':
          return UserRole.student;
        default:
          return UserRole.unknown;
      }
    } catch (e) {
      print('Error getting user role: $e');
      return UserRole.unknown;
    }
  }

  /// Check if user has temporary password
  static Future<bool> hasTemporaryPassword() async {
    try {
      final user = getCurrentUser();
      if (user == null) return false;

      final idTokenResult = await user.getIdTokenResult();
      final claims = idTokenResult.claims;

      return claims?['temporaryPassword'] == true;
    } catch (e) {
      print('Error checking temporary password: $e');
      return false;
    }
  }

  /// Sign in with email and password
  static Future<UserCredential?> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      print('Sign in error: $e');
      rethrow;
    }
  }

  /// Sign out
  static Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Update password
  static Future<void> updatePassword(String newPassword) async {
    final user = getCurrentUser();
    if (user != null) {
      await user.updatePassword(newPassword);
    }
  }

  /// Send password reset email
  static Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  /// Get current user ID token for API authentication
  static Future<String?> getIdToken() async {
    try {
      final user = getCurrentUser();
      if (user == null) return null;

      return await user.getIdToken();
    } catch (e) {
      print('Error getting ID token: $e');
      return null;
    }
  }

  /// Stream of auth state changes
  static Stream<User?> get authStateChanges => _auth.authStateChanges();
}
