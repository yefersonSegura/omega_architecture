import 'package:omega_architecture/omega_architecture.dart';

import '../omega/app_semantics.dart';

class AuthBehavior extends OmegaAgentBehaviorEngine {
  AuthBehavior() {
    addRule(
      OmegaAgentBehaviorRule(
        condition: (ctx) =>
            ctx.event?.name == AppEvent.authLoginRequest.name ||
            ctx.intent?.name == AppIntent.authLogin.name,
        reaction: (ctx) => OmegaAgentReaction(
          "doLogin",
          payload: ctx.event?.payload ?? ctx.intent?.payload,
        ),
      ),
    );
    addRule(
      OmegaAgentBehaviorRule(
        condition: (ctx) =>
            ctx.event?.name == AppEvent.authLogoutRequest.name ||
            ctx.intent?.name == AppIntent.authLogout.name,
        reaction: (_) => OmegaAgentReaction("doLogout"),
      ),
    );
  }
}
