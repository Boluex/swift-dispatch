// lib/screens/welcome_screen.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:myapp/main.dart';
import 'package:myapp/screens/home_screen.dart';
import 'package:myapp/screens/login_screen.dart';
import 'package:myapp/screens/registration_screen.dart';
import 'package:myapp/screens/rider/rider_registration_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  bool _isGoogleLoading = false;

  Future<void> _signInWithGoogle() async {
    setState(() { _isGoogleLoading = true; });
    try {
      // Get the Web Client ID from your Google Cloud Console
      // You MUST follow the Supabase guide to get this value.
      const webClientId = '763588143758-ov3kit3e7d2ti2l38na5t8fin25npqat.apps.googleusercontent.com';

      final GoogleSignIn googleSignIn = GoogleSignIn(serverClientId: webClientId);
      final googleUser = await googleSignIn.signIn();
      final googleAuth = await googleUser!.authentication;
      final accessToken = googleAuth.accessToken;
      final idToken = googleAuth.idToken;

      if (accessToken == null || idToken == null) {
        throw 'Google sign in failed: missing token.';
      }

      // Sign in to Supabase with the Google credentials
      final AuthResponse res = await supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );

      if (res.user != null) {
        // Check if a profile already exists for this user
        final userProfile = await supabase.from('profiles').select().eq('id', res.user!.id).maybeSingle();

        if (userProfile == null) {
          // If it's a new user, create their profile
          await supabase.from('profiles').insert({
            'id': res.user!.id,
            'full_name': res.user!.userMetadata?['full_name'],
            'email': res.user!.email,
            'role': 'customer', // Default role for Google sign-in
          });
        }
        if (mounted) Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => const HomeScreen()));
      }
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Google Sign-In Failed: $e"), backgroundColor: Colors.red));
    }
    if(mounted) setState(() { _isGoogleLoading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.delivery_dining_rounded, size: 100, color: Colors.amber),
              const SizedBox(height: 20),
              const Text('Welcome to Swift Dispatch', textAlign: TextAlign.center, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 40),
              
              // --- NEW GOOGLE SIGN IN BUTTON ---
              _isGoogleLoading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton.icon(
                    icon: Image.asset('assets/google_logo.png', height: 24.0), // You need to add a google logo to your assets
                    label: const Text('Sign in with Google', style: TextStyle(fontSize: 16)),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black),
                    onPressed: _signInWithGoogle,
                  ),
              const SizedBox(height: 16),

              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white),
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => const LoginScreen())),
                child: const Text('Sign in with Email', style: TextStyle(fontSize: 16)),
              ),
              const SizedBox(height: 30),
              const Text("Don't have an account?", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
              TextButton(
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => const RegistrationScreen())),
                child: const Text('Create a Customer Account', style: TextStyle(color: Colors.black)),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => const RiderRegistrationScreen())),
                child: const Text('Become a Dispatch Rider', style: TextStyle(color: Colors.black)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}