/// Result of a rule: [action] name and optional [payload]. The agent receives both in [OmegaAgent.onAction].
///
/// Omit [payload] when [onAction] does not need data for that action (e.g. `const OmegaAgentReaction("logout")`).
/// Pass [payload] when [onAction] uses it (e.g. `OmegaAgentReaction("login", payload: creds)`).
class OmegaAgentReaction {
  /// Action name (e.g. "login"). In [onAction] you compare by this value.
  final String action;

  /// Data for the action (e.g. credentials).
  final dynamic payload;

  const OmegaAgentReaction(this.action, {this.payload});
}
