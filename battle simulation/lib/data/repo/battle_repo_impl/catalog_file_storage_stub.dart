import 'catalog_file_storage.dart';

class UnsupportedCatalogFileStorage implements CatalogFileStorage {
  const UnsupportedCatalogFileStorage();

  @override
  String get currentDirectoryPath =>
      throw UnsupportedError('Local file storage is not available.');

  @override
  Future<void> ensureParentDirectory(String path) async {
    throw UnsupportedError('Local file storage is not available.');
  }

  @override
  Future<bool> exists(String path) async {
    throw UnsupportedError('Local file storage is not available.');
  }

  @override
  String join(String first, String second) {
    throw UnsupportedError('Local file storage is not available.');
  }

  @override
  Future<String> readAsString(String path) async {
    throw UnsupportedError('Local file storage is not available.');
  }

  @override
  Future<void> writeAsString(String path, String contents) async {
    throw UnsupportedError('Local file storage is not available.');
  }
}

CatalogFileStorage createPlatformCatalogFileStorage() =>
    const UnsupportedCatalogFileStorage();
