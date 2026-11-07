# Trickster

Trickster is a safety-first Luanti framework for context-driven, unnamed nature-spirit personas.
It currently contains one unnamed underground persona with one harmless acoustic interaction.

The binding design is documented in `DESIGN.md`.

## Architecture

- Persona packages register descriptive traits and plan builders.
- Plan builders may request only core-owned effect types.
- The framework revalidates every target immediately before applying an effect.
- Persistent player/persona relationships, cooldowns, transactions and fulfillment contracts live in the core.
- `fakelib` supplies player-shaped actors for regular protection and callback integration. It never replaces framework checks.
- Diagnostic audit records always retain the real origin of an action.

Currently exposed effect types are `sound`, `node_relocate` and `player_inventory_swap`.
Sounds and relocatable nodes require exact framework profiles before a plan can use them. Node inventories have an exact whitelist/profile API, but no generic take operation is enabled yet: removal will only be exposed together with an explicit vault fulfillment recipe.

## First persona

The technical package `personas/underground_01` has no canonical in-world name. It becomes active only below Y = -500, reaches its full depth factor at Y = -2500, requires at least two minutes underground and strongly prefers players without nearby witnesses.

Its first interaction plays a quiet ordinary Minetest Game sound behind or beside the player. At maximum activation the initial mean waiting time is one hour. A successful event applies a general player cooldown of 60–180 minutes and a persona-specific cooldown of 2–6 hours.

## Server camouflage

The canonical development name is `trickster`. A server operator may manually copy the directory under an inconspicuous name such as `marghl_custom_ambient` and change `name` in `mod.conf` to the same name. Enable that renamed mod normally in `world.mt`.

The code derives settings, privileges, commands and log prefixes from `minetest.get_current_modname()`. Renaming an existing installation changes those identifiers. Persistent data belongs to the loaded mod name, so existing state must be migrated deliberately or the renamed installation starts with empty framework state.

Do not configure `load_mod_<alias> = mods/trickster`; Luanti mod loading is based on the directory and `mod.conf` identity, not an arbitrary path assignment in `world.mt`.
