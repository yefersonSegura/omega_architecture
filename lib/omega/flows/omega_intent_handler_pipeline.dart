import 'dart:async';
import 'dart:developer' as developer;

import '../core/semantics/omega_intent.dart';
import '../core/semantics/omega_intent_name.dart';
import 'omega_flow_manager.dart';
import 'omega_intent_handler_context.dart';

/// Fluent builder that registers **one** [OmegaIntentHandler] with optional
/// [validate], async/sync [execute], [onSuccess], and [onError].
///
/// No hidden global state: close over your services, [ValueNotifier]s, or agents
/// inside the lambdas. Async work runs in a [Future] after the synchronous handler
/// returns (same pattern as other async-from-sync callbacks).
///
/// ```dart
/// OmegaIntentHandlerPipeline.withPayload<LoginCredentials>(AppIntent.authLogin)
///   .validate((creds, intent, ctx) => creds.email.isNotEmpty)
///   .execute<User>((creds, intent, ctx) => authApi.login(creds))
///   .onSuccess((user, intent, ctx) => ctx.channel.emit(...))
///   .onError((e, st, intent, ctx) => log(e))
///   .register(flowManager, consumeIntent: true);
/// ```
final class OmegaIntentHandlerPipeline {
  OmegaIntentHandlerPipeline._();

  /// Start a pipeline for [intentName]; payload is read with the intent extension
  /// `payloadAs` using the pipeline type argument.
  static OmegaIntentHandlerPipelinePayload<TPayload> withPayload<TPayload>(
    OmegaIntentName intentName,
  ) =>
      OmegaIntentHandlerPipelinePayload<TPayload>._(intentName);
}

/// Stage: optional [validate] then [execute].
final class OmegaIntentHandlerPipelinePayload<TPayload> {
  OmegaIntentHandlerPipelinePayload._(this._intentName);

  final OmegaIntentName _intentName;

  bool Function(
    TPayload payload,
    OmegaIntent intent,
    OmegaIntentHandlerContext ctx,
  )? _validate;

  /// Optional gate before [execute]. Only runs when `payloadAs` yields a non-null payload.
  OmegaIntentHandlerPipelinePayload<TPayload> validate(
    bool Function(
      TPayload payload,
      OmegaIntent intent,
      OmegaIntentHandlerContext ctx,
    ) predicate,
  ) {
    _validate = predicate;
    return this;
  }

  /// Required body; may return a [Future] or a direct value.
  OmegaIntentHandlerPipelineBridge<TPayload, TResult> execute<TResult>(
    FutureOr<TResult> Function(
      TPayload payload,
      OmegaIntent intent,
      OmegaIntentHandlerContext ctx,
    ) body,
  ) =>
      OmegaIntentHandlerPipelineBridge<TPayload, TResult>._(
        _intentName,
        _validate,
        body,
      );
}

/// Stage: optional [onSuccess] / [onError] / [onPayloadMissing], then [register].
final class OmegaIntentHandlerPipelineBridge<TPayload, TResult> {
  OmegaIntentHandlerPipelineBridge._(
    this._intentName,
    this._validate,
    this._execute,
  );

  final OmegaIntentName _intentName;
  final bool Function(
    TPayload payload,
    OmegaIntent intent,
    OmegaIntentHandlerContext ctx,
  )? _validate;
  final FutureOr<TResult> Function(
    TPayload payload,
    OmegaIntent intent,
    OmegaIntentHandlerContext ctx,
  ) _execute;

  void Function(
    TResult result,
    OmegaIntent intent,
    OmegaIntentHandlerContext ctx,
  )? _onSuccess;

  void Function(
    Object error,
    StackTrace? stackTrace,
    OmegaIntent intent,
    OmegaIntentHandlerContext ctx,
  )? _onError;

  void Function(OmegaIntent intent, OmegaIntentHandlerContext ctx)? _onPayloadMissing;

  OmegaIntentHandlerPipelineBridge<TPayload, TResult> onSuccess(
    void Function(
      TResult result,
      OmegaIntent intent,
      OmegaIntentHandlerContext ctx,
    ) fn,
  ) {
    _onSuccess = fn;
    return this;
  }

  OmegaIntentHandlerPipelineBridge<TPayload, TResult> onError(
    void Function(
      Object error,
      StackTrace? stackTrace,
      OmegaIntent intent,
      OmegaIntentHandlerContext ctx,
    ) fn,
  ) {
    _onError = fn;
    return this;
  }

  /// Runs when `payloadAs` is null (before [validate] / [execute]).
  OmegaIntentHandlerPipelineBridge<TPayload, TResult> onPayloadMissing(
    void Function(OmegaIntent intent, OmegaIntentHandlerContext ctx) fn,
  ) {
    _onPayloadMissing = fn;
    return this;
  }

  /// Registers on [flowManager] via [OmegaFlowManager.registerIntentHandler].
  void register(OmegaFlowManager flowManager, {bool consumeIntent = false}) {
    flowManager.registerIntentHandler(
      intentName: _intentName.name,
      consumeIntent: consumeIntent,
      handler: (intent, ctx) {
        Future(() async {
          final payload = intent.payloadAs<TPayload>();
          if (payload == null) {
            try {
              _onPayloadMissing?.call(intent, ctx);
            } catch (e, st) {
              developer.log(
                'onPayloadMissing failed.',
                name: 'omega_intent_pipeline',
                error: e,
                stackTrace: st,
              );
            }
            return;
          }
          if (_validate != null) {
            bool ok;
            try {
              ok = _validate!(payload, intent, ctx);
            } catch (e, st) {
              developer.log(
                'validate failed.',
                name: 'omega_intent_pipeline',
                error: e,
                stackTrace: st,
              );
              return;
            }
            if (!ok) return;
          }
          try {
            final result = await Future.sync(() => _execute(payload, intent, ctx));
            _onSuccess?.call(result, intent, ctx);
          } catch (e, st) {
            _onError?.call(e, st, intent, ctx);
          }
        });
      },
    );
  }
}
