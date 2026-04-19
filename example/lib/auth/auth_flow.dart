import 'package:omega_architecture/omega_architecture.dart';

import '../omega/app_runtime_ids.dart';
import '../omega/app_semantics.dart';
import 'auth_agent.dart';
import 'auth_events.dart';

class AuthFlow extends OmegaFlow {
  AuthFlow({required super.channel, required this.agent})
      : super(id: AppFlowId.authFlow.id);

  final AuthAgent agent;

  @override
  OmegaAgent? get uiScopeAgent => agent;

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

    final login = intent.typedPayloadAs<AuthLoginIntent>();
    if (login != null) {
      emitExpression("loading");
      channel.emitTyped(
        LoginRequestedEvent(
          email: login.credentials.email,
          password: login.credentials.password,
        ),
      );
      return;
    }

    final logout = intent.typedPayloadAs<AuthLogoutIntent>();
    if (logout != null) {
      emitExpression("loading");
      channel.emit(OmegaEvent.fromName(AppEvent.authLogoutRequest));
      return;
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

    if (event.name == AppEvent.authLoginSuccess.name) {
      final userData = event.payloadAs<LoginSuccessPayload>();
      emitExpression("success", payload: userData);
      if (userData != null) {
        channel.emit(
          OmegaEvent.fromName<OmegaIntent>(
            AppEvent.navigationIntent,
            payload: OmegaIntent.fromName<LoginSuccessPayload>(
              AppIntent.navigateHome,
              payload: userData,
            ),
          ),
        );
      }
    }

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
