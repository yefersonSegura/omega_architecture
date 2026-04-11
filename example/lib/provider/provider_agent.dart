import 'package:omega_architecture/omega_architecture.dart';

import '../omega/app_runtime_ids.dart';
import 'provider_behavior.dart';

class ProviderAgent extends OmegaAgent {
  static final _contract = OmegaAgentContract.fromTyped(
    agentId: AppAgentId.Provider.id,
    listenedEvents: [],
    acceptedIntents: [],
  );

  @override
  OmegaAgentContract? get contract => _contract;

  ProviderAgent(OmegaEventBus channel)
      : super(
          id: AppAgentId.Provider.id,
          channel: channel,
          behavior: ProviderBehavior(),
        );

  @override
  void onMessage(OmegaAgentMessage msg) {}

  @override
  void onAction(String action, dynamic payload) {}
}
