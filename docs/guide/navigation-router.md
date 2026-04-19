# Navigation & routes

**OmegaNavigator** connects navigation **intents** to **`OmegaRoute`** entries (ids and builders). Wire names use dotted lower case (see **`OmegaIntentNameDottedCamel`**) so Dart identifiers map cleanly to route ids.

Wrong wiring (route id does not match intent wire) is a common first bug — see README and [GUIA.md](https://github.com/yefersonSegura/omega_architecture/blob/main/doc/GUIA.md) for **`navigate.*`** vs **`navigate.push.*`** and examples.

Also read [ARQUITECTURA.md](https://github.com/yefersonSegura/omega_architecture/blob/main/doc/ARQUITECTURA.md) for the navigation contract.
