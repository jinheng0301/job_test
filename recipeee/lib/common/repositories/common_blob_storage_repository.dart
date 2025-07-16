import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recipeee/common/utils/utils.dart';
import 'package:uuid/uuid.dart';

// Provider for the recipe blob storage repository
final recipeBlobStorageRepositoryProvider = Provider(
  (ref) => RecipeBlobStorageRepository(firestore: FirebaseFirestore.instance),
);

class RecipeBlobStorageRepository {
  final FirebaseFirestore firestore;

  RecipeBlobStorageRepository({required this.firestore});

  // Image size limits for free tier
  static const int maxImageSize = 500 * 1024; // 500KB for recipe images
  static const int firestoreDocLimit = 1048576; // 1MB Firestore document limit

  // Store recipe image as BLOB in Firestore
  Future<String> storeRecipeImage(
    File imageFile,
    String userId,
    BuildContext? context,
  ) async {
    try {
      print('BlobRepository: Processing recipe image: ${imageFile.path}');

      // Check if file exists
      if (!await imageFile.exists()) {
        throw Exception('Image file does not exist');
      }

      final fileSize = await imageFile.length();
      print('BlobRepository: Original file size: $fileSize bytes');

      // Generate a unique ID for this image
      final imageId = const Uuid().v1();

      // Read and compress image if necessary
      Uint8List imageBytes = await imageFile.readAsBytes();
      final originalSize = imageBytes.length;

      // Compress image if it's too large
      if (originalSize > maxImageSize) {
        print('BlobRepository: Compressing image from $originalSize bytes');
        imageBytes = await _compressImage(imageBytes, imageId);
      }

      final finalSize = imageBytes.length;
      print('BlobRepository: Final image size: $finalSize bytes');

      // Check if still too large for Firestore
      if (finalSize > firestoreDocLimit) {
        throw Exception(
          'Image still too large after compression. Please use a smaller image.',
        );
      }

      // Convert to base64 for Firestore storage
      final base64Image = base64Encode(imageBytes);

      // Store in Firestore
      final documentData = {
        'data': base64Image,
        'contentType': 'image/jpeg',
        'createdAt': FieldValue.serverTimestamp(),
        'size': finalSize,
        'originalSize': originalSize,
        'userId': userId,
        'type': 'recipe_image',
      };

      await firestore
          .collection('recipe_images')
          .doc(imageId)
          .set(documentData);

      print('BlobRepository: Recipe image stored with ID: $imageId');
      return imageId;
    } catch (e) {
      print('BlobRepository: Error storing recipe image: $e');
      if (context != null) {
        showSnackBar(context, 'Error storing image: $e');
      }
      rethrow;
    }
  }

  // Retrieve recipe image from Firestore
  Future<Uint8List?> getRecipeImage(String imageId, String userId) async {
    try {
      print('BlobRepository: Retrieving recipe image with ID: $imageId');

      final docSnapshot =
          await firestore.collection('recipe_images').doc(imageId).get();

      if (!docSnapshot.exists || docSnapshot.data() == null) {
        print('BlobRepository: No image found for ID: $imageId');
        return null;
      }

      final data = docSnapshot.data()!;

      // Verify userId matches for security
      if (data['userId'] != userId) {
        print('BlobRepository: User ID mismatch for image access');
        return null;
      }

      // Decode base64 image data
      if (data.containsKey('data')) {
        final base64Data = data['data'] as String;
        return base64Decode(base64Data);
      }

      print('BlobRepository: No valid image data found');
      return null;
    } catch (e) {
      print('BlobRepository: Error retrieving recipe image: $e');
      return null;
    }
  }

  // Delete recipe image from Firestore
  Future<void> deleteRecipeImage(String imageId, String userId) async {
    try {
      print('BlobRepository: Deleting recipe image with ID: $imageId');

      // First verify the image belongs to the user
      final docSnapshot =
          await firestore.collection('recipe_images').doc(imageId).get();

      if (!docSnapshot.exists || docSnapshot.data() == null) {
        print('BlobRepository: Image not found for deletion: $imageId');
        return;
      }

      final data = docSnapshot.data()!;
      if (data['userId'] != userId) {
        print('BlobRepository: User ID mismatch for image deletion');
        return;
      }

      // Delete the document
      await firestore.collection('recipe_images').doc(imageId).delete();

      print('BlobRepository: Recipe image deleted successfully');
    } catch (e) {
      print('BlobRepository: Error deleting recipe image: $e');
      rethrow;
    }
  }

