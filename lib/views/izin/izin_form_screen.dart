import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_strings.dart';
import '../../core/widgets/image_source_sheet.dart';
import '../../core/widgets/upload_box.dart';
import '../../data/models/izin_record.dart';
import '../../viewmodels/izin_viewmodel.dart';

class IzinFormScreen extends StatefulWidget {
  const IzinFormScreen({super.key});

  @override
  State<IzinFormScreen> createState() => _IzinFormScreenState();
}

class _IzinFormScreenState extends State<IzinFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _dateController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime? _date;
  IzinReason? _reason;
  String? _photoPath;

  @override
  void dispose() {
    _dateController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final initial = _date ?? now;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 1),
      lastDate: now.add(const Duration(days: 365)),
      helpText: AppStrings.izinDateField,
    );
    if (picked != null) {
      setState(() {
        _date = picked;
        _dateController.text = AppStrings.fullDate(picked);
      });
    }
  }

  Future<void> _pickPhoto() async {
    final path = await pickCameraPhotoPath();
    if (path != null) {
      setState(() => _photoPath = path);
    }
  }

  Future<void> _submit(BuildContext context) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final viewModel = context.read<IzinViewModel>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final success = await viewModel.submitIzin(
      date: _date!,
      reason: _reason!,
      notes: _notesController.text.trim(),
      photoPath: _photoPath,
    );
    if (!success) {
      return;
    }
    navigator.pop(true);
    messenger.showSnackBar(
      const SnackBar(content: Text(AppStrings.izinSavedMessage)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<IzinViewModel>();

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.newIzinTitle)),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(
              readOnly: true,
              controller: _dateController,
              onTap: _pickDate,
              decoration: const InputDecoration(
                labelText: AppStrings.izinDateField,
                hintText: AppStrings.izinDateHint,
                prefixIcon: Icon(Icons.calendar_today_outlined),
                suffixIcon: Icon(Icons.arrow_drop_down),
              ),
              validator: (_) => _date == null ? AppStrings.invalidDate : null,
            ),
            const SizedBox(height: 18),
            DropdownButtonFormField<IzinReason>(
              initialValue: IzinReason.values.contains(_reason)
                  ? _reason
                  : null,
              isExpanded: true,
              hint: const Text(AppStrings.selectReasonHint),
              decoration: const InputDecoration(
                labelText: AppStrings.izinReasonField,
                prefixIcon: Icon(Icons.receipt_long_outlined),
              ),
              items: [
                for (final reason in IzinReason.values)
                  DropdownMenuItem(
                    value: reason,
                    child: Text(
                      AppStrings.izinReasonLabel(reason),
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
              ],
              onChanged: (value) => setState(() => _reason = value),
              validator: (value) =>
                  value == null ? AppStrings.invalidReason : null,
            ),
            const SizedBox(height: 18),
            TextFormField(
              controller: _notesController,
              maxLines: 3,
              maxLength: 200,
              decoration: const InputDecoration(
                labelText: AppStrings.notesField,
                hintText: AppStrings.izinNotesHint,
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 6),
            UploadBox(
              filePath: _photoPath,
              icon: Icons.add_photo_alternate_outlined,
              title: AppStrings.izinPhotoTitle,
              hint: AppStrings.izinPhotoHint,
              onTap: _pickPhoto,
            ),
            const SizedBox(height: 28),
            SizedBox(
              height: 56,
              child: ElevatedButton.icon(
                onPressed: viewModel.isSubmitting
                    ? null
                    : () => _submit(context),
                icon: viewModel.isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send),
                label: const Text(AppStrings.izinSubmitButton),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
