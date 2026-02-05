import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../services/gemini_service.dart';
import '../models/recipe.dart';
import 'recipe_detail_screen.dart';
import '../services/ad_manager.dart';

// Providers
final ingredientsProvider = StateProvider<List<String>>((ref) => []);
final isLoadingProvider = StateProvider<bool>((ref) => false);
final recipesProvider = StateProvider<List<Recipe>>((ref) => []);

// Use your valid API key here
const String _googleApiKey = 'AIzaSyCsYrD4almitmT-rpqjBxoIsUzPry4-hJA';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final TextEditingController _controller = TextEditingController();
  final GeminiService _geminiService = GeminiService(_googleApiKey);
  final ImagePicker _picker = ImagePicker();
  final AdManager _adManager = AdManager();

  @override
  void initState() {
    super.initState();
    _adManager.loadRewardedAd(onAdLoaded: () {});
  }

  void _addIngredient(String ingredient) {
    if (ingredient.trim().isEmpty) return;
    final current = ref.read(ingredientsProvider);
    if (!current.contains(ingredient.trim())) {
      ref.read(ingredientsProvider.notifier).state = [...current, ingredient.trim()];
    }
    _controller.clear();
  }

  Future<void> _pickImage(ImageSource source) async {
    final XFile? image = await _picker.pickImage(source: source);
    if (image == null) return;

    ref.read(isLoadingProvider.notifier).state = true;
    try {
      final ingredients = await _geminiService.identifyIngredientsFromImage(File(image.path));
      final current = ref.read(ingredientsProvider);
      ref.read(ingredientsProvider.notifier).state = {
        ...current,
        ...ingredients
      }.toList();
    } catch (e) {
      _showSnack('Oops! Could not scan image: $e');
    } finally {
      ref.read(isLoadingProvider.notifier).state = false;
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: const Color(0xFF2D3047),
      ),
    );
  }

  Future<void> _generateRecipes() async {
    final ingredients = ref.read(ingredientsProvider);
    if (ingredients.isEmpty) {
      _showSnack('Add some ingredients first, machan!');
      return;
    }

    _adManager.showRewardedAd(
      onUserEarnedReward: () async {
        ref.read(isLoadingProvider.notifier).state = true;
        try {
          final recipes = await _geminiService.generateRecipesFromIngredients(ingredients);
          ref.read(recipesProvider.notifier).state = recipes;
          if (recipes.isEmpty) _showSnack('No recipes found. Try adding more ingredients!');
        } catch (e) {
          _showSnack('Generation error: $e');
        } finally {
          ref.read(isLoadingProvider.notifier).state = false;
        }
      },
      onAdClosed: () {},
    );
  }

  @override
  Widget build(BuildContext context) {
    final ingredients = ref.watch(ingredientsProvider);
    final isLoading = ref.watch(isLoadingProvider);
    final recipes = ref.watch(recipesProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F4),
      body: Stack(
        children: [
          // Background Gradient
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 300,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFFFE5D9), Color(0xFFF9F9F4)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          
          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                _buildModernAppBar(),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),
                        _buildMainInputCard(),
                        const SizedBox(height: 16),
                        _buildIngredientChips(ingredients),
                        const SizedBox(height: 32),
                        _buildActionSection(isLoading, ingredients.isNotEmpty),
                        const SizedBox(height: 32),
                        _buildCulinaryTips(),
                        const SizedBox(height: 40),
                        if (recipes.isEmpty && !isLoading) _buildEmptyState(),
                        if (recipes.isNotEmpty) ...[
                          Text(
                            'AI Masterpieces',
                            style: GoogleFonts.outfit(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFF2D3047),
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ],
                    ),
                  ),
                ),
                if (recipes.isNotEmpty) _buildRecipesGrid(recipes, isLoading),
                const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
              ],
            ),
          ),
          
          if (isLoading) _buildLoadingOverlay(),
        ],
      ),
    );
  }

  Widget _buildModernAppBar() {
    return SliverAppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      pinned: true,
      stretch: true,
      expandedHeight: 80,
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: false,
        titlePadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        title: Text(
          'FridgeFeast',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w900,
            color: const Color(0xFFFF6B35),
            fontSize: 28,
          ),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: IconButton(
            onPressed: () {
              ref.read(ingredientsProvider.notifier).state = [];
              ref.read(recipesProvider.notifier).state = [];
            },
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF2D3047)),
          ),
        ),
      ],
    );
  }

  Widget _buildMainInputCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          TextField(
            controller: _controller,
            decoration: InputDecoration(
              hintText: 'What\'s available today?',
              hintStyle: GoogleFonts.outfit(color: Colors.grey.shade400),
              prefixIcon: const Icon(Icons.search, color: Color(0xFFFF6B35)),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            ),
            onSubmitted: _addIngredient,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: _buildInputButton(
                    onTap: () => _pickImage(ImageSource.camera),
                    icon: Icons.camera_alt_rounded,
                    label: 'Scan Fridge',
                    color: const Color(0xFF2D3047),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildInputButton(
                    onTap: () => _pickImage(ImageSource.gallery),
                    icon: Icons.photo_library_rounded,
                    label: 'From Gallery',
                    color: const Color(0xFFFF6B35),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildInputButton({required VoidCallback onTap, required IconData icon, required String label, required Color color}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.outfit(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIngredientChips(List<String> ingredients) {
    if (ingredients.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: ingredients.map((ingredient) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF2D3047),
              borderRadius: BorderRadius.circular(100),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2D3047).withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  ingredient,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: () {
                    ref.read(ingredientsProvider.notifier).state =
                        ingredients.where((i) => i != ingredient).toList();
                  },
                  child: const Icon(Icons.close, size: 16, color: Colors.white70),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildActionSection(bool isLoading, bool hasIngredients) {
    return SizedBox(
      width: double.infinity,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: hasIngredients ? 1.0 : 0.5,
        child: ElevatedButton(
          onPressed: (isLoading || !hasIngredients) ? null : _generateRecipes,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFF6B35),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 20),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.auto_awesome),
              const SizedBox(width: 12),
              Text(
                'Generate Magic Recipes',
                style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 40,
                ),
              ],
            ),
            child: Icon(Icons.restaurant_menu_rounded, size: 80, color: Colors.grey.shade300),
          ),
          const SizedBox(height: 24),
          Text(
            'Your fridge is waiting...',
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add ingredients or scan your fridge\nto unleash AI culinary magic!',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 14,
              color: Colors.grey.shade400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecipesGrid(List<Recipe> recipes, bool isLoading) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final recipe = recipes[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 20.0),
              child: InkWell(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => RecipeDetailScreen(recipe: recipe)),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                        child: Container(
                          height: 160,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFFFF6B35).withOpacity(0.8),
                                const Color(0xFF2D3047),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: const Center(
                            child: Icon(Icons.restaurant_rounded, color: Colors.white, size: 50),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    recipe.title,
                                    style: GoogleFonts.outfit(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF2D3047),
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFF6B35).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    recipe.difficulty,
                                    style: const TextStyle(
                                      color: Color(0xFFFF6B35),
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              recipe.description,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.outfit(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                const Icon(Icons.timer_outlined, size: 16, color: Colors.grey),
                                const SizedBox(width: 4),
                                Text(recipe.prepTime, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                                const Spacer(),
                                Text(
                                  'View Details',
                                  style: GoogleFonts.outfit(
                                    color: const Color(0xFFFF6B35),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                const Icon(Icons.arrow_right_alt, color: Color(0xFFFF6B35)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
          childCount: recipes.length,
        ),
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.white.withOpacity(0.8),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: Color(0xFFFF6B35)),
            const SizedBox(height: 24),
            Text(
              'Cooking up ideas...',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF2D3047),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCulinaryTips() {
    final tips = [
      {'icon': Icons.lightbulb_outline, 'tip': 'Keep herbs fresh by storing them like flowers in a glass of water.'},
      {'icon': Icons.timer_outlined, 'tip': 'Preheat your pan before adding oil for a better non-stick effect.'},
      {'icon': Icons.opacity, 'tip': 'Adding a splash of vinegar to boiling eggs makes them easier to peel.'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Chef\'s Secrets',
          style: GoogleFonts.outfit(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF2D3047),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: tips.length,
            itemBuilder: (context, index) {
              return Container(
                width: 250,
                margin: const EdgeInsets.only(right: 16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(tips[index]['icon'] as IconData, color: const Color(0xFFFF6B35)),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        tips[index]['tip'] as String,
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          color: const Color(0xFF2D3047).withOpacity(0.7),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
