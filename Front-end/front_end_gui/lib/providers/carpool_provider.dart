import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:front_end_gui/models/carpool_model.dart';
import 'package:front_end_gui/services/carpool_service.dart';
import 'package:front_end_gui/cubit/auth_cubit.dart';

class CarpoolProvider with ChangeNotifier {
  late final CarpoolService _carpoolService;
  List<Carpool> _availableCarpools = [];
  List<Carpool> _myCarpools = [];
  bool _isLoading = false;
  final SharedPreferences prefs;

  CarpoolProvider({required this.prefs}) {
    _carpoolService = CarpoolService(prefs: prefs);
  }

  List<Carpool> get availableCarpools => _availableCarpools;
  List<Carpool> get myCarpools => _myCarpools;
  bool get isLoading => _isLoading;

  // Cargar viajes disponibles para una fecha específica
  Future<void> loadAvailableCarpools(DateTime date, BuildContext context) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      final authCubit = context.read<AuthCubit>();
      final authState = authCubit.state;
      
      if (authState is! AuthAuthenticated) {
        throw Exception('Usuario no autenticado');
      }
      
      _availableCarpools = await _carpoolService.getAvailableCarpools(date);
    } catch (e) {
      debugPrint('Error al cargar viajes disponibles: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Cargar todos los viajes
  Future<void> loadCarpools(BuildContext context) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      // Cargar viajes disponibles
      await loadAvailableCarpools(DateTime.now(), context);
      
      // Cargar mis viajes si hay un usuario autenticado
      final authCubit = context.read<AuthCubit>();
      if (authCubit.state is AuthAuthenticated) {
        final authState = authCubit.state as AuthAuthenticated;
        await loadMyCarpools(authState.userData?['id'] ?? '', context);
      }
    } catch (e) {
      debugPrint('Error al cargar viajes: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Cargar los viajes del usuario
  Future<void> loadMyCarpools(String userId, BuildContext context) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      final authCubit = context.read<AuthCubit>();
      final authState = authCubit.state;
      
      if (authState is! AuthAuthenticated) {
        throw Exception('Usuario no autenticado');
      }
      
      _myCarpools = await _carpoolService.getUserCarpools(userId);
    } catch (e) {
      debugPrint('Error al cargar mis viajes: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Unirse a un viaje
  Future<void> joinCarpool(String carpoolId, BuildContext context) async {
    try {
      final authCubit = context.read<AuthCubit>();
      if (authCubit.state is! AuthAuthenticated) {
        throw Exception('Usuario no autenticado');
      }
      
      final authState = authCubit.state as AuthAuthenticated;
      final userId = authState.userData?['id'] ?? '';
      
      await _carpoolService.joinCarpool(carpoolId, userId);
      // Recargar la lista de viajes después de unirse
      await loadAvailableCarpools(DateTime.now(), context);
      await loadMyCarpools(userId, context);
    } catch (e) {
      debugPrint('Error al unirse al viaje: $e');
      rethrow;
    }
  }

  // Abandonar un viaje
  Future<void> leaveCarpool(String carpoolId, BuildContext context) async {
    try {
      final authCubit = context.read<AuthCubit>();
      if (authCubit.state is! AuthAuthenticated) {
        throw Exception('Usuario no autenticado');
      }
      
      final authState = authCubit.state as AuthAuthenticated;
      final userId = authState.userData?['id'] ?? '';
      
      await _carpoolService.leaveCarpool(carpoolId, userId);
      // Recargar la lista de viajes después de abandonar
      await loadAvailableCarpools(DateTime.now(), context);
      await loadMyCarpools(userId, context);
    } catch (e) {
      debugPrint('Error al abandonar el viaje: $e');
      rethrow;
    }
  }

  // Crear un nuevo viaje
  Future<Carpool> createCarpool({
    required BuildContext context,
    required DateTime date,
    required TimeOfDay time,
    required String origin,
    required String destination,
    required int availableSeats,
    String? notes,
  }) async {
    try {
      final authCubit = context.read<AuthCubit>();
      if (authCubit.state is! AuthAuthenticated) {
        throw Exception('Usuario no autenticado');
      }
      
      final authState = authCubit.state as AuthAuthenticated;
      final driverId = authState.userData?['id'] ?? '';
      final driverName = authState.userData?['name'] ?? 'Usuario';
      
      final carpool = await _carpoolService.createCarpool(
        driverId: driverId,
        driverName: driverName,
        date: date,
        time: time,
        origin: origin,
        destination: destination,
        availableSeats: availableSeats,
        notes: notes,
      );
      
      // Recargar la lista de viajes después de crear uno nuevo
      await loadAvailableCarpools(date, context);
      await loadMyCarpools(driverId, context);
      
      return carpool;
    } catch (e) {
      debugPrint('Error al crear el viaje: $e');
      rethrow;
    }
  }
}
