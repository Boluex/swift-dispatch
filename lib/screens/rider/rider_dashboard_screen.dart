// lib/screens/rider/rider_dashboard_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:location/location.dart';
import 'package:myapp/main.dart';
import 'package:myapp/screens/rider/rider_active_trip_screen.dart';
import 'package:myapp/screens/rider/service_areas_screen.dart';
import 'package:myapp/screens/welcome_screen.dart';

class RiderDashboardScreen extends StatefulWidget {
  const RiderDashboardScreen({super.key});
  @override
  State<RiderDashboardScreen> createState() => _RiderDashboardScreenState();
}

class _RiderDashboardScreenState extends State<RiderDashboardScreen> {
  bool _isOnline = false;
  bool _isLoadingStatus = true;
  late final Future<Map<String, dynamic>> _userData;
  
  final Location _location = Location();
  Timer? _locationUpdateTimer;
  String _statusMessage = "Checking status...";

  @override
  void initState() {
    super.initState();
    _userData = _getUserData();
    _checkInitialOnlineStatus();
  }

  Future<void> _checkInitialOnlineStatus() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        // If for some reason we land here without a user, go back to welcome
        if(mounted) Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (c) => const WelcomeScreen()), (r) => false);
        return;
      };

      final data = await supabase.from('profiles').select('is_online').eq('id', user.id).single();
      final lastKnownStatus = data['is_online'] ?? false;
      
      if (mounted) {
        setState(() {
          _isOnline = lastKnownStatus;
          _isLoadingStatus = false;
          _statusMessage = _isOnline ? "You are ONLINE. Location is being shared." : "You are OFFLINE.";
        });
        if (_isOnline) {
          _startLocationUpdates();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingStatus = false;
          _statusMessage = "Error fetching status.";
        });
      }
    }
  }
  
  void _startLocationUpdates() {
    _locationUpdateTimer?.cancel();
    _updateRiderLocation(); // Send initial location
    // --- THIS IS THE CORRECTED LINE ---
    _locationUpdateTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _updateRiderLocation();
    });
    // --- END CORRECTION ---
  }

  Future<void> _toggleOnlineStatus(bool value) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    setState(() { _isOnline = value; });
    
    try {
      await supabase.from('profiles').update({'is_online': value}).eq('id', user.id);
      
      if (_isOnline) {
        _startLocationUpdates();
        setState(() { _statusMessage = "You are ONLINE. Location is being shared."; });
      } else {
        _locationUpdateTimer?.cancel();
        await supabase.from('profiles').update({'location': null}).eq('id', user.id);
        setState(() { _statusMessage = "You are OFFLINE."; });
      }
    } catch (e) {
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error updating status: $e"), backgroundColor: Colors.red));
        setState(() { _isOnline = !value; });
      }
    }
  }

  Future<void> _updateRiderLocation() async {
    final user = supabase.auth.currentUser;
    if (user == null || !_isOnline) return;

    try {
      bool serviceEnabled = await _location.serviceEnabled();
      if (!serviceEnabled) { serviceEnabled = await _location.requestService(); if (!serviceEnabled) return; }
      PermissionStatus permissionGranted = await _location.hasPermission();
      if (permissionGranted == PermissionStatus.denied) { permissionGranted = await _location.requestPermission(); if (permissionGranted != PermissionStatus.granted) return; }
      
      final locationData = await _location.getLocation();
      if (locationData.latitude != null && locationData.longitude != null) {
        await supabase.from('profiles').update({
          'location': 'POINT(${locationData.longitude} ${locationData.latitude})'
        }).eq('id', user.id);
        debugPrint("Rider location updated.");
      }
    } catch (e) {
      debugPrint("Failed to update location: $e");
    }
  }

  Future<Map<String, dynamic>> _getUserData() async {
    final user = supabase.auth.currentUser;
    if (user == null) return {};
    final data = await supabase.from('profiles').select().eq('id', user.id).single();
    return data;
  }

  @override
  void dispose() {
    _locationUpdateTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rider Dashboard')),
      drawer: Drawer(
        child: FutureBuilder<Map<String, dynamic>>(
          future: _userData,
          builder: (context, snapshot) {
             if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
             if (!snapshot.hasData || snapshot.data!.isEmpty) return const Text("Error loading data");
             
             final userData = snapshot.data!;
             final fullName = userData['full_name'] ?? 'Rider';
             final profilePicUrl = userData['profile_picture_url'];
             
             return ListView(
               padding: EdgeInsets.zero,
               children: [
                 UserAccountsDrawerHeader(
                   accountName: Text(fullName), accountEmail: Text(userData['email'] ?? ''),
                   currentAccountPicture: CircleAvatar(
                    backgroundImage: (profilePicUrl != null) ? NetworkImage(profilePicUrl) : null,
                    child: (profilePicUrl == null) ? Text(fullName.isNotEmpty ? fullName[0].toUpperCase() : 'R') : null,
                   ),
                   decoration: const BoxDecoration(color: Colors.amber),
                 ),
                 ListTile(
                    leading: const Icon(Icons.map_outlined),
                    title: const Text('My Service Areas & Pricing'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.of(context).push(MaterialPageRoute(builder: (context) => const ServiceAreasScreen()));
                    },
                  ),
                 ListTile(leading: const Icon(Icons.history), title: const Text('Trip History'), onTap: () => Navigator.pop(context)),
                 const Divider(),
                 ListTile(
                    leading: const Icon(Icons.logout), title: const Text('Logout'),
                    onTap: () async {
                      if (_isOnline) { await _toggleOnlineStatus(false); }
                      await supabase.auth.signOut();
                      if (mounted) Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (context) => const WelcomeScreen()), (route) => false);
                    },
                  ),
               ],
             );
          }
        ),
      ),
      body: Column(
        children: [
          _isLoadingStatus 
            ? const Center(child: Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator()))
            : SwitchListTile(
                title: Text(_isOnline ? 'You are ONLINE' : 'You are OFFLINE', style: TextStyle(fontWeight: FontWeight.bold, color: _isOnline ? Colors.green : Colors.red)),
                subtitle: Text(_statusMessage),
                value: _isOnline,
                onChanged: _toggleOnlineStatus,
                secondary: Icon(_isOnline ? Icons.wifi : Icons.wifi_off),
              ),
          const Divider(),
          Expanded(
            child: _isOnline
                ? StreamBuilder<List<Map<String, dynamic>>>(
                    stream: supabase.from('orders').stream(primaryKey: ['id']).eq('status', 'pending'),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                      if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
                      if (!snapshot.hasData || snapshot.data!.isEmpty) return const Center(child: Text('No new job requests available.'));

                      final orders = snapshot.data!;
                      return ListView.builder(
                        padding: const EdgeInsets.all(8.0),
                        itemCount: orders.length,
                        itemBuilder: (context, index) {
                          final orderData = orders[index];
                          return Card(
                            child: ListTile(
                              leading: const Icon(Icons.local_shipping, color: Colors.amber),
                              title: Text('From: ${orderData['pickup_location']}'),
                              subtitle: Text('To: ${orderData['delivery_location']}'),
                              trailing: Text('₦${orderData['total_price']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => RiderActiveTripScreen(orderId: orderData['id'], orderData: orderData))),
                            ),
                          );
                        },
                      );
                    },
                  )
                : const Center(child: Text('Go online to see new requests.')),
          ),
        ],
      ),
    );
  }
}