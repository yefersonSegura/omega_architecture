# Navigation & routes

**OmegaNavigator** connects navigation **intents** to **`OmegaRoute`** entries (ids and builders). Wire names use dotted lower case (see **`OmegaIntentNameDottedCamel`**) so Dart identifiers map cleanly to route ids.

Wrong wiring (route id does not match intent wire) is a common first bug — see the README and **`example/lib/omega/omega_setup.dart`** for **`navigate.*`** vs **`navigate.push.*`**.

Contract summary: **[Total architecture](./total-architecture)** → Navigation.
