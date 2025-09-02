import 'package:shared_models/shared_models.dart';

class InvitationService {
  final String baseUrl;
  final String? authToken;

  InvitationService({
    required this.baseUrl,
    this.authToken,
  });

  // Enviar invitación
  Future<InvitationResponse> sendInvitation({
    required String email,
    required UserRole role,
    String? customMessage,
  }) async {
    try {
      // En un caso real, aquí harías una petición HTTP al backend
      // Por ahora simulamos la respuesta

      await Future.delayed(const Duration(seconds: 2)); // Simular delay de red

      // Simular respuesta exitosa
      return InvitationResponse(
        success: true,
        message: 'Invitación enviada correctamente',
        invitationId: 'inv_${DateTime.now().millisecondsSinceEpoch}',
      );
    } catch (e) {
      return InvitationResponse(
        success: false,
        message: 'Error enviando invitación: $e',
      );
    }
  }

  // Obtener lista de invitaciones
  Future<List<InvitationModel>> getInvitations({
    String? status,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      await Future.delayed(const Duration(seconds: 1));

      // Datos simulados para desarrollo
      return [
        InvitationModel(
          invitationId: '1',
          email: 'profesor@ejemplo.com',
          role: UserRole.teacher,
          token: 'token123',
          createdAt: DateTime.now().subtract(const Duration(hours: 2)),
          expiresAt: DateTime.now().add(const Duration(days: 7)),
          isUsed: false,
          invitedByUserId: 'admin-id',
          invitedByName: 'Admin User',
        ),
        InvitationModel(
          invitationId: '2',
          email: 'estudiante@ejemplo.com',
          role: UserRole.student,
          token: 'token456',
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
          expiresAt: DateTime.now().add(const Duration(days: 6)),
          isUsed: true,
          usedAt: DateTime.now().subtract(const Duration(hours: 12)),
          usedByUserId: 'student-id',
          invitedByUserId: 'admin-id',
          invitedByName: 'Admin User',
        ),
      ];
    } catch (e) {
      throw Exception('Error obteniendo invitaciones: $e');
    }
  }

  // Cancelar invitación
  Future<bool> cancelInvitation(String invitationId) async {
    try {
      await Future.delayed(const Duration(seconds: 1));
      return true;
    } catch (e) {
      return false;
    }
  }

  // Reenviar invitación
  Future<bool> resendInvitation(String invitationId) async {
    try {
      await Future.delayed(const Duration(seconds: 1));
      return true;
    } catch (e) {
      return false;
    }
  }
}

class InvitationResponse {
  final bool success;
  final String message;
  final String? invitationId;
  final String? error;

  InvitationResponse({
    required this.success,
    required this.message,
    this.invitationId,
    this.error,
  });
}
