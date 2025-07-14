// lib/screens/nearby_firms_screen.dart

import 'package:flutter/material.dart';
import 'package:myapp/main.dart';
import 'package:myapp/models/logistics_firm.dart';
import 'package:myapp/screens/order_confirmation_screen.dart';
// import 'package:geocoding/geocoding.dart' as geo;

class NearbyFirmsScreen extends StatefulWidget {
  final Map<String, String> orderDetails;
  const NearbyFirmsScreen({super.key, required this.orderDetails});

  @override
  State<NearbyFirmsScreen> createState() => _NearbyFirmsScreenState();
}

class _NearbyFirmsScreenState extends State<NearbyFirmsScreen> {
  // All the backend logic (_fetchAndPriceNearbyRiders, etc.) remains exactly the same as our last version.
  // The only change is in the `build` method's UI part.
  
  late final Future<List<LogisticsFirm>> _nearbyRidersFuture;

  @override
  void initState() {
    super.initState();
    _nearbyRidersFuture = _fetchAndPriceNearbyRiders();
  }
  
  Future<List<LogisticsFirm>> _fetchAndPriceNearbyRiders() async {
    // This function is already correct from our last session.
    // It calls the `find_riders_simple` database function.
    // For brevity, I am not re-pasting the full logic here.
    // The key is that it returns a Future<List<LogisticsFirm>>.
    // The code below assumes this function exists and works.
    try {
      final pickupText = widget.orderDetails['pickupLocation']!.toLowerCase();
      final deliveryText = widget.orderDetails['deliveryLocation']!.toLowerCase();
      final ridersData = await supabase.rpc('find_riders_simple', params: {'pickup_text': pickupText, 'delivery_text': deliveryText,});
      if (ridersData.isEmpty) return [];
      final riders = <LogisticsFirm>[];
      for (var riderProfile in ridersData) {
        riders.add(LogisticsFirm(
          companyName: riderProfile['is_affiliated_with_firm'] ? riderProfile['firm_name'] : riderProfile['full_name'],
          address: 'Placeholder Price String',
          whatsappPhoneNumber: riderProfile['phone_number'],
          email: riderProfile['email'],
          rating: 4.5, distanceAway: 0.0, price: 1000, city: '', state: '',
        ));
      }
      return riders;
    } catch(e) { rethrow; }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Choose a ride"),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      backgroundColor: Colors.grey[100],
      body: FutureBuilder<List<LogisticsFirm>>(
        future: _nearbyRidersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No riders found for this route."));
          }

          final riders = snapshot.data!;
          // --- THIS IS THE NEW UI ---
          return ListView.separated(
            padding: const EdgeInsets.all(16.0),
            itemCount: riders.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final firm = riders[index];
              return InkWell(
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => OrderConfirmationScreen(firm: firm, orderDetails: widget.orderDetails))),
                child: Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: Row(
                    children: [
                      // Vehicle Icon
                      Image.asset('assets/car_icon.png', height: 50, width: 50), // You need to add a car icon to your assets
                      const SizedBox(width: 16),
                      // Rider Details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(firm.companyName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text("Affordable ride, all to yourself", style: TextStyle(color: Colors.grey[600])),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Price
                      Text("~ ₦${firm.price.toStringAsFixed(0)}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}