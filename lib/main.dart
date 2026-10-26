import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // import for saving language
import 'screens/login_screen.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Save ki gayi language load karein (Default: English)
  final prefs = await SharedPreferences.getInstance();
  String savedLang = prefs.getString('selected_language') ?? 'English';

  runApp(TailorShopApp(initialLanguage: savedLang));
}

class TailorShopApp extends StatelessWidget {
  final String initialLanguage;
  const TailorShopApp({super.key, required this.initialLanguage});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tailor Management Pro',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.grey[100],
      ),
      // Login screen ko initial language pass karenge
      home: LoginScreen(initialLanguage: initialLanguage),
    );
  }
}