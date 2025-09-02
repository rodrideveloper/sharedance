import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_models/shared_models.dart';
import '../../domain/repositories/auth_repository.dart';

class AuthRepositorySimple implements AuthRepository {
  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;
  final FirebaseFirestore _firestore;

  AuthRepositorySimple({
    FirebaseAuth? firebaseAuth,
    GoogleSignIn? googleSignIn,
    FirebaseFirestore? firestore,
  }) : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
       _googleSignIn = googleSignIn ?? GoogleSignIn(),
       _firestore = firestore ?? FirebaseFirestore.instance;

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
        throw Exception('No se pudo obtener el usuario');
      }

      // Obtener datos del usuario desde Firestore
      final userDoc =
          await _firestore
              .collection('users')
              .doc(userCredential.user!.uid)
              .get();

      if (!userDoc.exists) {
        throw Exception('Usuario no encontrado en Firestore');
      }

      return UserModel.fromJson({
        'userId': userCredential.user!.uid,
        'email': userCredential.user!.email,
        ...userDoc.data()!,
      });
    } catch (e) {
      debugPrint('🔥 AuthRepo: Error en login: $e');
      rethrow;
    }
  }

  @override
  Future<UserModel> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
    String? phone,
  }) async {
    try {
      debugPrint('🔥 AuthRepo: Registrando usuario $email como student');

      // Crear usuario en Firebase Auth
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user == null) {
        throw Exception('No se pudo crear el usuario');
      }

      // Crear modelo de usuario
      final userModel = UserModel(
        userId: userCredential.user!.uid,
        name: name,
        email: email,
        phone: phone,
        role: UserRole.student, // Always student for mobile app registration
        credits: 0,
        createdAt: DateTime.now(),
        isActive: true,
        isEmailVerified: false,
        updatedAt: DateTime.now(),
      );

      // Guardar en Firestore con reintentos
      debugPrint('🔥 AuthRepo: Intentando guardar en Firestore...');
      await _saveUserToFirestore(userCredential.user!.uid, userModel);

      debugPrint('🔥 AuthRepo: Usuario registrado exitosamente');
      return userModel;
    } catch (e) {
      debugPrint('🔥 AuthRepo: Error en registro: $e');
      rethrow;
    }
  }

  @override
  Future<UserModel> signInWithGoogle() async {
    throw UnimplementedError('Google Sign-In pendiente');
  }

  @override
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
    await _googleSignIn.signOut();
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) return null;

    try {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();

      if (!userDoc.exists) return null;

      return UserModel.fromJson({
        'userId': user.uid,
        'email': user.email,
        ...userDoc.data()!,
      });
    } catch (e) {
      debugPrint('🔥 AuthRepo: Error obteniendo usuario actual: $e');
      return null;
    }
  }

  @override
  Future<void> resetPassword(String email) async {
    await _firebaseAuth.sendPasswordResetEmail(email: email);
  }

  @override
  Stream<UserModel?> get authStateChanges {
    return _firebaseAuth.authStateChanges().asyncMap((user) async {
      if (user == null) return null;
      return await getCurrentUser();
    });
  }

  // Método privado para guardar usuario en Firestore con reintentos
  Future<void> _saveUserToFirestore(String uid, UserModel userModel) async {
    const maxRetries = 3;
    const retryDelay = Duration(seconds: 2);

    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        debugPrint(
          '🔥 AuthRepo: Intento $attempt de $maxRetries para guardar en Firestore',
        );

        await _firestore.collection('users').doc(uid).set(userModel.toJson());

        debugPrint('🔥 AuthRepo: Usuario guardado exitosamente en Firestore');
        return; // Éxito, salir del loop
      } catch (e) {
        debugPrint('🔥 AuthRepo: Error en intento $attempt: $e');

        if (attempt == maxRetries) {
          debugPrint(
            '🔥 AuthRepo: Todos los intentos fallaron, lanzando error',
          );
          throw Exception(
            'No se pudo guardar el usuario en Firestore después de $maxRetries intentos: $e',
          );
        }

        debugPrint(
          '🔥 AuthRepo: Esperando ${retryDelay.inSeconds}s antes del siguiente intento...',
        );
        await Future.delayed(retryDelay);
      }
    }
  }
}
