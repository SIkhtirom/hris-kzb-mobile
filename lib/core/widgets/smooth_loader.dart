import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

class SmoothLoader extends StatelessWidget {
  final String? message;
  final double size;

  const SmoothLoader({super.key, this.message, this.size = 40});

  static OverlayEntry show(BuildContext context, {String? message}) {
    final overlay = Overlay.of(context, rootOverlay: true);
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _LoaderOverlay(message: message, remove: entry.remove),
    );
    overlay.insert(entry);
    return entry;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: const CircularProgressIndicator(
            strokeWidth: 3,
            color: AppColors.primary,
          ),
        ),
        if (message != null) ...[
          const SizedBox(height: 12),
          Text(
            message!,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ],
    );
  }
}

class _LoaderOverlay extends StatefulWidget {
  final String? message;
  final VoidCallback remove;

  const _LoaderOverlay({required this.message, required this.remove});

  @override
  State<_LoaderOverlay> createState() => _LoaderOverlayState();
}

class _LoaderOverlayState extends State<_LoaderOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: FadeTransition(
        opacity: _controller,
        child: Stack(
          children: [
            Positioned.fill(
              child: ColoredBox(color: Colors.black.withValues(alpha: 0.18)),
            ),
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 22,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: SmoothLoader(message: widget.message),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
