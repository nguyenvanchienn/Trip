import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class BusinessOnboardingStepLocation extends StatelessWidget {
  const BusinessOnboardingStepLocation({
    super.key,
    required this.locationImages,
    required this.maxLocationImages,
    required this.onPickLocationImages,
    required this.onRemoveLocationImage,
  });

  final List<XFile> locationImages;
  final int maxLocationImages;
  final VoidCallback onPickLocationImages;
  final ValueChanged<int> onRemoveLocationImage;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Ảnh địa điểm',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Text(
          'Tải lên ảnh địa điểm (${locationImages.length}/$maxLocationImages)',
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: onPickLocationImages,
          icon: const Icon(Icons.map_outlined),
          label: const Text('Chọn ảnh địa điểm'),
        ),
        const SizedBox(height: 8),
        if (locationImages.isEmpty)
          const Text('Chưa có ảnh nào', textAlign: TextAlign.center)
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (int i = 0; i < locationImages.length; i++)
                _buildThumb(locationImages[i], () => onRemoveLocationImage(i)),
            ],
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
