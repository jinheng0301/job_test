import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recipeee/features/recipe/repository/recipe_repository.dart';
import 'package:recipeee/models/recipe.dart';

final recipeControllerProvider = Provider((ref) {
  final repository = ref.watch(recipeRepositoryProvider);
  return RecipeController(repository: repository);
});

// Stream provider for real-time recipe updates
final recipesStreamProvider = StreamProvider<List<Recipe>>((ref) {
  final repository = ref.watch(recipeRepositoryProvider);
  return repository.streamRecipes();
});

// Future provider for loading recipes
final recipesFutureProvider = FutureProvider<List<Recipe>>((ref) {
  final repository = ref.watch(recipeRepositoryProvider);
  return repository.fetchRecipes();
});

// Provider for storage statistics
final storageStatsProvider = FutureProvider<Map<String, dynamic>>((ref) {
  final repository = ref.watch(recipeRepositoryProvider);
  return repository.getStorageStats();
});

class RecipeController {
  final RecipeRepository repository;

  RecipeController({required this.repository});

  // Add a new recipe
  Future<void> addRecipe(Recipe recipe) async {
    try {
      await repository.addRecipe(recipe);
    } catch (e) {
      print('RecipeController: Error adding recipe: $e');
      rethrow;
    }
  }

  // Update an existing recipe
  Future<void> updateRecipe(String id, Recipe recipe) async {
    try {
      await repository.updateRecipe(id, recipe);
    } catch (e) {
      print('RecipeController: Error updating recipe: $e');
      rethrow;
    }
  }

  // Delete a recipe
  Future<void> deleteRecipe(String id) async {
    try {
      await repository.deleteRecipe(id);
    } catch (e) {
      print('RecipeController: Error deleting recipe: $e');
      rethrow;
    }
  }

  // Fetch all recipes
  Future<List<Recipe>> fetchRecipes() async {
    try {
      return await repository.fetchRecipes();
    } catch (e) {
      print('RecipeController: Error fetching recipes: $e');
      rethrow;
    }
  }

  // Upload image and return image ID
  Future<String> uploadImage(File file) async {
    try {
      return await repository.uploadImage(file);
    } catch (e) {
      print('RecipeController: Error uploading image: $e');
      rethrow;
    }
  }

  // Get recipe image data
  Future<Uint8List?> getRecipeImage(String imageId) async {
    try {
      return await repository.getRecipeImage(imageId);
    } catch (e) {
      print('RecipeController: Error getting recipe image: $e');
      return null;
    }
  }

  // Get image metadata
  Future<Map<String, dynamic>?> getImageMetadata(String imageId) async {
    try {
      return await repository.getImageMetadata(imageId);
    } catch (e) {
      print('RecipeController: Error getting image metadata: $e');
      return null;
    }
  }

  // Get storage statistics
  Future<Map<String, dynamic>> getStorageStats() async {
    try {
      return await repository.getStorageStats();
    } catch (e) {
      print('RecipeController: Error getting storage stats: $e');
      return {'error': e.toString()};
    }
  }

  // Clean up orphaned images
  Future<void> cleanupOrphanedImages() async {
    try {
      await repository.cleanupOrphanedImages();
    } catch (e) {
      print('RecipeController: Error cleaning up orphaned images: $e');
    }
  }

  // Get recipe by ID
  Future<Recipe?> getRecipeById(String id) async {
    try {
      return await repository.getRecipeById(id);
    } catch (e) {
      print('RecipeController: Error getting recipe by ID: $e');
      return null;
    }
  }

  // Search recipes
  Future<List<Recipe>> searchRecipes(String query) async {
    try {
      return await repository.searchRecipes(query);
    } catch (e) {
      print('RecipeController: Error searching recipes: $e');
      return [];
    }
  }
}
