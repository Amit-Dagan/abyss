import 'dart:io';

import 'catalog_file_storage.dart';

class IoCatalogFileStorage implements CatalogFileStorage {
  const IoCatalogFileStorage();

  @override
  String get currentDirectoryPath => Directory.current.path;

  @override
  Future<void> ensureParentDirectory(String path) async {
    await File(path).parent.create(recursive: true);
  }

  @override
  Future<bool> exists(String path) async => File(path).exists();

  @override
  String join(String first, String second) {
    return '$first${Platform.pathSeparator}$second';
  }

  @override
  Future<String> readAsString(String path) async => File(path).readAsString();

  @override
  Future<void> writeAsString(String path, String contents) async {
    await File(path).writeAsString(contents);
  }
}

CatalogFileStorage createPlatformCatalogFileStorage() =>
    const IoCatalogFileStorage();
