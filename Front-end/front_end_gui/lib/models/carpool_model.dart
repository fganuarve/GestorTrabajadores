

import 'package:flutter/material.dart';

class Carpool {
  final String id;
  final String driverId;
  final String driverName;
  final DateTime date;
  final TimeOfDay time;
  final String origin;
  final String destination;
  final int availableSeats;
  final List<String> passengers;
  final String? notes;

  Carpool({
    required this.id,
    required this.driverId,
    required this.driverName,
    required this.date,
    required this.time,
    required this.origin,
    required this.destination,
    required this.availableSeats,
    this.notes,
    List<String>? passengers,
  }) : passengers = passengers ?? [];

  factory Carpool.fromJson(Map<String, dynamic> json) {
    // Intentar obtener la hora de diferentes campos según la estructura del backend
    String timeStr = '';
    if (json['horaSalida'] != null) {
      timeStr = json['horaSalida'].toString();
    } else if (json['hora'] != null) {
      timeStr = json['hora'].toString();
    } else if (json['time'] != null) {
      timeStr = json['time'].toString();
    }
    
    // Parsear la hora
    final timeParts = timeStr.split(':');
    final time = TimeOfDay(
      hour: int.tryParse(timeParts[0]) ?? 0,
      minute: timeParts.length > 1 ? int.tryParse(timeParts[1]) ?? 0 : 0,
    );

    // Obtener la fecha, intentando diferentes formatos
    DateTime date;
    if (json['fecha'] != null) {
      date = DateTime.tryParse(json['fecha'].toString()) ?? DateTime.now();
    } else if (json['fechaSalida'] != null) {
      date = DateTime.tryParse(json['fechaSalida'].toString()) ?? DateTime.now();
    } else if (json['date'] != null) {
      date = json['date'] is String 
          ? DateTime.tryParse(json['date']) ?? DateTime.now()
          : DateTime.now();
    } else {
      date = DateTime.now();
    }

    // Obtener el conductor
    final driver = json['conductor'] is Map<String, dynamic> 
        ? json['conductor']
        : json['driver'] is Map<String, dynamic>
            ? json['driver']
            : null;

    return Carpool(
      id: json['id']?.toString() ?? json['idViaje']?.toString() ?? '',
      driverId: json['idConductor']?.toString() ?? 
               driver?['id']?.toString() ?? 
               json['driverId']?.toString() ?? '',
      driverName: '${driver?['nombre'] ?? ''} ${driver?['apellido1'] ?? ''}'.trim(),
      date: date,
      time: time,
      origin: json['origen']?.toString() ?? json['origin']?.toString() ?? '',
      destination: json['destino']?.toString() ?? json['destination']?.toString() ?? '',
      availableSeats: (json['plazasDisponibles'] as num?)?.toInt() ?? 
                     (json['availableSeats'] as num?)?.toInt() ?? 1,
      notes: json['notas']?.toString() ?? json['notes']?.toString(),
      passengers: json['pasajeros'] is List 
          ? List<String>.from(json['pasajeros'].map((p) => p.toString()))
          : json['passengers'] is List
              ? List<String>.from(json['passengers'].map((p) => p.toString()))
              : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'driverId': driverId,
      'driverName': driverName,
      'date': date.toIso8601String(),
      'time': '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
      'origin': origin,
      'destination': destination,
      'availableSeats': availableSeats,
      if (notes != null) 'notes': notes,
      'passengers': passengers,
    };
  }

  Carpool copyWith({
    String? id,
    String? driverId,
    String? driverName,
    DateTime? date,
    TimeOfDay? time,
    String? origin,
    String? destination,
    int? availableSeats,
    String? notes,
    List<String>? passengers,
  }) {
    return Carpool(
      id: id ?? this.id,
      driverId: driverId ?? this.driverId,
      driverName: driverName ?? this.driverName,
      date: date ?? this.date,
      time: time ?? this.time,
      origin: origin ?? this.origin,
      destination: destination ?? this.destination,
      availableSeats: availableSeats ?? this.availableSeats,
      notes: notes ?? this.notes,
      passengers: passengers ?? this.passengers,
    );
  }
}
