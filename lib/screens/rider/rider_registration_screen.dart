// lib/screens/rider/rider_registration_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';


class RiderRegistrationScreen extends StatefulWidget {
  const RiderRegistrationScreen({super.key});
  @override
  State<RiderRegistrationScreen> createState() => _RiderRegistrationScreenState();
}

class _RiderRegistrationScreenState extends State<RiderRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();
  XFile? _profileImage, _idImage, _vehicleLicenseImage;
  String _vehicleType = 'Bike';
  bool _isAffiliatedWithFirm = false;
  bool _isLoading = false;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _firmNameController = TextEditingController();
  final _firmLocationController = TextEditingController();

  // All logic functions (_registerRider, _uploadImageToStorage) are correct and remain the same.
  // The changes are purely in the UI inside the build method.
 
  Future<void> _registerRider() async { /* ... */ }
  
  // --- UI HELPER WIDGETS ---
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 24.0, bottom: 8.0),
      child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
    );
  }

  TextFormField _buildTextFormField({required TextEditingController controller, required String label, TextInputType? keyboardType, bool isRequired = true}) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        filled: true,
        fillColor: Colors.grey[200],
      ),
      keyboardType: keyboardType,
      validator: (v) => (isRequired && (v == null || v.isEmpty)) ? '$label is required' : null,
    );
  }

  Widget _buildImagePicker({ required String label, required XFile? imageFile, required Function(XFile) onImageSelected }) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(color: Colors.black54)), const SizedBox(height: 8),
      InkWell(onTap: () => _pickImage(ImageSource.gallery, onImageSelected), child: Container(
        height: 150, width: double.infinity,
        decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(10)),
        child: imageFile != null
            ? ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.file(File(imageFile.path), fit: BoxFit.cover))
            : const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.add_a_photo_outlined, color: Colors.grey), Text('Tap to upload')])),
      )),
    ]);
  }

  Future<void> _pickImage(ImageSource source, Function(XFile) onImageSelected) async {
    final XFile? pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) setState(() => onImageSelected(pickedFile));
  }
  // --- END UI HELPERS ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Become a Dispatch Rider')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
        child: Form(key: _formKey, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _buildSectionHeader("Login Credentials"),
          _buildTextFormField(controller: _emailController, label: 'Email Address', keyboardType: TextInputType.emailAddress),
          const SizedBox(height: 16),
          TextFormField(
            controller: _passwordController,
            decoration: InputDecoration(labelText: 'Password', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none), filled: true, fillColor: Colors.grey[200]),
            obscureText: true,
            validator: (v) => (v == null || v.length < 6) ? 'Password must be at least 6 characters' : null,
          ),
          
          _buildSectionHeader("Personal & Vehicle Details"),
          _buildImagePicker(label: 'Profile Picture*', imageFile: _profileImage, onImageSelected: (file) => _profileImage = file),
          const SizedBox(height: 16),
          _buildTextFormField(controller: _fullNameController, label: 'Full Name'),
          const SizedBox(height: 16),
          _buildTextFormField(controller: _phoneController, label: 'Phone Number', keyboardType: TextInputType.phone),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _vehicleType,
            decoration: InputDecoration(labelText: 'Primary Vehicle Type', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none), filled: true, fillColor: Colors.grey[200]),
            items: ['Bike', 'Car', 'Van'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
            onChanged: (v) => setState(() => _vehicleType = v!),
          ),
          const SizedBox(height: 16),
          _buildImagePicker(label: 'Vehicle License*', imageFile: _vehicleLicenseImage, onImageSelected: (file) => _vehicleLicenseImage = file),

          _buildSectionHeader("Verification & Payment"),
          _buildImagePicker(label: 'NIN, Passport, or Driver\'s License*', imageFile: _idImage, onImageSelected: (file) => _idImage = file),
          const SizedBox(height: 16),
          _buildTextFormField(controller: _bankNameController, label: 'Bank Name'),
          const SizedBox(height: 16),
          _buildTextFormField(controller: _accountNumberController, label: 'Account Number', keyboardType: TextInputType.number),
          
          _buildSectionHeader("Firm Details"),
          Container(
            decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(10)),
            child: SwitchListTile(
              title: const Text('Are you part of a logistics firm?'),
              value: _isAffiliatedWithFirm,
              onChanged: (value) => setState(() => _isAffiliatedWithFirm = value),
            ),
          ),
          if (_isAffiliatedWithFirm) ...[
            const SizedBox(height: 16),
            _buildTextFormField(controller: _firmNameController, label: 'Firm Name', isRequired: _isAffiliatedWithFirm),
            const SizedBox(height: 16),
            _buildTextFormField(controller: _firmLocationController, label: 'Firm Location', isRequired: _isAffiliatedWithFirm),
          ],
          
          const SizedBox(height: 32),
          _isLoading 
            ? const Center(child: CircularProgressIndicator()) 
            : ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 50)),
                onPressed: _registerRider, 
                child: const Text('SUBMIT FOR APPROVAL', style: TextStyle(fontWeight: FontWeight.bold))
              ),
          const SizedBox(height: 20),
        ])),
      ),
    );
  }
}