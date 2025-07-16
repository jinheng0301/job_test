class Recipe {
  String id;
  String title;
  String type;
  String imageUrl;
  List<String> ingredients;
  List<String> steps;

  Recipe({
    required this.id,
    required this.title,
    required this.type,
    required this.imageUrl,
    required this.ingredients,
    required this.steps,
  });

  factory Recipe.fromJson(Map<String, dynamic> json) => Recipe(
    id: json['id'],
    title: json['title'],
    type: json['type'],
    imageUrl: json['imageUrl'],
    ingredients: List<String>.from(json['ingredients']),
    steps: List<String>.from(json['steps']),
  );

  factory Recipe.fromMap(String id, Map<String, dynamic> data) {
    return Recipe(
      id: id,
      title: data['title'] ?? '',
      type: data['type'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      ingredients: List<String>.from(data['ingredients'] ?? []),
      steps: List<String>.from(data['steps'] ?? []),
    );
  }

  Map<String, dynamic> toMap() => {
    'title': title,
    'type': type,
    'imageUrl': imageUrl,
    'ingredients': ingredients,
    'steps': steps,
  };

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'type': type,
    'imageUrl': imageUrl,
    'ingredients': ingredients,
    'steps': steps,
  };
}
