// lib/core/services/subscription_service.dart

import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants/firebase_constants.dart';
import '../../data/datasources/firebase_database_remote_data_source.dart';
import '../utils/platform_utils.dart';

/// Wraps the in_app_purchase package to manage the BuddyBook premium subscription.
///
/// Responsibilities:
/// - Initialize store connection
/// - Load the yearly subscription product
/// - Listen to purchase stream and complete/verify purchases
/// - Persist tier to Firebase on successful purchase
/// - Restore purchases
/// - Expose reactive subscription status
class SubscriptionService extends ChangeNotifier {
  final InAppPurchase _iap;
  final FirebaseDatabaseRemoteDataSource _databaseDataSource;

  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;
  StreamSubscription? _tierSubscription;

  bool _isAvailable = false;
  bool _isPremium = false;
  bool _isLoading = false;
  ProductDetails? _yearlyProduct;
  String? _userId;
  AppLifecycleState? _lastLifecycleState;

  SubscriptionService({
    required FirebaseDatabaseRemoteDataSource databaseDataSource,
    InAppPurchase? iap,
  })  : _databaseDataSource = databaseDataSource,
        _iap = iap ?? InAppPurchase.instance;

  // ─── Getters ────────────────────────────────────────────────────────

  bool get isAvailable => _isAvailable;
  bool get isPremium => _isPremium;
  bool get isLoading => _isLoading;
  ProductDetails? get yearlyProduct => _yearlyProduct;

  int get maxBooks => _isPremium
      ? FirebaseConstants.defaultMaxBooksPaid
      : FirebaseConstants.defaultMaxBooks;

  int get maxFolders => _isPremium
      ? FirebaseConstants.defaultMaxFoldersPaid
      : FirebaseConstants.defaultMaxFolders;

  int get maxChatMessagesPerSession => _isPremium
      ? 999999
      : FirebaseConstants.defaultMaxChatMessagesPerSessionFree;

  int get maxChatSessions =>
      _isPremium ? 999999 : FirebaseConstants.defaultMaxChatSessionsFree;

  String get tierLabel => _isPremium ? 'Premium' : 'Free';

  /// Formatted price string from the store, e.g. "€1.00/month"
  String get priceLabel {
    if (_yearlyProduct != null) {
      return '${_yearlyProduct!.price}/month';
    }
    return '€1.00/month'; // fallback
  }

  // ─── Initialization ─────────────────────────────────────────────────

