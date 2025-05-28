import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:formz/formz.dart';
import 'package:front_end_gui/views/cubit/SignUpCubit.dart';
import 'package:front_end_gui/views/cubit/SignUpState2.dart';
import 'package:front_end_gui/views/infraestructure/inputs/disponibilidadHorasExtras.dart';
import 'package:front_end_gui/views/infraestructure/inputs/inputs.dart';
import 'package:front_end_gui/views/infraestructure/inputs/multiInput.dart';
import 'package:front_end_gui/views/infraestructure/inputs/dropDwonPuesto.dart';
import 'package:front_end_gui/views/infraestructure/inputs/preferenciasRadioButton.dart';
import 'package:http/http.dart' as http;

/// Clase RegisterLoginCubit, en donde vamos a desarrollar los métodos de la validación
class SignUpCubit2 extends Cubit<SignUpState2> {
  SignUpCubit2() : super(SignUpState2(isValid2: false));

  void setValidState(bool isValid2) {
    emit(state.copyWith(isValid2: isValid2));
  }

  void setValidState3(bool isValid3) {
    emit(state.copyWith(isValid3: isValid3));
  }

  void onSubmit2(int partOfForm) {
    
    if(partOfForm == 0){
      log('---> Validación formulario 2/3 realizada');
      emit(
      state.copyWith(
        formStatus2: FormStatus.validating,
        centroDeTrabajo: MultiInput.dirty(value: state.centroDeTrabajo.value),
        puesto: DropDownPuesto.dirty(value: state.puesto.value),
        localidad: MultiInput.dirty(value: state.localidad.value),
        preferenciasHorarias: PreferenciasRadioButton.dirty(value: state.preferenciasHorarias.value),
        disponibilidadHorasExtras:  DisponibilidadHorasExtras.dirty(value: state.disponibilidadHorasExtras.value),
        
        isValid2: Formz.validate([
          state.centroDeTrabajo,
          state.puesto,
          state.localidad,
          state.preferenciasHorarias,
          state.disponibilidadHorasExtras,
        ]),
      )
      );
    } 
  }

  Future<bool> onSubmit3(int partOfForm, BuildContext context) async {
    log('---> Validación formulario 3/3 realizada');
    emit(
      state.copyWith(
        formStatus3: FormStatus3.validating,
        isValid3: Formz.validate([state.password]),
      ),
    );

    try {
      await sendHttpPost(context);
      return true; // Éxito
    } catch (e) {
      log('Error en onSubmit3: $e');
      rethrow; // Relanzamos el error para manejarlo en la UI
    }
  }

  Future<void> sendHttpPost(BuildContext context) async { 
    log('*** Iniciando envío de datos al servidor ***');
    final client = http.Client();
    const timeout = Duration(seconds: 30);
    
    try {
      // Obtener el cubit del primer formulario para acceder a sus datos
      final signUpCubit = BlocProvider.of<SignUpCubit>(context);
      
      // Configuración de las URLs a probar
      final urlsToTry = [
        'http://10.0.2.2:8080',    // Para emulador Android
        'http://localhost:8080',   // Para web/desktop
        'http://127.0.0.1:8080',   // Alternativa local
      ];
      
      // Construir los datos del usuario una sola vez
      final userData = _buildUserData(signUpCubit);
      
      log('------ DATOS A ENVIAR AL BACK-END -----');
      log('Datos del usuario: ${jsonEncode(userData)}');
      log('--------------------------------------');
      
      // Probar cada URL hasta que una funcione
      http.Response? response;
      String? lastError;
      
      for (final baseUrl in urlsToTry) {
        try {
          final endpoint = '/user/create';
          final url = Uri.parse('$baseUrl$endpoint');
          
          log('🔄 Intentando conectar a: $url');
          log('Método: POST');
          log('Headers: {Content-Type: application/json, Accept: application/json}');
          log('📤 Enviando petición HTTP POST...');
          
          // Realizar la petición HTTP
          response = await client.post(
            url,
            headers: {
              'Content-Type': 'application/json; charset=UTF-8',
              'Accept': 'application/json',
              'Connection': 'keep-alive',
            },
            body: jsonEncode(userData),
          ).timeout(timeout);
          
          log('✅ Conexión exitosa a: $url');
          break; // Si llegamos aquí, la conexión fue exitosa
          
        } catch (e) {
          lastError = e.toString();
          log('⚠️ Error al conectar a $baseUrl: $e');
          // Continuar con la siguiente URL
        }
      }
      
      // Si no se pudo conectar a ninguna URL
      if (response == null) {
        throw Exception('No se pudo conectar al servidor. Último error: $lastError');
      }
      
      // Procesar la respuesta del servidor
      log('✅ Respuesta recibida - Código: ${response.statusCode}');
      log('📝 Cuerpo de la respuesta: ${response.body}');
      log('📋 Headers: ${response.headers}');
      
      //4- Comprobar estado de la petición
      if (response.statusCode == 200 || response.statusCode == 201) {
        log('✅ Usuario creado correctamente');
        
        // Emitir un evento para indicar que el registro fue exitoso
        emit(state.copyWith(
          formStatus3: FormStatus3.valid,
          isValid3: true,
        ));
        
      } else {
        String errorMessage = 'Error desconocido';
        try {
          final errorData = jsonDecode(response.body);
          errorMessage = errorData.toString();
        } catch (e) {
          errorMessage = response.body;
        }
        
        log('❌ Error al crear usuario');
        log('Código de estado: ${response.statusCode}');
        log('Mensaje de error: $errorMessage');
        
        // Emitir un evento de error
        emit(state.copyWith(
          formStatus3: FormStatus3.invalid,
          isValid3: false,
        ));
        
        // Lanzar excepción con el mensaje de error
        throw Exception('Error ${response.statusCode}: $errorMessage');
      }

    } on http.ClientException catch (e) {
      log('❌ Error de conexión: ${e.message}');
      log('URI: ${e.uri}');
      rethrow;
    } on TimeoutException catch (e) {
      log('❌ Tiempo de espera agotado al conectar con el servidor: $e');
      rethrow;
    } on FormatException catch (e) {
      log('❌ Error de formato en la respuesta: ${e.message}');
      rethrow;
    } catch (e, stackTrace) {
      log('❌ Error inesperado de tipo: ${e.runtimeType}');
      log('❌ Error inesperado: ${e.toString()}');
      log('Tipo de error: ${e.runtimeType}');
      log('Stack trace: $stackTrace');
      rethrow;
    } finally {
      try {
        client.close();
        log('🔌 Cliente HTTP cerrado');
      } catch (e) {
        log('⚠️ Error al cerrar el cliente HTTP: $e');
      }
    }
  }
  
