import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:google_generative_ai/google_generative_ai.dart'; // AI එකට
import 'package:image_picker/image_picker.dart'; // Photo ගන්න
import 'dart:async';
import 'dart:io';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await MobileAds.instance.initialize();
  runApp(const FridgeFeastApp());
}

class FridgeFeastApp extends StatelessWidget {
  const FridgeFeastApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'FridgeFeast',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.deepOrange,
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
  final TextEditingController _ingredientController = TextEditingController();
  List<String> ingredients = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initAd();
    _checkConnectivity();
  }

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

  // Internet නැත්නම් Error එකක් දෙනවා
  void _checkConnectivity() async {
    var result = await Connectivity().checkConnectivity();
    if (result.contains(ConnectivityResult.none)) {
      _showError("No Connection", "AI වැඩ කරන්න ඉන්ටර්නෙට් ඕනේ මචං!");
    }
  }

  // AI එකෙන් Recipe Generate කරන තැන
  Future<void> _generateRecipes() async {
    if (ingredients.isEmpty) {
      _showError("Items මදි", "කරුණාකර මොනවා හරි ඇතුළත් කරන්න.");
      return;
    }

    setState(() => _isLoading = true);

    try {
      // මෙතනට ඔයා අරගත්ත API Key එක දාන්න
      const apiKey = "මෙතනට_ඔයාගේ_API_KEY_එක_පේස්ට්_කරන්න";
      
      // ERROR FIX: මෙතන version එක දාන්න එපා, කෙලින්ම මොඩල් එක විතරක් දෙන්න
      final model = GenerativeModel(
        model: 'gemini-1.5-flash', 
        apiKey: apiKey,
      );

      final prompt = "I have ${ingredients.join(", ")} in my fridge. Give me 3 quick recipes.";
      final content = [Content.text(prompt)];
      final response = await model.generateContent(content);

      _showResponse(response.text ?? "AI එකට උත්තරයක් දෙන්න බැරි වුණා.");
    } catch (e) {
      _showError("AI Error", "මොකක් හරි අවුලක් වුණා. API Key එක හරිද බලන්න.");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showError(String title, String msg) {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(title),
        content: Text(msg),
        actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text("OK"))],
      ),
    );
  }

  void _showResponse(String text) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (c) => Container(
        padding: const EdgeInsets.all(20),
        height: MediaQuery.of(context).size.height * 0.7,
        child: SingleChildScrollView(child: Text(text)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("FridgeFeast", style: GoogleFonts.lobster(fontSize: 28, color: Colors.orange)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ingredientController,
                    decoration: const InputDecoration(
                      hintText: "Add ingredient (e.g. Tomato)",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle, color: Colors.orange, size: 40),
                  onPressed: () {
                    if (_ingredientController.text.isNotEmpty) {
                      setState(() {
                        ingredients.add(_ingredientController.text);
                        _ingredientController.clear();
                      });
                    }
                  },
                ),
              ],
            ),
          ),
          
          Expanded(
            child: ListView.builder(
              itemCount: ingredients.length,
              itemBuilder: (context, index) => ListTile(
                leading: const Icon(Icons.check, color: Colors.green),
                title: Text(ingredients[index]),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => setState(() => ingredients.removeAt(index)),
                ),
              ),
            ),
          ),

          if (_isLoading) const CircularProgressIndicator(),

          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                minimumSize: const Size(double.infinity, 50),
              ),
              onPressed: _generateRecipes,
              child: const Text("Generate Creative Recipes", style: TextStyle(color: Colors.white)),
            ),
          ),

          if (_isAdLoaded)
            SizedBox(
              height: _bannerAd!.size.height.toDouble(),
              width: _bannerAd!.size.width.toDouble(),
              child: AdWidget(ad: _bannerAd!),
            ),
        ],
      ),
    );
  }
}
