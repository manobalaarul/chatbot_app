part of 'auth_bloc.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object?> get props => [];
}

class CheckSessionEvent extends AuthEvent {
  const CheckSessionEvent();
}

class LoginEvent extends AuthEvent {
  final String email, password, appKey;
  const LoginEvent({
    required this.email,
    required this.password,
    required this.appKey,
  });
  @override
  List<Object?> get props => [email, appKey];
}

class LogoutEvent extends AuthEvent {
  const LogoutEvent();
}
