import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:async';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  unawaited(MobileAds.instance.initialize());
  runApp(const FridgeFeastApp());
}

class FridgeFeastApp extends StatelessWidget {
  const FridgeFeastApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFFFF6D3F),
        textTheme: GoogleFonts.poppinsTextTheme(),
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;
  final TextEditingController _controller = TextEditingController();
  final List<String> _ingredients = [];
  bool _isLoading = false;
  late StreamSubscription<List<ConnectivityResult>> _connectivitySub;

  @override
  void initState() {
    super.initState();
    _initAd();
    _checkInternet();
  }

  void _initAd() {
    _bannerAd = BannerAd(
      adUnitId: 'ca-app-pub-7036399347927896/6074120884', 
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (ad) => setState(() => _isAdLoaded = true),
        onAdFailedToLoad: (ad, err) {
          ad.dispose();
        },
      ),
    )..load();
  }

  void _checkInternet() {
    _connectivitySub = Connectivity().onConnectivityChanged.listen((results) {
      if (results.contains(ConnectivityResult.none)) {
        _showErrorDialog("Offline!", "AI වැඩ කරන්න ඉන්ටර්නෙට් ඕනේ මචං!");
      }
    });
  }

  void _showErrorDialog(String title, String msg) {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(title),
        content: Text(msg),
        actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text("OK"))],
      ),
    );
  }

  Future<void> _generateRecipes() async {
    if (_ingredients.isEmpty) {
      _showErrorDialog("හිස්නෙ මචං", "මොනවා හරි ඇතුළත් කරන්න.");
      return;
    }

    setState(() => _isLoading = true);

    try {
      const apiKey = "AIzaSyCVpg99ta6BidHN46IPknuV4IpDNWCnO8M"; 
      final model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: apiKey);

      final prompt = "I have ${_ingredients.join(", ")}. Give me 3 quick recipes.";
      final response = await model.generateContent([Content.text(prompt)]);

      _showResultSheet(response.text ?? "සොරි, උත්තරයක් ලැබුණේ නැහැ.");
    } catch (e) {
      _showErrorDialog("AI Error", "API Key එක හෝ නෙට්වර්ක් අවුලක්.");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showResultSheet(String text) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (c) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        expand: false,
        builder: (context, scrollController) => Padding(
          padding: const EdgeInsets.all(20.0),
          child: SingleChildScrollView(controller: scrollController, child: Text(text)),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    _connectivitySub.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // මෙතන තමයි Font එක හදලා තියෙන්නේ (fredokaOne වෙනුවට lobster)
        title: Text("FridgeFeast", style: GoogleFonts.lobster(color: const Color(0xFFFF6D3F), fontSize: 28)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(hintText: "Add ingredient"),
                  ),
                ),
                IconButton(icon: const Icon(Icons.add), onPressed: _addIngredient),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _ingredients.length,
              itemBuilder: (context, index) => ListTile(
                title: Text(_ingredients[index]),
                trailing: IconButton(icon: const Icon(Icons.delete), onPressed: () => setState(() => _ingredients.removeAt(index))),
              ),
            ),
          ),
          if (_isLoading) const CircularProgressIndicator(),
          Padding(
            padding: const EdgeInsets.all(20),
            child: ElevatedButton(onPressed: _generateRecipes, child: const Text("Generate Recipes")),
          ),
          if (_isAdLoaded)
            SizedBox(height: 50, child: AdWidget(ad: _bannerAd!)),
        ],
      ),
    );
  }

  void _addIngredient() {
    if (_controller.text.trim().isNotEmpty) {
      setState(() {
        _ingredients.add(_controller.text.trim());
        _controller.clear();
      });
    }
  }
}
