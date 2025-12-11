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

  // 🟢 ANONYMOUS AUTH (Temporary for testing "Wild" mode)
  // This gives the app a valid User ID so DB writes don't fail.
  try {
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) {
      await Supabase.instance.client.auth.signInAnonymously();
      print("👻 Signed in Anonymously!");
    }
  } catch(e) {
    print("Auth Error: $e");
  }

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
