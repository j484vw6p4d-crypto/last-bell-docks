# Last Bell — Beta 0.1

This is a **friends-only beta**, not a public launch.

## What beta means here
- Loop works: harvest → stock → sell by day → steal at night → rebirth
- Map is still generated parts
- Data does **not** persist yet (leaving wipes coins)
- Keep the experience **Limited + Friends**

## Convert Studio play into the published place

1. Stop Steal a Crystal Rojo (`Ctrl+C` in that window).
2. Serve this repo:

```powershell
cd $HOME\Documents\last-bell-docks
git pull
rojo serve
```

3. Studio → **File → Open from Roblox** → **Last Bell** (not Girgaax2's Place).
4. Plugins → Rojo → Connect → Accept.
5. Press Play. Confirm HUD says **BETA 0.1** and you spawn at a stall.
6. Stop Play.
7. **File → Publish to Roblox** (same Last Bell place).
8. Dashboard: Last Bell stays **Limited**, Friends + Playtesters on.

Friends join from your profile or the place link. They will **not** see Rojo — they get the last publish.

## After every code change
`git pull` → Rojo still running or restart it → Play to test → Publish to Roblox again.
