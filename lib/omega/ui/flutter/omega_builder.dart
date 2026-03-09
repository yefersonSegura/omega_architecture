// lib/omega/ui/flutter/omega_builder.dart

import 'package:flutter/widgets.dart';
import 'package:omega_architecture/omega/core/events/omega_event.dart';
import 'omega_scope.dart';

/// Widget that rebuilds when an event arrives on the channel (optionally only when [eventName] matches).
///
/// **Why use it:** Show a banner when "auth.login.error" occurs without the screen knowing the flow. Requires [OmegaScope] in the tree.
///
/// **Example:** `OmegaBuilder(eventName: "auth.login.error", builder: (ctx, e) => Text(e?.payloadAs<String>() ?? ""));`
class OmegaBuilder extends StatelessWidget {
  /// Receives context and the latest event (or null). Called each time an event arrives (filtered by [eventName]).
  final Widget Function(BuildContext context, OmegaEvent? event) builder;

  /// If not null, only reacts to events with this name.
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
