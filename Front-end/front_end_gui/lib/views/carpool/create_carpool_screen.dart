import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:front_end_gui/services/carpool_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CreateCarpoolScreen extends StatefulWidget {
  final DateTime? selectedDate;

  const CreateCarpoolScreen({Key? key, this.selectedDate}) : super(key: key);

  @override
  _CreateCarpoolScreenState createState() => _CreateCarpoolScreenState();
}

class _CreateCarpoolScreenState extends State<CreateCarpoolScreen> {
  final _formKey = GlobalKey<FormState>();
  late final CarpoolService _carpoolService;
  bool _isInitialized = false;
  
  final _originController = TextEditingController();
  final _destinationController = TextEditingController();
  final _seatsController = TextEditingController(text: '1');
  final _notesController = TextEditingController();
  
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeServices();
    if (widget.selectedDate != null) {
      _selectedDate = widget.selectedDate!;
    }
  }

  Future<void> _initializeServices() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _carpoolService = CarpoolService(prefs: prefs);
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al inicializar los servicios: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _originController.dispose();
    _destinationController.dispose();
    _seatsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Obtener los datos del usuario desde SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final userData = prefs.getString('user_data');
      
      if (userData == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No se pudo obtener la información del usuario. Por favor, cierra sesión y vuelve a iniciar.'),
            ),
          );
        }
        return;
      }

      // Parsear los datos del usuario
      final user = Map<String, dynamic>.from(jsonDecode(userData));
      
      // Verificar que los campos requeridos del usuario estén presentes
      final dynamic userIdValue = user['id'];
      
      // Asegurarse de que el ID sea un número válido
      final int? userId = userIdValue is int 
          ? userIdValue 
          : (userIdValue is String && userIdValue.isNotEmpty) 
              ? int.tryParse(userIdValue) 
              : null;
      
      final userName = user['nombre']?.toString() ?? '';
      final userLastName = user['apellido1']?.toString() ?? '';
      
      if (userId == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('ID de usuario no válido (${user['id']}). Por favor, cierra sesión y vuelve a iniciar.'),
            ),
          );
        }
        return;
      }

      // Crear el viaje
      await _carpoolService.createCarpool(
        driverId: userId.toString(),  // Asegurarse de que el ID sea un string
        driverName: '$userName $userLastName'.trim(),
        date: _selectedDate,
        time: _selectedTime,
        origin: _originController.text,
        destination: _destinationController.text,
        availableSeats: int.parse(_seatsController.text),
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      );

      if (mounted) {
        Navigator.of(context).pop(true); // Retorna true para indicar éxito
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al crear el viaje: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Publicar Viaje Compartido'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _originController,
                      decoration: const InputDecoration(
                        labelText: 'Origen',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor ingresa el origen';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _destinationController,
                      decoration: const InputDecoration(
                        labelText: 'Destino',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor ingresa el destino';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ListTile(
                            title: Text(
                              'Fecha: ${DateFormat('dd/MM/yyyy').format(_selectedDate)}',
                            ),
                            trailing: const Icon(Icons.calendar_today),
                            onTap: () => _selectDate(context),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ListTile(
                            title: Text(
                              'Hora: ${_selectedTime.format(context)}',
                            ),
                            trailing: const Icon(Icons.access_time),
                            onTap: () => _selectTime(context),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _seatsController,
                      decoration: const InputDecoration(
                        labelText: 'Plazas disponibles',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor ingresa el número de plazas';
                        }
                        final seats = int.tryParse(value);
                        if (seats == null || seats < 1) {
                          return 'Debe haber al menos 1 plaza disponible';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _notesController,
                      decoration: const InputDecoration(
                        labelText: 'Notas (opcional)',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _submitForm,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text(
                        'Publicar Viaje',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
