import 'dart:io';
import 'dart:math';

import 'package:path_provider/path_provider.dart';

class PhotoStorageService {
  PhotoStorageService({Future<Directory> Function()? directoryProvider})
    : _directoryProvider =
          directoryProvider ?? getApplicationDocumentsDirectory;

  final Future<Directory> Function() _directoryProvider;

  Future<String?> copyPhoto({
    required String sourcePath,
    required String folder,
  }) async {
    try {
      final source = File(sourcePath);
      if (!await source.exists()) {
        return null;
      }
      final documentsDirectory = await _directoryProvider();
      final targetDirectory = Directory(
        '${documentsDirectory.path}${Platform.pathSeparator}$folder',
      );
      if (!await targetDirectory.exists()) {
        await targetDirectory.create(recursive: true);
      }
      final stamp = DateTime.now().microsecondsSinceEpoch;
      final suffix = Random()
          .nextInt(0xFFFFFF)
          .toRadixString(16)
          .padLeft(6, '0');
      final target = File(
        '${targetDirectory.path}${Platform.pathSeparator}'
        'photo_${stamp}_$suffix${_extensionOf(sourcePath)}',
      );
      await source.copy(target.path);
      return target.path;
    } catch (_) {
      return null;
    }
  }

  String _extensionOf(String path) {
    final normalized = path.replaceAll('\\', '/');
    final fileName = normalized.split('/').last;
    final dot = fileName.lastIndexOf('.');
    if (dot == -1) {
      return '.jpg';
    }
    final raw = fileName.substring(dot).split('?').first;
    return raw.isEmpty ? '.jpg' : raw;
  }
}
