import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../models/app_user.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_button.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  bool _isSaving = false;
  bool _initialized = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final user = ref.read(authServiceProvider).currentUser;
    final currentProfile = ref.read(currentUserProfileProvider).value;
    if (user == null || currentProfile == null) return;

    final updated = AppUser(
      uid: user.uid,
      phoneNumber: currentProfile.phoneNumber,
      name: _nameController.text.trim(),
      email: _emailController.text.trim().isEmpty
          ? null
          : _emailController.text.trim(),
      photoUrl: currentProfile.photoUrl,
      createdAt: currentProfile.createdAt,
    );

    await ref.read(userRepositoryProvider).createOrUpdateUser(updated);

    if (!mounted) return;
    setState(() => _isSaving = false);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(currentUserProfileProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (user) {
          if (!_initialized && user != null) {
            _nameController.text = user.name;
            _emailController.text = user.email ?? '';
            _initialized = true;
          }

          return Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  TextFormField(
                    controller: _nameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      hintText: 'Full Name',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Enter your name'
                        : null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    initialValue: user?.phoneNumber ?? '',
                    enabled: false,
                    decoration: const InputDecoration(
                      hintText: 'Phone Number',
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      hintText: 'Email (optional)',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return null;
                      final emailRegex = RegExp(
                        r'^[\w\.\-]+@[\w\-]+\.[a-zA-Z]{2,}$',
                      );
                      return emailRegex.hasMatch(v.trim())
                          ? null
                          : 'Enter a valid email';
                    },
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  AppButton(
                    label: 'Save Changes',
                    type: AppButtonType.gradient,
                    isLoading: _isSaving,
                    onPressed: _save,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
