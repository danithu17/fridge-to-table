import 'package:flutter/material.dart';
<<<<<<< HEAD
import 'package:flutter_riverpod/flutter_riverpod.dart';
=======
>>>>>>> 5799d9e17bd869c8d8ab2b834374425afac2fa97
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';
<<<<<<< HEAD
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  unawaited(MobileAds.instance.initialize());
  runApp(
    const ProviderScope(
      child: FridgeToTableApp(),
    ),
  );
=======

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await MobileAds.instance.initialize();
  runApp(const FridgeToTableApp());
>>>>>>> 5799d9e17bd869c8d8ab2b834374425afac2fa97
}

class FridgeToTableApp extends StatelessWidget {
  const FridgeToTableApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
<<<<<<< HEAD
      title: 'Fridge to Table AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFFFF6B35),
        textTheme: GoogleFonts.poppinsTextTheme(),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFF6B35),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
=======
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.green,
        textTheme: GoogleFonts.poppinsTextTheme(),
>>>>>>> 5799d9e17bd869c8d8ab2b834374425afac2fa97
      ),
      home: const HomeScreen(),
    );
  }
}
<<<<<<< HEAD
=======

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;
  late StreamSubscription<List<ConnectivityResult>> connectivitySub;

  @override
  void initState() {
    super.initState();
    _initAd();
    _checkInternet();
  }

  // 1. AdMob Setup
  void _initAd() {
    _bannerAd = BannerAd(
      adUnitId: 'ca-app-pub-3940256099942544/6300978111', // Test ID
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (ad) => setState(() => _isAdLoaded = true),
        onAdFailedToLoad: (ad, err) => ad.dispose(),
      ),
    )..load();
  }

  // 2. Internet Connection Check
  void _checkInternet() {
    connectivitySub = Connectivity().onConnectivityChanged.listen((results) {
      if (results.contains(ConnectivityResult.none)) {
        _showError("No Internet!", "AI scan එක වැඩ කරන්න නම් ඉන්ටර්නෙට් ඕනේ මචං.");
      }
    });
  }

  void _showError(String title, String msg) {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(msg),
        actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text("OK"))],
      ),
    );
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    connectivitySub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text("🍎 Fridge to Table AI", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Recipe List (Infinite-like scroll)
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: 15,
              itemBuilder: (context, index) => Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: ListTile(
                  leading: const CircleAvatar(backgroundColor: Colors.green, child: Icon(Icons.restaurant, color: Colors.white)),
                  title: Text("Recipe Idea ${index + 1}", style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text("Tap to see ingredients and AI guide"),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                ),
              ),
            ),
          ),
          
          // AdMob Banner at bottom
          if (_isAdLoaded)
            SizedBox(
              width: _bannerAd!.size.width.toDouble(),
              height: _bannerAd!.size.height.toDouble(),
              child: AdWidget(ad: _bannerAd!),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showError("AI Scan", "Gemini API Key එක තාම දාලා නැහැ මචං. ඒක දැම්ම ගමන් මේක වැඩ!"),
        icon: const Icon(Icons.camera_alt),
        label: const Text("Scan Fridge"),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
      ),
    );
  }
}
>>>>>>> 5799d9e17bd869c8d8ab2b834374425afac2fa97
