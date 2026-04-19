# Repository layout

High level:

- **`lib/`** — package source (`omega_architecture.dart` export barrel)  
- **`example/`** — runnable Flutter sample (auth flow)  
- **`bin/omega.dart`** — CLI implementation  
- **`doc/`** — long-form Markdown (Spanish + technical depth); the same files are **mirrored on this site** under **[Repository docs (Spanish)](/doc/)** when you run `npm run dev` / `npm run build` (see `docs/.vitepress/plugins/sync-doc-from-repo.mts`). Edit the Markdown in **`doc/`** on GitHub, not the generated copies under `docs/doc/`.  
- **`docs/`** — this VitePress site, plus `public/inspector.html` for the VM Service inspector  

Publishing to pub.dev uses the package `pubspec.yaml` in the repo root. Version is bumped with releases; see [CHANGELOG.md](https://github.com/yefersonSegura/omega_architecture/blob/main/CHANGELOG.md).
