import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:buddybook_flutter/presentation/blocs/auth/auth_bloc.dart';
import 'package:buddybook_flutter/presentation/blocs/auth/auth_event.dart';
import 'package:buddybook_flutter/presentation/blocs/auth/auth_state.dart';
import '../../widgets/auth/email_input_field.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  late TextEditingController _emailController;
  late FocusNode _emailFocus;
  bool _emailSent = false;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _emailFocus = FocusNode();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _emailFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reset Password'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          } else if (state is Unauthenticated && _emailController.text.isNotEmpty) {
             // In our implementation, resetPassword emits Unauthenticated
             setState(() {
               _emailSent = true;
             });
          }
        },
        builder: (context, state) {
          final isLoading = state is AuthLoading;

          return SingleChildScrollView(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  Text(
                    'Reset Your Password',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _emailSent
                        ? 'Password reset link sent to your email'
                        : 'Enter your email address and we\'ll send you a link to reset your password',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                  const SizedBox(height: 40),

                  if (!_emailSent) ...[
                    // Email Field
                    EmailInputField(
                      controller: _emailController,
                      focusNode: _emailFocus,
                      onFieldSubmitted: (_) {
                        _handleResetPassword(context);
                      },
                    ),
                    const SizedBox(height: 24),

                    // Send Reset Link Button
                    ElevatedButton(
                      onPressed: isLoading
                          ? null
                          : () => _handleResetPassword(context),
                      child: isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Send Reset Link'),
                    ),
                  ] else ...[
                    // Success Message
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        border: Border.all(color: Colors.green),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.check_circle,
                                  color: Colors.green.shade600),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Check your email',
                                  style: TextStyle(
                                    color: Colors.green.shade600,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'A password reset link has been sent to ${_emailController.text}. Please check your email and follow the instructions.',
                            style: TextStyle(color: Colors.green.shade700),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Back to Login Button
                    ElevatedButton(
                      onPressed: () => context.go('/login'),
                      child: const Text('Back to Sign In'),
                    ),
                  ],
                  const SizedBox(height: 24),

                  // Sign Up Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Don't have an account? "),
                      TextButton(
                        onPressed: () => context.go('/signup'),
                        child: const Text('Sign Up'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _handleResetPassword(BuildContext context) async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your email address'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    context.read<AuthBloc>().add(AuthPasswordResetRequested(email: email));
  }
}
