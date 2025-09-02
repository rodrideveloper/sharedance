import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'user_model.g.dart';

enum UserRole {
  @JsonValue('student')
  student,
  @JsonValue('teacher')
  teacher,
  @JsonValue('admin')
  admin,
}

@JsonSerializable()
class UserModel extends Equatable {
  final String userId;
  final String name;
  final String email;
  final String? phone;
  final UserRole role;
  final int credits;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? profileImageUrl;
  final bool isActive;
  final bool isEmailVerified;
  final DateTime? lastLoginAt;

  const UserModel({
    required this.userId,
    required this.name,
    required this.email,
    this.phone,
    required this.role,
    required this.credits,
    required this.createdAt,
    this.updatedAt,
    this.profileImageUrl,
    this.isActive = true,
    this.isEmailVerified = false,
    this.lastLoginAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);

  Map<String, dynamic> toJson() => _$UserModelToJson(this);

  UserModel copyWith({
    String? userId,
    String? name,
    String? email,
    String? phone,
    UserRole? role,
    int? credits,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? profileImageUrl,
    bool? isActive,
    bool? isEmailVerified,
    DateTime? lastLoginAt,
  }) {
    return UserModel(
      userId: userId ?? this.userId,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      credits: credits ?? this.credits,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      isActive: isActive ?? this.isActive,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
    );
  }

  @override
  List<Object?> get props => [
    userId,
    name,
    email,
    phone,
    role,
    credits,
    createdAt,
    updatedAt,
    profileImageUrl,
    isActive,
    isEmailVerified,
    lastLoginAt,
  ];
}
