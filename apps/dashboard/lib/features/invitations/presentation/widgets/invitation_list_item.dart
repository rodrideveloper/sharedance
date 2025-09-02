import 'package:flutter/material.dart';
import 'package:shared_models/shared_models.dart';
import 'package:shared_constants/shared_constants.dart';
import 'package:intl/intl.dart';

class InvitationListItem extends StatelessWidget {
  final InvitationModel invitation;
  final VoidCallback? onResend;
  final VoidCallback? onCancel;

  const InvitationListItem({
    super.key,
    required this.invitation,
    this.onResend,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildAvatarWithRole(),
                const SizedBox(width: AppSpacing.md),
                Expanded(child: _buildInvitationInfo()),
                _buildStatusBadge(),
                const SizedBox(width: AppSpacing.sm),
                _buildActionsMenu(context),
              ],
            ),
            if (_shouldShowDetails()) ...[
              const SizedBox(height: AppSpacing.md),
              const Divider(),
              _buildInvitationDetails(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarWithRole() {
    final roleIcon = _getRoleIcon();
    final roleColor = _getRoleColor();

    return Stack(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: roleColor.withOpacity(0.1),
          child: Text(
            invitation.email.substring(0, 1).toUpperCase(),
            style: AppTextStyles.headline6.copyWith(
              color: roleColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: roleColor,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: Icon(roleIcon, size: 12, color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _buildInvitationInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          invitation.email,
          style: AppTextStyles.bodyText1.copyWith(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: [
            Icon(_getRoleIcon(), size: 16, color: _getRoleColor()),
            const SizedBox(width: AppSpacing.xs),
            Text(
              _getRoleDisplayName(),
              style: AppTextStyles.caption.copyWith(
                color: _getRoleColor(),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Invitado por ${invitation.invitedByName ?? 'Usuario'}',
          style: AppTextStyles.caption.copyWith(color: AppColors.grey600),
        ),
      ],
    );
  }

  Widget _buildStatusBadge() {
    final status = _getInvitationStatus();
    final statusColor = _getStatusColor(status);
    final statusText = _getStatusText(status);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppSpacing.sm),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_getStatusIcon(status), size: 14, color: statusColor),
          const SizedBox(width: AppSpacing.xs),
          Text(
            statusText,
            style: AppTextStyles.caption.copyWith(
              color: statusColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionsMenu(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, color: AppColors.grey600),
      itemBuilder:
          (context) => [
            if (_canResend())
              const PopupMenuItem(
                value: 'resend',
                child: Row(
                  children: [
                    Icon(Icons.send, size: 16),
                    SizedBox(width: AppSpacing.sm),
                    Text('Reenviar'),
                  ],
                ),
              ),
            if (_canCancel())
              const PopupMenuItem(
                value: 'cancel',
                child: Row(
                  children: [
                    Icon(Icons.cancel, size: 16, color: AppColors.error),
                    SizedBox(width: AppSpacing.sm),
                    Text('Cancelar', style: TextStyle(color: AppColors.error)),
                  ],
                ),
              ),
            const PopupMenuItem(
              value: 'details',
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16),
                  SizedBox(width: AppSpacing.sm),
                  Text('Ver detalles'),
                ],
              ),
            ),
          ],
      onSelected: (value) {
        switch (value) {
          case 'resend':
            onResend?.call();
            break;
          case 'cancel':
            onCancel?.call();
            break;
          case 'details':
            _showDetailsDialog(context);
            break;
        }
      },
    );
  }

  Widget _buildInvitationDetails() {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Row(
        children: [
          Expanded(
            child: _buildDetailItem(
              'Enviado',
              DateFormat('dd/MM/yyyy HH:mm').format(invitation.createdAt),
              Icons.schedule,
            ),
          ),
          Expanded(
            child: _buildDetailItem(
              'Expira',
              DateFormat('dd/MM/yyyy').format(invitation.expiresAt),
              Icons.event,
            ),
          ),
          if (invitation.usedAt != null)
            Expanded(
              child: _buildDetailItem(
                'Aceptado',
                DateFormat('dd/MM/yyyy HH:mm').format(invitation.usedAt!),
                Icons.check_circle,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.grey500),
        const SizedBox(width: AppSpacing.xs),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.grey600,
                fontSize: 10,
              ),
            ),
            Text(
              value,
              style: AppTextStyles.caption.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showDetailsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Detalles de la Invitación'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow('Email', invitation.email),
                _buildDetailRow('Rol', _getRoleDisplayName()),
                _buildDetailRow(
                  'Estado',
                  _getStatusText(_getInvitationStatus()),
                ),
                _buildDetailRow(
                  'Invitado por',
                  invitation.invitedByName ?? 'Usuario',
                ),
                _buildDetailRow(
                  'Fecha de envío',
                  DateFormat('dd/MM/yyyy HH:mm').format(invitation.createdAt),
                ),
                _buildDetailRow(
                  'Fecha de expiración',
                  DateFormat('dd/MM/yyyy HH:mm').format(invitation.expiresAt),
                ),
                if (invitation.usedAt != null)
                  _buildDetailRow(
                    'Fecha de aceptación',
                    DateFormat('dd/MM/yyyy HH:mm').format(invitation.usedAt!),
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cerrar'),
              ),
            ],
          ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: AppTextStyles.caption.copyWith(
                fontWeight: FontWeight.w500,
                color: AppColors.grey600,
              ),
            ),
          ),
          Expanded(child: Text(value, style: AppTextStyles.caption)),
        ],
      ),
    );
  }

  // Helper methods
  IconData _getRoleIcon() {
    switch (invitation.role) {
      case UserRole.admin:
        return Icons.admin_panel_settings;
      case UserRole.teacher:
        return Icons.school;
      case UserRole.student:
        return Icons.person;
    }
  }

  Color _getRoleColor() {
    switch (invitation.role) {
      case UserRole.admin:
        return AppColors.error;
      case UserRole.teacher:
        return AppColors.primary;
      case UserRole.student:
        return AppColors.success;
    }
  }

  String _getRoleDisplayName() {
    switch (invitation.role) {
      case UserRole.admin:
        return 'Administrador';
      case UserRole.teacher:
        return 'Profesor';
      case UserRole.student:
        return 'Estudiante';
    }
  }

  InvitationStatus _getInvitationStatus() {
    if (invitation.isUsed) {
      return InvitationStatus.accepted;
    } else if (invitation.expiresAt.isBefore(DateTime.now())) {
      return InvitationStatus.expired;
    } else {
      return InvitationStatus.pending;
    }
  }

  Color _getStatusColor(InvitationStatus status) {
    switch (status) {
      case InvitationStatus.pending:
        return AppColors.warning;
      case InvitationStatus.accepted:
        return AppColors.success;
      case InvitationStatus.expired:
        return AppColors.error;
    }
  }

  String _getStatusText(InvitationStatus status) {
    switch (status) {
      case InvitationStatus.pending:
        return 'Pendiente';
      case InvitationStatus.accepted:
        return 'Aceptada';
      case InvitationStatus.expired:
        return 'Expirada';
    }
  }

  IconData _getStatusIcon(InvitationStatus status) {
    switch (status) {
      case InvitationStatus.pending:
        return Icons.schedule;
      case InvitationStatus.accepted:
        return Icons.check_circle;
      case InvitationStatus.expired:
        return Icons.cancel;
    }
  }

  bool _canResend() {
    final status = _getInvitationStatus();
    return status == InvitationStatus.pending ||
        status == InvitationStatus.expired;
  }

  bool _canCancel() {
    return _getInvitationStatus() == InvitationStatus.pending;
  }

  bool _shouldShowDetails() {
    return true; // Siempre mostrar detalles por ahora
  }
}

enum InvitationStatus { pending, accepted, expired }
