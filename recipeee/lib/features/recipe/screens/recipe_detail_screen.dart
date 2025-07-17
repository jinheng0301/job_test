import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recipeee/common/utils/utils.dart';
import 'package:recipeee/features/recipe/controller/recipe_controller.dart';
import 'package:recipeee/models/recipe.dart';

class RecipeDetailScreen extends ConsumerStatefulWidget {
  static const String routeName = '/recipe-detail-screen';
  final Recipe recipe;

  const RecipeDetailScreen({super.key, required this.recipe});

  @override
  ConsumerState<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends ConsumerState<RecipeDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController titleController;
  late TextEditingController ingredientsController;
  late TextEditingController stepsController;
  File? newImage;
  Uint8List? currentBlobImage;
  String? selectedType;
  List<String> recipeTypes = [];
  bool isEditing = false;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController(text: widget.recipe.title);
    ingredientsController = TextEditingController(
      text: widget.recipe.ingredients.join('\n'),
    );
    stepsController = TextEditingController(
      text: widget.recipe.steps.join('\n'),
    );
    selectedType = widget.recipe.type;

    loadTypes();
    loadCurrentImage();
  }

  Future<void> loadTypes() async {
    final jsonString = await DefaultAssetBundle.of(
      context,
    ).loadString('assets/recipetypes.json');
    final jsonData = jsonDecode(jsonString);
    setState(() {
      recipeTypes = List<String>.from(jsonData['types']);
    });
  }

  Future<void> loadCurrentImage() async {
    if (!widget.recipe.imageUrl.startsWith('http')) {
      try {
        final controller = ref.read(recipeControllerProvider);
        final imageData = await controller.getRecipeImage(
          widget.recipe.imageUrl,
        );
        if (mounted) {
          setState(() {
            currentBlobImage = imageData;
          });
        }
      } catch (e) {
        print('Error loading current image: $e');
      }
    }
  }

  Future<void> updateRecipe() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      isLoading = true;
    });

    try {
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
        ingredients:
            ingredientsController.text
                .trim()
                .split('\n')
                .where((s) => s.isNotEmpty)
                .toList(),
        steps:
            stepsController.text
                .trim()
                .split('\n')
                .where((s) => s.isNotEmpty)
                .toList(),
      );

      await controller.updateRecipe(widget.recipe.id, updatedRecipe);
      if (mounted) {
        showSnackBar(context, 'Recipe updated successfully');
        Navigator.pop(context, true); // Return true to indicate update
      }
    } catch (e) {
      if (mounted) {
        showSnackBar(context, 'Error updating recipe: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> deleteRecipe() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Recipe'),
            content: const Text(
              'Are you sure you want to delete this recipe? This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      setState(() {
        isLoading = true;
      });

      try {
        final controller = ref.read(recipeControllerProvider);
        await controller.deleteRecipe(widget.recipe.id);
        if (mounted) {
          showSnackBar(context, 'Recipe deleted successfully');
          Navigator.pop(context, true); // Return true to indicate deletion
        }
      } catch (e) {
        if (mounted) {
          showSnackBar(context, 'Error deleting recipe: $e');
        }
      } finally {
        if (mounted) {
          setState(() {
            isLoading = false;
          });
        }
      }
    }
  }

  Widget _buildCurrentImage() {
    if (newImage != null) {
      return Image.file(
        newImage!,
        height: 250,
        width: double.infinity,
        fit: BoxFit.cover,
      );
    } else if (widget.recipe.imageUrl.startsWith('http')) {
      return Image.network(
        widget.recipe.imageUrl,
        height: 250,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            height: 250,
            width: double.infinity,
            color: Colors.grey[300],
            child: const Icon(Icons.error, size: 50),
          );
        },
      );
    } else if (currentBlobImage != null) {
      return Image.memory(
        currentBlobImage!,
        height: 250,
        width: double.infinity,
        fit: BoxFit.cover,
      );
    } else {
      return Container(
        height: 250,
        width: double.infinity,
        color: Colors.grey[300],
        child: const Center(child: CircularProgressIndicator()),
      );
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    ingredientsController.dispose();
    stepsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Recipe' : widget.recipe.title),
        actions: [
          if (!isEditing)
            IconButton(
              onPressed: () => setState(() => isEditing = true),
              icon: const Icon(Icons.edit),
            ),
          if (isEditing)
            IconButton(
              onPressed: () => setState(() => isEditing = false),
              icon: const Icon(Icons.close),
            ),
          IconButton(
            onPressed: isLoading ? null : deleteRecipe,
            icon: const Icon(Icons.delete),
          ),
        ],
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: isEditing ? _buildEditForm() : _buildViewMode(),
              ),
    );
  }

  Widget _buildViewMode() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: _buildCurrentImage(),
        ),
        const SizedBox(height: 20),

        // Recipe Type Badge
        Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            'Types: ${widget.recipe.type}',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 16),

        // Recipe Title
        Text(
          widget.recipe.title,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 24),

        // Ingredients Section
        Text(
          'Ingredients',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ...widget.recipe.ingredients.map(
          (ingredient) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Colors.grey,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    ingredient,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Steps Section
        Text(
          'Instructions',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ...widget.recipe.steps.asMap().entries.map((entry) {
          final index = entry.key;
          final step = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    step,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildEditForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: _buildCurrentImage(),
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
            decoration: const InputDecoration(
              labelText: 'Recipe Type',
              border: OutlineInputBorder(),
            ),
            items:
                recipeTypes
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
            onChanged: (value) => setState(() => selectedType = value),
            validator:
                (value) => value == null ? 'Please choose a recipe type' : null,
          ),
          const SizedBox(height: 20),

          TextFormField(
            controller: titleController,
            decoration: const InputDecoration(
              labelText: 'Title',
              border: OutlineInputBorder(),
            ),
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
              border: OutlineInputBorder(),
            ),
            maxLines: 6,
            validator:
                (value) =>
                    value == null || value.isEmpty ? 'Enter ingredients' : null,
          ),
          const SizedBox(height: 20),

          TextFormField(
            controller: stepsController,
            decoration: const InputDecoration(
              labelText: 'Steps (one per line)',
              alignLabelWithHint: true,
              border: OutlineInputBorder(),
            ),
            maxLines: 6,
            validator:
                (value) =>
                    value == null || value.isEmpty ? 'Enter steps' : null,
          ),
          const SizedBox(height: 30),

          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: isLoading ? null : updateRecipe,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    backgroundColor: Colors.green,
                  ),
                  child:
                      isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Update Recipe'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() => isEditing = false),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: const Text('Cancel'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
