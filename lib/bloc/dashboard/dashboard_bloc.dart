import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../models/models.dart';
import '../../services/api_service.dart';
import '../../services/socket_service.dart';

part 'dashboard_event.dart';
part 'dashboard_state.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final ApiService _api;
  final SocketService _socket;

  Timer? _statsTimer;
  Timer? _convsTimer;
  Timer? _typingTimer;

  final Set<String> _pendingMessages = {};
  final Set<int> _unreadSet = {};

  bool _started = false;

  DashboardBloc({required ApiService api, required SocketService socket})
    : _api = api,
      _socket = socket,
      super(const DashboardInitial()) {
    on<InitDashboardEvent>(_onInit);
    on<ShutdownDashboardEvent>(_onShutdown);
    on<LoadConversationsEvent>(_onLoadConversations);
    on<SelectConversationEvent>(_onSelectConversation);
    on<SendMessageEvent>(_onSendMessage);
    on<TakeOverEvent>(_onTakeOver);
    on<CloseConversationEvent>(_onCloseConversation);
    on<SwitchTabEvent>(_onSwitchTab);
    on<SearchConversationsEvent>(_onSearch);
    on<RefreshStatsEvent>(_onRefreshStats);
    on<SocketMessageReceivedEvent>(_onSocketMessage);
    on<SocketVisitorWaitingEvent>(_onSocketWaiting);
    on<SocketVisitorTypingEvent>(_onSocketTyping);
    on<SocketVisitorOfflineEvent>(_onSocketOffline);
    on<SocketConvUpdatedEvent>(_onSocketConvUpdated);
    on<HideTypingEvent>(_onHideTyping);
  }

  // ── Init ────────────────────────────────────────────────────
  Future<void> _onInit(
    InitDashboardEvent e,
    Emitter<DashboardState> emit,
  ) async {
    if (_started) return;
    _started = true;

    // ✅ Only assign callbacks if not already set
    // Prevents double-registration if _onInit somehow fires twice
    _socket.onMessage ??= (id, type, body, at) =>
        add(SocketMessageReceivedEvent(id, type, body, at));
    _socket.onWaiting ??= (id) => add(SocketVisitorWaitingEvent(id));
    _socket.onVisitorTyping ??= (id) => add(SocketVisitorTypingEvent(id));
    _socket.onVisitorOffline ??= (id) => add(SocketVisitorOfflineEvent(id));
    _socket.onConvUpdated ??= (id, s) => add(SocketConvUpdatedEvent(id, s));

    emit(DashboardLoaded.initial());
    add(const LoadConversationsEvent('waiting'));
    add(const RefreshStatsEvent());

    _statsTimer = Timer.periodic(
      const Duration(seconds: 15),
      (_) => add(const RefreshStatsEvent()),
    );
    _convsTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => add(const LoadConversationsEvent(null)),
    );
  }

  // ── Shutdown ────────────────────────────────────────────────
  Future<void> _onShutdown(
    ShutdownDashboardEvent e,
    Emitter<DashboardState> emit,
  ) async {
    _statsTimer?.cancel();
    _convsTimer?.cancel();
    _typingTimer?.cancel();
    _statsTimer = null;
    _convsTimer = null;
    _typingTimer = null;
    _unreadSet.clear();
    _pendingMessages.clear();
    _started = false;
    emit(const DashboardInitial());
  }

  // ── Load Conversations ──────────────────────────────────────
  Future<void> _onLoadConversations(
    LoadConversationsEvent e,
    Emitter<DashboardState> emit,
  ) async {
    if (state is! DashboardLoaded) return;
    final s = state as DashboardLoaded;
    final tab = e.status ?? s.activeTab;

    try {
      final res = await _api.getConversations(tab);
      final list = (res.data as List)
          .map((j) => Conversation.fromJson(j as Map<String, dynamic>))
          .toList();
      emit(
        s.copyWith(
          conversations: list,
          activeTab: tab,
          unreadIds: Set.from(_unreadSet),
        ),
      );
    } catch (err) {
      print('loadConversations error: $err');
    }
  }

  // ── Select Conversation ─────────────────────────────────────
  Future<void> _onSelectConversation(
    SelectConversationEvent e,
    Emitter<DashboardState> emit,
  ) async {
    if (state is! DashboardLoaded) return;
    final s = state as DashboardLoaded;

    // Leave previous room
    if (s.activeConv != null && s.activeConv!.id != e.conv.id) {
      _socket.leaveConv(s.activeConv!.id);
    }

    _unreadSet.remove(e.conv.id);

    // Show loading state — do NOT join socket room yet
    emit(
      s.copyWith(
        activeConv: e.conv,
        messages: [],
        messagesState: MessagesLoadState.loading,
        showTyping: false,
        unreadIds: Set.from(_unreadSet),
      ),
    );

    try {
      // ── Step 1: Load history from REST API first ──────────────────────────
      final res = await _api.getMessages(e.conv.id);
      final msgs = (res.data as List)
          .map((j) => ChatMessage.fromJson(j as Map<String, dynamic>))
          .toList();

      if (state is DashboardLoaded) {
        emit(
          (state as DashboardLoaded).copyWith(
            messages: msgs,
            messagesState: MessagesLoadState.loaded,
          ),
        );
      }

      // ── Step 2: Join socket room AFTER history is rendered ────────────────
      // This prevents the socket from firing conversation:message events for
      // messages that are already in the history response, which caused every
      // message to appear twice (once from REST, once from socket echo).
      _socket.joinConv(e.conv.id);
    } catch (err) {
      print('fetchMessages error: $err');
      if (state is DashboardLoaded) {
        emit(
          (state as DashboardLoaded).copyWith(
            messagesState: MessagesLoadState.error,
          ),
        );
      }
      // Still join even on error so live messages work
      _socket.joinConv(e.conv.id);
    }
  }

  // ── Send Message ────────────────────────────────────────────
  Future<void> _onSendMessage(
    SendMessageEvent e,
    Emitter<DashboardState> emit,
  ) async {
    if (state is! DashboardLoaded) return;
    final s = state as DashboardLoaded;
    if (s.activeConv == null) return;

    // Optimistic render — add to UI immediately
    _pendingMessages.add(e.text);
    final optimisticMsg = ChatMessage(
      senderType: 'admin',
      body: e.text,
      createdAt: DateTime.now(),
    );
    emit(s.copyWith(messages: [...s.messages, optimisticMsg]));

    final ack = await _socket.sendMessage(s.activeConv!.id, e.text);

    if (ack['error'] != null) {
      // Failed — remove optimistic message
      _pendingMessages.remove(e.text);
      if (state is DashboardLoaded) {
        final current = state as DashboardLoaded;
        emit(
          current.copyWith(
            messages: current.messages
                .where((m) => m != optimisticMsg)
                .toList(),
            toastMessage: '❌ Send failed: ${ack['error']}',
          ),
        );
      }
    }
    // On success: nothing extra — optimistic bubble is already shown
  }

  // ── Take Over ───────────────────────────────────────────────
  Future<void> _onTakeOver(
    TakeOverEvent e,
    Emitter<DashboardState> emit,
  ) async {
    if (state is! DashboardLoaded) return;
    final s = state as DashboardLoaded;
    if (s.activeConv == null) return;

    final ack = await _socket.takeOver(s.activeConv!.id);
    if (ack['success'] == true) {
      final updated = s.activeConv!.copyWith(status: 'active');
      final convs = s.conversations
          .map((c) => c.id == updated.id ? updated : c)
          .toList();
      emit(
        s.copyWith(
          activeConv: updated,
          conversations: convs,
          toastMessage: '✅ You took over this conversation',
        ),
      );
    } else {
      emit(
        s.copyWith(
          toastMessage: '❌ Takeover failed: ${ack['error'] ?? 'unknown'}',
        ),
      );
    }
  }

  // ── Close Conversation ──────────────────────────────────────
  Future<void> _onCloseConversation(
    CloseConversationEvent e,
    Emitter<DashboardState> emit,
  ) async {
    if (state is! DashboardLoaded) return;
    final s = state as DashboardLoaded;
    if (s.activeConv == null) return;

    final ack = await _socket.closeConversation(s.activeConv!.id);
    if (ack['success'] == true) {
      _socket.leaveConv(s.activeConv!.id);
      emit(
        s.copyWith(
          activeConv: null,
          messages: [],
          clearActive: true,
          toastMessage: '✅ Conversation closed',
        ),
      );
      add(const LoadConversationsEvent(null));
    } else {
      emit(
        s.copyWith(
          toastMessage: '❌ Close failed: ${ack['error'] ?? 'unknown'}',
        ),
      );
    }
  }

  // ── Switch Tab ──────────────────────────────────────────────
  Future<void> _onSwitchTab(
    SwitchTabEvent e,
    Emitter<DashboardState> emit,
  ) async {
    if (state is! DashboardLoaded) return;
    final s = state as DashboardLoaded;
    emit(
      s.copyWith(
        activeTab: e.tab,
        activeConv: null,
        messages: [],
        clearActive: true,
      ),
    );
    add(LoadConversationsEvent(e.tab));
  }

  // ── Search ──────────────────────────────────────────────────
  Future<void> _onSearch(
    SearchConversationsEvent e,
    Emitter<DashboardState> emit,
  ) async {
    if (state is! DashboardLoaded) return;
    emit((state as DashboardLoaded).copyWith(searchQuery: e.query));
  }

  // ── Stats ───────────────────────────────────────────────────
  Future<void> _onRefreshStats(
    RefreshStatsEvent e,
    Emitter<DashboardState> emit,
  ) async {
    try {
      final res = await _api.getStats();
      final stats = DashboardStats.fromJson(res.data as Map<String, dynamic>);
      if (state is DashboardLoaded) {
        emit((state as DashboardLoaded).copyWith(stats: stats));
      }
    } catch (err) {
      print('refreshStats error: $err');
    }
  }

  // ── Socket: incoming message ────────────────────────────────
  Future<void> _onSocketMessage(
    SocketMessageReceivedEvent e,
    Emitter<DashboardState> emit,
  ) async {
    print(e.body);
    if (state is! DashboardLoaded) return;
    final s = state as DashboardLoaded;

    // Skip our own optimistic echo
    if (e.senderType == 'admin' && _pendingMessages.contains(e.body)) {
      _pendingMessages.remove(e.body);
      return;
    }

    if (e.convId == s.activeConv?.id) {
      final msg = ChatMessage(
        senderType: e.senderType,
        body: e.body,
        createdAt: e.createdAt,
      );
      emit(s.copyWith(messages: [...s.messages, msg]));
    } else {
      // Update last message preview + unread badge
      _unreadSet.add(e.convId);
      final updatedConvs = s.conversations.map((c) {
        if (c.id == e.convId) {
          return c.copyWith(lastMessage: e.body, lastMessageAt: e.createdAt);
        }
        return c;
      }).toList();
      emit(
        s.copyWith(
          conversations: updatedConvs,
          unreadIds: Set.from(_unreadSet),
        ),
      );
    }
    add(const RefreshStatsEvent());
  }

  Future<void> _onSocketWaiting(
    SocketVisitorWaitingEvent e,
    Emitter<DashboardState> emit,
  ) async {
    _unreadSet.add(e.convId);
    if (state is DashboardLoaded) {
      emit(
        (state as DashboardLoaded).copyWith(
          unreadIds: Set.from(_unreadSet),
          toastMessage: '🔔 New visitor waiting for support!',
        ),
      );
    }
    add(const LoadConversationsEvent(null));
  }

  Future<void> _onSocketTyping(
    SocketVisitorTypingEvent e,
    Emitter<DashboardState> emit,
  ) async {
    if (state is! DashboardLoaded) return;
    final s = state as DashboardLoaded;
    if (e.convId != s.activeConv?.id) return;

    _typingTimer?.cancel();
    emit(s.copyWith(showTyping: true));
    _typingTimer = Timer(
      const Duration(milliseconds: 2500),
      () => add(const HideTypingEvent()),
    );
  }

  Future<void> _onSocketOffline(
    SocketVisitorOfflineEvent e,
    Emitter<DashboardState> emit,
  ) async {
    if (state is! DashboardLoaded) return;
    final s = state as DashboardLoaded;
    if (e.convId == s.activeConv?.id) {
      emit(s.copyWith(toastMessage: '⚠️ Visitor disconnected'));
    }
  }

  Future<void> _onSocketConvUpdated(
    SocketConvUpdatedEvent e,
    Emitter<DashboardState> emit,
  ) async {
    if (state is! DashboardLoaded) return;
    final s = state as DashboardLoaded;
    final convs = s.conversations
        .map((c) => c.id == e.convId ? c.copyWith(status: e.status) : c)
        .toList();
    final active = s.activeConv?.id == e.convId
        ? s.activeConv!.copyWith(status: e.status)
        : s.activeConv;
    emit(s.copyWith(conversations: convs, activeConv: active));
  }

  Future<void> _onHideTyping(
    HideTypingEvent e,
    Emitter<DashboardState> emit,
  ) async {
    if (state is DashboardLoaded) {
      emit((state as DashboardLoaded).copyWith(showTyping: false));
    }
  }

  @override
  Future<void> close() {
    _statsTimer?.cancel();
    _convsTimer?.cancel();
    _typingTimer?.cancel();
    return super.close();
  }
}
