// lib/omega/flows/omega_flow_expression.dart

class OmegaFlowExpression {
  final String type; // ejemplo: "loading", "data", "error"
  final dynamic payload; // datos opcionales

  const OmegaFlowExpression(this.type, {this.payload});
}
