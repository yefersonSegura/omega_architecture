import 'package:omega_architecture/omega_architecture.dart';

/// Eventos globales del example. Cada miembro es **solo identificador camelCase** (sin
/// `('auth.login.success')` por caso ni `const AppEvent(this.name); final String name`).
/// El alambre lleva puntos vía [OmegaEventNameDottedCamel], p. ej.
/// `authLoginSuccess` → `auth.login.success`.
enum AppEvent with OmegaEventNameDottedCamel implements OmegaEventName {
  navigationIntent,
  authLoginRequest,
  authLogoutRequest,
  authLoginStarted,
  authLoginSuccess,
  authLoginError,
  authLogoutSuccess,
}

/// Intents globales del example. Misma convención ([OmegaIntentNameDottedCamel]): solo
/// identificadores — `navigateLogin` → `navigate.login`, `ordersCreate` → `orders.create`.
enum AppIntent with OmegaIntentNameDottedCamel implements OmegaIntentName {
  navigateLogin,
  navigateHome,
  authLogin,
  authLogout,
  ordersCreate,
}
