import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../models/address.dart';
import '../../providers/auth_provider.dart';
import '../../providers/checkout_provider.dart';
import '../../widgets/app_button.dart';
import '../checkout/add_address_screen.dart';

class AddressesScreen extends ConsumerWidget {
  const AddressesScreen({super.key});

  static const _labelIcons = {
    'Home': Icons.home_outlined,
    'Work': Icons.work_outline,
    'Site': Icons.construction_outlined,
    'Other': Icons.place_outlined,
  };

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Address address,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Address?'),
        content: Text('Remove "${address.label}" — ${address.formatted}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final uid = ref.read(authStateProvider).value?.uid;
      if (uid != null) {
        await ref
            .read(addressRepositoryProvider)
            .deleteAddress(uid, address.id);
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final addressesAsync = ref.watch(addressesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My Addresses')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const AddAddressScreen()));
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Address'),
      ),
      body: addressesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Could not load addresses: $e')),
        data: (addresses) {
          if (addresses.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.location_off_outlined,
                      size: 64,
                      color: AppColors.textMuted,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'No saved addresses',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Add an address to speed up checkout.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    AppButton(
                      label: 'Add Address',
                      icon: Icons.add,
                      width: 200,
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const AddAddressScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              88,
            ),
            itemCount: addresses.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, index) {
              final address = addresses[index];
              return Dismissible(
                key: ValueKey(address.id),
                direction: DismissDirection.endToStart,
                confirmDismiss: (_) async {
                  await _confirmDelete(context, ref, address);
                  return false; // repository stream removes it; we never let Dismissible do it itself
                },
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                  child: const Icon(Icons.delete_outline, color: Colors.white),
                ),
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _labelIcons[address.label] ?? Icons.place_outlined,
                          color: AppColors.primary,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  address.label,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium,
                                ),
                                if (address.isDefault) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary,
                                      borderRadius: BorderRadius.circular(
                                        AppRadius.sm,
                                      ),
                                    ),
                                    child: const Text(
                                      'DEFAULT',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              address.fullName,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            Text(
                              address.formatted,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            Text(
                              address.phoneNumber,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 20),
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  AddAddressScreen(existingAddress: address),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: AppColors.error,
                          size: 20,
                        ),
                        onPressed: () => _confirmDelete(context, ref, address),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
