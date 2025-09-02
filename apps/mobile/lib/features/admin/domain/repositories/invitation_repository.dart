import 'package:shared_models/shared_models.dart';

abstract class InvitationRepository {
  /// Envía una invitación por email
  Future<InvitationModel> sendInvitation({
    required String email,
    required UserRole role,
    String? customMessage,
  });

  /// Obtiene todas las invitaciones
  Future<List<InvitationModel>> getInvitations();

  /// Obtiene invitaciones pendientes
  Future<List<InvitationModel>> getPendingInvitations();

  /// Valida un token de invitación
  Future<InvitationModel?> validateInvitationToken(String token);

  /// Marca una invitación como usada
  Future<void> markInvitationAsUsed(String invitationId, String userId);

  /// Cancela una invitación
  Future<void> cancelInvitation(String invitationId);

  /// Reenvía una invitación
  Future<void> resendInvitation(String invitationId);
}
