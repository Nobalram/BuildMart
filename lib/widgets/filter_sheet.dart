import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../models/category.dart';
import '../providers/search_provider.dart';
import 'app_button.dart';

class FilterSheet extends StatefulWidget {
  final ProductFilters initialFilters;
  final List<ProductCategory> categories;
  final void Function(ProductFilters) onApply;

  const FilterSheet({
    super.key,
    required this.initialFilters,
    required this.categories,
    required this.onApply,
  });

  @override
  State<FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<FilterSheet> {
  late RangeValues _priceRange;
  String? _category;
  double? _minRating;
  bool _inStockOnly = false;

  static const double _maxPossiblePrice = 5000;

  @override
  void initState() {
    super.initState();
    _priceRange = RangeValues(
      widget.initialFilters.minPrice ?? 0,
      widget.initialFilters.maxPrice ?? _maxPossiblePrice,
    );
    _category = widget.initialFilters.category;
    _minRating = widget.initialFilters.minRating;
    _inStockOnly = widget.initialFilters.inStockOnly;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Filters',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _priceRange = const RangeValues(0, _maxPossiblePrice);
                        _category = null;
                        _minRating = null;
                        _inStockOnly = false;
                      });
                    },
                    child: const Text('Reset'),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              Text(
                'Price Range',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              RangeSlider(
                values: _priceRange,
                min: 0,
                max: _maxPossiblePrice,
                divisions: 50,
                labels: RangeLabels(
                  '₹${_priceRange.start.round()}',
                  '₹${_priceRange.end.round()}',
                ),
                activeColor: AppColors.primary,
                onChanged: (values) => setState(() => _priceRange = values),
              ),
              const SizedBox(height: AppSpacing.md),

              Text('Category', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: widget.categories.map((cat) {
                  final selected = _category == cat.name;
                  return ChoiceChip(
                    label: Text(cat.name),
                    selected: selected,
                    selectedColor: AppColors.primaryLight,
                    onSelected: (isSelected) {
                      setState(() => _category = isSelected ? cat.name : null);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: AppSpacing.md),

              Text(
                'Minimum Rating',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: 8,
                children: [3.0, 3.5, 4.0, 4.5].map((rating) {
                  final selected = _minRating == rating;
                  return ChoiceChip(
                    label: Text('$rating ★ & up'),
                    selected: selected,
                    selectedColor: AppColors.primaryLight,
                    onSelected: (isSelected) {
                      setState(() => _minRating = isSelected ? rating : null);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: AppSpacing.md),

              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('In stock only'),
                value: _inStockOnly,
                activeThumbColor: AppColors.primary,
                onChanged: (value) => setState(() => _inStockOnly = value),
              ),
              const SizedBox(height: AppSpacing.lg),

              AppButton(
                label: 'Apply Filters',
                onPressed: () {
                  widget.onApply(
                    ProductFilters(
                      minPrice: _priceRange.start > 0
                          ? _priceRange.start
                          : null,
                      maxPrice: _priceRange.end < _maxPossiblePrice
                          ? _priceRange.end
                          : null,
                      category: _category,
                      minRating: _minRating,
                      inStockOnly: _inStockOnly,
                    ),
                  );
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
