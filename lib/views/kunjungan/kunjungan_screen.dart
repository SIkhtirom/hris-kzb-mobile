import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/widgets/image_source_sheet.dart';
import '../../core/widgets/smooth_loader.dart';
import '../../core/widgets/upload_box.dart';
import '../../data/models/kunjungan_record.dart';
import '../../viewmodels/kunjungan_viewmodel.dart';

class KunjunganScreen extends StatefulWidget {
  final KunjunganMode mode;

  const KunjunganScreen({super.key, required this.mode});

  @override
  State<KunjunganScreen> createState() => _KunjunganScreenState();
}

class _KunjunganScreenState extends State<KunjunganScreen> {
  final _formKey = GlobalKey<FormState>();
  final _clientController = TextEditingController();
  final _notesController = TextEditingController();
  final _timeController = TextEditingController();

  late final bool _isStart = widget.mode == KunjunganMode.start;
  late final String _timeLabel;
  String? _evidencePath;

  @override
  void initState() {
    super.initState();
    _timeLabel = AppStrings.timeLabel(DateTime.now());
    _timeController.text = _timeLabel;
    WidgetsBinding.instance.addPostFrameCallback((_) => _locate());
  }

  @override
  void dispose() {
    _clientController.dispose();
    _notesController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  Future<void> _locate() async {
    final overlay = SmoothLoader.show(
      context,
      message: AppStrings.locatingLabel,
    );
    await context.read<KunjunganViewModel>().loadCurrentLocation();
    overlay.remove();
  }

  Future<void> _pickEvidence() async {
    final path = await pickCameraPhotoPath();
    if (path != null) {
      setState(() => _evidencePath = path);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final viewModel = context.read<KunjunganViewModel>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final overlay = SmoothLoader.show(
      context,
      message: AppStrings.savingMessage,
    );

    final success = await viewModel.submit(
      mode: widget.mode,
      timeLabel: _timeLabel,
      clientName: _clientController.text,
      notes: _notesController.text,
      evidencePath: _evidencePath,
    );
    overlay.remove();
    if (!mounted) {
      return;
    }
    if (!success) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            viewModel.errorMessage ?? AppStrings.visitFailedMessage,
          ),
        ),
      );
      return;
    }
    navigator.pop(true);
    messenger.showSnackBar(
      const SnackBar(content: Text(AppStrings.visitSavedMessage)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<KunjunganViewModel>();
    final title = _isStart
        ? AppStrings.startVisitTitle
        : AppStrings.endVisitTitle;
    final timeField = _isStart
        ? AppStrings.kunjunganNowTimeField
        : AppStrings.kunjunganEndTimeField;
    final notesField = _isStart
        ? AppStrings.visitNotesField
        : AppStrings.endVisitNotesField;
    final notesHint = _isStart
        ? AppStrings.visitNotesHint
        : AppStrings.endVisitNotesHint;
    final submitLabel = _isStart
        ? AppStrings.submitStartVisitButton
        : AppStrings.submitEndVisitButton;

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _mapArea(viewModel),
            const SizedBox(height: 16),
            TextFormField(
              key: const Key('kunjungan_time_field'),
              controller: _timeController,
              readOnly: true,
              decoration: InputDecoration(
                labelText: timeField,
                prefixIcon: const Icon(Icons.schedule_outlined),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _clientController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: AppStrings.clientNameField,
                hintText: AppStrings.clientNameHint,
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: (value) => (value == null || value.trim().isEmpty)
                  ? AppStrings.invalidClientName
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              maxLines: 4,
              maxLength: 300,
              decoration: InputDecoration(
                labelText: notesField,
                hintText: notesHint,
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 8),
            _evidenceUpload(),
            const SizedBox(height: 28),
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: viewModel.isSubmitting ? null : () => _submit(),
                child: Text(submitLabel),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _mapArea(KunjunganViewModel viewModel) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE8F1FC), Color(0xFFD3E3FA)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
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
                AppStrings.gpsLocationLabel,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.location_on,
                    color: AppColors.primary,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    viewModel.address,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${viewModel.formattedLatitude}, ${viewModel.formattedLongitude}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _evidenceUpload() {
    return _uploadSquare(
      label: AppStrings.evidenceLabel,
      filePath: _evidencePath,
      icon: Icons.document_scanner_outlined,
      onTap: _pickEvidence,
    );
  }

  Widget _uploadSquare({
    required String label,
    required String? filePath,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final path = filePath;
    final hasFile = path != null && File(path).existsSync();

    return Column(
      children: [
        CustomPaint(
          painter: const DashedBorderPainter(
            color: AppColors.primary,
            radius: 12,
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onTap,
            child: SizedBox(
              height: 120,
              width: double.infinity,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: hasFile
                    ? Image.file(
                        File(path),
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => _uploadPlaceholder(icon),
                      )
                    : _uploadPlaceholder(icon),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _uploadPlaceholder(IconData icon) {
    return Container(
      width: double.infinity,
      color: AppColors.background,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppColors.primary, size: 28),
          const SizedBox(height: 6),
          const Icon(
            Icons.add_circle_outline,
            color: AppColors.textSecondary,
            size: 18,
          ),
        ],
      ),
    );
  }
}
