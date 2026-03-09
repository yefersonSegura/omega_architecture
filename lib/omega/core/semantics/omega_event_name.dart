/// Contract for typed event names (avoids magic strings and eases refactoring).
///
/// Implement this interface with an enum or class to define your app's known
/// events and use [OmegaEvent.fromName] when emitting. You get autocomplete and
/// the analyzer catches broken usages when you change the name.
///
/// Example with enum:
/// ```dart
/// enum AppEvent implements OmegaEventName {
///   authLoginSuccess('auth.login.success'),
///   userUpdated('user.updated'),
///   navigateHome('navigate.home');
///   const AppEvent(this.name);
///   @override
///   final String name;
/// }
/// // Usage: channel.emit(OmegaEvent.fromName(AppEvent.authLoginSuccess, payload: user));
/// ```
abstract class OmegaEventName {
  /// Event name (e.g. "auth.login.success").
  String get name;
}
