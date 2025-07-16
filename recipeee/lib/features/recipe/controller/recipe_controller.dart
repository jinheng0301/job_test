import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recipeee/features/recipe/repository/recipe_repository.dart';
import 'package:recipeee/models/recipe.dart';

final recipeControllerProvider = Provider((ref) {
  final repo = RecipeRepository(
    firestore: FirebaseFirestore.instance,
    storage: FirebaseStorage.instance,
  );
  return RecipeController(repo: repo);
});

class RecipeController {
  final RecipeRepository repo;

  RecipeController({required this.repo});

  Future<void> addRecipe(Recipe recipe) => repo.addRecipe(recipe);
  Future<void> updateRecipe(String id, Recipe recipe) =>
      repo.updateRecipe(id, recipe);
  Future<void> deleteRecipe(String id) => repo.deleteRecipe(id);
  Future<List<Recipe>> fetchRecipes() => repo.fetchRecipes();
  Future<String> uploadImage(File file) => repo.uploadImage(file);
}
