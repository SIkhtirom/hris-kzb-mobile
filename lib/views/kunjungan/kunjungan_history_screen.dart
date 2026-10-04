import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/widgets/error_banner.dart';
import '../../data/models/kunjungan_record.dart';
import '../../viewmodels/kunjungan_viewmodel.dart';

enum _KunjunganFilter { all, start, end }

class KunjunganHistoryScreen extends StatefulWidget {
  const KunjunganHistoryScreen({super.key});

  @override
  State<KunjunganHistoryScreen> createState() => _KunjunganHistoryScreenState();
}

class _KunjunganHistoryScreenState extends State<KunjunganHistoryScreen> {
  _KunjunganFilter _filter = _KunjunganFilter.all;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<KunjunganViewModel>().loadHistory();
    });
  }

  List<KunjunganRecord> _visibleRecords(KunjunganViewModel viewModel) {
    switch (_filter) {
      case _KunjunganFilter.start:
        return viewModel.historyRecords
            .where((r) => r.mode == KunjunganMode.start)
            .toList();
      case _KunjunganFilter.end:
        return viewModel.historyRecords
            .where((r) => r.mode == KunjunganMode.end)
            .toList();
      case _KunjunganFilter.all:
        return viewModel.historyRecords;
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<KunjunganViewModel>();
    final records = _visibleRecords(viewModel);

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.kunjunganHistoryTitle)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: SegmentedButton<_KunjunganFilter>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(
                  value: _KunjunganFilter.all,
                  label: Text(AppStrings.filterAll),
                ),
                ButtonSegment(
                  value: _KunjunganFilter.start,
                  label: Text(AppStrings.startVisitCard),
                ),
                ButtonSegment(
                  value: _KunjunganFilter.end,
                  label: Text(AppStrings.endVisitCard),
                ),
              ],
              selected: {_filter},
              onSelectionChanged: (selection) {
                setState(() => _filter = selection.first);
              },
            ),
          ),
          if (viewModel.errorMessage != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: ErrorBanner(
                message: viewModel.errorMessage!,
                onRetry: viewModel.loadHistory,
              ),
            ),
          Expanded(
            child: viewModel.isHistoryLoading
                ? const Center(child: CircularProgressIndicator())
                : records.isEmpty
                ? _emptyState()
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    itemCount: records.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) =>
                        _historyCard(records[index]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _historyCard(KunjunganRecord record) {
    final isStart = record.mode == KunjunganMode.start;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isStart
                        ? AppColors.primary.withValues(alpha: 0.12)
                        : AppColors.safetyOrange.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isStart
                        ? AppStrings.startVisitCard
                        : AppStrings.endVisitCard,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isStart
                          ? AppColors.primaryDark
                          : AppColors.safetyOrange,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  record.timeLabel,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              record.clientName,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            if (record.notes.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                record.notes,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(
                  Icons.place_outlined,
                  size: 14,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    record.address,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
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
              Icons.location_on_outlined,
              size: 42,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            AppStrings.emptyKunjungans,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
