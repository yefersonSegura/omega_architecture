import 'package:omega_architecture/omega_architecture.dart';

import '../omega/app_semantics.dart';
import 'models.dart';

class AuthFlow extends OmegaFlow {
  AuthFlow(OmegaEventBus channel) : super(id: "authFlow", channel: channel);

  static final _contract = OmegaFlowContract.fromTyped(
    flowId: 'authFlow',
    listenedEvents: [
      AppEvent.authLoginStarted,
      AppEvent.authLoginSuccess,
      AppEvent.authLoginError,
      AppEvent.authLogoutSuccess,
    ],
    acceptedIntents: [AppIntent.authLogin, AppIntent.authLogout],
    emittedExpressionTypes: {'idle', 'loading', 'success', 'error', 'loggedOut'},
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

    // LOGIN → payload tipado con payloadAs<LoginCredentials>()
    if (intent.name == AppIntent.authLogin.name) {
      final creds = intent.payloadAs<LoginCredentials>();
      if (creds != null) {
        emitExpression("loading");
        channel.emit(
          OmegaEvent.fromName(AppEvent.authLoginRequest, payload: creds),
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
