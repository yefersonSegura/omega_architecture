import 'package:omega_architecture/omega_architecture.dart';

import '../omega/app_semantics.dart';
import 'auth_behavior.dart';
import 'auth_events.dart';

class AuthAgent extends OmegaAgent {
  AuthAgent(OmegaEventBus channel)
    : super(id: "Auth", channel: channel, behavior: AuthBehavior());

  static final _contract = OmegaAgentContract.fromTyped(
    agentId: 'Auth',
    listenedEvents: [AppEvent.authLoginRequest, AppEvent.authLogoutRequest],
    acceptedIntents: [AppIntent.authLogin, AppIntent.authLogout],
  );

  @override
  OmegaAgentContract? get contract => _contract;

  String? token;
  Map<String, dynamic>? user;

  @override
  void onMessage(OmegaAgentMessage msg) {
    if (msg.action == "invalidateToken") {
      token = null;
      user = null;
      emit("auth.token.invalidated");
    }
  }

  @override
  void onAction(String action, dynamic payload) {
    switch (action) {
      case "doLogin":
        _login(payload);
        break;

      case "doLogout":
        _logout();
        break;
    }
  }

  Future<void> _login(dynamic payload) async {
    // Payload puede ser LoginRequestedEvent (emitTyped) o LoginCredentials (desde intent directo)
    final String email;
    final String password;
    if (payload is LoginRequestedEvent) {
      email = payload.email;
      password = payload.password;
    } else if (payload is LoginCredentials) {
      email = payload.email;
      password = payload.password;
    } else {
      return;
    }

    channel.emit(OmegaEvent.fromName(AppEvent.authLoginStarted));

    await Future.delayed(const Duration(seconds: 1));

    if (email == "admin@admin.com" && password == "123456") {
      token = "FAKE_TOKEN_ABC123";
      user = {"name": "Admin", "email": email};
      channel.emit(
        OmegaEvent.fromName(
          AppEvent.authLoginSuccess,
          payload: LoginSuccessPayload(token: token!, user: user!),
        ),
      );
    } else {
      channel.emit(
        OmegaEvent.fromName(
          AppEvent.authLoginError,
          payload: OmegaFailure(
            id: "auth.invalid_credentials",
            message: "Credenciales inválidas",
            details: {"email": email},
          ),
        ),
      );
    }
  }

  void _logout() {
    token = null;
    user = null;
    channel.emit(OmegaEvent.fromName(AppEvent.authLogoutSuccess));
  }
}
