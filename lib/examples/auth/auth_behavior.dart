import 'package:omega_architecture/omega/agents/behavior/omega_agent_behavior_engine.dart';
import 'package:omega_architecture/omega/agents/behavior/omega_agent_behavior_rule.dart';
import 'package:omega_architecture/omega/agents/behavior/omega_agent_reaction.dart';

OmegaAgentBehaviorEngine createAuthBehavior() {
  final engine = OmegaAgentBehaviorEngine();

  // Regla 1: manejar solicitudes de login
  engine.addRule(
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
  engine.addRule(
    OmegaAgentBehaviorRule(
      condition: (ctx) =>
          ctx.event?.name == "auth.logout.request" ||
          ctx.intent?.name == "auth.logout",
      reaction: (_) => OmegaAgentReaction("doLogout"),
    ),
  );

  return engine;
}
