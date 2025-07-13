// lib/screens/rider/rider_registration_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:myapp/main.dart'; // Import for supabase instance
import 'package:myapp/screens/rider/pending_approval_screen.dart';

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

  Future<String> _uploadImageToStorage(XFile image, String filePath) async {
    try {
      final bytes = await image.readAsBytes();
      await supabase.storage.from('rider-uploads').uploadBinary(
        filePath,
        bytes,
        fileOptions: FileOptions(contentType: image.mimeType),
      );
      // Get the public URL of the uploaded file
      final String publicUrl = supabase.storage.from('rider-uploads').getPublicUrl(filePath);
      return publicUrl;
    } catch (e) {
      debugPrint("Error uploading image: $e");
      throw Exception('Failed to upload image.');
    }
  }

  Future<void> _registerRider() async {
    if (!_formKey.currentState!.validate()) return;
    if (_profileImage == null || _idImage == null || _vehicleLicenseImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please upload all required images.'), backgroundColor: Colors.red));
      return;
    }

    setState(() { _isLoading = true; });

    try {
      // Step 1: Create user in Supabase Auth
      final AuthResponse res = await supabase.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        data: {'full_name': _fullNameController.text.trim(), 'role': 'rider'},
      );

      final user = res.user;
      if (user == null) throw const AuthException("Registration failed, no user created.");
      
      final uid = user.id;

      // Step 2: Upload images to Supabase Storage
      final profilePicUrl = await _uploadImageToStorage(_profileImage!, '$uid/profile.jpg');
      final idCardUrl = await _uploadImageToStorage(_idImage!, '$uid/id_card.jpg');
      final vehicleLicenseUrl = await _uploadImageToStorage(_vehicleLicenseImage!, '$uid/vehicle_license.jpg');

      // Step 3: Create the rider's profile in the 'profiles' table
      await supabase.from('profiles').insert({
        'id': uid, 'email': _emailController.text.trim(), 'full_name': _fullNameController.text.trim(), 'phone_number': _phoneController.text.trim(),
        'role': 'rider', 'approval_status': 'pending', 'vehicle_type': _vehicleType, 'bank_name': _bankNameController.text.trim(),
        'account_number': _accountNumberController.text.trim(), 'profile_picture_url': profilePicUrl, 'id_card_url': idCardUrl, 'vehicle_license_url': vehicleLicenseUrl,
        'is_affiliated_with_firm': _isAffiliatedWithFirm,
        if (_isAffiliatedWithFirm) 'firm_name': _firmNameController.text.trim(),
        if (_isAffiliatedWithFirm) 'firm_location': _firmLocationController.text.trim(),
      });

      if (mounted) Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (context) => const PendingApprovalScreen()), (route) => false);

    } on AuthException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message), backgroundColor: Colors.red));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("An error occurred: ${e.toString()}"), backgroundColor: Colors.red));
    }

    if (mounted) setState(() { _isLoading = false; });
  }

  @override
  void dispose() {
    // ... dispose all controllers
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source, Function(XFile) onImageSelected) async {
    final XFile? pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) setState(() => onImageSelected(pickedFile));
  }
  
  // ... The rest of the file (_buildImagePicker, _buildTextFormField, and build method) is identical to the Firebase version.
  // I am including the full code below for completeness.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Become a Rider')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(key: _formKey, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Text("Login Credentials", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextFormField(controller: _emailController, decoration: const InputDecoration(labelText: 'Email*', border: OutlineInputBorder()), keyboardType: TextInputType.emailAddress, validator: (v) => v!.isEmpty ? 'Field required' : null),
          const SizedBox(height: 16),
          TextFormField(controller: _passwordController, decoration: const InputDecoration(labelText: 'Password*', border: OutlineInputBorder()), obscureText: true, validator: (v) => (v == null || v.length < 6) ? 'Password must be at least 6 characters' : null),
          const SizedBox(height: 24),
          const Text("Personal & Vehicle Details", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _buildImagePicker(label: 'Profile Picture*', imageFile: _profileImage, onImageSelected: (file) => _profileImage = file),
          const SizedBox(height: 16),
          TextFormField(controller: _fullNameController, decoration: const InputDecoration(labelText: 'Full Name*', border: OutlineInputBorder()), validator: (v) => v!.isEmpty ? 'Field required' : null),
          const SizedBox(height: 16),
          TextFormField(controller: _phoneController, decoration: const InputDecoration(labelText: 'Phone Number*', border: OutlineInputBorder()), keyboardType: TextInputType.phone, validator: (v) => v!.isEmpty ? 'Field required' : null),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(value: _vehicleType, decoration: const InputDecoration(labelText: 'Primary Vehicle Type*', border: OutlineInputBorder()), items: ['Bike', 'Car', 'Van'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(), onChanged: (v) => setState(() => _vehicleType = v!)),
          const SizedBox(height: 16),
          _buildImagePicker(label: 'Vehicle License*', imageFile: _vehicleLicenseImage, onImageSelected: (file) => _vehicleLicenseImage = file),
          const SizedBox(height: 24),
          const Text("Verification & Payment", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _buildImagePicker(label: 'NIN, Passport, or Driver\'s License*', imageFile: _idImage, onImageSelected: (file) => _idImage = file),
          const SizedBox(height: 16),
          TextFormField(controller: _bankNameController, decoration: const InputDecoration(labelText: 'Bank Name*', border: OutlineInputBorder()), validator: (v) => v!.isEmpty ? 'Field required' : null),
          const SizedBox(height: 16),
          TextFormField(controller: _accountNumberController, decoration: const InputDecoration(labelText: 'Account Number*', border: OutlineInputBorder()), keyboardType: TextInputType.number, validator: (v) => v!.isEmpty ? 'Field required' : null),
          const SizedBox(height: 24),
          const Text("Logistics Firm Affiliation", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          SwitchListTile(title: const Text('Are you affiliated with a logistics firm?'), value: _isAffiliatedWithFirm, onChanged: (value) => setState(() => _isAffiliatedWithFirm = value)),
          if (_isAffiliatedWithFirm) ...[
            const SizedBox(height: 16),
            TextFormField(controller: _firmNameController, decoration: const InputDecoration(labelText: 'Firm Name*', border: OutlineInputBorder()), validator: (v) => _isAffiliatedWithFirm && v!.isEmpty ? 'Field required' : null),
            const SizedBox(height: 16),
            TextFormField(controller: _firmLocationController, decoration: const InputDecoration(labelText: 'Firm Location*', border: OutlineInputBorder()), validator: (v) => _isAffiliatedWithFirm && v!.isEmpty ? 'Field required' : null),
          ],
          const SizedBox(height: 32),
          _isLoading ? const Center(child: CircularProgressIndicator()) : ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white), onPressed: _registerRider, child: const Text('Submit for Approval')),
        ])),
      ),
    );
  }
  
  Widget _buildImagePicker({ required String label, required XFile? imageFile, required Function(XFile) onImageSelected }) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontWeight: FontWeight.bold)), const SizedBox(height: 8),
      InkWell(onTap: () => _pickImage(ImageSource.gallery, onImageSelected), child: Container(
        height: 150, width: double.infinity,
        decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(8)),
        child: imageFile != null
            ? ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.file(File(imageFile.path), fit: BoxFit.cover))
            : const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.add_a_photo), Text('Tap to select image')])),
      )),
    ]);
  }
}