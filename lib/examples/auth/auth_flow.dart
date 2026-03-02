import 'package:omega_architecture/omega/core/channel/omega_channel.dart';
import 'package:omega_architecture/omega/core/events/omega_event.dart';
import 'package:omega_architecture/omega/core/semantics/omega_intent.dart';
import 'package:omega_architecture/omega/core/types/omega_failure.dart';
import 'package:omega_architecture/omega/flows/omega_flow.dart';
import 'package:omega_architecture/omega/flows/omega_flow_context.dart';

class AuthFlow extends OmegaFlow {
  AuthFlow({required OmegaChannel channel})
    : super(id: "authFlow", channel: channel);

  // -----------------------------------------------------------
  // Lógica al iniciar el Flow
  // -----------------------------------------------------------
  @override
  void onStart() {
    emitExpression("idle"); // estado inicial de UI
  }

  // -----------------------------------------------------------
  // 1. INTENCIONES desde la UI
  // -----------------------------------------------------------
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

  // -----------------------------------------------------------
  // 2. EVENTOS desde los agentes
  // -----------------------------------------------------------
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
      if (event.name == "auth.login.error") {
        final failure = event.payload;

        emitExpression(
          "error",
          payload: failure is OmegaFailure
              ? failure.message
              : failure.toString(),
        );
      }
    }

    // LOGOUT
    if (event.name == "auth.logout.success") {
      emitExpression("loggedOut");
    }
  }
}
