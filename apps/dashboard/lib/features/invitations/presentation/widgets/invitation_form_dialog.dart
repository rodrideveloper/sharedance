import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_models/shared_models.dart';
import 'package:shared_constants/shared_constants.dart';
import '../bloc/invitations_bloc.dart';

class InvitationFormDialog extends StatefulWidget {
  const InvitationFormDialog({super.key});

  @override
  State<InvitationFormDialog> createState() => _InvitationFormDialogState();
}

class _InvitationFormDialogState extends State<InvitationFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _messageController = TextEditingController();
  UserRole _selectedRole = UserRole.teacher;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<InvitationsBloc, InvitationsState>(
      listener: (context, state) {
        if (state is InvitationSending) {
          setState(() {
            _isLoading = true;
          });
        } else if (state is InvitationSent) {
          setState(() {
            _isLoading = false;
          });
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.success,
            ),
          );
        } else if (state is InvitationSendError) {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
      child: AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.person_add, color: AppColors.primary),
            const SizedBox(width: AppSpacing.sm),
            const Text('Enviar Invitación'),
          ],
        ),
        content: SizedBox(
          width: 400,
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildEmailField(),
                const SizedBox(height: AppSpacing.lg),
                _buildRoleSelector(),
                const SizedBox(height: AppSpacing.lg),
                _buildMessageField(),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: _isLoading ? null : _sendInvitation,
            child:
                _isLoading
                    ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                    : const Text('Enviar Invitación'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmailField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Email del usuario *',
          style: AppTextStyles.labelLarge.copyWith(color: AppColors.onSurface),
        ),
        const SizedBox(height: AppSpacing.xs),
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            hintText: 'usuario@ejemplo.com',
            prefixIcon: const Icon(Icons.email_outlined),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.sm),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.sm),
              borderSide: const BorderSide(color: AppColors.grey300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.sm),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'El email es requerido';
            }
            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
              return 'Ingresa un email válido';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildRoleSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Rol del usuario *',
          style: AppTextStyles.labelLarge.copyWith(color: AppColors.onSurface),
        ),
        const SizedBox(height: AppSpacing.sm),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.grey300),
            borderRadius: BorderRadius.circular(AppSpacing.sm),
          ),
          child: Column(
            children: [
              _buildRoleOption(
                UserRole.teacher,
                'Profesor',
                'Puede gestionar clases y ver estudiantes',
                Icons.school,
              ),
              const Divider(height: 1),
              _buildRoleOption(
                UserRole.admin,
                'Administrador',
                'Acceso completo al sistema',
                Icons.admin_panel_settings,
              ),
              const Divider(height: 1),
              _buildRoleOption(
                UserRole.student,
                'Estudiante',
                'Puede reservar y ver clases',
                Icons.person,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRoleOption(
    UserRole role,
    String title,
    String description,
    IconData icon,
  ) {
    final isSelected = _selectedRole == role;
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? AppColors.primary : AppColors.grey500,
      ),
      title: Text(
        title,
        style: AppTextStyles.labelLarge.copyWith(
          color: isSelected ? AppColors.primary : AppColors.onSurface,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
        ),
      ),
      subtitle: Text(
        description,
        style: AppTextStyles.caption.copyWith(color: AppColors.grey600),
      ),
      trailing: Radio<UserRole>(
        value: role,
        groupValue: _selectedRole,
        onChanged: (UserRole? value) {
          setState(() {
            _selectedRole = value!;
          });
        },
        activeColor: AppColors.primary,
      ),
      onTap: () {
        setState(() {
          _selectedRole = role;
        });
      },
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.sm),
      ),
      selectedTileColor: AppColors.primary.withOpacity(0.1),
      selected: isSelected,
    );
  }

  Widget _buildMessageField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Mensaje personalizado (opcional)',
          style: AppTextStyles.labelLarge.copyWith(color: AppColors.onSurface),
        ),
        const SizedBox(height: AppSpacing.xs),
        TextFormField(
          controller: _messageController,
          maxLines: 3,
          maxLength: 500,
          decoration: InputDecoration(
            hintText: 'Escribe un mensaje personalizado para el usuario...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.sm),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.sm),
              borderSide: const BorderSide(color: AppColors.grey300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.sm),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  void _sendInvitation() {
    if (_formKey.currentState!.validate()) {
      context.read<InvitationsBloc>().add(
        SendInvitation(
          email: _emailController.text.trim(),
          role: _selectedRole,
          customMessage:
              _messageController.text.trim().isNotEmpty
                  ? _messageController.text.trim()
                  : null,
        ),
      );
    }
  }
}
