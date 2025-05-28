import 'dart:convert';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:front_end_gui/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthService _authService;
  final SharedPreferences _prefs;

  AuthCubit({
    AuthService? authService,
    required SharedPreferences prefs,
  })  : _authService = authService ?? AuthService(),
        _prefs = prefs,
        super(AuthInitial()) {
    // Check if user is already logged in
    _checkAuthStatus();
  }
  
  void _checkAuthStatus() {
    final token = _prefs.getString('auth_token');
    final userData = _prefs.getString('user_data');
    
    if (token != null && userData != null) {
      try {
        final userMap = Map<String, dynamic>.from(jsonDecode(userData));
        emit(AuthAuthenticated(
          token: token,
          userData: userMap,
        ));
      } catch (e) {
        debugPrint('Error parsing user data: $e');
        emit(AuthUnauthenticated());
      }
    } else {
      emit(AuthUnauthenticated());
    }
  }

  Future<void> register({
    required String email,
    required String password,
    required String fullName,
    required String workplace,
    required String role, // Se mantiene como 'role' para el backend
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
        role: role, // Se envía como 'role' al backend
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
      debugPrint('Iniciando proceso de login para: $email');
      
      final result = await _authService.login(email, password);
      debugPrint('Resultado del login: $result');
      
      if (result['success'] == true) {
        final token = result['token'];
        final userData = result['user'];
        
        if (token != null && userData != null) {
          // Convertir userData a Map si es necesario
          final userMap = userData is Map<String, dynamic> 
              ? userData 
              : Map<String, dynamic>.from(userData as Map);
          
          // Guardar el token y los datos del usuario en SharedPreferences
          await _prefs.setString('auth_token', token);
          await _prefs.setString('user_data', jsonEncode(userMap));
          
          debugPrint('Datos de usuario guardados correctamente');
          
          // Emitir estado autenticado con los datos del usuario
          emit(AuthAuthenticated(
            token: token,
            userData: userMap,
          ));
          
          // Los datos ya se guardaron en SharedPreferences
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

  Future<void> signOut() async {
    try {
      emit(AuthLoading());
      // Limpiar cualquier dato de sesión local
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
      await prefs.remove('user_id');
      await prefs.remove('user_name');
      await prefs.remove('user_last_name');
      await prefs.remove('user_role');
      await prefs.remove('user_email');
      await prefs.remove('user_phone');
      await prefs.remove('user_workplace');
      await prefs.remove('user_location');
      
      // Emitir estado de no autenticado
      emit(AuthUnauthenticated());
    } catch (e) {
      print('Error al cerrar sesión: $e');
      emit(AuthError(message: 'Error al cerrar la sesión'));
    }
  }
  
  // Método obsoleto, mantener para compatibilidad
  @Deprecated('Use signOut() instead')
  void logout() {
    signOut();
  }
}
