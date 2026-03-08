/// Contrato para nombres de evento tipados (evita strings mágicos y facilita refactors).
///
/// Implementa esta interfaz con un enum o una clase para definir los eventos conocidos
/// de tu app y usa [OmegaEvent.fromName] al emitir. Así tienes autocompletado y el
/// analizador detecta usos rotos si cambias el nombre.
///
/// Ejemplo con enum:
/// ```dart
/// enum AppEvent implements OmegaEventName {
///   authLoginSuccess('auth.login.success'),
///   userUpdated('user.updated'),
///   navigateHome('navigate.home');
///   const AppEvent(this.name);
///   @override
///   final String name;
/// }
/// // Uso: channel.emit(OmegaEvent.fromName(AppEvent.authLoginSuccess, payload: user));
/// ```
abstract class OmegaEventName {
  /// Nombre del evento (ej. "auth.login.success").
  String get name;
}
