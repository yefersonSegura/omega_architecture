import 'omega_agent_message.dart';

class OmegaAgentInbox {
  final _queue = <OmegaAgentMessage>[];

  void receive(OmegaAgentMessage message) {
    _queue.add(message);
  }

  OmegaAgentMessage? next() {
    if (_queue.isEmpty) return null;
    return _queue.removeAt(0);
  }

  bool get hasMessages => _queue.isNotEmpty;
}
