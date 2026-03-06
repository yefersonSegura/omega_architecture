import 'package:omega_architecture/omega_architecture.dart';
import 'provider_behavior.dart';

class ProviderAgent extends OmegaAgent {
  ProviderAgent(OmegaChannel channel)
    : super(id: "Provider", channel: channel, behavior: ProviderBehavior());

  @override
  void onMessage(OmegaAgentMessage msg) {}

  @override
  void onAction(String action, dynamic payload) {}
}
