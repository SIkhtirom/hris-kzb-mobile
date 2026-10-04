import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../calendar/calendar_screen.dart';
import '../izin/izin_list_screen.dart';
import '../kunjungan/kunjungan_history_screen.dart';

class DocumentHubScreen extends StatelessWidget {
  const DocumentHubScreen({super.key});

  void _openHistory(BuildContext context) {
    Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => const CalendarScreen()));
  }

  void _openIzin(BuildContext context) {
    Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => const IzinListScreen()));
  }

  void _openKunjunganHistory(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const KunjunganHistoryScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.documentsTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          _documentTile(
            icon: Icons.calendar_month_outlined,
            title: AppStrings.historyActionLabel,
            subtitle: AppStrings.historyActionSubtitle,
            onTap: () => _openHistory(context),
          ),
          const SizedBox(height: 12),
          _documentTile(
            icon: Icons.location_on_outlined,
            title: AppStrings.kunjunganHistoryTitle,
            subtitle: AppStrings.kunjunganHistorySubtitle,
            onTap: () => _openKunjunganHistory(context),
          ),
          const SizedBox(height: 12),
          _documentTile(
            icon: Icons.event_note_outlined,
            title: AppStrings.izinActionLabel,
            subtitle: AppStrings.izinActionSubtitle,
            onTap: () => _openIzin(context),
          ),
        ],
      ),
    );
  }

  Widget _documentTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.primary, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
