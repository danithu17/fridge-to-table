import 'dart:convert';
import 'dart:io';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/recipe.dart';

class GeminiService {
  final String apiKey;
  late final GenerativeModel _model;
  late final GenerativeModel _visionModel;

  GeminiService(this.apiKey) {
    _model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: apiKey,
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
      ),
    );
    _visionModel = _model; // Both use the same multimodal model
  }

  Future<List<Recipe>> generateRecipesFromIngredients(List<String> ingredients) async {
    final prompt = '''
    Generate 3 creative and delicious recipes based STRICTLY on these ingredients: ${ingredients.join(', ')}.
    You can assume basic pantry staples like salt, pepper, oil, and water are available.
    
    Return the result ONLY as a JSON array of objects with this structure:
    [
      {
        "title": "Recipe Name",
        "description": "Short appetizing description",
        "ingredients": ["item 1", "item 2"],
        "instructions": ["Step 1", "Step 2"],
        "prepTime": "30 mins",
        "difficulty": "Easy/Medium/Hard"
      }
    ]
    ''';

    final content = [Content.text(prompt)];
    final response = await _model.generateContent(content);
    
    if (response.text == null) return [];
    
    final List<dynamic> data = jsonDecode(response.text!);
    return data.map((item) => Recipe.fromJson(item)).toList();
  }

  Future<List<String>> identifyIngredientsFromImage(File imageFile) async {
    final prompt = '''
    List all the food items and ingredients you can see in this fridge or kitchen image. 
    Return ONLY a comma-separated list of ingredients. No other text.
    ''';

    final bytes = await imageFile.readAsBytes();
    final content = [
      Content.multi([
        TextPart(prompt),
        DataPart('image/jpeg', bytes),
      ])
    ];

    final response = await _visionModel.generateContent(content);
    
    if (response.text == null) return [];
    
    return response.text!
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }
}
