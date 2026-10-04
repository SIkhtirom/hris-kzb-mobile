import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/config/app_config.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/widgets/dashboard_skeleton.dart';
import '../../core/widgets/error_banner.dart';
import '../../core/widgets/record_photo.dart';
import '../../data/models/attendance_record.dart';
import '../../data/models/kunjungan_record.dart';
import '../../data/models/user.dart';
import '../../viewmodels/dashboard_viewmodel.dart';
import '../attendance/attendance_screen.dart';
import '../kunjungan/kunjungan_screen.dart';
import '../reimbursement/reimbursement_list_screen.dart';
import '../timesheet/timesheet_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardViewModel>().loadDashboard();
    });
  }

  Future<void> _openAttendance(ClockEventType action) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => AttendanceScreen(action: action)),
    );
    if (mounted) {
      await context.read<DashboardViewModel>().loadDashboard();
    }
  }

  void _openReimbursement() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const ReimbursementListScreen()),
    );
  }

  void _openStartVisit() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const KunjunganScreen(mode: KunjunganMode.start),
      ),
    );
  }

  void _openEndVisit() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const KunjunganScreen(mode: KunjunganMode.end),
      ),
    );
  }

  void _openTimesheet() {
    Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => const TimesheetScreen()));
  }

  void _showAlreadyClockedDialog() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        content: const Text(AppStrings.alreadyClockedTodayMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text(AppStrings.okActionLabel),
          ),
        ],
      ),
    );
  }

  Future<void> _pickProfilePicture() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 800,
      maxHeight: 800,
    );
    if (picked == null) {
      return;
    }
    if (!mounted) {
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    final updated = await context
        .read<DashboardViewModel>()
        .updateProfilePicture(picked.path);
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          updated
              ? AppStrings.profilePictureUpdatedMessage
              : AppStrings.profilePictureSaveError,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<DashboardViewModel>();
    final user = viewModel.user;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: viewModel.loadDashboard,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          children: [
            SafeArea(bottom: false, child: _buildHeader(user: user)),
            _buildGreeting(user),
            if (viewModel.isLoading && user == null)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: DashboardSkeleton(),
              )
            else ...[
              if (viewModel.errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: ErrorBanner(
                    message: viewModel.errorMessage!,
                    onRetry: viewModel.loadDashboard,
                  ),
                ),
              const SizedBox(height: 20),
              _buildFeatureGrid(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader({required User? user}) {
    return Container(
      padding: const EdgeInsets.only(top: 16, bottom: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(
              'assets/images/logo-kzb.png',
              width: 30,
              height: 30,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) =>
                  const Icon(Icons.public, color: AppColors.primary, size: 28),
            ),
          ),
          const SizedBox(width: 10),
          const Text(
            AppStrings.brandName,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const Spacer(),
          _profileAvatar(user),
        ],
      ),
    );
  }

  Widget _profileAvatar(User? user) {
    final path = user?.profilePicturePath;
    final initial = (user?.name.isNotEmpty ?? false) ? user!.name[0] : 'K';

    return InkWell(
      onTap: _pickProfilePicture,
      customBorder: const CircleBorder(),
      child: Stack(
        children: [
          SizedBox(
            width: 44,
            height: 44,
            child: ClipOval(
              child: RecordPhoto(
                path: path,
                width: 44,
                height: 44,
                fallback: Container(
                  color: AppColors.primary.withValues(alpha: 0.14),
                  child: Center(
                    child: Text(
                      initial,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              child: const Icon(
                Icons.camera_alt,
                size: 11,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGreeting(User? user) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 28, 8, 24),
      child: Column(
        children: [
          Text(
            AppStrings.homeGreeting(user?.name ?? '', DateTime.now()),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            AppStrings.greetingSubtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureGrid() {
    final viewModel = context.watch<DashboardViewModel>();

    void showLocked(String message) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.25,
      children: [
        _featureCard(
          icon: Icons.inbox_outlined,
          label: AppStrings.checkInCard,
          enabled: AppConfig.allowRepeatCheckIn || !viewModel.hasClockedInToday,
          onTap: () => _openAttendance(ClockEventType.checkIn),
          onLocked: _showAlreadyClockedDialog,
        ),
        _featureCard(
          icon: Icons.outbox_outlined,
          label: AppStrings.checkOutCard,
          enabled: viewModel.isCheckOutAvailable,
          onTap: () => _openAttendance(ClockEventType.checkOut),
          onLocked: viewModel.hasCompletedCycleToday
              ? _showAlreadyClockedDialog
              : () => showLocked(AppStrings.checkOutWaitingLabel),
        ),
        _featureCard(
          icon: Icons.location_on_outlined,
          label: AppStrings.startVisitCard,
          onTap: _openStartVisit,
        ),
        _featureCard(
          icon: Icons.luggage_outlined,
          label: AppStrings.endVisitCard,
          onTap: _openEndVisit,
        ),
        _featureCard(
          icon: Icons.currency_exchange,
          label: AppStrings.reimbursementCard,
          onTap: _openReimbursement,
        ),
        _featureCard(
          icon: Icons.query_stats,
          label: AppStrings.timesheetCard,
          onTap: _openTimesheet,
        ),
      ],
    );
  }

  Widget _featureCard({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool enabled = true,
    VoidCallback? onLocked,
  }) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: enabled ? onTap : onLocked,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: enabled
                      ? AppColors.primary.withValues(alpha: 0.12)
                      : AppColors.inputBorder.withValues(alpha: 0.4),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: enabled ? AppColors.primary : AppColors.textSecondary,
                  size: 28,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: enabled
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
