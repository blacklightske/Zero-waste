import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'api_service.dart';
import 'dart:async';

class ImageUploadService {
  static final ImagePicker _picker = ImagePicker();
  static final ApiService _apiService = ApiService();
  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  
  // Stream controllers for tracking upload progress
  static final StreamController<double> _uploadProgressController = StreamController<double>.broadcast();
  static Stream<double> get uploadProgress => _uploadProgressController.stream;

  // Pick image from camera or gallery
  static Future<File?> pickImage({ImageSource source = ImageSource.gallery}) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      
      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      debugPrint('Error picking image: $e');
      return null;
    }
  }

  // Pick multiple images
  static Future<List<File>> pickMultipleImages({int maxImages = 5}) async {
    try {
      final List<XFile> images = await _picker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      
      if (images.length > maxImages) {
        return images.take(maxImages).map((image) => File(image.path)).toList();
      }
      
      return images.map((image) => File(image.path)).toList();
    } catch (e) {
      debugPrint('Error picking multiple images: $e');
      return [];
    }
  }

  // Upload single image to product
  static Future<Map<String, dynamic>?> uploadProductImage(String productId, File imageFile, {bool isPrimary = false}) async {
    try {
      String fileName = imageFile.path.split('/').last;
      FormData formData = FormData.fromMap({
        'product': productId,
        'is_primary': isPrimary,
        'image': await MultipartFile.fromFile(imageFile.path, filename: fileName),
      });

      // Create a custom Dio instance with onSendProgress callback
    final dio = Dio();
    dio.options = _apiService.getDioOptions();
    
    // Add auth token to headers
    final token = await _storage.read(key: 'auth_token');
    if (token != null) {
      dio.options.headers['Authorization'] = 'Bearer $token';
    }
      
      final response = await dio.post(
        '${ApiService.baseUrl}/marketplace/images/',
        data: formData,
        onSendProgress: (sent, total) {
          if (total != -1) {
            final progress = sent / total;
            _uploadProgressController.add(progress);
            debugPrint('Upload progress: ${(progress * 100).toStringAsFixed(2)}%');
          }
        },
      );
      
      // Reset progress when complete
      _uploadProgressController.add(1.0);
      
      // Return both the image URL and cloudinary URL if available
      return {
        'image': response.data['image'],
        'cloudinary_url': response.data['cloudinary_url'] ?? response.data['image'],
        'id': response.data['id'],
      };
    } catch (e) {
      debugPrint('Error uploading image: $e');
      _uploadProgressController.add(0.0); // Reset progress on error
      return null;
    }
  }

  // Upload multiple images for a product
  static Future<List<Map<String, dynamic>>> uploadProductImages(String productId, List<File> imageFiles) async {
    List<Map<String, dynamic>> uploadedImages = [];
    final totalImages = imageFiles.length;
    
    // Initialize progress
    _uploadProgressController.add(0.0);
    
    try {
      for (int i = 0; i < imageFiles.length; i++) {
        // Update overall progress (considering both current image and position in queue)
        final baseProgress = i / totalImages;
        _uploadProgressController.add(baseProgress);
        
        // Create a custom progress handler for this specific image
        void onProgress(int sent, int total) {
          if (total != -1) {
            // Calculate progress for current image (0-1 range)
            final imageProgress = sent / total;
            
            // Calculate overall progress: base progress + (image progress * segment size)
            // where segment size is 1/totalImages
            final overallProgress = baseProgress + (imageProgress / totalImages);
            
            // Update the progress stream
            _uploadProgressController.add(overallProgress);
            debugPrint('Upload progress: ${(overallProgress * 100).toStringAsFixed(2)}%');
          }
        }
        
        // Upload the image with progress tracking
        final imageData = await uploadProductImage(
          productId,
          imageFiles[i],
          isPrimary: i == 0, // First image is primary
        );
        
        // Wait for the Cloudinary link to be available
        if (imageData != null) {
          uploadedImages.add(imageData);
          debugPrint('Image ${i+1}/${totalImages} uploaded successfully: ${imageData['cloudinary_url']}');
        } else {
          debugPrint('Failed to upload image ${i+1}/${totalImages}');
        }
      }
    } catch (e) {
      debugPrint('Error during multiple image upload: $e');
    } finally {
      // Complete progress
      _uploadProgressController.add(1.0);
    }
    
    return uploadedImages;
  }

  // Delete product image
  static Future<bool> deleteProductImage(String imageId) async {
    try {
      await _apiService.delete('/marketplace/images/$imageId/');
      return true;
    } catch (e) {
      debugPrint('Error deleting image: $e');
      return false;
    }
  }

  // Upload user avatar
  static Future<Map<String, dynamic>?> uploadUserAvatar(File imageFile) async {
    try {
      String fileName = imageFile.path.split('/').last;
      FormData formData = FormData.fromMap({
        'avatar': await MultipartFile.fromFile(imageFile.path, filename: fileName),
      });

      final response = await _apiService.put('/marketplace/profiles/me/', formData);
      return {
        'avatar': response['avatar'],
        'avatar_cloudinary_url': response['avatar_cloudinary_url'] ?? response['avatar'],
      };
    } catch (e) {
      debugPrint('Error uploading avatar: $e');
      return null;
    }
  }

  // Show image source selection dialog
  static Future<File?> showImageSourceDialog(BuildContext context) async {
    return await showDialog<File?>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Image Source'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Camera'),
                onTap: () async {
                  Navigator.pop(context);
                  final image = await pickImage(source: ImageSource.camera);
                  if (context.mounted) {
                    Navigator.pop(context, image);
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                onTap: () async {
                  Navigator.pop(context);
                  final image = await pickImage(source: ImageSource.gallery);
                  if (context.mounted) {
                    Navigator.pop(context, image);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  // Show multiple image picker with options
  static Future<List<File>?> showMultipleImagePicker(BuildContext context, {int maxImages = 5}) async {
    return await showDialog<List<File>?>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Select Images (Max $maxImages)'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Pick from Gallery'),
                onTap: () async {
                  Navigator.pop(context);
                  final images = await pickMultipleImages(maxImages: maxImages);
                  if (context.mounted) {
                    Navigator.pop(context, images);
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take Photo'),
                onTap: () async {
                  Navigator.pop(context);
                  final image = await pickImage(source: ImageSource.camera);
                  if (context.mounted) {
                    Navigator.pop(context, image != null ? [image] : <File>[]);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, <File>[]),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  // Compress and save image locally
  static Future<File?> compressAndSaveImage(File imageFile) async {
    try {
      final directory = await getTemporaryDirectory();
      final String fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final String filePath = '${directory.path}/$fileName';
      
      // Copy the file to temp directory (in a real app, you'd compress it here)
      final compressedFile = await imageFile.copy(filePath);
      return compressedFile;
    } catch (e) {
      debugPrint('Error compressing image: $e');
      return null;
    }
  }

  // Clear temporary images
  static Future<void> clearTemporaryImages() async {
    try {
      final directory = await getTemporaryDirectory();
      final dir = Directory(directory.path);
      await for (FileSystemEntity entity in dir.list()) {
        if (entity is File && entity.path.endsWith('.jpg')) {
          await entity.delete();
        }
      }
    } catch (e) {
      debugPrint('Error clearing temporary images: $e');
    }
  }
}
