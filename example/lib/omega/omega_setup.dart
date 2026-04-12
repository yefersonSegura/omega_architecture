import 'package:omega_architecture/omega_architecture.dart';

// En el example, cada flujo recibe su agente (`required this.agent`) y expone
// [OmegaFlow.uiScopeAgent] para OmegaFlowExpressionBuilder + OmegaScopedAgentBuilder.
// Una sola instancia por módulo: final xAgent = XAgent(ns); agents + flows + rutas.

import '../auth/auth_agent.dart';
import '../auth/auth_flow.dart';
import '../auth/auth_events.dart';
import '../auth/ui/auth_page.dart';
import '../home/home.dart';
import '../orders/orders_agent.dart';
import '../orders/orders_flow.dart';
import '../provider/provider_agent.dart';
import '../provider/provider_flow.dart';
import '../demo/example_intent_handlers.dart';
import 'app_runtime_ids.dart';
import 'app_semantics.dart';

OmegaConfig createOmegaConfig(OmegaChannel channel) {
  final offlineQueue = OmegaMemoryOfflineQueue();
  final authNs = channel.namespace('auth');
  final providerNs = channel.namespace('provider');
  final ordersNs = channel.namespace('orders');
  final authAgent = AuthAgent(authNs);
  final providerAgent = ProviderAgent(providerNs);
  final ordersAgent = OrdersAgent(ordersNs);

  return OmegaConfig(
    agents: <OmegaAgent>[providerAgent, authAgent, ordersAgent],
    flows: <OmegaFlow>[
      ProviderFlow(channel: providerNs, agent: providerAgent),
      AuthFlow(channel: authNs, agent: authAgent),
      OrdersFlow(
        channel: ordersNs,
        agent: ordersAgent,
        offlineQueue: offlineQueue,
      ),
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
    initialNavigationIntent: OmegaIntent.fromName(AppIntent.navigateLogin),
    intentHandlerRegistrars: [ExampleIntentHandlerDemo.attach],
  );
}
