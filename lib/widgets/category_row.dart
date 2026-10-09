import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../core/utils/category_icons.dart';
import '../models/category.dart';

class CategoryRow extends StatelessWidget {
  final List<ProductCategory> categories;
  final String? selectedCategoryName;
  final void Function(String? categoryName) onSelect;
  final void Function(String categoryName)? onLongPress;

  const CategoryRow({
    super.key,
    required this.categories,
    required this.selectedCategoryName,
    required this.onSelect,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 92,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        itemCount: categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.md),
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = category.name == selectedCategoryName;

          return GestureDetector(
            onTap: () => onSelect(isSelected ? null : category.name),
            onLongPress: () => onLongPress?.call(category.name),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.9, end: isSelected ? 1.08 : 1.0),
              duration: const Duration(milliseconds: 200),
              builder: (context, scale, child) =>
                  Transform.scale(scale: scale, child: child),
              child: SizedBox(
                width: 68,
                child: Column(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 260),
                      curve: Curves.easeOutBack,
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: isSelected ? AppColors.primaryGradient : null,
                        color: isSelected ? null : AppColors.surface,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        border: Border.all(
                          color: isSelected
                              ? Colors.transparent
                              : AppColors.border,
                        ),
                        boxShadow: isSelected
                            ? AppShadows.colored(AppColors.primary, alpha: 0.35)
                            : AppShadows.soft,
                      ),
                      child: Icon(
                        categoryIconFor(category.icon),
                        color: isSelected
                            ? Colors.white
                            : AppColors.textSecondary,
                        size: 26,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      category.name,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isSelected
                            ? FontWeight.w800
                            : FontWeight.w500,
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
