import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/theme/app_theme.dart';

class _Offer {
  final String code;
  final String title;
  final String subtitle;
  final IconData icon;

  const _Offer(this.code, this.title, this.subtitle, this.icon);
}

/// Static promotional strip — matches your spec's "Offers" section.
/// Swap for a Firestore `coupons` collection once a real coupon
/// engine is built; the UI shape here won't need to change.
class OffersStrip extends StatelessWidget {
  const OffersStrip({super.key});

  static const _offers = [
    _Offer(
      'WELCOME10',
      '10% OFF',
      'On your first order',
      Icons.celebration_outlined,
    ),
    _Offer(
      'BULK500',
      '₹500 OFF',
      'On bulk cement orders',
      Icons.local_shipping_outlined,
    ),
    _Offer(
      'FREESHIP',
      'Free Delivery',
      'On orders above ₹5,000',
      Icons.card_giftcard_outlined,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 104,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        itemCount: _offers.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          final offer = _offers[index];
          return InkWell(
            onTap: () {
              Clipboard.setData(ClipboardData(text: offer.code));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Code "${offer.code}" copied!')),
              );
            },
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: DottedBorderContainer(
              child: Container(
                width: 200,
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Row(
                  children: [
                    Icon(offer.icon, color: AppColors.primary, size: 28),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            offer.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            offer.subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          Text(
                            'Tap to copy: ${offer.code}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
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

/// Simple passthrough — kept as a separate widget in case you want to
/// add an actual dashed border treatment later without touching callers.
class DottedBorderContainer extends StatelessWidget {
  final Widget child;
  const DottedBorderContainer({super.key, required this.child});

  @override
  Widget build(BuildContext context) => child;
}
