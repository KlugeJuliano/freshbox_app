import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:freshbox_app/features/auth/presentation/auth_bloc.dart';
import 'package:freshbox_app/features/auth/presentation/auth_event.dart';
import 'package:freshbox_app/features/auth/presentation/auth_state.dart';
import 'package:freshbox_app/features/auth/presentation/widgets/login_form.dart';
import 'package:freshbox_app/features/auth/presentation/widgets/splash_screen.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: context.read<AuthBloc>(),
      child: const _LoginView(),
    );
  }
}

class _LoginView extends StatelessWidget {
  const _LoginView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        return state.when(
          checking: () => const SplashScreen(),
          loading: () => const SplashScreen(),
          authenticated: (_) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (context.mounted) context.go('/admin');
            });
            return const SplashScreen();
          },
          unauthenticated: () => const _LoginFormView(),
          error: (message) => _LoginFormView(error: message),
        );
      },
    );
  }
}

class _LoginFormView extends StatelessWidget {
  const _LoginFormView({this.error});

  final String? error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo/Title
                Icon(
                  Icons.local_grocery_store,
                  size: 80,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  'FreshBox',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Área administrativa',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 32),
                // Error message
                if (error != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onErrorContainer,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                // Login Form
                LoginForm(
                  onSubmit: (email, password, rememberMe) {
                    context.read<AuthBloc>().add(AuthEvent.login(
                          email: email,
                          password: password,
                          rememberMe: rememberMe,
                        ));
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}