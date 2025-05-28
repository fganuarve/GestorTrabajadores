import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const HomeScreenGo();
  }
}

class HomeScreenGo extends StatefulWidget {
  const HomeScreenGo({super.key});

  @override
  State<HomeScreenGo> createState() => _HomeScreenGoState();
}

class _HomeScreenGoState extends State<HomeScreenGo> {
  int _position = 0;
  String _userName = 'Usuario';
  bool _isLoading = true;
  String _errorMessage = '';
  List<Map<String, dynamic>> _next7Days = [];

  @override
  void initState() {
    super.initState();
    _generateNext7Days();
    _isLoading = false;
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
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/login');
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
                  Text(
                    '¡Bienvenido, $_userName!',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
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
            // TODO: Implement navigation between tabs
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