  // Compress image to reduce size
  Future<Uint8List> _compressImage(Uint8List imageBytes, String imageId) async {
    try {
      // Decode image
      final codec = await instantiateImageCodec(
        imageBytes,
        targetWidth: 800,
        targetHeight: 600,
      );
      final frame = await codec.getNextFrame();

      // Convert to PNG with compression
      final byteData = await frame.image.toByteData(
        format: ImageByteFormat.png,
      );

      if (byteData != null) {
        final compressedBytes = byteData.buffer.asUint8List();

        // If still too large, try JPEG with lower quality
        if (compressedBytes.length > maxImageSize) {
          final jpegByteData = await frame.image.toByteData(
            format: ImageByteFormat.rawRgba,
          );
          if (jpegByteData != null) {
            return jpegByteData.buffer.asUint8List();
          }
        }

        return compressedBytes;
      }

      return imageBytes;
    } catch (e) {
      print('BlobRepository: Error compressing image: $e');
      return imageBytes;
    }
  }

  // Get storage statistics for user's recipe images
  Future<Map<String, dynamic>> getStorageStats(String userId) async {
    try {
      final querySnapshot =
          await firestore
              .collection('recipe_images')
              .where('userId', isEqualTo: userId)
              .get();

      int totalImages = querySnapshot.docs.length;
      int totalSize = 0;

      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        if (data.containsKey('size')) {
          totalSize += (data['size'] as int);
        }
      }

      return {
        'totalImages': totalImages,
        'totalSize': totalSize,
        'totalSizeKB': (totalSize / 1024).toStringAsFixed(2),
        'totalSizeMB': (totalSize / (1024 * 1024)).toStringAsFixed(2),
        'maxImageSize': '${(maxImageSize / 1024).toStringAsFixed(0)}KB',
        'firestoreLimit':
            '${(firestoreDocLimit / (1024 * 1024)).toStringAsFixed(1)}MB per document',
      };
    } catch (e) {
      print('BlobRepository: Error getting storage stats: $e');
      return {'error': e.toString()};
    }
  }

  // Clean up orphaned recipe images (images not referenced by any recipe)
  Future<void> cleanupOrphanedImages(String userId) async {
    try {
      print('BlobRepository: Starting cleanup for user: $userId');

      // Get all recipe image IDs for this user
      final imageSnapshot =
          await firestore
              .collection('recipe_images')
              .where('userId', isEqualTo: userId)
              .get();

      Set<String> imageIds = imageSnapshot.docs.map((doc) => doc.id).toSet();

      // Get all recipes for this user to find referenced images
      final recipeSnapshot =
          await firestore
              .collection('recipes')
              .where('userId', isEqualTo: userId)
              .get();

      Set<String> referencedImageIds = {};
      for (var doc in recipeSnapshot.docs) {
        final data = doc.data();
        if (data.containsKey('imageUrl') && data['imageUrl'] != null) {
          // Extract image ID from imageUrl if it's a blob reference
          final imageUrl = data['imageUrl'] as String;
          if (!imageUrl.startsWith('http')) {
            // This is a blob reference, not a URL
            referencedImageIds.add(imageUrl);
          }
        }
      }

      // Find orphaned images
      Set<String> orphanedImages = imageIds.difference(referencedImageIds);

      // Delete orphaned images
      int deletedCount = 0;
      for (String imageId in orphanedImages) {
        try {
          await firestore.collection('recipe_images').doc(imageId).delete();
          deletedCount++;
          print('BlobRepository: Deleted orphaned image: $imageId');
        } catch (e) {
          print('BlobRepository: Error deleting orphaned image: $e');
        }
      }

      print(
        'BlobRepository: Cleanup completed. Deleted $deletedCount orphaned images',
      );
    } catch (e) {
      print('BlobRepository: Error during cleanup: $e');
    }
  }

  // Get image metadata without downloading the full image
  Future<Map<String, dynamic>?> getImageMetadata(
    String imageId,
    String userId,
  ) async {
    try {
      final docSnapshot =
          await firestore.collection('recipe_images').doc(imageId).get();

      if (!docSnapshot.exists || docSnapshot.data() == null) {
        return null;
      }

      final data = docSnapshot.data()!;

      // Verify userId matches
      if (data['userId'] != userId) {
        return null;
      }

      // Return metadata without the actual image data
      return {
        'id': imageId,
        'contentType': data['contentType'],
        'size': data['size'],
        'originalSize': data['originalSize'],
        'createdAt': data['createdAt'],
        'userId': data['userId'],
        'type': data['type'],
      };
    } catch (e) {
      print('BlobRepository: Error getting image metadata: $e');
      return null;
    }
  }
}
