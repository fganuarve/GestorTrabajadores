import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:front_end_gui/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthService _authService;

  AuthCubit({AuthService? authService})
      : _authService = authService ?? AuthService(),
        super(AuthInitial());

  Future<void> register({
    required String email,
    required String password,
    required String fullName,
    required String workplace,
    required String role,
    required String location,
    String? phoneNumber,
  }) async {
    try {
      emit(AuthLoading());
      print('Iniciando registro para: $email');
      
      final result = await _authService.register(
        email: email,
        password: password,
        fullName: fullName,
        workplace: workplace,
        role: role,
        location: location,
        phoneNumber: phoneNumber,
      );

      print('Resultado del registro: $result');

      if (result['success'] == true) {
        print('Registro exitoso');
        emit(AuthRegistered());
      } else {
        final errorMessage = result['message'] ?? 'Error desconocido';
        print('Error en el registro: $errorMessage');
        emit(AuthError(message: errorMessage));
      }
    } catch (e, stackTrace) {
      print('Error inesperado en AuthCubit.register:');
      print('Tipo: ${e.runtimeType}');
      print('Mensaje: $e');
      print('Stack trace: $stackTrace');
      emit(AuthError(message: 'Error inesperado: ${e.toString()}'));
    }
  }

  Future<void> login(String email, String password) async {
    try {
      emit(AuthLoading());
      print('Iniciando proceso de login para: $email');
      
      final result = await _authService.login(email, password);
      print('Resultado del login: $result');
      
      if (result['success'] == true) {
        final token = result['token'];
        final userData = result['user'];
        
        if (token != null && userData != null) {
          // Guardar el token y los datos del usuario en SharedPreferences
          final prefs = await SharedPreferences.getInstance();
          
          // Guardar el token de autenticación
          await prefs.setString('auth_token', token);
          
          // Guardar los datos del usuario
          if (userData['id'] != null) {
            await prefs.setString('user_id', userData['id'].toString());
          }
          
          // Guardar datos básicos del usuario
          await prefs.setString('user_name', userData['nombre']?.toString() ?? 'Usuario');
          await prefs.setString('user_last_name', userData['apellido1']?.toString() ?? '');
          await prefs.setString('user_role', userData['rol']?.toString() ?? 'user');
          
          // Guardar el email si está disponible
          if (userData['email'] != null) {
            await prefs.setString('user_email', userData['email'].toString());
          }
          
          // Guardar datos adicionales del perfil
          if (userData['telefono'] != null) {
            await prefs.setString('user_phone', userData['telefono'].toString());
          }
          if (userData['centroTrabajo'] != null) {
            await prefs.setString('user_workplace', userData['centroTrabajo'].toString());
          }
          if (userData['localidad'] != null) {
            await prefs.setString('user_location', userData['localidad'].toString());
          }
          
          print('Login exitoso. Token y datos de usuario guardados.');
          emit(AuthAuthenticated(token: token, userData: userData));
        } else {
          print('Error: Token nulo en la respuesta exitosa');
          emit(const AuthError(message: 'Error en la autenticación: token no proporcionado'));
        }
      } else {
        final errorMessage = result['message'] ?? 'Error desconocido al iniciar sesión';
        print('Error en el login: $errorMessage');
        emit(AuthError(message: errorMessage));
      }
    } catch (e, stackTrace) {
      print('Error inesperado en AuthCubit.login:');
      print('Tipo: ${e.runtimeType}');
      print('Mensaje: $e');
      print('Stack trace: $stackTrace');
      emit(AuthError(message: 'Error inesperado: ${e.toString()}'));
    }
  }

  void logout() {
    emit(AuthUnauthenticated());
  }
}
