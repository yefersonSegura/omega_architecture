import 'package:flutter/material.dart';
import 'package:omega_architecture/omega_architecture.dart';

import 'demo_counter_intent.dart';
import 'example_intent_handlers.dart';

/// Pantalla que muestra el contador actualizado por handlers registrados vía
/// [OmegaConfig.intentHandlerRegistrars] ([ExampleIntentHandlerDemo.attach]).
///
/// Alternativa con estado tipo reducer (sin [ValueNotifier]):
/// ```dart
/// final r = OmegaIntentReducer<int>(0, flowManager);
/// r.on(DemoCounterIntent.demoCounterIncrement, (n, i) => n + (i.payloadAs<int>() ?? 1));
/// // leer r.state después de cada handleIntent (p. ej. setState manual o stream)
/// ```
class IntentHandlerDemoPage extends StatelessWidget {
  const IntentHandlerDemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    final scope = OmegaScope.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Demo: handlers de intent')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Registro en omega_setup → intentHandlerRegistrars: '
              '[ExampleIntentHandlerDemo.attach]. '
              'Abajo: [Omega.handle] (increment/reset) y [OmegaIntentHandlerPipeline] '
              '(cuadrado async con validate). consumeIntent evita que un flow vea estos intents.',
              style: TextStyle(height: 1.4),
            ),
            const SizedBox(height: 24),
            ValueListenableBuilder<int>(
              valueListenable: ExampleIntentHandlerDemo.counter,
              builder: (context, value, _) {
                return Text(
                  'Contador: $value',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium,
                );
              },
            ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: () {
                scope.flowManager.handleIntent(
                  OmegaIntent.fromName(DemoCounterIntent.demoCounterIncrement),
                );
              },
              child: const Text('+1 (intent default)'),
            ),
            const SizedBox(height: 8),
            FilledButton.tonal(
              onPressed: () {
                scope.flowManager.handleIntent(
                  OmegaIntent.fromName(
                    DemoCounterIntent.demoCounterIncrement,
                    payload: 5,
                  ),
                );
              },
              child: const Text('+5 (payload int)'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () {
                scope.flowManager.handleIntent(
                  OmegaIntent.fromName(DemoCounterIntent.demoCounterReset),
                );
              },
              child: const Text('Reset'),
            ),
            const Divider(height: 40),
            Text(
              'OmegaIntentHandlerPipeline',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              'Intent demo.counter.square: valida 1…100, espera 80 ms y guarda n². '
              'Si la validación falla, no se llama a execute y el texto de abajo no se actualiza.',
              style: TextStyle(height: 1.3),
            ),
            const SizedBox(height: 12),
            ValueListenableBuilder<int?>(
              valueListenable: ExampleIntentHandlerDemo.pipelineSquareLast,
              builder: (context, square, _) {
                return Text(
                  square == null
                      ? 'Último cuadrado: (aún no)'
                      : 'Último cuadrado: $square',
                  textAlign: TextAlign.center,
                );
              },
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () {
                scope.flowManager.handleIntent(
                  OmegaIntent.fromName(
                    DemoCounterIntent.demoCounterSquare,
                    payload: 4,
                  ),
                );
              },
              child: const Text('Cuadrado async (4 → 16)'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () {
                scope.flowManager.handleIntent(
                  OmegaIntent.fromName(
                    DemoCounterIntent.demoCounterSquare,
                    payload: 0,
                  ),
                );
              },
              child: const Text('Validación falla (payload 0)'),
            ),
          ],
        ),
      ),
    );
  }
}
