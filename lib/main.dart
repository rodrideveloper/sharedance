import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import 'core/constants/app_theme.dart';
import 'core/utils/flavor_helper.dart';
import 'features/auth/data/repositories/auth_repository_simple.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/auth/presentation/pages/register_page.dart';

// Import Firebase configurations
import 'firebase_options_production.dart' as production;
import 'firebase_options_staging.dart' as staging;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Get the flavor from environment
  const flavor = String.fromEnvironment('FLAVOR', defaultValue: 'staging');

  // Debug print to verify flavor
  debugPrint('🔥 ShareDance - Using flavor: $flavor');

  // Choose Firebase configuration based on flavor
  FirebaseOptions firebaseOptions;
  if (flavor == 'production') {
    firebaseOptions = production.DefaultFirebaseOptions.currentPlatform;
    debugPrint('🔥 Using PRODUCTION Firebase config');
  } else {
    firebaseOptions = staging.DefaultFirebaseOptions.currentPlatform;
    debugPrint('🔥 Using STAGING Firebase config');
  }

  await Firebase.initializeApp(options: firebaseOptions);

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  MyApp({super.key});

  final GoRouter _router = GoRouter(
    initialLocation: '/login',
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(path: '/home', builder: (context, state) => const HomePage()),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create:
                (context) => AuthBloc(authRepository: AuthRepositorySimple()),
          ),
        ],
        child: MaterialApp.router(
          title: 'ShareDance',
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
            useMaterial3: true,
          ),
          routerConfig: _router,
        ),
      ),
    );
  }
}

// Temporary HomePage - will be replaced with proper dashboard
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('ShareDance'),
            if (FlavorHelper.isStaging) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'STAGING',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.surface,
      ),
      body: Column(
        children: [
          // Banner de staging si estamos en staging
          if (FlavorHelper.getStagingBanner() != null)
            FlavorHelper.getStagingBanner()!,
          Expanded(
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('¡Bienvenido a ShareDance!', style: AppTextStyles.h2),
                  SizedBox(height: AppSpacing.md),
                  Text(
                    'Tu app de gestión de clases de baile',
                    style: AppTextStyles.bodyLarge,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
