import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recipeee/common/utils/loader.dart';
import 'package:recipeee/features/recipe/controller/recipe_controller.dart';

// Provider for caching blob images
final blobImageProvider = FutureProvider.family<Uint8List?, String>((
  ref,
  imageId,
) async {
  final controller = ref.watch(recipeControllerProvider);
  return await controller.getRecipeImage(imageId);
});

class BlobImageWidget extends ConsumerWidget {
  final String imageId;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final BorderRadius? borderRadius;

  const BlobImageWidget({
    super.key,
    required this.imageId,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Check if imageId is a URL (fallback to network image)
    if (imageId.startsWith('http')) {
      return ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.zero,
        child: Image.network(
          imageId,
          width: width,
          height: height,
          fit: fit,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return _buildPlaceholder(context);
          },
          errorBuilder: (context, error, stackTrace) {
            return _buildErrorWidget(context);
          },
        ),
      );
    }

    // Use blob image provider for blob storage
    final imageAsyncValue = ref.watch(blobImageProvider(imageId));

    return imageAsyncValue.when(
      data: (imageData) {
        if (imageData == null) {
          return _buildErrorWidget(context);
        }

        return ClipRRect(
          borderRadius: borderRadius ?? BorderRadius.zero,
          child: Image.memory(
            imageData,
            width: width,
            height: height,
            fit: fit,
            errorBuilder: (context, error, stackTrace) {
              return _buildErrorWidget(context);
            },
          ),
        );
      },
      loading: () => _buildPlaceholder(context),
      error: (error, stackTrace) => _buildErrorWidget(context),
    );
  }

  Widget _buildPlaceholder(BuildContext context) {
    return placeholder ??
        Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: borderRadius,
          ),
          child: const Center(child: Loader()),
        );
  }

  Widget _buildErrorWidget(BuildContext context) {
    return errorWidget ??
        Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: borderRadius,
          ),
          child: const Center(
            child: Icon(Icons.error, color: Colors.red, size: 30),
          ),
        );
  }
}

// Specialized widget for recipe list items
class RecipeListImageWidget extends ConsumerWidget {
  final String imageId;
  final double size;

  const RecipeListImageWidget({
    super.key,
    required this.imageId,
    this.size = 50.0,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return BlobImageWidget(
      imageId: imageId,
      width: size,
      height: size,
      fit: BoxFit.cover,
      borderRadius: BorderRadius.circular(size / 2),
      placeholder: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.restaurant, color: Colors.grey),
      ),
      errorWidget: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.restaurant, color: Colors.grey),
      ),
    );
  }
}

// Specialized widget for recipe detail screens
class RecipeDetailImageWidget extends ConsumerWidget {
  final String imageId;
  final double height;

  const RecipeDetailImageWidget({
    super.key,
    required this.imageId,
    this.height = 200.0,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return BlobImageWidget(
      imageId: imageId,
      width: double.infinity,
      height: height,
      fit: BoxFit.cover,
      borderRadius: BorderRadius.circular(8.0),
      placeholder: Container(
        width: double.infinity,
        height: height,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 10),
            Text('Loading image...'),
          ],
        ),
      ),
      errorWidget: Container(
        width: double.infinity,
        height: height,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error, color: Colors.red, size: 50),
            SizedBox(height: 10),
            Text('Failed to load image'),
          ],
        ),
      ),
    );
  }
}
