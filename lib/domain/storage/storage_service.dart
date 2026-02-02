abstract class StorageService {
  /// Upload local file at [localPath] to [destinationPath] and return a download URL.
  Future<String> uploadFile(String localPath, String destinationPath);
}
