import 'package:omega_architecture/omega_architecture.dart';
import 'package:omega_architecture/omega/bootstrap/omega_config.dart';

import '../auth/auth_agent.dart';
import '../auth/auth_flow.dart';
import '../auth/models.dart';
import '../auth/ui/auth_page.dart';
import '../home/home.dart';
import '../orders/orders_flow.dart';
import '../provider/provider_agent.dart';
import '../provider/provider_flow.dart';

OmegaConfig createOmegaConfig(OmegaChannel channel) {
  final offlineQueue = OmegaMemoryOfflineQueue();
  final authNs = channel.namespace('auth');
  final providerNs = channel.namespace('provider');
  final ordersNs = channel.namespace('orders');

  return OmegaConfig(
    agents: <OmegaAgent>[
      ProviderAgent(providerNs),
      AuthAgent(authNs),
    ],
    flows: <OmegaFlow>[
      ProviderFlow(providerNs),
      AuthFlow(authNs),
      OrdersFlow(ordersNs, offlineQueue),
    ],
    routes: [
      OmegaRoute(id: "login", builder: (context) => const OmegaLoginPage()),
      // Ruta tipada: la vista recibe LoginSuccessPayload? (ej. tras login desde el flow)
      OmegaRoute.typed<LoginSuccessPayload>(
        id: "home",
        builder: (context, userData) => HomePage(userData: userData),
      ),
    ],
    initialFlowId: "authFlow",
  );
}
