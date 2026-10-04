import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/widgets/record_photo.dart';
import '../../data/repositories/auth_repository.dart';
import '../../viewmodels/dashboard_viewmodel.dart';
import '../settings/settings_screen.dart';

class MoreScreen extends StatelessWidget {
  final VoidCallback? onLoggedOut;

  const MoreScreen({super.key, this.onLoggedOut});

  void _openSettings(BuildContext context) {
    Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => const SettingsScreen()));
  }

  void _openAbout(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: AppStrings.brandName,
      applicationVersion: AppStrings.aboutVersionLabel,
      applicationLegalese: AppStrings.splashTagline,
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text(AppStrings.logoutConfirmTitle),
        content: const Text(AppStrings.logoutConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text(
              AppStrings.cancelActionLabel,
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text(
              AppStrings.logoutActionLabel,
              style: TextStyle(
                color: AppColors.danger,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await context.read<AuthRepository>().logout();
      onLoggedOut?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<DashboardViewModel>().user;
    final photoPath = user?.profilePicturePath;
    final initial = (user?.name.isNotEmpty ?? false) ? user!.name[0] : 'K';

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.moreTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  SizedBox(
                    width: 48,
                    height: 48,
                    child: ClipOval(
                      child: RecordPhoto(
                        path: photoPath,
                        width: 48,
                        height: 48,
                        fallback: Container(
                          color: AppColors.primary,
                          child: Center(
                            child: Text(
                              initial,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.name ?? AppStrings.brandName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Row(
                          children: [
                            Text(
                              AppStrings.roleLabel,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              user?.role ?? AppStrings.splashTagline,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          _menuTile(
            icon: Icons.person_outline,
            title: AppStrings.profileLabel,
            onTap: () => _openSettings(context),
          ),
          _menuTile(
            icon: Icons.info_outline,
            title: AppStrings.aboutTitle,
            showVersionBadge: true,
            onTap: () => _openAbout(context),
          ),
          const SizedBox(height: 8),
          Card(
            margin: EdgeInsets.zero,
            child: ListTile(
              onTap: () => _confirmLogout(context),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              leading: const Icon(Icons.logout, color: AppColors.danger),
              title: const Text(
                AppStrings.logoutLabel,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.danger,
                ),
              ),
              trailing: const Icon(
                Icons.chevron_right,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _menuTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool showVersionBadge = false,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: Icon(icon, color: AppColors.primary),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        trailing: showVersionBadge
            ? Text(
                AppStrings.aboutVersionLabel,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              )
            : const Icon(Icons.chevron_right, color: AppColors.textSecondary),
      ),
    );
  }
}
