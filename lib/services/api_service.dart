import 'package:dio/dio.dart';
import '../core/app_config.dart';

class ApiService {
  late final Dio _dio;
  String? _token;

  ApiService() {
    _dio = Dio(
      BaseOptions(
        baseUrl:        AppConfig.apiBase,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 15),
        headers: {'Content-Type': 'application/json'},
      ),
    );
    _dio.interceptors.addAll([_AuthInterceptor(this), _LogInterceptor()]);
  }

  void setToken(String token) => _token = token;
  void clearToken()           => _token = null;
  String? get token           => _token;

  // ── Auth ───────────────────────────────────────────────────
  Future<Response> login({
    required String email,
    required String password,
    required String appKey,
  }) =>
      _dio.post('/admin/login', data: {
        'email':    email,
        'password': password,
        'app_key':  appKey,
      });

  // ── Conversations ──────────────────────────────────────────
  Future<Response> getConversations(String status, {int limit = 50}) =>
      _dio.get('/conversations', queryParameters: {'status': status, 'limit': limit});

  Future<Response> getMessages(int convId) =>
      _dio.get('/conversations/$convId/messages');

  // ── Stats ──────────────────────────────────────────────────
  Future<Response> getStats() => _dio.get('/stats');

  // ── Auto-replies ───────────────────────────────────────────
  Future<Response> getAutoReplies() => _dio.get('/auto-replies');

  Future<Response> createAutoReply(Map<String, dynamic> body) =>
      _dio.post('/auto-replies', data: body);

  Future<Response> deleteAutoReply(int id) => _dio.delete('/auto-replies/$id');
}

// ── Interceptors ──────────────────────────────────────────────

class _AuthInterceptor extends Interceptor {
  final ApiService _svc;
  _AuthInterceptor(this._svc);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (_svc._token != null) {
      options.headers['Authorization'] = 'Bearer ${_svc._token}';
    }
    handler.next(options);
  }
}

class _LogInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions o, RequestInterceptorHandler h) {
    print('📤 [${o.method}] ${o.uri}');
    h.next(o);
  }

  @override
  void onResponse(Response r, ResponseInterceptorHandler h) {
    print('📥 [${r.statusCode}] ${r.requestOptions.uri}');
    h.next(r);
  }

  @override
  void onError(DioException e, ErrorInterceptorHandler h) {
    print('❌ [${e.response?.statusCode}] ${e.message}');
    h.next(e);
  }
}