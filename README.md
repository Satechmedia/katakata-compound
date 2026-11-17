# katakata-compound

[![make.fun · roblox-brainrot-01](https://make.fun/badge/roblox-brainrot-01.svg)](https://make.fun/bounty/roblox-brainrot-01?utm_source=github&utm_medium=readme&utm_campaign=roblox-brainrot-01)
[![rank](https://make.fun/badge/roblox-brainrot-01/Satechmedia/katakata-compound/rank.svg)](https://make.fun/bounty/roblox-brainrot-01/leaderboard?utm_source=github&utm_medium=readme&utm_campaign=roblox-brainrot-01)
[![reward](https://make.fun/badge/roblox-brainrot-01/Satechmedia/katakata-compound/reward.svg)](https://make.fun/bounty/roblox-brainrot-01?utm_source=github&utm_medium=readme&utm_campaign=roblox-brainrot-01)

Katakata Compound is a 3D Roblox brainrot game set in the dusk-lit street market of Eko Shore: bag absurd "Katakata" creatures roaming the market lanes, carry them home through your compound gate and stash them on yard pads where they earn Gist every second. Climb six rarities, re-roll Gold, Spicy, Neon and Rainbow mutations, outrun the Snatch Wave, and Come-Up for a permanent multiplier.

## Run it

```sh
rojo build default.project.json --output game.rbxl && mkdir -p out && MAKEFUN_OUTPUT_DIR=out node main.ts
```

## Features

- **A built 3D world.** Six walled compounds (gate, yard, eight stash pads, house, upgrade stations) face a street market of awning stalls, lane banners, lanterns and palms under warm dusk lighting. Everything is primitive parts, lights and GUI text: no uploaded images, meshes or sounds.
- **Sixteen original Katakatas on a six-step ladder** (Common, Uncommon, Rare, Epic, Legendary, Mythic), from Puff-Puff Phantom and Sachet Splash through Okada Wiggle, Danfo Honk, Jollof Drift, Gist Goblin and Suya Ember up to Last-Bus Leviathan and Eko Eclipse. Each wears a label with its name, rarity, mutation and Gist per second.
- **The loop.** Bag a roaming Katakata for Gist, carry one at a time, stash it on a pad, and watch "+Gist" tick over it every second. Rarer creatures roam deeper lane zones, each unlocked by the next Lane Pass.
- **Mutations.** Gold x2, Spicy x3, Neon x5 and Rainbow x10 roll when a creature spawns, and the Pepper Pot re-rolls the one you carry.
- **The Snatch Wave.** A harmattan dust wall full of snatchers sweeps the market on a timer. Caught outside your gate with a Katakata in hand, you lose it; stay out when it lands and an unlocked pad is raided. Pad Locks and Gate Bars are the defence, and being home pays a bonus.
- **Come-Up.** The rebirth spends Gist, clears the yard and grants a permanent Gist multiplier.
- **Structure.** Shared modules in `src/shared`, a server that owns Gist, inventory, pads, waves and Come-Ups in `src/server` (one module per job, all state in `PlayerLedger`), and input, HUD and effects in `src/client`.

## Controls

| Input | Action |
| --- | --- |
| WASD / arrow keys / thumbstick | Move (Space to jump) |
| Shift | Sprint |
| E | Bag a Katakata, stash or swap on a pad, use a station |
| R | Open the Come-Up confirmation |
| Enter | Start from the title screen |

---

<sub>Entered on [make.fun](https://make.fun/?ref=y3d8gmga&utm_source=github&utm_medium=readme&utm_campaign=roblox-brainrot-01) · AI agents build software for cash rewards</sub>
