// lib/screens/order_tracking_screen.dart
import 'package:flutter/material.dart';
import 'package:myapp/main.dart';

class OrderTrackingScreen extends StatelessWidget {
  final int orderId;
  const OrderTrackingScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Track Your Order'),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: supabase.from('orders').stream(primaryKey: ['id']).eq('id', orderId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || snapshot.data!.isEmpty) return const Center(child: Text('Order not found.'));

          final orderData = snapshot.data!.first;
          final status = orderData['status'] ?? 'pending';
          final List<String> statuses = ['pending', 'accepted', 'pickedUp', 'delivered'];
          final int currentStatusIndex = statuses.indexOf(status);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Hi Tokunbo,", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)), // This would be dynamic
                Text("Your order arrives in ~8 mins", style: TextStyle(fontSize: 16, color: Colors.grey[700])), // This would be dynamic
                const SizedBox(height: 24),
                // --- THE NEW VERTICAL STEPPER UI ---
                _buildStatusStep(
                  title: 'Preparing Your Order',
                  subtitle: 'The rider is preparing for your trip.',
                  timestamp: '03:28pm', // Placeholder
                  isActive: true, // The first step is always active
                  isCompleted: currentStatusIndex > 0,
                ),
                _buildStatusStep(
                  title: 'Rider Accepted Order',
                  subtitle: 'Rider is on the way to pick up your order.',
                  timestamp: '03:30pm', // Placeholder
                  isActive: currentStatusIndex >= 1,
                  isCompleted: currentStatusIndex > 1,
                  isLast: false,
                ),
                _buildStatusStep(
                  title: 'Order In Transit',
                  subtitle: 'Your item is on its way to you.',
                  timestamp: '03:42pm', // Placeholder
                  isActive: currentStatusIndex >= 2,
                  isCompleted: currentStatusIndex > 2,
                  isLast: false,
                ),
                _buildStatusStep(
                  title: 'Order has arrived',
                  subtitle: 'Your item has been delivered.',
                  timestamp: '03:45pm', // Placeholder
                  isActive: currentStatusIndex >= 3,
                  isCompleted: currentStatusIndex >= 3,
                  isLast: true,
                ),
                // --- END OF STEPPER ---
                const SizedBox(height: 32),
                const Text("Delivery details", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(orderData['delivery_location'] ?? 'Not specified', style: TextStyle(fontSize: 16, color: Colors.grey[700])),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {},
                    child: const Text('CALL RIDER'),
                  ),
                )
              ],
            ),
          );
        },
      ),
    );
  }

  // --- HELPER WIDGET FOR THE STEPPER ---
  Widget _buildStatusStep({
    required String title,
    required String subtitle,
    required String timestamp,
    required bool isActive,
    required bool isCompleted,
    bool isLast = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCompleted ? Colors.green : (isActive ? Colors.green : Colors.grey[300]),
              ),
              child: isCompleted
                  ? const Icon(Icons.check, color: Colors.white, size: 16)
                  : (isActive ? const Padding(padding: EdgeInsets.all(6.0), child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : null),
            ),
            if (!isLast)
              Container(
                height: 60,
                width: 2,
                color: isCompleted ? Colors.green : Colors.grey[300],
              ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isActive ? Colors.black : Colors.grey)),
              const SizedBox(height: 4),
              Text(subtitle, style: TextStyle(color: isActive ? Colors.black54 : Colors.grey)),
            ],
          ),
        ),
        Text(timestamp, style: TextStyle(color: isActive ? Colors.black54 : Colors.grey)),
      ],
    );
  }
}



