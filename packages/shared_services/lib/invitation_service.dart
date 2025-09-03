import 'package:shared_models/shared_models.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class InvitationService {
  final String baseUrl;
  final String? authToken;

  InvitationService({
    required this.baseUrl,
    this.authToken,
  });

  Map<String, String> get _headers {
    final headers = {
      'Content-Type': 'application/json',
    };
    if (authToken != null) {
      headers['Authorization'] = 'Bearer $authToken';
    }
    return headers;
  }

  // Enviar invitación (método original)
  Future<InvitationResponse> sendInvitation({
    required String email,
    required UserRole role,
    String? customMessage,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/invitations'),
        headers: _headers,
        body: jsonEncode({
          'email': email,
          'role': _roleToString(role),
          'customMessage': customMessage,
        }),
      );

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 201) {
        return InvitationResponse(
          success: true,
          message: data['message'] ?? 'Invitación enviada correctamente',
          invitationId: data['invitationId'],
        );
      } else {
        return InvitationResponse(
          success: false,
          message: data['error'] ?? 'Error enviando invitación',
          error: data['error'],
        );
      }
    } catch (e) {
      return InvitationResponse(
        success: false,
        message: 'Error de conexión: $e',
        error: e.toString(),
      );
    }
  }

  // Crear instructor automáticamente
  Future<InvitationResponse> createInstructor({
    required String email,
    required String firstName,
    required String lastName,
    required String phone,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/invitations/create-instructor'),
        headers: _headers,
        body: jsonEncode({
          'email': email,
          'firstName': firstName,
          'lastName': lastName,
          'phone': phone,
        }),
      );

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 201) {
        return InvitationResponse(
          success: true,
          message: data['message'] ??
              'Instructor creado y email enviado correctamente',
          invitationId: data['invitationId'],
        );
      } else {
        return InvitationResponse(
          success: false,
          message: data['error'] ?? 'Error creando instructor',
          error: data['error'],
        );
      }
    } catch (e) {
      return InvitationResponse(
        success: false,
        message: 'Error de conexión: $e',
        error: e.toString(),
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
      final queryParams = <String, String>{
        'limit': limit.toString(),
        'offset': offset.toString(),
      };
      if (status != null) {
        queryParams['status'] = status;
      }

      final uri = Uri.parse('$baseUrl/api/invitations').replace(
        queryParameters: queryParams,
      );

      final response = await http.get(uri, headers: _headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final invitationsJson = data['invitations'] as List<dynamic>;

        return invitationsJson
            .map((json) =>
                InvitationModel.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        // Si hay error, retornar lista vacía en lugar de crash
        print('Error getting invitations: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Error getting invitations: $e');
      // En caso de error, retornar lista vacía
      return [];
    }
  }

  // Cancelar invitación
  Future<bool> cancelInvitation(String invitationId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/api/invitations/$invitationId'),
        headers: _headers,
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error canceling invitation: $e');
      return false;
    }
  }

  // Reenviar invitación
  Future<bool> resendInvitation(String invitationId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/invitations/$invitationId/resend'),
        headers: _headers,
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error resending invitation: $e');
      return false;
    }
  }

  // Método auxiliar para convertir UserRole a String
  String _roleToString(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return 'admin';
      case UserRole.teacher:
        return 'instructor';
      case UserRole.student:
        return 'student';
    }
  }
}
