// lib/screens/rider/rider_active_trip_screen.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:myapp/main.dart'; // For supabase instance
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
      
      setState(() { _status = newStatus; });
      if(newStatus == 'delivered' && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Delivery Completed!"), backgroundColor: Colors.green,));
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
      case 'pending': return ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.green), onPressed: () => _updateOrderStatus('accepted'), child: Text('ACCEPT ORDER (₦${widget.orderData['total_price']})'));
      case 'accepted': return ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.blue), onPressed: () => _updateOrderStatus('pickedUp'), child: const Text('CONFIRM ITEM PICKUP'));
      case 'pickedUp': return ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.orange), onPressed: _handleCompleteDelivery, child: const Text('COMPLETE DELIVERY (TAKE PHOTO)'));
      case 'delivered': return ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.grey), onPressed: () => Navigator.of(context).pop(), child: const Text('TRIP COMPLETED - GO BACK'));
      default: return const Text('Status Unknown');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Delivery Details')),
      body: Column(
        children: [
          Expanded(flex: 2, child: FlutterMap(options: const MapOptions(initialCenter: LatLng(6.6018, 3.3515), initialZoom: 13.0), children: [TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png')])),
          Expanded(flex: 3, child: Padding(padding: const EdgeInsets.all(16.0), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text('TRIP DETAILS', style: Theme.of(context).textTheme.titleMedium),
            const Divider(),
            Card(child: ListTile(title: Text('From: ${widget.orderData['pickup_location']}'), subtitle: Text('Contact: ${widget.orderData['pickup_contact']}'))),
            Card(child: ListTile(title: Text('To: ${widget.orderData['delivery_location']}'), subtitle: Text('Contact: ${widget.orderData['receiver_contact']}'))),
            const Spacer(),
            _buildStatusButton(),
            const SizedBox(height: 16),
          ]))),
        ],
      ),
    );
  }
}