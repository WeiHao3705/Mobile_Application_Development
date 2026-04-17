import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'dart:developer' as developer;

class ImagePickerService {
  final ImagePicker _imagePicker = ImagePicker();

  /// Pick image from camera
  Future<File?> pickImageFromCamera() async {
    try {
      developer.log('📷 Opening camera...');

      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxHeight: 1920.0,
        maxWidth: 1920.0,
      );

      if (pickedFile != null) {
        developer.log('✅ Image captured: ${pickedFile.path}');
        final file = File(pickedFile.path);
        final sizeInKB = file.lengthSync() / 1024;
        developer.log('📊 Image size: ${sizeInKB.toStringAsFixed(2)} KB');
        return file;
      }

      developer.log('⚠️  Camera capture cancelled');
      return null;
    } catch (e) {
      developer.log('❌ Camera error: $e');
      developer.log('❌ Error type: ${e.runtimeType}');
      rethrow;
    }
  }

  /// Pick image from gallery
  Future<File?> pickImageFromGallery() async {
    try {
      developer.log('🖼️  Opening gallery...');

      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxHeight: 1920.0,
        maxWidth: 1920.0,
      );

      if (pickedFile != null) {
        developer.log('✅ Image selected: ${pickedFile.path}');
        final file = File(pickedFile.path);
        final sizeInKB = file.lengthSync() / 1024;
        developer.log('📊 Image size: ${sizeInKB.toStringAsFixed(2)} KB');
        return file;
      }

      developer.log('⚠️  Gallery selection cancelled');
      return null;
    } catch (e) {
      developer.log('❌ Gallery error: $e');
      rethrow;
    }
  }

  /// Get file size in MB
  static double getFileSizeInMB(File file) {
    return file.lengthSync() / (1024 * 1024);
  }

  /// Get file size in KB
  static double getFileSizeInKB(File file) {
    return file.lengthSync() / 1024;
  }

  /// Check if file is a valid image
  static bool isValidImageFile(File file) {
    final path = file.path.toLowerCase();
    return path.endsWith('.jpg') ||
        path.endsWith('.jpeg') ||
        path.endsWith('.png') ||
        path.endsWith('.gif') ||
        path.endsWith('.webp');
  }

  /// Get image file size and validate
  static bool validateImageFile({
    required File file,
    double maxSizeInMB = 10.0,
  }) {
    developer.log('🔍 Validating image file: ${file.path}');

    // Check if file exists
    if (!file.existsSync()) {
      developer.log('❌ File does not exist');
      return false;
    }

    // Check file type
    if (!isValidImageFile(file)) {
      developer.log('❌ Invalid file type');
      return false;
    }

    // Check file size
    final sizeInMB = getFileSizeInMB(file);
    if (sizeInMB > maxSizeInMB) {
      developer.log('❌ File size ($sizeInMB MB) exceeds maximum ($maxSizeInMB MB)');
      return false;
    }

    developer.log('✅ Image file validation passed');
    return true;
  }
}




