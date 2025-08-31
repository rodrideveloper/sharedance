import '../../../../shared/models/models.dart';

abstract class AuthRepository {
  Future<UserModel> signInWithEmailAndPassword({
    required String email,
    required String password,
  });

  Future<UserModel> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
    String? phone,
    required UserRole role,
  });

  Future<UserModel> signInWithGoogle();

  Future<void> signOut();

  Future<UserModel?> getCurrentUser();

  Future<void> resetPassword(String email);

  Stream<UserModel?> get authStateChanges;
}
