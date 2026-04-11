import 'package:flutter/foundation.dart';
import 'package:omega_architecture/omega_architecture.dart';

import 'demo_counter_intent.dart';

/// Demuestra [Omega.handle] con [consumeIntent]: el intent no llega a los flows;
/// el estado vive en [counter] y la UI llama [OmegaFlowManager.handleIntent].
///
/// Registro vía [OmegaConfig.intentHandlerRegistrars] — pasa [attach] en `omega_setup`.
final class ExampleIntentHandlerDemo {
  ExampleIntentHandlerDemo._();

  static final ValueNotifier<int> counter = ValueNotifier<int>(0);

  /// Último n² calculado por [OmegaIntentHandlerPipeline] (`demoCounterSquare`).
  static final ValueNotifier<int?> pipelineSquareLast = ValueNotifier<int?>(null);

  static bool _registered = false;

  /// [OmegaIntentHandlerRegistrar]: idempotente por proceso (evita duplicar handlers).
  static void attach(OmegaFlowManager flowManager, OmegaChannel _) {
    if (_registered) return;
    _registered = true;

    Omega.handle(
      flowManager,
      DemoCounterIntent.demoCounterIncrement,
      (intent, ctx) {
        final delta = intent.payloadAs<int>() ?? 1;
        counter.value = counter.value + delta;
      },
      consumeIntent: true,
    );

    Omega.handle(
      flowManager,
      DemoCounterIntent.demoCounterReset,
      (intent, ctx) {
        counter.value = 0;
        pipelineSquareLast.value = null;
      },
      consumeIntent: true,
    );

    OmegaIntentHandlerPipeline.withPayload<int>(DemoCounterIntent.demoCounterSquare)
        .validate((payload, intent, ctx) => payload > 0 && payload <= 100)
        .execute((payload, intent, ctx) async {
          await Future<void>.delayed(const Duration(milliseconds: 80));
          return payload * payload;
        })
        .onSuccess((result, intent, ctx) {
          pipelineSquareLast.value = result;
        })
        .onPayloadMissing((intent, ctx) {
          pipelineSquareLast.value = null;
        })
        .onError((error, stackTrace, intent, ctx) {
          pipelineSquareLast.value = null;
        })
        .register(flowManager, consumeIntent: true);
  }
}
