import 'package:omega_architecture/omega_architecture.dart';

import '../omega/app_semantics.dart';
import 'auth_behavior.dart';

class AuthAgent extends OmegaAgent {
  AuthAgent(OmegaChannel channel)
    : super(id: "Auth", channel: channel, behavior: AuthBehavior());

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

  Future<void> _login(dynamic credentials) async {
    channel.emit(OmegaEvent.fromName(AppEvent.authLoginStarted));

    await Future.delayed(const Duration(seconds: 1));

    final email = credentials["email"];
    final pass = credentials["password"];

    if (email == "admin@admin.com" && pass == "123456") {
      token = "FAKE_TOKEN_ABC123";
      user = {"name": "Admin", "email": email};
      channel.emit(
        OmegaEvent.fromName(AppEvent.authLoginSuccess,
            payload: {"token": token, "user": user}),
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
