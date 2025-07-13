// lib/screens/nearby_firms_screen.dart

import 'package:flutter/material.dart';
import 'package:myapp/main.dart';
import 'package:myapp/models/logistics_firm.dart';
import 'package:myapp/screens/order_confirmation_screen.dart';
import 'package:geocoding/geocoding.dart' as geo;
import 'package:geolocator/geolocator.dart';

class NearbyFirmsScreen extends StatefulWidget {
  final Map<String, String> orderDetails;
  const NearbyFirmsScreen({super.key, required this.orderDetails});

  @override
  State<NearbyFirmsScreen> createState() => _NearbyFirmsScreenState();
}

class _NearbyFirmsScreenState extends State<NearbyFirmsScreen> {
  late final Future<List<LogisticsFirm>> _nearbyRidersFuture;

  @override
  void initState() {
    super.initState();
    _nearbyRidersFuture = _fetchAndPriceNearbyRiders();
  }
  
  // This is the final, robust logic
  Future<List<LogisticsFirm>> _fetchAndPriceNearbyRiders() async {
    try {
      final pickupText = widget.orderDetails['pickupLocation']!.toLowerCase();
      final deliveryText = widget.orderDetails['deliveryLocation']!.toLowerCase();

      // Step 1: Find riders using only smart text matching. THIS CANNOT FAIL.
      final List<dynamic> ridersData = await supabase.rpc('find_riders_by_route', params: {
        'pickup_zone_text': pickupText,
        'delivery_zone_text': deliveryText,
      });

      // If the primary search finds no one, we can stop here.
      if (ridersData.isEmpty) return [];

      // Step 2: NOW, ATTEMPT to geocode, but DO NOT FAIL if it doesn't work.
      List<geo.Location> pickupLocations = [];
      List<geo.Location> deliveryLocations = [];
      try {
        pickupLocations = await geo.locationFromAddress(widget.orderDetails['pickupLocation']!);
        deliveryLocations = await geo.locationFromAddress(widget.orderDetails['deliveryLocation']!);
      } catch (e) {
        // This is no longer a fatal error. We just print a debug message.
        debugPrint("Could not geocode one or both addresses. Will show base fees. Error: $e");
      }

      bool canCalculateDynamicPrice = pickupLocations.isNotEmpty && deliveryLocations.isNotEmpty;
      double tripDistanceKm = 0;

      if (canCalculateDynamicPrice) {
        tripDistanceKm = Geolocator.distanceBetween(
          pickupLocations.first.latitude, pickupLocations.first.longitude,
          deliveryLocations.first.latitude, deliveryLocations.first.longitude
        ) / 1000;
      }

      // Step 3: Build the final list for the UI
      final List<LogisticsFirm> riders = [];
      for (var riderProfile in ridersData) {
        
        double price;
        String priceLabel;

        if (canCalculateDynamicPrice) {
          // If we have coordinates, calculate the full dynamic price
          final baseFee = (riderProfile['base_fee'] as num?)?.toDouble() ?? 0.0;
          final ratePerKm = (riderProfile['rate_per_km'] as num?)?.toDouble() ?? 0.0;
          price = baseFee + (ratePerKm * tripDistanceKm);
          priceLabel = '₦${price.toStringAsFixed(0)}'; // Final Price
        } else {
          // If geocoding failed, just show the rider's base fee as an estimate
          price = (riderProfile['base_fee'] as num?)?.toDouble() ?? 0.0;
          priceLabel = '~ ₦${price.toStringAsFixed(0)}'; // Estimated Price
        }

        riders.add(
          LogisticsFirm(
            // We pass the price label to our model now
            companyName: riderProfile['is_affiliated_with_firm'] ? riderProfile['firm_name'] : riderProfile['full_name'],
            address: priceLabel, // We'll re-purpose the 'address' field to hold our price label
            whatsappPhoneNumber: riderProfile['phone_number'],
            email: '',
            rating: 4.5,
            distanceAway: 0.0,
            price: price, // Store the raw price for the next screen
            city: '', state: '',
          )
        );
      }
      return riders;
    } catch (e) {
      debugPrint("Critical Error fetching riders: $e");
      // This will now only be thrown if the supabase.rpc call itself fails.
      throw Exception('A server error occurred. Please try again later.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Available Riders Nearby")),
      body: FutureBuilder<List<LogisticsFirm>>(
        future: _nearbyRidersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [CircularProgressIndicator(), SizedBox(height: 16), Text("Searching for riders...") ]));
          }
          if (snapshot.hasError) {
            return Center(child: Padding(padding: const EdgeInsets.all(16.0), child: Text("Error: ${snapshot.error}", textAlign: TextAlign.center)));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Padding(padding: const EdgeInsets.all(16.0), child: Text("No riders were found for this specific route. Please try again later.", textAlign: TextAlign.center, style: TextStyle(fontSize: 16))));
          }

          final riders = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: riders.length,
            itemBuilder: (context, index) {
              final firm = riders[index];
              return Card(
                elevation: 4.0, margin: const EdgeInsets.symmetric(vertical: 8.0),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Flexible(child: Text(firm.companyName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                        // --- UPDATED TO USE THE PRICE LABEL ---
                        Text(firm.address, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green.shade700)),
                      ]),
                      const SizedBox(height: 8),
                      // ... a
                      Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                        // ... details button
                        ElevatedButton(
                          onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => OrderConfirmationScreen(firm: firm, orderDetails: widget.orderDetails))),
                          child: const Text('Select'),
                        ),
                      ])
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