import 'package:equatable/equatable.dart';

// ── Admin Info ────────────────────────────────────────────────
class AdminInfo extends Equatable {
  final int    id;
  final String name;
  final String email;

  const AdminInfo({required this.id, required this.name, required this.email});

  factory AdminInfo.fromJson(Map<String, dynamic> j) => AdminInfo(
        id:    j['id']    ?? 0,
        name:  j['name']  ?? 'Admin',
        email: j['email'] ?? '',
      );

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'email': email};

  @override
  List<Object?> get props => [id];
}

// ── Conversation ──────────────────────────────────────────────
class Conversation extends Equatable {
  final int     id;
  final String  visitorName;
  final String? visitorEmail;
  final String  status;        // waiting | active | bot | closed
  final String? lastMessage;
  final DateTime lastMessageAt;

  const Conversation({
    required this.id,
    required this.visitorName,
    this.visitorEmail,
    required this.status,
    this.lastMessage,
    required this.lastMessageAt,
  });

  factory Conversation.fromJson(Map<String, dynamic> j) => Conversation(
        id:            j['id'] ?? 0,
        visitorName:   j['visitor_name'] ?? 'Visitor',
        visitorEmail:  j['visitor_email'],
        status:        j['status'] ?? 'waiting',
        lastMessage:   j['last_message'],
        lastMessageAt: DateTime.tryParse(
              (j['last_message_at'] ?? j['started_at'] ?? '').toString(),
            ) ??
            DateTime.now(),
      );

  Conversation copyWith({String? status, String? lastMessage, DateTime? lastMessageAt}) =>
      Conversation(
        id:            id,
        visitorName:   visitorName,
        visitorEmail:  visitorEmail,
        status:        status        ?? this.status,
        lastMessage:   lastMessage   ?? this.lastMessage,
        lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      );

  @override
  List<Object?> get props => [id, status, lastMessage];
}

// ── Message ───────────────────────────────────────────────────
class ChatMessage extends Equatable {
  final int?   id;
  final String senderType; // visitor | admin | bot
  final String body;
  final DateTime createdAt;

  const ChatMessage({
    this.id,
    required this.senderType,
    required this.body,
    required this.createdAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> j) => ChatMessage(
        id:         j['id'],
        senderType: j['sender_type'] ?? 'visitor',
        body:       j['body'] ?? '',
        createdAt:  DateTime.tryParse((j['created_at'] ?? '').toString()) ?? DateTime.now(),
      );

  @override
  List<Object?> get props => [id, senderType, body, createdAt];
}

// ── Stats ─────────────────────────────────────────────────────
class DashboardStats extends Equatable {
  final int waiting;
  final int active;
  final int today;
  final int messages;

  const DashboardStats({
    this.waiting  = 0,
    this.active   = 0,
    this.today    = 0,
    this.messages = 0,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> j) => DashboardStats(
        waiting:  j['waiting']  ?? 0,
        active:   j['active']   ?? 0,
        today:    j['today']    ?? 0,
        messages: j['messages'] ?? 0,
      );

  @override
  List<Object?> get props => [waiting, active, today, messages];
}

// ── Auto Reply ────────────────────────────────────────────────
class AutoReply extends Equatable {
  final int    id;
  final String triggerType;  // keyword | regex
  final String triggerValue;
  final String response;

  const AutoReply({
    required this.id,
    required this.triggerType,
    required this.triggerValue,
    required this.response,
  });

  factory AutoReply.fromJson(Map<String, dynamic> j) => AutoReply(
        id:           j['id'] ?? 0,
        triggerType:  j['trigger_type']  ?? 'keyword',
        triggerValue: j['trigger_value'] ?? '',
        response:     j['response']      ?? '',
      );

  @override
  List<Object?> get props => [id];
}