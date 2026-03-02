// lib/omega/flows/omega_flow_expression.dart

/// [OmegaFlowExpression] es un mensaje reactivo enviado desde un flujo hacia la UI.
/// Representa un cambio en el estado visual o una información que la interfaz debe mostrar.
class OmegaFlowExpression {
  /// El tipo de expresión (ej: "loading", "success", "error").
  final String type;

  /// La carga útil de datos asociada a la expresión.
  final dynamic payload;

  const OmegaFlowExpression(this.type, {this.payload});
}
