import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:front_end_gui/models/shift_model.dart';
import 'package:front_end_gui/services/shift_service.dart';
import 'package:front_end_gui/cubit/shift_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ShiftCubit extends Cubit<ShiftState> {
  final ShiftService _shiftService;
  final SharedPreferences _prefs;
  
  String? get _currentUserId => _prefs.getString('user_id');
  String? get _currentUserRole => _prefs.getString('user_role');

  ShiftCubit({
    required ShiftService shiftService,
    required SharedPreferences prefs,
  })  : _shiftService = shiftService,
        _prefs = prefs,
        super(ShiftLoading()) {
    // Load shifts when cubit is created
    loadShifts();
  }

  @override
  Future<void> close() async {
    await super.close();
  }
  
  // Check if a user already has a shift on a specific date
  Future<bool> hasShiftOnDate(String userId, DateTime date) async {
    try {
      // Check in the current state first
      if (state is ShiftsLoaded) {
        final currentState = state as ShiftsLoaded;
        return currentState.myShifts.any((shift) => 
          shift.userId == userId && 
          shift.date.year == date.year &&
          shift.date.month == date.month &&
          shift.date.day == date.day
        );
      }
      
      // If not found in current state, check in the database
      final shifts = await _shiftService.getShiftsByUserAndDate(userId, date);
      return shifts.isNotEmpty;
    } catch (e) {
      print('Error checking user shift: $e');
      return false;
    }
  }
  
  // Alias for backward compatibility
  Future<bool> checkUserHasShift(String userId, DateTime date) => hasShiftOnDate(userId, date);

  // Load shifts for a specific date
  Future<void> loadShiftsByDate(DateTime date) async {
    if (_currentUserId == null || _currentUserRole == null) {
      emit(ShiftError('User not authenticated'));
      return;
    }

    try {
      emit(ShiftLoading());
      
      // Get user's shifts for the date
      final myShifts = await _shiftService.getShiftsByUserAndDate(
        _currentUserId!,
        date,
      );
      
      // Get available shifts for the date and user's role
      final availableShifts = await _shiftService.getAvailableShiftsByDateAndRole(
        date,
        _currentUserRole!,
      );
      
      // Get all shifts for the date to check if user already has a shift
      final hasShift = await hasShiftOnDate(_currentUserId!, date);
      
      emit(ShiftsLoaded(
        myShifts: myShifts,
        availableShifts: availableShifts,
        hasUserShift: hasShift,
      ));
    } catch (e) {
      emit(ShiftError('Failed to load shifts: $e'));
      rethrow;
    }
  }

  // Load all shifts for the current user
  Future<void> loadShifts() async {
    if (_currentUserId == null || _currentUserRole == null) {
      emit(ShiftError('User not authenticated'));
      return;
    }

    try {
      emit(ShiftLoading());
      
      // Get user's shifts
      final myShifts = await _shiftService.getShiftsByUser(_currentUserId!);
      
      // Get available shifts for user's role
      final availableShifts = await _shiftService.getAvailableShifts(_currentUserRole!);
      
      emit(ShiftsLoaded(
        myShifts: myShifts,
        availableShifts: availableShifts,
        hasUserShift: myShifts.isNotEmpty,
      ));
    } catch (e) {
      emit(ShiftError('Failed to load shifts: $e'));
    }
  }
  
  // Cargar turnos disponibles para solicitar
  Future<void> loadAvailableShifts(String userId) async {
    emit(ShiftLoading());
    try {
      if (userId.isEmpty) {
        emit(ShiftsLoaded(myShifts: [], availableShifts: []));
        return;
      }
      
      final availableShifts = await _shiftService.getAvailableShifts(userId);
      
      // Si ya hay un estado cargado, mantener mis turnos
      if (state is ShiftsLoaded) {
        final currentState = state as ShiftsLoaded;
        emit(ShiftsLoaded(
          myShifts: currentState.myShifts,
          availableShifts: availableShifts,
        ));
      } else {
        emit(ShiftsLoaded(myShifts: [], availableShifts: availableShifts));
      }
    } catch (e) {
      emit(ShiftError('Error al cargar turnos disponibles: $e'));
    }
  }
  
  // Cargar turnos disponibles por rol
  Future<void> loadAvailableShiftsByRole(
    String role, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    if (_currentUserId == null) {
      emit(ShiftError('User not authenticated'));
      return;
    }

    try {
      emit(ShiftLoading());
      
      // Get available shifts for the role within the date range
      final shifts = await _shiftService.getAvailableShiftsByRole(
        role,
        startDate: startDate,
        endDate: endDate,
      );
      
      // Check if user already has a shift on any of these days
      final userShifts = await _shiftService.getShiftsByUser(_currentUserId!);
      
      // Mark shifts where user already has a shift on that day
      final updatedShifts = shifts.map((shift) {
        final hasShiftOnThisDay = userShifts.any((userShift) {
          return userShift.date.year == shift.date.year &&
                 userShift.date.month == shift.date.month &&
                 userShift.date.day == shift.date.day;
        });
        
        return shift.copyWith(
          isAvailable: !hasShiftOnThisDay,
        );
      }).toList();
      
      if (state is ShiftsLoaded) {
        final currentState = state as ShiftsLoaded;
        emit(ShiftsLoaded(
          myShifts: currentState.myShifts,
          availableShifts: updatedShifts,
          hasUserShift: currentState.hasUserShift,
        ));
      } else {
        emit(ShiftsLoaded(
          myShifts: [],
          availableShifts: updatedShifts,
          hasUserShift: false,
        ));
      }
    } catch (e) {
      emit(ShiftError('Error al cargar turnos disponibles: $e'));
      rethrow;
    }
  }
  
  // Publicar un nuevo turno
  Future<void> publishShift(Shift shift) async {
    if (_currentUserId == null) {
      emit(ShiftError('User not authenticated'));
      return;
    }

    try {
      emit(ShiftLoading());
      
      // Create a new shift that's marked as published
      final publishedShift = shift.copyWith(
        isPublished: true,
        publishedAt: DateTime.now(),
        status: 'available',
      );
      
      await _shiftService.addShift(publishedShift);
      
      // Reload shifts after publishing
      await loadShifts();
      
      emit(ShiftPublished(publishedShift));
    } catch (e) {
      emit(ShiftError('Failed to publish shift: $e'));
    }
  }
  
  // Solicitar un turno disponible
  // Actualizar un turno existente
  Future<void> updateShift(Shift shift) async {
    emit(ShiftLoading());
    try {
      await _shiftService.updateShift(shift);
      
      // Recargar los turnos después de actualizar
      await loadShiftsByDate(shift.date);
      
      emit(ShiftUpdated(shift));
    } catch (e) {
      emit(ShiftError('Error al actualizar el turno: $e'));
      rethrow;
    }
  }

  // Solicitar un turno disponible
  Future<void> requestShift(String shiftId, String userId, {String? notes}) async {
    if (_currentUserId == null) {
      emit(ShiftError('Usuario no autenticado'));
      return;
    }

    emit(ShiftLoading());
    try {
      // Obtener el turno completo
      final shift = await _shiftService.getShiftById(shiftId);
      
      if (shift == null) {
        throw Exception('Turno no encontrado');
      }
      
      // Verificar si el turno ya está ocupado
      if (shift.status == 'taken' || shift.status == 'approved') {
        throw Exception('Este turno ya ha sido ocupado');
      }

      // Verificar si el usuario ya tiene un turno en la misma fecha
      final hasShift = await hasShiftOnDate(userId, shift.date);
      if (hasShift) {
        throw Exception('Ya tienes un turno asignado para esta fecha');
      }
      
      // Actualizar el turno en el servidor
      await _shiftService.requestShift(shiftId, userId, notes: notes);
      
      // Actualizar el estado local
      if (state is ShiftsLoaded) {
        final currentState = state as ShiftsLoaded;
        final updatedShifts = List<Shift>.from(currentState.availableShifts)
          ..removeWhere((s) => s.id == shiftId);
        
        final updatedShift = shift.copyWith(
          status: 'requested',
          requestedBy: userId,
          requestedAt: DateTime.now(),
          notes: notes,
        );
        
        final myShifts = List<Shift>.from(currentState.myShifts)..add(updatedShift);
        
        emit(ShiftsLoaded(
          myShifts: myShifts,
          availableShifts: updatedShifts,
          hasUserShift: true,
        ));
      }
      
      emit(ShiftRequested(shift));
    } catch (e) {
      emit(ShiftError('Error al solicitar el turno: $e'));
      rethrow;
    }
  }
}
