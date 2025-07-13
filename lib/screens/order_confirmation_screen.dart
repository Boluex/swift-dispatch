// lib/screens/order_confirmation_screen.dart
import 'package:flutter/material.dart';
import 'package:myapp/main.dart';
import 'package:myapp/models/logistics_firm.dart';
import 'package:myapp/screens/dummy_payment_screen.dart'; // Import the dummy payment screen
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
      final serviceFee = widget.firm.price * 0.1;
      final totalPrice = widget.firm.price + serviceFee;

      // The logic to create the order now happens *after* successful payment simulation
      final List<Map<String, dynamic>> newOrder = await supabase.from('orders').insert({
        'customer_id': currentUser.id,
        'pickup_location': widget.orderDetails['pickupLocation'],
        'delivery_location': widget.orderDetails['deliveryLocation'],
        'pickup_contact': widget.orderDetails['pickupContact'],
        'receiver_contact': widget.orderDetails['receiverContact'],
        'item_details': widget.orderDetails['itemDetails'],
        'status': 'pending',
        'total_price': totalPrice,
      }).select('id');

      if (mounted && newOrder.isNotEmpty) {
        final orderId = newOrder.first['id'];
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => OrderTrackingScreen(orderId: orderId)),
          (route) => route.isFirst,
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to create order: $e'), backgroundColor: Colors.red));
      if (mounted) setState(() { _isPlacingOrder = false; });
    }
  }

  void _navigateToPayment() {
    final serviceFee = widget.firm.price * 0.1;
    final totalPayable = widget.firm.price + serviceFee;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => DummyPaymentScreen(
          amount: totalPayable,
          onPaymentSuccess: () {
            // This is the callback function. It gets executed when the user
            // clicks "Simulate Successful Payment" on the next screen.
            Navigator.of(context).pop(); // Close the payment screen
            _placeOrderAfterPayment(); // Then proceed to create the order
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final serviceFee = widget.firm.price * 0.1;
    final totalPayable = widget.firm.price + serviceFee;

    return Scaffold(
      appBar: AppBar(title: const Text('Confirm Your Order')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('SELECTED RIDER', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(height: 8),
            Card(child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person)),
              title: Text(widget.firm.companyName, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Row(children: [const Icon(Icons.star, color: Colors.amber, size: 16), Text(' ${widget.firm.rating}')]),
            )),
            const SizedBox(height: 24),
            const Text('PRICE SUMMARY', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(height: 8),
            Card(child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Delivery Fee'), Text('₦${widget.firm.price.toStringAsFixed(2)}')]),
                  const SizedBox(height: 8),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Service Fee (10%)'), Text('₦${serviceFee.toStringAsFixed(2)}')]),
                  const Divider(height: 24),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    const Text('Total Payable', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    Text('₦${totalPayable.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  ]),
                ],
              ),
            )),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: _isPlacingOrder
                  ? const Center(child: Column(children: [CircularProgressIndicator(), SizedBox(height: 8), Text("Placing order...")]))
                  : ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                      onPressed: _navigateToPayment, // Navigate to the payment screen
                      child: const Text('PROCEED TO PAYMENT', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}