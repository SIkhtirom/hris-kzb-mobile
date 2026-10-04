import 'dart:io';

import 'photo_storage_service.dart';

class SelfieStorageService {
  SelfieStorageService({Future<Directory> Function()? directoryProvider})
    : _photos = PhotoStorageService(directoryProvider: directoryProvider);

  final PhotoStorageService _photos;

  Future<String?> copyToPermanent(String sourcePath) {
    return _photos.copyPhoto(sourcePath: sourcePath, folder: 'selfies');
  }
}
