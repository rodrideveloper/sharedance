import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_services/shared_services.dart';
import 'firebase_options.dart';
import 'core/routing/app_router.dart';
import 'core/config/app_config.dart';
import 'core/auth/auth_service.dart';
import 'features/invitations/presentation/bloc/invitations_bloc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const ShareDanceApp());
}

class ShareDanceApp extends StatelessWidget {
  const ShareDanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService.authStateChanges,
      builder: (context, userSnapshot) {
        return MultiBlocProvider(
          providers: [
            BlocProvider<InvitationsBloc>(
              create:
                  (context) => InvitationsBloc(
                    invitationService: InvitationService(
                      getBaseUrl: () => AppConfig.baseUrl,
                      getAuthToken: () async => await AuthService.getIdToken(),
                    ),
                  ),
            ),
          ],
          child: MaterialApp.router(
            title: 'ShareDance Dashboard',
            debugShowCheckedModeBanner: false,
            routerConfig: AppRouter.router,
            theme: ThemeData(
              useMaterial3: true,
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF6366F1),
                brightness: Brightness.light,
              ),
              appBarTheme: const AppBarTheme(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black87,
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
                  backgroundColor: const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
              inputDecorationTheme: InputDecorationTheme(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.grey),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
                    color: Color(0xFF6366F1),
                    width: 2,
                  ),
                ),
              ),
            ),
          ),
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

  final List<NavigationItem> _navigationItems = [
    NavigationItem(
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard,
      label: 'Dashboard',
      page: const DashboardOverviewPage(),
    ),
    NavigationItem(
      icon: Icons.mail_outline,
      selectedIcon: Icons.mail,
      label: 'Invitaciones',
      page: const InvitationsPreviewPage(),
    ),
    NavigationItem(
      icon: Icons.people_outline,
      selectedIcon: Icons.people,
      label: 'Usuarios',
      page: const UsersPage(),
    ),
    NavigationItem(
      icon: Icons.class_outlined,
      selectedIcon: Icons.class_,
      label: 'Clases',
      page: const ClassesPage(),
    ),
    NavigationItem(
      icon: Icons.analytics_outlined,
      selectedIcon: Icons.analytics,
      label: 'Reportes',
      page: const ReportsPage(),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            extended: MediaQuery.of(context).size.width > 800,
            destinations:
                _navigationItems
                    .map(
                      (item) => NavigationRailDestination(
                        icon: Icon(item.icon),
                        selectedIcon: Icon(item.selectedIcon),
                        label: Text(item.label),
                      ),
                    )
                    .toList(),
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            backgroundColor: Colors.white,
            indicatorColor: const Color(0xFF6366F1).withOpacity(0.2),
            selectedIconTheme: const IconThemeData(color: Color(0xFF6366F1)),
            selectedLabelTextStyle: const TextStyle(
              color: Color(0xFF6366F1),
              fontWeight: FontWeight.w500,
            ),
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(child: _navigationItems[_selectedIndex].page),
        ],
      ),
    );
  }
}

class NavigationItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final Widget page;

  NavigationItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.page,
  });
}

class DashboardOverviewPage extends StatelessWidget {
  const DashboardOverviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Dashboard'),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Bienvenido al Dashboard de ShareDance',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Gestiona invitaciones, usuarios y clases desde aquí',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 32),
            Expanded(
              child: GridView.count(
                crossAxisCount: MediaQuery.of(context).size.width > 800 ? 3 : 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _buildDashboardCard(
                    context,
                    'Invitaciones',
                    Icons.mail,
                    'Envía invitaciones por email',
                    const Color(0xFF10B981),
                    () {},
                  ),
                  _buildDashboardCard(
                    context,
                    'Usuarios',
                    Icons.people,
                    'Gestiona usuarios registrados',
                    const Color(0xFF3B82F6),
                    () {},
                  ),
                  _buildDashboardCard(
                    context,
                    'Clases',
                    Icons.class_,
                    'Administra clases de baile',
                    const Color(0xFF8B5CF6),
                    () {},
                  ),
                  _buildDashboardCard(
                    context,
                    'Reportes',
                    Icons.analytics,
                    'Visualiza estadísticas',
                    const Color(0xFFF59E0B),
                    () {},
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardCard(
    BuildContext context,
    String title,
    IconData icon,
    String description,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 32, color: color),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class InvitationsPreviewPage extends StatelessWidget {
  const InvitationsPreviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Invitaciones'),
        automaticallyImplyLeading: false,
        actions: [
          ElevatedButton.icon(
            onPressed: () => _showInvitationDialog(context),
            icon: const Icon(Icons.add),
            label: const Text('Enviar Invitación'),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Buscar invitaciones...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                DropdownButton<String>(
                  value: 'Todas',
                  items:
                      ['Todas', 'Pendientes', 'Aceptadas', 'Rechazadas'].map((
                        String value,
                      ) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                  onChanged: (String? value) {},
                ),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Email',
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              'Rol',
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              'Estado',
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              'Fecha',
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                          ),
                          const SizedBox(width: 80),
                        ],
                      ),
                      const Divider(),
                      Expanded(
                        child: ListView.builder(
                          itemCount: 5,
                          itemBuilder: (context, index) {
                            return _buildInvitationRow(
                              'profesor${index + 1}@example.com',
                              'Profesor',
                              index % 3 == 0
                                  ? 'Pendiente'
                                  : index % 3 == 1
                                  ? 'Aceptada'
                                  : 'Rechazada',
                              '${index + 1}/12/2023',
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInvitationRow(
    String email,
    String role,
    String status,
    String date,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Expanded(child: Text(email)),
          Expanded(child: Text(role)),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color:
                    status == 'Pendiente'
                        ? Colors.orange.withOpacity(0.1)
                        : status == 'Aceptada'
                        ? Colors.green.withOpacity(0.1)
                        : Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                status,
                style: TextStyle(
                  color:
                      status == 'Pendiente'
                          ? Colors.orange
                          : status == 'Aceptada'
                          ? Colors.green
                          : Colors.red,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          Expanded(child: Text(date)),
          SizedBox(
            width: 80,
            child: Row(
              children: [
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.refresh, size: 20),
                  tooltip: 'Reenviar',
                ),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.delete, size: 20),
                  tooltip: 'Eliminar',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showInvitationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Enviar Invitación'),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  decoration: InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'Rol',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  items:
                      ['Profesor', 'Administrador', 'Estudiante'].map((
                        String value,
                      ) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                  onChanged: (String? value) {},
                ),
                const SizedBox(height: 16),
                TextField(
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Mensaje personalizado (opcional)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Invitación enviada correctamente'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              child: const Text('Enviar'),
            ),
          ],
        );
      },
    );
  }
}

class UsersPage extends StatelessWidget {
  const UsersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Usuarios'),
        automaticallyImplyLeading: false,
      ),
      body: const Center(
        child: Text(
          'Gestión de Usuarios\n(Próximamente)',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

class ClassesPage extends StatelessWidget {
  const ClassesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Clases'),
        automaticallyImplyLeading: false,
      ),
      body: const Center(
        child: Text(
          'Gestión de Clases\n(Próximamente)',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

class ReportsPage extends StatelessWidget {
  const ReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Reportes'),
        automaticallyImplyLeading: false,
      ),
      body: const Center(
        child: Text(
          'Reportes y Estadísticas\n(Próximamente)',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
