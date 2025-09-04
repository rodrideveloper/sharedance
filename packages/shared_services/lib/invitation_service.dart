import 'package:shared_models/shared_models.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class InvitationService {
  final String? baseUrl;
  final String? authToken;
  final Future<String?> Function()? getAuthToken;
  final String Function()? getBaseUrl;

  InvitationService({
    this.baseUrl,
    this.authToken,
    this.getAuthToken,
    this.getBaseUrl,
  });

  String get _currentBaseUrl {
    // If getBaseUrl function is provided, use it to get dynamic baseUrl
    if (getBaseUrl != null) {
      final dynamicUrl = getBaseUrl!();
      print('🔗 InvitationService: Using dynamic baseUrl: $dynamicUrl');
      return dynamicUrl;
    }
    
    // Fallback to static baseUrl
    if (baseUrl != null) {
      print('🔗 InvitationService: Using static baseUrl: $baseUrl');
      return baseUrl!;
    }
    
    throw Exception('No baseUrl provided to InvitationService');
  }

  Future<Map<String, String>> get _headers async {
    final headers = {
      'Content-Type': 'application/json',
    };

    // Usar getAuthToken si está disponible, sino usar authToken
    String? token = authToken;
    if (getAuthToken != null) {
      token = await getAuthToken!();
    }

    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
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
      print('📤 InvitationService: Sending invitation to: $email');
      print('🔗 InvitationService: Using URL: $_currentBaseUrl/api/invitations/send');
      
      final response = await http.post(
        Uri.parse('$_currentBaseUrl/api/invitations/send'),
        headers: await _headers,
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
        Uri.parse('$_currentBaseUrl/api/invitations/create-instructor'),
        headers: await _headers,
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

  /// Obtiene todas las invitaciones
  Future<List<InvitationModel>> getInvitations() async {
    try {
      final url = '$_currentBaseUrl/api/invitations';
      print('🔗 InvitationService: Fetching invitations from: $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: await _headers,
      );

      print('📊 InvitationService: Response status: ${response.statusCode}');
      print('📊 InvitationService: Response body preview: ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}...');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        print('✅ InvitationService: Successfully fetched ${data.length} invitations');
        
        final List<InvitationModel> invitations = [];
        for (int i = 0; i < data.length; i++) {
          try {
            final invitation = InvitationModel.fromJson(data[i]);
            invitations.add(invitation);
          } catch (e) {
            print('❌ Error parsing invitation $i: $e');
            print('❌ Raw data: ${data[i]}');
          }
        }
        
        return invitations;
      } else {
        print('❌ InvitationService: Failed to fetch invitations - Status: ${response.statusCode}');
        print('❌ InvitationService: Response body: ${response.body}');
        throw Exception('Failed to load invitations: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      print('❌ InvitationService: Exception in getInvitations: $e');
      print('❌ Stack trace: $stackTrace');
      throw Exception('Error fetching invitations: $e');
    }
  }

  // Cancelar invitación
  Future<bool> cancelInvitation(String invitationId) async {
    try {
      final response = await http.delete(
        Uri.parse('$_currentBaseUrl/api/invitations/$invitationId'),
        headers: await _headers,
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
        Uri.parse('$_currentBaseUrl/api/invitations/$invitationId/resend'),
        headers: await _headers,
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
        return 'Admin';
      case UserRole.teacher:
        return 'Teacher'; // Mayúscula para coincidir con backend
      case UserRole.student:
        return 'Student';
    }
  }
}
