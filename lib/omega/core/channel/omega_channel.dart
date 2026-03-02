import 'dart:async';
import '../events/omega_event.dart';

class OmegaChannel {
  final _controller = StreamController<OmegaEvent>.broadcast();

  Stream<OmegaEvent> get events => _controller.stream;

  void emit(OmegaEvent event) {
    _controller.add(event);
  }

  void dispose() {
    _controller.close();
  }
}
