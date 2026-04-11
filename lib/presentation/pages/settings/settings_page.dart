// lib/presentation/pages/settings/settings_page.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../config/theme.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/services/subscription_service.dart';
import '../../../core/utils/book_export_util.dart';
import '../../providers/auth_state_provider.dart';
import '../../widgets/subscription/upgrade_dialog.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  int _bookCount = 0;
  bool _isLoadingBookCount = true;

  @override
  void initState() {
    super.initState();
    _loadBookCount();
  }

  Future<void> _loadBookCount() async {
    final subService = getIt<SubscriptionService>();
    final count = await subService.getBookCount();
    if (mounted) {
      setState(() {
        _bookCount = count;
        _isLoadingBookCount = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Consumer<AuthStateProvider>(
        builder: (context, authProvider, _) {
          if (authProvider.user == null) {
            return const Center(child: Text('Not authenticated'));
          }

          final user = authProvider.user!;
          final isPremium = authProvider.isPremium;
          final subService = getIt<SubscriptionService>();

          return ListView(
            children: [
              // User Section
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'User Profile',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 32,
                                  backgroundColor: Colors.blue[100],
                                  child: Text(
                                    user.username.isNotEmpty
                                        ? user.username[0].toUpperCase()
                                        : '?',
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              user.username,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleMedium
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                            ),
                                          ),
                                          if (isPremium)
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 2,
                                              ),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFFFD700),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: const Text(
                                                'PRO',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.black87,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                      Text(
                                        user.email,
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Subscription Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Subscription',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      color: isPremium
                          ? (Theme.of(context).brightness == Brightness.dark
                              ? AppColors.premiumBackgroundDark
                              : AppColors.premiumBackgroundLight)
                          : Theme.of(context).colorScheme.surface,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      isPremium
                                          ? Icons.star
                                          : Icons.star_border,
                                      color: isPremium
                                          ? AppColors.premiumGold
                                          : Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withValues(alpha: 0.6),
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      authProvider.tierLabel.toUpperCase(),
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: isPremium
                                            ? AppColors.premiumGold
                                            : Theme.of(context)
                                                .colorScheme
                                                .onSurface
                                                .withValues(alpha: 0.6),
                                      ),
                                    ),
                                  ],
                                ),
                                if (!isPremium)
                                  Text(
                                    subService.priceLabel,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                      fontSize: 14,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            if (isPremium) ...[
                              _buildBenefitRow(
                                  Icons.check_circle, 'Unlimited books', true),
                              const SizedBox(height: 8),
                              _buildBenefitRow(Icons.check_circle,
                                  'Unlimited folders', true),
                              const SizedBox(height: 8),
                              _buildBenefitRow(Icons.check_circle,
                                  'Unlimited AI chat', true),
                              const SizedBox(height: 8),
                              _buildBenefitRow(
                                  Icons.check_circle, 'CSV export', true),
                            ] else ...[
                              _buildBenefitRow(
                                Icons.check_circle,
                                '$_bookCount / ${authProvider.maxBooks} books',
                                true,
                                subtext:
                                    _isLoadingBookCount ? 'Loading...' : null,
                              ),
                              const SizedBox(height: 8),
                              _buildBenefitRow(
                                Icons.check_circle,
                                'Up to 5 folders',
                                true,
                              ),
                              const SizedBox(height: 8),
                              _buildBenefitRow(
                                Icons.check_circle,
                                '3 AI chat sessions (5 msgs each)',
                                true,
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () => showUpgradeDialog(
                                    context,
                                    currentCount: _bookCount,
                                    maxBooks: authProvider.maxBooks,
                                  ),
                                  icon: const Icon(Icons.upgrade),
                                  label: const Text('Upgrade to Premium'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        Theme.of(context).colorScheme.primary,
                                    foregroundColor:
                                        Theme.of(context).colorScheme.onPrimary,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: () async {
                                    await subService.restorePurchases();
                                    if (!mounted) return;
                                    if (!subService.isPremium) {
                                      if (!context.mounted) return;
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'No previous purchases found.',
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                  icon: const Icon(Icons.restore),
                                  label: const Text('Restore Purchases'),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Cancel Subscription - always visible for premium users
              if (isPremium) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _showCancelSubscriptionDialog(
                      context,
                      subService,
                    ),
                    icon: const Icon(Icons.cancel_outlined),
                    label: const Text('Cancel Subscription'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 32),

              // Data Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Data',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Card(
                      child: Column(
                        children: [
                          ListTile(
                            leading: Icon(
                              Icons.download,
                              color: isPremium
                                  ? const Color(0xFF009688)
                                  : Colors.grey,
                            ),
                            title: const Text('Export Library (CSV)'),
                            subtitle: isPremium
                                ? null
                                : const Text('Premium feature'),
                            trailing: isPremium
                                ? null
                                : const Icon(Icons.lock,
                                    color: Colors.grey, size: 18),
                            onTap: () async {
                              if (!isPremium) {
                                showUpgradeDialog(
                                  context,
                                  currentCount: _bookCount,
                                  maxBooks: authProvider.maxBooks,
                                );
                                return;
                              }
                              await _exportLibrary();
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Account Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Account',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    ListTile(
                      leading: const Icon(Icons.logout),
                      title: const Text('Sign Out'),
                      onTap: () {
                        final pageContext = context;
                        showDialog(
                          context: context,
                          builder: (dialogContext) => AlertDialog(
                            title: const Text('Sign Out'),
                            content: const Text(
                              'Are you sure you want to sign out?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => dialogContext.pop(),
                                child: const Text('Cancel'),
                              ),
                              ElevatedButton(
                                onPressed: () async {
                                  dialogContext.pop();
                                  await authProvider.signOut();
                                  if (pageContext.mounted) {
                                    pageContext.go('/login');
                                  }
                                },
                                child: const Text('Sign Out'),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // About Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'About',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    ListTile(
                      leading: const Icon(Icons.info),
                      title: const Text('About BuddyBook'),
                      subtitle: const Text('Version 1.0.0'),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBenefitRow(
    IconData icon,
    String text,
    bool enabled, {
    String? subtext,
  }) {
    return Row(
      children: [
        Icon(icon,
            size: 18, color: enabled ? const Color(0xFF009688) : Colors.grey),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                text,
                style: TextStyle(
                  fontSize: 14,
                  color: enabled ? null : Colors.grey,
                ),
              ),
              if (subtext != null)
                Text(
                  subtext,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _exportLibrary() async {
    final authProvider = context.read<AuthStateProvider>();
    if (authProvider.user == null) return;

    try {
      final userId = authProvider.user!.uid;
      final result = await BookExportUtil.exportBooksAsCSV(
        userId: userId,
        context: context,
      );

      if (mounted) {
        if (result.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Library exported successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Export failed: ${result.error}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showCancelSubscriptionDialog(
    BuildContext context,
    SubscriptionService subService,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancel Subscription?'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to cancel your Premium subscription?',
            ),
            SizedBox(height: 12),
            Text(
              '⚠️ Warning: Cancellation is immediate. You will lose Premium access right away.',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'You can resubscribe anytime to restore your Premium benefits.',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Keep Subscription'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              await subService.openSubscriptionManagement();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Cancel Subscription'),
          ),
        ],
      ),
    );
  }
}
