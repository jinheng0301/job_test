import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recipeee/common/repositories/common_blob_storage_repository.dart';
import 'package:recipeee/models/recipe.dart';

final recipeRepositoryProvider = Provider((ref) {
  return RecipeRepository(
    firestore: FirebaseFirestore.instance,
    auth: FirebaseAuth.instance,
    blobRepository: ref.watch(recipeBlobStorageRepositoryProvider),
  );
});

class RecipeRepository {
  final FirebaseFirestore firestore;
  final FirebaseAuth auth;
  final RecipeBlobStorageRepository blobRepository;

  RecipeRepository({
    required this.firestore,
    required this.auth,
    required this.blobRepository,
  });

  CollectionReference get _recipes => firestore.collection('recipes');
  String? get _currentUserId => auth.currentUser?.uid;

  // Add a new recipe
  Future<void> addRecipe(Recipe recipe) async {
    if (_currentUserId == null) {
      throw Exception('User not authenticated');
    }

    // Add userId to recipe data
    final recipeData = recipe.toMap();
    recipeData['userId'] = _currentUserId;
    recipeData['createdAt'] = FieldValue.serverTimestamp();
    recipeData['updatedAt'] = FieldValue.serverTimestamp();

    await _recipes.add(recipeData);
  }

  // Update an existing recipe
  Future<void> updateRecipe(String id, Recipe recipe) async {
    if (_currentUserId == null) {
      throw Exception('User not authenticated');
    }

    // Verify recipe belongs to current user
    final docSnapshot = await _recipes.doc(id).get();
    if (!docSnapshot.exists) {
      throw Exception('Recipe not found');
    }

    final data = docSnapshot.data() as Map<String, dynamic>;
    if (data['userId'] != _currentUserId) {
      throw Exception('Not authorized to update this recipe');
    }

    // Update recipe data
    final recipeData = recipe.toMap();
    recipeData['userId'] = _currentUserId;
    recipeData['updatedAt'] = FieldValue.serverTimestamp();

    await _recipes.doc(id).update(recipeData);
  }

  // Delete a recipe
  Future<void> deleteRecipe(String id) async {
    if (_currentUserId == null) {
      throw Exception('User not authenticated');
    }

    // Verify recipe belongs to current user
    final docSnapshot = await _recipes.doc(id).get();
    if (!docSnapshot.exists) {
      throw Exception('Recipe not found');
    }

    final data = docSnapshot.data() as Map<String, dynamic>;
    if (data['userId'] != _currentUserId) {
      throw Exception('Not authorized to delete this recipe');
    }

    // Delete associated image from blob storage if it exists
    if (data.containsKey('imageUrl') && data['imageUrl'] != null) {
      final imageUrl = data['imageUrl'] as String;
      if (!imageUrl.startsWith('http')) {
        // This is a blob reference, delete it
        try {
          await blobRepository.deleteRecipeImage(imageUrl, _currentUserId!);
        } catch (e) {
          print('Error deleting recipe image: $e');
          // Continue with recipe deletion even if image deletion fails
        }
      }
    }

    await _recipes.doc(id).delete();
  }

  // Fetch all recipes for current user
  Future<List<Recipe>> fetchRecipes() async {
    if (_currentUserId == null) {
      throw Exception('User not authenticated');
    }

    final snapshot =
        await _recipes
            .where('userId', isEqualTo: _currentUserId)
            .orderBy('createdAt', descending: true)
            .get();

    return snapshot.docs
        .map(
          (doc) => Recipe.fromMap(doc.id, doc.data() as Map<String, dynamic>),
        )
        .toList();
  }

  // Upload image and return image ID
  Future<String> uploadImage(File file) async {
    if (_currentUserId == null) {
      throw Exception('User not authenticated');
    }

    return await blobRepository.storeRecipeImage(file, _currentUserId!, null);
  }

  // Get image data from blob storage
  Future<Uint8List?> getRecipeImage(String imageId) async {
    if (_currentUserId == null) {
      throw Exception('User not authenticated');
    }

    return await blobRepository.getRecipeImage(imageId, _currentUserId!);
  }

  // Get image metadata
  Future<Map<String, dynamic>?> getImageMetadata(String imageId) async {
    if (_currentUserId == null) {
      throw Exception('User not authenticated');
    }

    return await blobRepository.getImageMetadata(imageId, _currentUserId!);
  }

  // Get storage statistics
  Future<Map<String, dynamic>> getStorageStats() async {
    if (_currentUserId == null) {
      throw Exception('User not authenticated');
    }

    return await blobRepository.getStorageStats(_currentUserId!);
  }

  // Clean up orphaned images
  Future<void> cleanupOrphanedImages() async {
    if (_currentUserId == null) {
      throw Exception('User not authenticated');
    }

    await blobRepository.cleanupOrphanedImages(_currentUserId!);
  }

  // Stream recipes for real-time updates
  Stream<List<Recipe>> streamRecipes() {
    if (_currentUserId == null) {
      throw Exception('User not authenticated');
    }

    return _recipes
        .where('userId', isEqualTo: _currentUserId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map(
                    (doc) => Recipe.fromMap(
                      doc.id,
                      doc.data() as Map<String, dynamic>,
                    ),
                  )
                  .toList(),
        );
  }

  // Get recipe by ID
  Future<Recipe?> getRecipeById(String id) async {
    if (_currentUserId == null) {
      throw Exception('User not authenticated');
    }

    final docSnapshot = await _recipes.doc(id).get();
    if (!docSnapshot.exists) {
      return null;
    }

    final data = docSnapshot.data() as Map<String, dynamic>;
    if (data['userId'] != _currentUserId) {
      throw Exception('Not authorized to access this recipe');
    }

    return Recipe.fromMap(id, data);
  }

  // Search recipes by title or type
  Future<List<Recipe>> searchRecipes(String query) async {
    if (_currentUserId == null) {
      throw Exception('User not authenticated');
    }

    final snapshot =
        await _recipes.where('userId', isEqualTo: _currentUserId).get();

    return snapshot.docs
        .map(
          (doc) => Recipe.fromMap(doc.id, doc.data() as Map<String, dynamic>),
        )
        .where(
          (recipe) =>
              recipe.title.toLowerCase().contains(query.toLowerCase()) ||
              recipe.type.toLowerCase().contains(query.toLowerCase()),
        )
        .toList();
  }
}
