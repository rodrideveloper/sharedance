import 'package:equatable/equatable.dart';

class InvitationResponse extends Equatable {
  final bool success;
  final String message;
  final String? invitationId;
  final String? error;

  const InvitationResponse({
    required this.success,
    required this.message,
    this.invitationId,
    this.error,
  });

  factory InvitationResponse.fromJson(Map<String, dynamic> json) {
    return InvitationResponse(
      success: json['success'] as bool,
      message: json['message'] as String,
      invitationId: json['invitationId'] as String?,
      error: json['error'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'invitationId': invitationId,
      'error': error,
    };
  }

  @override
  List<Object?> get props => [success, message, invitationId, error];
}
