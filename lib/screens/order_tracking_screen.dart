// lib/screens/order_tracking_screen.dart
import 'package:flutter/material.dart';
import 'package:myapp/main.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class OrderTrackingScreen extends StatelessWidget {
  final int orderId;
  const OrderTrackingScreen({super.key, required this.orderId});

  Widget _buildStatusIcon(String currentStatus, String stepStatus) {
    List<String> statusOrder = ['pending', 'accepted', 'pickedUp', 'delivered', 'completed'];
    int currentIndex = statusOrder.indexOf(currentStatus);
    int stepIndex = statusOrder.indexOf(stepStatus);

    if (currentIndex == stepIndex) {
      return const CircleAvatar(backgroundColor: Colors.orange, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2));
    } else if (currentIndex > stepIndex) {
      return const CircleAvatar(backgroundColor: Colors.green, child: Icon(Icons.check, color: Colors.white));
    } else {
      return CircleAvatar(backgroundColor: Colors.grey.shade400, child: const Icon(Icons.more_horiz, color: Colors.white));
    }
  }

  Stream<Map<String, dynamic>?> _getOrderStream() {
    // This stream listens for changes on a single order document.
    return supabase.from('orders').stream(primaryKey: ['id']).eq('id', orderId).map((listOfMaps) {
      return listOfMaps.isNotEmpty ? listOfMaps.first : null;
    });
  }
  
  // This function will fetch the live location of the assigned rider
  Stream<LatLng?> _getRiderLocationStream(String? riderId) {
    if (riderId == null) return Stream.value(null);
    return supabase.from('profiles').stream(primaryKey: ['id']).eq('id', riderId).map((listOfProfiles) {
      if (listOfProfiles.isNotEmpty) {
        final pointData = listOfProfiles.first['location'];
        if (pointData != null) {
          // PostGIS POINT format is 'POINT(longitude latitude)'
          // We need to parse this string to get the coordinates.
          final parts = pointData.replaceAll('POINT(', '').replaceAll(')', '').split(' ');
          final lon = double.parse(parts[0]);
          final lat = double.parse(parts[1]);
          return LatLng(lat, lon);
        }
      }
      return null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tracking Your Delivery')),
      body: StreamBuilder<Map<String, dynamic>?>(
        stream: _getOrderStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || snapshot.data == null) return const Center(child: Text('Order not found or has been completed.'));

          final orderData = snapshot.data!;
          final status = orderData['status'] ?? 'pending';
          final riderId = orderData['rider_id'];
          
          return Stack(
            children: [
              // --- LIVE MAP WITH RIDER LOCATION ---
              StreamBuilder<LatLng?>(
                stream: _getRiderLocationStream(riderId),
                builder: (context, riderLocSnapshot) {
                  LatLng riderPosition = riderLocSnapshot.data ?? const LatLng(6.5244, 3.3792); // Default to Lagos

                  return FlutterMap(
                    options: MapOptions(initialCenter: riderPosition, initialZoom: 14.0),
                    children: [ 
                      TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png'),
                      if (riderLocSnapshot.hasData && riderLocSnapshot.data != null)
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: riderPosition,
                              width: 80, height: 80,
                              child: const Icon(Icons.delivery_dining_rounded, color: Colors.blue, size: 50),
                            )
                          ]
                        ),
                    ],
                  );
                }
              ),
              Positioned(
                left: 0, right: 0, bottom: 0,
                child: Card(
                  margin: EdgeInsets.zero,
                  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('STATUS: ${status.toString().toUpperCase()}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        const SizedBox(height: 16),
                        ListTile(leading: _buildStatusIcon(status, 'pending'), title: const Text('Order Placed')),
                        ListTile(leading: _buildStatusIcon(status, 'accepted'), title: const Text('Order Accepted')),
                        ListTile(leading: _buildStatusIcon(status, 'pickedUp'), title: const Text('Item Picked Up')),
                        ListTile(leading: _buildStatusIcon(status, 'delivered'), title: const Text('Delivered')),
                        const SizedBox(height: 16),
                        // --- TRACK MY GOODS BUTTON ---
                        if (status == 'pickedUp')
                          ElevatedButton.icon(
                            onPressed: () { /* The map is already tracking, this could show more details */ },
                            icon: const Icon(Icons.track_changes),
                            label: const Text('TRACK MY GOODS'),
                          )
                        else if (status == 'delivered')
                          // --- COMPLAIN / CONFIRM BUTTONS ---
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              TextButton.icon(onPressed: () {}, icon: const Icon(Icons.error_outline, color: Colors.red), label: const Text('Report Issue')),
                              ElevatedButton(onPressed: () => _updateOrderStatus(orderId, 'completed'), child: const Text('Confirm Delivery')),
                            ],
                          )
                      ],
                    ),
                  ),
                ),
              )
            ],
          );
        },
      ),
    );
  }

  // Helper function to update the final status
  Future<void> _updateOrderStatus(int orderId, String newStatus) async {
    await supabase.from('orders').update({'status': newStatus}).eq('id', orderId);
  }
}