// Stub: en plataformas no-web se muestra el inspector en un diálogo (como antes).

import 'package:flutter/material.dart';

import 'omega_inspector.dart';

/// Botón que abre el inspector. En **web** abre una nueva ventana del navegador (estilo Isar).
/// En otras plataformas abre el inspector en un [Dialog].
class OmegaInspectorLauncher extends StatelessWidget {
  /// Máximo de eventos a mostrar en el panel.
  final int eventLimit;

  const OmegaInspectorLauncher({super.key, this.eventLimit = kOmegaInspectorDefaultEventLimit});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.bug_report),
      tooltip: 'Omega Inspector',
      onPressed: () {
        showDialog<void>(
          context: context,
          builder: (ctx) => Dialog(
            child: SizedBox(
              width: 320,
              height: 400,
              child: OmegaInspector(eventLimit: eventLimit, initiallyCollapsed: false),
            ),
          ),
        );
      },
    );
  }
}
