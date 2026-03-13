/// Direct message from one agent ([from]) to another ([to]).
///
/// Sent with [OmegaAgentProtocol.send]. The receiver gets it in [OmegaAgent.receiveMessage],
/// which enqueues it in [OmegaAgentInbox] and calls [OmegaAgent.onMessage].
class OmegaAgentMessage {
  /// Sender agent id (or "system" for [OmegaAgentProtocol.broadcast]).
  final String from;

  /// Receiver agent id. Must match a registered agent id for [OmegaAgentProtocol.send] to deliver.
  final String to;

  /// Action or command (e.g. "invalidateToken", "validate").
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
