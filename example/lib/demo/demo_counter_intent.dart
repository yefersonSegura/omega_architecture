import 'package:omega_architecture/omega_architecture.dart';

/// Intents del demo: un solo identificador camelCase por caso; el alambre lleva puntos
/// (`demoCounterIncrement` → `demo.counter.increment`) vía [OmegaIntentNameDottedCamel].
enum DemoCounterIntent with OmegaIntentNameDottedCamel implements OmegaIntentName {
  demoCounterIncrement,
  demoCounterReset,

  /// Demo [OmegaIntentHandlerPipeline]: `demo.counter.square` (payload int → n² async).
  demoCounterSquare,
}
