import 'catalog_file_storage_stub.dart'
    if (dart.library.io) 'catalog_file_storage_io.dart';

abstract class CatalogFileStorage {
  String get currentDirectoryPath;

  String join(String first, String second);

  Future<bool> exists(String path);

  Future<void> ensureParentDirectory(String path);

  Future<String> readAsString(String path);

  Future<void> writeAsString(String path, String contents);
}

CatalogFileStorage createCatalogFileStorage() =>
    createPlatformCatalogFileStorage();
