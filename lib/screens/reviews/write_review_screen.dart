import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/theme/app_theme.dart';
import '../../core/services/cloudinary_service.dart';
import '../../models/review.dart';
import '../../providers/auth_provider.dart';
import '../../providers/review_provider.dart';
import '../../widgets/app_button.dart';

class WriteReviewScreen extends ConsumerStatefulWidget {
  final String orderId;
  final String productId;
  final String productName;
  final String productImageUrl;
  final Review? existingReview;

  const WriteReviewScreen({
    super.key,
    required this.orderId,
    required this.productId,
    required this.productName,
    required this.productImageUrl,
    this.existingReview,
  });

  @override
  ConsumerState<WriteReviewScreen> createState() => _WriteReviewScreenState();
}

class _WriteReviewScreenState extends ConsumerState<WriteReviewScreen> {
  int _rating = 0;
  final _textController = TextEditingController();
  File? _newPhoto;
  String? _existingPhotoUrl;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingReview;
    if (existing != null) {
      _rating = existing.rating;
      _textController.text = existing.reviewText ?? '';
      _existingPhotoUrl = existing.photoUrl;
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked == null) return;
    setState(() {
      _newPhoto = File(picked.path);
      _existingPhotoUrl = null;
    });
  }

  Future<void> _submit() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a star rating.')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      String? photoUrl = _existingPhotoUrl;
      if (_newPhoto != null) {
        photoUrl = await CloudinaryService().uploadImage(_newPhoto!);
      }

      final uid = ref.read(authStateProvider).value?.uid;
      final profile = ref.read(currentUserProfileProvider).value;
      if (uid == null) return;

      await ref
          .read(reviewRepositoryProvider)
          .submitReview(
            productId: widget.productId,
            orderId: widget.orderId,
            buyerId: uid,
            buyerName: profile?.name ?? 'Buyer',
            rating: _rating,
            reviewText: _textController.text.trim().isEmpty
                ? null
                : _textController.text.trim(),
            photoUrl: photoUrl,
          );

      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not submit review: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingReview != null;

    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Edit Review' : 'Write a Review')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.sm),
                child: Image.network(
                  widget.productImageUrl,
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  widget.productName,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),

          Center(
            child: Column(
              children: [
                Text(
                  'How was this product?',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (i) {
                    final star = i + 1;
                    return IconButton(
                      onPressed: () => setState(() => _rating = star),
                      icon: Icon(
                        star <= _rating ? Icons.star : Icons.star_border,
                        color: AppColors.star,
                        size: 36,
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          Text(
            'Your Review (optional)',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _textController,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'Share details about quality, delivery, packaging...',
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          Text(
            'Add a Photo (optional)',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          GestureDetector(
            onTap: _pickPhoto,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.border),
              ),
              child: _newPhoto != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      child: Image.file(_newPhoto!, fit: BoxFit.cover),
                    )
                  : (_existingPhotoUrl != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            child: Image.network(
                              _existingPhotoUrl!,
                              fit: BoxFit.cover,
                            ),
                          )
                        : const Icon(
                            Icons.add_a_photo_outlined,
                            color: AppColors.textMuted,
                          )),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          AppButton(
            label: isEditing ? 'Update Review' : 'Submit Review',
            isLoading: _isSaving,
            onPressed: _submit,
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}
