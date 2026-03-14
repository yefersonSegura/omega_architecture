// Conditional export: IO implementation on VM/mobile/desktop (dart:io), stub on web.

export 'omega_inspector_server_stub.dart'
    if (dart.library.io) 'omega_inspector_server_io.dart';
