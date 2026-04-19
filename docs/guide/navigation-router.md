# Navigation & routes

**[OmegaNavigator](https://pub.dev/documentation/omega_architecture/latest/omega_architecture/OmegaNavigator-class.html)** registers **[OmegaRoute](https://pub.dev/documentation/omega_architecture/latest/omega_architecture/OmegaRoute-class.html)** entries and listens on the **channel** (via **[OmegaFlowManager.wireNavigator](https://pub.dev/documentation/omega_architecture/latest/omega_architecture/OmegaFlowManager/wireNavigator.html)**) for:

- **`navigation.intent`** with an **[OmegaIntent](https://pub.dev/documentation/omega_architecture/latest/omega_architecture/OmegaIntent-class.html)** payload, or  
- **`navigate.<id>`** / **`navigate.push.<id>`** event names (converted to intents).

Assign **`navigatorKey: runtime.navigator.navigatorKey`** on **`MaterialApp`**.

---

## `navigate.*` vs `navigate.push.*`

| Pattern | Navigator behaviour |
|---------|---------------------|
| **`navigate.login`** | **Replace** current route (e.g. login as root — user should not “back” into a stale screen). |
| **`navigate.push.detail`** | **Push** a new route so **`Navigator.pop`** returns to the previous screen. |

Intent **payloads** become **`RouteSettings.arguments`**. Prefer **`OmegaRoute.typed`** ([API](https://pub.dev/documentation/omega_architecture/latest/omega_architecture/OmegaRoute/OmegaRoute.typed.html)) or **`routeArguments`** so pages do not cast by hand.

---

## Route ids and wires

**`OmegaRoute(id: 'login')`** pairs with **`AppIntent`** members whose wire is **`navigate.login`** (via **`OmegaIntentNameDottedCamel`**). A **mismatch** between id and wire is a frequent first bug — **`omega validate`** checks common cases when your setup references **`navigateLogin`**, **`navigateHome`**, **`navigateRoot`**, etc.

---

## Cold start

**`initialNavigationIntent`** in [OmegaConfig](https://pub.dev/documentation/omega_architecture/latest/omega_architecture/OmegaConfig-class.html) must align with **[OmegaScope.initialNavigationIntent](https://pub.dev/documentation/omega_architecture/latest/omega_architecture/OmegaScope/initialNavigationIntent.html)** and **[OmegaInitialRoute](https://pub.dev/documentation/omega_architecture/latest/omega_architecture/OmegaInitialRoute-class.html)** so the first frame opens the correct screen. See **[omega_setup.dart](./omega-setup)**.

---

## Full example

`example/lib/omega/omega_setup.dart` (routes) + `auth_flow.dart` (navigation emits) + `auth_page.dart` (UI).

---

## Next

- [Intents, flows & manager](./intents-flows-manager)  
- [Total architecture](./total-architecture)  
