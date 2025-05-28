import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:formz/formz.dart';
import 'package:front_end_gui/config/api_config.dart';
import 'package:front_end_gui/views/infraestructure/inputs/inputs.dart';
import 'package:http/http.dart' as http;
import 'dart:convert'; // Para convertir el JSON
import 'dart:developer';
part 'RegisterState.dart';


/// Clase RegisterLoginCubit, en donde vamos a desarrollar los métodos de la validación
class RegisterCubit extends Cubit<RegisterState> {
  RegisterCubit() : super(RegisterState());

 

  // Métodos en el cubic de las variables del formulario
  Future<bool> onSubmit() async {
    log('Estado actual formulario al enviarlo, antes de emitir emit -> ${state.formStatus}');
    log('Enviando formulario... datos -> email: ${state.email.value}, contraseña: ${state.password.value}');
    
    emit(state.copyWith(
      formStatus: FormStatus.validating,
      email: GmailInput.dirty(value: state.email.value),
      password: PasswordLoginInput.dirty(value: state.password.value),
      isValid: Formz.validate([state.email, state.password])
    ));

    final client = http.Client();
    const timeout = Duration(seconds: 30);
    
    try {
      // Usar la URL de la configuración de la API
      final loginUrl = Uri.parse(ApiConfig.login);
      log('🔄 Intentando conectar a: $loginUrl');
      
      final requestData = {
        'username': state.email.value,
        'password': state.password.value
      };
      
      log('📤 Enviando credenciales de inicio de sesión...');
      
      try {
        final response = await client.post(
          loginUrl,
          headers: {
            'Content-Type': 'application/json; charset=UTF-8',
            'Accept': 'application/json',
            'Connection': 'keep-alive',
          },
          body: jsonEncode(requestData),
        ).timeout(timeout);
        
        log('✅ Respuesta recibida - Código: ${response.statusCode}');
        log('📝 Cuerpo de la respuesta: ${response.body}');
        
        if (response.statusCode == 200) {
          log('✅ Inicio de sesión exitoso');
          emit(state.copyWith(formStatus: FormStatus.valid));
          return true;
        } else {
          log('❌ Error en la autenticación -> ${response.statusCode}');
          log('📝 Detalles del error: ${response.body}');
          emit(state.copyWith(formStatus: FormStatus.failHttp));
          return false;
        }
      } on http.ClientException catch (e) {
        log('❌ Error de conexión: $e');
        emit(state.copyWith(formStatus: FormStatus.failHttp));
        return false;
      } on Exception catch (e) {
        log('❌ Error inesperado: $e');
        emit(state.copyWith(formStatus: FormStatus.failHttp));
        return false;
      }
    } catch (e, stackTrace) {
      log('❌ Error inesperado durante el inicio de sesión: $e');
      log('Stack trace: $stackTrace');
      emit(state.copyWith(formStatus: FormStatus.failHttp));
      return false;
    } finally {
      client.close();
      log('🔌 Cliente HTTP cerrado');
    }
  }

  void emailChanged(String value){
    final emailNewValue = GmailInput.dirty(value: value);
    emit( // Función utilizada en Cubit para notificar a Flutter de que el estado ha cambiado

      state.copyWith( // Crea nueva instancia manteniendo el estado anterior y solo cambia el campo email
        email: emailNewValue,
        isValid: Formz.validate([emailNewValue, state.password]), // Se le envía todos los campos porque necesita saber si son todos validos
        //icono: state.isValid ? Icons.check : Icons.error,
      )
    );
  }

  void passwordChanged(String value){
    final passwordNewValue = PasswordLoginInput.dirty(value: value);

    emit(

      state.copyWith(
        password: passwordNewValue,
        isValid: Formz.validate([state.email, passwordNewValue]),
        //icono: state.isValid ? Icons.check : Icons.error,
      )
    );
  }
}
