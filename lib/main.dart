import 'package:baddel/screens/main_screen.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    // TODO: Replace with your own Supabase URL and anon key
    url: 'YOUR_SUPABASE_URL',
    anonKey: 'YOUR_SUPABASE_ANON_KEY',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Baddel',
      theme: ThemeData.dark().copyWith(
        primaryColor: const Color(0xFF2962FF),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF2962FF),
          secondary: Color(0xFFBB86FC),
          surface: Colors.black,
          background: Colors.black,
          error: Color(0xFFFF1744),
        ),
      ),
      home: const MainScreen(),
    );
  }
}
