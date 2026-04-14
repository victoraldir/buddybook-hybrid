// lib/main.dart

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:go_router/go_router.dart';
import 'firebase_options.dart';
import 'core/di/service_locator.dart' as di;
import 'core/constants/env_constants.dart';
import 'core/services/subscription_service.dart';
import 'config/theme.dart';
import 'package:buddybook_flutter/l10n/app_localizations.dart';
import 'presentation/blocs/auth/auth_bloc.dart';
import 'presentation/navigation/app_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase initialization failed: $e');
    // Continue without Firebase for now (Phase 2 will require Firebase)
  }

  // Initialize Firebase App Check
  await _initializeAppCheck();

  // Setup dependency injection
  await di.setupServiceLocator();

  runApp(const BuddyBookApp());
}

/// Initialize Firebase App Check with dynamic provider selection
///
/// - **Debug Mode**: Uses AndroidDebugProvider and AppleDebugProvider
///   - Bypasses real attestation verification
///   - Perfect for development and emulator testing
///   - No need to register debug tokens in Firebase Console
///
/// - **Release Mode**: Uses AndroidPlayIntegrityProvider and AppleDeviceCheckProvider
///   - Real app integrity verification using Play Integrity API
///   - Production-ready security
///   - Requires Play Integrity setup in Firebase Console
Future<void> _initializeAppCheck() async {
  try {
    if (EnvConstants.isDebugMode) {
      debugPrint(
        '[APP_CHECK] Initializing in DEBUG mode - using debug providers (no attestation)',
      );
      await FirebaseAppCheck.instance.activate(
        providerAndroid: const AndroidDebugProvider(),
        providerApple: const AppleDebugProvider(),
      );
      debugPrint('[APP_CHECK] ✓ Initialized with DEBUG providers');
    } else {
      debugPrint(
        '[APP_CHECK] Initializing in RELEASE mode - using production providers (real attestation)',
      );
      await FirebaseAppCheck.instance.activate(
        providerAndroid: const AndroidPlayIntegrityProvider(),
        providerApple: const AppleDeviceCheckProvider(),
      );
      debugPrint('[APP_CHECK] ✓ Initialized with PRODUCTION providers');
    }
  } catch (e) {
    debugPrint('[APP_CHECK] ✗ Failed to initialize: $e');
    // App Check failure is non-critical - app continues to work
    // but without app integrity verification
  }
}

class BuddyBookApp extends StatefulWidget {
  const BuddyBookApp({super.key});

  @override
  State<BuddyBookApp> createState() => _BuddyBookAppState();
}

class _BuddyBookAppState extends State<BuddyBookApp>
    with WidgetsBindingObserver {
  late GoRouter _router;
  late AuthBloc _authBloc;
  SubscriptionService? _subscriptionService;

  @override
  void initState() {
    super.initState();
    _authBloc = di.getIt<AuthBloc>();
    _authBloc.add(AuthCheckRequested());
    _router = createRouter(authBloc: _authBloc);

    // Register for app lifecycle changes to sync subscription status
    WidgetsBinding.instance.addObserver(this);

    // Get subscription service if available
    if (di.getIt.isRegistered<SubscriptionService>()) {
      _subscriptionService = di.getIt<SubscriptionService>();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _authBloc.close();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Forward lifecycle changes to subscription service
    _subscriptionService?.handleAppLifecycleState(state);
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AuthBloc>.value(
      value: _authBloc,
      child: MaterialApp.router(
        title: 'BuddyBook',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        routerConfig: _router,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    );
  }
}
