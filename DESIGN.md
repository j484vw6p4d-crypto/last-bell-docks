# Last Bell Docks — design

## Hook
You own a stall on a foggy dock. Crates grow on the pier (asynchronous, like a garden). Display them. NPC buyers pay during **Day**. When the **Bell** rings, lanterns dim and players may steal displayed crates. Owners who stay at their stall can tag a thief and force a drop.

## Why not another steal game
Stealing is a *phase*, not the whole product. Most of the session is growing and stocking — same dopamine as Grow a Garden — then a 40-second spike like 99 Nights / MM2 night.

## Day / Night
- Day 50s: harvest + sell to NPCs
- Bell 4s sting (sound + flash)
- Night 40s: steal prompts on other stalls
- Repeat. Night index increments (rebirth scales rewards)

## Economy
Coins → stall upgrades (display slots, grow speed, night lantern = harder steal).
Rebirth at 500 coins: coins reset, `rebirths+1`, coin multiplier `1 + 0.25*rebirths`.

## Anti-exploit
Server owns crates, coins, night flag, distances.
