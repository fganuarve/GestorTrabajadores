import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:front_end_gui/views/widgets/Turn_detail_screen.dart';

class CalendarWidget extends StatefulWidget {
  const CalendarWidget({super.key});

  @override
  State<CalendarWidget> createState() => _CalendarWidgetState();
}

class _CalendarWidgetState extends State<CalendarWidget> {
  late DateTime _selectedDay;
  late DateTime _focusedDay;
  late CalendarFormat _calendarFormat;
  late Map<DateTime, String> _turnos;

  @override
  void initState() {
    super.initState();

    _selectedDay = DateTime.now();
    _focusedDay = DateTime.now();
    _calendarFormat = CalendarFormat.month;

    // 🔹 Simulación de turnos con horarios específicos (Año 2025)
    _turnos = {
      DateTime.utc(2025, 4, 5): "Turno de mañana: 08:00 - 16:00",
      DateTime.utc(2025, 4, 6): "Turno de tarde: 16:00 - 00:00",
      DateTime.utc(2025, 4, 7): "Turno de noche: 00:00 - 08:00",
      DateTime.utc(2025, 4, 10): "Turno de mañana: 08:00 - 16:00",
      DateTime.utc(2025, 4, 15): "Día libre",
      DateTime.utc(2025, 4, 20): "Turno de tarde: 16:00 - 00:00",
      DateTime.utc(2025, 4, 25): "Turno de noche: 00:00 - 08:00",
    };

    // Programamos el pop‑up para que aparezca tras la primera renderización
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _mostrarPopupNuevosHorarios();
    });
  }

  void _mostrarPopupNuevosHorarios() {
    // Preparamos la lista de fechas formateadas
    final formatter = DateFormat.yMMMMd('es_ES');
    final dias = _turnos.keys.toList()
      ..sort();
    final listadoDias = dias
        .map((d) => formatter.format(d))
        .join('\n');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Center(child: Text('Tienes nuevos horarios')),
        content: Text(listadoDias),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        TableCalendar(
          locale: 'es_ES',
          firstDay: DateTime.utc(2020, 1, 1),
          lastDay: DateTime.utc(2100, 12, 31),
          focusedDay: _focusedDay,
          calendarFormat: _calendarFormat,
          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
          onDaySelected: (selectedDay, focusedDay) {
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
            });
          },
          headerStyle: HeaderStyle(
            formatButtonVisible: false,
            titleCentered: true,
            titleTextStyle: TextStyle(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          calendarStyle: CalendarStyle(
            todayDecoration: BoxDecoration(
              color: theme.colorScheme.secondary,
              shape: BoxShape.circle,
            ),
            selectedDecoration: BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
            ),
            defaultTextStyle: TextStyle(color: theme.colorScheme.onSurface),
            weekendTextStyle: TextStyle(color: theme.colorScheme.error),
          ),
          calendarBuilders: CalendarBuilders(
            dowBuilder: (context, day) {
              final text = DateFormat.EEEE('es_ES').format(day);
              return Center(
                child: Text(
                  text.substring(0, 3).toUpperCase(),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              );
            },
            markerBuilder: (context, date, events) {
              String? turno =
                  _turnos[DateTime.utc(date.year, date.month, date.day)];
              if (turno != null) {
                final color = turno.contains("mañana")
                    ? Colors.blue
                    : turno.contains("tarde")
                        ? Colors.orange
                        : turno.contains("noche")
                            ? Colors.purple
                            : Colors.green;
                return Positioned(
                  bottom: 5,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                  ),
                );
              }
              return null;
            },
          ),
        ),
        const SizedBox(height: 20),
        Text(
          _turnos[DateTime.utc(
                  _selectedDay.year, _selectedDay.month, _selectedDay.day)] ??
              "Sin turno asignado",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: _turnos[DateTime.utc(_selectedDay.year,
                        _selectedDay.month, _selectedDay.day)] ==
                    "Día libre"
                ? Colors.green
                : theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: () {
            String turno = _turnos[DateTime.utc(_selectedDay.year,
                    _selectedDay.month, _selectedDay.day)] ??
                "Sin turno asignado";
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TurnoDetallesScreen(
                  selectedDay: _selectedDay,
                  turno: turno,
                ),
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.primary,
            padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 30),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: const Text(
            "Ver Turno",
            style: TextStyle(fontSize: 18, color: Colors.white),
          ),
        ),
      ],
    );
  }
}
