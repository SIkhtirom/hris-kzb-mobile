import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../constants/app_colors.dart';
import '../constants/app_strings.dart';

Future<String?> pickImageFilePath(BuildContext context) async {
  final source = await showModalBottomSheet<ImageSource>(
    context: context,
    showDragHandle: true,
    backgroundColor: AppColors.surface,
    builder: (_) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                AppStrings.photoSourceTitle,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),
          _OptionTile(
            icon: Icons.photo_camera_outlined,
            label: AppStrings.cameraActionLabel,
            source: ImageSource.camera,
          ),
          _OptionTile(
            icon: Icons.photo_library_outlined,
            label: AppStrings.galleryActionLabel,
            source: ImageSource.gallery,
          ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );

  if (source == null) {
    return null;
  }
  final file = await ImagePicker().pickImage(
    source: source,
    imageQuality: 85,
    maxWidth: 1600,
  );
  return file?.path;
}

Future<String?> pickCameraPhotoPath() async {
  final file = await ImagePicker().pickImage(
    source: ImageSource.camera,
    imageQuality: 85,
    maxWidth: 1600,
  );
  return file?.path;
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.icon,
    required this.label,
    required this.source,
  });

  final IconData icon;
  final String label;
  final ImageSource source;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(
        label,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
      onTap: () => Navigator.of(context).pop(source),
    );
  }
}
