/// Result of a rule: [action] name and [payload]. The agent receives it in [OmegaAgent.onAction].
///
/// **Example:** `OmegaAgentReaction("login", payload: creds);` → in onAction: action == "login", payload == creds.
class OmegaAgentReaction {
  /// Action name (e.g. "login"). In [onAction] you compare by this value.
  final String action;

  /// Data for the action (e.g. credentials).
  final dynamic payload;

  const OmegaAgentReaction(this.action, {this.payload});
}
