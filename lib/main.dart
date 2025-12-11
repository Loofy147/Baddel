import 'package:baddel/ui/screens/auth/login_screen.dart';
import 'package:baddel/ui/screens/main_layout.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
    // 1. CHECK SESSION ON LAUNCH
    final session = Supabase.instance.client.auth.currentSession;
    final bool isLoggedIn = session != null;

    return MaterialApp(
      title: 'Baddel',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF2962FF),
        scaffoldBackgroundColor: const Color(0xFF000000),
        useMaterial3: true,
      ),
      // 2. ROUTING LOGIC
      // If logged in -> HomeDeck. If not -> Login.
      home: isLoggedIn ? const MainLayout() : const LoginScreen(),
    );
  }
}
