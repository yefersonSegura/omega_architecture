import 'omega_agent_message.dart';

/// FIFO queue of direct messages for an agent.
///
/// When a message arrives via [OmegaAgentProtocol.send], the agent's [receiveMessage] calls
/// [receive] (which adds to the queue) and then [onMessage]. So you can handle immediately
/// in [onMessage], or ignore there and drain later with [next]. Messages stay in the queue
/// until removed by [next]. Optionally set [maxMessages] to cap the queue and drop oldest when full.
class OmegaAgentInbox {
  final _queue = <OmegaAgentMessage>[];
  final int maxMessages;

  /// [maxMessages] > 0 caps the queue (oldest dropped when full); 0 means unbounded.
  OmegaAgentInbox({this.maxMessages = 0});

  /// Adds a message to the queue. If [maxMessages] is set and the queue is full, the oldest message is removed first.
  void receive(OmegaAgentMessage message) {
    if (maxMessages > 0 && _queue.length >= maxMessages) {
      _queue.removeAt(0);
    }
    _queue.add(message);
  }

  /// Removes and returns the next message, or null if empty.
  OmegaAgentMessage? next() {
    if (_queue.isEmpty) return null;
    return _queue.removeAt(0);
  }

  /// Whether there are messages in the queue.
  bool get hasMessages => _queue.isNotEmpty;

  /// Number of messages currently in the queue.
  int get length => _queue.length;
}
