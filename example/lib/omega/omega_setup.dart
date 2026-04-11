import 'package:omega_architecture/omega_architecture.dart';
import 'package:omega_architecture/omega/bootstrap/omega_config.dart';

import '../auth/auth_agent.dart';
import '../auth/auth_flow.dart';
import '../auth/auth_events.dart';
import '../auth/ui/auth_page.dart';
import '../home/home.dart';
import '../orders/orders_flow.dart';
import '../provider/provider_agent.dart';
import '../provider/provider_flow.dart';
import '../demo/example_intent_handlers.dart';
import 'app_runtime_ids.dart';

OmegaConfig createOmegaConfig(OmegaChannel channel) {
  final offlineQueue = OmegaMemoryOfflineQueue();
  final authNs = channel.namespace('auth');
  final providerNs = channel.namespace('provider');
  final ordersNs = channel.namespace('orders');
  final authAgent = AuthAgent(authNs);

  return OmegaConfig(
    agents: <OmegaAgent>[ProviderAgent(providerNs), authAgent],
    flows: <OmegaFlow>[
      ProviderFlow(providerNs),
      AuthFlow(authNs),
      OrdersFlow(ordersNs, offlineQueue),
    ],
    routes: [
      OmegaRoute(
        id: "login",
        builder: (context) => OmegaLoginPage(authAgent: authAgent),
      ),
      // Ruta tipada: la vista recibe LoginSuccessPayload? (ej. tras login desde el flow)
      OmegaRoute.typed<LoginSuccessPayload>(
        id: "home",
        builder: (context, userData) => HomePage(userData: userData),
      ),
    ],
    initialFlowId: AppFlowId.authFlow.id,
    intentHandlerRegistrars: [ExampleIntentHandlerDemo.attach],
  );
}
