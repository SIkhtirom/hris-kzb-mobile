import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_strings.dart';
import '../../core/widgets/image_source_sheet.dart';
import '../../core/widgets/smooth_loader.dart';
import '../../core/widgets/upload_box.dart';
import '../../data/models/reimbursement_claim.dart';
import '../../viewmodels/reimbursement_viewmodel.dart';

class ReimbursementFormScreen extends StatefulWidget {
  const ReimbursementFormScreen({super.key});

  @override
  State<ReimbursementFormScreen> createState() =>
      _ReimbursementFormScreenState();
}

class _ReimbursementFormScreenState extends State<ReimbursementFormScreen> {
  static const int _maxAmountDigits = 12;
  static const List<String> _currencies = [AppStrings.idr, AppStrings.usd];

  final _formKey = GlobalKey<FormState>();
  final _activityController = TextEditingController();
  final _amountController = TextEditingController();
  final _sellerController = TextEditingController();
  final _notesController = TextEditingController();
  final _dateController = TextEditingController();
  ExpenseCategory? _category;
  DateTime? _expenseDate;
  String _currency = AppStrings.idr;
  String? _receiptPath;

  @override
  void initState() {
    super.initState();
    _expenseDate = DateTime.now();
    _dateController.text = AppStrings.fullDate(_expenseDate!);
  }

  @override
  void dispose() {
    _activityController.dispose();
    _amountController.dispose();
    _sellerController.dispose();
    _notesController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  Future<void> _pickReceipt() async {
    final path = await pickImageFilePath(context);
    if (path != null) {
      setState(() => _receiptPath = path);
    }
  }

  Future<void> _pickDate() async {
    final initial = _expenseDate ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(initial.year - 1),
      lastDate: initial.add(const Duration(days: 365)),
      helpText: AppStrings.reimbDateField,
    );
    if (picked != null) {
      setState(() {
        _expenseDate = picked;
        _dateController.text = AppStrings.fullDate(picked);
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final viewModel = context.read<ReimbursementViewModel>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final overlay = SmoothLoader.show(
      context,
      message: AppStrings.savingMessage,
    );

    final success = await viewModel.submitClaim(
      amount: _parseAmount(_amountController.text),
      category: _category!,
      notes: _notesController.text.trim(),
      activityName: _activityController.text.trim(),
      sellerName: _sellerController.text.trim(),
      expenseDate: _expenseDate!,
      currency: _currency,
      receiptFileName: _receiptPath,
    );
    overlay.remove();
    if (!success) {
      return;
    }
    navigator.pop(true);
    messenger.showSnackBar(
      const SnackBar(content: Text(AppStrings.claimSavedMessage)),
    );
  }

  double _parseAmount(String raw) {
    final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
    return double.parse(digits.isEmpty ? '0' : digits);
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ReimbursementViewModel>();

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.newClaimTitle)),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          children: [
            TextFormField(
              controller: _activityController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: AppStrings.reimbActivityField,
                hintText: AppStrings.reimbActivityHint,
                prefixIcon: Icon(Icons.stars_outlined),
              ),
              validator: (value) => (value == null || value.trim().isEmpty)
                  ? AppStrings.invalidActivity
                  : null,
            ),
            const SizedBox(height: 18),
            DropdownButtonFormField<ExpenseCategory>(
              initialValue: ExpenseCategory.values.contains(_category)
                  ? _category
                  : null,
              isExpanded: true,
              hint: const Text(AppStrings.selectCategoryHint),
              decoration: const InputDecoration(
                labelText: AppStrings.reimbCategoryField,
                prefixIcon: Icon(Icons.category_outlined),
              ),
              items: [
                for (final category in ExpenseCategory.values)
                  DropdownMenuItem(
                    value: category,
                    child: Text(
                      AppStrings.expenseCategoryLabel(category),
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
              ],
              onChanged: (value) => setState(() => _category = value),
              validator: (value) =>
                  value == null ? AppStrings.invalidCategory : null,
            ),
            const SizedBox(height: 18),
            TextFormField(
              controller: _dateController,
              readOnly: true,
              onTap: _pickDate,
              decoration: const InputDecoration(
                labelText: AppStrings.reimbDateField,
                prefixIcon: Icon(Icons.calendar_today_outlined),
                suffixIcon: Icon(Icons.arrow_drop_down),
              ),
            ),
            const SizedBox(height: 18),
            DropdownButtonFormField<String>(
              initialValue: _currencies.contains(_currency) ? _currency : null,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: AppStrings.reimbCurrencyField,
                prefixIcon: Icon(Icons.attach_money),
              ),
              items: [
                for (final option in _currencies)
                  DropdownMenuItem(
                    value: option,
                    child: Text(option, style: const TextStyle(fontSize: 16)),
                  ),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _currency = value);
                }
              },
            ),
            const SizedBox(height: 18),
            TextFormField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                _CurrencyDigitsFormatter(maxDigits: _maxAmountDigits),
              ],
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                labelText: '$_currency ${AppStrings.reimbAmountField}',
                hintText: AppStrings.reimbAmountHint,
                prefixIcon: const Icon(Icons.payments_outlined),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return AppStrings.invalidAmount;
                }
                return _parseAmount(value) <= 0
                    ? AppStrings.invalidAmount
                    : null;
              },
            ),
            const SizedBox(height: 18),
            TextFormField(
              controller: _sellerController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: AppStrings.reimbSellerField,
                hintText: AppStrings.reimbSellerHint,
                prefixIcon: Icon(Icons.store_outlined),
              ),
              validator: (value) => (value == null || value.trim().isEmpty)
                  ? AppStrings.invalidSeller
                  : null,
            ),
            const SizedBox(height: 18),
            TextFormField(
              controller: _notesController,
              maxLines: 3,
              maxLength: 200,
              decoration: const InputDecoration(
                labelText: AppStrings.reimbNotesField,
                hintText: AppStrings.reimbNotesHint,
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 6),
            UploadBox(
              filePath: _receiptPath,
              icon: Icons.upload_file,
              title: AppStrings.reimbEvidenceLabel,
              hint: AppStrings.reimbEvidenceHint,
              onTap: _pickReceipt,
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: viewModel.isSubmitting ? null : () => _submit(),
              child: const Text(AppStrings.submitProcessButton),
            ),
          ),
        ),
      ),
    );
  }
}

