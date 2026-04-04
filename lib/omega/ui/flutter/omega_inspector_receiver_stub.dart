// Stub: on non-web platforms the receiver points users to the remote web window pattern.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// On **web**, the real implementation listens on BroadcastChannel and renders the inspector.
/// On other platforms this stub shows a short hint: use [OmegaInspector] in an overlay or
/// [OmegaInspectorLauncher] in a dialog. In release builds only a message is shown.
class OmegaInspectorReceiver extends StatelessWidget {
  const OmegaInspectorReceiver({super.key});

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) {
      return Material(
        child: Center(
          child: Text(
            'Inspector is only available in debug mode.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      );
    }
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
                'Omega Inspector (remote)',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'On this platform use the launcher button to open the inspector in a dialog.',
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
