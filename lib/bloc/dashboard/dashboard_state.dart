part of 'dashboard_bloc.dart';

enum MessagesLoadState { idle, loading, loaded, error }

abstract class DashboardState extends Equatable {
  const DashboardState();
  @override
  List<Object?> get props => [];
}

class DashboardInitial extends DashboardState {
  const DashboardInitial();
}

class DashboardLoaded extends DashboardState {
  final List<Conversation> conversations;
  final Conversation? activeConv;
  final List<ChatMessage> messages;
  final MessagesLoadState messagesState;
  final DashboardStats stats;
  final String activeTab;
  final String searchQuery;
  final Set<int> unreadIds;
  final bool showTyping;
  final String? toastMessage;

  const DashboardLoaded({
    required this.conversations,
    this.activeConv,
    required this.messages,
    this.messagesState = MessagesLoadState.idle,
    required this.stats,
    required this.activeTab,
    this.searchQuery = '',
    required this.unreadIds,
    this.showTyping = false,
    this.toastMessage,
  });

  factory DashboardLoaded.initial() => DashboardLoaded(
    conversations: const [],
    messages: const [],
    stats: const DashboardStats(),
    activeTab: 'waiting',
    unreadIds: {},
  );

  List<Conversation> get filteredConversations {
    if (searchQuery.isEmpty) return conversations;
    final q = searchQuery.toLowerCase();
    return conversations
        .where(
          (c) =>
              c.visitorName.toLowerCase().contains(q) ||
              (c.lastMessage?.toLowerCase().contains(q) ?? false) ||
              c.id.toString().contains(q),
        )
        .toList();
  }

  DashboardLoaded copyWith({
    List<Conversation>? conversations,
    Conversation? activeConv,
    bool clearActive = false,
    List<ChatMessage>? messages,
    MessagesLoadState? messagesState,
    DashboardStats? stats,
    String? activeTab,
    String? searchQuery,
    Set<int>? unreadIds,
    bool? showTyping,
    String? toastMessage,
  }) => DashboardLoaded(
    conversations: conversations ?? this.conversations,
    activeConv: clearActive ? null : (activeConv ?? this.activeConv),
    messages: messages ?? this.messages,
    messagesState: messagesState ?? this.messagesState,
    stats: stats ?? this.stats,
    activeTab: activeTab ?? this.activeTab,
    searchQuery: searchQuery ?? this.searchQuery,
    unreadIds: unreadIds ?? this.unreadIds,
    showTyping: showTyping ?? this.showTyping,
    toastMessage: toastMessage,
  );

  @override
  List<Object?> get props => [
    conversations,
    activeConv,
    messages,
    messagesState,
    stats,
    activeTab,
    searchQuery,
    unreadIds,
    showTyping,
    toastMessage,
  ];
}
