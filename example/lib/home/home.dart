import 'package:flutter/material.dart';

import '../auth/models.dart';

/// Pantalla Home. Recibe [userData] cuando se navega desde el flow tras login
/// con OmegaIntent.fromName(AppIntent.navigateHome, payload: loginSuccessPayload).
/// La ruta está registrada como OmegaRoute.typed(LoginSuccessPayload) para que
/// el argumento llegue tipado sin castear.
class HomePage extends StatelessWidget {
  const HomePage({super.key, this.userData});

  /// Datos del usuario tras login; null si se llegó sin pasar por login (ej. deep link).
  final LoginSuccessPayload? userData;

  @override
  Widget build(BuildContext context) {
    final name = userData?.user["name"] as String?;
    return Scaffold(
      appBar: AppBar(title: const Text("Home")),
      body: Center(
        child: name != null
            ? Text("Bienvenido, $name", style: const TextStyle(fontSize: 20))
            : const Text("Home Page"),
      ),
    );
  }
}
