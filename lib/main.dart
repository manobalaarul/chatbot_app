import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'bloc/auth/auth_bloc.dart';
import 'bloc/autoreplies/autoreplies_bloc.dart';
import 'bloc/dashboard/dashboard_bloc.dart';
import 'screens/dashboard_screen.dart';
import 'screens/login_screen.dart';
import 'services/api_service.dart';
import 'services/session_service.dart';
import 'services/socket_service.dart';
import 'theme/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SessionService.instance.init();
  runApp(const ChatFlowApp());
}

class ChatFlowApp extends StatelessWidget {
  const ChatFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    // ── DI: create services once ──────────────────────────────
    final api    = ApiService();
    final socket = SocketService();
    final session = SessionService.instance;

    // Pre-load token into Dio if session exists
    if (session.token != null) api.setToken(session.token!);

    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: api),
        RepositoryProvider.value(value: socket),
        RepositoryProvider.value(value: session),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (ctx) => AuthBloc(
              api:     ctx.read<ApiService>(),
              socket:  ctx.read<SocketService>(),
              session: ctx.read<SessionService>(),
            )..add(const CheckSessionEvent()),
          ),
          BlocProvider(
            create: (ctx) => DashboardBloc(
              api:    ctx.read<ApiService>(),
              socket: ctx.read<SocketService>(),
            ),
          ),
          BlocProvider(
            create: (ctx) => AutoRepliesBloc(api: ctx.read<ApiService>()),
          ),
        ],
        child: MaterialApp(
          title:                  'ChatFlow Admin',
          debugShowCheckedModeBanner: false,
          theme:                  T.theme,
          home:                   const _AppRouter(),
        ),
      ),
    );
  }
}

// ── Router: listens to AuthBloc and navigates accordingly ──────
class _AppRouter extends StatelessWidget {
  const _AppRouter();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (ctx, state) {
        if (state is AuthAuthenticated) {
          // Boot dashboard when authenticated
          ctx.read<DashboardBloc>().add(const InitDashboardEvent());
        }
        if (state is AuthUnauthenticated) {
          ctx.read<DashboardBloc>().add(const ShutdownDashboardEvent());
        }
      },
      builder: (ctx, state) {
        if (state is AuthInitial || state is AuthLoading) {
          return const Scaffold(
            backgroundColor: T.bg,
            body: Center(child: CircularProgressIndicator(color: T.accentBlue, strokeWidth: 2)),
          );
        }
        if (state is AuthAuthenticated) {
          return DashboardScreen(admin: state.admin);
        }
        return const LoginScreen();
      },
    );
  }
}