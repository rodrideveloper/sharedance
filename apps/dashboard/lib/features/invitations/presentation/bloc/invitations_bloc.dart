import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:shared_models/shared_models.dart';
import 'package:shared_services/shared_services.dart';

// Events
abstract class InvitationsEvent extends Equatable {
  const InvitationsEvent();

  @override
  List<Object?> get props => [];
}

class LoadInvitations extends InvitationsEvent {
  const LoadInvitations();
}

class SendInvitation extends InvitationsEvent {
  final String email;
  final UserRole role;
  final String? customMessage;

  const SendInvitation({
    required this.email,
    required this.role,
    this.customMessage,
  });

  @override
  List<Object?> get props => [email, role, customMessage];
}

class FilterInvitations extends InvitationsEvent {
  final String filter;

  const FilterInvitations(this.filter);

  @override
  List<Object> get props => [filter];
}

class ResendInvitation extends InvitationsEvent {
  final String invitationId;

  const ResendInvitation(this.invitationId);

  @override
  List<Object> get props => [invitationId];
}

class CancelInvitation extends InvitationsEvent {
  final String invitationId;

  const CancelInvitation(this.invitationId);

  @override
  List<Object> get props => [invitationId];
}

// States
abstract class InvitationsState extends Equatable {
  const InvitationsState();

  @override
  List<Object?> get props => [];
}

class InvitationsInitial extends InvitationsState {}

class InvitationsLoading extends InvitationsState {}

class InvitationsLoaded extends InvitationsState {
  final List<InvitationModel> invitations;
  final String currentFilter;

  const InvitationsLoaded({
    required this.invitations,
    this.currentFilter = 'all',
  });

  @override
  List<Object> get props => [invitations, currentFilter];
}

class InvitationsError extends InvitationsState {
  final String message;

  const InvitationsError(this.message);

  @override
  List<Object> get props => [message];
}

class InvitationSending extends InvitationsState {}

class InvitationSent extends InvitationsState {
  final String message;

  const InvitationSent(this.message);

  @override
  List<Object> get props => [message];
}

class InvitationSendError extends InvitationsState {
  final String message;

  const InvitationSendError(this.message);

  @override
  List<Object> get props => [message];
}

// BLoC
class InvitationsBloc extends Bloc<InvitationsEvent, InvitationsState> {
  final InvitationService _invitationService;
  List<InvitationModel> _allInvitations = [];

  InvitationsBloc({required InvitationService invitationService})
    : _invitationService = invitationService,
      super(InvitationsInitial()) {
    on<LoadInvitations>(_onLoadInvitations);
    on<SendInvitation>(_onSendInvitation);
    on<FilterInvitations>(_onFilterInvitations);
    on<ResendInvitation>(_onResendInvitation);
    on<CancelInvitation>(_onCancelInvitation);
  }

  Future<void> _onLoadInvitations(
    LoadInvitations event,
    Emitter<InvitationsState> emit,
  ) async {
    try {
      emit(InvitationsLoading());

      final invitations = await _invitationService.getInvitations();
      _allInvitations = invitations;

      emit(InvitationsLoaded(invitations: invitations));
    } catch (e) {
      emit(InvitationsError('Error cargando invitaciones: ${e.toString()}'));
    }
  }

  Future<void> _onSendInvitation(
    SendInvitation event,
    Emitter<InvitationsState> emit,
  ) async {
    try {
      emit(InvitationSending());

      final result = await _invitationService.sendInvitation(
        email: event.email,
        role: event.role,
        customMessage: event.customMessage,
      );

      if (result.success) {
        emit(InvitationSent(result.message));
        // Recargar las invitaciones
        add(const LoadInvitations());
      } else {
        emit(InvitationSendError(result.message));
      }
    } catch (e) {
      emit(InvitationSendError('Error enviando invitación: ${e.toString()}'));
    }
  }

  void _onFilterInvitations(
    FilterInvitations event,
    Emitter<InvitationsState> emit,
  ) {
    final filteredInvitations = _filterInvitations(event.filter);
    emit(
      InvitationsLoaded(
        invitations: filteredInvitations,
        currentFilter: event.filter,
      ),
    );
  }

  Future<void> _onResendInvitation(
    ResendInvitation event,
    Emitter<InvitationsState> emit,
  ) async {
    try {
      final success = await _invitationService.resendInvitation(
        event.invitationId,
      );
      if (success) {
        // Recargar las invitaciones
        add(const LoadInvitations());
      }
    } catch (e) {
      emit(InvitationsError('Error reenviando invitación: ${e.toString()}'));
    }
  }

  Future<void> _onCancelInvitation(
    CancelInvitation event,
    Emitter<InvitationsState> emit,
  ) async {
    try {
      final success = await _invitationService.cancelInvitation(
        event.invitationId,
      );
      if (success) {
        // Recargar las invitaciones
        add(const LoadInvitations());
      }
    } catch (e) {
      emit(InvitationsError('Error cancelando invitación: ${e.toString()}'));
    }
  }

  List<InvitationModel> _filterInvitations(String filter) {
    switch (filter) {
      case 'pending':
        return _allInvitations
            .where((inv) => !inv.isUsed && !_isExpired(inv))
            .toList();
      case 'accepted':
        return _allInvitations.where((inv) => inv.isUsed).toList();
      case 'expired':
        return _allInvitations
            .where((inv) => _isExpired(inv) && !inv.isUsed)
            .toList();
      default:
        return _allInvitations;
    }
  }

  bool _isExpired(InvitationModel invitation) {
    return invitation.expiresAt.isBefore(DateTime.now());
  }
}
