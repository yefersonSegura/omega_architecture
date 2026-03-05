import 'dart:async';
import '../events/omega_event.dart';

/// [OmegaChannel] es el bus de eventos central del sistema.
/// Permite la comunicación reactiva entre agentes y flujos.
///
/// Quien cree el canal debe llamar a [dispose] al cerrar la app para liberar recursos.
/// Los agentes que escuchen [events] deben llamar a su propio [OmegaAgent.dispose] para
/// cancelar suscripciones.
class OmegaChannel {
  final _controller = StreamController<OmegaEvent>.broadcast();

  /// Callback opcional para registrar errores de emisión (p. ej. canal cerrado).
  final void Function(Object error, StackTrace? stackTrace)? onEmitError;

  OmegaChannel({this.onEmitError});

  /// Un flujo de eventos [OmegaEvent] a los que cualquiera puede suscribirse.
  Stream<OmegaEvent> get events => _controller.stream;

  /// Emite un nuevo evento al canal para ser procesado por los suscriptores.
  /// Si el canal está cerrado, se notifica con [onEmitError] y no se emite.
  /// Si [add] falla (p. ej. cerrado entre comprobaciones), se notifica con [onEmitError]
  /// y se propaga el error a los suscriptores vía [Stream.addError].
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
