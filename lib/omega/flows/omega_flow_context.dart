import 'package:omega_architecture/omega/core/semantics/omega_intent.dart';

import '../core/events/omega_event.dart';

class OmegaFlowContext {
  final OmegaEvent? event;
  final OmegaIntent? intent;
  final Map<String, dynamic> memory;

  OmegaFlowContext({this.event, this.intent, this.memory = const {}});
}
