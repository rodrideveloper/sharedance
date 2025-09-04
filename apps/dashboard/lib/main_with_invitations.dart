import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_constants/shared_constants.dart';
import 'package:shared_services/shared_services.dart';
import 'features/invitations/presentation/bloc/invitations_bloc.dart';
import 'features/invitations/presentation/pages/invitations_page.dart';
import 'features/auth/login_page.dart';
import 'core/config/app_config.dart';
import 'core/auth/auth_service.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const ShareDanceWithInvitationsApp());
}

class ShareDanceWithInvitationsApp extends StatelessWidget {
  const ShareDanceWithInvitationsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService.authStateChanges,
      builder: (context, snapshot) {
        print(
          '🔐 Auth StreamBuilder - Connection state: ${snapshot.connectionState}',
        );
        print('🔐 Auth StreamBuilder - Has data: ${snapshot.hasData}');
        print('🔐 Auth StreamBuilder - User: ${snapshot.data?.email}');

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const MaterialApp(
            home: Scaffold(body: Center(child: CircularProgressIndicator())),
          );
        }

        if (!snapshot.hasData || snapshot.data == null) {
          print('🔐 User not authenticated, showing login');
          return MaterialApp(home: LoginPage());
        }

        print('🔐 User authenticated: ${snapshot.data!.email}');

        return FutureBuilder<String?>(
          future: AuthService.getIdToken(),
          builder: (context, tokenSnapshot) {
            print(
              '🔑 Token FutureBuilder - Connection state: ${tokenSnapshot.connectionState}',
            );
            print(
              '🔑 Token FutureBuilder - Has data: ${tokenSnapshot.hasData}',
            );
            print(
              '🔑 Token preview: ${tokenSnapshot.data?.substring(0, 20)}...',
            );

            if (tokenSnapshot.connectionState == ConnectionState.waiting) {
              return const MaterialApp(
                home: Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                ),
              );
            }

            if (!tokenSnapshot.hasData || tokenSnapshot.data == null) {
              print('⚠️ No token available, user needs to re-authenticate');
              return MaterialApp(home: LoginPage());
            }

            return MultiBlocProvider(
              providers: [
                BlocProvider(
                  create:
                      (context) => InvitationsBloc(
                        invitationService: InvitationService(
                          getBaseUrl: () => AppConfig.baseUrl,
                          getAuthToken:
                              () async => await AuthService.getIdToken(),
                        ),
                      ),
                ),
              ],
              child: MaterialApp(
                title: 'ShareDance Dashboard',
                debugShowCheckedModeBanner: false,
                theme: ThemeData(
                  useMaterial3: true,
                  colorScheme: ColorScheme.fromSeed(
                    seedColor: AppColors.primary,
                    brightness: Brightness.light,
                  ),
                  appBarTheme: const AppBarTheme(
                    backgroundColor: AppColors.surface,
                    foregroundColor: AppColors.onSurface,
                    elevation: 0,
                    centerTitle: false,
                  ),
                  cardTheme: CardTheme(
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  elevatedButtonTheme: ElevatedButtonThemeData(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                home: const DashboardHomePage(),
              ),
            );
          },
        );
      },
    );
  }
}

class DashboardHomePage extends StatefulWidget {
  const DashboardHomePage({super.key});

  @override
  State<DashboardHomePage> createState() => _DashboardHomePageState();
}

class _DashboardHomePageState extends State<DashboardHomePage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const DashboardOverview(),
    const InvitationsPage(),
    const UsersPage(),
    const SettingsPage(),
  ];

  final List<String> _titles = [
    'Dashboard',
    'Invitaciones',
    'Usuarios',
    'Configuración',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_selectedIndex]),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.onSurface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await AuthService.signOut();
              // Navegar a login (esto se manejará con el router)
            },
          ),
        ],
      ),
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            labelType: NavigationRailLabelType.all,
            backgroundColor: AppColors.surface,
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard),
                label: Text('Dashboard'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.email_outlined),
                selectedIcon: Icon(Icons.email),
                label: Text('Invitaciones'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.people_outlined),
                selectedIcon: Icon(Icons.people),
                label: Text('Usuarios'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.settings_outlined),
                selectedIcon: Icon(Icons.settings),
                label: Text('Configuración'),
              ),
            ],
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(child: _pages[_selectedIndex]),
        ],
      ),
    );
  }
}

// Páginas temporales para la demo
class DashboardOverview extends StatelessWidget {
  const DashboardOverview({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Resumen del Dashboard',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),
          Text('Bienvenido al sistema de gestión de ShareDance'),
        ],
      ),
    );
  }
}

class UsersPage extends StatelessWidget {
  const UsersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Gestión de Usuarios',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),
          Text('Aquí se mostrarán los usuarios del sistema'),
        ],
      ),
    );
  }
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Configuración',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),
          Text('Configuraciones del sistema'),
        ],
      ),
    );
  }
}
