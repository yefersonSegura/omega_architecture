import 'package:omega_architecture/omega_architecture.dart';

import '../omega/app_semantics.dart';
import 'auth_behavior.dart';
import 'models.dart';

class AuthAgent extends OmegaAgent {
  AuthAgent(OmegaChannel channel)
    : super(id: "Auth", channel: channel, behavior: AuthBehavior());

  @override
  OmegaAgentContract? get contract => OmegaAgentContract.fromTyped(
        listenedEvents: [AppEvent.authLoginRequest, AppEvent.authLogoutRequest],
        acceptedIntents: [AppIntent.authLogin, AppIntent.authLogout],
      );

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
    if (payload is! LoginCredentials) return;
    final creds = payload; // Tipo promocionado a LoginCredentials

    channel.emit(OmegaEvent.fromName(AppEvent.authLoginStarted));

    await Future.delayed(const Duration(seconds: 1));

    if (creds.email == "admin@admin.com" && creds.password == "123456") {
      token = "FAKE_TOKEN_ABC123";
      user = {"name": "Admin", "email": creds.email};
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
            details: {"email": creds.email},
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
