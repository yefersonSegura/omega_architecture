import 'package:flutter/material.dart';
import 'package:omega_architecture/omega_architecture.dart';

import '../auth/auth_events.dart';
import '../demo/intent_handler_demo_page.dart';
import '../omega/app_runtime_ids.dart';
import '../omega/app_semantics.dart';

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
    return OmegaFlowActivator(
      flowId: AppFlowId.ordersFlow,
      child: Scaffold(
        appBar: AppBar(title: const Text("Home")),
        body: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (name != null)
                Text("Bienvenido, $name", style: const TextStyle(fontSize: 20))
              else
                const Text("Home Page", style: TextStyle(fontSize: 20)),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  final scope = OmegaScope.of(context);
                  final intent = OmegaIntent.fromName(
                    AppIntent.ordersCreate,
                    payload: {'total': 100},
                  );
                  scope.flowManager.handleIntent(intent);
                },
                child: const Text('Crear pedido (offline demo)'),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  Navigator.of(context).push<void>(
                    MaterialPageRoute<void>(
                      builder: (_) => const IntentHandlerDemoPage(),
                    ),
                  );
                },
                child: const Text('Demo: handlers + pipeline'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
