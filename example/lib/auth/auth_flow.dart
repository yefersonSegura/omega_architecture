import 'package:omega_architecture/omega_architecture.dart';

import '../omega/app_runtime_ids.dart';
import '../omega/app_semantics.dart';
import 'auth_events.dart';

class AuthFlow extends OmegaFlow {
  AuthFlow(OmegaEventBus channel)
      : super(id: AppFlowId.authFlow.id, channel: channel);

  static final _contract = OmegaFlowContract.fromTyped(
    flowId: AppFlowId.authFlow.id,
    listenedEvents: [
      AppEvent.authLoginStarted,
      AppEvent.authLoginSuccess,
      AppEvent.authLoginError,
      AppEvent.authLogoutSuccess,
    ],
    acceptedIntents: [AppIntent.authLogin, AppIntent.authLogout],
    emittedExpressionTypes: {
      'idle',
      'loading',
      'success',
      'error',
      'loggedOut',
    },
  );

  @override
  OmegaFlowContract? get contract => _contract;

  @override
  void onStart() {
    emitExpression("idle");
  }

  @override
  void onIntent(OmegaFlowContext ctx) {
    final intent = ctx.intent;

    if (intent == null) return;

    // LOGIN → evento tipado (emitTyped) o clásico (fromName + payload)
    if (intent.name == AppIntent.authLogin.name) {
      final creds = intent.payloadAs<LoginCredentials>();
      if (creds != null) {
        emitExpression("loading");
        channel.emitTyped(
          LoginRequestedEvent(email: creds.email, password: creds.password),
        );
      }
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
    if (event.name == AppEvent.authLoginStarted.name) {
      emitExpression("loading");
    }

    // LOGIN CORRECTO: navegar a home con payload tipado (la vista recibe LoginSuccessPayload)
    if (event.name == AppEvent.authLoginSuccess.name) {
      emitExpression("success", payload: event.payload);
      final userData = event.payload; // LoginSuccessPayload desde el agente
      channel.emit(
        OmegaEvent.fromName(
          AppEvent.navigationIntent,
          payload: OmegaIntent.fromName(
            AppIntent.navigateHome,
            payload: userData,
          ),
        ),
      );
    }

    // ERROR DE LOGIN: payload tipado con payloadAs<OmegaFailure>()
    if (event.name == AppEvent.authLoginError.name) {
      final failure = event.payloadAs<OmegaFailure>();
      emitExpression(
        "error",
        payload: failure?.message ?? event.payload?.toString() ?? "Error",
      );
    }

    // LOGOUT
    if (event.name == AppEvent.authLogoutSuccess.name) {
      emitExpression("loggedOut");
    }
  }
}
