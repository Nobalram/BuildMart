import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/theme/app_theme.dart';

/// Opens a dialog that lets the user type an exact quantity instead of
/// tapping + / - repeatedly. Returns the chosen value (clamped to
/// [min]..[max]) or null when cancelled.
Future<int?> showQuantityInputDialog(
  BuildContext context, {
  required int initial,
  required int min,
  required int max,
  String? unit,
  String title = 'Enter quantity',
}) {
  return showDialog<int>(
    context: context,
    barrierDismissible: true,
    builder: (_) => QuantityInputDialog(
      initial: initial,
      min: min,
      max: max,
      unit: unit,
      title: title,
    ),
  );
}

class QuantityInputDialog extends StatefulWidget {
  final int initial;
  final int min;
  final int max;
  final String? unit;
  final String title;

  const QuantityInputDialog({
    super.key,
    required this.initial,
    required this.min,
    required this.max,
    this.unit,
    this.title = 'Enter quantity',
  });

  @override
  State<QuantityInputDialog> createState() => _QuantityInputDialogState();
}

class _QuantityInputDialogState extends State<QuantityInputDialog> {
  late final TextEditingController _controller;
  final _formKey = GlobalKey<FormState>();
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: '${widget.initial}');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _apply() {
    final raw = _controller.text.trim();
    final value = int.tryParse(raw);
    if (value == null || value < widget.min || value > widget.max) {
      setState(
        () => _error =
            'Enter a whole number between ${widget.min} and ${widget.max}',
      );
      return;
    }
    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      title: Text(
        widget.title,
        style: theme.textTheme.titleLarge,
        textAlign: TextAlign.center,
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _controller,
              autofocus: true,
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
              decoration: InputDecoration(
                hintText: '${widget.min} - ${widget.max}',
                suffixText: widget.unit,
                suffixStyle: theme.textTheme.bodySmall,
                errorText: _error,
                errorMaxLines: 2,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm + 2,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
              onFieldSubmitted: (_) => _apply(),
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              alignment: WrapAlignment.center,
              children: [
                for (final v in _quickValues())
                  ActionChip(
                    label: Text('$v'),
                    onPressed: () {
                      _controller.text = '$v';
                      setState(() => _error = null);
                    },
                  ),
              ],
            ),
          ],
        ),
      ),
      actionsAlignment: MainAxisAlignment.spaceBetween,
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(onPressed: _apply, child: const Text('Apply')),
      ],
    );
  }

  List<int> _quickValues() {
    final values = <int>{widget.min};
    if (widget.initial > widget.min && widget.initial <= widget.max) {
      values.add(widget.initial);
    }
    for (final v in [5, 10, 25, 50]) {
      if (v >= widget.min && v <= widget.max) values.add(v);
    }
    if (widget.max > widget.min && widget.max <= 1000) values.add(widget.max);
    final sorted = values.toList()..sort();
    return sorted.take(5).toList();
  }
}
