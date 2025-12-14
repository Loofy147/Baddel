import 'package:baddel/ui/screens/auth/login_screen.dart';
import 'package:baddel/ui/screens/admin/analytics_dashboard.dart';
import 'package:baddel/ui/screens/main_layout.dart';
import 'package:baddel/ui/screens/onboarding/onboarding_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'YOUR_SUPABASE_URL',
    anonKey: 'YOUR_SUPABASE_ANON_KEY',
  );

  runApp(const ProviderScope(child: BaddelApp()));
}

class BaddelApp extends StatelessWidget {
  const BaddelApp({super.key});

  Future<bool> _isFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    final isFirstLaunch = prefs.getBool('first_launch') ?? true;
    if (isFirstLaunch) {
      await prefs.setBool('first_launch', false);
    }
    return isFirstLaunch;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Baddel',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF2962FF),
        scaffoldBackgroundColor: const Color(0xFF000000),
        useMaterial3: true,
      ),
      home: FutureBuilder<bool>(
        future: _isFirstLaunch(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }

          if (snapshot.data == true) {
            return const OnboardingScreen();
          }

          final session = Supabase.instance.client.auth.currentSession;
          return session != null ? const MainLayout() : const LoginScreen();
        },
      ),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/analytics': (context) => const AnalyticsDashboard(),
      },
    );
  }
}
