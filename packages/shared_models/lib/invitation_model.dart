import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'user_model.dart';

part 'invitation_model.g.dart';

@JsonSerializable()
class InvitationModel extends Equatable {
  final String invitationId;
  final String email;
  final UserRole role;
  final String token;
  final DateTime createdAt;
  final DateTime expiresAt;
  final bool isUsed;
  final String? usedByUserId;
  final DateTime? usedAt;
  final String invitedByUserId;
  final String? invitedByName;

  const InvitationModel({
    required this.invitationId,
    required this.email,
    required this.role,
    required this.token,
    required this.createdAt,
    required this.expiresAt,
    required this.isUsed,
    this.usedByUserId,
    this.usedAt,
    required this.invitedByUserId,
    this.invitedByName,
  });

  factory InvitationModel.fromJson(Map<String, dynamic> json) =>
      _$InvitationModelFromJson(json);

  Map<String, dynamic> toJson() => _$InvitationModelToJson(this);

  InvitationModel copyWith({
    String? invitationId,
    String? email,
    UserRole? role,
    String? token,
    DateTime? createdAt,
    DateTime? expiresAt,
    bool? isUsed,
    String? usedByUserId,
    DateTime? usedAt,
    String? invitedByUserId,
    String? invitedByName,
  }) {
    return InvitationModel(
      invitationId: invitationId ?? this.invitationId,
      email: email ?? this.email,
      role: role ?? this.role,
      token: token ?? this.token,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      isUsed: isUsed ?? this.isUsed,
      usedByUserId: usedByUserId ?? this.usedByUserId,
      usedAt: usedAt ?? this.usedAt,
      invitedByUserId: invitedByUserId ?? this.invitedByUserId,
      invitedByName: invitedByName ?? this.invitedByName,
    );
  }

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool get isValid => !isUsed && !isExpired;

  @override
  List<Object?> get props => [
    invitationId,
    email,
    role,
    token,
    createdAt,
    expiresAt,
    isUsed,
    usedByUserId,
    usedAt,
    invitedByUserId,
    invitedByName,
  ];
}
