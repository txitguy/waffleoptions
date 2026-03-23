# Wafflemations

WoW 12.0.1 retail addon that provides gameplay automations.

**IMPORTANT:** Always keep this file updated when making changes. Any new features, options, architecture decisions, or structural changes must be reflected here before the task is complete.

## Architecture

- **Wafflemations.toc** — Addon metadata, declares `SavedVariables: WafflemationsDB`, loads files in order: `Wafflemations.lua`, `Options.lua`
- **Wafflemations.lua** — Core logic. Initializes saved variables with defaults, contains all automation functions, registers events and the `/waffle` slash command
- **Options.lua** — Custom options panel UI with category sidebar and content area. All settings save immediately to `WafflemationsDB` on interaction

## Settings System

- Settings are stored in the global `WafflemationsDB` table (WoW SavedVariables, persisted across sessions)
- Defaults are defined in the `defaults` table in `Wafflemations.lua` and applied via `InitDB()`
- `InitDB()` is called immediately at load time (not just on ADDON_LOADED) so that `Options.lua` can safely read DB values during frame creation
- The global `Wafflemations` table is used to share functions between files (e.g., `Wafflemations.ToggleOptions`)

## Options Panel

- Opened with `/waffle` slash command
- Custom frame with dark theme, green accents, draggable, closes with Escape
- Left sidebar has category buttons; right side shows settings for the selected category
- Helper functions `CreateCheckbox`, `CreateRadioGroup`, and `CreateTextInput` are used to build settings UI tied to `WafflemationsDB` keys
- When adding a new category: use `CreateCategoryButton(name, index)` and `CreateContentFrame(name)`, then populate the content frame with controls

## Features & Options

### Auto-Sell
- Sells all gray (Poor quality) items when visiting a merchant
- **Options (WafflemationsDB keys):**
  - `autoSellEnabled` (bool, default: true) — Master toggle for auto-selling gray items
  - `autoSellChat` (bool, default: true) — Whether to print sell total to chat

### Auto-Repair
- Runs when visiting a repair-capable merchant
- **Options (WafflemationsDB keys):**
  - `autoRepairEnabled` (bool, default: true) — Master toggle for auto-repair
  - `autoRepairMode` (string, default: "guild_first") — `"guild_first"`: attempts guild bank repair first, falls back to personal gold. `"personal_only"`: always uses personal gold
  - `autoRepairChat` (bool, default: true) — Whether to print repair cost to chat

### Auto-Mail
- Automatically collects items and gold from the mailbox when opened (MAIL_SHOW event)
- Skips COD mail, collects money and items from everything else
- Uses timer-based sequential processing (C_Timer.After with 0.15s between operations) since mail API is async
- Two-phase approach: Phase 1 collects money/items (high index to low), Phase 2 deletes empty mail after a 0.5s delay
- Stops processing immediately if mailbox is closed (MAIL_CLOSED event)
- **Options (WafflemationsDB keys):**
  - `autoMailEnabled` (bool, default: true) — Master toggle for auto-collecting mail
  - `autoMailChat` (bool, default: true) — Whether to print collected gold/items summary to chat
  - `autoMailDeleteEmpty` (bool, default: true) — Auto-delete mail that has no items, money, or COD (just text) after collection

### Auto-Summon
- Listens for `CONFIRM_SUMMON` event
- Auto-accepts summons when enabled via `C_SummonInfo.ConfirmSummon()`
- Sends customizable chat messages to the appropriate channel (PARTY, RAID, or INSTANCE_CHAT) based on current group type
- Key behavior: "Chat on Receive" is suppressed when auto-accept is enabled to prevent double-messaging / spam. "Chat on Accept" still works with auto-accept on.
- Message templates support `{summoner}` and `{location}` placeholders, replaced at runtime via `FormatSummonMsg()`
- Group type detection order: Instance group (LFG/LFR) > Raid > Party (checked via `IsInGroup(LE_PARTY_CATEGORY_INSTANCE)`, `IsInRaid()`, `IsInGroup()`)
- **Options (WafflemationsDB keys):**
  - `autoSummonEnabled` (bool, default: false) — Master toggle for auto-accepting summons
  - `autoSummonChatOnReceive` (bool, default: true) — Announce in chat when summon received (disabled when auto-accept is on)
  - `autoSummonChatOnAccept` (bool, default: true) — Announce in chat when summon accepted
  - `autoSummonReceiveMsg` (string) — Customizable message for summon received
  - `autoSummonAcceptMsg` (string) — Customizable message for summon accepted
  - `autoSummonChatParty` (bool, default: true) — Enable chat announcements in party
  - `autoSummonChatRaid` (bool, default: true) — Enable chat announcements in raid
  - `autoSummonChatInstance` (bool, default: true) — Enable chat announcements in instance groups

### Auto-Resurrect
- Listens for `RESURRECT_REQUEST` event (arg1 = caster name)
- Separately toggleable for out-of-combat (enabled by default) and combat resurrections (disabled by default)
- Calls `AcceptResurrect()` and hides the static popup dialogs (`RESURRECT_NO_TIMER`, `RESURRECT_NO_SICKNESS`, `RESURRECT`)
- Checks `UnitAffectingCombat("player")` to determine if it's a combat res
- Customizable chat message on accept with `{caster}` placeholder
- Per-group-type chat toggles (party/raid/instance), reuses `GetGroupChatChannel()` from Auto-Summon
- **Options (WafflemationsDB keys):**
  - `autoResOOCEnabled` (bool, default: true) — Auto-accept out-of-combat resurrections
  - `autoResCombatEnabled` (bool, default: false) — Auto-accept combat resurrections
  - `autoResChatOnAccept` (bool, default: true) — Announce in chat when resurrection accepted
  - `autoResAcceptMsg` (string) — Customizable accept message (`{caster}` placeholder)
  - `autoResChatParty` (bool, default: true) — Enable chat in party
  - `autoResChatRaid` (bool, default: true) — Enable chat in raid
  - `autoResChatInstance` (bool, default: true) — Enable chat in instance groups

