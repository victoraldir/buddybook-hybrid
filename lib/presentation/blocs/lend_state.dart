// lib/presentation/blocs/lend_state.dart

part of 'lend_bloc.dart';

abstract class LendState extends Equatable {
  const LendState();

  @override
  List<Object?> get props => [];
}

class LendInitial extends LendState {
  const LendInitial();
}

class LendLoading extends LendState {
  const LendLoading();
}

class LendsLoaded extends LendState {
  final List<dynamic> lends;

  const LendsLoaded({required this.lends});

  @override
  List<Object> get props => [lends];
}

class LendCreated extends LendState {
  const LendCreated();
}

class LendUpdated extends LendState {
  const LendUpdated();
}

class LendDeleted extends LendState {
  const LendDeleted();
}

class LendError extends LendState {
  final String message;

  const LendError({required this.message});

  @override
  List<Object> get props => [message];
}
