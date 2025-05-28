import 'package:flutter/material.dart';
import '../models/shift_model.dart';
import 'database_service.dart';

class ShiftService {
  final DatabaseService _dbService = DatabaseService();
  
  // Add a new shift to the database
  Future<void> addShift(Shift shift) async {
    try {
      await _dbService.query('''
        INSERT INTO gestionturnos.jornada 
        (Fecha, HoraInicio, HoraFin, Estado, TrabajadorID, Rol, Publicado, FechaPublicacion, AsignadoA, SolicitadoPor, FechaSolicitud, Notas)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      ''', [
        shift.date.toString().split(' ')[0],
        '${shift.startTime.hour.toString().padLeft(2, '0')}:${shift.startTime.minute.toString().padLeft(2, '0')}:00',
        '${shift.endTime.hour.toString().padLeft(2, '0')}:${shift.endTime.minute.toString().padLeft(2, '0')}:00',
        shift.status,
        shift.userId,
        shift.role,
        shift.isPublished ? 1 : 0,
        shift.publishedAt?.toIso8601String(),
        shift.assignedTo,
        shift.requestedBy,
        shift.requestedAt?.toIso8601String(),
        shift.notes,
      ]);
    } catch (e) {
      throw Exception('Failed to add shift: $e');
    }
  }
  
  // Publish a shift to make it available for others to request
  Future<void> publishShift({
    required String userId,
    required DateTime date,
    required TimeOfDay startTime,
    required TimeOfDay endTime,
    required String role,
  }) async {
    try {
      print('Publicando turno con datos:');
      print('- Usuario: $userId');
      print('- Fecha: $date');
      print('- Hora Inicio: $startTime');
      print('- Hora Fin: $endTime');
      print('- Rol: $role');
      
      await _dbService.query('''
        INSERT INTO gestionturnos.jornada 
        (UserID, Fecha, HoraInicio, HoraFin, Estado, IsPublished, PublishedAt, Puesto)
        VALUES (?, ?, ?, ?, 'Disponible', 1, NOW(), ?)
      ''', [
        int.tryParse(userId),
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
        '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}:00',
        '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}:00',
        role
      ]);
      
      print('Turno publicado correctamente');
    } catch (e) {
      print('Error al publicar turno: $e');
      rethrow;
    }
  }
  
  // Request an available shift
  Future<void> requestShift(String shiftId, String userId, {String? notes}) async {
    try {
      print('Solicitando turno $shiftId para el usuario $userId');
      
      // First, verify the shift is available
      final results = await _dbService.query(
        'SELECT * FROM gestionturnos.jornada WHERE ID = ? AND Estado = "Disponible"',
        [int.tryParse(shiftId)]
      );
      
      if (results.isEmpty) {
        throw Exception('El turno no está disponible');
      }
      
      // Update the shift to assign it to the user
      await _dbService.query('''
        UPDATE gestionturnos.jornada 
        SET Estado = 'Solicitado', 
            TrabajadorID = ?
        WHERE ID = ? AND Estado = 'Disponible'
      ''', [int.tryParse(userId), int.tryParse(shiftId)]);
      
      print('Turno asignado correctamente');
    } catch (e) {
      print('Error al solicitar turno: $e');
      rethrow;
    }
  }
  
  // Get shifts for a specific user
  Future<List<Shift>> getShiftsByUser(String userId) async {
    try {
      final results = await _dbService.query('''
        SELECT * FROM gestionturnos.jornada 
        WHERE TrabajadorID = ?
        ORDER BY Fecha, HoraInicio
      ''', [userId]);
      
      return results.map((row) => _shiftFromMap(row.fields)).toList();
    } catch (e) {
      throw Exception('Failed to load shifts: $e');
    }
  }
  

  
  // Helper method to convert database row to Shift object
  Shift _shiftFromMap(Map<String, dynamic> map) {
    // Función para convertir hora a TimeOfDay
    TimeOfDay _parseTime(dynamic timeValue) {
      if (timeValue == null) {
        return const TimeOfDay(hour: 0, minute: 0);
      } else if (timeValue is Duration) {
        // Si es un Duration, convertirlo a TimeOfDay
        final hours = timeValue.inHours % 24;
        final minutes = timeValue.inMinutes % 60;
        return TimeOfDay(hour: hours, minute: minutes);
      } else if (timeValue is String) {
        // Si es un String, parsearlo
        final parts = timeValue.split(':');
        return TimeOfDay(
          hour: int.tryParse(parts[0]) ?? 0,
          minute: parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0,
        );
      } else {
        // Valor por defecto si no se puede parsear
        return const TimeOfDay(hour: 0, minute: 0);
      }
    }
    
    // Función para convertir cualquier valor a String de forma segura
    String _toString(dynamic value) {
      if (value == null) return '';
      return value.toString();
    }
    
    // Función para convertir a entero de forma segura
    int _toInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }
    
