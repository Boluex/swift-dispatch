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
      };
      
      Navigator.push(context, MaterialPageRoute(builder: (context) => NearbyFirmsScreen(orderDetails: orderDetails)));
    }
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
  
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 24.0, bottom: 8.0, left: 4.0),
      child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, String hint, {TextInputType keyboardType = TextInputType.text}) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        filled: true,
        fillColor: Colors.grey[200],
        floatingLabelBehavior: FloatingLabelBehavior.never,
      ),
      keyboardType: keyboardType,
      validator: (v) => (v == null || v.isEmpty) ? '$label is required' : null,
    );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create a Delivery')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader("Where to?"),
              _buildTextField(_pickupLocationController, "Pickup Location", "e.g., 123 Allen Avenue - Ikeja"),
              const SizedBox(height: 16),
              _buildTextField(_deliveryLocationController, "Delivery Location", "e.g., Unilag Main Gate - Yaba"),

              _buildSectionHeader("Who's Involved?"),
              _buildTextField(_pickupContactController, "Sender's Name & Phone", "John Doe - 080...", keyboardType: TextInputType.text),
              const SizedBox(height: 16),
              _buildTextField(_receiverDetailsController, "Receiver's Name & Phone", "Jane Smith - 090...", keyboardType: TextInputType.text),

              _buildSectionHeader("What's the Item?"),
              _buildTextField(_itemDetailsController, "Item Description", "e.g., Small box, contains shoes"),
              const SizedBox(height: 16),
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

              _buildSectionHeader("Preferences"),
              DropdownButtonFormField<String>(
                value: _vehicleType,
                decoration: InputDecoration(labelText: 'Vehicle Type', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none), filled: true, fillColor: Colors.grey[200], prefixIcon: const Icon(Icons.two_wheeler)),
                items: ['Bike', 'Car', 'Van'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
                onChanged: (v) => setState(() => _vehicleType = v!),
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(10)),
                child: SwitchListTile(
                  title: const Text('Express Delivery'),
                  subtitle: const Text('Prioritize this delivery for a higher fee.'),
                  value: _isExpress,
                  onChanged: (v) => setState(() => _isExpress = v),
                  secondary: const Icon(Icons.flash_on),
                ),
              ),

              const SizedBox(height: 32),
              ElevatedButton(
                style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50), backgroundColor: Colors.black, foregroundColor: Colors.white),
                onPressed: _findDeliveryFirm,
                child: const Text('FIND A RIDER', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}