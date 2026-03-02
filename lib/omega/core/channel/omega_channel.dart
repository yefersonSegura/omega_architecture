import 'dart:async';
import '../events/omega_event.dart';

/// [OmegaChannel] es el bus de eventos central del sistema.
/// Permite la comunicación reactiva entre agentes y flujos.
class OmegaChannel {
  final _controller = StreamController<OmegaEvent>.broadcast();

  /// Un flujo de eventos [OmegaEvent] a los que cualquiera puede suscribirse.
  Stream<OmegaEvent> get events => _controller.stream;

  /// Emite un nuevo evento al canal para ser procesado por los suscriptores.
  void emit(OmegaEvent event) {
    try {
      _controller.add(event);
    } catch (e) {
      // Manejar o registrar error de emisión
      print("Error emitting event: $e");
    }
  }

  /// Cierra el controlador del canal y libera recursos.
  void dispose() {
    _controller.close();
  }
}
