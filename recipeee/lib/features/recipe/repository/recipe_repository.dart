import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:recipeee/models/recipe.dart';

class RecipeRepository {
  final FirebaseFirestore firestore;
  final FirebaseStorage storage;

  RecipeRepository({required this.firestore, required this.storage});

  CollectionReference get _recipes => firestore.collection('recipes');

  Future<void> addRecipe(Recipe recipe) async {
    await _recipes.add(recipe.toMap());
  }

  Future<void> updateRecipe(String id, Recipe recipe) async {
    await _recipes.doc(id).update(recipe.toMap());
  }

  Future<void> deleteRecipe(String id) async {
    await _recipes.doc(id).delete();
  }

  Future<List<Recipe>> fetchRecipes() async {
    final snapshot = await _recipes.get();
    return snapshot.docs
        .map(
          (doc) => Recipe.fromMap(doc.id, doc.data() as Map<String, dynamic>),
        )
        .toList();
  }

  Future<String> uploadImage(File file) async {
    final ref = storage.ref().child(
      'recipes/${DateTime.now().millisecondsSinceEpoch}.jpg',
    );
    await ref.putFile(file);
    return await ref.getDownloadURL();
  }
}