class _CurrencyDigitsFormatter extends TextInputFormatter {
  static final RegExp _nonDigits = RegExp(r'[^0-9]');
  static final NumberFormat _groupFormat = NumberFormat.decimalPattern('id');

  final int maxDigits;

  const _CurrencyDigitsFormatter({this.maxDigits = 12});

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var digits = newValue.text.replaceAll(_nonDigits, '');
    if (digits.length > maxDigits) {
      digits = digits.substring(0, maxDigits);
    }
    if (digits.isEmpty) {
      return TextEditingValue(
        text: '',
        selection: const TextSelection.collapsed(offset: 0),
      );
    }

    final selection = newValue.selection;
    final digitsBeforeCursor = selection.isValid
        ? newValue.text
              .substring(0, selection.baseOffset.clamp(0, newValue.text.length))
              .replaceAll(_nonDigits, '')
              .length
        : digits.length;

    final formatted = _groupFormat.format(int.parse(digits));

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(
        offset: _cursorOffsetForPrefix(formatted, digits, digitsBeforeCursor),
      ),
    );
  }

  int _cursorOffsetForPrefix(
    String formatted,
    String digits,
    int prefixDigits,
  ) {
    final consumed = digits.substring(0, prefixDigits);
    var matched = 0;
    var index = 0;
    while (matched < consumed.length && index < formatted.length) {
      if (formatted[index] == consumed[matched]) {
        matched++;
      }
      index++;
    }
    return index;
  }
}
