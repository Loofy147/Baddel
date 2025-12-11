import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:baddel/ui/screens/deck/home_deck_screen.dart'; // We will create this next

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🟢 REPLACE WITH YOUR ACTUAL SUPABASE KEYS
  await Supabase.initialize(
    url: 'YOUR_SUPABASE_URL',
    anonKey: 'YOUR_SUPABASE_ANON_KEY',
  );

  runApp(const BaddelApp());
}

class BaddelApp extends StatelessWidget {
  const BaddelApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Baddel',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark, // 🌑 DARK MODE AS PLANNED
        primaryColor: const Color(0xFF2962FF), // Electric Blue
        scaffoldBackgroundColor: const Color(0xFF000000), // OLED Black
        useMaterial3: true,
      ),
      home: const HomeDeckScreen(),
    );
  }
}
