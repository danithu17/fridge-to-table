import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:async';
import 'dart:io';

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
        colorSchemeSeed: const Color(0xFFFF6D3F), // FridgeFeast Orange Theme
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

  // AdMob Setup - සල්ලි හම්බවෙන්න නම් පස්සේ ඔයාගේ Real ID එක මෙතනට දාන්න
  void _initAd() {
    _bannerAd = BannerAd(
      adUnitId: 'ca-app-pub-7036399347927896/6074120884', // දැනට Test ID එකක් තියෙන්නේ
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (ad) => setState(() => _isAdLoaded = true),
        onAdFailedToLoad: (ad, err) => ad.dispose(),
      ),
    )..load();
  }

  // Internet නැති වුණොත් දැනුම් දෙනවා
  void _checkInternet() {
    _connectivitySub = Connectivity().onConnectivityChanged.listen((results) {
      if (results.contains(ConnectivityResult.none)) {
        _showErrorDialog("Connection Lost", "AI එක වැඩ කරන්න ඉන්ටර්නෙට් ඕනේ මචං!");
      }
    });
  }

  void _showErrorDialog(String title, String msg) {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(msg),
        actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text("OK"))],
      ),
    );
  }

  // AI Recipe Generation Fix
  Future<void> _generateRecipes() async {
    if (_ingredients.isEmpty) {
      _showErrorDialog("හිස්නෙ මචං", "මොනවා හරි දේවල් ටිකක් කලින් ඇඩ් කරන්න.");
      return;
    }

    setState(() => _isLoading = true);

    try {
      // මෙතනට ඔයාගේ Gemini API Key එක අනිවාර්යයෙන් දාන්න
      const apiKey = "මෙතනට_ඔයාගේ_API_KEY_එක_දාන්න";
      final model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: apiKey);

      final prompt = "I have ${_ingredients.join(", ")} in my fridge. Give me 3 creative recipes.";
      final response = await model.generateContent([Content.text(prompt)]);

      _showResultSheet(response.text ?? "සොරි මචං, AI එකට උත්තරයක් දෙන්න බැරි වුණා.");
    } catch (e) {
      _showErrorDialog("AI Error", "API Key එක හෝ ඉන්ටර්නෙට් චෙක් කරන්න.");
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("FridgeFeast", style: GoogleFonts.fredokaOne(color: const Color(0xFFFF6D3F), fontSize: 28)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [IconButton(onPressed: () => setState(() => _ingredients.clear()), icon: const Icon(Icons.refresh))],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("What's in your fridge?", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF2D2D2D))),
                const SizedBox(height: 15),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        decoration: InputDecoration(
                          hintText: "Add ingredient (e.g. Tomato)",
                          filled: true,
                          fillColor: Colors.grey[100],
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    _actionButton(Icons.add, () {
                      if (_controller.text.isNotEmpty) {
                        setState(() { _ingredients.add(_controller.text); _controller.clear(); });
                      }
                    }),
                  ],
                ),
              ],
            ),
          ),
          
          // Ingredient List
          Expanded(
            child: ListView.builder(
              itemCount: _ingredients.length,
              itemBuilder: (context, index) => Card(
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                child: ListTile(
                  title: Text(_ingredients[index]),
                  trailing: IconButton(icon: const Icon(Icons.close, color: Colors.red), onPressed: () => setState(() => _ingredients.removeAt(index))),
                ),
              ),
            ),
          ),

          if (_isLoading) const CircularProgressIndicator(color: Color(0xFFFF6D3F)),

          // Generate Button
          Padding(
            padding: const EdgeInsets.all(20),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6D3F),
                minimumSize: const Size(double.infinity, 55),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              ),
              onPressed: _generateRecipes,
              child: const Text("Generate Creative Recipes", style: TextStyle(fontSize: 18, color: Colors.white)),
            ),
          ),

          // AdMob Banner
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

  Widget _actionButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: const Color(0xFFFFF0EB), borderRadius: BorderRadius.circular(15)),
        child: Icon(icon, color: const Color(0xFFFF6D3F)),
      ),
    );
  }
}
