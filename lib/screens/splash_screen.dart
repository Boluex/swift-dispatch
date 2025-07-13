// lib/screens/splash_screen.dart
import 'package:flutter/material.dart';
import 'package:myapp/main.dart';
import 'package:myapp/screens/home_screen.dart';
import 'package:myapp/screens/rider/rider_dashboard_screen.dart';
import 'package:myapp/screens/welcome_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Wait a moment for Supabase to initialize, then check the session
    WidgetsBinding.instance.addPostFrameCallback((_) => _redirect());
  }

  Future<void> _redirect() async {
    // This delay gives Supabase time to load the persisted session from device storage
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;

    final session = supabase.auth.currentSession;
    final user = supabase.auth.currentUser;

    if (session == null || user == null) {
      // If no session, go to WelcomeScreen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const WelcomeScreen()),
      );
    } else {
      // If there IS a session, check the user's role from the database
      try {
        final data = await supabase
            .from('profiles')
            .select('role, approval_status')
            .eq('id', user.id)
            .single();
        
        final role = data['role'];
        if (role == 'rider') {
          // If rider, send them to their dashboard
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const RiderDashboardScreen()),
          );
        } else { // 'customer' or any other role
          // If customer, send them to the main home screen
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        }
      } catch (e) {
        // If there's an error fetching the profile (e.g., network issue),
        // log them out and send to welcome screen for safety.
        await supabase.auth.signOut();
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const WelcomeScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // A simple loading screen UI
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}