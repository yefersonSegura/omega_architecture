// lib/omega/flows/omega_flow_expression.dart

/// [OmegaFlowExpression] es un mensaje que un [OmegaFlow] emite hacia la UI.
///
/// El flow llama a [OmegaFlow.emitExpression]. La UI se suscribe a
/// [OmegaFlow.expressions] y reconstruye según [type] y [payload] (ej. "loading", "success").
class OmegaFlowExpression {
  /// Tipo de expresión (ej. "loading", "success", "error", "idle").
  final String type;

  /// Datos opcionales asociados (objeto, mapa, etc.).
  final dynamic payload;

  const OmegaFlowExpression(this.type, {this.payload});
}
