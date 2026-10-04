import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

class DashboardSkeleton extends StatefulWidget {
  const DashboardSkeleton({super.key});

  @override
  State<DashboardSkeleton> createState() => _DashboardSkeletonState();
}

class _DashboardSkeletonState extends State<DashboardSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
      lowerBound: 0.35,
      upperBound: 1,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: Column(
        children: [
          const _Block(width: 120, height: 14),
          const SizedBox(height: 10),
          const _Block(width: 220, height: 12),
          const SizedBox(height: 28),
          for (var row = 0; row < 3; row++) ...[
            Row(
              children: [
                for (var column = 0; column < 2; column++) ...[
                  const Expanded(child: _Block(height: 96)),
                  if (column == 0) const SizedBox(width: 12),
                ],
              ],
            ),
            if (row < 2) const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _Block extends StatelessWidget {
  final double width;
  final double height;

  const _Block({this.width = double.infinity, required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.inputBorder.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}
