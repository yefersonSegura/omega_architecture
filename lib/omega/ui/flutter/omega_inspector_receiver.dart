// Conditional export: web listens on BroadcastChannel; other platforms use the stub message.

export 'omega_inspector_receiver_stub.dart'
    if (dart.library.html) 'omega_inspector_receiver_web.dart';
