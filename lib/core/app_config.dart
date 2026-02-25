class AppConfig {
  // 🔁 Base server URL — NO trailing slash
  static const String serverUrl = 'https://socket.thilagasrecipe.in';

  // REST API base (Dio baseUrl)
  static const String apiBase = '$serverUrl/api';

  // Socket.IO connection URL — points at root, NOT /api
  // The namespace (/admin) is appended by SocketService
  static const String socketUrl = '$serverUrl/admin';

  // SharedPreferences keys
  static const String kToken  = 'cf_token';
  static const String kAdmin  = 'cf_admin';
  static const String kAppKey = 'cf_appkey';
}