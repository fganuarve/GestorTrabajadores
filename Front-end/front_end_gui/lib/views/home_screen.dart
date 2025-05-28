import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:front_end_gui/cubit/auth_cubit.dart';
import 'package:front_end_gui/cubit/shift_cubit.dart';
import 'package:front_end_gui/cubit/shift_state.dart';
import 'package:front_end_gui/models/shift_model.dart';
import 'package:front_end_gui/views/new_calendar_screen_fixed.dart' as new_calendar;
import 'package:front_end_gui/views/carpool/carpool_list_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthCubit>().state;
    // Obtener y observar el estado actual de los turnos
    context.watch<ShiftCubit>().state;
    
    if (authState is! AuthAuthenticated) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    
    final userId = authState.userData?['id'] ?? 0;
    
    return HomeScreenGo(userId: userId);
  }
}

class HomeScreenGo extends StatefulWidget {
  final int userId;
  
  const HomeScreenGo({
    super.key, 
    required this.userId,
  });

  @override
  State<HomeScreenGo> createState() => _HomeScreenGoState();
}

class _HomeScreenGoState extends State<HomeScreenGo> {
  // Obtener el ID del usuario desde el widget
  int get userId => widget.userId;
  int _position = 0;
  String _userPuesto = 'Usuario';
  String _userName = 'Usuario';
  String _userId = '';
  bool _isLoading = true;
  String _errorMessage = '';
  List<Map<String, dynamic>> _next7Days = [];
  DateTime _selectedDate = DateTime.now();
  List<Shift> _availableShifts = [];

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _generateNext7Days();
    _loadShiftsForSelectedDate();
    _checkUserShift();
  }

  // Cargar turnos para la fecha seleccionada
  Future<void> _loadShiftsForSelectedDate() async {
    if (!mounted) return;
    
    final shiftCubit = context.read<ShiftCubit>();
    await shiftCubit.loadShiftsByDate(_selectedDate);
    
    // También cargar turnos disponibles por rol
    if (_userPuesto.isNotEmpty && _userPuesto != 'Usuario') {
      await shiftCubit.loadAvailableShiftsByRole(_userPuesto);
    }
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _userName = prefs.getString('user_name') ?? 'Usuario';
        _userPuesto = prefs.getString('user_puesto') ?? 'Usuario';
        _userId = prefs.getString('user_id') ?? '';
      });
      
      // Cargar turnos después de obtener los datos del usuario
      if (mounted) {
        await _loadShiftsForSelectedDate();
      }
    } catch (e) {
      print('Error al cargar datos del usuario: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _generateNext7Days() {
    final now = DateTime.now();
    setState(() {
      _next7Days = List.generate(7, (index) {
        final date = now.add(Duration(days: index));
        return {
          'date': date,
          'dayName': _getWeekdayName(date.weekday),
          'isToday': _isToday(date),
        };
      });
    });
  }

  String _getWeekdayName(int weekday) {
    const weekdays = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
    return weekdays[weekday - 1];
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
           date.month == now.month &&
           date.day == now.day;
  }
  
  String _getNombrePuestoAmigable(String puesto) {
    switch (puesto.toUpperCase()) {
      case 'MEDICO':
        return 'Médico';
      case 'ENFERMERO':
        return 'Enfermero/a';
      case 'TCAE':
        return 'Técnico en Cuidados de Enfermería';
      default:
        return puesto;
    }
  }

  // Construir la lista de turnos
  Widget _buildShiftsList() {
    return BlocConsumer<ShiftCubit, ShiftState>(
      listener: (context, state) {
        // Actualizar la lista de turnos disponibles cuando cambie el estado
        if (state is ShiftsLoaded) {
          setState(() {
            // Combine both myShifts and availableShifts, then filter by role or user ID
            _availableShifts = [
              ...state.myShifts,
              ...state.availableShifts.where((shift) => 
                shift.role == _userPuesto || shift.userId == _userId
              )
            ];
          });
        }
      },
      builder: (context, state) {
        // Mostrar el estado de carga
        if (state is ShiftLoading) {
          return const Center(child: CircularProgressIndicator());
        } 
        
        // Mostrar mensaje de error si lo hay
        if (state is ShiftError) {
          return Center(child: Text('Error: ${state.message}'));
        }
        
        // Mostrar mensaje si no hay turnos
        if (_availableShifts.isEmpty) {
          return const Center(
            child: Text('No hay turnos disponibles para esta fecha.'),
          );
        }
        
        // Mostrar la lista de turnos
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _availableShifts.length,
          itemBuilder: (context, index) {
            final shift = _availableShifts[index];
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 0),
              child: ListTile(
                title: Text('${_formatTime(shift.startTime)} - ${_formatTime(shift.endTime)}'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Puesto: ${_getNombrePuestoAmigable(shift.role)}'),
                    Text('Estado: ${_getStatusText(shift.status)}'),
                  ],
                ),
                trailing: shift.userId == _userId 
                    ? const Icon(Icons.check_circle, color: Colors.green)
                    : null,
                onTap: () {
                  // Navegar a la pantalla de detalles del turno si es necesario
                },
              ),
            );
          },
        );
      },
    );
  }
  
  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
  
  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'available':
        return 'Disponible';
      case 'taken':
        return 'Ocupado';
      case 'pending':
        return 'Pendiente';
      default:
        return status;
    }
  }

  // Variable para almacenar el turno del usuario (por si se necesita en el futuro)
  // ignore: unused_field
  Shift? _userShift;

  // Verificar si el usuario ya tiene un turno para la fecha seleccionada
  Future<void> _checkUserShift() async {
    try {
      final userId = widget.userId.toString();
      final hasShift = await context.read<ShiftCubit>().checkUserHasShift(userId, _selectedDate);
      
      if (mounted) {
        // No necesitamos actualizar el estado aquí ya que usamos el estado del cubit
        print('Usuario ${hasShift ? 'tiene' : 'no tiene'} turno para la fecha seleccionada');
      }
    } catch (e) {
      // Opcional: Mostrar un mensaje de error al usuario
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al verificar turnos: $e')),
        );
      }
    }
  }

  Widget _buildFloatingActionButton() {
    final authState = context.watch<AuthCubit>().state;
    final shiftState = context.watch<ShiftCubit>().state;
    
    if (authState is! AuthAuthenticated) {
      return const SizedBox.shrink();
    }
    
    final userRole = authState.userRole?.toUpperCase() ?? '';
    final hasShift = shiftState is ShiftsLoaded && shiftState.hasUserShift;
    
    // Si el usuario ya tiene un turno, mostrar el botón de ver turnos
    if (hasShift) {
      return FloatingActionButton(
        heroTag: 'view_shifts_btn',
        onPressed: () {
          // Navegar a la pantalla de ver turnos
          Navigator.pushNamed(
            context, 
            '/view_shifts',
            arguments: _selectedDate,
          );
        },
        child: const Icon(Icons.calendar_today),
        backgroundColor: Colors.blue,
      );
    }
    
    // Para administradores y supervisores, mostrar el botón de agregar turno
    if (userRole == 'ADMIN' || userRole == 'SUPERVISOR') {
      return FloatingActionButton(
        heroTag: 'add_shift_btn',
        onPressed: () {
          // Navegar a la pantalla de agregar turno
          Navigator.pushNamed(
            context, 
            '/add_shift',
            arguments: _selectedDate,
          );
        },
        child: const Icon(Icons.add),
      );
    }
    
    // Para otros usuarios, no mostrar ningún botón flotante
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: _buildFloatingActionButton(),
      appBar: AppBar(
        title: const Text('Gestor de Turnos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              // Cerrar sesión usando el AuthCubit
              await context.read<AuthCubit>().signOut();
              if (mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '¡Bienvenido!',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Puesto: ${_getNombrePuestoAmigable(_userPuesto)}',
                        style: TextStyle(
                          fontSize: 16,
                          color: Theme.of(context).hintColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Próximos 7 días:',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 100,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _next7Days.length,
                      itemBuilder: (context, index) {
                        final day = _next7Days[index];
                        final date = day['date'] as DateTime;
                        final isToday = day['isToday'] as bool;
                        
                        return Container(
                          width: 80,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: isToday ? Colors.blue[100] : Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                            border: isToday
                                ? Border.all(color: Colors.blue, width: 2)
                                : null,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '${date.day}',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                                  color: isToday ? Colors.blue[800] : Colors.black,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                day['dayName'],
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isToday ? Colors.blue[800] : Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Turnos disponibles:',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildShiftsList(),
                  const SizedBox(height: 80), // Espacio para el botón flotante
                  if (_errorMessage.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      _errorMessage,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ],
                ],
              ),
            ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _position,
        onTap: (index) {
          setState(() {
            _position = index;
          });
          
          // Navegar a la pantalla de calendario cuando se presiona el botón
          if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const new_calendar.NewCalendarScreen()),
            ).then((_) {
              // Al volver de la pantalla de calendario, restablecer el índice
              setState(() {
                _position = 0; // Volver a la pestaña de inicio
              });
            });
            return; // Prevent the index from changing
          }
          
          // Navegar a la pantalla de coches cuando se presiona el botón
          if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => CarpoolListScreen(selectedDate: DateTime.now())),
            ).then((_) {
              // Al volver de la pantalla de coches, restablecer el índice
              setState(() {
                _position = 0; // Volver a la pestaña de inicio
              });
            });
            return; // Prevent the index from changing
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Calendario',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}
