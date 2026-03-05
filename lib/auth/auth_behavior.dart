import 'package:omega_architecture/omega_architecture.dart';

class AuthBehavior extends OmegaAgentBehaviorEngine {
  AuthBehavior() {
    // Regla 1: manejar solicitudes de login
    addRule(
      OmegaAgentBehaviorRule(
        condition: (ctx) =>
            ctx.event?.name == "auth.login.request" ||
            ctx.intent?.name == "auth.login",
        reaction: (ctx) => OmegaAgentReaction(
          "doLogin",
          payload: ctx.event?.payload ?? ctx.intent?.payload,
        ),
      ),
    );

    // Regla 2: manejar logout
    addRule(
      OmegaAgentBehaviorRule(
        condition: (ctx) =>
            ctx.event?.name == "auth.logout.request" ||
            ctx.intent?.name == "auth.logout",
        reaction: (_) => OmegaAgentReaction("doLogout"),
      ),
    );
  }
}
