import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:tourn/domain/storage/storage_service.dart';

/// Dịch vụ Storage không dùng Firebase Storage, thay vào đó
/// nén ảnh và lưu trực tiếp dưới dạng chuỗi base64 giống với bài viết cá nhân.
class FirebaseStorageService implements StorageService {
  @override
  Future<String> uploadFile(String localPath, String destinationPath) async {
    final file = File(localPath);
    if (!await file.exists()) {
      throw Exception('File not found: $localPath');
    }

    final bytes = await file.readAsBytes();
    final compressedBytes = _compressImage(bytes);
    final base64String = base64Encode(compressedBytes);
    return 'data:image/jpeg;base64,$base64String';
  }

  Uint8List _compressImage(
    Uint8List bytes, {
    int maxWidth = 800,
    int quality = 70,
  }) {
    try {
      final image = img.decodeImage(bytes);
      if (image == null) return bytes;

      img.Image resized;
      if (image.width > maxWidth) {
        resized = img.copyResize(image, width: maxWidth);
      } else {
        resized = image;
      }

      return Uint8List.fromList(img.encodeJpg(resized, quality: quality));
    } catch (e) {
      print('Error compressing image: $e');
      return bytes;
    }
  }
}
