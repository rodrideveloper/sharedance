import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../../shared/models/models.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/firebase_service.dart';
import '../../../../core/constants/app_constants.dart';
import '../../domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;

  AuthRepositoryImpl({FirebaseAuth? firebaseAuth, GoogleSignIn? googleSignIn})
    : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
      _googleSignIn = googleSignIn ?? GoogleSignIn();

  @override
  Future<UserModel> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      debugPrint('🔥 AuthRepo: Intentando Firebase Auth con $email');
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user == null) {
        debugPrint('🔥 AuthRepo: Firebase Auth exitoso pero user es null');
        throw const AuthException('Error de autenticación');
      }

      debugPrint(
        '🔥 AuthRepo: Firebase Auth exitoso, obteniendo datos del usuario ${userCredential.user!.uid}',
      );
      return await _getUserData(userCredential.user!.uid);
    } on FirebaseAuthException catch (e) {
      debugPrint(
        '🔥 AuthRepo: FirebaseAuthException - ${e.code}: ${e.message}',
      );
      throw AuthException(_getAuthErrorMessage(e.code));
    } catch (e) {
      debugPrint('🔥 AuthRepo: Error inesperado: $e');
      throw AuthException(e.toString());
    }
  }

  @override
  Future<UserModel> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
    String? phone,
    required UserRole role,
  }) async {
    try {
      debugPrint('🔥 AuthRepo: Creando usuario con email: $email');
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user == null) {
        throw const AuthException('Error al crear usuario');
      }

      final user = UserModel(
        userId: userCredential.user!.uid,
        name: name,
        email: email,
        phone: phone,
        role: role, // Use provided role
        credits: 0, // Initial credits
        createdAt: DateTime.now(),
      );

      debugPrint('🔥 AuthRepo: Guardando usuario en Firestore: ${user.userId}');
      // Save user data to Firestore
      await FirebaseService.setDocument(
        AppConstants.usersCollection,
        user.userId,
        user.toJson(),
      );

      debugPrint('🔥 AuthRepo: Usuario creado exitosamente: ${user.email}');
      return user;
    } on FirebaseAuthException catch (e) {
      debugPrint(
        '🔥 AuthRepo: Error al crear usuario - ${e.code}: ${e.message}',
      );
      throw AuthException(_getAuthErrorMessage(e.code));
    } catch (e) {
      debugPrint('🔥 AuthRepo: Error inesperado al crear usuario: $e');
      throw AuthException(e.toString());
    }
  }

  @override
  Future<UserModel> signInWithGoogle() async {
    try {
      debugPrint('🔥 AuthRepo: Iniciando login con Google');
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        throw const AuthException('Inicio de sesión cancelado');
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _firebaseAuth.signInWithCredential(
        credential,
      );

      if (userCredential.user == null) {
        throw const AuthException('Error en autenticación con Google');
      }

      final user = userCredential.user!;
      debugPrint('🔥 AuthRepo: Google Auth exitoso para: ${user.email}');

      // Check if user exists in Firestore, create if not
      try {
        return await _getUserData(user.uid);
      } catch (e) {
        // User doesn't exist in Firestore, create them
        debugPrint(
          '🔥 AuthRepo: Usuario de Google no existe en Firestore, creando...',
        );
        final newUser = UserModel(
          userId: user.uid,
          name: user.displayName ?? 'Usuario',
          email: user.email!,
          phone: user.phoneNumber,
          role: UserRole.student,
          credits: 0,
          createdAt: DateTime.now(),
        );

        await FirebaseService.setDocument(
          AppConstants.usersCollection,
          newUser.userId,
          newUser.toJson(),
        );

        return newUser;
      }
    } on FirebaseAuthException catch (e) {
      debugPrint(
        '🔥 AuthRepo: Error en Google Sign-In - ${e.code}: ${e.message}',
      );
      throw AuthException(_getAuthErrorMessage(e.code));
    } catch (e) {
      debugPrint('🔥 AuthRepo: Error inesperado en Google Sign-In: $e');
      throw AuthException(e.toString());
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await Future.wait([_firebaseAuth.signOut(), _googleSignIn.signOut()]);
    } catch (e) {
      throw AuthException('Error al cerrar sesión: $e');
    }
  }

  @override
  Future<void> resetPassword(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw AuthException(_getAuthErrorMessage(e.code));
    } catch (e) {
      throw AuthException(e.toString());
    }
  }

  @override
  Stream<UserModel?> get authStateChanges {
    return _firebaseAuth.authStateChanges().asyncMap((firebaseUser) async {
      if (firebaseUser == null) {
        return null;
      }

      try {
        return await _getUserData(firebaseUser.uid);
      } catch (e) {
        return null;
      }
    });
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    final firebaseUser = _firebaseAuth.currentUser;
    if (firebaseUser == null) return null;

    try {
      return await _getUserData(firebaseUser.uid);
    } catch (e) {
      return null;
    }
  }

  Future<UserModel> _getUserData(String uid) async {
    debugPrint(
      '🔥 AuthRepo: Buscando datos del usuario en Firestore para UID: $uid',
    );
    final userData = await FirebaseService.getDocument(
      AppConstants.usersCollection,
      uid,
    );

    if (userData == null) {
      debugPrint(
        '🔥 AuthRepo: Usuario no encontrado en Firestore para UID: $uid',
      );
      throw const AuthException('Usuario no encontrado');
    }

    debugPrint(
      '🔥 AuthRepo: Datos del usuario encontrados: ${userData['email']}',
    );
    return UserModel.fromJson(userData);
  }

  String _getAuthErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'user-not-found':
        return 'Usuario no encontrado';
      case 'wrong-password':
        return 'Contraseña incorrecta';
      case 'invalid-email':
        return 'Email inválido';
      case 'user-disabled':
        return 'Usuario deshabilitado';
      case 'too-many-requests':
        return 'Muchos intentos. Intenta más tarde';
      case 'email-already-in-use':
        return 'El email ya está en uso';
      case 'weak-password':
        return 'La contraseña es muy débil';
      case 'operation-not-allowed':
        return 'Operación no permitida';
      default:
        return 'Error de autenticación';
    }
  }
}
