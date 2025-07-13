// lib/main.dart
import 'package:myapp/screens/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await Supabase.initialize(
    url: 'https://chhgumlknhvtycpekbba.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNoaGd1bWxrbmh2dHljcGVrYmJhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTA2MzE0MDksImV4cCI6MjA2NjIwNzQwOX0.gV86v0rDbVb3AJ0SAgZRLvaaSBL2FscTGhVYq63cVic',
  );

  runApp(const MyApp());
}

// Helper for accessing Supabase instance easily from any file
final supabase = Supabase.instance.client;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Swift Dispatch',
      theme: ThemeData(
        // Your theme data here...
      ),
       home: const SplashScreen(),
    );
  }
}