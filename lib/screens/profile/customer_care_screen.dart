import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_theme.dart';

class CustomerCareScreen extends StatelessWidget {
  const CustomerCareScreen({super.key});

  Future<void> _call(BuildContext context) async {
    final uri = Uri.parse('tel:+910000000000');
    if (!await launchUrl(uri)) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Could not open dialer.')));
      }
    }
  }

  Future<void> _email(BuildContext context) async {
    final uri = Uri(
      scheme: 'mailto',
      path: 'support@buildmart.example',
      query: 'subject=BuildMart Support Request',
    );
    if (!await launchUrl(uri)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open email app.')),
        );
      }
    }
  }

  Future<void> _whatsapp(BuildContext context) async {
    final uri = Uri.parse('https://wa.me/910000000000');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open WhatsApp.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Customer Care')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Text(
            'We\'re here to help',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Reach out through any of these channels — our team typically responds within 24 hours.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.xl),
          _ContactTile(
            icon: Icons.call_outlined,
            label: 'Call Us',
            subtitle: '+91 00000 00000',
            color: AppColors.success,
            onTap: () => _call(context),
          ),
          const SizedBox(height: AppSpacing.sm),
          _ContactTile(
            icon: Icons.email_outlined,
            label: 'Email Us',
            subtitle: 'support@buildmart.example',
            color: AppColors.info,
            onTap: () => _email(context),
          ),
          const SizedBox(height: AppSpacing.sm),
          _ContactTile(
            icon: Icons.chat_outlined,
            label: 'WhatsApp',
            subtitle: 'Chat with support',
            color: const Color(0xFF25D366),
            onTap: () => _whatsapp(context),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'Frequently Asked Questions',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          const _FaqTile(
            question: 'How do I track my order?',
            answer: 'Go to Profile → My Orders → tap your order to see live status updates.',
          ),
          const _FaqTile(
            question: 'Can I cancel an order?',
            answer: 'Yes, as long as it hasn\'t been marked Delivered yet — open the order and tap Cancel Order.',
          ),
          const _FaqTile(
            question: 'How is the transport fee calculated?',
            answer: 'It\'s based on the distance between your delivery address and the seller, using current fuel rates. Orders above ₹5,000 get free delivery.',
          ),
        ],
      ),
    );
  }
}

class _ContactTile extends StatelessWidget {
  final IconData icon;
  final String label, subtitle;
  final Color color;
  final VoidCallback onTap;
  const _ContactTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: Theme.of(context).textTheme.titleMedium),
                  Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}

class _FaqTile extends StatelessWidget {
  final String question, answer;
  const _FaqTile({required this.question, required this.answer});

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      title: Text(question, style: Theme.of(context).textTheme.bodyLarge),
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(answer, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ),
      ],
    );
  }
}
