part of 'autoreplies_bloc.dart';

abstract class AutoRepliesEvent extends Equatable {
  const AutoRepliesEvent();
  @override List<Object?> get props => [];
}

class LoadAutoRepliesEvent extends AutoRepliesEvent { const LoadAutoRepliesEvent(); }

class AddAutoReplyEvent extends AutoRepliesEvent {
  final String type, trigger, response;
  const AddAutoReplyEvent({required this.type, required this.trigger, required this.response});
  @override List<Object?> get props => [trigger];
}

class DeleteAutoReplyEvent extends AutoRepliesEvent {
  final int id;
  const DeleteAutoReplyEvent(this.id);
  @override List<Object?> get props => [id];
}