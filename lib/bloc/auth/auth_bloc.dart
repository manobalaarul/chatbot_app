import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../models/models.dart';
import '../../services/api_service.dart';
import '../../services/session_service.dart';
import '../../services/socket_service.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final ApiService     _api;
  final SocketService  _socket;
  final SessionService _session;

  AuthBloc({
    required ApiService    api,
    required SocketService socket,
    required SessionService session,
  })  : _api    = api,
        _socket = socket,
        _session = session,
        super(const AuthInitial()) {
    on<CheckSessionEvent>(_onCheckSession);
    on<LoginEvent>(_onLogin);
    on<LogoutEvent>(_onLogout);
  }

  Future<void> _onCheckSession(CheckSessionEvent e, Emitter<AuthState> emit) async {
    if (_session.hasSession) {
      _api.setToken(_session.token!);
      _socket.connect(_session.token!);
      emit(AuthAuthenticated(admin: _session.adminInfo!, appKey: _session.appKey!));
    } else {
      emit(const AuthUnauthenticated());
    }
  }

  Future<void> _onLogin(LoginEvent e, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    try {
      final res  = await _api.login(email: e.email, password: e.password, appKey: e.appKey);
      final data = res.data as Map<String, dynamic>;
      final admin = AdminInfo.fromJson(data['admin'] ?? data);
      final token = data['token'] as String;

      _api.setToken(token);
      await _session.save(token, admin, e.appKey);
      _socket.connect(token);

      emit(AuthAuthenticated(admin: admin, appKey: e.appKey));
    } catch (err) {
      final msg = err.toString().contains('DioException')
          ? 'Invalid credentials'
          : err.toString().replaceFirst('Exception: ', '');
      emit(AuthError(msg));
    }
  }

  Future<void> _onLogout(LogoutEvent e, Emitter<AuthState> emit) async {
    _socket.disconnect();
    _api.clearToken();
    await _session.clear();
    emit(const AuthUnauthenticated());
  }
}