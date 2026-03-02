import 'package:flutter/material.dart';
import 'package:omega_architecture/examples/auth/auth_agent.dart';
import 'package:omega_architecture/examples/auth/auth_behavior.dart';
import 'package:omega_architecture/examples/auth/auth_flow.dart';
import 'package:omega_architecture/examples/auth/ui/omega_login_page.dart';
import 'package:omega_architecture/examples/home/ui/omega_home_page.dart';
import 'package:omega_architecture/omega_architecture.dart';

void main() {
  // 1. Inicializar el núcleo una sola vez
  final channel = OmegaChannel();
  final flowManager = OmegaFlowManager(channel: channel);
  final navigator = OmegaNavigator();
  final protocol = OmegaAgentProtocol(channel);

  // 4. Registrar el agente de Auth
  final authAgent = AuthAgent(channel: channel, behavior: createAuthBehavior());

  protocol.register(authAgent);

  final authFlow = AuthFlow(channel: channel);
  flowManager.registerFlow(authFlow);
  flowManager.activate("authFlow");

  // 2. Configurar rutas
  navigator.registerRoute(
    OmegaRoute(
      id: 'login',
      builder: (context) => OmegaLoginPage(
        flowManager: flowManager,
      ), // Ya no necesitas pasar channel por constructor
    ),
  );

  navigator.registerRoute(
    OmegaRoute(id: 'home', builder: (context) => const OmegaHomePage()),
  );

  // 3. Conectar navegación
  flowManager.wireNavigator(navigator);

  runApp(
    // 4. EL SCOPE: Envuelve toda la app para inyectar las dependencias
    OmegaScope(
      channel: channel,
      flowManager: flowManager,
      child: MainApp(navigator: navigator),
    ),
  );
}

class MainApp extends StatelessWidget {
  final OmegaNavigator navigator;
  const MainApp({super.key, required this.navigator});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigator.navigatorKey,
      // Usamos un Builder para disparar el evento inicial una vez que el contexto esté listo
      home: const RootHandler(),
    );
  }
}

// Un pequeño widget para manejar el estado inicial
class RootHandler extends StatefulWidget {
  const RootHandler({super.key});

  @override
  State<RootHandler> createState() => _RootHandlerState();
}

class _RootHandlerState extends State<RootHandler> {
  @override
  void initState() {
    super.initState();
    final intent = OmegaIntent(id: "goLogin", name: "navigate.login");

    // 5. USAR EL SCOPE: Accedemos al canal global para disparar el login inicial
    WidgetsBinding.instance.addPostFrameCallback((_) {
      OmegaScope.of(context).channel.emit(
        OmegaEvent(
          id: "nav:${DateTime.now().millisecondsSinceEpoch}",
          name: 'navigation.intent',
          payload: intent,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        // 6. EL BUILDER: Ejemplo de cómo escuchar eventos en cualquier parte
        child: OmegaBuilder(
          eventName: 'system.status',
          builder: (context, event) {
            return Text(event?.payload ?? 'Cargando sistema...');
          },
        ),
      ),
    );
  }
}
