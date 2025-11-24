import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:super_admin/screens/company_screen.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🧩 Initialize Supabase
  await Supabase.initialize(
    url: 'https://sjajaycmqwpqhepvqvzi.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNqYWpheWNtcXdwcWhlcHZxdnppIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjI4Nzc5NzcsImV4cCI6MjA3ODQ1Mzk3N30.uFW5koljLypGF1f7xjE64muSHXOCnsshuYXD6PEfjlc',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Stellar Admin',
      theme: ThemeData(
        primaryColor: const Color(0xFF6A11CB),
        hintColor: const Color(0xFF2575FC),
        scaffoldBackgroundColor: const Color(0xFFF5F7FA),
        visualDensity: VisualDensity.adaptivePlatformDensity,
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: const MaterialColor(
            0xFF6A11CB,
            <int, Color>{
              50: Color(0xFFE8E0F3),
              100: Color(0xFFC6B3E1),
              200: Color(0xFFA080CE),
              300: Color(0xFF7A4DBC),
              400: Color(0xFF5E27AD),
              500: Color(0xFF42009E),
              600: Color(0xFF3C0096),
              700: Color(0xFF34008C),
              800: Color(0xFF2D0083),
              900: Color(0xFF1F0071),
            },
          ),
        ).copyWith(secondary: const Color(0xFF2575FC)),
      ),
      home: const CompaniesScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
