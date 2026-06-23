## Loadstring ( Mobile/Pc )
```lua
loadstring(game:HttpGet("https://github.com/BOXLEGENDARY/Dex/releases/latest/download/out.lua"))()
```

---

## Search Filters ( QoL )
You can chain filters using `&&` (AND), `||` (OR), and `!` (NOT).

| Filter | Description | Example |
| :--- | :--- | :--- |
| `c:ClassName` | Find instances by ClassName. | `c:Part` |
| `p:Prop=Val` | Find instances with a specific property value. | `p:Anchored=true` |
| `p:Prop>Val` | Compare numbers (supports `>`, `<`, `>=`, `<=`, `~=`). | `p:Transparency>0.5` |
| `a:Name=Val` | Search by custom Attribute. | `a:IsAdmin=true` |
| `t:Tag` | Find instances with a CollectionService tag. | `t:KillBrick` |
| `rad:Radius` | Find parts within a specific radius from your character. | `rad:50` |
| `in:Name` | Find instances inside a specific parent. | `c:Script && in:Workspace` |
| `remotes` | Quick filter for all RemoteEvents/Functions. | `remotes` |

*Example:* `c:BasePart && p:Transparency=1 && rad:100` (Finds all invisible parts within 100 studs).

---
## Notes
* To reset the settings, delete `workspace/dex/DexSettings.json`.
* ​To install plugins, place the plugin files in `workspace/dex/plugins`.
* All files save in `workspace/dex/saved`.
* What's different between Dex 2021 and Dex 2026?
    * Mostly keeping it fresh and adding more features.
    * Uses stable third-party components.
    * fix all problems in Dex.

---

## To Build
1. Download this repository
2. Ensure you have Python 3 (I use 3.9.0)
3. Run build.py
4. The executable script will be created as out.lua

---

## Credits
[ZxL](https://youtu.be/dQw4w9WgXcQ?si=IkAXjfO3Uf2UOJ9V) - Dex Developer

[chillz](https://github.com/AZYsGithub/DexPlusPlus) - DexPlusPlus

[Moon](https://github.com/LorekeeperZinnia/Dex) – Original Dex Explorer

---

## Third Party Components

[Konstant-Decompiler](https://discord.gg/konstant-tm-tm-lykooking-tm-krack-tm-tm-tm-tm-1277806964356939837)

[Advanced-Luau-Decompiler](https://github.com/BOXLEGENDARY/Advanced-Luau-Decompiler)

[UniversalSynapseSaveInstance](https://github.com/BOXLEGENDARY/UniversalSynSaveInstance)

[Shiny](https://github.com/BOXLEGENDARY/shiny)

---
