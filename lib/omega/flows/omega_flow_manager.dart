// lib/omega/flows/omega_flow_manager.dart

import 'package:omega_architecture/omega/core/semantics/omega_intent.dart';
import 'package:omega_architecture/omega/ui/navigation/omega_navigator.dart';

import '../core/channel/omega_channel.dart';

import 'omega_flow.dart';
import 'omega_flow_state.dart';

/// [OmegaFlowManager] es el orquestador de todos los flujos en la aplicación.
/// Permite registrar, activar y gestionar el ciclo de vida de mútiples flujos.
class OmegaFlowManager {
  /// El canal de comunicación global para coordinar eventos.
  final OmegaChannel channel;

  // Registro dinámico de flows del sistema.
  final Map<String, OmegaFlow> _flows = {};

  OmegaFlowManager({required this.channel});

  // -----------------------------------------------------------
  // 1. Registrar un Flow en el sistema
  // -----------------------------------------------------------
  /// Registra un nuevo flujo en el sistema para que pueda ser gestionado.
  void registerFlow(OmegaFlow flow) {
    _flows[flow.id] = flow;
  }

  // -----------------------------------------------------------
  // 2. Obtener un flow por ID
  // -----------------------------------------------------------
  OmegaFlow? getFlow(String id) => _flows[id];

  // -----------------------------------------------------------
  // 3. Recibir intenciones desde la UI o sistema
  // -----------------------------------------------------------
  /// Procesa una intención y la distribuye a todos los flujos que estén en ejecución.
  void handleIntent(OmegaIntent intent) {
    for (final flow in _flows.values) {
      if (flow.state == OmegaFlowState.running) {
        flow.receiveIntent(intent);
      }
    }
  }

  // -----------------------------------------------------------
  // 4. Activar un flow específico
  // -----------------------------------------------------------
  /// Inicia o reanuda un flujo específico por su identificador.
  void activate(String id) {
    final flow = _flows[id];
    if (flow == null) return;

    flow.start();
  }

  // -----------------------------------------------------------
  // 5. Poner un flow en pausa
  // -----------------------------------------------------------
  void pause(String id) {
    final flow = _flows[id];
    flow?.pause();
  }

  // -----------------------------------------------------------
  // 6. Dormir un flow
  // -----------------------------------------------------------
  void sleep(String id) {
    final flow = _flows[id];
    flow?.sleep();
  }

  // -----------------------------------------------------------
  // 7. Detener un flow definitivamente
  // -----------------------------------------------------------
  /// Finaliza un flujo definitivamente.
  void end(String id) {
    final flow = _flows[id];
    flow?.end();
  }

  /// Finaliza todos los flujos registrados (útil para cerrar sesión).
  void endAll() {
    for (final flow in _flows.values) {
      flow.end();
    }
  }

  // -----------------------------------------------------------
  // 9. Activar un único flow y pausar los demás (Modo exclusivo)
  // -----------------------------------------------------------
  void activateExclusive(String id) {
    for (final flow in _flows.values) {
      if (flow.id == id) {
        flow.start();
      } else {
        flow.pause();
      }
    }
  }

  /// Vincula un [OmegaNavigator] con el canal para procesar intenciones de navegación automáticamente.
  void wireNavigator(OmegaNavigator nav) {
    print("OmegaFlowManager: Vinculando navegador...");
    channel.events.listen((event) {
      print("OmegaFlowManager: Evento recibido -> ${event.name}");

      // 1. Manejar Intención formal (vía navigation.intent)
      if (event.name == "navigation.intent") {
        if (event.payload is OmegaIntent) {
          nav.handleIntent(event.payload as OmegaIntent);
        } else {
          print(
            "OmegaFlowManager ERROR: El payload de navigation.intent no es un OmegaIntent",
          );
        }
      }
      // 2. Manejar Evento directo (Atajo: permite usar name: 'navigate.login')
      else if (event.name.startsWith("navigate.")) {
        print(
          "OmegaFlowManager: Detectado atajo de navegación para ${event.name}",
        );
        nav.handleIntent(
          OmegaIntent(id: event.id, name: event.name, payload: event.payload),
        );
      }
    });
  }
}
