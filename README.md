# func_breakable Breaker

Breaks `func_breakable` entities at the start of each round so players do not have to shoot them.

## How it works

After `round_start`, the plugin sends the `Break` input to every `func_breakable` except static and map-controlled ones:

- entities with the "Only Break on Trigger" spawn flag, which the map breaks through its own logic;
- entities with 0 health, which cannot take damage;
- entities with 1,000,000 or more health, which mappers use for permanent sensors.

When at least one entity breaks, the plugin prints the count in chat.

## Commands

No commands. Runs automatically.
