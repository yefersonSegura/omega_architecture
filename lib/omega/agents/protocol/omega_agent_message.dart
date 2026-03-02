class OmegaAgentMessage {
  final String from;
  final String to;
  final String action;
  final dynamic payload;

  const OmegaAgentMessage({
    required this.from,
    required this.to,
    required this.action,
    this.payload,
  });
}
