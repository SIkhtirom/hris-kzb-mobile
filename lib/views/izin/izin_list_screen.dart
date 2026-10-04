import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/error_banner.dart';
import '../../core/widgets/status_badge.dart';
import '../../data/models/izin_record.dart';
import '../../viewmodels/izin_viewmodel.dart';
import 'izin_form_screen.dart';

class IzinListScreen extends StatefulWidget {
  const IzinListScreen({super.key});

  @override
  State<IzinListScreen> createState() => _IzinListScreenState();
}

class _IzinListScreenState extends State<IzinListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<IzinViewModel>().loadIzins();
    });
  }

  Future<void> _openForm() async {
    final viewModel = context.read<IzinViewModel>();
    final submitted = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(builder: (_) => const IzinFormScreen()),
    );
    if (submitted == true) {
      await viewModel.loadIzins();
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<IzinViewModel>();

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.izinTitle)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openForm,
        icon: const Icon(Icons.add),
        label: const Text(AppStrings.newClaimAction),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (viewModel.errorMessage != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: ErrorBanner(
                message: viewModel.errorMessage!,
                onRetry: viewModel.loadIzins,
              ),
            ),
          const SizedBox(height: 12),
          _filterChips(
            activeFilter: viewModel.activeFilter,
            pendingCount: viewModel.pendingCount,
            approvedCount: viewModel.approvedCount,
            rejectedCount: viewModel.rejectedCount,
            onSelected: viewModel.setFilter,
          ),
          const SizedBox(height: 8),
          Expanded(child: _izinsList(viewModel)),
        ],
      ),
    );
  }

  Widget _izinsList(IzinViewModel viewModel) {
    if (viewModel.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (viewModel.displayedRecords.isEmpty) {
      return const EmptyState(
        icon: Icons.event_note,
        message: AppStrings.emptyIzins,
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      itemCount: viewModel.displayedRecords.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) =>
          _izinCard(viewModel.displayedRecords[index]),
    );
  }

  Widget _filterChips({
    required IzinStatus? activeFilter,
    required int pendingCount,
    required int approvedCount,
    required int rejectedCount,
    required ValueChanged<IzinStatus?> onSelected,
  }) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _filterChip(
            label: AppStrings.filterAll,
            selected: activeFilter == null,
            onSelected: () => onSelected(null),
          ),
          const SizedBox(width: 8),
          _filterChip(
            label: '${AppStrings.pendingLabel} ($pendingCount)',
            selected: activeFilter == IzinStatus.pending,
            onSelected: () => onSelected(IzinStatus.pending),
          ),
          const SizedBox(width: 8),
          _filterChip(
            label: '${AppStrings.approvedLabel} ($approvedCount)',
            selected: activeFilter == IzinStatus.approved,
            onSelected: () => onSelected(IzinStatus.approved),
          ),
          const SizedBox(width: 8),
          _filterChip(
            label: '${AppStrings.rejectedLabel} ($rejectedCount)',
            selected: activeFilter == IzinStatus.rejected,
            onSelected: () => onSelected(IzinStatus.rejected),
          ),
        ],
      ),
    );
  }

  Widget _filterChip({
    required String label,
    required bool selected,
    required VoidCallback onSelected,
  }) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
      showCheckmark: false,
      selectedColor: AppColors.primary.withValues(alpha: 0.15),
      labelStyle: TextStyle(
        color: selected ? AppColors.primary : AppColors.textSecondary,
        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
      ),
      side: BorderSide(color: selected ? AppColors.primary : AppColors.border),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
    );
  }

  Widget _izinCard(IzinRecord record) {
    final (icon, color) = switch (record.reason) {
      IzinReason.sick => (Icons.medical_services_outlined, AppColors.danger),
      IzinReason.family => (Icons.family_restroom, AppColors.primary),
      IzinReason.other => (Icons.event_note, const Color(0xFF7B4FA6)),
    };
    final badge = switch (record.status) {
      IzinStatus.pending => const StatusBadge.pending(),
      IzinStatus.approved => const StatusBadge.approved(),
      IzinStatus.rejected => const StatusBadge.rejected(),
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.izinReasonLabel(record.reason),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        AppStrings.fullDate(record.date),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                badge,
              ],
            ),
            if (record.notes.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                record.notes,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textPrimary,
                  height: 1.4,
                ),
              ),
            ],
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(
                  Icons.schedule,
                  size: 15,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '${AppStrings.submittedLabel}: '
                    '${AppStrings.fullDate(record.createdAt)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                if (record.photoPath != null) ...[
                  const Icon(
                    Icons.photo_outlined,
                    size: 15,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 110),
                    child: Text(
                      AppStrings.fileNameFromPath(record.photoPath!),
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
