import 'database_service.dart';

class DebugService {
  final DatabaseService _dbService = DatabaseService();

  Future<void> checkShiftsInDatabase() async {
    try {
      print('=== DEPURACIÓN: Verificando turnos en la base de datos ===');
      
      // Conectar a la base de datos
      await _dbService.initialize();
      
      // Consultar los últimos 10 turnos
      final results = await _dbService.query('''
        SELECT j.*, t.Puesto 
        FROM gestionturnos.jornada j
        LEFT JOIN gestionturnos.trabajadorsanitario t ON j.TrabajadorID = t.ID
        ORDER BY j.Fecha DESC, j.HoraInicio DESC
        LIMIT 10
      ''');
      
      print('=== Turnos encontrados (${results.length}) ===');
      for (var row in results) {
        print('ID: ${row['j.ID']}');
        print('  - Fecha: ${row['j.Fecha']}');
        print('  - Hora Inicio: ${row['j.HoraInicio']}');
        print('  - Hora Fin: ${row['j.HoraFin']}');
        print('  - Estado: ${row['j.Estado']}');
        print('  - TrabajadorID: ${row['j.TrabajadorID']}');
        print('  - Puesto: ${row['t.Puesto']}');
        print('----------------------------------------');
      }
      
    } catch (e) {
      print('Error al verificar turnos: $e');
      rethrow;
    }
  }
  
  // Patrón singleton
  static final DebugService _instance = DebugService._internal();
  factory DebugService() => _instance;
  DebugService._internal();
}
