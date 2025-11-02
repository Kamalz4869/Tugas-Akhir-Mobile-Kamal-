import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'pages/login_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://drtrovipzryufirfhvcf.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRydHJvdmlwenJ5dWZpcmZodmNmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjE5NTY0MDUsImV4cCI6MjA3NzUzMjQwNX0.C_S3Cu0L594yqzhc-uNuSQAhpKAkDvCCsqWjKXQ3Lp4',
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Steam Game Price App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.light,
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          selectedItemColor: Colors.blue,
          unselectedItemColor: Colors.lightBlue,
        ),
      ),
      home: const LoginPage(),
    );
  }
}
