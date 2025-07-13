// lib/screens/home_screen.dart

import 'package:flutter/material.dart';
//import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:myapp/main.dart'; // Import for supabase instance
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';
import 'package:myapp/screens/create_order_screen.dart';
import 'package:myapp/screens/welcome_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final MapController _mapController = MapController();
  static const LatLng _initialPosition = LatLng(6.6018, 3.3515);
  late final Future<Map<String, dynamic>> _userData;

  @override
  void initState() {
    super.initState();
    _userData = _getUserData();
  }

  Future<Map<String, dynamic>> _getUserData() async {
    final user = supabase.auth.currentUser;
    if (user == null) return {};

    final data = await supabase
        .from('profiles')
        .select('full_name, email')
        .eq('id', user.id)
        .single();
    return data;
  }

  final List<Marker> _markers = [
    Marker(width: 80.0, height: 80.0, point: const LatLng(6.6058, 3.3495), child: const Icon(Icons.delivery_dining_rounded, color: Colors.blueAccent, size: 40)),
    Marker(width: 80.0, height: 80.0, point: const LatLng(6.5988, 3.3510), child: const Icon(Icons.delivery_dining_rounded, color: Colors.blueAccent, size: 40)),
  ];

  Future<void> _centerOnUserLocation() async {
    final location = Location();
    bool serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) return;
    }

    PermissionStatus permissionGranted = await location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) return;
    }

    final locationData = await location.getLocation();
    if (locationData.latitude != null && locationData.longitude != null) {
      _mapController.move(LatLng(locationData.latitude!, locationData.longitude!), 15.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Swift Dispatch'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
      ),
      drawer: Drawer(
        child: FutureBuilder<Map<String, dynamic>>(
          future: _userData,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
              return ListView(children: [const DrawerHeader(child: Text("Error Loading Data")), _buildLogoutTile(context)]);
            }

            final userData = snapshot.data!;
            final fullName = userData['full_name'] ?? 'User';
            final email = userData['email'] ?? 'No Email';
            
            return ListView(
              padding: EdgeInsets.zero,
              children: [
                UserAccountsDrawerHeader(
                  accountName: Text(fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  accountEmail: Text(email),
                  currentAccountPicture: CircleAvatar(
                    backgroundColor: Colors.white,
                    child: Text(fullName.isNotEmpty ? fullName[0].toUpperCase() : 'U', style: const TextStyle(fontSize: 40.0, color: Colors.amber)),
                  ),
                  decoration: const BoxDecoration(color: Colors.amber),
                ),
                ListTile(leading: const Icon(Icons.history), title: const Text('Order History'), onTap: () => Navigator.pop(context)),
                ListTile(leading: const Icon(Icons.person), title: const Text('Profile'), onTap: () => Navigator.pop(context)),
                const Divider(),
                _buildLogoutTile(context),
              ],
            );
          },
        ),
      ),
      // --- THIS IS THE CORRECTED PART ---
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: const MapOptions(initialCenter: _initialPosition, initialZoom: 14.0),
            children: [
              TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'com.example.myapp'),
              MarkerLayer(markers: _markers),
            ],
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Card(
              margin: const EdgeInsets.all(20.0),
              elevation: 8.0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('CREATE A NEW DELIVERY', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const CreateOrderScreen())),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(8.0), border: Border.all(color: Colors.grey[400]!)),
                        child: const Row(children: [Icon(Icons.search, color: Colors.grey), SizedBox(width: 8), Text('Where are you sending us?', style: TextStyle(color: Colors.black54))]),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _centerOnUserLocation,
        backgroundColor: Colors.white,
        child: const Icon(Icons.my_location, color: Colors.black54),
      ),
      // --- END OF CORRECTION ---
    );
  }

  ListTile _buildLogoutTile(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.logout),
      title: const Text('Logout'),
      onTap: () async {
        await supabase.auth.signOut();
        if (mounted) Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (context) => const WelcomeScreen()), (route) => false);
      },
    );
  }
}