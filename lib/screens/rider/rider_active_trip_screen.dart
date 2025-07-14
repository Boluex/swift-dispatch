// lib/screens/rider/rider_active_trip_screen.dart
import 'package:flutter/material.dart'; // <-- THE MOST IMPORTANT MISSING IMPORT
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:myapp/main.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';

class RiderActiveTripScreen extends StatefulWidget {
  final int orderId;
  final Map<String, dynamic> orderData;
  const RiderActiveTripScreen({super.key, required this.orderId, required this.orderData});
  @override
  State<RiderActiveTripScreen> createState() => _RiderActiveTripScreenState();
}

class _RiderActiveTripScreenState extends State<RiderActiveTripScreen> {
  late String _status;
  bool _isUploading = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _status = widget.orderData['status'];
  }

  Future<void> _updateOrderStatus(String newStatus, {String? imageUrl}) async {
    final rider = supabase.auth.currentUser;
    if (rider == null) return;
    
    try {
      final updateData = <String, dynamic>{
        'status': newStatus,
        'rider_id': rider.id,
      };
      if (imageUrl != null) {
        updateData['delivery_confirmation_image_url'] = imageUrl;
      }
      
      await supabase.from('orders').update(updateData).eq('id', widget.orderId);
      
      if(mounted) {
        setState(() { _status = newStatus; });
        if(newStatus == 'delivered') {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Delivery Completed!"), backgroundColor: Colors.green));
        }
      }
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to update status: $e")));
    }
  }

  Future<void> _handleCompleteDelivery() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.camera, imageQuality: 50);
    if (image == null) return;
    
    setState(() { _isUploading = true; });

    try {
      final bytes = await image.readAsBytes();
      final filePath = 'delivery-confirmations/${widget.orderId}.jpg';
      await supabase.storage.from('rider-uploads').uploadBinary(
        filePath,
        bytes,
        fileOptions: FileOptions(contentType: image.mimeType, upsert: true),
      );
      final imageUrl = supabase.storage.from('rider-uploads').getPublicUrl(filePath);
      
      await _updateOrderStatus('delivered', imageUrl: imageUrl);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to upload proof: $e")));
    }

    if (mounted) setState(() { _isUploading = false; });
  }

  Widget _buildStatusButton() {
    if (_isUploading) return const Center(child: CircularProgressIndicator());
    
    switch (_status) {
      case 'pending': return ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.green, minimumSize: const Size(double.infinity, 50)), onPressed: () => _updateOrderStatus('accepted'), child: Text('ACCEPT ORDER (EARN ₦${(widget.orderData['total_price'] * 0.9).toStringAsFixed(0)})', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)));
      case 'accepted': return ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, minimumSize: const Size(double.infinity, 50)), onPressed: () => _updateOrderStatus('pickedUp'), child: const Text('CONFIRM ITEM PICKUP', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)));
      case 'pickedUp': return ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, minimumSize: const Size(double.infinity, 50)), onPressed: _handleCompleteDelivery, child: const Text('COMPLETE DELIVERY (TAKE PHOTO)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)));
      case 'delivered': return ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.grey, minimumSize: const Size(double.infinity, 50)), onPressed: () => Navigator.of(context).pop(), child: const Text('TRIP COMPLETED - GO BACK', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)));
      default: return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Active Delivery')),
      body: Column(
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.35,
            child: FlutterMap(
              options: const MapOptions(initialCenter: LatLng(6.6018, 3.3515), initialZoom: 13.0),
              children: [TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png')],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('TRIP DETAILS', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(height: 16),
                  Card(
                    elevation: 0, color: Colors.blue.withAlpha(25),
                    child: ListTile(
                      leading: const Icon(Icons.arrow_upward_rounded, color: Colors.blue),
                      title: const Text("PICKUP", style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(widget.orderData['pickup_location']),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    elevation: 0, color: Colors.green.withAlpha(25),
                    child: ListTile(
                      leading: const Icon(Icons.arrow_downward_rounded, color: Colors.green),
                      title: const Text("DROP OFF", style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(widget.orderData['delivery_location']),
                    ),
                  ),
                  const Spacer(),
                  _buildStatusButton(),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}