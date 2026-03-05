import 'package:omega_architecture/omega_architecture.dart';

class AuthFlow extends OmegaFlow {
  AuthFlow(OmegaChannel channel) : super(id: "auth", channel: channel);

  @override
  void onStart() {
    emitExpression("idle");
    channel.emit(
      OmegaEvent(
        id: "nav.login",
        name: "navigation.intent",
        payload: OmegaIntent(id: "goLogin", name: "navigate.login"),
      ),
    );
  }

  @override
  void onIntent(OmegaFlowContext ctx) {
    final intent = ctx.intent;

    if (intent == null) return;

    // LOGIN → intención desde UI
    if (intent.name == "auth.login") {
      emitExpression("loading");

      // Disparamos evento a los agentes
      channel.emit(
        OmegaEvent(
          id: "authFlow:${DateTime.now().millisecondsSinceEpoch}",
          name: "auth.login.request",
          payload: intent.payload,
        ),
      );
    }

    // LOGOUT
    if (intent.name == "auth.logout") {
      emitExpression("loading");

      channel.emit(
        OmegaEvent(
          id: "authFlow:${DateTime.now().millisecondsSinceEpoch}",
          name: "auth.logout.request",
        ),
      );
    }
  }

  @override
  void onEvent(OmegaFlowContext ctx) {
    final event = ctx.event;
    if (event == null) return;

    // LOGIN INICIADO
    if (event.name == "auth.login.started") {
      emitExpression("loading");
    }

    // LOGIN CORRECTO
    if (event.name == "auth.login.success") {
      final intent = OmegaIntent(id: "goHome", name: "navigate.home");

      channel.emit(
        OmegaEvent(
          id: "nav:${DateTime.now().millisecondsSinceEpoch}",
          name: "navigation.intent",
          payload: intent,
        ),
      );
    }

    // ERROR DE LOGIN
    if (event.name == "auth.login.error") {
      final failure = event.payload;
      emitExpression(
        "error",
        payload: failure is OmegaFailure
            ? failure.message
            : failure.toString(),
      );
    }

    // LOGOUT
    if (event.name == "auth.logout.success") {
      emitExpression("loggedOut");
    }
  }
}
