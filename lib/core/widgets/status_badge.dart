import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_strings.dart';

class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;

  const StatusBadge({
    super.key,
    required this.label,
    required this.color,
    required this.icon,
  });

  const StatusBadge.pending({super.key})
    : label = AppStrings.pendingLabel,
      color = AppColors.warning,
      icon = Icons.schedule;

  const StatusBadge.approved({super.key})
    : label = AppStrings.approvedLabel,
      color = AppColors.success,
      icon = Icons.verified;

  const StatusBadge.rejected({super.key})
    : label = AppStrings.rejectedLabel,
      color = AppColors.danger,
      icon = Icons.block;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