### General
- **Cutscene skipping:** Listens for `CINEMATIC_START` (in-engine) and `PLAY_MOVIE` (pre-rendered) events
  - `PLAY_MOVIE` uses `C_MovieInfo.GetMovieSeen(movieID)` to check if already watched; skips via `GameMovieFinished()`
  - `CINEMATIC_START` has no movie ID; uses a session-local `watchedMovies` table so in-engine cinematics play once per session then skip; skips via `CinematicFrame_CancelCinematic()`
- **Talking Head:** Listens for `TALKINGHEAD_REQUESTED`, hides `TalkingHeadFrame` immediately
- **Combat:** Listens for `PLAYER_REGEN_DISABLED` event (fires when entering combat). Closes the World Map (`WorldMapFrame:Hide()`) and/or bags (`CloseAllBags()`) on combat start
- **Options (WafflemationsDB keys):**
  - `skipCutscenes` (bool, default: false) — Master toggle for auto-skipping cutscenes
  - `skipCutscenesOnlyWatched` (bool, default: true) — Only skip cutscenes that have been watched before
  - `hideTalkingHead` (bool, default: false) — Hide Talking Head popups
  - `combatHideMap` (bool, default: true) — Auto-hide World Map when entering combat
  - `combatHideBags` (bool, default: true) — Auto-close bags when entering combat

### Dungeon
- **M+ Key Reminder:** Listens for `GROUP_JOINED`, uses `C_LFGList.GetActiveEntryInfo()` / `C_LFGList.GetSearchResultInfo()` + `C_LFGList.GetActivityInfoTable()` to get group's listed key. Delayed 1s for API data availability.
- **Auto-Insert Keystone:** Listens for `CHALLENGE_MODE_KEYSTONE_RECEPTACLE_OPEN`, calls `C_ChallengeMode.SlotKeystone()` after 0.3s delay.
- **End of Dungeon Message:** `CHALLENGE_MODE_COMPLETED` (M+) and `LFG_COMPLETION_REWARD` (regular). Sends customizable message to group chat via `GetGroupChatChannel()` with configurable delay via `C_Timer.After`.
- **Spec/Talent Reminder:** `ZONE_CHANGED_NEW_AREA` → checks `IsInMythicDungeon()` (mythic difficulty via `GetDifficultyInfo()` OR active challenge mode). Shows current spec via `GetSpecializationInfo()`. Optionally shows active loadout name via `C_ClassTalents.GetActiveConfigID()` + `C_Traits.GetConfigInfo()`. Checks unspent talent points via `C_Traits.GetTreeCurrencyInfo()`. Optional alert sound. Logic extracted into `RunSpecAndTalentCheck()` for reuse by `/waffletest`.
- **Ready Check Buffs:** `READY_CHECK` event. Scans party classes via `UnitClass()`. Checks player for class buffs (Intellect 1459, Fortitude 21562, Battle Shout 6673, MotW 1126, Bronze 381748), food (Well Fed aura name match), flask (Phial/Flask aura name match) via `C_UnitAuras.GetBuffDataByIndex()`. Personal or group chat mode.
- **Options (WafflemationsDB keys):**
  - `dungeonKeyReminder` (bool, default: true) — Show group key info on join
  - `dungeonAutoInsertKey` (bool, default: true) — Auto-slot keystone
  - `dungeonAutoGG` (bool, default: false) — Master toggle for end-of-dungeon message
  - `dungeonGGMessage` (string, default: "gg") — Customizable message
  - `dungeonGGDelay` (number, default: 0) — Delay in seconds
  - `dungeonGGMythicPlus` (bool, default: true) — Trigger on M+ completion
  - `dungeonGGRegular` (bool, default: true) — Trigger on regular dungeons
  - `dungeonSpecReminder` (bool, default: true) — Spec/talent reminder in dungeons
  - `dungeonSpecShowLoadout` (bool, default: true) — Show active talent loadout name in spec reminder
  - `dungeonSpecReminderChannel` (string, default: "print") — Channel for spec reminder
  - `dungeonUnspentWarning` (bool, default: true) — Warn about unspent talent points
  - `dungeonUnspentChannel` (string, default: "print") — Channel for unspent warning
  - `dungeonSpecReminderSound` (bool, default: true) — Alert sound for unspent talents
  - `dungeonSpecReminderSoundID` (number, default: 37666) — Sound ID ("You are not prepared")
  - `dungeonReadyCheckBuffs` (bool, default: true) — Buff check on ready check
  - `dungeonBuffCheckMode` (string, default: "personal") — "personal" or "party"
  - `dungeonBuffCheckClassBuffs` (bool, default: true) — Check class buffs
  - `dungeonBuffCheckFood` (bool, default: true) — Check food buff
  - `dungeonBuffCheckFlask` (bool, default: true) — Check flask/phial

## Conventions

- **All UI must be designed with beauty and excellent user experience in mind.** Prioritize clean, polished, ElvUI-inspired aesthetics: pixel-perfect borders, consistent spacing, thoughtful color use (green accent for interactive elements, warm gold for labels, muted grays for secondary text), hover/disabled states, and smooth visual feedback. The options panel should feel premium and intuitive.
- Chat messages use the prefix `|cff88cc88[Wafflemations]|r`
- Uses modern WoW API (`C_Container.*`, `C_Item.*`, `Enum.ItemQuality`)
- No external libraries or dependencies
