import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:front_end_gui/cubit/shift_cubit.dart';
import 'package:front_end_gui/models/shift_model.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RequestShiftScreen extends StatefulWidget {
  final DateTime selectedDate;
  final String userId;
  final Shift? existingShift;

  const RequestShiftScreen({
    Key? key,
    required this.selectedDate,
    required this.userId,
    this.existingShift,
  }) : super(key: key);

  @override
  _RequestShiftScreenState createState() => _RequestShiftScreenState();
}

class _RequestShiftScreenState extends State<RequestShiftScreen> {
  final _formKey = GlobalKey<FormState>();
  late DateTime _startDate;
  late TimeOfDay _startTime;
  late DateTime _endDate;
  late TimeOfDay _endTime;
  final TextEditingController _notesController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    
    if (widget.existingShift != null) {
      final shift = widget.existingShift!;
      _startDate = shift.date;
      _endDate = shift.date;
      _startTime = shift.startTime;
      _endTime = shift.endTime;
    } else {
      _startDate = widget.selectedDate;
      _endDate = widget.selectedDate;
      _startTime = TimeOfDay.now();
      _endTime = TimeOfDay(
        hour: TimeOfDay.now().hour + 1,
        minute: TimeOfDay.now().minute,
      );
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _selectTime(BuildContext context, bool isStart) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;

    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final startDateTime = DateTime(
        _startDate.year,
        _startDate.month,
        _startDate.day,
        _startTime.hour,
        _startTime.minute,
      );
      
      final endDateTime = DateTime(
        _endDate.year,
        _endDate.month,
        _endDate.day,
        _endTime.hour,
        _endTime.minute,
      );

      // Validations
      if (endDateTime.isBefore(startDateTime)) {
        throw Exception('La hora de fin debe ser posterior a la hora de inicio');
      }
      
      final now = DateTime.now();
      if (startDateTime.isBefore(now.subtract(const Duration(minutes: 1)))) {
        throw Exception('No se puede solicitar un turno en el pasado');
      }

      // Validate minimum shift duration (e.g., at least 30 minutes)
      final minDuration = const Duration(minutes: 30);
      if (endDateTime.difference(startDateTime) < minDuration) {
        throw Exception('El turno debe tener al menos 30 minutos de duración');
      }

      final shift = widget.existingShift != null
          ? widget.existingShift!.copyWith(
              startTime: _startTime,
              endTime: _endTime,
              status: 'taken',
              requestedBy: widget.userId,
              requestedAt: DateTime.now(),
              notes: _notesController.text.isNotEmpty
                  ? _notesController.text
                  : 'Solicitado por el usuario',
            )
          : Shift.create(
              userId: widget.userId,
              date: _startDate,
              startTime: _startTime,
              endTime: _endTime,
              role: widget.existingShift?.role ?? 'General',
            ).copyWith(
              status: 'requested',
              requestedBy: widget.userId,
              requestedAt: DateTime.now(),
              notes: _notesController.text.isNotEmpty
                  ? _notesController.text
                  : 'Solicitud de turno',
            );

      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');
      if (userId == null) {
        throw Exception('No se pudo obtener el ID del usuario');
      }
      
      await context.read<ShiftCubit>().requestShift(
        shift.id,
        userId,
        notes: _notesController.text.isNotEmpty ? _notesController.text : 'Solicitud de turno',
      );
      
      if (mounted) {
        // Mostrar mensaje de éxito
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Turno solicitado correctamente'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Cerrar la pantalla y regresar a la pantalla anterior
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        // Mostrar mensaje de error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildDateField(String label, DateTime date, bool isStart) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => _selectDate(context, isStart),
          borderRadius: BorderRadius.circular(4),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade400),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat('EEEE d MMMM y', 'es_ES').format(date),
                  style: const TextStyle(fontSize: 16, color: Colors.black87),
                ),
                const Icon(Icons.calendar_today, size: 20, color: Colors.grey),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeField(String label, TimeOfDay time, bool isStart) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => _selectTime(context, isStart),
          borderRadius: BorderRadius.circular(4),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade400),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
                  style: const TextStyle(fontSize: 16, color: Colors.black87),
                ),
                const Icon(Icons.access_time, size: 20, color: Colors.grey),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingShift != null ? 'Editar Turno' : 'Solicitar Turno'),
        elevation: 0,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildDateField('Fecha de inicio', _startDate, true),
            const SizedBox(height: 16),
            _buildTimeField('Hora de inicio', _startTime, true),
            const SizedBox(height: 16),
            _buildDateField('Fecha de fin', _endDate, false),
            const SizedBox(height: 16),
            _buildTimeField('Hora de fin', _endTime, false),
            const SizedBox(height: 24),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notas (opcional)',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 32),
            _buildSubmitButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      height: 50,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submitRequest,
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).primaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          elevation: 0,
        ),
        child: _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                widget.existingShift != null ? 'ACTUALIZAR TURNO' : 'SOLICITAR TURNO',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
      ),
    );
  }
}
