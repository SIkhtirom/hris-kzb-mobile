import 'dart:async';

import 'package:image_picker/image_picker.dart';

import '../core/constants/app_strings.dart';
import '../data/models/timesheet_task.dart';
import '../data/repositories/timesheet_repository.dart';
import '../data/remote/auth_remote_data_source.dart';
import 'base_viewmodel.dart';

class TimesheetViewModel extends BaseViewModel {
  final TimesheetRepository _repository;

  DateTime _selectedDate = DateTime.now();
  List<TimesheetTask> _tasks = <TimesheetTask>[];
  String? _proofPreviewPath;
  bool _isSubmitting = false;

  TimesheetViewModel({required this._repository});

  DateTime get selectedDate => _selectedDate;
  List<TimesheetTask> get tasks => List.unmodifiable(_tasks);
  String? get proofPreviewPath => _proofPreviewPath;
  bool get isSubmitting => _isSubmitting;

  Future<void> loadTasks() async {
    setLoading(true);
    setError(null);
    try {
      _tasks = await _repository.fetchTasks(_selectedDate);
      setError(null);
      setLoading(false);
    } on TimeoutException {
      setError(AppStrings.poorConnectionMessage);
      setLoading(false);
    } catch (_) {
      setError('Gagal memuat timesheet. Silakan coba lagi.');
      setLoading(false);
    }
  }

  Future<void> selectDate(DateTime date) async {
    _selectedDate = DateTime(date.year, date.month, date.day);
    notifyListeners();
    await loadTasks();
  }

  Future<String?> pickProofImage({required ImageSource source}) async {
    final picked = await ImagePicker().pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1600,
    );
    if (picked == null) {
      return null;
    }
    _proofPreviewPath = picked.path;
    notifyListeners();
    return _proofPreviewPath;
  }

  void setProofPreview(String path) {
    _proofPreviewPath = path;
    notifyListeners();
  }

  void cancelProof() {
    _proofPreviewPath = null;
    notifyListeners();
  }

  Future<bool> submitProof(TimesheetTask task, {String? proofPath}) async {
    final proof = proofPath ?? _proofPreviewPath;
    if (proof == null) {
      setError(AppStrings.proofPickError);
      return false;
    }
    if (_isSubmitting) {
      return false;
    }
    _isSubmitting = true;
    setError(null);
    notifyListeners();
    try {
      await _repository.completeTaskRemote(taskId: task.id, proofPath: proof);
      _proofPreviewPath = null;
      setError(null);
      await loadTasks();
      return true;
    } on ApiException catch (error) {
      setError(error.message);
      return false;
    } on TimeoutException {
      setError(AppStrings.poorConnectionMessage);
      return false;
    } catch (_) {
      setError(AppStrings.proofSubmitError);
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }
}
