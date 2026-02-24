part of 'autoreplies_bloc.dart';

abstract class AutoRepliesState extends Equatable {
  const AutoRepliesState();
  @override List<Object?> get props => [];
}

class AutoRepliesInitial extends AutoRepliesState { const AutoRepliesInitial(); }
class AutoRepliesLoading extends AutoRepliesState { const AutoRepliesLoading(); }

class AutoRepliesLoaded extends AutoRepliesState {
  final List<AutoReply> rules;
  const AutoRepliesLoaded(this.rules);
  @override List<Object?> get props => [rules];
}

class AutoRepliesError extends AutoRepliesState {
  final String message;
  const AutoRepliesError(this.message);
  @override List<Object?> get props => [message];
}