import 'package:equatable/equatable.dart';
import '../../../../shared/models/models.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AuthSignInWithEmailRequested extends AuthEvent {
  final String email;
  final String password;

  const AuthSignInWithEmailRequested({
    required this.email,
    required this.password,
  });

  @override
  List<Object> get props => [email, password];
}

class AuthSignUpWithEmailRequested extends AuthEvent {
  final String email;
  final String password;
  final String name;
  final String? phone;
  final UserRole role;

  const AuthSignUpWithEmailRequested({
    required this.email,
    required this.password,
    required this.name,
    this.phone,
    required this.role,
  });

  @override
  List<Object?> get props => [email, password, name, phone, role];
}

class AuthSignInWithGoogleRequested extends AuthEvent {}

class AuthSignOutRequested extends AuthEvent {}

class AuthResetPasswordRequested extends AuthEvent {
  final String email;

  const AuthResetPasswordRequested({required this.email});

  @override
  List<Object> get props => [email];
}

class AuthUserChanged extends AuthEvent {
  final UserModel? user;

  const AuthUserChanged(this.user);

  @override
  List<Object?> get props => [user];
}
