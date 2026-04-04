// Stub: on non-web the inspector opens in a dialog.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'omega_inspector.dart';

/// Button that opens the inspector. On **web** the implementation opens a new browser window.
/// On other platforms this stub opens a [Dialog]. Hidden in release (no-op).
class OmegaInspectorLauncher extends StatelessWidget {
  /// Max events to keep in the inspector panel.
  final int eventLimit;

  const OmegaInspectorLauncher({super.key, this.eventLimit = kOmegaInspectorDefaultEventLimit});

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) return const SizedBox.shrink();
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
