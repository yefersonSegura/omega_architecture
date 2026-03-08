import 'package:omega_architecture/omega_architecture.dart';

import '../omega/app_semantics.dart';

class AuthFlow extends OmegaFlow {
  AuthFlow(OmegaChannel channel) : super(id: "authFlow", channel: channel);

  @override
  void onStart() {
    emitExpression("idle");
  }

  @override
  void onIntent(OmegaFlowContext ctx) {
    final intent = ctx.intent;

    if (intent == null) return;

    // LOGIN → intención desde UI (comparar con nombre tipado)
    if (intent.name == AppIntent.authLogin.name) {
      emitExpression("loading");
      channel.emit(
        OmegaEvent.fromName(AppEvent.authLoginRequest, payload: intent.payload),
      );
    }

    // LOGOUT
    if (intent.name == AppIntent.authLogout.name) {
      emitExpression("loading");
      channel.emit(OmegaEvent.fromName(AppEvent.authLogoutRequest));
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
        payload: failure is OmegaFailure ? failure.message : failure.toString(),
      );
    }

    // LOGOUT
    if (event.name == AppEvent.authLogoutSuccess.name) {
      emitExpression("loggedOut");
    }
  }
}
