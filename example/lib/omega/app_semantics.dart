import 'package:omega_architecture/omega_architecture.dart';

/// Eventos globales del example. Cada miembro es **camelCase**; el nombre en alambre
/// lleva puntos automáticamente ([OmegaEventNameDottedCamel]), p. ej.
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

/// Intents globales del example. Misma convención ([OmegaIntentNameDottedCamel]):
/// `navigateLogin` → `navigate.login`, `ordersCreate` → `orders.create`.
enum AppIntent with OmegaIntentNameDottedCamel implements OmegaIntentName {
  navigateLogin,
  navigateHome,
  authLogin,
  authLogout,
  ordersCreate,
}
