import 'omega_agent_message.dart';

/// FIFO queue of direct messages for an agent.
///
/// When a message arrives via [OmegaAgentProtocol.send], [receive] is called.
/// The agent can consume with [next] or check [hasMessages].
class OmegaAgentInbox {
  final _queue = <OmegaAgentMessage>[];

  /// Adds a message to the queue.
  void receive(OmegaAgentMessage message) {
    _queue.add(message);
  }

  /// Returns the next message in the queue or null if empty.
  OmegaAgentMessage? next() {
    if (_queue.isEmpty) return null;
    return _queue.removeAt(0);
  }

  /// Whether there are messages pending to process.
  bool get hasMessages => _queue.isNotEmpty;
}
