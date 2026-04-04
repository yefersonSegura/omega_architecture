// Conditional export: web opens a new browser window; other platforms use a dialog stub.

export 'omega_inspector_launcher_stub.dart'
    if (dart.library.html) 'omega_inspector_launcher_web.dart';
