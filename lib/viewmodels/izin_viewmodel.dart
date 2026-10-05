import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/constants/app_strings.dart';
import '../data/models/izin_record.dart';
import '../data/repositories/izin_repository.dart';
import '../data/remote/auth_remote_data_source.dart';
import 'base_viewmodel.dart';

class IzinViewModel extends BaseViewModel {
  final IzinRepository _izinRepository;

  List<IzinRecord> _allRecords = [];
  List<IzinRecord> _displayedRecords = [];
  IzinStatus? _activeFilter;
  bool _isSubmitting = false;

  IzinViewModel({required this._izinRepository});

  bool get isSubmitting => _isSubmitting;
  IzinStatus? get activeFilter => _activeFilter;
  List<IzinRecord> get displayedRecords => List.unmodifiable(_displayedRecords);

  int get pendingCount => _countWith(IzinStatus.pending);
  int get approvedCount => _countWith(IzinStatus.approved);
  int get rejectedCount => _countWith(IzinStatus.rejected);

  int _countWith(IzinStatus status) {
    return _allRecords.where((r) => r.status == status).length;
  }

  Future<void> loadIzins() async {
    setLoading(true);
    setError(null);
    try {
      _allRecords = await _izinRepository.fetchIzins();
      _applyFilter();
      setError(null);
      setLoading(false);
    } on TimeoutException {
      setError(AppStrings.poorConnectionMessage);
      setLoading(false);
    } catch (_) {
      setError('Gagal memuat data izin. Silakan coba lagi.');
      setLoading(false);
    }
  }

  void setFilter(IzinStatus? status) {
    _activeFilter = status;
    _applyFilter();
    notifyListeners();
  }

  void _applyFilter() {
    if (_activeFilter == null) {
      _displayedRecords = _allRecords;
    } else {
      _displayedRecords = _allRecords
          .where((r) => r.status == _activeFilter)
          .toList();
    }
  }

  Future<bool> submitIzin({
    required DateTime date,
    required IzinReason reason,
    required String notes,
    String? photoPath,
  }) async {
    if (_isSubmitting) {
      return false;
    }
    _isSubmitting = true;
    setError(null);
    notifyListeners();
    try {
      await _izinRepository.postIzin(
        date: date,
        reason: reason,
        notes: notes,
        photoPath: photoPath,
      );
      _allRecords = await _izinRepository.fetchIzins();
      _applyFilter();
      setError(null);
      return true;
    } on ApiException catch (error) {
      debugPrint('ERROR SUBMIT IZIN: ${error.message}');
      setError(error.message);
      return false;
    } on TimeoutException {
      debugPrint('ERROR SUBMIT IZIN: TimeoutException');
      setError(AppStrings.poorConnectionMessage);
      return false;
    } catch (error) {
      debugPrint('ERROR SUBMIT IZIN: $error');
      setError('Gagal mengirim izin. Silakan coba lagi.');
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }
}
