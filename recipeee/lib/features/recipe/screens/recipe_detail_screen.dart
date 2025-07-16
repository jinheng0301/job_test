import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recipeee/common/utils/utils.dart';
import 'package:recipeee/features/recipe/controller/recipe_controller.dart';
import 'package:recipeee/models/recipe.dart';

class RecipeDetailScreen extends ConsumerStatefulWidget {
  static const String routeName = '/recipe-detail-screen';
  final Recipe recipe;

  RecipeDetailScreen({required this.recipe});

  @override
  ConsumerState<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends ConsumerState<RecipeDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController titleController;
  late TextEditingController ingredientsController;
  late TextEditingController stepsController;
  File? newImage;
  String? selectedType;
  List<String> recipeTypes = [];

  Future<void> loadTypes() async {
    final jsonString = await DefaultAssetBundle.of(
      context,
    ).loadString('assets/recipetypes.json');
    final jsonData = jsonDecode(jsonString);
    setState(() {
      recipeTypes = List<String>.from(jsonData['types']);
    });
  }

  Future<void> updateRecipe() async {
    try {
      if (_formKey.currentState!.validate()) {
        final controller = ref.read(recipeControllerProvider);
        String imageUrl = widget.recipe.imageUrl;

        if (newImage != null) {
          imageUrl = await controller.uploadImage(newImage!);
        }

        final updatedRecipe = Recipe(
          id: widget.recipe.id,
          title: titleController.text.trim(),
          type: selectedType!,
          imageUrl: imageUrl,
          ingredients: ingredientsController.text.trim().split('\n'),
          steps: stepsController.text.trim().split('\n'),
        );

        await controller.updateRecipe(widget.recipe.id, updatedRecipe);
        showSnackBar(context, 'Recipe updated');
        Navigator.pop(context);
      }
    } catch (e) {
      showSnackBar(context, 'Error updating recipe: $e');
    }
  }

  Future<void> deleteRecipe() async {
    try {
      final controller = ref.read(recipeControllerProvider);
      await controller.deleteRecipe(widget.recipe.id);
      showSnackBar(context, 'Recipe deleted');
      Navigator.pop(context);
    } catch (e) {
      showSnackBar(context, 'Error deleting recipe: $e');
    }
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    titleController.dispose();
    ingredientsController.dispose();
    stepsController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.recipe.title),
        actions: [
          IconButton(onPressed: deleteRecipe, icon: const Icon(Icons.delete)),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              newImage != null
                  ? Image.file(
                    newImage!,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  )
                  : Image.network(
                    widget.recipe.imageUrl,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: () async {
                  final image = await pickImageFromGallery(context);
                  if (image != null) {
                    setState(() {
                      newImage = image;
                    });
                  }
                },
                icon: const Icon(Icons.image),
                label: const Text('Change Image'),
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: selectedType,
                decoration: const InputDecoration(labelText: 'Recipe Type'),
                items:
                    recipeTypes
                        .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                        .toList(),
                onChanged: (value) => setState(() => selectedType = value),
                validator:
                    (value) =>
                        value == null ? 'Please choose a recipe type' : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Title'),
                validator:
                    (value) =>
                        value == null || value.isEmpty ? 'Enter title' : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: ingredientsController,
                decoration: const InputDecoration(
                  labelText: 'Ingredients (one per line)',
                  alignLabelWithHint: true,
                ),
                maxLines: 4,
                validator:
                    (value) =>
                        value == null || value.isEmpty
                            ? 'Enter ingredients'
                            : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: stepsController,
                decoration: const InputDecoration(
                  labelText: 'Steps (one per line)',
                  alignLabelWithHint: true,
                ),
                maxLines: 4,
                validator:
                    (value) =>
                        value == null || value.isEmpty ? 'Enter steps' : null,
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: updateRecipe,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: Colors.green,
                ),
                child: const Text('Update Recipe'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
