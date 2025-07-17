import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recipeee/common/utils/color.dart';
import 'package:recipeee/common/utils/utils.dart';
import 'package:recipeee/features/recipe/controller/recipe_controller.dart';
import 'package:recipeee/models/recipe.dart';

class AddRecipeScreen extends ConsumerStatefulWidget {
  static const String routeName = '/add-recipe-screen';
  const AddRecipeScreen({super.key});

  @override
  ConsumerState<AddRecipeScreen> createState() => _AddRecipeScreenState();
}

class _AddRecipeScreenState extends ConsumerState<AddRecipeScreen> {
  final _formKey = GlobalKey<FormState>();

  final titleController = TextEditingController();
  final ingredientsController = TextEditingController();
  final stepsController = TextEditingController();

  List<String> recipeTypes = [];
  String? selectedType;
  File? selectedImage;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    loadRecipeTypes();
  }

  Future<void> loadRecipeTypes() async {
    final jsonString = await DefaultAssetBundle.of(
      context,
    ).loadString('assets/recipetypes.json');
    final jsonData = jsonDecode(jsonString);
    setState(() {
      recipeTypes = List<String>.from(jsonData['types']);
    });
  }

  void submitRecipe() async {
    if (_formKey.currentState!.validate() &&
        selectedImage != null &&
        selectedType != null) {
      final controller = ref.read(recipeControllerProvider);
      final imageUrl = await controller.uploadImage(selectedImage!);

      final recipe = Recipe(
        id: '',
        title: titleController.text.trim(),
        type: selectedType!,
        imageUrl: imageUrl,
        ingredients: ingredientsController.text.trim().split('\n'),
        steps: stepsController.text.trim().split('\n'),
      );

      await controller.addRecipe(recipe);
      showSnackBar(context, 'Recipe added successfully!');
      Navigator.pop(context);
    } else {
      showSnackBar(context, 'Please complete all fields and select an image.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Recipe'),
        backgroundColor: appBarColor,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                selectedImage != null
                    ? Image.file(
                      selectedImage!,
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    )
                    : SizedBox(
                      height: 180,
                      width: double.infinity,
                      child: const Center(child: Text('No Image Selected')),
                    ),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  onPressed: () async {
                    final image = await pickImageFromGallery(context);
                    if (image != null) {
                      setState(() {
                        selectedImage = image;
                      });
                    }
                  },
                  icon: const Icon(Icons.image),
                  label: const Text('Choose Image'),
                ),
                const SizedBox(height: 20),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Select Recipe Type',
                  ),
                  value: selectedType,
                  items:
                      recipeTypes
                          .map(
                            (type) => DropdownMenuItem(
                              value: type,
                              child: Text(type),
                            ),
                          )
                          .toList(),
                  onChanged: (value) => setState(() => selectedType = value),
                  validator:
                      (value) =>
                          value == null ? 'Please select a recipe type' : null,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Recipe Title'),
                  validator:
                      (value) =>
                          value == null || value.isEmpty
                              ? 'Enter recipe title'
                              : null,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: ingredientsController,
                  decoration: const InputDecoration(
                    labelText: 'Ingredients (one per line)',
                    alignLabelWithHint: true,
                  ),
                  keyboardType: TextInputType.multiline,
                  maxLines: 5,
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
                  keyboardType: TextInputType.multiline,
                  maxLines: 5,
                  validator:
                      (value) =>
                          value == null || value.isEmpty ? 'Enter steps' : null,
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: submitRecipe,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    backgroundColor: Colors.blue,
                  ),
                  child: const Text(
                    'Save Recipe',
                    style: TextStyle(
                      color: Colors.amber,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
