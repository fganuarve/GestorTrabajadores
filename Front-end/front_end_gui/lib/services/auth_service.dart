import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthService {
  // Usando la IP local de la máquina (obtenida con ipconfig)
  static const String _baseUrl = 'http://192.168.1.40:8080';
  
  final http.Client _client;
  
  AuthService({http.Client? client}) : _client = client ?? http.Client();
  
  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String fullName,
    required String workplace,
    required String role,
    required String location,
    String? phoneNumber,
  }) async {
    try {
      // Normalizar el rol a mayúsculas y sin tildes
      final normalizedRole = role.toUpperCase()
          .replaceAll('Á', 'A')
          .replaceAll('É', 'E')
          .replaceAll('Í', 'I')
          .replaceAll('Ó', 'O')
          .replaceAll('Ú', 'U');
          
      print('Enviando registro a: $_baseUrl/user/create');
      print('Datos del registro:');
      print('- Email: $email');
      print('- Rol: $normalizedRole');
      
      final requestData = {
        'email': email,
        'password': password,
        'fullName': fullName,
        'workplace': workplace,
        'role': normalizedRole,
        'location': location,
        if (phoneNumber != null && phoneNumber.isNotEmpty) 'phoneNumber': phoneNumber,
      };
      
      print('Datos completos: $requestData');
      
      // Crear el objeto de solicitud que coincide exactamente con CrearUsuarioRequest en el backend
      final requestBody = {
        'email': email,
        'password': password,
        'nombre': fullName,
        'apellido1': 'Apellido1',  // Campo requerido por el backend
        'apellido2': '',           // Campo opcional
        'telefono': phoneNumber ?? '',
        'centroTrabajo': workplace,  // Nota: centroTrabajo (camelCase) no centro_trabajo
        'puesto': normalizedRole,   // Asegurarse de que coincida con el enum Puesto en el backend
        'localidad': location,
        'preferenciasHorarias': '',  // Campo requerido
        'disponibilidadHorasExtras': false,  // Valor por defecto
        'rol': 'user',  // Forzamos que sea un usuario normal
        'activo': true,  // Por defecto activo
      };
      
      print('Enviando petición a: $_baseUrl/user/create');
      print('Cuerpo de la petición: $requestBody');
      
      final response = await _client.post(
        Uri.parse('$_baseUrl/user/create'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(requestBody),
      );
      
      print('Respuesta del servidor:');
      print('Código de estado: ${response.statusCode}');
      print('Cuerpo: ${response.body}');
      
      try {
        final responseData = jsonDecode(response.body);
        
        if (response.statusCode == 200 && responseData['success'] == true) {
          // Registro exitoso
          print('Usuario registrado con éxito');
          return {'success': true};
        } else {
          // Error en el registro
          final errorMessage = responseData['error']?['message'] ?? 'Error en el registro';
          print('Error en la respuesta: $errorMessage');
          return {'success': false, 'message': errorMessage};
        }
      } catch (e) {
        print('Error al decodificar la respuesta: $e');
        return {'success': false, 'message': 'Error al procesar la respuesta del servidor'};
      }
    } catch (e, stackTrace) {
      print('Error en register:');
      print('Tipo: ${e.runtimeType}');
      print('Mensaje: $e');
      print('Stack trace: $stackTrace');
      
      String errorMessage = 'Error de conexión. Inténtalo de nuevo.';
      if (e is FormatException) {
        errorMessage = 'Error de formato en la respuesta del servidor';
      } else if (e is ArgumentError) {
        errorMessage = 'Error en los argumentos de la petición';
      } else if (e is Exception) {
        errorMessage = 'Error: ${e.toString()}';
      }
      
      return {'success': false, 'message': errorMessage};
    } finally {
      _client.close();
    }
  }
  
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      print('Iniciando sesión para: $email');
      print('URL de login: $_baseUrl/login');
      
      final response = await _client.post(
        Uri.parse('$_baseUrl/login'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'username': email,
          'password': password,
        }),
      );
      
      print('Respuesta del servidor:');
      print('Código de estado: ${response.statusCode}');
      print('Cabeceras: ${response.headers}');
      print('Cuerpo: ${response.body}');
      
      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body);
          
          // Verificar si el token está en la cabecera
          final token = response.headers['authorization'] ?? 
                       response.headers['Authorization'];
          
          if (token != null) {
            print('Token JWT recibido en la cabecera');
            return {
              'success': true, 
              'token': token.replaceAll('Bearer ', ''),
              'user': data['data']
            };
          } 
          // Si no está en la cabecera, verificar si está en el cuerpo
          else if (data['token'] != null) {
            print('Token JWT recibido en el cuerpo de la respuesta');
            return {
              'success': true, 
              'token': data['token'],
              'user': data['data']
            };
          } 
          // Si no hay token en ningún lado pero la respuesta es exitosa
          // y tiene datos de usuario, asumimos que la autenticación fue exitosa
          else if (data['success'] == true && data['data'] != null) {
            print('Inicio de sesión exitoso sin token JWT');
            // Usamos un token local para mantener la sesión
            final userId = data['data']['id']?.toString() ?? '';
            final userEmail = data['data']['email']?.toString() ?? '';
            final token = 'local_token_${userId}_${userEmail}';
            
            print('Token local generado: $token');
            return {
              'success': true,
              'token': token,
              'user': data['data']
            };
          } 
          else {
            print('Error: No se recibió token ni datos de usuario en la respuesta');
            return {
              'success': false, 
              'message': 'Error en la respuesta del servidor: No se recibieron credenciales válidas'
            };
          }
        } catch (e) {
          print('Error al decodificar la respuesta: $e');
          return {'success': false, 'message': 'Error al procesar la respuesta del servidor'};
        }
      } else {
        String errorMessage = 'Error en el inicio de sesión';
        try {
          final errorData = jsonDecode(response.body);
          errorMessage = errorData['message'] ?? errorData['error'] ?? errorMessage;
          print('Error en la respuesta: $errorMessage');
        } catch (e) {
          print('Error al decodificar el mensaje de error: $e');
        }
        return {'success': false, 'message': errorMessage};
      }
    } catch (e, stackTrace) {
      print('Error en login:');
      print('Tipo: ${e.runtimeType}');
      print('Mensaje: $e');
      print('Stack trace: $stackTrace');
      
      String errorMessage = 'Error de conexión. Inténtalo de nuevo.';
      if (e is FormatException) {
        errorMessage = 'Error de formato en la respuesta del servidor';
      } else if (e is ArgumentError) {
        errorMessage = 'Error en los argumentos de la petición';
      }
      
      return {'success': false, 'message': errorMessage};
    } finally {
      _client.close();
    }
  }
}
