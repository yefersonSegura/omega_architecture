/// Contract for typed intent names (avoids magic strings and eases refactoring).
///
/// Implement this interface with an enum or class to define your app's known
/// intents and use [OmegaIntent.fromName] when creating intents. You get autocomplete
/// and the analyzer catches broken usages when you change the name.
///
/// Example with enum:
/// ```dart
/// enum AppIntent implements OmegaIntentName {
///   goLogin('navigate.login'),
///   goHome('navigate.home'),
///   addToCart('cart.add');
///   const AppIntent(this.name);
///   @override
///   final String name;
/// }
/// // Usage: OmegaIntent.fromName(AppIntent.goLogin, payload: args);
/// ```
abstract class OmegaIntentName {
  /// Intent name (e.g. "navigate.login", "cart.add").
  String get name;
}
