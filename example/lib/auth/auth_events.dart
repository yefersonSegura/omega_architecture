// Modelos tipados para el flujo de auth. Se usan con OmegaIntent/OmegaEvent
// y con la extensión payloadAs<T>() para leer el payload con tipo seguro.

import 'package:omega_architecture/omega_architecture.dart';

import '../omega/app_semantics.dart';

/// Credenciales de login enviadas desde la UI en el intent [AppIntent.authLogin].
class LoginCredentials {
  const LoginCredentials({required this.email, required this.password});
  final String email;
  final String password;
}

/// Evento tipado para "login solicitado". Se emite con [OmegaEventBus.emitTyped]
/// y se lee con [OmegaEvent.payloadAs]<LoginRequestedEvent>.
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
