import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';

// -- Pages --
import 'pages/main_screen.dart';
import 'pages/00_page_home.dart';
import 'pages/01_page_login.dart';
// import 'pages/02_page_buysell.dart';
import 'pages/03_page_appointment.dart';
// import 'pages/04_page_history.dart';
import 'pages/99_page_blank.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Enforce required logout on app open:
  await FirebaseAuth.instance.signOut();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sung Seng Lee Gold',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF800000), // Deep Maroon Red
          secondary: const Color(0xFFFFD700), // Gold
          surface: const Color(
            0xFFFFF8E1,
          ), // Light Cream (optional warm background)
        ),
        scaffoldBackgroundColor: const Color(0xFFFFF8E1),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF800000),
          foregroundColor: Color(0xFFFFD700),
          centerTitle: true,
        ),
      ),

      initialRoute: '/',
      routes: {
        '/': (_) => const MainScreen(),
        '/login': (_) => const LoginPage(),
        //        '/buy-sell': (_) => const BuySellPage(),
        '/appointment': (_) => const AppointmentPage(),
        //       '/history': (_) => const HistoryPage(),
        '/blank': (_) => const BlankPage(),
      },
    );
  }
}
