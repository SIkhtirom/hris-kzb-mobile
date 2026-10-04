import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_strings.dart';
import '../../core/widgets/error_banner.dart';
import '../../core/widgets/smooth_loader.dart';
import '../../viewmodels/settings_viewmodel.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscureText = true;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final viewModel = context.read<SettingsViewModel>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final overlay = SmoothLoader.show(
      context,
      message: AppStrings.savingMessage,
    );

    final success = await viewModel.changePassword(
      currentPassword: _currentController.text,
      newPassword: _newController.text,
    );
    overlay.remove();
    if (!success) {
      return;
    }
    navigator.pop(true);
    messenger.showSnackBar(
      const SnackBar(content: Text(AppStrings.passwordChangedMessage)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<SettingsViewModel>();

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.changePasswordTitle)),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            if (viewModel.errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: ErrorBanner(
                  message: viewModel.errorMessage!,
                  onRetry: viewModel.load,
                ),
              ),
            TextFormField(
              controller: _currentController,
              obscureText: _obscureText,
              textInputAction: TextInputAction.next,
              decoration: _passwordDecoration(
                label: AppStrings.currentPasswordField,
                hint: AppStrings.currentPasswordHint,
                icon: Icons.lock_outline,
              ),
              validator: (value) => (value == null || value.isEmpty)
                  ? AppStrings.requiredCurrentPassword
                  : null,
            ),
            const SizedBox(height: 18),
            TextFormField(
              controller: _newController,
              obscureText: _obscureText,
              textInputAction: TextInputAction.next,
              decoration: _passwordDecoration(
                label: AppStrings.newPasswordField,
                hint: AppStrings.newPasswordHint,
                icon: Icons.password_outlined,
              ),
              validator: (value) => (value == null || value.length < 6)
                  ? AppStrings.invalidPasswordLength
                  : null,
            ),
            const SizedBox(height: 18),
            TextFormField(
              controller: _confirmController,
              obscureText: _obscureText,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _submit(),
              decoration: _passwordDecoration(
                label: AppStrings.confirmNewPasswordField,
                hint: AppStrings.confirmNewPasswordHint,
                icon: Icons.verified_user_outlined,
              ),
              validator: (value) => value != _newController.text
                  ? AppStrings.invalidConfirmPassword
                  : null,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: viewModel.isSaving ? null : () => _submit(),
              child: const Text(AppStrings.saveButton),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _passwordDecoration({
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon),
      suffixIcon: IconButton(
        icon: Icon(
          _obscureText
              ? Icons.visibility_outlined
              : Icons.visibility_off_outlined,
        ),
        onPressed: () => setState(() => _obscureText = !_obscureText),
      ),
    );
  }
}
