// ── main.dart ─────────────────────────────────────────────────────────────────
// FIX: InitDashboardEvent is fired ONLY from _AppRouter's BlocListener
// (when AuthAuthenticated arrives). DashboardScreen.initState must NOT fire it
// again — that caused double-init which double-registers socket callbacks and
// starts duplicate polling timers.

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
    final api = ApiService();
    final socket = SocketService();
    final session = SessionService.instance;

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
              api: ctx.read<ApiService>(),
              socket: ctx.read<SocketService>(),
              session: ctx.read<SessionService>(),
            )..add(const CheckSessionEvent()),
          ),
          BlocProvider(
            create: (ctx) => DashboardBloc(
              api: ctx.read<ApiService>(),
              socket: ctx.read<SocketService>(),
            ),
          ),
          BlocProvider(
            create: (ctx) => AutoRepliesBloc(api: ctx.read<ApiService>()),
          ),
        ],
        child: MaterialApp(
          title: 'ChatFlow Admin',
          debugShowCheckedModeBanner: false,
          theme: T.theme,
          home: const _AppRouter(),
        ),
      ),
    );
  }
}

class _AppRouter extends StatelessWidget {
  const _AppRouter();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (ctx, state) {
        if (state is AuthAuthenticated) {
          // ✅ Single place InitDashboardEvent is fired
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
            body: Center(
              child: CircularProgressIndicator(
                color: T.accentBlue,
                strokeWidth: 2,
              ),
            ),
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
