import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';
import 'screens/home_screen.dart';

void main() async {
  // Ensure Flutter engine is ready
  WidgetsFlutterBinding.ensureInitialized();
<<<<<<< HEAD
  unawaited(MobileAds.instance.initialize());
=======
  
  // Initialize Mobile Ads SDK
  await MobileAds.instance.initialize();
  
>>>>>>> 5a0b667382ec38c1f6d820dce5ef9441ab9eb3d0
  runApp(
    const ProviderScope(
      child: FridgeToTableApp(),
    ),
  );
}

class FridgeToTableApp extends StatelessWidget {
  const FridgeToTableApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fridge to Table AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
<<<<<<< HEAD
        scaffoldBackgroundColor: const Color(0xFFF9F9F4),
        colorSchemeSeed: const Color(0xFFFF6B35),
        textTheme: GoogleFonts.outfitTextTheme(),
        cardTheme: CardTheme(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          color: Colors.white,
=======
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFF6B35), // The Orange 'Foodie' color
          primary: const Color(0xFFFF6B35),
          secondary: const Color(0xFFF7C59F),
          surface: Colors.white,
          background: const Color(0xFFFAFAFA),
        ),
        textTheme: GoogleFonts.outfitTextTheme(
          Theme.of(context).textTheme,
>>>>>>> 5a0b667382ec38c1f6d820dce5ef9441ab9eb3d0
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFF6B35),
            foregroundColor: Colors.white,
            elevation: 8,
            shadowColor: const Color(0xFFFF6B35).withOpacity(0.4),
            padding: const EdgeInsets.symmetric(vertical: 18),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}