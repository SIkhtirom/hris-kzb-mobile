import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/widgets/smooth_loader.dart';
import '../../core/widgets/upload_box.dart';
import '../../data/models/timesheet_task.dart';
import '../../viewmodels/timesheet_viewmodel.dart';

class TimesheetScreen extends StatefulWidget {
  const TimesheetScreen({super.key});

  @override
  State<TimesheetScreen> createState() => _TimesheetScreenState();
}

class _TimesheetScreenState extends State<TimesheetScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TimesheetViewModel>().loadTasks();
    });
  }

  Future<void> _pickDate() async {
    final viewModel = context.read<TimesheetViewModel>();
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: viewModel.selectedDate,
      firstDate: DateTime(now.year - 1),
      lastDate: now.add(const Duration(days: 365)),
      helpText: AppStrings.timesheetTitle,
    );
    if (picked != null) {
      await viewModel.selectDate(picked);
    }
  }

  Future<void> _openTaskDetail(TimesheetTask task) async {
    final viewModel = context.read<TimesheetViewModel>();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _TaskProofSheet(task: task),
    );
    viewModel.cancelProof();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<TimesheetViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.timesheetTitle),
        actions: [
          IconButton(
            onPressed: _pickDate,
            icon: const Icon(Icons.filter_list),
            tooltip: AppStrings.timesheetTitle,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: _dateSelector(viewModel),
          ),
          Expanded(child: _tasksArea(viewModel)),
        ],
      ),
    );
  }

  Widget _dateSelector(TimesheetViewModel viewModel) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: _pickDate,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              const Icon(
                Icons.calendar_month_outlined,
                color: AppColors.primary,
                size: 22,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  AppStrings.shortDate(viewModel.selectedDate),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const Icon(
                Icons.keyboard_arrow_down,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tasksArea(TimesheetViewModel viewModel) {
    if (viewModel.isLoading) {
      return const Center(child: SmoothLoader());
    }
    if (viewModel.tasks.isEmpty) {
      return _emptyState();
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: viewModel.tasks.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) => _taskCard(viewModel.tasks[index]),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: AppColors.inputBorder.withValues(alpha: 0.4),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.assignment_outlined,
              size: 42,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            AppStrings.noTasksTitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            AppStrings.noTasksBody,
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

  Widget _taskCard(TimesheetTask task) {
    final time =
        '${task.hour.toString().padLeft(2, '0')}:${task.minute.toString().padLeft(2, '0')}';

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openTaskDetail(task),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Icon(
                task.isCompleted ? Icons.task_alt : Icons.radio_button_checked,
                color: task.isCompleted ? AppColors.success : AppColors.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  task.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (task.isCompleted)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check, color: AppColors.success, size: 13),
                          SizedBox(width: 3),
                          Text(
                            AppStrings.taskCompletedLabel,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.success,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.inputBorder.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        AppStrings.taskPendingLabel,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (task.isCompleted) ...[
                        const Icon(
                          Icons.image_outlined,
                          color: AppColors.success,
                          size: 14,
                        ),
                        const SizedBox(width: 3),
                      ],
                      Text(
                        time,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: task.isCompleted
                              ? AppColors.success
                              : AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TaskProofSheet extends StatefulWidget {
  final TimesheetTask task;

  const _TaskProofSheet({required this.task});

  @override
  State<_TaskProofSheet> createState() => _TaskProofSheetState();
}

class _TaskProofSheetState extends State<_TaskProofSheet> {
  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<TimesheetViewModel>();
    final matches = viewModel.tasks
        .where((item) => item.id == widget.task.id)
        .toList();
    final task = matches.isEmpty ? widget.task : matches.first;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      task.name,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: task.isCompleted
                          ? AppColors.success.withValues(alpha: 0.12)
                          : AppColors.warning.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      task.isCompleted
                          ? AppStrings.taskCompletedLabel
                          : AppStrings.taskPendingLabel,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: task.isCompleted
                            ? AppColors.success
                            : AppColors.warning,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${AppStrings.shortDate(task.assignedDate)} · '
                '${task.hour.toString().padLeft(2, '0')}:'
                '${task.minute.toString().padLeft(2, '0')}',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                AppStrings.taskInstructionsLabel,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                task.instructions,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              if (!task.isCompleted) ...[
                const Text(
                  AppStrings.taskProofLabel,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                UploadBox(
                  filePath: viewModel.proofPreviewPath,
                  icon: Icons.image_outlined,
                  title: AppStrings.taskProofLabel,
                  hint: AppStrings.taskProofHint,
                  onTap: _pickProof,
                ),
                const SizedBox(height: 16),
                _submitButton(viewModel),
              ] else ...[
                const Row(
                  children: [
                    Icon(Icons.verified, color: AppColors.success, size: 20),
                    SizedBox(width: 8),
                    Text(
                      AppStrings.proofSubmittedMessage,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickProof() async {
    final viewModel = context.read<TimesheetViewModel>();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      backgroundColor: AppColors.surface,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  AppStrings.photoSourceTitle,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(
                Icons.photo_camera_outlined,
                color: AppColors.primary,
              ),
              title: const Text(
                AppStrings.cameraActionLabel,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              onTap: () => Navigator.of(context).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(
                Icons.photo_library_outlined,
                color: AppColors.primary,
              ),
              title: const Text(
                AppStrings.galleryActionLabel,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              onTap: () => Navigator.of(context).pop(ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (source == null) {
      return;
    }
    await viewModel.pickProofImage(source: source);
  }

  Widget _submitButton(TimesheetViewModel viewModel) {
    return SizedBox(
      height: 50,
      child: ElevatedButton.icon(
        onPressed: viewModel.isSubmitting ? null : () => _submit(viewModel),
        icon: viewModel.isSubmitting
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.upload_file, size: 20),
        label: const Text(
          AppStrings.submitProofButton,
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  Future<void> _submit(TimesheetViewModel viewModel) async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final success = await viewModel.submitProof(widget.task);
    if (!success && mounted) {
      final error = viewModel.errorMessage;
      messenger.showSnackBar(
        SnackBar(content: Text(error ?? AppStrings.proofPickError)),
      );
      return;
    }
    if (mounted) {
      navigator.pop();
      messenger.showSnackBar(
        const SnackBar(content: Text(AppStrings.proofSubmittedMessage)),
      );
    }
  }
}
