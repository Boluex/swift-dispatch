// lib/screens/rider/service_areas_screen.dart

import 'package:flutter/material.dart';
import 'package:myapp/main.dart';

class ServiceAreasScreen extends StatefulWidget {
  const ServiceAreasScreen({super.key});

  @override
  State<ServiceAreasScreen> createState() => _ServiceAreasScreenState();
}

class _ServiceAreasScreenState extends State<ServiceAreasScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fromZoneController = TextEditingController();
  final _toZoneController = TextEditingController();
  final _baseFeeController = TextEditingController();
  final _ratePerKmController = TextEditingController();
  bool _showAdvancedPricing = false;
  bool _isSaving = false;

  Stream<List<Map<String, dynamic>>> _getServiceAreasStream() {
    final user = supabase.auth.currentUser;
    if (user == null) return Stream.value([]);
    return supabase.from('service_areas').stream(primaryKey: ['id']).eq('rider_id', user.id);
  }

  Future<void> _addServiceArea() async {
    if (!_formKey.currentState!.validate()) return;
    final user = supabase.auth.currentUser;
    if (user == null) return;

    setState(() { _isSaving = true; });

    try {
      await supabase.from('service_areas').insert({
        'rider_id': user.id,
        'from_zone': _fromZoneController.text.trim().toLowerCase(),
        'to_zone': _toZoneController.text.trim().toLowerCase(),
        'base_fee': double.parse(_baseFeeController.text.trim()),
        'rate_per_km': double.tryParse(_ratePerKmController.text.trim()) ?? 100.0,
      });

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Route added successfully!'), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to add route: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() { _isSaving = false; });
    }
  }

  void _showAddAreaDialog() {
    _fromZoneController.clear();
    _toZoneController.clear();
    _baseFeeController.clear();
    _ratePerKmController.text = "100";
    setState(() { _showAdvancedPricing = false; });

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Add New Route & Pricing'),
            content: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(controller: _fromZoneController, decoration: const InputDecoration(labelText: 'From Zone (e.g., ikeja)'), validator: (v) => v!.isEmpty ? 'Required' : null),
                    TextFormField(controller: _toZoneController, decoration: const InputDecoration(labelText: 'To Zone (e.g., surulere)'), validator: (v) => v!.isEmpty ? 'Required' : null),
                    TextFormField(controller: _baseFeeController, decoration: const InputDecoration(labelText: 'Base Fee (₦)'), keyboardType: TextInputType.number, validator: (v) => v!.isEmpty ? 'Required' : null),
                    if (_showAdvancedPricing)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: TextFormField(controller: _ratePerKmController, decoration: const InputDecoration(labelText: 'Rate per KM (₦)'), keyboardType: TextInputType.number, validator: (v) => v!.isEmpty ? 'Required' : null),
                      ),
                    TextButton(
                      onPressed: () => setDialogState(() => _showAdvancedPricing = !_showAdvancedPricing),
                      child: Text(_showAdvancedPricing ? 'Hide Advanced Pricing' : 'Set Custom Rate per KM'),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
              _isSaving ? const CircularProgressIndicator() : ElevatedButton(onPressed: _addServiceArea, child: const Text('Add Route')),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Service Routes')),
      backgroundColor: Colors.grey[100],
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _getServiceAreasStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || snapshot.data!.isEmpty) return const Center(child: Padding(padding: EdgeInsets.all(16.0), child: Text('You have not added any service routes yet. Tap the "+" button to add your first one.', textAlign: TextAlign.center)));
          
          final areas = snapshot.data!;
          return ListView.builder(
            itemCount: areas.length,
            itemBuilder: (context, index) {
              final area = areas[index];
              return Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: ListTile(
                  leading: const Icon(Icons.route_outlined, color: Colors.blueAccent),
                  title: Text("${area['from_zone'].toString().toUpperCase()}  ➔  ${area['to_zone'].toString().toUpperCase()}", style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Base: ₦${area['base_fee']} | Rate/km: ₦${area['rate_per_km']}'),
                  trailing: IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () async {
                    await supabase.from('service_areas').delete().eq('id', area['id']);
                  }),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddAreaDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}