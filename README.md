# Last Bell Docks

**One-line hook:** Grow cargo on the pier by day. When the bell rings, the harbor goes dark — and anyone can steal from open stalls.

Not a Steal-a-Crystal clone. Loop is Grow a Garden (wait/harvest) + 99 Nights (night threat) + a market stall (Sell Lemons), with PvP only during **Bell Night**.

Leave Steal a Crystal alone. This is a new repo: https://github.com/j484vw6p4d-crypto/last-bell-docks

## The 7 product points

| # | Point | How this project covers it |
|---|--------|------------------------------|
| 1 | Map that feels like a place | Harbor town: pier, stalls, bell tower, lanterns, water plane |
| 2 | Audio | Pickup / sell / bell / night sting via `rbxasset://` sounds |
| 3 | Unique hook | Day = safe grow. Night = open season. Bell is the brand |
| 4 | Retention | Rebirth multiplier + gamepass stubs in Config |
| 5 | Density | 20 stalls, server-size note 20 |
| 6 | Discover | Title, icon copy, thumbnail brief, tutorial in DESIGN.md |
| 7 | Iteration | Roadmap below. Update weekly after friends playtest |

## Play in Studio

```powershell
cd $HOME\Documents
git clone https://github.com/j484vw6p4d-crypto/last-bell-docks.git
cd last-bell-docks
rojo serve
```

New Baseplate → Plugins → Rojo → Connect → Accept → Play.

**Loop:** walk to the pier → harvest crate → stock YOUR stall → wait for gold customers OR survive Bell Night without getting cleaned out → sell → rebirth at 500 coins.

## Publish checklist (point 6)

1. Creator Dashboard → new experience, max players **20**
2. Title: `Last Bell Docks`
3. Icon: lantern + bell on black water
4. Thumbnail text: `GROW BY DAY. STEAL WHEN THE BELL RINGS.`
5. Description: use the one-line hook
6. Enable Studio API Services if you want DataStores live
7. Playtest with 3 friends before public

Gamepass IDs in `Config.lua` are `0` until you create them in Creator Dashboard.

## Roadmap (point 7)

- Week 1: friends-only, tune day/night length
- Week 2: replace generated stalls with a Studio-built dock mesh
- Week 3: real music + more crate types
- Week 4: codes + daily login
