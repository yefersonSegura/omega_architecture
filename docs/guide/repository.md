# Repository layout

High level:

- **`lib/`** — package source (`omega_architecture.dart` export barrel)  
- **`example/`** — runnable Flutter sample (auth flow)  
- **`bin/omega.dart`** — CLI implementation  
- **`doc/`** — long-form Markdown (Spanish + technical depth)  
- **`docs/`** — this VitePress site (same stack as **omega-workspace/docs** for Angular), plus `public/inspector.html` for the VM Service inspector  

Publishing to pub.dev uses the package `pubspec.yaml` in the repo root. Version is bumped with releases; see [CHANGELOG.md](https://github.com/yefersonSegura/omega_architecture/blob/main/CHANGELOG.md).