  /// Call once after login. Sets the userId and kicks off store init + purchase listener.
  Future<void> initialize(String userId) async {
    _userId = userId;
    _isLoading = true;
    notifyListeners();

    // Skip store initialization on platforms that don't support in-app purchases
    if (!PlatformUtils.isInAppPurchaseSupported) {
      debugPrint(
          '[SUBSCRIPTION] In-app purchases not supported on this platform');
      _isAvailable = false;
      _isLoading = false;
      notifyListeners();
      return;
    }

    try {
      _isAvailable = await _iap.isAvailable();
      if (!_isAvailable) {
        debugPrint('[SUBSCRIPTION] Store not available');
        _isLoading = false;
        notifyListeners();
        return;
      }

      // Start listening to purchases
      _purchaseSubscription?.cancel();
      _purchaseSubscription = _iap.purchaseStream.listen(
        _onPurchaseUpdated,
        onDone: () => _purchaseSubscription?.cancel(),
        onError: (error) {
          debugPrint('[SUBSCRIPTION] Purchase stream error: $error');
        },
      );

      // Start listening to Firebase tier changes in real-time
      _startTierListener();

      // Load product details
      await _loadProducts();

      // Restore purchases to check if user is already premium
      await _iap.restorePurchases();
    } catch (e) {
      debugPrint('[SUBSCRIPTION] Initialization error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _startTierListener() {
    _tierSubscription?.cancel();
    final ref = _databaseDataSource.userTierRef(_userId!);
    _tierSubscription = ref.onValue.listen((event) {
      final newTier = event.snapshot.value as String?;
      final wasPremium = _isPremium;
      _isPremium = newTier == FirebaseConstants.paidTier;

      if (wasPremium != _isPremium) {
        debugPrint('[SUBSCRIPTION] Firebase tier changed: $_isPremium');
        notifyListeners();
      }
    });
  }

  Future<void> _loadProducts() async {
    final response = await _iap.queryProductDetails(
      {FirebaseConstants.monthlySubscriptionId},
    );

    if (response.error != null) {
      debugPrint(
          '[SUBSCRIPTION] Product query error: ${response.error!.message}');
      return;
    }

    if (response.notFoundIDs.isNotEmpty) {
      debugPrint('[SUBSCRIPTION] Products not found: ${response.notFoundIDs}');
    }

    if (response.productDetails.isNotEmpty) {
      _yearlyProduct = response.productDetails.first;
      debugPrint(
          '[SUBSCRIPTION] Loaded product: ${_yearlyProduct!.id} - ${_yearlyProduct!.price}');
    }
  }

  // ─── Purchase Flow ──────────────────────────────────────────────────

  /// Initiate the purchase flow for the yearly subscription.
  /// Returns false if the store isn't available or product isn't loaded.
  Future<bool> purchasePremium() async {
    if (!_isAvailable || _yearlyProduct == null) {
      debugPrint(
          '[SUBSCRIPTION] Cannot purchase: available=$_isAvailable, product=$_yearlyProduct');
      return false;
    }

    final purchaseParam = PurchaseParam(productDetails: _yearlyProduct!);
    // Subscriptions use buyNonConsumable
    return _iap.buyNonConsumable(purchaseParam: purchaseParam);
  }

  /// Restore previous purchases (e.g. after reinstall or new device).
  Future<void> restorePurchases() async {
    if (!_isAvailable) return;
    _isLoading = true;
    notifyListeners();

    try {
      await _iap.restorePurchases();
      // After restore, sync tier from Firebase to verify subscription status
      await syncTierFromFirebase();
    } catch (e) {
      debugPrint('[SUBSCRIPTION] Restore error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Open the Play Store/App Store subscription management page.
  /// This allows users to cancel their subscription.
  Future<bool> openSubscriptionManagement() async {
    const packageName = 'com.quartzodev.buddybook';

    // Android: Open Play Store subscription management
    if (PlatformUtils.isAndroid) {
      final Uri url = Uri.parse(
        'https://play.google.com/store/account/subscriptions?package=$packageName',
      );
      try {
        return await launchUrl(url, mode: LaunchMode.externalApplication);
      } catch (e) {
        debugPrint('[SUBSCRIPTION] Failed to open Play Store: $e');
        return false;
      }
    }

    // iOS: Open App Store subscriptions
    if (PlatformUtils.isIOS) {
      final Uri url = Uri.parse(
        'https://apps.apple.com/account/subscriptions',
      );
      try {
        return await launchUrl(url, mode: LaunchMode.externalApplication);
      } catch (e) {
        debugPrint('[SUBSCRIPTION] Failed to open App Store: $e');
        return false;
      }
    }

    return false;
  }

  // ─── Purchase Updates ───────────────────────────────────────────────

  Future<void> _onPurchaseUpdated(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      debugPrint(
          '[SUBSCRIPTION] Purchase update: ${purchase.productID} - ${purchase.status}');

      switch (purchase.status) {
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          await _handleSuccessfulPurchase(purchase);
          break;
        case PurchaseStatus.error:
          debugPrint(
              '[SUBSCRIPTION] Purchase error: ${purchase.error?.message}');
          break;
        case PurchaseStatus.pending:
          debugPrint('[SUBSCRIPTION] Purchase pending');
          break;
        case PurchaseStatus.canceled:
          await _handleCancelledPurchase(purchase);
          break;
      }

      // Complete the purchase if it's pending completion
      if (purchase.pendingCompletePurchase) {
        await _iap.completePurchase(purchase);
      }
    }
  }

  Future<void> _handleSuccessfulPurchase(PurchaseDetails purchase) async {
    if (purchase.productID == FirebaseConstants.monthlySubscriptionId) {
      _isPremium = true;
      notifyListeners();

      // Persist to Firebase
      if (_userId != null) {
        try {
          // Update tier
          await _databaseDataSource.updateUserTier(
            _userId!,
            FirebaseConstants.paidTier,
          );
          debugPrint('[SUBSCRIPTION] Tier updated to paid in Firebase');

          // Store purchase token for subscription cancellation tracking
          if (purchase.verificationData.localVerificationData.isNotEmpty) {
            await _databaseDataSource.storePurchaseToken(
              _userId!,
              purchase.verificationData.localVerificationData,
            );
            debugPrint('[SUBSCRIPTION] Purchase token stored in Firebase');
          }
        } catch (e) {
          debugPrint('[SUBSCRIPTION] Failed to update tier in Firebase: $e');
        }
      }
    }
  }

  Future<void> _handleCancelledPurchase(PurchaseDetails purchase) async {
    if (purchase.productID == FirebaseConstants.monthlySubscriptionId) {
      // Sync tier from Firebase to handle subscription cancellations
      await syncTierFromFirebase();
    }
  }

  /// Sync the local premium flag from Firebase.
  /// Returns the actual premium status from the server.
  Future<bool> syncTierFromFirebase() async {
    if (_userId == null) return false;

    try {
      final tier = await _databaseDataSource.getUserTier(_userId!);
      final wasPremium = _isPremium;
      _isPremium = tier == FirebaseConstants.paidTier;

      if (wasPremium != _isPremium) {
        debugPrint(
            '[SUBSCRIPTION] Tier sync: was=$wasPremium, now=$_isPremium');
        notifyListeners();
      }

      return _isPremium;
    } catch (e) {
      debugPrint('[SUBSCRIPTION] Failed to sync tier from Firebase: $e');
      return false;
    }
  }

  // ─── Book Limit Check ───────────────────────────────────────────────

  /// Check whether the user can add another book.
  /// Returns true if under the limit (or premium), false if at/over the free limit.
  Future<bool> canAddBook() async {
    if (_isPremium) return true;
    if (_userId == null) return false;

    try {
      final count = await _databaseDataSource.countUserBooks(_userId!);
      return count < FirebaseConstants.defaultMaxBooks;
    } catch (e) {
      debugPrint('[SUBSCRIPTION] Error counting books: $e');
      // On error, allow the add so the user isn't blocked by a transient failure
      return true;
    }
  }

  /// Get the current book count for the user.
  Future<int> getBookCount() async {
    if (_userId == null) return 0;
    try {
      return await _databaseDataSource.countUserBooks(_userId!);
    } catch (e) {
      debugPrint('[SUBSCRIPTION] Error getting book count: $e');
      return 0;
    }
  }

  /// Check whether the user can add another folder.
  Future<bool> canAddFolder() async {
    if (_isPremium) return true;
    if (_userId == null) return false;

    try {
      final count = await _databaseDataSource.countUserFolders(_userId!);
      return count < FirebaseConstants.defaultMaxFolders;
    } catch (e) {
      debugPrint('[SUBSCRIPTION] Error counting folders: $e');
      return true;
    }
  }

  /// Get the current folder count for the user.
  Future<int> getFolderCount() async {
    if (_userId == null) return 0;
    try {
      return await _databaseDataSource.countUserFolders(_userId!);
    } catch (e) {
      debugPrint('[SUBSCRIPTION] Error getting folder count: $e');
      return 0;
    }
  }

  // ─── Manual tier sync ───────────────────────────────────────────────

  /// Sync the local premium flag from the Firebase user tier value.
  /// Call this after login when the User entity is available.
  void syncTierFromUser(String tier) {
    _isPremium = tier == FirebaseConstants.paidTier;
    notifyListeners();
  }

  /// Handle app lifecycle changes to sync subscription status.
  void handleAppLifecycleState(AppLifecycleState state) {
    if (_userId == null) return;

    // Only sync when resuming from background
    if (_lastLifecycleState == AppLifecycleState.paused &&
        state == AppLifecycleState.resumed) {
      debugPrint('[SUBSCRIPTION] App resumed - syncing tier from Firebase');
      syncTierFromFirebase();
    }

    _lastLifecycleState = state;
  }

  // ─── Cleanup ────────────────────────────────────────────────────────

  @override
  void dispose() {
    _purchaseSubscription?.cancel();
    _tierSubscription?.cancel();
    super.dispose();
  }
}
