// Modelos tipados para el flujo de auth: [OmegaTypedIntent], [OmegaTypedEvent],
// [OmegaFlowManager.handleTypedIntent] y [OmegaEvent.fromName]<T> / payloadAs.

import 'package:omega_architecture/omega_architecture.dart';

import '../omega/app_semantics.dart';

/// Credenciales de login (DTO reutilizable).
class LoginCredentials {
  const LoginCredentials({required this.email, required this.password});
  final String email;
  final String password;
}

/// Intent con tipado fuerte: mismo wire que [AppIntent.authLogin] + [LoginCredentials].
final class AuthLoginIntent implements OmegaTypedIntent {
  const AuthLoginIntent(this.credentials);
  final LoginCredentials credentials;
  @override
  String get name => AppIntent.authLogin.name;
}

/// Intent sin cuerpo extra; mismo wire que [AppIntent.authLogout].
final class AuthLogoutIntent implements OmegaTypedIntent {
  const AuthLogoutIntent();
  @override
  String get name => AppIntent.authLogout.name;
}

/// Evento tipado para "login solicitado". Se emite con [OmegaEventBus.emitTyped]
/// y se lee con `event.typedPayloadAs<LoginRequestedEvent>()`.
class LoginRequestedEvent implements OmegaTypedEvent {
  const LoginRequestedEvent({required this.email, required this.password});
  final String email;
  final String password;
  @override
  String get name => AppEvent.authLoginRequest.name;
}

/// Payload que emite el agente en [AppEvent.authLoginSuccess] y que la UI lee
/// con `expr.payloadAs<LoginSuccessPayload>()` para mostrar el nombre del usuario.
class LoginSuccessPayload {
  const LoginSuccessPayload({required this.token, required this.user});
  final String token;
  final Map<String, dynamic> user;
}
