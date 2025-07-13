// lib/screens/create_order_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:myapp/screens/nearby_firms_screen.dart';

class CreateOrderScreen extends StatefulWidget {
  const CreateOrderScreen({super.key});
  @override
  State<CreateOrderScreen> createState() => _CreateOrderScreenState();
}

class _CreateOrderScreenState extends State<CreateOrderScreen> {
  final _formKey = GlobalKey<FormState>();
  String _vehicleType = 'Bike';
  bool _isExpress = false;
  final ImagePicker _picker = ImagePicker();
  final List<XFile> _selectedImages = [];

  final _pickupLocationController = TextEditingController();
  final _deliveryLocationController = TextEditingController();
  final _pickupContactController = TextEditingController();
  final _receiverDetailsController = TextEditingController();
  final _itemDetailsController = TextEditingController();

  void _findDeliveryFirm() {
    if (_formKey.currentState!.validate()) {
      final orderDetails = {
        'pickupLocation': _pickupLocationController.text.trim(),
        'deliveryLocation': _deliveryLocationController.text.trim(),
        'pickupContact': _pickupContactController.text.trim(),
        'receiverContact': _receiverDetailsController.text.trim(),
        'itemDetails': _itemDetailsController.text.trim(),
        'vehicleType': _vehicleType,
        'isExpress': _isExpress.toString(),
      };
      // TODO: Here you would also handle uploading the _selectedImages
      Navigator.push(context, MaterialPageRoute(builder: (context) => NearbyFirmsScreen(orderDetails: orderDetails)));
    }
  }

  @override
  void dispose() {
    _pickupLocationController.dispose();
    _deliveryLocationController.dispose();
    _pickupContactController.dispose();
    _receiverDetailsController.dispose();
    _itemDetailsController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    if (_selectedImages.length >= 2) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Maximum of 2 images allowed.')));
      return;
    }
    final XFile? pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) setState(() { _selectedImages.add(pickedFile); });
  }

  void _showPicker(BuildContext context) {
    showModalBottomSheet(context: context, builder: (ctx) => SafeArea(child: Wrap(
      children: <Widget>[
        ListTile(leading: const Icon(Icons.photo_library), title: const Text('Gallery'), onTap: () { _pickImage(ImageSource.gallery); Navigator.of(ctx).pop(); }),
        ListTile(leading: const Icon(Icons.photo_camera), title: const Text('Camera'), onTap: () { _pickImage(ImageSource.camera); Navigator.of(ctx).pop(); }),
      ],
    )));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Delivery Request')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- SIMPLIFIED TEXT FIELDS ---
              TextFormField(
                controller: _pickupLocationController,
                decoration: const InputDecoration(labelText: 'Pickup Location', hintText: 'e.g., 24 Allen Avenue - Ikeja', border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? 'Please enter a pickup location' : null
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _deliveryLocationController,
                decoration: const InputDecoration(labelText: 'Delivery Location', hintText: 'e.g., 123 Yaba Road - Sabo', border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? 'Please enter a delivery location' : null
              ),
              // --- END OF SIMPLIFIED FIELDS ---

              const SizedBox(height: 24),
              const Text("Delivery Details", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const Divider(),
              const SizedBox(height: 16),
              TextFormField(controller: _pickupContactController, decoration: const InputDecoration(labelText: 'Pickup Contact (Name & Phone)', border: OutlineInputBorder()), validator: (v) => v!.isEmpty ? 'Field required' : null),
              const SizedBox(height: 16),
              TextFormField(controller: _receiverDetailsController, decoration: const InputDecoration(labelText: 'Receiver Contact (Name & Phone)', border: OutlineInputBorder()), validator: (v) => v!.isEmpty ? 'Field required' : null),
              const SizedBox(height: 16),
              TextFormField(controller: _itemDetailsController, decoration: const InputDecoration(labelText: 'Item Details (e.g., Small Box, 2kg)', border: OutlineInputBorder()), validator: (v) => v!.isEmpty ? 'Field required' : null),
              
              const SizedBox(height: 16),
              // --- ADDED BACK THE MISSING UI WIDGETS ---
              const Text("Item Photos (Optional, Max 2)", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 8),
              _selectedImages.isEmpty
                  ? OutlinedButton.icon(onPressed: () => _showPicker(context), icon: const Icon(Icons.add_a_photo), label: const Text("Add Photos"))
                  : SizedBox(height: 100, child: ListView.builder(scrollDirection: Axis.horizontal, itemCount: _selectedImages.length + 1, itemBuilder: (context, index) {
                      if (index == _selectedImages.length) {
                        return _selectedImages.length < 2
                            ? Padding(padding: const EdgeInsets.symmetric(horizontal: 8.0), child: IconButton.filled(icon: const Icon(Icons.add), onPressed: () => _showPicker(context)))
                            : const SizedBox.shrink();
                      }
                      return Stack(children: [
                        Container(margin: const EdgeInsets.only(right: 8), width: 100, height: 100, child: ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.file(File(_selectedImages[index].path), fit: BoxFit.cover))),
                        Positioned(top: -10, right: -10, child: IconButton(icon: const Icon(Icons.cancel, color: Colors.red), onPressed: () => setState(() => _selectedImages.removeAt(index)))),
                      ]);
                    })),
              
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _vehicleType,
                decoration: InputDecoration(labelText: 'Vehicle Type', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), prefixIcon: const Icon(Icons.two_wheeler)),
                items: ['Bike', 'Car', 'Van'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
                onChanged: (v) => setState(() => _vehicleType = v!),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Express Delivery'),
                subtitle: const Text('Prioritize this delivery for a higher fee.'),
                value: _isExpress,
                onChanged: (v) => setState(() => _isExpress = v),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: Colors.grey.shade300)),
                secondary: const Icon(Icons.flash_on),
              ),
              // --- END OF ADDED WIDGETS ---

              const SizedBox(height: 32),
              ElevatedButton(onPressed: _findDeliveryFirm, child: const Text('Find Delivery Firm', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
            ],
          ),
        ),
      ),
    );
  }
}