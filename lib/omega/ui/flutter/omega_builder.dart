// lib/omega/ui/flutter/omega_builder.dart

import 'package:flutter/widgets.dart';
import 'package:omega_architecture/omega/core/events/omega_event.dart';
import 'omega_scope.dart';

/// [OmegaBuilder] es un widget reactivo que se reconstruye cuando ocurren eventos específicos en el canal.
class OmegaBuilder extends StatelessWidget {
  /// Función constructora que recibe el contexto y el último evento recibido.
  final Widget Function(BuildContext context, OmegaEvent? event) builder;

  /// Filtro opcional para reconstruir solo cuando el evento coincida con este nombre.
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
