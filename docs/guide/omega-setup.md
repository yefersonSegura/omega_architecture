# omega_setup.dart

`omega_setup.dart` (name may vary per app) is where you assemble:

- **`OmegaChannel`** (and optional namespaces)  
- **`OmegaConfig`** — agents list, flows list, routes, navigator  
- **`OmegaScope`** / bootstrap for the `MaterialApp`

**Rule of thumb:** each **agent** instance appears once in `agents:`; each **flow** is constructed with the channel + its agent(s); **routes** ids must match navigation intent wires.

After **`omega init`**, compare your file with the **`example/lib/omega/`** tree in this repository.
