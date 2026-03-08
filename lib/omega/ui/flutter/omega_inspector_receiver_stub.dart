// Stub: en plataformas no-web el "receiver" indica que se use la ventana remota en web.

import 'package:flutter/material.dart';

/// En **web**, este widget recibe datos del canal principal vía BroadcastChannel y muestra el inspector.
/// En otras plataformas muestra un mensaje: usar [OmegaInspector] en overlay o [OmegaInspectorLauncher] en diálogo.
class OmegaInspectorReceiver extends StatelessWidget {
  const OmegaInspectorReceiver({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.bug_report, size: 48, color: Colors.orange.shade700),
              const SizedBox(height: 16),
              Text(
                'Omega Inspector (remoto)',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'En esta plataforma usa el botón del launcher para abrir el inspector en un diálogo.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
