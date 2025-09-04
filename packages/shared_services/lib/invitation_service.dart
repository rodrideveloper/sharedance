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
      print('🔑 InvitationService: Getting token with getAuthToken function');
      token = await getAuthToken!();
      print(
          '🔑 InvitationService: Token received: ${token?.substring(0, 20)}...${token?.substring(token.length - 10)}');
    } else {
      print('🔑 InvitationService: Using static authToken');
    }

    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
      print('🔑 InvitationService: Authorization header set');
    } else {
      print(
          '⚠️ InvitationService: NO TOKEN AVAILABLE - this will cause 401 error');
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
      final roleString = _roleToString(role);
      print('📤 InvitationService: Sending invitation to: $email');
      print('📤 InvitationService: Role enum: $role');
      print('📤 InvitationService: Role string: $roleString');
      print(
          '🔗 InvitationService: Using URL: $_currentBaseUrl/api/invitations/send');

      final requestBody = {
        'email': email,
        'role': roleString,
        'customMessage': customMessage ?? '',
      };

      // Debug con alert para ver exactamente qué se envía
      print('🚨 DEBUG REQUEST BODY: ${jsonEncode(requestBody)}');

      final headers = await _headers;
      print('� DEBUG HEADERS: $headers');

      final response = await http.post(
        Uri.parse('$_currentBaseUrl/api/invitations/send'),
        headers: headers,
        body: jsonEncode(requestBody),
      );

      print('📤 InvitationService: Response status: ${response.statusCode}');
      print('📤 InvitationService: Response body: ${response.body}');

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

  /// Transforma los datos del backend al formato esperado por el modelo del frontend
  Map<String, dynamic> _transformInvitationData(
      Map<String, dynamic> backendData) {
    print('🔄 Input data: $backendData');

    try {
      // Verificar campos obligatorios
      if (backendData['id'] == null || 
          backendData['email'] == null || 
          backendData['role'] == null) {
        print('❌ Missing required fields in backend data');
        throw Exception('Missing required fields: id, email, or role');
      }

      // Generar un token único si no existe
      final token = backendData['token'] ??
          'inv_${backendData['id']}_${DateTime.now().millisecondsSinceEpoch}';

      // Manejar fechas - crear DateTime si no existen
      DateTime createdAt;
      DateTime expiresAt;

      if (backendData['sentAt'] != null) {
        createdAt = DateTime.parse(backendData['sentAt']);
      } else if (backendData['createdAt'] != null) {
        createdAt = DateTime.parse(backendData['createdAt']);
      } else {
        // Si no hay fecha, usar la actual
        createdAt = DateTime.now();
      }

      if (backendData['expiresAt'] != null) {
        expiresAt = DateTime.parse(backendData['expiresAt']);
      } else {
        // Si no hay fecha de expiración, usar 30 días desde creación
        expiresAt = createdAt.add(const Duration(days: 30));
      }

      print('🔄 Dates - createdAt: $createdAt, expiresAt: $expiresAt');

      // Asegurar que invitedByUserId no sea null
      final invitedByUserId = backendData['inviterId'] ??
          backendData['invitedByUserId'] ??
          'system'; // valor por defecto si no existe

      final result = {
        'invitationId':
            backendData['id'], // Backend usa 'id', frontend espera 'invitationId'
        'email': backendData['email'],
        'role': backendData['role'],
        'token': token,
        'createdAt': createdAt.toIso8601String(), // Convertir a string ISO
        'expiresAt': expiresAt.toIso8601String(), // Convertir a string ISO  
        'isUsed': backendData['status'] ==
            'accepted', // Backend usa 'status', frontend espera 'isUsed'
        'usedByUserId': null, // No disponible en backend actual
        'usedAt': null, // No disponible en backend actual
        'invitedByUserId': invitedByUserId,
        'invitedByName':
            backendData['inviterName'] ?? backendData['invitedByName'] ?? 'System',
      };

      print('🔄 Output data: $result');
      return result;
    } catch (e) {
      print('❌ Error in _transformInvitationData: $e');
      print('❌ Backend data: $backendData');
      rethrow;
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
      print(
          '📊 InvitationService: Response body preview: ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}...');

      if (response.statusCode == 200) {
        print('🔍 Full response body: ${response.body}');
        final Map<String, dynamic> responseData = json.decode(response.body);
        print('🔍 Decoded response data: $responseData');
        final List<dynamic> data = responseData['invitations'] ?? [];
        print('🔍 Extracted invitations array: $data');
        print(
            '✅ InvitationService: Successfully fetched ${data.length} invitations');

        final List<InvitationModel> invitations = [];
        for (int i = 0; i < data.length; i++) {
          try {
            final rawInvitationData = data[i];
            print(
                '🔍 Processing invitation $i: Type: ${rawInvitationData.runtimeType}, Value: $rawInvitationData');

            if (rawInvitationData == null) {
              print('⚠️ Invitation $i is null, skipping...');
              continue;
            }

            // Transform backend data to match frontend model
            final rawInvitation = rawInvitationData as Map<String, dynamic>;
            print('🔄 Transforming invitation data for invitation $i');
            final transformedData = _transformInvitationData(rawInvitation);
            print('✨ Transformed data: $transformedData');

            final invitation = InvitationModel.fromJson(transformedData);
            invitations.add(invitation);
            print('✅ Successfully parsed invitation $i');
          } catch (e, stackTrace) {
            print('❌ Error parsing invitation $i: $e');
            print('❌ Raw data: ${data[i]}');
            print('❌ Stack trace: $stackTrace');
          }
        }

        return invitations;
      } else {
        print(
            '❌ InvitationService: Failed to fetch invitations - Status: ${response.statusCode}');
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
