// Reexporta el receiver del inspector: en web escucha BroadcastChannel; en otras plataformas muestra mensaje.

export 'omega_inspector_receiver_stub.dart'
    if (dart.library.html) 'omega_inspector_receiver_web.dart';
