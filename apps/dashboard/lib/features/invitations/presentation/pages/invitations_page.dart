import 'package:fl  @override
  void initState() {
    super.initState();
    print('🎯 InvitationsPage: initState called');
    print('🔗 InvitationsPage: Current URL base: ${Uri.base}');
    print('🌐 InvitationsPage: AppConfig baseUrl: ${AppConfig.baseUrl}');
    
    // Add a small delay to ensure JavaScript is loaded
    Future.delayed(Duration(milliseconds: 500), () {
      print('⏰ InvitationsPage: Loading invitations after delay');
      _loadInvitations();
    });
  }ial.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_models/shared_models.dart';
import 'package:shared_constants/shared_constants.dart';
import '../bloc/invitations_bloc.dart';
import '../widgets/invitation_form_dialog.dart';
import '../widgets/invitation_list_item.dart';

class InvitationsPage extends StatefulWidget {
  const InvitationsPage({super.key});

  @override
  State<InvitationsPage> createState() => _InvitationsPageState();
}

class _InvitationsPageState extends State<InvitationsPage> {
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    print('🔄 InvitationsPage: initState - about to load invitations');
    try {
      context.read<InvitationsBloc>().add(const LoadInvitations());
      print('✅ InvitationsPage: Successfully added LoadInvitations event');
    } catch (e) {
      print('❌ InvitationsPage: Error accessing InvitationsBloc: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: AppSpacing.lg),
            _buildFilters(),
            const SizedBox(height: AppSpacing.lg),
            Expanded(child: _buildInvitationsList()),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showInvitationDialog,
        icon: const Icon(Icons.person_add),
        label: const Text('Enviar Invitación'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        const Icon(Icons.mail_outline, size: 32, color: AppColors.primary),
        const SizedBox(width: AppSpacing.md),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Invitaciones',
              style: AppTextStyles.headline3.copyWith(
                color: AppColors.onBackground,
              ),
            ),
            Text(
              'Gestiona las invitaciones de usuarios',
              style: AppTextStyles.bodyText2.copyWith(color: AppColors.grey600),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFilters() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            const Icon(Icons.filter_list, color: AppColors.grey600),
            const SizedBox(width: AppSpacing.sm),
            const Text('Filtrar:', style: AppTextStyles.labelLarge),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Wrap(
                spacing: AppSpacing.sm,
                children: [
                  _buildFilterChip('all', 'Todas'),
                  _buildFilterChip('pending', 'Pendientes'),
                  _buildFilterChip('accepted', 'Aceptadas'),
                  _buildFilterChip('expired', 'Expiradas'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _selectedFilter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = value;
        });
        // Aquí podrías filtrar la lista
        context.read<InvitationsBloc>().add(FilterInvitations(value));
      },
      selectedColor: AppColors.primary.withOpacity(0.2),
      checkmarkColor: AppColors.primary,
    );
  }

  Widget _buildInvitationsList() {
    return BlocBuilder<InvitationsBloc, InvitationsState>(
      builder: (context, state) {
        if (state is InvitationsLoading) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        if (state is InvitationsError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: AppColors.error,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Error al cargar invitaciones',
                  style: AppTextStyles.headline5,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  state.message,
                  style: AppTextStyles.bodyText2.copyWith(
                    color: AppColors.grey600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.lg),
                ElevatedButton.icon(
                  onPressed: () {
                    context.read<InvitationsBloc>().add(
                      const LoadInvitations(),
                    );
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reintentar'),
                ),
              ],
            ),
          );
        }

        if (state is InvitationsLoaded) {
          if (state.invitations.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.mail_outline,
                    size: 64,
                    color: AppColors.grey400,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'No hay invitaciones',
                    style: AppTextStyles.headline5.copyWith(
                      color: AppColors.grey600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Envía tu primera invitación para comenzar',
                    style: AppTextStyles.bodyText2.copyWith(
                      color: AppColors.grey500,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  ElevatedButton.icon(
                    onPressed: _showInvitationDialog,
                    icon: const Icon(Icons.person_add),
                    label: const Text('Enviar Invitación'),
                  ),
                ],
              ),
            );
          }

          return Card(
            child: ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: state.invitations.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final invitation = state.invitations[index];
                return InvitationListItem(
                  invitation: invitation,
                  onResend: () => _resendInvitation(invitation.invitationId),
                  onCancel: () => _cancelInvitation(invitation.invitationId),
                );
              },
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  void _showInvitationDialog() {
    showDialog(
      context: context,
      builder:
          (context) => BlocProvider.value(
            value: context.read<InvitationsBloc>(),
            child: const InvitationFormDialog(),
          ),
    );
  }

  void _resendInvitation(String invitationId) {
    context.read<InvitationsBloc>().add(ResendInvitation(invitationId));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Invitación reenviada'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  void _cancelInvitation(String invitationId) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Cancelar Invitación'),
            content: const Text(
              '¿Estás seguro de que quieres cancelar esta invitación?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  context.read<InvitationsBloc>().add(
                    CancelInvitation(invitationId),
                  );

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Invitación cancelada'),
                      backgroundColor: AppColors.warning,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                ),
                child: const Text('Confirmar'),
              ),
            ],
          ),
    );
  }
}
