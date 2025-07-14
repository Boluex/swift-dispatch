// lib/screens/rider/rider_dashboard_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:myapp/main.dart';
import 'package:myapp/screens/rider/rider_active_trip_screen.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class RiderDashboardScreen extends StatefulWidget {
  const RiderDashboardScreen({super.key});
  @override
  State<RiderDashboardScreen> createState() => _RiderDashboardScreenState();
}

class _RiderDashboardScreenState extends State<RiderDashboardScreen> {
  bool _isOnline = false;
  bool _isLoadingStatus = true;
  late final Future<Map<String, dynamic>> _userData;
  
  Timer? _locationUpdateTimer;
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _userData = _getUserData();
    _checkInitialOnlineStatus();
  }
  
  // All logic functions (_checkInitialOnlineStatus, _toggleOnlineStatus, etc.)
  // are correct and remain the same as the last version.
  // For brevity, I am not re-pasting them here.
  // The only change is in the build method's UI.
  
  Future<void> _checkInitialOnlineStatus() async { /* ... */ }
  Future<void> _toggleOnlineStatus(bool value) async { /* ... */ }
  Future<Map<String, dynamic>> _getUserData() async {
    final user = supabase.auth.currentUser;
    if (user == null) return {};
    return await supabase.from('profiles').select().eq('id', user.id).single();
  }

  @override
  void dispose() {
    _locationUpdateTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.black, size: 30),
        actions: [
          // The online/offline toggle is now a button in the AppBar
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: _isLoadingStatus 
              ? const Center(child: CircularProgressIndicator(color: Colors.black))
              : IconButton(
                  icon: Icon(_isOnline ? Icons.toggle_on : Icons.toggle_off, color: _isOnline ? Colors.green : Colors.grey, size: 40),
                  onPressed: () => _toggleOnlineStatus(!_isOnline),
                  tooltip: _isOnline ? 'Go Offline' : 'Go Online',
                ),
          )
        ],
      ),
      drawer: Drawer(
        child: FutureBuilder<Map<String, dynamic>>(
          future: _userData,
          builder: (context, snapshot) {
            // ... Drawer UI is the same and already good
            return const Center(child: CircularProgressIndicator());
          },
        )
      ),
      body: Stack(
        children: [
          // Map takes up the full screen
          FlutterMap(
            mapController: _mapController,
            options: const MapOptions(initialCenter: LatLng(6.5244, 3.3792), initialZoom: 12.0),
            children: [TileLayer(urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png')],
          ),

          // Draggable sheet for orders
          DraggableScrollableSheet(
            initialChildSize: 0.4,
            minChildSize: 0.15,
            maxChildSize: 0.8,
            builder: (context, scrollController) {
              return Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  boxShadow: [BoxShadow(blurRadius: 10, color: Colors.black26)]
                ),
                child: _isOnline
                  ? _buildOrderList(scrollController)
                  : _buildOfflineView(scrollController),
              );
            },
          )
        ],
      ),
    );
  }

  Widget _buildOfflineView(ScrollController scrollController) {
    return SingleChildScrollView(
      controller: scrollController,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Icon(Icons.wifi_off_rounded, size: 60, color: Colors.grey),
            const SizedBox(height: 16),
            const Text("You Are Offline", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text("Go online using the toggle at the top right to start receiving new delivery requests.", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderList(ScrollController scrollController) {
    return Column(
      children: [
        // Handle to indicate draggable
        Container(
          width: 40, height: 5, margin: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)),
        ),
        const Text("New Requests", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Expanded(
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: supabase.from('orders').stream(primaryKey: ['id']).eq('status', 'pending'),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
              if (!snapshot.hasData || snapshot.data!.isEmpty) return const Center(child: Text('Waiting for new requests...'));

              final orders = snapshot.data!;
              return ListView.builder(
                controller: scrollController,
                padding: const EdgeInsets.all(8.0),
                itemCount: orders.length,
                itemBuilder: (context, index) {
                  final orderData = orders[index];
                  // Using a more detailed card inspired by Glovo
                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
                    child: InkWell(
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => RiderActiveTripScreen(orderId: orderData['id'], orderData: orderData))),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              const Icon(Icons.arrow_upward_rounded, color: Colors.blue), const SizedBox(width: 8),
                              Expanded(child: Text("Pick up: ${orderData['pickup_location']}", overflow: TextOverflow.ellipsis)),
                            ]),
                            const SizedBox(height: 12),
                            Row(children: [
                              const Icon(Icons.arrow_downward_rounded, color: Colors.green), const SizedBox(width: 8),
                              Expanded(child: Text("Drop off: ${orderData['delivery_location']}", overflow: TextOverflow.ellipsis)),
                            ]),
                            const Divider(height: 24),
                            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                              const Text("Earning", style: TextStyle(color: Colors.grey)),
                              Text('₦${(orderData['total_price'] * 0.9).toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), // Assuming 10% commission
                            ]),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}