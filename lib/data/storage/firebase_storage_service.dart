import 'package:tourn/domain/storage/storage_service.dart';

/// Minimal Firebase Storage service stub to satisfy compilation.
class FirebaseStorageService implements StorageService {
  @override
  Future<String> uploadFile(String localPath, String destinationPath) async {
    // TODO: Implement actual upload logic using firebase_storage package
    // For now return a dummy URL to keep the app compiling.
    return 'https://example.com/$destinationPath';
  }
}
