// lib/screens/login_screen.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:myapp/main.dart'; // Import for the supabase instance
import 'package:myapp/screens/home_screen.dart';
import 'package:myapp/screens/rider/pending_approval_screen.dart';
import 'package:myapp/screens/rider/rider_dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _loginUser() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() { _isLoading = true; });

    try {
      // Step 1: Sign in with Supabase Auth
      final AuthResponse res = await supabase.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (res.user != null) {
        // Step 2: Get the user's profile from the 'profiles' table
        final List<dynamic> data = await supabase
            .from('profiles')
            .select('role, approval_status')
            .eq('id', res.user!.id);

        if (mounted && data.isNotEmpty) {
          final profile = data.first;
          final role = profile['role'];
          final status = profile['approval_status'];

          // Step 3: Smart Redirection based on role and status
          if (role == 'customer') {
            Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (context) => const HomeScreen()), (route) => false);
          } else if (role == 'rider') {
            if (status == 'approved') {
              Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (context) => const RiderDashboardScreen()), (route) => false);
            } else { // 'pending' or 'rejected'
              Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (context) => const PendingApprovalScreen()), (route) => false);
            }
          }
        } else {
           // This is an edge case, user exists in Auth but not in our profiles table.
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User profile not found. Please contact support.'), backgroundColor: Colors.red));
        }
      }
    } on AuthException catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message), backgroundColor: Colors.red));
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('An unexpected error occurred: $e'), backgroundColor: Colors.red));
    }

    if(mounted) setState(() { _isLoading = false; });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(controller: _emailController, decoration: const InputDecoration(labelText: 'Email Address', border: OutlineInputBorder()), keyboardType: TextInputType.emailAddress, validator: (v) => (v == null || !v.contains('@')) ? 'Please enter a valid email' : null),
              const SizedBox(height: 16),
              TextFormField(controller: _passwordController, decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder()), obscureText: true, validator: (v) => (v == null || v.isEmpty) ? 'Please enter your password' : null),
              const SizedBox(height: 32),
              _isLoading ? const Center(child: CircularProgressIndicator()) : ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white), onPressed: _loginUser, child: const Text('Login', style: TextStyle(fontSize: 16))),
            ],
          ),
        ),
      ),
    );
  }
}