import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'package:front_end_gui/config/api_config.dart';
import 'package:front_end_gui/models/shift_model.dart';

class ShiftService {
  final String _baseUrl = ApiConfig.apiBaseUrl;
  final String? _authToken;

  ShiftService(this._authToken);

  // Formatear fecha a string en formato YYYY-MM-DD
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  // Obtener los turnos de un usuario para un rango de fechas
  Future<List<ShiftModel>> getUserShifts({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/shifts/user/$userId')
          .replace(queryParameters: {
        'startDate': _formatDate(startDate),
        'endDate': _formatDate(endDate),
      });

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_authToken',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = jsonDecode(response.body);
        return jsonData.map((json) => ShiftModel.fromJson(json)).toList();
      } else {
        log('Error al obtener los turnos: ${response.statusCode} - ${response.body}');
        throw Exception('Error al cargar los turnos');
      }
    } catch (e) {
      log('Error en getUserShifts: $e');
      rethrow;
    }
  }

  // Obtener el perfil del usuario actual
  Future<Map<String, dynamic>> getUserProfile(String userId) async {
    try {
      final url = Uri.parse('${ApiConfig.apiBaseUrl}/user/$userId');
      
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_authToken',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        log('Error al obtener el perfil: ${response.statusCode} - ${response.body}');
        throw Exception('Error al cargar el perfil del usuario');
      }
    } catch (e) {
      log('Error en getUserProfile: $e');
      rethrow;
    }
  }
}
