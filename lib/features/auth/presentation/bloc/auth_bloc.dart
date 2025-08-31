import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../../../shared/models/models.dart';
import '../../../../core/errors/exceptions.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;
  StreamSubscription<UserModel?>? _authSubscription;

  AuthBloc({required AuthRepository authRepository})
    : _authRepository = authRepository,
      super(const AuthState()) {
    on<AuthSignInWithEmailRequested>(_onSignInWithEmailRequested);
    on<AuthSignUpWithEmailRequested>(_onSignUpWithEmailRequested);
    on<AuthSignInWithGoogleRequested>(_onSignInWithGoogleRequested);
    on<AuthSignOutRequested>(_onSignOutRequested);
    on<AuthResetPasswordRequested>(_onResetPasswordRequested);
    on<AuthUserChanged>(_onUserChanged);

    // Listen to auth state changes
    _authSubscription = _authRepository.authStateChanges.listen(
      (user) => add(AuthUserChanged(user)),
    );
  }

  Future<void> _onSignInWithEmailRequested(
    AuthSignInWithEmailRequested event,
    Emitter<AuthState> emit,
  ) async {
    debugPrint('🔥 AuthBloc: Iniciando login para ${event.email}');
    emit(state.copyWith(status: AuthStatus.loading));

    try {
      final user = await _authRepository.signInWithEmailAndPassword(
        email: event.email,
        password: event.password,
      );

      debugPrint('🔥 AuthBloc: Login exitoso para ${user.email}');
      emit(
        state.copyWith(
          status: AuthStatus.authenticated,
          user: user,
          errorMessage: null,
        ),
      );
    } on AuthException catch (e) {
      debugPrint('🔥 AuthBloc: Error de login: ${e.message}');
      emit(state.copyWith(status: AuthStatus.error, errorMessage: e.message));
    } catch (e) {
      debugPrint('🔥 AuthBloc: Error inesperado de login: $e');
      emit(
        state.copyWith(
          status: AuthStatus.error,
          errorMessage: 'Error inesperado: $e',
        ),
      );
    }
  }

  Future<void> _onSignUpWithEmailRequested(
    AuthSignUpWithEmailRequested event,
    Emitter<AuthState> emit,
  ) async {
    debugPrint('🔥 AuthBloc: Iniciando registro para ${event.email}');
    emit(state.copyWith(status: AuthStatus.loading));

    try {
      final user = await _authRepository.signUpWithEmailAndPassword(
        email: event.email,
        password: event.password,
        name: event.name,
        phone: event.phone,
        role: event.role,
      );

      debugPrint('🔥 AuthBloc: Registro exitoso para ${user.email}');
      emit(
        state.copyWith(
          status: AuthStatus.authenticated,
          user: user,
          errorMessage: null,
        ),
      );
    } on AuthException catch (e) {
      debugPrint('🔥 AuthBloc: Error de registro: ${e.message}');
      emit(state.copyWith(status: AuthStatus.error, errorMessage: e.message));
    } catch (e) {
      debugPrint('🔥 AuthBloc: Error inesperado de registro: $e');
      emit(
        state.copyWith(
          status: AuthStatus.error,
          errorMessage: 'Error inesperado: $e',
        ),
      );
    }
  }

  Future<void> _onSignInWithGoogleRequested(
    AuthSignInWithGoogleRequested event,
    Emitter<AuthState> emit,
  ) async {
    debugPrint('🔥 AuthBloc: Iniciando login con Google');
    emit(state.copyWith(status: AuthStatus.loading));

    try {
      final user = await _authRepository.signInWithGoogle();

      debugPrint('🔥 AuthBloc: Login con Google exitoso para ${user.email}');
      emit(
        state.copyWith(
          status: AuthStatus.authenticated,
          user: user,
          errorMessage: null,
        ),
      );
    } on AuthException catch (e) {
      debugPrint('🔥 AuthBloc: Error de login con Google: ${e.message}');
      emit(state.copyWith(status: AuthStatus.error, errorMessage: e.message));
    } catch (e) {
      debugPrint('🔥 AuthBloc: Error inesperado de login con Google: $e');
      emit(
        state.copyWith(
          status: AuthStatus.error,
          errorMessage: 'Error inesperado: $e',
        ),
      );
    }
  }

  Future<void> _onSignOutRequested(
    AuthSignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    debugPrint('🔥 AuthBloc: Cerrando sesión');
    emit(state.copyWith(status: AuthStatus.loading));

    try {
      await _authRepository.signOut();
      debugPrint('🔥 AuthBloc: Sesión cerrada exitosamente');
      emit(const AuthState());
    } catch (e) {
      debugPrint('🔥 AuthBloc: Error al cerrar sesión: $e');
      emit(
        state.copyWith(
          status: AuthStatus.error,
          errorMessage: 'Error al cerrar sesión: $e',
        ),
      );
    }
  }

  Future<void> _onResetPasswordRequested(
    AuthResetPasswordRequested event,
    Emitter<AuthState> emit,
  ) async {
    debugPrint(
      '🔥 AuthBloc: Solicitando reset de contraseña para ${event.email}',
    );
    emit(state.copyWith(status: AuthStatus.loading));

    try {
      await _authRepository.resetPassword(event.email);
      debugPrint('🔥 AuthBloc: Email de reset enviado a ${event.email}');
      emit(
        state.copyWith(status: AuthStatus.unauthenticated, errorMessage: null),
      );
    } on AuthException catch (e) {
      debugPrint(
        '🔥 AuthBloc: Error al enviar reset de contraseña: ${e.message}',
      );
      emit(state.copyWith(status: AuthStatus.error, errorMessage: e.message));
    } catch (e) {
      debugPrint('🔥 AuthBloc: Error inesperado al reset contraseña: $e');
      emit(
        state.copyWith(
          status: AuthStatus.error,
          errorMessage: 'Error inesperado: $e',
        ),
      );
    }
  }

  void _onUserChanged(AuthUserChanged event, Emitter<AuthState> emit) {
    final user = event.user;
    if (user != null) {
      debugPrint('🔥 AuthBloc: Usuario autenticado: ${user.email}');
      emit(state.copyWith(status: AuthStatus.authenticated, user: user));
    } else {
      debugPrint('🔥 AuthBloc: Usuario no autenticado');
      emit(state.copyWith(status: AuthStatus.unauthenticated, user: null));
    }
  }

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    return super.close();
  }
}
