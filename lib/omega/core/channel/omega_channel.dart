import 'dart:async';
import '../events/omega_event.dart';

/// [OmegaChannel] es el bus de eventos central del sistema.
///
/// Permite la comunicación reactiva: agentes y flows se suscriben a [events]
/// y cualquiera puede [emit] un [OmegaEvent]. Es el "sistema nervioso" de la app.
///
/// **Ciclo de vida:** Quien cree el canal debe llamar a [dispose] al cerrar la app.
/// Los agentes que escuchen [events] deben llamar a [OmegaAgent.dispose] para
/// cancelar suscripciones.
class OmegaChannel {
  final _controller = StreamController<OmegaEvent>.broadcast();

  /// Callback opcional al emitir y fallar (p. ej. canal ya cerrado).
  final void Function(Object error, StackTrace? stackTrace)? onEmitError;

  OmegaChannel({this.onEmitError});

  /// Stream de eventos al que se suscriben agentes, flows y la UI.
  Stream<OmegaEvent> get events => _controller.stream;

  /// Publica [event] en el canal. Los suscriptores de [events] lo reciben.
  /// Si el canal está cerrado, se llama [onEmitError] y no se emite.
  void emit(OmegaEvent event) {
    if (_controller.isClosed) {
      onEmitError?.call(
        StateError('OmegaChannel is disposed, cannot emit'),
        StackTrace.current,
      );
      return;
    }
    try {
      _controller.add(event);
    } catch (e, st) {
      if (!_controller.isClosed) {
        _controller.addError(e, st);
      }
      onEmitError?.call(e, st);
    }
  }

  /// Cierra el controlador del canal y libera recursos.
  void dispose() {
    if (!_controller.isClosed) {
      _controller.close();
    }
  }
}
