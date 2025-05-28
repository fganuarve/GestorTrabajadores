import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:front_end_gui/models/carpool_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class CarpoolService {
  // Usar localhost para desarrollo local
  static const String baseUrl = 'http://localhost:8080/viaje'; // Usando localhost para desarrollo
  final SharedPreferences prefs;

  CarpoolService({required this.prefs});

  // Método auxiliar para obtener los headers con el token de autenticación
  Future<Map<String, String>> _getHeaders() async {
    try {
      final token = prefs.getString('auth_token') ?? '';
      if (token.isEmpty) {
        throw Exception('No se encontró el token de autenticación');
      }
      
      return {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      };
    } catch (e) {
      print('Error al obtener los headers: $e');
      rethrow;
    }
  }

  // Obtiene la lista de viajes disponibles para una fecha específica
  Future<List<Carpool>> getAvailableCarpools(DateTime date) async {
    try {
      // Formatear la fecha como 'yyyy-MM-dd' para la API
      final formattedDate = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      
      // Construir la URL con los parámetros de consulta
      final url = Uri.parse('$baseUrl/disponibles').replace(
        queryParameters: {
          'fecha': formattedDate,
        },
      );

      print('🔍 Buscando viajes disponibles para la fecha: $formattedDate');
      print('URL de la petición: ${url.toString()}');

      final headers = await _getHeaders();
      
      // Realizar la petición GET con timeout
      final response = await http.get(url, headers: headers).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw TimeoutException('La solicitud ha tardado demasiado tiempo');
        },
      );

      print('Respuesta del servidor: ${response.statusCode}');
      print('Cuerpo de la respuesta: ${response.body}');

      // Handle 404 as a valid case (no carpools available)
      if (response.statusCode == 404) {
        print('No se encontraron viajes disponibles (404)');
        return [];
      }

      // Handle other error statuses
      if (response.statusCode != 200) {
        String errorMessage;
        try {
          final errorData = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
          errorMessage = errorData['message'] ?? 'Error al obtener los viajes disponibles';
          print('Error del servidor: $errorMessage');
        } catch (e) {
          errorMessage = 'Error en el servidor (${response.statusCode}): ${response.body}';
          print('Error al procesar el mensaje de error: $e');
        }
        throw Exception(errorMessage);
      }

      // Process successful response
      final dynamic responseData = jsonDecode(utf8.decode(response.bodyBytes));
      List<dynamic> carpoolsList = [];

      // Handle different response formats
      if (responseData is List) {
        carpoolsList = responseData;
      } else if (responseData is Map) {
        if (responseData['data'] is List) {
          carpoolsList = responseData['data'];
        } else if (responseData['data'] is Map) {
          carpoolsList = [responseData['data']];
        } else if (responseData.isNotEmpty) {
          carpoolsList = [responseData];
        }
      }

      // Mapear cada elemento de la lista a un objeto Carpool
      final result = carpoolsList.map<Carpool>((carpool) {
        try {
          return Carpool.fromJson(carpool is Map<String, dynamic> ? carpool : carpool as Map<String, dynamic>);
        } catch (e, stackTrace) {
          print('Error al parsear el viaje: $e');
          print('Stack trace: $stackTrace');
          print('Datos del viaje con error: $carpool');
          rethrow;
        }
      }).toList();
      
      print('✅ Viajes procesados exitosamente: ${result.length}');
      return result;
      
    } on TimeoutException catch (e) {
      print('⏱️ Timeout al obtener los viajes: $e');
      throw Exception('La solicitud ha tardado demasiado tiempo. Por favor, verifica tu conexión e inténtalo de nuevo.');
    } catch (e, stackTrace) {
      print('❌ Error en getAvailableCarpools: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  // Crea un nuevo viaje compartido
  Future<Carpool> createCarpool({
    required String driverId,
    required String driverName,
    required DateTime date,
    required TimeOfDay time,
    required String origin,
    required String destination,
    required int availableSeats,
    String? notes,
  }) async {
    try {
      // Validar que el ID del conductor no sea nulo o vacío
      if (driverId.isEmpty) {
        throw Exception('El ID del conductor no puede estar vacío');
      }

      // Validar que el ID del conductor sea un número válido
      final int? parsedDriverId = int.tryParse(driverId);
      if (parsedDriverId == null) {
        throw Exception('El ID del conductor debe ser un número válido');
      }

      // Validar campos requeridos
      if (origin.isEmpty || destination.isEmpty) {
        throw Exception('El origen y el destino son requeridos');
      }

      if (availableSeats <= 0) {
        throw Exception('El número de plazas disponibles debe ser mayor a cero');
      }

      // Formatear la fecha y hora en el formato que espera el backend
      final fechaHoraSalida = '${date.toIso8601String().split('T')[0]}T${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:00';
      
      developer.log('Creando viaje con datos:', error: {
        'idConductor': parsedDriverId,
        'fechaSalida': fechaHoraSalida,
        'origen': origin,
        'destino': destination,
        'plazasDisponibles': availableSeats,
        'notas': notes ?? '',
        'estado': 'PENDIENTE',
      });
      
      // Crear el objeto de solicitud según lo esperado por el backend
      final requestBody = {
        'idConductor': parsedDriverId,  // Asegurarse de que es un número
        'idVehiculo': 1,  // Valor temporal, deberías obtenerlo del usuario o de otra fuente
        'origen': origin,
        'destino': destination,
        'fechaSalida': fechaHoraSalida,
        'horaSalida': fechaHoraSalida,  // Misma fecha y hora para simplificar
        'plazas': availableSeats,
        'notas': notes ?? '',
        'activo': true,
      };
      
      // Log detallado de la petición
      print('Enviando petición a $baseUrl/crear');
      print('Headers: ${await _getHeaders()}');
      print('Body: ${jsonEncode(requestBody)}');
      
      try {
        final response = await http.post(
          Uri.parse('$baseUrl/crear'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            ...await _getHeaders(),
          },
          body: jsonEncode(requestBody),
        );

        // Mostrar la respuesta completa para depuración
        developer.log('Respuesta completa del servidor:', error: {
          'statusCode': response.statusCode,
          'headers': response.headers,
          'body': response.body,
        });

        // Manejar códigos de estado
        if (response.statusCode == 401) {
          throw Exception('Sesión expirada. Por favor, inicia sesión nuevamente.');
        }

        // Intentar decodificar la respuesta
        try {
          final responseData = jsonDecode(response.body);
          
          if (response.statusCode == 201 || response.statusCode == 200) {
            return Carpool.fromJson(responseData is Map<String, dynamic> ? responseData : {});
          } else {
            final errorMsg = responseData is Map 
                ? responseData['message'] ?? 'Error desconocido'
                : 'Error en el servidor';
            developer.log('Error del servidor: $errorMsg');
            throw Exception('Error al crear el viaje: $errorMsg');
          }
        } catch (e) {
          print('Error al procesar la respuesta: $e');
          throw Exception('Error al procesar la respuesta del servidor: ${e.toString()}');
        }
      } on http.ClientException catch (e) {
        print('Error de conexión: $e');
        throw Exception('Error de conexión: ${e.message}');
      } on FormatException catch (e) {
        print('Error de formato en la respuesta: $e');
        throw Exception('Error en el formato de la respuesta del servidor');
      } catch (e) {
        print('Error inesperado: $e');
        rethrow;
      }
    } catch (e) {
      print('Error al crear el viaje: $e');
      rethrow;
    }
  }

  // Permite a un usuario unirse a un viaje existente
  Future<void> joinCarpool(String carpoolId, String userId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/$carpoolId/unirse'),
        headers: headers,
        body: jsonEncode({'userId': userId}),
      );

      if (response.statusCode != 200) {
        throw Exception('Error al unirse al viaje: ${response.statusCode}');
      }
    } catch (e) {
      print('Error al unirse al viaje: $e');
      rethrow;
    }
  }

  // Permite a un usuario abandonar un viaje
  Future<void> leaveCarpool(String carpoolId, String userId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/$carpoolId/abandonar'),
        headers: headers,
        body: jsonEncode({'userId': userId}),
      );

      if (response.statusCode != 200) {
        throw Exception('Error al abandonar el viaje: ${response.statusCode}');
      }
    } catch (e) {
      print('Error al abandonar el viaje: $e');
      rethrow;
    }
  }

  // Obtiene la lista de viajes de un usuario específico
  Future<List<Carpool>> getUserCarpools(String userId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/usuario/$userId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        
        // Manejar diferentes formatos de respuesta
        if (responseData is List) {
          return responseData.map<Carpool>((json) => Carpool.fromJson(json)).toList();
        } else if (responseData is Map && responseData['data'] is List) {
          final data = responseData['data'] as List;
          return data.map<Carpool>((json) => Carpool.fromJson(json)).toList();
        } else {
          throw Exception('Formato de respuesta inesperado');
        }
      } else if (response.statusCode == 404) {
        return []; // No se encontraron viajes
      } else {
        throw Exception('Error al obtener los viajes del usuario: ${response.statusCode}');
      }
    } catch (e) {
      print('Error al obtener los viajes del usuario: $e');
      rethrow;
    }
  }
}
