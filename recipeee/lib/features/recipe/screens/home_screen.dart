import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recipeee/features/recipe/controller/recipe_controller.dart';
import 'package:recipeee/features/recipe/screens/add_recipe_screen.dart';
import 'package:recipeee/features/recipe/screens/recipe_detail_screen.dart';
import 'package:recipeee/models/recipe.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  List<Recipe> allRecipes = [];
  List<Recipe> filteredRecipes = [];
  String? selectedType;
  List<String> recipeTypes = [];

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    loadData();
  }

  void loadData() async {
    final controller = ref.read(recipeControllerProvider);
    final typesJson = await DefaultAssetBundle.of(
      context,
    ).loadString('assets/recipetypes.json');
    final decoded = Map<String, dynamic>.from(await jsonDecode(typesJson));
    setState(() {
      recipeTypes = List<String>.from(decoded['types']);
    });

    final recipes = await controller.fetchRecipes();
    setState(() {
      allRecipes = recipes;
      filteredRecipes = recipes;
    });
  }

  void filterRecipes(String? type) {
    setState(() {
      selectedType = type;
      if (type == null || type.isEmpty) {
        filteredRecipes = allRecipes;
      } else {
        filteredRecipes = allRecipes.where((r) => r.type == type).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Recipes")),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddRecipeScreen()),
          );
        },
      ),
      body: Column(
        children: [
          DropdownButton<String>(
            value: selectedType,
            hint: const Text("Filter by type"),
            items:
                recipeTypes
                    .map(
                      (type) =>
                          DropdownMenuItem(value: type, child: Text(type)),
                    )
                    .toList(),
            onChanged: filterRecipes,
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filteredRecipes.length,
              itemBuilder: (_, index) {
                final recipe = filteredRecipes[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: NetworkImage(recipe.imageUrl),
                  ),
                  title: Text(recipe.title),
                  subtitle: Text(recipe.type),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RecipeDetailScreen(recipe: recipe),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
