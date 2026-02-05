import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../services/gemini_service.dart';
import '../models/recipe.dart';
import 'recipe_detail_screen.dart';

// Providers
final ingredientsProvider = StateProvider<List<String>>((ref) => []);
final isLoadingProvider = StateProvider<bool>((ref) => false);
final recipesProvider = StateProvider<List<Recipe>>((ref) => []);

// Note: In a real app, use a secure way to store API key
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error identifying ingredients: $e')),
      );
    } finally {
      ref.read(isLoadingProvider.notifier).state = false;
    }
  }

  Future<void> _generateRecipes() async {
    final ingredients = ref.read(ingredientsProvider);
    if (ingredients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add some ingredients first!')),
      );
      return;
    }

    ref.read(isLoadingProvider.notifier).state = true;
    try {
      final recipes = await _geminiService.generateRecipesFromIngredients(ingredients);
      ref.read(recipesProvider.notifier).state = recipes;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error generating recipes: $e')),
      );
    } finally {
      ref.read(isLoadingProvider.notifier).state = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ingredients = ref.watch(ingredientsProvider);
    final isLoading = ref.watch(isLoadingProvider);
    final recipes = ref.watch(recipesProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInputSection(),
                  const SizedBox(height: 24),
                  if (ingredients.isNotEmpty) _buildIngredientsList(ingredients),
                  const SizedBox(height: 32),
                  _buildGenerateButton(isLoading),
                  const SizedBox(height: 32),
                  if (recipes.isNotEmpty) ...[
                    Text(
                      'Suggested Recipes',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF2D3047),
                          ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ],
              ),
            ),
          ),
          if (recipes.isNotEmpty) _buildRecipesList(recipes),
          const SliverPadding(padding: EdgeInsets.only(bottom: 40)),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        title: Text(
          'FridgeFeast',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            color: const Color(0xFFFF6B35),
            fontSize: 24,
          ),
        ),
      ),
      actions: [
        IconButton(
          onPressed: () => ref.read(ingredientsProvider.notifier).state = [],
          icon: const Icon(Icons.refresh, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildInputSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'What\'s in your fridge?',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: const Color(0xFF2D3047),
              ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                decoration: InputDecoration(
                  hintText: 'Add ingredient (e.g. Tomato)',
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
                onSubmitted: _addIngredient,
              ),
            ),
            const SizedBox(width: 12),
            _buildIconButton(
              icon: Icons.camera_alt_outlined,
              onPressed: () => _pickImage(ImageSource.camera),
            ),
            const SizedBox(width: 8),
            _buildIconButton(
              icon: Icons.image_outlined,
              onPressed: () => _pickImage(ImageSource.gallery),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildIconButton({required IconData icon, required VoidCallback onPressed}) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFF6B35).withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: IconButton(
        icon: Icon(icon, color: const Color(0xFFFF6B35)),
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildIngredientsList(List<String> ingredients) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: ingredients.map((ingredient) {
        return Chip(
          label: Text(ingredient),
          onDeleted: () {
            ref.read(ingredientsProvider.notifier).state =
                ingredients.where((i) => i != ingredient).toList();
          },
          deleteIcon: const Icon(Icons.close, size: 16),
          backgroundColor: Colors.white,
          side: BorderSide(color: Colors.grey.shade200),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        );
      }).toList(),
    );
  }

  Widget _buildGenerateButton(bool isLoading) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isLoading ? null : _generateRecipes,
        child: isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              )
            : const Text(
                'Generate Creative Recipes',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }

  Widget _buildRecipesList(List<Recipe> recipes) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final recipe = recipes[index];
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: InkWell(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => RecipeDetailScreen(recipe: recipe),
                ),
              ),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF7C59F).withOpacity(0.3),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.restaurant, color: Color(0xFFFF6B35), size: 32),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              recipe.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: Color(0xFF2D3047),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              recipe.description,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                _recipeTag(Icons.timer_outlined, recipe.prepTime),
                                const SizedBox(width: 12),
                                _recipeTag(Icons.bolt, recipe.difficulty),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
        childCount: recipes.length,
      ),
    );
  }

  Widget _recipeTag(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 14, color: const Color(0xFFFF6B35)),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
