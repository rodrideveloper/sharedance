import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_theme.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/utils/flavor_helper.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isObscured = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Banner de staging si estamos en staging
          if (FlavorHelper.getStagingBanner() != null)
            FlavorHelper.getStagingBanner()!,
          Expanded(
            child: BlocConsumer<AuthBloc, AuthState>(
              listener: (context, state) {
                if (state.status == AuthStatus.authenticated) {
                  context.go('/home');
                } else if (state.status == AuthStatus.error) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.errorMessage ?? 'Error desconocido'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              },
              builder: (context, state) {
                return SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Logo or App Title
                          const Icon(
                            Icons.music_note,
                            size: 80,
                            color: AppColors.primary,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          const Text(
                            'ShareDance',
                            style: AppTextStyles.h1,
                            textAlign: TextAlign.center,
                          ),
                          const Text(
                            'Gestiona tus clases de baile',
                            style: AppTextStyles.bodyMedium,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: AppSpacing.xxl),

                          // Email Field
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              labelText: 'Correo electrónico',
                              prefixIcon: Icon(Icons.email),
                              border: OutlineInputBorder(),
                            ),
                            validator: Validators.validateEmail,
                          ),
                          const SizedBox(height: AppSpacing.md),

                          // Password Field
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _isObscured,
                            decoration: InputDecoration(
                              labelText: 'Contraseña',
                              prefixIcon: const Icon(Icons.lock),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _isObscured
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                ),
                                onPressed:
                                    () => setState(
                                      () => _isObscured = !_isObscured,
                                    ),
                              ),
                              border: const OutlineInputBorder(),
                            ),
                            validator: Validators.validatePassword,
                          ),
                          const SizedBox(height: AppSpacing.lg),

                          // Login Button
                          ElevatedButton(
                            onPressed:
                                state.status == AuthStatus.loading
                                    ? null
                                    : () => _signInWithEmail(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: AppColors.surface,
                              padding: const EdgeInsets.symmetric(
                                vertical: AppSpacing.md,
                              ),
                            ),
                            child:
                                state.status == AuthStatus.loading
                                    ? const CircularProgressIndicator(
                                      color: AppColors.surface,
                                    )
                                    : const Text('Iniciar sesión'),
                          ),
                          const SizedBox(height: AppSpacing.md),

                          // Divider
                          const Row(
                            children: [
                              Expanded(child: Divider()),
                              Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: AppSpacing.md,
                                ),
                                child: Text('o'),
                              ),
                              Expanded(child: Divider()),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.md),

                          // Google Sign In Button
                          OutlinedButton.icon(
                            onPressed:
                                state.status == AuthStatus.loading
                                    ? null
                                    : () => _signInWithGoogle(context),
                            icon: const Icon(Icons.login),
                            label: const Text('Continuar con Google'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                vertical: AppSpacing.md,
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),

                          // Forgot Password
                          TextButton(
                            onPressed: () {
                              // TODO: Implement forgot password
                            },
                            child: const Text(
                              '¿Olvidaste tu contraseña?',
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _signInWithEmail(BuildContext context) {
    if (_formKey.currentState!.validate()) {
      context.read<AuthBloc>().add(
        AuthSignInWithEmailRequested(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        ),
      );
    }
  }

  void _signInWithGoogle(BuildContext context) {
    context.read<AuthBloc>().add(AuthSignInWithGoogleRequested());
  }
}
