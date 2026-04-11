// lib/presentation/widgets/subscription/upgrade_dialog.dart

import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/services/subscription_service.dart';

/// Shows a dialog prompting the free-tier user to upgrade to Premium.
///
/// [currentCount] — the user's current book count
/// [maxBooks] — the free tier limit (e.g. 25)
///
/// Returns `true` if the user initiated a purchase, `false`/`null` otherwise.
Future<bool?> showUpgradeDialog(
  BuildContext context, {
  required int currentCount,
  required int maxBooks,
}) {
  return showDialog<bool>(
    context: context,
    builder: (dialogContext) => _UpgradeDialog(
      currentCount: currentCount,
      maxBooks: maxBooks,
    ),
  );
}

class _UpgradeDialog extends StatefulWidget {
  final int currentCount;
  final int maxBooks;

  const _UpgradeDialog({
    required this.currentCount,
    required this.maxBooks,
  });

  @override
  State<_UpgradeDialog> createState() => _UpgradeDialogState();
}

class _UpgradeDialogState extends State<_UpgradeDialog> {
  bool _isPurchasing = false;

  @override
  Widget build(BuildContext context) {
    final subscriptionService = getIt<SubscriptionService>();
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(Icons.star, color: AppColors.premiumGold, size: 28),
          const SizedBox(width: 8),
          const Text('Upgrade to Premium'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Limit reached message - theme-aware
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.warningDark : AppColors.warningLight,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isDark
                    ? AppColors.warningTextDark
                    : AppColors.warningTextLight,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: isDark
                      ? AppColors.warningTextDark
                      : AppColors.warningTextLight,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'You have ${widget.currentCount}/${widget.maxBooks} books. '
                    'Free plan limit reached.',
                    style: TextStyle(
                      color: isDark
                          ? AppColors.warningTextDark
                          : AppColors.warningTextLight,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Plan comparison
          Text(
            'Premium Benefits',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _buildBenefitRow(Icons.all_inclusive, 'Unlimited books', colors),
          const SizedBox(height: 8),
          _buildBenefitRow(Icons.folder_copy, 'Unlimited folders', colors),
          const SizedBox(height: 8),
          _buildBenefitRow(Icons.cloud_upload, 'Full cloud storage', colors),
          const SizedBox(height: 20),

          // Price - theme-aware
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                subscriptionService.priceLabel,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: colors.primary,
                ),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isPurchasing ? null : () => Navigator.pop(context, false),
          child: const Text('Not Now'),
        ),
        ElevatedButton(
          onPressed: _isPurchasing ? null : _onUpgrade,
          style: ElevatedButton.styleFrom(
            backgroundColor: colors.primary,
            foregroundColor: colors.onPrimary,
          ),
          child: _isPurchasing
              ? SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: colors.onPrimary,
                  ),
                )
              : const Text('Upgrade Now'),
        ),
      ],
    );
  }

  Widget _buildBenefitRow(IconData icon, String text, ColorScheme colors) {
    return Row(
      children: [
        Icon(icon, size: 18, color: colors.primary),
        const SizedBox(width: 10),
        Text(text, style: const TextStyle(fontSize: 14)),
      ],
    );
  }

  Future<void> _onUpgrade() async {
    final subscriptionService = getIt<SubscriptionService>();

    setState(() => _isPurchasing = true);

    try {
      final success = await subscriptionService.purchasePremium();
      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Unable to start purchase. Please try again later.',
            ),
          ),
        );
        setState(() => _isPurchasing = false);
      }
      // If purchase started successfully, the dialog stays open.
      // The purchase result will be handled by the SubscriptionService listener.
      // In a real implementation you'd listen for the result and dismiss.
      // For now, dismiss after initiating:
      if (success && mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isPurchasing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Purchase error: $e')),
        );
      }
    }
  }
}
