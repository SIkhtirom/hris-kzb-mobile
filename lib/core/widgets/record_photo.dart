import 'dart:io';

import 'package:flutter/material.dart';

import '../constants/api_constants.dart';

class RecordPhoto extends StatelessWidget {
  final String? path;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadiusGeometry? borderRadius;
  final Widget fallback;

  const RecordPhoto({
    super.key,
    required this.path,
    required this.fallback,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final source = path;
    Widget? image;
    if (source != null && source.isNotEmpty) {
      if (ApiConstants.isLocalFilePath(source)) {
        if (File(source).existsSync()) {
          image = Image.file(
            File(source),
            width: width,
            height: height,
            fit: fit,
            errorBuilder: (_, _, _) => fallback,
          );
        }
      } else {
        image = Image.network(
          ApiConstants.fileUrl(source),
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (_, _, _) => fallback,
        );
      }
    }
    final resolved = image ?? fallback;
    final radius = borderRadius;
    if (radius == null) {
      return resolved;
    }
    return ClipRRect(borderRadius: radius, child: resolved);
  }
}
