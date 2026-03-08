/// Contrato para nombres de intent tipados (evita strings mágicos y facilita refactors).
///
/// Implementa esta interfaz con un enum o una clase para definir los intents conocidos
/// de tu app y usa [OmegaIntent.fromName] al crear intents. Así tienes autocompletado
/// y el analizador detecta usos rotos si cambias el nombre.
///
/// Ejemplo con enum:
/// ```dart
/// enum AppIntent implements OmegaIntentName {
///   goLogin('navigate.login'),
///   goHome('navigate.home'),
///   addToCart('cart.add');
///   const AppIntent(this.name);
///   @override
///   final String name;
/// }
/// // Uso: OmegaIntent.fromName(AppIntent.goLogin, payload: args);
/// ```
abstract class OmegaIntentName {
  /// Nombre del intent (ej. "navigate.login", "cart.add").
  String get name;
}
