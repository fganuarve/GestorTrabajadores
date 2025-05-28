import 'dart:async';
import 'package:mysql1/mysql1.dart';

class DatabaseService {
  // Singleton pattern
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  
  // Configuración de conexión local
  final String _host = 'localhost';
  final int _port = 3306;
  final String _user = 'root';
  final String _password = 'dani'; // Contraseña actualizada
  final String _dbName = 'gestionturnos';
  
  // Configuración de reconexión
  static const int _reconnectInterval = 5; // segundos
  static const int _maxReconnectAttempts = 5;
  
  // Configuración de conexión
  static const int _timeoutInSeconds = 30;
  
  MySqlConnection? _connection;
  bool _isInitialized = false;
  int _reconnectAttempts = 0;
  
  // Stream para notificar cambios en el estado de la conexión
  final _connectionController = StreamController<bool>.broadcast();
  Stream<bool> get onConnectionChange => _connectionController.stream;
  
  DatabaseService._internal();
  
  Future<void> initialize() async {
    if (_isInitialized && _connection != null) return;
    
    try {
      print('Intentando conectar a la base de datos...');
      
      // Configuración mejorada de conexión
      final settings = ConnectionSettings(
        host: _host,
        port: _port,
        user: _user,
        password: _password,
        db: _dbName,
        // Configuración para mejorar la estabilidad
        maxPacketSize: 16 * 1024 * 1024, // 16MB
        timeout: Duration(seconds: _timeoutInSeconds),
        // Deshabilitar compresión para evitar problemas de paquetes
        useCompression: false,
      );
      
      print('Configuración de conexión:');
      print('- Host: $_host');
      print('- Puerto: $_port');
      print('- Usuario: $_user');
      print('- Base de datos: $_dbName');
      
      _connection = await MySqlConnection.connect(settings);
      
      // Verificar conexión con una consulta simple
      await _connection!.query('SELECT 1');
      
      _isInitialized = true;
      _reconnectAttempts = 0;
      _connectionController.add(true);
      print('Conexión a la base de datos establecida exitosamente');
      
    } catch (e) {
      _isInitialized = false;
      _connection = null;
      _reconnectAttempts++;
      
      if (_reconnectAttempts <= _maxReconnectAttempts) {
        print('Error al conectar a la base de datos (intento $_reconnectAttempts/$_maxReconnectAttempts): $e');
        print('Reintentando en $_reconnectInterval segundos...');
        await Future.delayed(Duration(seconds: _reconnectInterval));
        return initialize();
      } else {
        print('Número máximo de intentos de reconexión alcanzado');
        _connectionController.add(false);
        rethrow;
      }
    }
  }
  
  Future<MySqlConnection> get connection async {
    if (!_isInitialized || _connection == null) {
      await initialize();
    }
    
    try {
      // Verificar si la conexión sigue activa con una consulta simple
      await _connection!.query('SELECT 1');
      return _connection!;
    } catch (e) {
      print('Error al verificar conexión: $e');
      // Intentar reconectar
      _isInitialized = false;
      _connection = null;
      await initialize();
      return _connection!;
    }
  }
  
  // Método para ejecutar consultas con reintentos
  Future<Results> query(String sql, [List<dynamic>? params, int maxRetries = 2]) async {
    int attempts = 0;
    
    while (attempts <= maxRetries) {
      try {
        final conn = await connection;
        return await conn.query(sql, params);
      } catch (e) {
        attempts++;
        
        if (attempts > maxRetries) {
          print('Error en la consulta SQL (intento $attempts): $e');
          print('Consulta: $sql');
          print('Parámetros: $params');
          rethrow;
        }
        
        print('Reintentando consulta (intento ${attempts}/$maxRetries)...');
        await Future.delayed(Duration(seconds: 1 * attempts));
      }
    }
    
    throw Exception('No se pudo ejecutar la consulta después de $maxRetries intentos');
  }
  
  // Cerrar la conexión cuando ya no se necesite
  Future<void> close() async {
    try {
      if (_isInitialized && _connection != null) {
        await _connection!.close();
        _isInitialized = false;
        _connection = null;
        _connectionController.add(false);
        print('Conexión a la base de datos cerrada correctamente');
      }
    } catch (e) {
      print('Error al cerrar la conexión: $e');
      rethrow;
    } finally {
      _connectionController.close();
    }
  }
  
  // Verificar si la conexión está activa
  bool get isConnected => _isInitialized && _connection != null;
  
  // Método para ejecutar transacciones
  Future<T> transaction<T>(Future<T> Function(MySqlConnection) action) async {
    final conn = await connection;
    await conn.query('START TRANSACTION');
    
    try {
      final result = await action(conn);
      await conn.query('COMMIT');
      return result;
    } catch (e) {
      await conn.query('ROLLBACK');
      rethrow;
    }
  }
}
