import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/widgets/error_banner.dart';
import '../../core/widgets/record_photo.dart';
import '../../core/widgets/smooth_loader.dart';
import '../../viewmodels/dashboard_viewmodel.dart';
import '../../viewmodels/settings_viewmodel.dart';
import 'change_password_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _dateOfBirthController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _synced = false;
  DateTime? _dateOfBirth;
  SettingsViewModel? _viewModel;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _viewModel = context.read<SettingsViewModel>();
        _viewModel!.addListener(_syncFromModel);
        _viewModel!.load();
      }
    });
  }

  @override
  void dispose() {
    _viewModel?.removeListener(_syncFromModel);
    _nameController.dispose();
    _dateOfBirthController.dispose();
    _currentPasswordController.dispose();
    super.dispose();
  }

  void _syncFromModel() {
    if (_synced) {
      return;
    }
    final user = _viewModel?.user;
    if (user == null) {
      return;
    }
    _synced = true;
    _nameController.text = user.name;
    _dateOfBirth = user.dateOfBirth;
    _dateOfBirthController.text = user.dateOfBirth == null
        ? ''
        : AppStrings.shortDate(user.dateOfBirth!);
    _currentPasswordController.text = user.password;
    setState(() {});
  }

  Future<void> _pickProfilePicture() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 800,
      maxHeight: 800,
    );
    if (picked != null) {
      if (!mounted) {
        return;
      }
      await context.read<SettingsViewModel>().stageProfilePicture(picked.path);
    }
  }

  Future<void> _pickDateOfBirth() async {
    final now = DateTime.now();
    final initial = _dateOfBirth ?? DateTime(now.year - 30, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 100, 1, 1),
      lastDate: DateTime(now.year, now.month, now.day),
      helpText: AppStrings.dateOfBirthField,
    );
    if (picked != null) {
      setState(() {
        _dateOfBirth = picked;
        _dateOfBirthController.text = AppStrings.shortDate(picked);
      });
    }
  }

  Future<void> _openChangePassword() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const ChangePasswordScreen()),
    );
    if (mounted) {
      context.read<SettingsViewModel>().load();
    }
  }

  Future<void> _save() async {
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

    final success = await viewModel.save(
      name: _nameController.text,
      dateOfBirth: _dateOfBirth,
      currentPassword: _currentPasswordController.text,
    );
    overlay.remove();
    if (!success) {
      return;
    }
    if (mounted) {
      await context.read<DashboardViewModel>().refreshUser();
    }
    navigator.pop(true);
    messenger.showSnackBar(
      const SnackBar(content: Text(AppStrings.settingsSavedMessage)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<SettingsViewModel>();
    final globalUser = context.watch<DashboardViewModel>().user;
    final path = viewModel.profilePicturePath ?? globalUser?.profilePicturePath;
    final initial = (globalUser?.name.isNotEmpty ?? false)
        ? globalUser!.name[0]
        : 'K';

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.profileLabel)),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
          children: [
            if (viewModel.errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: ErrorBanner(
                  message: viewModel.errorMessage!,
                  onRetry: viewModel.load,
                ),
              ),
            Center(
              child: Column(
                children: [
                  Stack(
                    children: [
                      SizedBox(
                        width: 96,
                        height: 96,
                        child: ClipOval(
                          child: RecordPhoto(
                            path: path,
                            width: 96,
                            height: 96,
                            fallback: Container(
                              color: AppColors.primary.withValues(alpha: 0.14),
                              child: Center(
                                child: Text(
                                  initial,
                                  style: const TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            size: 15,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: _pickProfilePicture,
                    icon: const Icon(Icons.photo_library_outlined, size: 18),
                    label: const Text(AppStrings.changePhotoLabel),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _sectionLabel(AppStrings.profileSectionTitle),
            const SizedBox(height: 10),
            TextFormField(
              controller: _nameController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: AppStrings.nameField,
                hintText: AppStrings.nameField,
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: (value) => (value == null || value.trim().isEmpty)
                  ? AppStrings.invalidName
                  : null,
            ),
            const SizedBox(height: 18),
            TextFormField(
              controller: _dateOfBirthController,
              readOnly: true,
              onTap: _pickDateOfBirth,
              decoration: const InputDecoration(
                labelText: AppStrings.dateOfBirthField,
                hintText: AppStrings.dateOfBirthHint,
                prefixIcon: Icon(Icons.calendar_today_outlined),
                suffixIcon: Icon(Icons.arrow_drop_down),
              ),
              validator: (value) => (value == null || value.isEmpty)
                  ? AppStrings.invalidDateOfBirth
                  : null,
            ),
            const SizedBox(height: 18),
            TextFormField(
              controller: _currentPasswordController,
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _save(),
              decoration: InputDecoration(
                labelText: AppStrings.currentPasswordField,
                hintText: AppStrings.currentPasswordHint,
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              validator: (value) => (value == null || value.isEmpty)
                  ? AppStrings.requiredCurrentPassword
                  : null,
            ),
            const SizedBox(height: 24),
            _changePasswordTile(),
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
              onPressed: viewModel.isSaving ? null : () => _save(),
              child: const Text(AppStrings.saveButton),
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
      ),
    );
  }

  Widget _changePasswordTile() {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        onTap: _openChangePassword,
        leading: const Icon(Icons.lock_reset, color: AppColors.primary),
        title: const Text(
          AppStrings.changePasswordTitle,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        trailing: const Icon(
          Icons.chevron_right,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}
