// Reexporta el launcher del inspector: en web abre otra ventana del navegador; en otras plataformas abre un diálogo.

export 'omega_inspector_launcher_stub.dart'
    if (dart.library.html) 'omega_inspector_launcher_web.dart';
