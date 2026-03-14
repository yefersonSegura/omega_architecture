import 'package:omega_architecture/omega_architecture.dart';
import 'provider_behavior.dart';

class ProviderAgent extends OmegaAgent {
  static final _contract = OmegaAgentContract.fromTyped(
    agentId: 'Provider',
    listenedEvents: [],
    acceptedIntents: [],
  );

  @override
  OmegaAgentContract? get contract => _contract;

  ProviderAgent(OmegaEventBus channel)
      : super(id: "Provider", channel: channel, behavior: ProviderBehavior());

  @override
  void onMessage(OmegaAgentMessage msg) {}

  @override
  void onAction(String action, dynamic payload) {}
}
