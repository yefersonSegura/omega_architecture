import 'package:omega_architecture/omega_architecture.dart';

/// Eventos conocidos del example. Usar con [OmegaEvent.fromName] para evitar strings mágicos.
enum AppEvent implements OmegaEventName {
  navigationIntent('navigation.intent'),
  authLoginRequest('auth.login.request'),
  authLogoutRequest('auth.logout.request'),
  authLoginStarted('auth.login.started'),
  authLoginSuccess('auth.login.success'),
  authLoginError('auth.login.error'),
  authLogoutSuccess('auth.logout.success');

  const AppEvent(this.name);
  @override
  final String name;
}

/// Intents conocidos del example. Usar con [OmegaIntent.fromName] para evitar strings mágicos.
enum AppIntent implements OmegaIntentName {
  navigateLogin('navigate.login'),
  navigateHome('navigate.home'),
  authLogin('auth.login'),
  authLogout('auth.logout');

  const AppIntent(this.name);
  @override
  final String name;
}
