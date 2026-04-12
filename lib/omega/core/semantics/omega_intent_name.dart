import 'omega_semantics_wire_from_camel.dart';

/// Contract for typed intent names (avoids magic strings and eases refactoring).
///
/// Implement this interface with an enum or class to define your app's known
/// intents and use [OmegaIntent.fromName] when creating intents. You get autocomplete
/// and the analyzer catches broken usages when you change the name.
///
/// **Styles:** (1) Enhanced enum with `final String name` when you need exact wire
/// ids per case (legacy / hand-maintained strings). (2) [OmegaIntentNameDottedCamel] —
/// one camelCase member per intent; wire is derived (`navigateLogin` → `navigate.login`,
/// `ordersCreate` → `orders.create`). **Preferred for** `lib/omega/app_semantics.dart`
/// and feature `*_events.dart` — matches `example/lib/omega/app_semantics.dart` and
/// `omega init`. (3) [OmegaIntentNameEnumWire] when the wire should equal [Enum.name]
/// as-is (no dots).
///
/// Preferred (`AppIntent` in app semantics):
/// ```dart
/// enum AppIntent with OmegaIntentNameDottedCamel implements OmegaIntentName {
///   navigateLogin,
///   navigateHome,
/// }
/// // OmegaIntent.fromName(AppIntent.navigateLogin) → name "navigate.login"
/// ```
///
/// Legacy (explicit wire per case — still valid API, not recommended for new apps):
/// ```dart
/// enum LegacyIntent implements OmegaIntentName {
///   goLogin('navigate.login');
///   const LegacyIntent(this.name);
///   @override
///   final String name;
/// }
/// ```
abstract class OmegaIntentName {
  /// Intent name (e.g. "navigate.login", "cart.add").
  String get name;
}

/// Mixin: wire name = [omegaWireNameFromCamelCaseEnumMember] applied to [Enum.name].
///
/// Name one identifier per case in camelCase (`ordersCreate`, `authLogout`); the
/// runtime string becomes dotted lowercase (`orders.create`, `auth.logout`).
///
/// ```dart
/// enum OrdersIntent with OmegaIntentNameDottedCamel implements OmegaIntentName {
///   ordersCreate,
///   ordersCancel,
/// }
/// ```
mixin OmegaIntentNameDottedCamel on Enum implements OmegaIntentName {
  @override
  String get name =>
      omegaWireNameFromCamelCaseEnumMember((this as Enum).name);
}

/// Mixin for enums whose wire name is exactly [Enum.name] — no `case x('a.b')` per value.
///
/// Use when you do not need dotted protocol strings. Pick **descriptive** member names
/// (`authLoginSubmit` not `go`) so they stay unique across the app (or scope by module
/// enum: `AuthIntent`, `OrdersIntent`, …).
///
/// ```dart
/// enum DemoCounterIntent with OmegaIntentNameEnumWire implements OmegaIntentName {
///   demoCounterIncrement,
///   demoCounterReset,
/// }
/// // OmegaIntent.fromName(DemoCounterIntent.demoCounterIncrement) → name "demoCounterIncrement"
/// ```
mixin OmegaIntentNameEnumWire on Enum implements OmegaIntentName {
  @override
  String get name => (this as Enum).name;
}
