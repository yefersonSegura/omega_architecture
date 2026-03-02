import 'package:omega_architecture/omega/agents/behavior/omega_agent_behavior_engine.dart';
import 'package:omega_architecture/omega/agents/omega_agent.dart';
import 'package:omega_architecture/omega/agents/protocol/omega_agent_message.dart';
import 'package:omega_architecture/omega/core/types/omega_failure.dart';

class AuthAgent extends OmegaAgent {
  AuthAgent({
    required super.channel,
    required OmegaAgentBehaviorEngine behavior,
  }) : super(id: "auth", behavior: behavior);

  // Estado interno del agente
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
  void onAction(String action, payload) async {
    switch (action) {
      case "doLogin":
        await _login(payload);
        break;

      case "doLogout":
        _logout();
        break;
    }
  }

  // ----------------------------------------------
  // LOGIN SIMULADO (aquí pondrás tu API real)
  // ----------------------------------------------
  Future<void> _login(dynamic credentials) async {
    emit("auth.login.started");

    await Future.delayed(const Duration(seconds: 1)); // simular API

    final email = credentials["email"];
    final pass = credentials["password"];

    if (email == "admin@admin.com" && pass == "123456") {
      token = "FAKE_TOKEN_ABC123";
      user = {"name": "Admin", "email": email};

      emit("auth.login.success", payload: {"token": token, "user": user});
    } else {
      emit(
        "auth.login.error",
        payload: OmegaFailure(
          id: "auth.invalid_credentials",
          message: "Credenciales inválidas",
          details: {"email": email},
        ),
      );
    }
  }

  // ----------------------------------------------
  // LOGOUT
  // ----------------------------------------------
  void _logout() {
    token = null;
    user = null;

    emit("auth.logout.success");
  }
}
