import 'dart:async';

import 'package:socket_io_client/socket_io_client.dart' as IO;

import '../core/app_config.dart';

typedef MessageCallback =
    void Function(
      int convId,
      String senderType,
      String body,
      DateTime createdAt,
    );
typedef ConvCallback = void Function(int convId);
typedef ConvUpdatedCallback = void Function(int convId, String status);

class SocketService {
  IO.Socket? _socket;
  int? _activeConvId;

  // ── Callbacks set by DashboardBloc ────────────────────────────────────────
  MessageCallback? onMessage;
  ConvCallback? onWaiting;
  ConvCallback? onVisitorTyping;
  ConvCallback? onVisitorOffline;
  ConvUpdatedCallback? onConvUpdated;

  bool get isConnected => _socket?.connected ?? false;

  // ── Track whether listeners have been registered on this socket instance ──
  bool _listenersRegistered = false;

  void connect(String token) {
    // Already connected — do nothing
    if (_socket != null && _socket!.connected) return;

    // If socket exists but is disconnected, destroy it fully first
    if (_socket != null) {
      _socket!.dispose();
      _socket = null;
      _listenersRegistered = false;
    }

    _socket = IO.io(
      AppConfig.socketUrl,
      IO.OptionBuilder()
          .setTransports(['websocket', 'polling'])
          .setPath('/socket.io')
          .setAuth({'token': token})
          .setReconnectionAttempts(10)
          .setReconnectionDelay(2000)
          .disableAutoConnect()
          .build(),
    );

    _registerListeners();
    _socket!.connect();
  }

  // ── Register listeners ONCE per socket instance ───────────────────────────
  // The key insight: we register ONE handler per event that simply calls
  // the current value of the callback field. This way:
  // - The socket listener is registered exactly once (guarded by _listenersRegistered)
  // - The callback can be swapped (??= in bloc) without re-registering socket listeners
  // - Reconnects reuse the same socket object and same listeners — no stacking
  void _registerListeners() {
    if (_listenersRegistered) return;
    _listenersRegistered = true;

    _socket!.onConnect((_) {
      print('✅ Admin socket connected: ${_socket?.id}');
      if (_activeConvId != null) {
        _socket!.emit('admin:join', {'conversationId': _activeConvId});
      }
    });

    _socket!.onDisconnect((r) => print('⚠️ Socket disconnected: $r'));
    _socket!.onConnectError((e) => print('❌ Socket error: $e'));

    // ── Each handler calls the CURRENT callback value ─────────────────────
    // If onMessage is replaced later, the new one is called automatically.
    // This is the single source of truth — registered once, never stacked.

    _socket!.on('conversation:message', (raw) {
      final m = _asMap(raw);
      if (m == null) return;
      // Add debug print here to verify this fires only ONCE per message
      print('🔌 socket raw message: ${m['body']}');
      onMessage?.call(
        _toInt(m['conversationId']),
        _str(m['senderType']),
        _str(m['body']),
        _toDate(m['createdAt']),
      );
    });

    _socket!.on('conversation:waiting', (raw) {
      final m = _asMap(raw);
      if (m == null) return;
      onWaiting?.call(_toInt(m['conversationId']));
    });

    _socket!.on('visitor:typing', (raw) {
      final m = _asMap(raw);
      if (m == null) return;
      onVisitorTyping?.call(_toInt(m['conversationId']));
    });

    _socket!.on('visitor:offline', (raw) {
      final m = _asMap(raw);
      if (m == null) return;
      onVisitorOffline?.call(_toInt(m['conversationId']));
    });

    _socket!.on('conversation:updated', (raw) {
      final m = _asMap(raw);
      if (m == null) return;
      onConvUpdated?.call(_toInt(m['conversationId']), _str(m['status']));
    });
  }

  void disconnect() {
    _socket?.dispose();
    _socket = null;
    _activeConvId = null;
    _listenersRegistered = false;
  }

  // ── Room management ────────────────────────────────────────────────────────
  void joinConv(int convId) {
    _activeConvId = convId;
    _socket?.emit('admin:join', {'conversationId': convId});
  }

  void leaveConv(int convId) {
    if (_activeConvId == convId) _activeConvId = null;
    _socket?.emit('admin:leave', {'conversationId': convId});
  }

  // ── Actions ────────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> sendMessage(int convId, String text) {
    final completer = Completer<Map<String, dynamic>>();
    if (_socket == null || !_socket!.connected) {
      completer.complete({'error': 'Not connected'});
      return completer.future;
    }
    _socket!.emitWithAck(
      'admin:message',
      {'conversationId': convId, 'text': text},
      ack: (data) {
        if (!completer.isCompleted) {
          completer.complete(_asMap(data) ?? {});
        }
      },
    );
    Future.delayed(const Duration(seconds: 8), () {
      if (!completer.isCompleted) completer.complete({'error': 'Ack timeout'});
    });
    return completer.future;
  }

  Future<Map<String, dynamic>> takeOver(int convId) {
    final completer = Completer<Map<String, dynamic>>();
    if (_socket == null || !_socket!.connected) {
      completer.complete({'error': 'Not connected'});
      return completer.future;
    }
    _socket!.emitWithAck(
      'admin:takeover',
      {'conversationId': convId},
      ack: (data) {
        if (!completer.isCompleted) completer.complete(_asMap(data) ?? {});
      },
    );
    Future.delayed(const Duration(seconds: 8), () {
      if (!completer.isCompleted) completer.complete({'error': 'Ack timeout'});
    });
    return completer.future;
  }

  Future<Map<String, dynamic>> closeConversation(int convId) {
    final completer = Completer<Map<String, dynamic>>();
    if (_socket == null || !_socket!.connected) {
      completer.complete({'error': 'Not connected'});
      return completer.future;
    }
    _socket!.emitWithAck(
      'admin:close',
      {'conversationId': convId},
      ack: (data) {
        if (!completer.isCompleted) completer.complete(_asMap(data) ?? {});
      },
    );
    Future.delayed(const Duration(seconds: 8), () {
      if (!completer.isCompleted) completer.complete({'error': 'Ack timeout'});
    });
    return completer.future;
  }

  // ── Safe type helpers ──────────────────────────────────────────────────────
  static Map<String, dynamic>? _asMap(dynamic raw) {
    if (raw == null) return null;
    if (raw is List && raw.isNotEmpty) raw = raw.first;
    if (raw is Map) return raw.map((k, v) => MapEntry(k.toString(), v));
    return null;
  }

  static int _toInt(dynamic v) {
    if (v is int) return v;
    if (v is String) return int.tryParse(v) ?? 0;
    if (v is double) return v.toInt();
    return 0;
  }

  static String _str(dynamic v) => v?.toString() ?? '';

  static DateTime _toDate(dynamic v) =>
      DateTime.tryParse(v?.toString() ?? '') ?? DateTime.now();
}
