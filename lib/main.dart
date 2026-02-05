import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:google_fonts/google_fonts.dart';

void main() async {
  // Flutter Engine එක සහ AdMob Initialize කිරීම
  WidgetsFlutterBinding.ensureInitialized();
  await MobileAds.instance.initialize();
  
  runApp(const FridgeToTableApp());
}

class FridgeToTableApp extends StatelessWidget {
  const FridgeToTableApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fridge to Table',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        // ඇප් එකේ ප්‍රධාන පාට කොළ පාටට ගත්තා (Fresh Look)
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green.shade700),
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
  bool _isBannerAdLoaded = false;

  // ⚠️ වැදගත්: මේක Google දෙන Test ID එක. 
  // ඇප් එක Play Store දාද්දි විතරක් ඔයාගේ සැබෑ Ad Unit ID එක මෙතනට දාන්න.
  final String adUnitId = 'ca-app-pub-3940256099942544/6300978111';

  @override
  void initState() {
    super.initState();
    _loadBannerAd();
  }

  // Banner Ad එක ලෝඩ් කරන ෆන්ක්ෂන් එක
  void _loadBannerAd() {
    _bannerAd = BannerAd(
      adUnitId: adUnitId,
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          setState(() {
            _isBannerAdLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          print('Ad failed to load: $error');
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('🍎 Fridge to Table', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.notifications_none)),
        ],
      ),
      body: Column(
        children: [
          // සර්ච් බාර් එක (UI එක Advance කරන්න)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search items in fridge...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // Fridge Items ලිස්ට් එක
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildFoodItem("Milk Carton", "Expires in 2 days", Colors.blue.shade100, Icons.local_drink),
                _buildFoodItem("Fresh Eggs", "Expires in 5 days", Colors.orange.shade100, Icons.egg),
                _buildFoodItem("Green Spinach", "Expires today", Colors.green.shade100, Icons.eco),
                _buildFoodItem("Chicken Breast", "Expires in 1 day", Colors.red.shade100, Icons.kebab_dining),
              ],
            ),
          ),

          // පතුලේ ඇඩ් එක පෙන්වන කොටස
          if (_isBannerAdLoaded)
            Container(
              alignment: Alignment.center,
              width: _bannerAd!.size.width.toDouble(),
              height: _bannerAd!.size.height.toDouble(),
              child: AdWidget(ad: _bannerAd!),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_a_photo),
        label: const Text("Scan Fridge"),
      ),
    );
  }

  // ඇප් එකේ අයිතම පෙන්වන කාඩ් එක හදන හැටි
  Widget _buildFoodItem(String name, String expiry, Color bgColor, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5)),
        ],
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: Colors.black87),
        ),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(expiry, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
        trailing: const Icon(Icons.more_vert, size: 20),
      ),
    );
  }
}