import 'package:baddel/screens/splash_screen.dart';
import 'package:baddel/services/supabase_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  setupLocator();

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
      home: const SplashScreen(),
    );
  }
}
