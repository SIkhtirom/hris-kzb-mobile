import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/error_banner.dart';
import '../../core/widgets/status_badge.dart';
import '../../data/models/reimbursement_claim.dart';
import '../../viewmodels/reimbursement_viewmodel.dart';
import 'reimbursement_form_screen.dart';

class ReimbursementListScreen extends StatefulWidget {
  const ReimbursementListScreen({super.key});

  @override
  State<ReimbursementListScreen> createState() =>
      _ReimbursementListScreenState();
}

class _ReimbursementListScreenState extends State<ReimbursementListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReimbursementViewModel>().loadClaims();
    });
  }

  Future<void> _openForm() async {
    final viewModel = context.read<ReimbursementViewModel>();
    final submitted = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(builder: (_) => const ReimbursementFormScreen()),
    );
    if (submitted == true) {
      await viewModel.loadClaims();
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ReimbursementViewModel>();

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.reimbursementTitle)),
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
                onRetry: viewModel.loadClaims,
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: _totalCard(amount: viewModel.totalPendingAmount),
          ),
          const SizedBox(height: 16),
          _filterChips(
            activeFilter: viewModel.activeFilter,
            pendingCount: viewModel.pendingCount,
            approvedCount: viewModel.approvedCount,
            rejectedCount: viewModel.rejectedCount,
            onSelected: viewModel.setFilter,
          ),
          const SizedBox(height: 4),
          Expanded(child: _claimsList(viewModel)),
        ],
      ),
    );
  }

  Widget _totalCard({required double amount}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.account_balance_wallet,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.totalPendingAmountLabel,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  AppStrings.formatCurrency(amount),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _claimsList(ReimbursementViewModel viewModel) {
    if (viewModel.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (viewModel.displayedClaims.isEmpty) {
      return const EmptyState(
        icon: Icons.receipt_long,
        message: AppStrings.emptyClaims,
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      itemCount: viewModel.displayedClaims.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) =>
          _claimCard(viewModel.displayedClaims[index]),
    );
  }

  Widget _filterChips({
    required ClaimStatus? activeFilter,
    required int pendingCount,
    required int approvedCount,
    required int rejectedCount,
    required ValueChanged<ClaimStatus?> onSelected,
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
            selected: activeFilter == ClaimStatus.pending,
            onSelected: () => onSelected(ClaimStatus.pending),
          ),
          const SizedBox(width: 8),
          _filterChip(
            label: '${AppStrings.approvedLabel} ($approvedCount)',
            selected: activeFilter == ClaimStatus.approved,
            onSelected: () => onSelected(ClaimStatus.approved),
          ),
          const SizedBox(width: 8),
          _filterChip(
            label: '${AppStrings.rejectedLabel} ($rejectedCount)',
            selected: activeFilter == ClaimStatus.rejected,
            onSelected: () => onSelected(ClaimStatus.rejected),
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

  Widget _claimCard(ReimbursementClaim claim) {
    final (icon, color) = switch (claim.category) {
      ExpenseCategory.material => (
        Icons.inventory_2_outlined,
        const Color(0xFF8D6E63),
      ),
      ExpenseCategory.transport => (
        Icons.directions_car_outlined,
        AppColors.primary,
      ),
      ExpenseCategory.meals => (
        Icons.restaurant_outlined,
        AppColors.safetyOrange,
      ),
      ExpenseCategory.other => (
        Icons.category_outlined,
        const Color(0xFF7B4FA6),
      ),
    };
    final badge = switch (claim.status) {
      ClaimStatus.pending => const StatusBadge.pending(),
      ClaimStatus.approved => const StatusBadge.approved(),
      ClaimStatus.rejected => const StatusBadge.rejected(),
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
                        AppStrings.formatCurrency(claim.amount),
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        AppStrings.expenseCategoryLabel(claim.category),
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
            if (claim.notes.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                claim.notes,
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
                    '${AppStrings.fullDate(claim.submittedAt)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                if (claim.receiptFileName != null) ...[
                  const Icon(
                    Icons.attach_file,
                    size: 15,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 110),
                    child: Text(
                      claim.receiptFileName!,
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
