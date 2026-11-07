# Trickster framework API v1

This API separates descriptive persona extensions from trusted effect integrations.

## Persona hook

```lua
trickster.register_persona({
    id = "underground_01",
    domain = {kind = "underground"},
    traits = {curiosity = 0.8, malice = 0.3},
    taboos = {"open_confession"},
    defaults = {check_interval = 30, mean_wait_at_maximum = 3600},
    activation = function(context)
        if context.position.y >= -500 then
            return {in_domain = false, factor = 0}
        end
        return {in_domain = true, factor = 0.1}
    end,
})
```

The ID is a meaningless technical identifier, not a canonical in-world name. Trait values are clamped to `0..1`. The activation callback is read-only and returns a bounded activity factor; it must not modify the world.

## Interaction hook

```lua
trickster.register_interaction({
    id = "misplace_tool",
    persona_id = "underground_01",
    intents = {"confuse"},
    tiers = {0},
    weight = 1,
    build_plan = function(context)
        return {
            player_name = context.player_name,
            intent = "confuse",
            tier = 0,
            cooldowns = {player = 7200, persona = 14400},
            effects = {{
                type = "player_inventory_swap",
                request = {source_index = 2, target_index = 19},
            }},
        }
    end,
})
```

`build_plan` may decline by returning `nil`. It must not modify the world. A plan may request only core-owned effect types; all requests are prepared and revalidated by the framework.

API v1 accepts exactly one effect per plan. Individual effects are crash-recoverable; compound plans remain disabled until the framework has a plan-wide rollback coordinator.

An automatic caller submits the registered interaction with:

```lua
local plan_id, reason = trickster.request_interaction(
    "underground_01:misplace_tool",
    {player_name = "singleplayer"}
)
```

## Current effects

### `player_inventory_swap`

Swaps two slots in the connected player's `main` inventory. The wielded source slot is rejected. Both slots are compared again immediately before the transaction.

### `sound`

Plays a profiled sound only for the target player. A trusted integration must register the sound profile first. Gain and distance are capped by that profile.

### `node_relocate`

Relocates an exactly profiled node between two loaded, accessible positions. The profile determines acceptable targets and the source replacement. Nodes carrying metadata are rejected unless the trusted profile explicitly permits them.

## Trusted integration hooks

The following hooks define what the framework can regard as safe. They belong in the core or a reviewed compatibility integration, never in a persona package:

- `trickster.register_sound_profile(id, definition)`
- `trickster.register_node_relocation_profile(definition)`
- `trickster.register_inventory_profile(definition)`
- `trickster.block_inventory_neighbor(node_name)`
- `trickster.block_inventory_neighbor_group(group_name)`

Inventory profiles grant operations separately for each exact node and inventory list. An allowed container is still rejected if an adjacent blocked automation node or an unloaded neighbor prevents a complete check.

Node-inventory removal is intentionally not exposed as a generic effect in API v1. The whitelist and fake-player callback adapter are present, but removal becomes executable only together with a reviewed fulfillment recipe using the persistent effect vault.

## Persistent state

Relationship values and cooldowns are stored per player and persona:

```lua
trickster.state.relationship(player_name, persona_id)
trickster.state.change_relationship(player_name, persona_id, delta)
trickster.state.cooldown_reason(player_name, persona_id)
trickster.state.set_cooldowns(player_name, persona_id, absolute_times)
```

Relationship values are clamped to `-100..100`.

## Operation modes

The persistent modes are `active`, `directing` and `paused`. Pausing clears all plans that have not begun. Prepared or partially applied transactions remain journaled and are recovered rather than discarded.

The administrator commands use the current mod name:

```text
/<current_modname>_status
/<current_modname>_mode active|directing|paused
```

They require the `<current_modname>_admin` privilege.
