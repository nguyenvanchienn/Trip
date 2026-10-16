import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class BusinessOnboardingStepLicense extends StatelessWidget {
  const BusinessOnboardingStepLicense({
    super.key,
    required this.licenseImage,
    required this.onPickLicense,
    required this.onRemoveLicense,
  });

  final XFile? licenseImage;
  final VoidCallback onPickLicense;
  final VoidCallback onRemoveLicense;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Giấy phép kinh doanh',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        const Text('Tải lên ảnh giấy phép kinh doanh để xác minh hồ sơ.'),
        const SizedBox(height: 12),
        if (licenseImage == null)
          OutlinedButton.icon(
            onPressed: onPickLicense,
            icon: const Icon(Icons.badge_outlined),
            label: const Text('Chọn ảnh giấy phép'),
          )
        else
          _buildImage(licenseImage!, onRemoveLicense),
      ],
    );
  }

  Widget _buildImage(XFile file, VoidCallback onRemove) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.file(
            File(file.path),
            height: 200,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: InkWell(
            onTap: onRemove,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(6),
              child: const Icon(Icons.close, color: Colors.white, size: 16),
            ),
          ),
        ),
      ],
    );
  }
}
