# Agents & behaviors

**OmegaAgent** subscribes to `channel.events` (often via typed streams). A **behavior** class maps **reaction** ids to imperative steps (HTTP, DB, analytics) and emits follow-up events.

Keep **widgets free** of IO: the agent is the natural place for side effects coordinated with the flow.

Reference implementation: **`example/lib/auth/auth_agent.dart`** in the repository.
