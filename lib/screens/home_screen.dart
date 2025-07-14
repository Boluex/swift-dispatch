// lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:myapp/main.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:myapp/screens/create_order_screen.dart';
import 'package:myapp/screens/welcome_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final MapController _mapController = MapController();
  static const LatLng _initialPosition = LatLng(6.5244, 3.3792);
  late final Future<Map<String, dynamic>> _userData;

  @override
  void initState() {
    super.initState();
    _userData = _getUserData();
  }

  Future<Map<String, dynamic>> _getUserData() async {
    final user = supabase.auth.currentUser;
    if (user == null) return {};
    return await supabase.from('profiles').select().eq('id', user.id).single();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black, size: 30),
      ),
      drawer: Drawer(
        child: FutureBuilder<Map<String, dynamic>>(
          future: _userData,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
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
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: const MapOptions(initialCenter: _initialPosition, initialZoom: 12.0),
            children: [
              TileLayer(urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png'),
            ],
          ),
          DraggableScrollableSheet(
            initialChildSize: 0.35, minChildSize: 0.15, maxChildSize: 0.35,
            builder: (BuildContext context, ScrollController scrollController) {
              return Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
                  boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10.0)],
                ),
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Ready to dispatch?", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        const Text("Enter your pickup and delivery details to find a rider.", style: TextStyle(color: Colors.grey)),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50), backgroundColor: Colors.black, foregroundColor: Colors.white),
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const CreateOrderScreen())),
                          child: const Text('REQUEST A RIDER', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        )
                      ],
                    ),
                  ),
                ),
              );
            },
          )
        ],
      ),
    );
  }
}