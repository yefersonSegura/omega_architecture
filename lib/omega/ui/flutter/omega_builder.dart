// lib/omega/ui/flutter/omega_builder.dart

import 'package:flutter/widgets.dart';
import 'package:omega_architecture/omega/core/events/omega_event.dart';
import 'omega_scope.dart';

/// [OmegaBuilder] es un widget que se reconstruye cuando se emite un [OmegaEvent] en el canal.
///
/// Si [eventName] no es null, solo reacciona a eventos con ese nombre (ej. "user.updated").
/// El [builder] recibe el [BuildContext] y el último evento recibido (o null).
/// Requiere un [OmegaScope] en el árbol.
class OmegaBuilder extends StatelessWidget {
  /// Construye el widget con el contexto y el último evento (o null).
  final Widget Function(BuildContext context, OmegaEvent? event) builder;

  /// Si se indica, solo se reconstruye cuando [OmegaEvent.name] coincida (ej. "auth.login.success").
  final String? eventName;

  const OmegaBuilder({super.key, required this.builder, this.eventName});

  @override
  Widget build(BuildContext context) {
    final channel = OmegaScope.of(context).channel;

    return StreamBuilder<OmegaEvent>(
      stream: channel.events.where((event) {
        if (eventName == null) return true;
        return event.name == eventName;
      }),
      builder: (context, snapshot) {
        return builder(context, snapshot.data);
      },
    );
  }
}
