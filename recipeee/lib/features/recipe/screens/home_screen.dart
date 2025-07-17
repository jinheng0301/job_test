import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recipeee/common/utils/loader.dart';
import 'package:recipeee/common/utils/utils.dart';
import 'package:recipeee/common/widgets/error.dart';
import 'package:recipeee/features/auth/controller/auth_controller.dart';
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
  Map<String, Uint8List?> imageCache = {}; // Cache for blob images

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

    // Preload images for visible recipes
    _preloadImages();
  }

  void _preloadImages() async {
    final controller = ref.read(recipeControllerProvider);

    for (Recipe recipe in filteredRecipes) {
      if (!recipe.imageUrl.startsWith('http') &&
          !imageCache.containsKey(recipe.imageUrl)) {
        try {
          final imageData = await controller.getRecipeImage(recipe.imageUrl);
          if (mounted) {
            setState(() {
              imageCache[recipe.imageUrl] = imageData;
            });
          }
        } catch (e) {
          print('Error loading image for recipe ${recipe.id}: $e');
          if (mounted) {
            setState(() {
              imageCache[recipe.imageUrl] = null;
            });
          }
        }
      }
    }
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

    // Preload images for visible recipes
    _preloadImages();
  }

  Widget _buildRecipeImage(Recipe recipe) {
    if (recipe.imageUrl.startsWith('http')) {
      // Network image
      return CircleAvatar(
        backgroundImage: NetworkImage(recipe.imageUrl),
        onBackgroundImageError: (error, stackTrace) {
          print('Error loading network image: $error');
        },
      );
    } else {
      // Blob image
      final imageData = imageCache[recipe.imageUrl];

      if (imageData == null) {
        // Still loading or failed to load
        return const CircleAvatar(child: Icon(Icons.image));
      }

      return CircleAvatar(
        backgroundImage: MemoryImage(imageData),
        onBackgroundImageError: (error, stackTrace) {
          print('Error displaying blob image: $error');
        },
      );
    }
  }

  Future<void> _showLogOutDialog() async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Are you sure want to log out?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                try {
                  // Call the sign-out method from the AuthController
                  await ref
                      .read(authControllerProvider)
                      .signOut(context: context);
                } catch (e) {
                  showSnackBar(context, 'Failed to sign out: $e');
                }
              },
              child: Text('Conlan7firm!'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ref
          .watch(userDataAuthProvider)
          .when(
            loading: () => null,
            error: (error, stackTrace) {
              return AppBar(title: const Text('Recipeee'));
            },
            data: (user) {
              return AppBar(
                title: Row(
                  children: [
                    user?.profilePic != null && user!.profilePic.isNotEmpty
                        ? CircleAvatar(
                          radius: 18,
                          backgroundImage: NetworkImage(user.profilePic),
                        )
                        : CircleAvatar(
                          radius: 18,
                          backgroundImage: NetworkImage(
                            'https://www.shutterstock.com/image-vector/donald-trump-president-united-states-260nw-2283642167.jpg',
                          ),
                        ),
                    SizedBox(width: 10),
                    Text('${user?.username}\'s recipe '),
                  ],
                ),
                actions: [
                  PopupMenuButton(
                    onSelected: (value) {
                      _showLogOutDialog();
                    },
                    icon: Icon(Icons.more_vert, color: Colors.greenAccent),
                    itemBuilder: (BuildContext context) {
                      return [
                        PopupMenuItem(value: 'logout', child: Text('Log out')),
                      ];
                    },
                  ),
                ],
              );
            },
          ),

      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () {
          Navigator.pushNamed(context, AddRecipeScreen.routeName);
        },
      ),

      body: ref
          .watch(userDataAuthProvider)
          .when(
            data: (user) {
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: DropdownButton<String>(
                            value: selectedType,
                            hint: const Text("Filter by type"),
                            items: [
                              const DropdownMenuItem(
                                value: null,
                                child: Text("All Types"),
                              ),
                              ...recipeTypes
                                  .map(
                                    (type) => DropdownMenuItem(
                                      value: type,
                                      child: Text(type),
                                    ),
                                  )
                                  .toList(),
                            ],
                            onChanged: filterRecipes,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          '${filteredRecipes.length} recipe${filteredRecipes.length != 1 ? 's' : ''}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child:
                        filteredRecipes.isEmpty
                            ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.restaurant_menu,
                                    size: 64,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No recipes found',
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Add your first recipe to get started!',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                ],
                              ),
                            )
                            : RefreshIndicator(
                              onRefresh: () async {
                                loadData();
                              },
                              child: ListView.builder(
                                itemCount: filteredRecipes.length,
                                itemBuilder: (_, index) {
                                  final recipe = filteredRecipes[index];

                                  return Card(
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    child: ListTile(
                                      leading: _buildRecipeImage(recipe),
                                      title: Text(
                                        recipe.title,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            recipe.type,
                                            style: TextStyle(
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${recipe.ingredients.length} ingredients • ${recipe.steps.length} steps',
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                      trailing: const Icon(
                                        Icons.arrow_forward_ios,
                                      ),
                                      onTap: () async {
                                        // Navigate to recipe detail screen
                                        final result =
                                            await Navigator.pushNamed(
                                              context,
                                              RecipeDetailScreen.routeName,
                                              arguments: recipe,
                                            );

                                        // Refresh the list if recipe was updated/deleted
                                        if (result == true) {
                                          loadData();
                                        }
                                      },
                                    ),
                                  );
                                },
                              ),
                            ),
                  ),
                ],
              );
            },
            loading: () => const Loader(),
            error: (error, stackTrace) => ErrorScreen(error: error.toString()),
          ),
    );
  }
}
