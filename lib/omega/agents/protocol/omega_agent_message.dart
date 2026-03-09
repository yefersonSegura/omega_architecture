/// Direct message from one agent ([from]) to another ([to]).
///
/// Sent with [OmegaAgentProtocol.send]. The receiver handles it in [OmegaAgent.onMessage].
class OmegaAgentMessage {
  /// Sender agent id.
  final String from;

  /// Receiver agent id.
  final String to;

  /// Action or command (e.g. "login", "validate").
  final String action;

  /// Optional data for the action.
  final dynamic payload;

  const OmegaAgentMessage({
    required this.from,
    required this.to,
    required this.action,
    this.payload,
  });
}
