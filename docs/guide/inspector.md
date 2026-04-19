# Inspector & VM Service

Omega can expose an **inspector** UI (dialog, separate window, or browser) backed by the **VM Service** so you can inspect channel traffic, flows, and related state during development.

For VM Service URLs and security, prefer **`omega inspector`** and the README on GitHub.

**Hosted inspector page:** **[inspector.html](/inspector.html)** (static asset in `docs/public/`, deployed with GitHub Pages). When `OmegaInspectorServer.start` prints a URL, it points at this page with a `#<encoded-vm-service-uri>` hash for auto-connect.
