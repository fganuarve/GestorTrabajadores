import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:front_end_gui/cubit/shift_cubit.dart';
import 'package:front_end_gui/models/shift_model.dart';
import 'package:front_end_gui/views/shift/request_shift_screen.dart';
import 'package:intl/intl.dart';

class ViewShiftsScreen extends StatelessWidget {
  final DateTime date;
  final List<Shift> availableShifts;
  final String userRole;
  final String userId;

  const ViewShiftsScreen({
    Key? key,
    required this.date,
    required this.availableShifts,
    required this.userRole,
    required this.userId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Turnos - ${DateFormat('dd/MM/yyyy').format(date)}',
        ),
        actions: [
          if (availableShifts.isEmpty)
            TextButton(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RequestShiftScreen(
                      selectedDate: date,
                      userId: userId,
                    ),
                  ),
                );
                
                if (result == true && context.mounted) {
                  // Refresh shifts if a new one was added
                  context.read<ShiftCubit>().loadShiftsByDate(date);
                }
              },
              child: const Text('Solicitar Turno', style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
      body: availableShifts.isEmpty
          ? _buildNoShiftsView(context)
          : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: availableShifts.length,
              itemBuilder: (context, index) {
                final shift = availableShifts[index];
                return _buildShiftCard(context, shift);
              },
            ),
    );
  }
  
  Widget _buildNoShiftsView(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.calendar_today, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'No hay turnos disponibles para este día.',
            style: TextStyle(fontSize: 18, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => RequestShiftScreen(
                    selectedDate: date,
                    userId: userId,
                  ),
                ),
              );
              
              if (result == true && context.mounted) {
                // Refresh shifts if a new one was added
                context.read<ShiftCubit>().loadShiftsByDate(date);
              }
            },
            icon: const Icon(Icons.add),
            label: const Text('Solicitar Turno'),
          ),
        ],
      ),
    );
  }

  Widget _buildShiftCard(BuildContext context, Shift shift) {
    final timeFormat = DateFormat('HH:mm');
    final startTime = DateTime(
      shift.date.year,
      shift.date.month,
      shift.date.day,
      shift.startTime.hour,
      shift.startTime.minute,
    );
    final endTime = DateTime(
      shift.date.year,
      shift.date.month,
      shift.date.day,
      shift.endTime.hour,
      shift.endTime.minute,
    );

    // Verificar el estado del turno
    final isAvailable = shift.status == 'available' || shift.status == 'Disponible';
    final isTaken = shift.status == 'taken' || 
                   shift.status == 'approved' || 
                   shift.status == 'Ocupado';
    final isMyShift = shift.userId == userId;

    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${timeFormat.format(startTime)} - ${timeFormat.format(endTime)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                _buildStatusChip(shift.status),
              ],
            ),
            const SizedBox(height: 8),
            if (shift.role.isNotEmpty) ...[
              Text(
                'Rol: ${_capitalizeFirstLetter(shift.role)}',
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 4),
            ],
            const SizedBox(height: 12),
            if (isMyShift)
              _buildActionButton(
                context,
                'Tú tienes este turno',
                Icons.check_circle,
                Colors.green,
                () {
                  // Mostrar detalles del turno
                  _showShiftDetails(context, shift);
                },
              )
            else if (isTaken)
              _buildActionButton(
                context,
                'Turno Ocupado',
                Icons.block,
                Colors.grey,
                null, // Botón deshabilitado
              )
            else if (isAvailable)
              _buildActionButton(
                context,
                'Solicitar Turno',
                Icons.add,
                Theme.of(context).primaryColor,
                () async {
                  // Verificar si el usuario ya tiene un turno en esta fecha
                  final hasShift = await context.read<ShiftCubit>().hasShiftOnDate(userId, shift.date);
                  
                  if (hasShift && context.mounted) {
                    // Mostrar mensaje de error
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Ya tienes un turno asignado para esta fecha'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                    return;
                  }
                  
                  // Navegar a la pantalla de solicitud de turno
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RequestShiftScreen(
                        selectedDate: shift.date,
                        userId: userId,
                        existingShift: shift,
                      ),
                    ),
                  );
                  
                  if (result == true && context.mounted) {
                    // Actualizar la lista de turnos
                    context.read<ShiftCubit>().loadShiftsByDate(shift.date);
                    
                    // Mostrar mensaje de éxito
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Turno solicitado correctamente'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color statusColor;
    String statusText;

    switch (status) {
      case 'available':
        statusColor = Colors.blue;
        statusText = 'Disponible';
        break;
      case 'taken':
        statusColor = Colors.orange;
        statusText = 'Ocupado';
        break;
      case 'completed':
        statusColor = Colors.green;
        statusText = 'Completado';
        break;
      default:
        statusColor = Colors.grey;
        statusText = 'Desconocido';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor),
      ),
      child: Text(
        statusText,
        style: TextStyle(
          color: statusColor,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    String text,
    IconData icon,
    Color color,
    VoidCallback? onPressed,
  ) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color.withOpacity(0.1),
          foregroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: color),
          ),
        ),
        icon: Icon(icon, color: color),
        label: Text(
          text,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  String _capitalizeFirstLetter(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }
  
  void _showShiftDetails(BuildContext context, Shift shift) {
    final timeFormat = DateFormat('HH:mm');
    final dateFormat = DateFormat('dd/MM/yyyy');
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Detalles del Turno'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Fecha:', dateFormat.format(shift.date)),
              const SizedBox(height: 8),
              _buildDetailRow('Hora de inicio:', timeFormat.format(DateTime(0, 0, 0, shift.startTime.hour, shift.startTime.minute))),
              const SizedBox(height: 8),
              _buildDetailRow('Hora de fin:', timeFormat.format(DateTime(0, 0, 0, shift.endTime.hour, shift.endTime.minute))),
              const SizedBox(height: 8),
              _buildDetailRow('Estado:', _getStatusText(shift.status)),
              if (shift.notes?.isNotEmpty ?? false) ...[
                const SizedBox(height: 8),
                _buildDetailRow('Notas:', shift.notes!),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
  
  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'available':
      case 'disponible':
        return 'Disponible';
      case 'taken':
      case 'ocupado':
        return 'Ocupado';
      case 'approved':
        return 'Aprobado';
      case 'completed':
        return 'Completado';
      case 'pending':
        return 'Pendiente';
      default:
        return status;
    }
  }
}
