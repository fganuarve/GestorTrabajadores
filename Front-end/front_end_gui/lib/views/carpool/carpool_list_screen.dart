import 'package:flutter/material.dart';
import 'package:front_end_gui/models/carpool_model.dart';
import 'package:front_end_gui/services/carpool_service.dart';
import 'package:front_end_gui/views/carpool/create_carpool_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CarpoolListScreen extends StatefulWidget {
  final DateTime selectedDate;

  const CarpoolListScreen({Key? key, required this.selectedDate}) : super(key: key);

  @override
  _CarpoolListScreenState createState() => _CarpoolListScreenState();
}

class _CarpoolListScreenState extends State<CarpoolListScreen> {
  late final CarpoolService _carpoolService;
  late Future<List<Carpool>> _carpoolsFuture;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _carpoolsFuture = Future.value([]);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeServices();
    });
  }

  Future<void> _initializeServices() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _carpoolService = CarpoolService(prefs: prefs);
      _loadCarpools();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al inicializar servicios: $e')),
        );
      }
    }
  }

  Future<void> _loadCarpools() async {
    if (!mounted) return;
    
    setState(() => _isLoading = true);
    
    try {
      final carpools = await _carpoolService.getAvailableCarpools(widget.selectedDate);
      if (!mounted) return;
      
      setState(() {
        _carpoolsFuture = Future.value(carpools);
      });
      
      // Log para depuración
      print('Carpools cargados: ${carpools.length}');
      for (var carpool in carpools) {
        print('Carpool: ${carpool.id} - ${carpool.origin} a ${carpool.destination}');
      }
    } catch (e, stackTrace) {
      print('Error en _loadCarpools: $e');
      print('Stack trace: $stackTrace');
      
      if (!mounted) return;
      
      setState(() {
        _carpoolsFuture = Future.error(e.toString());
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar los viajes: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _refreshCarpools() async {
    try {
      setState(() => _isLoading = true);
      await _carpoolService.getAvailableCarpools(widget.selectedDate);
      await _loadCarpools();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lista de viajes actualizada')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al actualizar los viajes: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _joinCarpool(String carpoolId) async {
    if (_isLoading) return;

    try {
      setState(() => _isLoading = true);
      final userId = 'current_user_id'; // TODO: Get from auth
      
      // Ensure the service is initialized
      if (_carpoolService == null) {
        throw Exception('El servicio de viajes compartidos no está inicializado');
      }
      
      await _carpoolService.joinCarpool(carpoolId, userId);
      
      // Refresh the carpool list after joining
      await _loadCarpools();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Te has unido al viaje exitosamente')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al unirse al viaje: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildDetailRow(IconData icon, String text, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color ?? Colors.grey[600]),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: color ?? Colors.grey[800],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCarpoolCard(Carpool carpool) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          // TODO: Navegar al detalle del viaje
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Encabezado con origen y destino
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF7E57C2).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.directions_car, color: Color(0xFF7E57C2)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${carpool.origin} → ${carpool.destination}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Color(0xFF333333),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Hoy, ${carpool.time.hour.toString().padLeft(2, '0')}:${carpool.time.minute.toString().padLeft(2, '0')}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: carpool.availableSeats > 0 
                          ? Colors.green.withOpacity(0.1) 
                          : Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${carpool.availableSeats} asiento${carpool.availableSeats != 1 ? 's' : ''}',
                      style: TextStyle(
                        color: carpool.availableSeats > 0 
                            ? Colors.green 
                            : Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Detalles del viaje
              _buildDetailRow(
                Icons.person_outline,
                'Conductor: ${carpool.driverName ?? 'No especificado'}',
                color: Colors.grey[700],
              ),
              
              if (carpool.notes?.isNotEmpty ?? false) ...[
                const SizedBox(height: 8),
                _buildDetailRow(
                  Icons.notes,
                  carpool.notes!,
                  color: Colors.grey[600],
                ),
              ],
              
              const SizedBox(height: 12),
              
              // Botón de unirse al viaje
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: carpool.availableSeats > 0 
                      ? () => _joinCarpool(carpool.id)
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7E57C2),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Unirse al viaje',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Viajes para ${'${widget.selectedDate.day}/${widget.selectedDate.month}/${widget.selectedDate.year}'}',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF7E57C2),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CreateCarpoolScreen(selectedDate: widget.selectedDate),
                ),
              );
              if (result == true) {
                _refreshCarpools();
              }
            },
            tooltip: 'Crear nuevo viaje',
          ),
          IconButton(
            icon: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _refreshCarpools,
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshCarpools,
        child: FutureBuilder<List<Carpool>>(
          future: _carpoolsFuture,
          builder: (context, snapshot) {
            if (_isLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 48),
                    const SizedBox(height: 16),
                    Text(
                      'Error al cargar los viajes',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32.0),
                      child: Text(
                        '${snapshot.error}',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey[600]),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.refresh),
                      label: const Text('Reintentar'),
                      onPressed: _refreshCarpools,
                    ),
                  ],
                ),
              );
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.car_rental, size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    Text(
                      'No hay viajes disponibles',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 48.0),
                      child: Text(
                        'Sé el primero en crear un viaje para esta fecha',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text('Crear viaje'),
                      onPressed: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CreateCarpoolScreen(selectedDate: widget.selectedDate),
                          ),
                        );
                        if (result == true) {
                          _refreshCarpools();
                        }
                      },
                    ),
                  ],
                ),
              );
            }

            final carpools = snapshot.data!;
            return ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: carpools.length,
              itemBuilder: (context, index) {
                return _buildCarpoolCard(carpools[index]);
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CreateCarpoolScreen(selectedDate: widget.selectedDate),
            ),
          );
          if (result == true) {
            _refreshCarpools();
          }
        },
        backgroundColor: const Color(0xFF7E57C2),
        child: const Icon(Icons.add, color: Colors.white),
        tooltip: 'Crear nuevo viaje',
      ),
    );
  }
}
