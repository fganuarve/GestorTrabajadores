/*import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:table_calendar/table_calendar.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Adjust layout based on screen size
        if (constraints.maxWidth > 600) {
          // Tablet/Desktop layout
          return Scaffold(
            body: Row(
              children: [
                NavigationRail(
                  selectedIndex: 0,
                  onDestinationSelected: (int index) {
                    // Handle navigation
                  },
                  labelType: NavigationRailLabelType.all,
                  destinations: const [
                    NavigationRailDestination(
                      icon: Icon(Icons.home),
                      label: Text('Inicio'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.calendar_today),
                      label: Text('Calendario'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.person),
                      label: Text('Perfil'),
                    ),
                  ],
                ),
                const VerticalDivider(thickness: 1, width: 1),
                const Expanded(child: HomeScreenGo()),
              ],
            ),
          );
        }
        // Mobile layout
        return const HomeScreenGo();
      },
    );
  }
}

class HomeScreenGo extends StatefulWidget {
  const HomeScreenGo({super.key});

  @override
  State<HomeScreenGo> createState() => _HomeScreenGoState();
}

class _HomeScreenGoState extends State<HomeScreenGo> {
  int _currentIndex = 0;
  String _userName = 'Usuario';
  bool _isLoading = false;
  String _errorMessage = '';
  List<Map<String, dynamic>> _next7Days = [];

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _generateNext7Days();
  }

  Future<void> _loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Debug: Print all keys and values from SharedPreferences
      print('=== SharedPreferences Debug ===');
      final keys = prefs.getKeys();
      for (String key in keys) {
        print('$key: ${prefs.get(key)}');
      }
      print('==============================');
      
      // Get user name from SharedPreferences
      setState(() {
        _userName = prefs.getString('user_name') ?? 'Usuario';
        _isLoading = false;
      });
      
      print('Usuario actual: $_userName');
    } catch (e) {
      print('Error al cargar datos del usuario: $e');
      setState(() {
        _userName = 'Usuario';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestor de Turnos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();
              if (!mounted) return;
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: _buildCurrentView(),
      bottomNavigationBar: MediaQuery.of(context).size.width > 600
          ? null // Hide bottom nav on larger screens (using NavigationRail)
          : BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (index) {
                setState(() {
                  _currentIndex = index;
                });
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

  Widget _buildCurrentView() {
    switch (_currentIndex) {
      case 0:
        return _buildHomeView();
      case 1:
        return _buildCalendarView();
      case 2:
        return _buildProfileView();
      default:
        return _buildHomeView();
    }
  }

  Widget _buildHomeView() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: EdgeInsets.all(constraints.maxWidth > 600 ? 24.0 : 16.0),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight - 100,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '¡Bienvenido, $_userName!',
                  style: TextStyle(
                    fontSize: constraints.maxWidth > 600 ? 32.0 : 24.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Próximos 7 días:',
                  style: TextStyle(
                    fontSize: constraints.maxWidth > 600 ? 24.0 : 18.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 120,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _next7Days.length,
                    itemBuilder: (context, index) {
                      final day = _next7Days[index];
                      final date = day['date'] as DateTime;
                      final isToday = day['isToday'] as bool;
                      
                      return Container(
                        width: constraints.maxWidth > 600 ? 100 : 80,
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          color: isToday ? Colors.blue[100] : Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                          border: isToday
                              ? Border.all(color: Colors.blue, width: 2)
                              : null,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${date.day}',
                              style: TextStyle(
                                fontSize: constraints.maxWidth > 600 ? 32.0 : 24.0,
                                fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                                color: isToday ? Colors.blue[800] : Colors.black,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              day['dayName'],
                              style: TextStyle(
                                fontSize: constraints.maxWidth > 600 ? 16.0 : 12.0,
                                color: isToday ? Colors.blue[800] : Colors.grey[600],
                                fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                if (_errorMessage.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red[200]!),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const Spacer(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCalendarView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2010, 10, 16),
            lastDay: DateTime.utc(2030, 3, 14),
            focusedDay: DateTime.now(),
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
            ),
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                color: Colors.blue[100],
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
            ),
            onDaySelected: (selectedDay, focusedDay) {
              // Handle day selection
            },
          ),
          const SizedBox(height: 20),
          const Text(
            'Eventos del día',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          // Add your events list here
        ],
      ),
    );
  }

  Widget _buildProfileView() {
    return const Center(
      child: Text('Perfil del usuario'),
    );
  }
}
*/