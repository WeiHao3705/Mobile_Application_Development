import 'package:flutter/material.dart';
import 'package:mobile_application_development/theme/app_colors.dart';
import 'package:provider/provider.dart';
import 'package:mobile_application_development/controllers/meal_controller.dart';

class MealImagePickerWidget extends StatefulWidget {
  final VoidCallback? onImageSelected;
  final VoidCallback? onImageCleared;

  const MealImagePickerWidget({
    super.key,
    this.onImageSelected,
    this.onImageCleared,
  });

  @override
  State<MealImagePickerWidget> createState() => _MealImagePickerWidgetState();
}

class _MealImagePickerWidgetState extends State<MealImagePickerWidget> {
  @override
  Widget build(BuildContext context) {
    return Consumer<MealController>(
      builder: (context, mealController, _) {
        final hasImage = mealController.selectedMealImage != null;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 18.0),
              child: Text(
                'Add Meal Photo (Optional)',
                style: TextStyle(
                  color: AppColors.lavender,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Image preview or placeholder
            if (hasImage)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18.0),
                child: Stack(
                  children: [
                    // Image preview
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        mealController.selectedMealImage!,
                        width: double.infinity,
                        height: 200,
                        fit: BoxFit.cover,
                      ),
                    ),

                    // Remove button
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: () {
                          mealController.clearSelectedImage();
                          widget.onImageCleared?.call();
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.8),
                            shape: BoxShape.circle,
                          ),
                          padding: const EdgeInsets.all(8),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18.0),
                child: Container(
                  width: double.infinity,
                  height: 160,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: AppColors.lavender.withValues(alpha: 0.3),
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    color: AppColors.inputBg,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.image_outlined,
                        size: 48,
                        color: AppColors.lavender.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'No photo selected',
                        style: TextStyle(
                          color: AppColors.fatBar,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 14),

            // Image picker buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18.0),
              child: Row(
                children: [
                  // Camera button
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: mealController.isUploadingImage
                          ? null
                          : () async {
                              final success =
                                  await mealController.pickImageFromCamera();
                              if (success && mounted) {
                                widget.onImageSelected?.call();
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.lime,
                        foregroundColor: AppColors.nearBlack,
                        disabledBackgroundColor:
                            AppColors.lime.withValues(alpha: 0.5),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: const Icon(Icons.camera_alt_outlined, size: 18),
                      label: const Text(
                        'Camera',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Gallery button
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: mealController.isUploadingImage
                          ? null
                          : () async {
                              final success =
                                  await mealController.pickImageFromGallery();
                              if (success && mounted) {
                                widget.onImageSelected?.call();
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.lavender,
                        foregroundColor: AppColors.white,
                        disabledBackgroundColor:
                            AppColors.lavender.withValues(alpha: 0.5),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: const Icon(Icons.photo_library_outlined, size: 18),
                      label: const Text(
                        'Gallery',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Error message
            if (mealController.errorMessage.isNotEmpty &&
                !mealController.isLoading)
              Padding(
                padding: const EdgeInsets.only(
                  left: 18.0,
                  right: 18.0,
                  top: 10,
                ),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    mealController.errorMessage,
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}