    // Obtener las horas de inicio y fin
    final startTime = _parseTime(map['HoraInicio']);
    final endTime = _parseTime(map['HoraFin']);
    
    // Función para parsear fechas de forma segura
    DateTime? _parseDate(dynamic dateValue) {
      if (dateValue == null) return null;
      
      if (dateValue is DateTime) {
        return dateValue;
      } else if (dateValue is String) {
        try {
          // Si la cadena ya está en formato DateTime
          if (dateValue.contains(' ')) {
            return DateTime.parse(dateValue);
          }
          // Si es solo la fecha (YYYY-MM-DD)
          final dateParts = dateValue.split('-');
          if (dateParts.length == 3) {
            return DateTime(
              int.parse(dateParts[0]),
              int.parse(dateParts[1]),
              int.parse(dateParts[2])
            );
          }
          // Si es en otro formato, intentar parsear directamente
          return DateTime.parse(dateValue);
        } catch (e) {
          print('Error al parsear fecha: $dateValue. Error: $e');
          return null;
        }
      }
      print('Tipo de fecha no soportado: ${dateValue.runtimeType}');
      return null;
    }
    
    return Shift(
      id: _toString(map['JornadaID'] ?? map['ID'] ?? ''),
      userId: _toString(map['TrabajadorID'] ?? map['userId'] ?? ''),
      date: _parseDate(map['Fecha']) ?? DateTime.now(),
      startTime: startTime,
      endTime: endTime,
      status: _toString(map['Estado']),
      role: _toString(map['Rol'] ?? map['Puesto'] ?? ''),
      isPublished: _toInt(map['Publicado']) == 1,
      publishedAt: _parseDate(map['FechaPublicacion']),
      assignedTo: map['AsignadoA']?.toString(),
      requestedBy: map['SolicitadoPor']?.toString(),
      requestedAt: _parseDate(map['FechaSolicitud']),
      notes: _toString(map['Notas']),
    );
  }

  // Obtener todos los turnos
  Future<List<Shift>> getShifts() async {
    try {
      final results = await _dbService.query('''
        SELECT j.*, t.* FROM gestionturnos.jornada j
        LEFT JOIN gestionturnos.trabajadorsanitario t ON j.TrabajadorID = t.ID
      ''');

      return results.map((row) => Shift.fromDb(row.fields)).toList();
    } catch (e) {
      print('Error al obtener turnos: $e');
      return [];
    }
  }

  // Obtener turnos por fecha
  Future<List<Shift>> getShiftsByDate(DateTime date) async {
    try {
      final formattedDate = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      print('Buscando turnos para la fecha: $formattedDate');
      
      final results = await _dbService.query('''
        SELECT j.*, t.* FROM gestionturnos.jornada j
        LEFT JOIN gestionturnos.trabajadorsanitario t ON j.TrabajadorID = t.ID
        WHERE j.Fecha = ?
      ''', [formattedDate]);

      print('Resultados de la consulta:');
      for (var row in results) {
        print('  - ID: ${row['j.ID']}, Fecha: ${row['j.Fecha']}, HoraInicio: ${row['j.HoraInicio']}, Estado: ${row['j.Estado']}');
      }

      final shifts = results.map((row) => Shift.fromDb(row.fields)).toList();
      print('Turnos convertidos a objetos: ${shifts.length}');
      
      return shifts;
    } catch (e) {
      print('Error al obtener turnos por fecha: $e');
      rethrow;
    }
  }

  // Obtener turnos por rol
  Future<List<Shift>> getShiftsByRole(String role) async {
    try {
      final results = await _dbService.query('''
        SELECT j.*, t.* FROM gestionturnos.jornada j
        LEFT JOIN gestionturnos.trabajadorsanitario t ON j.TrabajadorID = t.ID
        WHERE t.Puesto = ?
      ''', [role]);

      return results.map((row) => Shift.fromDb(row.fields)).toList();
    } catch (e) {
      print('Error al obtener turnos por rol: $e');
      return [];
    }
  }

  // Get shifts for a specific user on a specific date
  Future<List<Shift>> getShiftsByUserAndDate(String userId, DateTime date) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));
      
      final results = await _dbService.query('''
        SELECT j.*, t.* FROM gestionturnos.jornada j
        LEFT JOIN gestionturnos.trabajadorsanitario t ON j.TrabajadorID = t.ID
        WHERE j.TrabajadorID = ? 
          AND j.Fecha >= ? 
          AND j.Fecha < ?
      ''', [
        userId, 
        startOfDay.toIso8601String(), 
        endOfDay.toIso8601String()
      ]);
      
      return results.map((row) => Shift.fromDb(row.fields)).toList();
    } catch (e) {
      print('Error al obtener turnos por usuario y fecha: $e');
      rethrow;
    }
  }

  // Get available shifts for a specific role on a specific date
  Future<List<Shift>> getAvailableShiftsByDateAndRole(DateTime date, String role) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));
      
      final results = await _dbService.query('''
        SELECT j.*, t.* FROM gestionturnos.jornada j
        LEFT JOIN gestionturnos.trabajadorsanitario t ON j.TrabajadorID = t.ID
        WHERE t.Puesto = ? 
          AND j.Estado = 'DISPONIBLE'
          AND j.Fecha >= ? 
          AND j.Fecha < ?
      ''', [
        role,
        startOfDay.toIso8601String(), 
        endOfDay.toIso8601String()
      ]);
      
      return results.map((row) => Shift.fromDb(row.fields)).toList();
    } catch (e) {
      print('Error al obtener turnos disponibles por fecha y rol: $e');
      rethrow;
    }
  }


  

  
  // Obtener mis turnos publicados
  Future<List<Shift>> getMyShifts(String userId) async {
    try {
      final results = await _dbService.query('''
        SELECT * FROM gestionturnos.jornada 
        WHERE UserID = ?
        ORDER BY Fecha DESC, HoraInicio
      ''', [int.tryParse(userId)]);
      
      return results.map((row) => Shift.fromDb(row.fields)).toList();
    } catch (e) {
      print('Error al obtener mis turnos: $e');
      return [];
    }
  }
  
  // Obtener turnos disponibles para solicitar
  Future<List<Shift>> getAvailableShifts(String userId) async {
    try {
      print('🔍 Buscando turnos disponibles para el usuario: $userId');
      
      // Obtener los turnos disponibles para el rol del usuario
      final query = '''
        SELECT j.*, t.Puesto
        FROM gestionturnos.jornada j
        LEFT JOIN gestionturnos.trabajadorsanitario t ON j.TrabajadorID = t.ID
        WHERE j.Estado = 'Disponible'
        AND (j.TrabajadorID IS NULL OR j.TrabajadorID != ?)
        ORDER BY j.Fecha, j.HoraInicio
      ''';
      
      final results = await _dbService.query(query, [int.tryParse(userId)]);
      
      print('✅ Turnos disponibles encontrados: ${results.length}');
      
      return results.map((row) => Shift.fromDb(row.fields)).toList();
    } catch (e) {
      print('❌ Error al obtener turnos disponibles: $e');
      rethrow;
    }
  }
  
  // Verificar si el usuario ya tiene un turno en una fecha específica
  // Este método ya está definido más abajo en el archivo
  
  // Obtener turnos disponibles para un día específico
  Future<List<Shift>> getAvailableShiftsForDate(DateTime date, String role) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));
      
      final results = await _dbService.query('''
        SELECT j.*, t.Puesto
        FROM gestionturnos.jornada j
        LEFT JOIN gestionturnos.trabajadorsanitario t ON j.TrabajadorID = t.ID
        WHERE j.Estado = 'Disponible'
        AND j.Fecha >= ? 
        AND j.Fecha < ?
        AND t.Puesto = ?
        ORDER BY j.HoraInicio
      ''', [
        startOfDay.toIso8601String(),
        endOfDay.toIso8601String(),
        role
      ]);
      
      return results.map((row) => Shift.fromDb(row.fields)).toList();
    } catch (e) {
      print('Error al obtener turnos para la fecha: $e');
      return [];
    }
  }
  
  // Actualizar un turno existente
  Future<void> updateShift(Shift shift) async {
    try {
      // Convertir el estado al formato de la base de datos
      String dbStatus;
      switch (shift.status) {
        case 'available':
          dbStatus = 'Disponible';
          break;
        case 'taken':
        case 'approved':
          dbStatus = 'Ocupado';
          break;
        case 'completed':
          dbStatus = 'Completado';
          break;
        default:
          dbStatus = 'Pendiente';
      }

      // Solo asignar TrabajadorID si el turno está siendo asignado a un trabajador
      final trabajadorId = (shift.status == 'taken' || shift.status == 'approved') && shift.userId.isNotEmpty
          ? int.tryParse(shift.userId)
          : null;
      
      print('Actualizando turno con ID: ${shift.id}');
      print('- Nuevo TrabajadorID: $trabajadorId');
      print('- Nuevo Estado: $dbStatus');
      
      await _dbService.query('''
        UPDATE gestionturnos.jornada 
        SET 
          Fecha = ?, 
          HoraInicio = ?, 
          HoraFin = ?, 
          Estado = ?, 
          TrabajadorID = ?
        WHERE ID = ?
      ''', [
        '${shift.date.year}-${shift.date.month.toString().padLeft(2, '0')}-${shift.date.day.toString().padLeft(2, '0')}',
        '${shift.startTime.hour.toString().padLeft(2, '0')}:${shift.startTime.minute.toString().padLeft(2, '0')}:00',
        '${shift.endTime.hour.toString().padLeft(2, '0')}:${shift.endTime.minute.toString().padLeft(2, '0')}:00',
        dbStatus,
        trabajadorId,
        int.tryParse(shift.id) ?? 0
      ]);
      
      print('Turno actualizado correctamente');
    } catch (e) {
      print('Error al actualizar turno: $e');
      rethrow;
    }
  }

  // Verificar si un usuario ya tiene turno en una fecha específica
  Future<bool> hasShiftOnDate(String userId, DateTime date) async {
    try {
      final formattedDate = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      
      final results = await _dbService.query('''
        SELECT COUNT(*) as count FROM gestionturnos.jornada 
        WHERE TrabajadorID = ? AND Fecha = ?
      ''', [userId, formattedDate]);

      return (results.first['count'] as int) > 0;
    } catch (e) {
      print('Error al verificar turno del usuario: $e');
      rethrow;
    }
  }
  
  // Obtener el turno del usuario para una fecha específica
  Future<Shift?> getUserShiftOnDate(String userId, DateTime date) async {
    try {
      final formattedDate = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      
      final results = await _dbService.query('''
        SELECT j.*, t.Puesto 
        FROM gestionturnos.jornada j
        LEFT JOIN gestionturnos.trabajadorsanitario t ON j.TrabajadorID = t.ID
        WHERE j.TrabajadorID = ? AND j.Fecha = ?
        LIMIT 1
      ''', [userId, formattedDate]);

      if (results.isEmpty) return null;
      
      return Shift.fromDb(results.first.fields);
    } catch (e) {
      print('Error al obtener turno del usuario: $e');
      rethrow;
    }
  }

  // Get a shift by its ID
  Future<Shift?> getShiftById(String id) async {
    try {
      final results = await _dbService.query(
        'SELECT j.*, t.* FROM gestionturnos.jornada j '
        'LEFT JOIN gestionturnos.trabajadorsanitario t ON j.TrabajadorID = t.ID '
        'WHERE j.ID = ?',
        [int.tryParse(id)],
      );

      if (results.isEmpty) return null;
      
      // Convert the database row to a map
      final row = results.first;
      final rowMap = Map<String, dynamic>.from(row.fields);
      
      // Format the data for the Shift.fromJson constructor
      final formattedDate = '${rowMap['Fecha']}';
      final startTime = '${rowMap['HoraInicio'] ?? '00:00:00'}'.split('.').first; // Remove milliseconds if present
      final endTime = '${rowMap['HoraFin'] ?? '00:00:00'}'.split('.').first; // Remove milliseconds if present
      
      final shiftData = {
        'id': rowMap['ID']?.toString() ?? '',
        'userId': rowMap['TrabajadorID']?.toString() ?? '',
        'date': formattedDate,
        'startTime': startTime,
        'endTime': endTime,
        'role': rowMap['Puesto']?.toString() ?? '',
        'status': (rowMap['Estado']?.toString().toLowerCase() == 'disponible') ? 'available' : 'taken',
        'isPublished': true,
        'isAvailable': (rowMap['Estado']?.toString().toLowerCase() == 'disponible'),
        'publishedAt': formattedDate,
      };
      
      return Shift.fromJson(shiftData);
    } catch (e) {
      print('Error al obtener el turno por ID: $e');
      rethrow;
    }
  }

  // Formatear fecha para consultas SQL
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  // Obtener turnos disponibles por rol
  Future<List<Shift>> getAvailableShiftsByRole(
    String role, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final now = DateTime.now();
      
      // Convertir el rol al formato de la base de datos
      String dbRole = role;
      if (role == 'ENFERMERO') {
        dbRole = 'Enfermero';
      } else if (role == 'MÉDICO' || role == 'MEDICO') {
        dbRole = 'Médico';
      } else if (role == 'TCAE') {
        dbRole = 'TCAE';
      }

      // Establecer fechas por defecto si no se proporcionan
      final startDateToUse = startDate ?? now;
      final endDateToUse = endDate ?? DateTime(now.year + 1, 12, 31);
      
      // Formatear fechas para la consulta
      final startDateStr = _formatDate(startDateToUse);
      final endDateStr = _formatDate(endDateToUse);

      print('=== BÚSQUEDA DE TURNOS DISPONIBLES ===');
      print('Rol: $role (convertido a: $dbRole)');
      print('Rango de fechas: $startDateStr a $endDateStr');

      // Consulta optimizada para obtener turnos disponibles
      final query = '''
        SELECT j.*, t.Puesto 
        FROM gestionturnos.jornada j
        LEFT JOIN gestionturnos.trabajadorsanitario t ON j.TrabajadorID = t.ID
        WHERE j.Estado = 'Disponible'
        AND (t.Puesto = ? OR j.TrabajadorID IS NULL)
        AND j.Fecha BETWEEN ? AND ?
        ORDER BY j.Fecha, j.HoraInicio
      ''';
      
      print('\n=== EJECUTANDO CONSULTA ===');
      print(query.trim());
      print('Parámetros:');
      print('- Rol: $dbRole');
      print('- Fecha inicio: $startDateStr');
      print('- Fecha fin: $endDateStr');
      
      // Ejecutar la consulta
      final results = await _dbService.query(query, [dbRole, startDateStr, endDateStr]);
      
      // Depuración: Mostrar resultados
      print('\n=== RESULTADOS ENCONTRADOS ===');
      if (results.isEmpty) {
        print('No se encontraron turnos con los criterios especificados');
        
        // Consulta de depuración: Ver qué turnos hay en la base de datos
        final allShifts = await _dbService.query('''
          SELECT j.ID, j.Fecha, j.HoraInicio, j.Estado, t.Puesto, t.ID as TrabajadorID
          FROM gestionturnos.jornada j
          LEFT JOIN gestionturnos.trabajadorsanitario t ON j.TrabajadorID = t.ID
          WHERE j.Fecha BETWEEN ? AND ?
          ORDER BY j.Fecha, j.HoraInicio
        ''', [startDateStr, endDateStr]);
        
        if (allShifts.isNotEmpty) {
          print('\n=== TURNOS ENCONTRADOS EN LA BASE DE DATOS ===');
          print('ID | Fecha | HoraInicio | Estado | TrabajadorID | Puesto');
          print('-' * 70);
          for (var row in allShifts) {
            print('${row['ID']} | ${row['Fecha']} | ${row['HoraInicio']} | ${row['Estado']} | ${row['TrabajadorID']} | ${row['Puesto']}');
          }
          
          // Verificar roles existentes en la base de datos
          final roles = await _dbService.query('''
            SELECT DISTINCT Puesto FROM gestionturnos.trabajadorsanitario
          ''');
          
          print('\n=== ROLES EXISTENTES EN LA BASE DE DATOS ===');
          for (var row in roles) {
            print('- ${row['Puesto']}');
          }
        } else {
          print('No hay turnos registrados en el rango de fechas especificado');
        }
      } else {
        print('Turnos encontrados: ${results.length}');
        for (var row in results) {
          print('ID: ${row['ID']}, Fecha: ${row['Fecha']}, Hora: ${row['HoraInicio']}, Estado: ${row['Estado']}');
        }
      }

      // Mapear resultados a objetos Shift
      return results.map((row) {
        try {
          return Shift.fromDb(row.fields);
        } catch (e) {
          print('Error al convertir fila a Shift: $e');
          print('Datos de la fila: ${row.fields}');
          rethrow;
        }
      }).toList();
    } catch (e) {
      print('Error al obtener turnos disponibles: $e');
      rethrow;
    }
  }
}
