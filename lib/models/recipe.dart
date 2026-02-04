class Recipe {
  final String title;
  final String description;
  final List<String> ingredients;
  final List<String> instructions;
  final String prepTime;
  final String difficulty;
  final String imageUrl;

  Recipe({
    required this.title,
    required this.description,
    required this.ingredients,
    required this.instructions,
    required this.prepTime,
    required this.difficulty,
    this.imageUrl = '',
  });

  factory Recipe.fromJson(Map<String, dynamic> json) {
    return Recipe(
      title: json['title'] ?? 'Unknown Recipe',
      description: json['description'] ?? '',
      ingredients: List<String>.from(json['ingredients'] ?? []),
      instructions: List<String>.from(json['instructions'] ?? []),
      prepTime: json['prepTime'] ?? '20 mins',
      difficulty: json['difficulty'] ?? 'Medium',
      imageUrl: json['imageUrl'] ?? '',
    );
  }
}
