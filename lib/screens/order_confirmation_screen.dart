// lib/screens/order_confirmation_screen.dart
import 'package:flutter/material.dart';
import 'package:myapp/main.dart';
import 'package:myapp/models/logistics_firm.dart';
import 'package:myapp/screens/dummy_payment_screen.dart';
import 'package:myapp/screens/order_tracking_screen.dart';

class OrderConfirmationScreen extends StatefulWidget {
  final LogisticsFirm firm;
  final Map<String, String> orderDetails;

  const OrderConfirmationScreen({super.key, required this.firm, required this.orderDetails});

  @override
  State<OrderConfirmationScreen> createState() => _OrderConfirmationScreenState();
}

class _OrderConfirmationScreenState extends State<OrderConfirmationScreen> {
  bool _isPlacingOrder = false;

  Future<void> _placeOrderAfterPayment() async {
    final currentUser = supabase.auth.currentUser;
    if (currentUser == null) return;

    setState(() { _isPlacingOrder = true; });

    try {
      final List<Map<String, dynamic>> newOrder = await supabase.from('orders').insert({
        'customer_id': currentUser.id,
        'pickup_location': widget.orderDetails['pickupLocation'],
        'delivery_location': widget.orderDetails['deliveryLocation'],
        'pickup_contact': widget.orderDetails['pickupContact'],
        'receiver_contact': widget.orderDetails['receiverContact'],
        'item_details': widget.orderDetails['itemDetails'],
        'status': 'pending',
        'total_price': widget.firm.price, // Use the price from the selected firm
      }).select('id');

      if (mounted && newOrder.isNotEmpty) {
        final orderId = newOrder.first['id'];
        Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (context) => OrderTrackingScreen(orderId: orderId)), (route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to create order: $e'), backgroundColor: Colors.red));
      if (mounted) setState(() { _isPlacingOrder = false; });
    }
  }

  void _navigateToPayment() {
    Navigator.of(context).push(MaterialPageRoute(builder: (context) => DummyPaymentScreen(
      amount: widget.firm.price, // Use the calculated price
      onPaymentSuccess: () {
        Navigator.of(context).pop();
        _placeOrderAfterPayment();
      },
    )));
  }
  
  Widget _buildInfoCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.grey.withAlpha(25), spreadRadius: 1, blurRadius: 5)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
          const Divider(height: 20),
          child,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Review Your Order')),
      backgroundColor: Colors.grey[100],
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoCard(
                      title: "SELECTED RIDER / FIRM",
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(backgroundColor: Colors.grey[200], child: const Icon(Icons.directions_bike, color: Colors.black)),
                        title: Text(widget.firm.companyName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        subtitle: Text(widget.firm.address, style: TextStyle(color: Colors.grey[600])),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildInfoCard(
                      title: "PRICE SUMMARY",
                      child: Column(
                        children: [
                          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Delivery Fee'), Text('₦${widget.firm.price.toStringAsFixed(0)}')]),
                          const SizedBox(height: 8),
                          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Service Fee'), Text('Included')]), // Simplified
                          const Divider(height: 24),
                          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                            const Text('Total', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                            Text('₦${widget.firm.price.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.green)),
                          ]),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: _isPlacingOrder
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 50)),
                      onPressed: _navigateToPayment,
                      child: const Text('PROCEED TO PAYMENT', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}