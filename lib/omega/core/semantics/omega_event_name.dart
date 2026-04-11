import 'omega_semantics_wire_from_camel.dart';

/// Contract for typed event names (avoids magic strings and eases refactoring).
///
/// Implement this interface with an enum or class to define your app's known
/// events and use [OmegaEvent.fromName] when emitting. You get autocomplete and
/// the analyzer catches broken usages when you change the name.
///
/// **Styles:** (1) Enhanced enum with explicit `name`. (2) [OmegaEventNameDottedCamel]
/// — camelCase member → dotted wire (`authLoginSuccess` → `auth.login.success`).
/// (3) [OmegaEventNameEnumWire] — wire equals [Enum.name].
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

/// Mixin: wire = [omegaWireNameFromCamelCaseEnumMember] on [Enum.name].
///
/// ```dart
/// enum OrdersEvent with OmegaEventNameDottedCamel implements OmegaEventName {
///   ordersCreated,
///   ordersFailed,
/// }
/// ```
mixin OmegaEventNameDottedCamel on Enum implements OmegaEventName {
  @override
  String get name =>
      omegaWireNameFromCamelCaseEnumMember((this as Enum).name);
}

/// Mixin: wire equals [Enum.name] (no dots).
mixin OmegaEventNameEnumWire on Enum implements OmegaEventName {
  @override
  String get name => (this as Enum).name;
}
