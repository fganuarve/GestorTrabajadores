import 'package:equatable/equatable.dart';
import 'package:front_end_gui/models/shift_model.dart';

// Base state class
abstract class ShiftState extends Equatable {
  const ShiftState();
  
  @override
  List<Object> get props => [];
}

// Initial state

class ShiftLoading extends ShiftState {}

class ShiftsLoaded extends ShiftState {
  final List<Shift> myShifts;
  final List<Shift> availableShifts;
  final bool hasUserShift;

  const ShiftsLoaded({
    this.myShifts = const [],
    this.availableShifts = const [],
    this.hasUserShift = false,
  });

  @override
  List<Object> get props => [myShifts, availableShifts, hasUserShift];
  
  ShiftsLoaded copyWith({
    List<Shift>? myShifts,
    List<Shift>? availableShifts,
    bool? hasUserShift,
  }) {
    return ShiftsLoaded(
      myShifts: myShifts ?? this.myShifts,
      availableShifts: availableShifts ?? this.availableShifts,
      hasUserShift: hasUserShift ?? this.hasUserShift,
    );
  }
}

class ShiftPublished extends ShiftState {
  final Shift shift;

  const ShiftPublished(this.shift);

  @override
  List<Object> get props => [shift];
}

class ShiftRequested extends ShiftState {
  final Shift shift;

  const ShiftRequested(this.shift);

  @override
  List<Object> get props => [shift];
}

class ShiftUpdated extends ShiftState {
  final Shift shift;

  const ShiftUpdated(this.shift);

  @override
  List<Object> get props => [shift];
}

class ShiftError extends ShiftState {
  final String message;

  const ShiftError(this.message);

  @override
  List<Object> get props => [message];
}
