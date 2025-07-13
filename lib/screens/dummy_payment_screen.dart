// lib/screens/dummy_payment_screen.dart

import 'package:flutter/material.dart';

class DummyPaymentScreen extends StatelessWidget {
  final double amount;
  final VoidCallback onPaymentSuccess;

  const DummyPaymentScreen({
    super.key,
    required this.amount,
    required this.onPaymentSuccess,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Simulate Payment')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.payment, size: 80, color: Colors.grey),
              const SizedBox(height: 20),
              Text(
                'Total Amount Due',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              Text(
                '₦${amount.toStringAsFixed(2)}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                onPressed: onPaymentSuccess, // This calls the function passed from the previous screen
                child: const Text('Simulate Successful Payment'),
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Payment Failed. Please try again.'), backgroundColor: Colors.red),
                  );
                },
                child: const Text('Simulate Failed Payment'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}