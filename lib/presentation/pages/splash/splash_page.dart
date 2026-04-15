import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../config/theme.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_state.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    // Match the native splash: teal status bar
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: AppTheme.primaryDarkColor,
      statusBarIconBrightness: Brightness.light,
    ));
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    final authBloc = context.read<AuthBloc>();

    // Wait for auth initialization to complete
    int attempts = 0;
    while (authBloc.state is AuthInitial && attempts < 30) {
      await Future.delayed(const Duration(milliseconds: 100));
      attempts++;
    }

    if (!mounted) return;

    // Show splash screen for at least 1 second regardless
    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;

    if (authBloc.state is Authenticated) {
      context.go('/home');
    } else {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryColor,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 48.0),
          child: Image.asset(
            'assets/images/logo_white_splash.png',
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}
