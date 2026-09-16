# FoxDebug guides

Start with **Getting started**; the rest can be read in any order.

| Guide | What it covers |
|-------|----------------|
| [Getting started](getting-started.md) | Adding the package and wiring the whole stack into a SwiftUI app |
| [Debug menu](debug-menu.md) | Opening the menu, writing your own sections, matching its look |
| [Feature flags](feature-flags.md) | Declaring flags, stages, overrides, reading flags in code |
| [Debug settings](debug-settings.md) | Text and choice settings, resolution order, threading |
| [Remote config](remote-config.md) | Feeding flags and settings from a backend, the deferred pattern |
| [Testing](testing.md) | Unit tests and previews without `UserDefaults` leaking between runs |
| [Recipes](recipes.md) | Switching servers, keeping the menu out of production, feature modules |
| [Migrating from 3.x](migrating-from-3.md) | What 4.0.0 changed and how to update |
| [Migrating from 2.x](migrating-from-2.md) | What 3.0.0 changed and how to update |

The `Demo/` directory holds iOS and macOS apps that use everything described here.
