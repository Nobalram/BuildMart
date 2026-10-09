import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

class StaticContentScreen extends StatelessWidget {
  final String title;
  final String content;

  const StaticContentScreen({
    super.key,
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Text(content, style: Theme.of(context).textTheme.bodyMedium),
      ),
    );
  }
}
