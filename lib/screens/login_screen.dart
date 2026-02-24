import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../bloc/auth/auth_bloc.dart';
import '../theme/theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _appKeyCtrl = TextEditingController(text: 'DEMO_APP_KEY_123');
  final _emailCtrl = TextEditingController(text: 'admin@demo.com');
  final _passCtrl = TextEditingController();
  bool _obscure = true;

  void _submit() {
    context.read<AuthBloc>().add(
      LoginEvent(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
        appKey: _appKeyCtrl.text.trim(),
      ),
    );
  }

  @override
  void dispose() {
    _appKeyCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: T.bg,
      body: BlocListener<AuthBloc, AuthState>(
        listener: (ctx, state) {
          // Navigation handled by router in main
        },
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Container(
              width: 400,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: T.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: T.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Logo
                  Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: T.active,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'ChatFlow',
                        style: GoogleFonts.inter(
                          color: T.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Welcome back',
                    style: GoogleFonts.inter(
                      color: T.textPrimary,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Sign in to your support dashboard',
                    style: TextStyle(color: T.textSecondary, fontSize: 14),
                  ),
                  const SizedBox(height: 28),

                  // App Key
                  _Label('App Key'),
                  const SizedBox(height: 6),
                  _Field(
                    controller: _appKeyCtrl,
                    hint: 'DEMO_APP_KEY_123',
                    onSubmit: (_) {},
                  ),
                  const SizedBox(height: 16),

                  // Email
                  _Label('Email'),
                  const SizedBox(height: 6),
                  _Field(
                    controller: _emailCtrl,
                    hint: 'admin@demo.com',
                    keyboardType: TextInputType.emailAddress,
                    onSubmit: (_) {},
                  ),
                  const SizedBox(height: 16),

                  // Password
                  _Label('Password'),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _passCtrl,
                    obscureText: _obscure,
                    style: const TextStyle(color: T.textPrimary, fontSize: 14),
                    onSubmitted: (_) => _submit(),
                    decoration: InputDecoration(
                      hintText: '••••••••',
                      suffixIcon: GestureDetector(
                        onTap: () => setState(() => _obscure = !_obscure),
                        child: Icon(
                          _obscure
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          size: 18,
                          color: T.textMuted,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Error
                  BlocBuilder<AuthBloc, AuthState>(
                    builder: (ctx, state) {
                      if (state is AuthError) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF3D1F1F),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.red.shade800),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.error_outline,
                                  color: Colors.redAccent,
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    state.message,
                                    style: const TextStyle(
                                      color: Colors.redAccent,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),

                  // Submit
                  BlocBuilder<AuthBloc, AuthState>(
                    builder: (ctx, state) {
                      final loading = state is AuthLoading;
                      return SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: loading ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: T.accentBlue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                            elevation: 0,
                          ),
                          child: loading
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Sign In',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: T.surfaceEl,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: T.border),
                    ),
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          color: T.textSecondary,
                          fontSize: 12,
                          height: 1.6,
                        ),
                        children: const [
                          TextSpan(text: 'Demo: '),
                          TextSpan(
                            text: 'admin@demo.com',
                            style: TextStyle(
                              color: T.textPrimary,
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          TextSpan(text: ' / '),
                          TextSpan(
                            text: 'Admin@1234',
                            style: TextStyle(
                              color: T.textPrimary,
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          TextSpan(text: '\nApp Key: '),
                          TextSpan(
                            text: 'DEMO_APP_KEY_123',
                            style: TextStyle(
                              color: T.textPrimary,
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05, end: 0),
          ),
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      color: T.textSecondary,
      fontSize: 12,
      fontWeight: FontWeight.w500,
    ),
  );
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;
  final void Function(String) onSubmit;

  const _Field({
    required this.controller,
    required this.hint,
    this.keyboardType,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: T.textPrimary, fontSize: 14),
      onSubmitted: onSubmit,
      decoration: InputDecoration(hintText: hint),
    );
  }
}
