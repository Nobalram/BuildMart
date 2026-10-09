import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

import '../../core/theme/app_theme.dart';
import '../../core/services/location_service.dart';
import '../../models/address.dart';
import '../../providers/auth_provider.dart';
import '../../providers/checkout_provider.dart';
import '../../widgets/app_button.dart';

class AddAddressScreen extends ConsumerStatefulWidget {
  final Address? existingAddress;
  const AddAddressScreen({super.key, this.existingAddress});

  @override
  ConsumerState<AddAddressScreen> createState() => _AddAddressScreenState();
}

class _AddAddressScreenState extends ConsumerState<AddAddressScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _pincodeController = TextEditingController();
  String _label = 'Home';
  bool _isDefault = false;
  bool _isSaving = false;
  bool _isLocating = false;
  double? _latitude;
  double? _longitude;

  static const _labelIcons = {
    'Home': Icons.home_outlined,
    'Work': Icons.work_outline,
    'Site': Icons.construction_outlined,
    'Other': Icons.place_outlined,
  };

  bool get _isEditing => widget.existingAddress != null;

  @override
  void initState() {
    super.initState();
    final a = widget.existingAddress;
    if (a != null) {
      _label = a.label;
      _nameController.text = a.fullName;
      _phoneController.text = a.phoneNumber.replaceFirst('+91', '');
      _addressController.text = a.addressLine;
      _cityController.text = a.city;
      _stateController.text = a.state;
      _pincodeController.text = a.pincode;
      _isDefault = a.isDefault;
      _latitude = a.latitude;
      _longitude = a.longitude;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _isLocating = true);
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permission denied.')),
          );
        }
        return;
      }

      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          // Shows Android's native one-tap "Turn on Location?" dialog
          // instead of just telling the person to go do it themselves.
          await LocationService.ensureLocationEnabled(context);
        }
        final nowEnabled = await Geolocator.isLocationServiceEnabled();
        if (!nowEnabled) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Location services are still off.')),
            );
          }
          return;
        }
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
        ),
      );

      final geocoding = Geocoding();
      final placemarks = await geocoding.placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isEmpty) return;
      final place = placemarks.first;

      setState(() {
        final parts = <String>[
          if (place.street != null && place.street!.isNotEmpty) place.street!,
          if (place.subLocality != null && place.subLocality!.isNotEmpty)
            place.subLocality!,
        ];
        _addressController.text = parts.join(', ');
        _cityController.text = place.locality ?? '';
        _stateController.text = place.administrativeArea ?? '';
        _pincodeController.text = place.postalCode ?? '';
        _latitude = position.latitude;
        _longitude = position.longitude;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location filled — please review before saving.'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not fetch location: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  /// If we don't already have coordinates (user typed the address by
  /// hand instead of using GPS), try to look them up from the typed
  /// text so the distance-based transport fee still works.
  Future<void> _ensureCoordinates() async {
    if (_latitude != null && _longitude != null) return;
    try {
      final query =
          '${_addressController.text}, ${_cityController.text}, ${_stateController.text} ${_pincodeController.text}';
      final geocoding = Geocoding();
      final locations = await geocoding.locationFromAddress(query);
      if (locations.isNotEmpty) {
        _latitude = locations.first.latitude;
        _longitude = locations.first.longitude;
      }
    } catch (_) {
      // Non-fatal — transport fee falls back gracefully if coordinates are missing.
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    await _ensureCoordinates();

    final uid = ref.read(authStateProvider).value?.uid;
    if (uid == null) return;

    final address = Address(
      id: widget.existingAddress?.id ?? '',
      label: _label,
      fullName: _nameController.text.trim(),
      phoneNumber: '+91${_phoneController.text.trim()}',
      addressLine: _addressController.text.trim(),
      city: _cityController.text.trim(),
      state: _stateController.text.trim(),
      pincode: _pincodeController.text.trim(),
      isDefault: _isDefault,
      latitude: _latitude,
      longitude: _longitude,
      createdAt: widget.existingAddress?.createdAt ?? DateTime.now(),
    );

    if (_isEditing) {
      await ref
          .read(addressRepositoryProvider)
          .updateAddress(uid, widget.existingAddress!.id, address);
    } else {
      await ref.read(addressRepositoryProvider).addAddress(uid, address);
    }

    if (!mounted) return;
    Navigator.pop(context);
  }

  InputDecoration _decoration(String hint, IconData icon) {
    return InputDecoration(hintText: hint, prefixIcon: Icon(icon, size: 20));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Edit Address' : 'Add Address')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            InkWell(
              onTap: _isLocating ? null : _useCurrentLocation,
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    _isLocating
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2.2),
                          )
                        : const Icon(
                            Icons.my_location,
                            color: AppColors.primary,
                            size: 20,
                          ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        _isLocating
                            ? 'Fetching your location...'
                            : 'Use my current location',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    if (!_isLocating)
                      const Icon(
                        Icons.chevron_right,
                        color: AppColors.primary,
                        size: 20,
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Address Type',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: 8,
              children: ['Home', 'Work', 'Site', 'Other'].map((label) {
                final selected = _label == label;
                return ChoiceChip(
                  label: Text(label),
                  avatar: Icon(
                    _labelIcons[label],
                    size: 16,
                    color: selected ? Colors.white : AppColors.textSecondary,
                  ),
                  selected: selected,
                  selectedColor: AppColors.primary,
                  labelStyle: TextStyle(
                    color: selected ? Colors.white : AppColors.textPrimary,
                  ),
                  onSelected: (_) => setState(() => _label = label),
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Contact Details',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            TextFormField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              decoration: _decoration('Full Name', Icons.person_outline),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              maxLength: 10,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: const TextStyle(letterSpacing: 1),
              decoration: InputDecoration(
                counterText: '',
                hintText: '98765 43210',
                prefixIcon: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  alignment: Alignment.center,
                  width: 64,
                  child: const Text(
                    '🇮🇳 +91',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Required';
                if (v.trim().length != 10) {
                  return 'Enter a valid 10-digit number';
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Address Details',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            TextFormField(
              controller: _addressController,
              maxLines: 2,
              decoration: _decoration(
                'House No, Street, Area',
                Icons.home_outlined,
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
              onChanged: (_) {
                // Manual edits invalidate any previously captured GPS point.
                _latitude = null;
                _longitude = null;
              },
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _cityController,
                    decoration: _decoration(
                      'City',
                      Icons.location_city_outlined,
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: TextFormField(
                    controller: _stateController,
                    decoration: _decoration('State', Icons.map_outlined),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _pincodeController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: _decoration(
                'Pincode',
                Icons.pin_drop_outlined,
              ).copyWith(counterText: ''),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Required';
                if (v.trim().length != 6) {
                  return 'Enter a valid 6-digit pincode';
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.md),
            Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: CheckboxListTile(
                title: const Text('Set as default address'),
                secondary: const Icon(
                  Icons.star_outline,
                  color: AppColors.primary,
                ),
                value: _isDefault,
                activeColor: AppColors.primary,
                controlAffinity: ListTileControlAffinity.trailing,
                onChanged: (value) =>
                    setState(() => _isDefault = value ?? false),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            AppButton(
              label: _isEditing ? 'Save Changes' : 'Save Address',
              isLoading: _isSaving,
              onPressed: _save,
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }
}
