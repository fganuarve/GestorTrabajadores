import 'package:flutter/material.dart';

class Shift {
  final String id;
  final String userId; // Original publisher of the shift
  final DateTime date;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final String status; // 'available', 'taken', 'completed'
  final String role;
  final DateTime? publishedAt;
  final bool isPublished;
  final String? assignedTo; // User ID of who took the shift
  final String? requestedBy; // User ID of who requested the shift
  final DateTime? requestedAt;
  final String? notes;
  final bool isAvailable;

  const Shift({
    required this.id,
    required this.userId,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.status,
    required this.role,
    this.publishedAt,
    this.isPublished = false,
    this.assignedTo,
    this.requestedBy,
    this.requestedAt,
    this.notes,
    this.isAvailable = true,
  });
  
  // Create a new available shift
  factory Shift.create({
    required String userId,
    required DateTime date,
    required TimeOfDay startTime,
    required TimeOfDay endTime,
    required String role,
    bool publish = false,
  }) {
    return Shift(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      date: date,
      startTime: startTime,
      endTime: endTime,
      role: role,
      status: 'available',
      isPublished: publish,
      isAvailable: true,
      publishedAt: publish ? DateTime.now() : null,
    );
  }

  // Convertir a Map para guardar en la base de datos
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'requestedBy': requestedBy,
      'date': '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
      'startTime': '${startTime.hour}:${startTime.minute.toString().padLeft(2, '0')}',
      'endTime': '${endTime.hour}:${endTime.minute.toString().padLeft(2, '0')}',
      'role': role,
      'status': status,
      'isPublished': isPublished,
      'publishedAt': publishedAt?.toIso8601String(),
    };
  }

  // Create a Shift from a Map
  factory Shift.fromJson(Map<String, dynamic> json) {
    try {
      final date = json['date'] as String? ?? '';
      final startTime = json['startTime'] as String? ?? '00:00';
      final endTime = json['endTime'] as String? ?? '00:00';
      
      final dateParts = date.split('-');
      final startParts = startTime.split(':');
      final endParts = endTime.split(':');
      
      // Ensure required fields are not null
      final id = json['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString();
      final userId = json['userId']?.toString() ?? '';
      
      return Shift(
        id: id,
        userId: userId,
        assignedTo: json['assignedTo']?.toString(),
        date: DateTime(
          dateParts.length >= 1 ? int.tryParse(dateParts[0]) ?? DateTime.now().year : DateTime.now().year,
          dateParts.length >= 2 ? int.tryParse(dateParts[1]) ?? 1 : 1,
          dateParts.length >= 3 ? int.tryParse(dateParts[2]) ?? 1 : 1,
        ),
        startTime: TimeOfDay(
          hour: startParts.isNotEmpty ? int.tryParse(startParts[0]) ?? 0 : 0,
          minute: startParts.length > 1 ? int.tryParse(startParts[1]) ?? 0 : 0,
        ),
        endTime: TimeOfDay(
          hour: endParts.isNotEmpty ? int.tryParse(endParts[0]) ?? 0 : 0,
          minute: endParts.length > 1 ? int.tryParse(endParts[1]) ?? 0 : 0,
        ),
        role: json['role']?.toString() ?? '',
        status: json['status']?.toString() ?? 'available',
        isPublished: json['isPublished'] == true,
        publishedAt: json['publishedAt'] != null 
            ? DateTime.tryParse(json['publishedAt'].toString()) 
            : null,
        requestedBy: json['requestedBy']?.toString(),
        requestedAt: json['requestedAt'] != null
            ? DateTime.tryParse(json['requestedAt'].toString())
            : null,
        notes: json['notes']?.toString(),
      );
    } catch (e) {
      print('Error in Shift.fromJson: $e');
      rethrow;
    }
  }

  // Create a copy of the shift with updated fields
  Shift copyWith({
    String? id,
    String? userId,
    DateTime? date,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
    String? status,
    String? role,
    DateTime? publishedAt,
    bool? isPublished,
    String? assignedTo,
    String? requestedBy,
    DateTime? requestedAt,
    String? notes,
    bool? isAvailable,
  }) {
    return Shift(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      date: date ?? this.date,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      status: status ?? this.status,
      role: role ?? this.role,
      publishedAt: publishedAt ?? this.publishedAt,
      isPublished: isPublished ?? this.isPublished,
      assignedTo: assignedTo ?? this.assignedTo,
      requestedBy: requestedBy ?? this.requestedBy,
      requestedAt: requestedAt ?? this.requestedAt,
      notes: notes ?? this.notes,
      isAvailable: isAvailable ?? this.isAvailable,
    );
  }

  // Create a Shift from database data
  factory Shift.fromDb(Map<String, dynamic> dbData) {
    try {
      // Manejar valores nulos con operadores null-aware
      final fecha = (dbData['j.Fecha'] ?? dbData['Fecha'] ?? '').toString();
      final horaInicio = (dbData['j.HoraInicio'] ?? dbData['HoraInicio'] ?? '00:00:00').toString();
      final horaFin = (dbData['j.HoraFin'] ?? dbData['HoraFin'] ?? '00:00:00').toString();
      final puesto = (dbData['t.Puesto'] ?? dbData['Puesto'] ?? '').toString();
      final estado = (dbData['j.Estado'] ?? dbData['Estado'] ?? 'Disponible').toString().toLowerCase();
      
      // Parsear fechas y horas con mejor manejo de errores
      DateTime? parsedDate;
      TimeOfDay? parsedStartTime;
      TimeOfDay? parsedEndTime;

      try {
        final fechaParts = fecha.split('-');
        if (fechaParts.length >= 3) {
          final year = int.tryParse(fechaParts[0]) ?? DateTime.now().year;
          final month = int.tryParse(fechaParts[1]) ?? 1;
          final day = int.tryParse(fechaParts[2]) ?? 1;
          parsedDate = DateTime(year, month, day);
        } else {
          parsedDate = DateTime.now();
        }
      } catch (e) {
        print('Error al parsear la fecha: $e');
        parsedDate = DateTime.now();
      }

      try {
        final startParts = horaInicio.split(':');
        if (startParts.length >= 2) {
          parsedStartTime = TimeOfDay(
            hour: int.tryParse(startParts[0]) ?? 0,
            minute: int.tryParse(startParts[1]) ?? 0,
          );
        } else {
          parsedStartTime = const TimeOfDay(hour: 0, minute: 0);
        }
      } catch (e) {
        print('Error al parsear la hora de inicio: $e');
        parsedStartTime = const TimeOfDay(hour: 0, minute: 0);
      }

      try {
        final endParts = horaFin.split(':');
        if (endParts.length >= 2) {
          parsedEndTime = TimeOfDay(
            hour: int.tryParse(endParts[0]) ?? 0,
            minute: int.tryParse(endParts[1]) ?? 0,
          );
        } else {
          parsedEndTime = const TimeOfDay(hour: 0, minute: 0);
        }
      } catch (e) {
        print('Error al parsear la hora de fin: $e');
        parsedEndTime = const TimeOfDay(hour: 0, minute: 0);
      }

      final shift = Shift(
        id: dbData['j.ID']?.toString() ?? dbData['ID']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
        userId: dbData['j.TrabajadorID']?.toString() ?? dbData['TrabajadorID']?.toString() ?? '',
        date: parsedDate,
        startTime: parsedStartTime,
        endTime: parsedEndTime,
        role: puesto.isEmpty ? 'Desconocido' : puesto,
        status: estado,
        assignedTo: dbData['AsignadoA']?.toString(),
        requestedBy: dbData['SolicitadoPor']?.toString(),
        requestedAt: dbData['FechaSolicitud'] != null 
            ? DateTime.tryParse(dbData['FechaSolicitud'].toString())
            : null,
        notes: dbData['Notas']?.toString(),
        isPublished: (dbData['Publicado'] ?? 0) == 1,
        publishedAt: dbData['FechaPublicacion'] != null
            ? DateTime.tryParse(dbData['FechaPublicacion'].toString())
            : null,
      );
      
      return shift;
    } catch (e) {
      print('Error en Shift.fromDb: $e');
      // Devolver un turno por defecto en caso de error
      return Shift(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: '',
        date: DateTime.now(),
        startTime: const TimeOfDay(hour: 0, minute: 0),
        endTime: const TimeOfDay(hour: 0, minute: 0),
        status: 'error',
        role: 'Error',
      );
    }
  }
}
