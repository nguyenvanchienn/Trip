import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class BusinessOnboardingStepMedia extends StatelessWidget {
  const BusinessOnboardingStepMedia({
    super.key,
    required this.avatarImage,
    required this.shopImages,
    required this.maxShopImages,
    required this.onPickAvatar,
    required this.onRemoveAvatar,
    required this.onPickShopImages,
    required this.onRemoveShopImage,
  });

  final XFile? avatarImage;
  final List<XFile> shopImages;
  final int maxShopImages;
  final VoidCallback onPickAvatar;
  final VoidCallback onRemoveAvatar;
  final VoidCallback onPickShopImages;
  final ValueChanged<int> onRemoveShopImage;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Ảnh đại diện và ảnh quán',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        _buildSectionTitle('Ảnh đại diện'),
        const SizedBox(height: 8),
        if (avatarImage == null)
          OutlinedButton.icon(
            onPressed: onPickAvatar,
            icon: const Icon(Icons.image_outlined),
            label: const Text('Chọn ảnh đại diện'),
          )
        else
          _buildSingleImage(avatarImage!, onRemoveAvatar),
        const SizedBox(height: 16),
        _buildSectionTitle('Ảnh quán (${shopImages.length}/$maxShopImages)'),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: onPickShopImages,
          icon: const Icon(Icons.photo_library_outlined),
          label: const Text('Chọn ảnh quán'),
        ),
        const SizedBox(height: 8),
        if (shopImages.isEmpty)
          const Text('Chưa có ảnh nào', textAlign: TextAlign.center)
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (int i = 0; i < shopImages.length; i++)
                _buildThumb(shopImages[i], () => onRemoveShopImage(i)),
            ],
          ),
      ],
    );
  }

  Widget _buildSectionTitle(String text) {
    return Text(text, style: const TextStyle(fontWeight: FontWeight.w600));
  }

  Widget _buildSingleImage(XFile file, VoidCallback onRemove) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.file(
            File(file.path),
            height: 160,
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

  Widget _buildThumb(XFile file, VoidCallback onRemove) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.file(
            File(file.path),
            width: 96,
            height: 96,
            fit: BoxFit.cover,
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: InkWell(
            onTap: onRemove,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(4),
              child: const Icon(Icons.close, color: Colors.white, size: 14),
            ),
          ),
        ),
      ],
    );
  }
}
