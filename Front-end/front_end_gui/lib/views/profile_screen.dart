import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:front_end_gui/models/user_model.dart';
import 'package:front_end_gui/providers/carpool_provider.dart';
import 'package:front_end_gui/providers/user_provider.dart';
import 'package:front_end_gui/views/carpool/carpool_list_screen.dart';
import 'package:front_end_gui/views/carpool/create_carpool_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late CarpoolProvider _carpoolProvider;
  UserModel? _user;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _carpoolProvider = Provider.of<CarpoolProvider>(context, listen: false);
      _loadUserData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final userData = userProvider.user;
    
    if (userData != null) {
      setState(() {
        _user = UserModel.fromJson(Map<String, dynamic>.from(userData));
      });
      await _carpoolProvider.loadMyCarpools(_user!.id, context);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_user == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Perfil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CarpoolListScreen(
                    selectedDate: DateTime.now(),
                  ),
                ),
              );
            },
            tooltip: 'Ver todos los viajes',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.person), text: 'Perfil'),
            Tab(icon: Icon(Icons.car_rental), text: 'Mis Viajes'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildProfileTab(),
          _buildMyTripsTab(),
        ],
      ),
    );
  }

  Widget _buildProfileTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: Theme.of(context).primaryColor,
                      child: Text(
                        _user!.fullName.substring(0, 1).toUpperCase(),
                        style: const TextStyle(fontSize: 40, color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Text(
                      _user!.fullName,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                  const Divider(height: 32),
                  _buildProfileInfoItem('Email', _user!.email, Icons.email),
                  _buildProfileInfoItem('Centro de trabajo', _user!.workplace, Icons.work),
                  _buildProfileInfoItem('Rol', _user!.role, Icons.medical_services),
                  _buildProfileInfoItem('Ubicación', _user!.location, Icons.location_on),
                  if (_user!.phoneNumber != null)
                    _buildProfileInfoItem('Teléfono', _user!.phoneNumber!, Icons.phone),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Publicar un viaje compartido',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CreateCarpoolScreen(),
                        ),
                      );
                      
                      if (result == true && _user != null) {
                        await _carpoolProvider.loadMyCarpools(_user!.id, context);
                      }
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Nuevo Viaje Compartido'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyTripsTab() {
    return Consumer<CarpoolProvider>(
      builder: (context, carpoolProvider, _) {
        if (carpoolProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final myTrips = carpoolProvider.myCarpools;

        if (myTrips.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.car_rental, size: 60, color: Colors.grey),
                const SizedBox(height: 16),
                const Text(
                  'No tienes viajes programados',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: () {
                    _tabController.animateTo(0); // Cambiar a la pestaña de perfil
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Publicar un viaje'),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => _carpoolProvider.loadMyCarpools(_user!.id, context),
          child: ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: myTrips.length,
            itemBuilder: (context, index) {
              final trip = myTrips[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                child: ListTile(
                  leading: const Icon(Icons.car_rental, size: 40),
                  title: Text('${trip.origin} → ${trip.destination}'),
                  subtitle: Text(
                    '${trip.date.day}/${trip.date.month}/${trip.date.year} - ${trip.time.format(context)}',
                  ),
                  trailing: Text('${trip.availableSeats} plazas'),
                  onTap: () {
                    // Navegar a los detalles del viaje
                  },
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildProfileInfoItem(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
