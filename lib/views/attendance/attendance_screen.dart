import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/widgets/record_photo.dart';
import '../../data/models/attendance_record.dart';
import '../../viewmodels/attendance_viewmodel.dart';
import '../../viewmodels/calendar_viewmodel.dart';

class AttendanceScreen extends StatefulWidget {
  final ClockEventType action;

  const AttendanceScreen({super.key, required this.action});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final viewModel = context.read<AttendanceViewModel>();
    viewModel.configure(widget.action);
    await viewModel.loadInitialState();
    if (!mounted) {
      return;
    }
    if (viewModel.errorMessage == AppStrings.poorConnectionMessage) {
      _showPoorConnectionAndExit();
    }
  }

  void _showPoorConnectionAndExit() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text(AppStrings.poorConnectionMessage)),
    );
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
    }
  }

  Future<void> _submit() async {
    final viewModel = context.read<AttendanceViewModel>();
    final messenger = ScaffoldMessenger.of(context);
    final actionLabel = viewModel.actionLabel;
    final success = await viewModel.submit();
    if (!mounted) {
      return;
    }
    if (!success) {
      if (viewModel.errorMessage == AppStrings.poorConnectionMessage) {
        _showPoorConnectionAndExit();
      }
      return;
    }
    try {
      await context.read<CalendarViewModel>().loadCalendarWindow(
        DateTime.now(),
      );
    } catch (_) {}
    if (!mounted) {
      return;
    }
    Navigator.of(context).pop();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          '$actionLabel berhasil dicatat pada ${viewModel.lastSubmittedAt ?? ''}',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<AttendanceViewModel>();

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.attendanceTitle)),
      body: viewModel.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Column(
                children: [
                  Expanded(child: _selfieSection(viewModel.selfiePath)),
                  if (viewModel.verificationRecord != null)
                    _verificationStrip(
                      viewModel.verificationRecord!,
                      timeLabel: viewModel.verificationTimeLabel,
                    ),
                  if (viewModel.errorMessage != null)
                    _errorStrip(viewModel.errorMessage!),
                  if (viewModel.hasClockedInToday && !viewModel.canCheckOut)
                    _cycleNotice(viewModel.hasCheckedOutToday),
                  Expanded(
                    child: _mapSection(
                      timeLabel: viewModel.currentServerTime,
                      dateLabel: viewModel.currentDateLabel,
                      latitude: viewModel.formattedLatitude,
                      longitude: viewModel.formattedLongitude,
                      address: viewModel.address,
                    ),
                  ),
                ],
              ),
            ),
      bottomNavigationBar: viewModel.showActionButton
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: _submitButton(
                  label: viewModel.actionLabel,
                  isSubmitting: viewModel.isSubmitting,
                  onPressed: _submit,
                ),
              ),
            )
          : null,
    );
  }

  Widget _selfieSection(String? path) {
    final hasSelfie = path != null && path.isNotEmpty;

    return Container(
      width: double.infinity,
      color: const Color(0xFF2E3B45),
      child: Stack(
        children: [
          if (hasSelfie)
            Positioned.fill(
              child: RecordPhoto(
                path: path,
                fit: BoxFit.cover,
                fallback: Center(child: _selfiePlaceholder()),
              ),
            )
          else
            Center(child: _selfiePlaceholder()),
          if (hasSelfie)
            Positioned(
              top: 12,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle, color: Colors.white, size: 14),
                    SizedBox(width: 4),
                    Text(
                      AppStrings.selfieCapturedLabel,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _selfiePlaceholder() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.08),
              border: Border.all(color: Colors.white24, width: 2),
            ),
            child: const Icon(
              Icons.person_outline,
              color: Colors.white54,
              size: 50,
            ),
          ),
          const SizedBox(height: 18),
          const Icon(
            Icons.photo_camera_outlined,
            color: Colors.white38,
            size: 28,
          ),
          const SizedBox(height: 8),
          const Text(
            AppStrings.selfiePrompt,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _verificationStrip(
    AttendanceRecord record, {
    required String timeLabel,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      color: AppColors.success.withValues(alpha: 0.14),
      child: Row(
        children: [
          const Icon(Icons.verified, color: AppColors.success, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${AppStrings.attendanceActionLabel(record.eventType)} · '
              '$timeLabel · ${AppStrings.attendanceRecordedLabel}',
              style: const TextStyle(
                color: AppColors.success,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _cycleNotice(bool hasCheckedOut) {
    final label = hasCheckedOut
        ? AppStrings.cycleDoneLabel
        : AppStrings.checkOutWaitingLabel;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      color: AppColors.success.withValues(alpha: 0.14),
      child: Row(
        children: [
          Icon(
            hasCheckedOut ? Icons.verified : Icons.schedule,
            color: AppColors.success,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.success,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _errorStrip(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      color: AppColors.danger.withValues(alpha: 0.12),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.danger, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: AppColors.danger, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _mapSection({
    required String timeLabel,
    required String dateLabel,
    required String latitude,
    required String longitude,
    required String address,
  }) {
    return Container(
      width: double.infinity,
      color: const Color(0xFFE8EFE6),
      child: Stack(
        children: [
          const Positioned.fill(child: CustomPaint(painter: _GridPainter())),
          Positioned(
            top: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.border),
              ),
              child: const Text(
                AppStrings.gpsChipLabel,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
          Center(
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.location_on,
                color: AppColors.danger,
                size: 34,
              ),
            ),
          ),
          Positioned(
            left: 12,
            right: 12,
            bottom: 12,
            child: _locationCard(
              timeLabel: timeLabel,
              dateLabel: dateLabel,
              latitude: latitude,
              longitude: longitude,
              address: address,
            ),
          ),
        ],
      ),
    );
  }

  Widget _locationCard({
    required String timeLabel,
    required String dateLabel,
    required String latitude,
    required String longitude,
    required String address,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppStrings.serverTimeLabel,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Text(
                timeLabel,
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(dateLabel, style: Theme.of(context).textTheme.bodySmall),
          const Divider(height: 20),
          _locationRow(
            icon: Icons.place,
            label: AppStrings.addressLabel,
            value: address,
          ),
          const SizedBox(height: 10),
          _locationRow(
            icon: Icons.gps_fixed,
            label: AppStrings.coordinatesLabel,
            value: '$latitude, $longitude',
          ),
        ],
      ),
    );
  }

  Widget _locationRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.primary, size: 18),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.bodySmall),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _submitButton({
    required String label,
    required bool isSubmitting,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      height: 56,
      child: ElevatedButton.icon(
        onPressed: isSubmitting ? null : onPressed,
        icon: isSubmitting
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.fingerprint, size: 22),
        label: Text(label, style: const TextStyle(fontSize: 16)),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  const _GridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    const step = 36.0;
    final paint = Paint()
      ..color = const Color(0xFFD6E0D3)
      ..strokeWidth = 1;

    final mainRoad = Paint()
      ..color = const Color(0xFFC8D4C5)
      ..strokeWidth = 6;

    for (var x = 0.0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var y = 0.0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    canvas.drawLine(
      Offset(size.width * 0.18, 0),
      Offset(size.width * 0.55, size.height),
      mainRoad,
    );
    canvas.drawLine(const Offset(0, 40), Offset(size.width, 40), mainRoad);
  }

  @override
  bool shouldRepaint(covariant _GridPainter oldDelegate) => false;
}
