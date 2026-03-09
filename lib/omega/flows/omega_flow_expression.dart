// lib/omega/flows/omega_flow_expression.dart

/// Message a flow sends to the UI (loading, success, error). The UI listens to [OmegaFlow.expressions].
///
/// **Why use it:** The flow announces state; the UI doesn't ask "are you loading?". Use [payloadAs] for typed reads.
///
/// **Example:** In the flow: `emitExpression("success", payload: user);` In the UI: `exp.payloadAs<User>();`
class OmegaFlowExpression {
  /// Type ("loading", "success", "error"). The UI typically does setState based on this value.
  final String type;

  /// Optional data. Use [payloadAs] to read with type.
  final dynamic payload;

  const OmegaFlowExpression(this.type, {this.payload});
}

/// Extension to read the payload with type safety.
extension OmegaFlowExpressionPayloadExtension on OmegaFlowExpression {
  /// Returns [payload] as [T] if compatible; otherwise null.
  ///
  /// **Example:** `final user = exp.payloadAs<LoginSuccessPayload>();`
  T? payloadAs<T>() =>
      payload != null && payload is T ? payload as T : null;
}
