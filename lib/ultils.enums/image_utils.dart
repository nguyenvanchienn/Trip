import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';

/// Returns the appropriate ImageProvider for a given URL.
/// Handles both base64 data URLs and regular network URLs.
ImageProvider? getImageProvider(String? url) {
  if (url == null || url.isEmpty) {
    return null;
  }

  // Check if it's a base64 data URL
  if (url.startsWith('data:image')) {
    try {
      // Extract the base64 part after the comma
      final base64String = url.split(',').last;
      final bytes = base64Decode(base64String);
      return MemoryImage(bytes);
    } catch (e) {
      print('Error decoding base64 image: $e');
      return null;
    }
  }

  if (url.startsWith('file://')) {
    try {
      return FileImage(File(Uri.parse(url).toFilePath()));
    } catch (e) {
      // Fallback if parsing fails
      return FileImage(File(url.replaceFirst('file://', '')));
    }
  } else if (url.startsWith('/')) {
    return FileImage(File(url));
  }

  // Otherwise treat as network URL
  return NetworkImage(url);
}

/// Widget that displays an image from either base64 or network URL
class SmartImage extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;

  const SmartImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    final provider = getImageProvider(imageUrl);

    if (provider == null) {
      return placeholder ?? const Icon(Icons.person, color: Colors.grey);
    }

    return Image(
      image: provider,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) {
        return errorWidget ?? const Icon(Icons.error, color: Colors.red);
      },
    );
  }
}
