import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:front_end_gui/models/shift_model.dart';
import 'package:front_end_gui/services/shift_service.dart';

// Estados
abstract class HomeState extends Equatable {
  const HomeState();
  @override
  List<Object> get props => [];
}

class HomeInitial extends HomeState {}

class HomeLoading extends HomeState {}

class HomeLoaded extends HomeState {
  final String userName;
  final List<ShiftModel> weeklyShifts;
  final DateTime currentDate;

  const HomeLoaded({
    required this.userName,
    required this.weeklyShifts,
    required this.currentDate,
  });

  @override
  List<Object> get props => [userName, weeklyShifts, currentDate];
}

class HomeError extends HomeState {
  final String message;

  const HomeError(this.message);

  @override
  List<Object> get props => [message];
}

// Cubit
class HomeCubit extends Cubit<HomeState> {
  final ShiftService _shiftService;
  final String _userId;
  final String _userName;
  final String _userLastName;

  HomeCubit({
    required ShiftService shiftService,
    required String userId,
    required String userName,
    required String userLastName,
  })  : _shiftService = shiftService,
        _userId = userId,
        _userName = userName,
        _userLastName = userLastName,
        super(HomeInitial());

  // Cargar los datos iniciales
  Future<void> loadInitialData() async {
    try {
      emit(HomeLoading());
      
      // Obtener la fecha actual y calcular el rango de la semana
      final now = DateTime.now();
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      final endOfWeek = startOfWeek.add(const Duration(days: 6));

      // Obtener los turnos de la semana actual
      List<ShiftModel> shifts = [];
      try {
        shifts = await _shiftService.getUserShifts(
          userId: _userId,
          startDate: startOfWeek,
          endDate: endOfWeek,
        );
      } catch (e) {
        debugPrint('Error al cargar los turnos: $e');
        // Continuar con una lista vacía de turnos
      }

      emit(HomeLoaded(
        userName: '$_userName $_userLastName'.trim(),
        weeklyShifts: shifts,
        currentDate: now,
      ));
    } catch (e) {
      debugPrint('Error en loadInitialData: $e');
      emit(HomeError('Error al cargar los datos'));
      // No relanzar la excepción para evitar que la aplicación se bloquee
    }
  }

  // Actualizar los turnos para una semana específica
  Future<void> loadWeekShifts(DateTime startDate, DateTime endDate) async {
    try {
      if (state is HomeLoaded) {
        emit(HomeLoading());
        
        final shifts = await _shiftService.getUserShifts(
          userId: _userId,
          startDate: startDate,
          endDate: endDate,
        );

        if (state is HomeLoaded) {
          final currentState = state as HomeLoaded;
          emit(HomeLoaded(
            userName: currentState.userName,
            weeklyShifts: shifts,
            currentDate: currentState.currentDate,
          ));
        }
      }
    } catch (e) {
      emit(HomeError('Error al cargar los turnos: $e'));
      rethrow;
    }
  }
}
