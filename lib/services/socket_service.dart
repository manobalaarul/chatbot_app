import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../core/app_config.dart';

typedef MessageCallback       = void Function(int convId, String senderType, String body, DateTime createdAt);
typedef ConvCallback          = void Function(int convId);
typedef ConvUpdatedCallback   = void Function(int convId, String status);

class SocketService {
  IO.Socket? _socket;
  int? _activeConvId;

  // ── Callbacks ─────────────────────────────────────────────
  MessageCallback?     onMessage;
  ConvCallback?        onWaiting;
  ConvCallback?        onVisitorTyping;
  ConvCallback?        onVisitorOffline;
  ConvUpdatedCallback? onConvUpdated;

  bool get isConnected => _socket?.connected ?? false;

  // ── Connect ────────────────────────────────────────────────
  void connect(String token) {
    _socket = IO.io(
      '${AppConfig.serverUrl}/admin',
      IO.OptionBuilder()
          .setTransports(['websocket', 'polling'])
          .setAuth({'token': token})
          .setReconnectionAttempts(10)
          .setReconnectionDelay(2000)
          .build(),
    );

    _socket!.onConnect((_) {
      print('✅ Admin socket connected: ${_socket!.id}');
      // Re-join active room after reconnect
      if (_activeConvId != null) {
        _socket!.emit('admin:join', {'conversationId': _activeConvId});
      }
    });

    _socket!.onDisconnect((r) => print('⚠️ Socket disconnected: $r'));
    _socket!.onConnectError((e) => print('❌ Socket error: $e'));

    _socket!.on('conversation:message', (data) {
      final m = data as Map;
      onMessage?.call(
        m['conversationId'] as int,
        m['senderType']     as String,
        m['body']           as String,
        DateTime.tryParse((m['createdAt'] ?? '').toString()) ?? DateTime.now(),
      );
    });

    _socket!.on('conversation:waiting', (data) {
      onWaiting?.call((data as Map)['conversationId'] as int);
    });

    _socket!.on('visitor:typing', (data) {
      onVisitorTyping?.call((data as Map)['conversationId'] as int);
    });

    _socket!.on('visitor:offline', (data) {
      onVisitorOffline?.call((data as Map)['conversationId'] as int);
    });

    _socket!.on('conversation:updated', (data) {
      final m = data as Map;
      onConvUpdated?.call(m['conversationId'] as int, m['status'] as String);
    });
  }

  void disconnect() {
    _socket?.disconnect();
    _socket = null;
    _activeConvId = null;
  }

  // ── Room management ────────────────────────────────────────
  void joinConv(int convId) {
    _activeConvId = convId;
    _socket?.emit('admin:join', {'conversationId': convId});
  }

  void leaveConv(int convId) {
    if (_activeConvId == convId) _activeConvId = null;
    _socket?.emit('admin:leave', {'conversationId': convId});
  }

  // ── Actions with acknowledgement ───────────────────────────
  Future<Map<String, dynamic>> sendMessage(int convId, String text) {
    final completer = _Completer<Map<String, dynamic>>();
    _socket?.emitWithAck('admin:message', {'conversationId': convId, 'text': text},
        ack: (data) => completer.complete(Map<String, dynamic>.from(data ?? {})));
    return completer.future;
  }

  Future<Map<String, dynamic>> takeOver(int convId) {
    final completer = _Completer<Map<String, dynamic>>();
    _socket?.emitWithAck('admin:takeover', {'conversationId': convId},
        ack: (data) => completer.complete(Map<String, dynamic>.from(data ?? {})));
    return completer.future;
  }

  Future<Map<String, dynamic>> closeConversation(int convId) {
    final completer = _Completer<Map<String, dynamic>>();
    _socket?.emitWithAck('admin:close', {'conversationId': convId},
        ack: (data) => completer.complete(Map<String, dynamic>.from(data ?? {})));
    return completer.future;
  }
}

// Simple completer wrapper
class _Completer<T> {
  T? _result;
  Function(T)? _then;
  bool _completed = false;

  void complete(T value) {
    _result = value;
    _completed = true;
    _then?.call(value);
  }

  Future<T> get future async {
    while (!_completed) {
      await Future.delayed(const Duration(milliseconds: 50));
    }
    return _result as T;
  }
}