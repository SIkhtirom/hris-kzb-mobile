import 'dart:async';

import '../core/constants/app_strings.dart';
import '../data/models/reimbursement_claim.dart';
import '../data/repositories/reimbursement_repository.dart';
import '../data/remote/auth_remote_data_source.dart';
import 'base_viewmodel.dart';

class ReimbursementViewModel extends BaseViewModel {
  final ReimbursementRepository _reimbursementRepository;

  List<ReimbursementClaim> _allClaims = [];
  List<ReimbursementClaim> _displayedClaims = [];
  ClaimStatus? _activeFilter;
  bool _isSubmitting = false;

  ReimbursementViewModel({required this._reimbursementRepository});

  bool get isSubmitting => _isSubmitting;
  ClaimStatus? get activeFilter => _activeFilter;
  List<ReimbursementClaim> get displayedClaims =>
      List.unmodifiable(_displayedClaims);

  int get pendingCount => _countWith(ClaimStatus.pending);
  int get approvedCount => _countWith(ClaimStatus.approved);
  int get rejectedCount => _countWith(ClaimStatus.rejected);

  double get totalPendingAmount {
    return _allClaims
        .where((c) => c.status == ClaimStatus.pending)
        .fold<double>(0, (sum, c) => sum + c.amount);
  }

  int _countWith(ClaimStatus status) {
    return _allClaims.where((c) => c.status == status).length;
  }

  Future<void> loadClaims() async {
    setLoading(true);
    setError(null);
    try {
      _allClaims = await _reimbursementRepository.fetchClaims();
      _applyFilter();
      setError(null);
      setLoading(false);
    } on TimeoutException {
      setError(AppStrings.poorConnectionMessage);
      setLoading(false);
    } catch (_) {
      setError('Gagal memuat pengajuan reimburse. Silakan coba lagi.');
      setLoading(false);
    }
  }

  void setFilter(ClaimStatus? status) {
    _activeFilter = status;
    _applyFilter();
    notifyListeners();
  }

  void _applyFilter() {
    if (_activeFilter == null) {
      _displayedClaims = _allClaims;
    } else {
      _displayedClaims = _allClaims
          .where((c) => c.status == _activeFilter)
          .toList();
    }
  }

  Future<bool> submitClaim({
    required double amount,
    required ExpenseCategory category,
    required String notes,
    required String activityName,
    required String sellerName,
    required DateTime expenseDate,
    String currency = 'IDR',
    String? receiptFileName,
  }) async {
    if (_isSubmitting) {
      return false;
    }
    _isSubmitting = true;
    setError(null);
    notifyListeners();
    try {
      await _reimbursementRepository.postClaim(
        amount: amount,
        activityName: activityName,
        category: category,
        expenseDate: expenseDate,
        currency: currency,
        sellerName: sellerName,
        notes: notes,
        receiptPath: receiptFileName,
      );
      _allClaims = await _reimbursementRepository.fetchClaims();
      _applyFilter();
      setError(null);
      return true;
    } on ApiException catch (error) {
      setError(error.message);
      return false;
    } on TimeoutException {
      setError(AppStrings.poorConnectionMessage);
      return false;
    } catch (_) {
      setError('Gagal mengirim pengajuan. Silakan coba lagi.');
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }
}
