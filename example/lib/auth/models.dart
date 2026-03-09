// Modelos tipados para el flujo de auth. Se usan con OmegaIntent/OmegaEvent
// y con la extensión payloadAs<T>() para leer el payload con tipo seguro.

/// Credenciales de login enviadas desde la UI en el intent [AppIntent.authLogin].
class LoginCredentials {
  const LoginCredentials({required this.email, required this.password});
  final String email;
  final String password;
}

/// Payload que emite el agente en [AppEvent.authLoginSuccess] y que la UI lee
/// con `expr.payloadAs<LoginSuccessPayload>()` para mostrar el nombre del usuario.
class LoginSuccessPayload {
  const LoginSuccessPayload({required this.token, required this.user});
  final String token;
  final Map<String, dynamic> user;
}
