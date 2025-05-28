import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:front_end_gui/cubit/shift_cubit.dart';
import 'package:front_end_gui/cubit/shift_state.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class NewCalendarScreen extends StatefulWidget {
  const NewCalendarScreen({super.key});

  @override
  State<NewCalendarScreen> createState() => _NewCalendarScreenState();
}

class _NewCalendarScreenState extends State<NewCalendarScreen> {
  late DateTime _selectedDate;
  String? _userId;
  String? _userRole;
  bool _isLoading = true;
  
  // Add a key for the refresh indicator
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();
  
  // Format shift date for display
  String _formatShiftDate(DateTime date) {
    return DateFormat('EEEE d MMMM y', 'es_ES').format(date);
  }

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _loadUserData();
    _loadShiftsForSelectedDate();

    // Initialize the ShiftCubit if not already initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ShiftCubit>();
      }
    });
  }

  Future<void> _loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _userRole = prefs.getString('user_role');
        _userId = prefs.getString('user_id');
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadShiftsForSelectedDate() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      print('🔄 Cargando turnos para la fecha: ${_selectedDate.toString().split(' ')[0]}');
      
      // Primero, cargar los turnos disponibles para el rol del usuario
      if (_userRole != null) {
        print('🔍 Buscando turnos para el rol: $_userRole');
        
        // Calcular el primer y último día del mes actual
        final firstDayOfMonth = DateTime(_selectedDate.year, _selectedDate.month, 1);
        final lastDayOfMonth = DateTime(_selectedDate.year, _selectedDate.month + 1, 0);
        
        print('📅 Rango de fechas: ${firstDayOfMonth.toString().split(' ')[0]} - ${lastDayOfMonth.toString().split(' ')[0]}');
        
        // Cargar turnos disponibles para el rango de fechas
        await context.read<ShiftCubit>().loadAvailableShiftsByRole(
          _userRole!,
          startDate: firstDayOfMonth,
          endDate: lastDayOfMonth,
        );
        
        print('✅ Turnos cargados correctamente');
      } else {
        print('⚠️ No se pudo determinar el rol del usuario');
      }
      
      // Luego, cargar los turnos del usuario para la fecha seleccionada
      if (_userId != null) {
        await context.read<ShiftCubit>().loadShiftsByDate(_selectedDate);
      }
      
    } catch (e) {
      if (!mounted) return;
      print('❌ Error al cargar los turnos: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar los turnos: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Formatea la hora
  String _formatTime(TimeOfDay? time) {
    if (time == null) return '--:--';
    try {
      final hour = time.hour.toString().padLeft(2, '0');
      final minute = time.minute.toString().padLeft(2, '0');
      return '$hour:$minute';
    } catch (e) {
      return '--:--';
    }
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    try {
      // Normalizar fechas a UTC y comparar solo año, mes y día
      final utcDate1 = DateTime.utc(date1.year, date1.month, date1.day);
      final utcDate2 = DateTime.utc(date2.year, date2.month, date2.day);
      
      return utcDate1.isAtSameMomentAs(utcDate2);
    } catch (e) {
      debugPrint('Error en _isSameDay: $e');
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendario de Turnos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _refreshIndicatorKey.currentState?.show();
              _loadShiftsForSelectedDate();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              key: _refreshIndicatorKey,
              onRefresh: _loadShiftsForSelectedDate,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Month header with navigation
                      _buildMonthHeader(),
                      const SizedBox(height: 16),
                      // Calendar
                      _buildCalendar(),
                      const SizedBox(height: 24),
                      // Shifts for selected date
                      Text(
                        'Turnos para ${_formatShiftDate(_selectedDate)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildShiftList(),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildMonthHeader() {
    final monthFormat = DateFormat('MMMM yyyy', 'es_ES');
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Text(
        monthFormat.format(_selectedDate).toUpperCase(),
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildCalendar() {
    final firstDay = DateTime(_selectedDate.year, _selectedDate.month, 1);
    final lastDay = DateTime(_selectedDate.year, _selectedDate.month + 1, 0);
    final daysInMonth = lastDay.day;
    final firstWeekday = firstDay.weekday % 7;
    final totalDays = daysInMonth + firstWeekday - 1;
    final totalWeeks = (totalDays / 7).ceil();
    final cellSize = 40.0;

    return BlocBuilder<ShiftCubit, ShiftState>(
      builder: (context, state) {
        if (state is ShiftLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        return Column(
          children: [
            // Weekday headers
            Row(
              children: const [
                _WeekdayText(day: 'Lun'),
                _WeekdayText(day: 'Mar'),
                _WeekdayText(day: 'Mié'),
                _WeekdayText(day: 'Jue'),
                _WeekdayText(day: 'Vie'),
                _WeekdayText(day: 'Sáb'),
                _WeekdayText(day: 'Dom'),
              ],
            ),
            const SizedBox(height: 8),
            // Calendar grid
            ...List.generate(totalWeeks, (weekIndex) {
              return Row(
                children: List.generate(7, (weekday) {
                  final dayNumber = weekIndex * 7 + weekday - firstWeekday + 2;
                  final isCurrentMonth = dayNumber > 0 && dayNumber <= daysInMonth;
                  final currentDate = isCurrentMonth 
                      ? DateTime(_selectedDate.year, _selectedDate.month, dayNumber)
                      : DateTime.now();
                  
                  final isSelected = isCurrentMonth && _isSameDay(_selectedDate, currentDate);
                  
                  // Verificar si hay turnos disponibles para este día
                  bool hasShift = false;
                  if (isCurrentMonth && state is ShiftsLoaded) {
                    final currentDateUtc = DateTime.utc(currentDate.year, currentDate.month, currentDate.day);
                    
                    // Verificar si hay algún turno para este día
                    hasShift = state.availableShifts.any((shift) {
                      try {
                        final shiftDate = shift.date;
                        final shiftDateUtc = DateTime.utc(
                          shiftDate.year,
                          shiftDate.month,
                          shiftDate.day,
                        );
                        
                        final isSameDay = currentDateUtc.isAtSameMomentAs(shiftDateUtc);
                        
                        if (isSameDay) {
                          print('📅 Turno encontrado para el día: ${currentDate.toString().split(' ')[0]}');
                          print('   - ID: ${shift.id}, Hora: ${_formatTime(shift.startTime)} - ${_formatTime(shift.endTime)}');
                        }
                        
                        return isSameDay;
                      } catch (e) {
                        print('❌ Error al comparar fechas: $e');
                        return false;
                      }
                    });
                    
                    if (hasShift) {
                      print('✅ Día con turno: ${currentDate.toString().split(' ')[0]}');
                    }
                  }

                  return Expanded(
                    child: GestureDetector(
                      onTap: isCurrentMonth ? () => _onDaySelected(currentDate) : null,
                      child: Container(
                        width: cellSize,
                        height: cellSize,
                        margin: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: isSelected 
                              ? Theme.of(context).primaryColor 
                              : (hasShift ? Colors.green.withOpacity(0.2) : Colors.transparent),
                          shape: BoxShape.circle,
                          border: hasShift
                              ? Border.all(color: Colors.green, width: 2.0)
                              : (isSelected 
                                  ? Border.all(color: Theme.of(context).primaryColor, width: 1.5)
                                  : null),
                        ),
                        child: Center(
                          child: Text(
                            dayNumber > 0 && dayNumber <= daysInMonth ? dayNumber.toString() : '',
                            style: TextStyle(
                              color: isSelected 
                                  ? Colors.white 
                                  : (hasShift ? Colors.green : null),
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              );
            }),
          ],
        );
      },
    );
  }


  Widget _buildShiftList() {
    return BlocBuilder<ShiftCubit, ShiftState>(
      builder: (context, state) {
        if (state is ShiftLoading) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is ShiftError) {
          return Center(child: Text('Error: ${state.message}'));
        } else if (state is ShiftsLoaded) {
          final shiftsForSelectedDate = state.myShifts
              .where((shift) => _isSameDay(shift.date, _selectedDate))
              .toList();

          if (shiftsForSelectedDate.isEmpty) {
            return const Center(child: Text('No hay turnos para esta fecha'));
          }

          return ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: shiftsForSelectedDate.length,
            itemBuilder: (context, index) {
              final shift = shiftsForSelectedDate[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4.0),
                child: ListTile(
                  title: Text('${shift.role} - ${shift.status}'),
                  subtitle: Text('${_formatTime(shift.startTime)} - ${_formatTime(shift.endTime)}'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    // Navegar a la pantalla de detalles del turno
                  },
                ),
              );
            },
          );
        }
        return const Center(child: Text('Seleccione una fecha para ver los turnos'));
      },
    );
  }

  void _onDaySelected(DateTime selectedDate) {
    if (_isSameDay(_selectedDate, selectedDate)) return;
    
    setState(() {
      _selectedDate = selectedDate;
      _loadShiftsForSelectedDate();
    });
  }
}

class _WeekdayText extends StatelessWidget {
  final String day;
  
  const _WeekdayText({required this.day});
  
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Text(
        day,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}