  // Método auxiliar para construir los datos del usuario
  Map<String, dynamic> _buildUserData(SignUpCubit signUpCubit) {
    // Mapear el valor del puesto al formato esperado por el backend
    String formatPuesto(String puesto) {
      // Convertir a minúsculas y eliminar acentos para hacer la comparación más flexible
      final puestoLower = puesto.toLowerCase();
      
      if (puestoLower.contains('medic') || puestoLower == 'médico') {
        return 'MEDICO';
      } else if (puestoLower.contains('enferm')) {
        return 'ENFERMERO';
      } else if (puestoLower.contains('tcae') || puestoLower.contains('técnico') || puestoLower.contains('tecnico')) {
        return 'TCAE';
      }
      // Por defecto, devolver el valor en mayúsculas
      return puesto.toUpperCase();
    }

    return {
      "nombre": signUpCubit.state.nombre.value,
      "apellido1": signUpCubit.state.apellidos.value.split(' ')[0],
      "apellido2": signUpCubit.state.apellidos.value.split(' ').length > 1 
          ? signUpCubit.state.apellidos.value.split(' ')[1] 
          : '',
      "email": signUpCubit.state.gmail.value,
      "telefono": signUpCubit.state.telefono.value,
      "centroTrabajo": state.centroDeTrabajo.value,
      "puesto": formatPuesto(state.puesto.value),
      "localidad": state.localidad.value,
      "preferenciasHorarias": state.preferenciasHorarias.value,
      "disponibilidadHorasExtras": state.disponibilidadHorasExtras.value,
      "password": state.password.value,
      "rol": "user",
      "activo": true
    };
  }

  // Parte 2/3 del formulario
  void centroTrabajoChanged(String centroDeTrabajo){
    final centroTrabajoNewValor = MultiInput.dirty(value: centroDeTrabajo);
    
    emit(
      state.copyWith(
        centroDeTrabajo: centroTrabajoNewValor,
        isValid2: Formz.validate([centroTrabajoNewValor, state.localidad, state.puesto, state.preferenciasHorarias, state.disponibilidadHorasExtras])
      )
    );
  }




  void puestoChanged(String puesto){
    final puestoNewValor = DropDownPuesto.dirty(value: puesto);
    log('MARCADO RADIO BUTTON PUESTO -> $puesto');
    emit(
      state.copyWith(
        puesto: puestoNewValor,
        isValid2: Formz.validate([puestoNewValor, state.centroDeTrabajo, state.localidad, state.disponibilidadHorasExtras, state.preferenciasHorarias])
      )
    );
  }

  
  void localidadChanged(String localidad) {
    final localidadNewValor = MultiInput.dirty(value: localidad);
    log('SE EJECUTA CHANGED $localidad');
    emit(state.copyWith(
      localidad: localidadNewValor,
      isValid2: Formz.validate([
        localidadNewValor, 
        state.centroDeTrabajo, 
        state.puesto,  
        state.disponibilidadHorasExtras,  
        state.preferenciasHorarias
      ])
    ));
  }

  void preferenciaHorariaChanged(String preferencias){
    log('PREFERENCIA HORARIA MARCADA -> $preferencias');
    final preferenciasHorariasNewValor = PreferenciasRadioButton.dirty(value: preferencias);
    
    emit(
      state.copyWith(
        preferenciasHorarias: preferenciasHorariasNewValor,
        isValid2: Formz.validate([preferenciasHorariasNewValor, state.centroDeTrabajo, state.puesto , state.localidad, state.disponibilidadHorasExtras])
      )
    );

  }

  void disponibilidadHorasExtrasChanged(int disponibilidadHorasExtras){
    final disponibilidadhorasExtrasNewValor = DisponibilidadHorasExtras.dirty(value: disponibilidadHorasExtras);
    log('SE EJECUTA EL METODO DEL READIO BUTTON');
    emit(
      state.copyWith(
        disponibilidadHorasExtras: disponibilidadhorasExtrasNewValor,
        isValid2: Formz.validate([disponibilidadhorasExtrasNewValor, state.puesto, state.localidad, state.centroDeTrabajo,  state.preferenciasHorarias])
      )
    );

  }

  void passwordChanged(String password) {
    final passwordNewValor = PasswordInput.dirty(value: password);
    log('Contraseña cambiada');
    emit(state.copyWith(
      password: passwordNewValor,
      isValid3: Formz.validate([passwordNewValor])
    ));
  }
}
