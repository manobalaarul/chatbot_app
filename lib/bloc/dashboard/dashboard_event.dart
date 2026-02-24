part of 'dashboard_bloc.dart';

abstract class DashboardEvent extends Equatable {
  const DashboardEvent();
  @override List<Object?> get props => [];
}

class InitDashboardEvent     extends DashboardEvent { const InitDashboardEvent(); }
class ShutdownDashboardEvent extends DashboardEvent { const ShutdownDashboardEvent(); }

class LoadConversationsEvent extends DashboardEvent {
  final String? status;
  const LoadConversationsEvent(this.status);
  @override List<Object?> get props => [status];
}

class SelectConversationEvent extends DashboardEvent {
  final Conversation conv;
  const SelectConversationEvent(this.conv);
  @override List<Object?> get props => [conv.id];
}

class SendMessageEvent extends DashboardEvent {
  final String text;
  const SendMessageEvent(this.text);
  @override List<Object?> get props => [text];
}

class TakeOverEvent         extends DashboardEvent { const TakeOverEvent(); }
class CloseConversationEvent extends DashboardEvent { const CloseConversationEvent(); }

class SwitchTabEvent extends DashboardEvent {
  final String tab;
  const SwitchTabEvent(this.tab);
  @override List<Object?> get props => [tab];
}

class SearchConversationsEvent extends DashboardEvent {
  final String query;
  const SearchConversationsEvent(this.query);
  @override List<Object?> get props => [query];
}

class RefreshStatsEvent extends DashboardEvent { const RefreshStatsEvent(); }
class HideTypingEvent   extends DashboardEvent { const HideTypingEvent(); }

// Socket-driven
class SocketMessageReceivedEvent extends DashboardEvent {
  final int     convId;
  final String  senderType;
  final String  body;
  final DateTime createdAt;
  const SocketMessageReceivedEvent(this.convId, this.senderType, this.body, this.createdAt);
  @override List<Object?> get props => [convId, body];
}

class SocketVisitorWaitingEvent  extends DashboardEvent {
  final int convId;
  const SocketVisitorWaitingEvent(this.convId);
  @override List<Object?> get props => [convId];
}

class SocketVisitorTypingEvent extends DashboardEvent {
  final int convId;
  const SocketVisitorTypingEvent(this.convId);
  @override List<Object?> get props => [convId];
}

class SocketVisitorOfflineEvent extends DashboardEvent {
  final int convId;
  const SocketVisitorOfflineEvent(this.convId);
  @override List<Object?> get props => [convId];
}

class SocketConvUpdatedEvent extends DashboardEvent {
  final int    convId;
  final String status;
  const SocketConvUpdatedEvent(this.convId, this.status);
  @override List<Object?> get props => [convId, status];
}