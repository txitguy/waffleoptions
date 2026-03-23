# WaffleOptions

WoW 12.0.1 retail addon that provides gameplay automations.

**IMPORTANT:** Always keep this file updated when making changes. Any new features, options, architecture decisions, or structural changes must be reflected here before the task is complete.

## Architecture

- **WaffleOptions.toc** — Addon metadata, declares `SavedVariables: WaffleOptionsDB`, loads files in order: `WaffleOptions.lua`, `Options.lua`
- **WaffleOptions.lua** — Core logic. Initializes saved variables with defaults, contains all automation functions, registers events and the `/waffle` slash command
- **Options.lua** — Custom options panel UI with category sidebar and content area. All settings save immediately to `WaffleOptionsDB` on interaction

## Settings System

- Settings are stored in the global `WaffleOptionsDB` table (WoW SavedVariables, persisted across sessions)
- Defaults are defined in the `defaults` table in `WaffleOptions.lua` and applied via `InitDB()`
- `InitDB()` is called immediately at load time (not just on ADDON_LOADED) so that `Options.lua` can safely read DB values during frame creation
- The global `WaffleOptions` table is used to share functions between files (e.g., `WaffleOptions.ToggleOptions`)

## Options Panel

- Opened with `/waffle` slash command
- Custom frame with dark theme, green accents, draggable, closes with Escape
- Left sidebar has section headers (non-interactive labels) with category sub-items; right side shows settings for the selected category
- Sidebar uses dynamic layout: `sidebarItems` ordered list + `LayoutSidebar()` positions all items
- `CreateSidebarSection(name)` creates a static section header label; `CreateCategoryButton(name, section)` creates a category item under a section (or top-level if section is nil)
- Sections: "General" (Interface, Repair & Sell, Mail, Summon, Resurrect, Party, Death, Quests, Screenshots) and "Dungeons & Raids" (Keystones, Completion Msg, Spec & Talents, Ready Check, Announcements, Combat Res, Interrupts)
- Helper functions `CreateCheckbox`, `CreateRadioGroup`, `CreateTextInput`, and `CreateSoundPicker` are used to build settings UI tied to `WaffleOptionsDB` keys
- When adding a new category: use `CreateCategoryButton(name, section)` and `CreateContentFrame(name)`, then populate the content frame with controls

## Features & Options

### Auto-Sell
- Sells all gray (Poor quality) items when visiting a merchant
- **Options (WaffleOptionsDB keys):**
  - `autoSellEnabled` (bool, default: true) — Master toggle for auto-selling gray items
  - `autoSellChat` (bool, default: true) — Whether to print sell total to chat

### Auto-Repair
- Runs when visiting a repair-capable merchant
- **Options (WaffleOptionsDB keys):**
  - `autoRepairEnabled` (bool, default: true) — Master toggle for auto-repair
  - `autoRepairMode` (string, default: "guild_first") — `"guild_first"`: attempts guild bank repair first, falls back to personal gold. `"personal_only"`: always uses personal gold
  - `autoRepairChat` (bool, default: true) — Whether to print repair cost to chat

### Auto-Confirm Loot
- Automatically confirms loot roll dialogs (Need/Greed) and Bind-on-Pickup prompts
- Listens for `CONFIRM_LOOT_ROLL` and `LOOT_BIND_CONFIRM` events
- Calls `ConfirmLootRoll()` / `ConfirmLootSlot()` via pcall (may be protected)
- **Options (WaffleOptionsDB keys):**
  - `autoConfirmLoot` (bool, default: false) — Master toggle for auto-confirming loot dialogs

### Auto-Fill Delete
- Auto-fills the "DELETE" text in item delete confirmation dialogs
- Uses `hooksecurefunc("StaticPopup_Show", ...)` to detect DELETE_ITEM/DELETE_GOOD_ITEM/DELETE_QUEST_ITEM popups
- Only fills the text; user still clicks confirm (safe, no protected API calls)
- **Options (WaffleOptionsDB keys):**
  - `autoFillDelete` (bool, default: false) — Master toggle for auto-filling delete text

### Auto-Mail
- Automatically collects items and gold from the mailbox when opened (MAIL_SHOW event)
- Skips COD mail, collects money and items from everything else
- Uses timer-based sequential processing (C_Timer.After with 0.15s between operations) since mail API is async
- Two-phase approach: Phase 1 collects money/items (high index to low), Phase 2 deletes empty mail after a 0.5s delay
- Stops processing immediately if mailbox is closed (MAIL_CLOSED event)
- **Options (WaffleOptionsDB keys):**
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
- **Options (WaffleOptionsDB keys):**
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
- **Options (WaffleOptionsDB keys):**
  - `autoResOOCEnabled` (bool, default: true) — Auto-accept out-of-combat resurrections
  - `autoResCombatEnabled` (bool, default: false) — Auto-accept combat resurrections
  - `autoResChatOnAccept` (bool, default: true) — Announce in chat when resurrection accepted
  - `autoResAcceptMsg` (string) — Customizable accept message (`{caster}` placeholder)
  - `autoResChatParty` (bool, default: true) — Enable chat in party
  - `autoResChatRaid` (bool, default: true) — Enable chat in raid
  - `autoResChatInstance` (bool, default: true) — Enable chat in instance groups

### Auto-Accept Party Invites
- Listens for `PARTY_INVITE_REQUEST` event (arg1 = inviterName)
- Checks if inviter is a friend (via `C_FriendList` and `C_BattleNet` APIs) and/or guildmate (via `GetGuildRosterInfo()`)
- Calls `AcceptGroup()` via pcall (may be protected) and hides the party invite popup
- **Options (WaffleOptionsDB keys):**
  - `autoPartyEnabled` (bool, default: false) — Master toggle for auto-accepting party invites
  - `autoPartyFriends` (bool, default: true) — Accept from friends
  - `autoPartyGuild` (bool, default: true) — Accept from guildmates

### Auto-Release Spirit
- Listens for `PLAYER_DEAD` event
- Only triggers in open world (skips instances via `IsInInstance()`)
- Calls `RepopMe()` via pcall after configurable delay, re-checks death state before releasing
- **Options (WaffleOptionsDB keys):**
  - `autoReleaseEnabled` (bool, default: false) — Master toggle for auto-release
  - `autoReleaseDelay` (number, default: 2) — Delay in seconds before auto-release

### Auto-Quest
- Listens for `QUEST_DETAIL` (accept), `QUEST_COMPLETE` (turn-in), and `QUEST_PROGRESS` (completion check) events
- Hold Shift to temporarily disable and interact manually
- Auto-complete skips quests with multiple reward choices (lets user pick)
- Calls `AcceptQuest()` / `CompleteQuest()` via pcall (may be protected)
- **Options (WaffleOptionsDB keys):**
  - `autoQuestAccept` (bool, default: false) — Auto-accept quests from NPCs
  - `autoQuestComplete` (bool, default: false) — Auto-complete quests at NPCs
  - `autoQuestRepeatables` (bool, default: true) — Include repeatable quests (dailies/weeklies) in auto-accept

### Gossip Skip
- Listens for `GOSSIP_SHOW` event
- Auto-selects NPC gossip when there is only one option via `C_GossipInfo.SelectOption()`
- Hold Shift to override
- **Options (WaffleOptionsDB keys):**
  - `autoGossipSkip` (bool, default: false) — Master toggle for gossip skip

### Auto-Screenshot
- Takes screenshots on configurable triggers with optional delay for UI toasts to appear
- Triggers: `ACHIEVEMENT_EARNED`, `ENCOUNTER_END` (boss kill, success=1), `PLAYER_LEVEL_UP`
- Uses `Screenshot()` API (safe, not protected)
- **Options (WaffleOptionsDB keys):**
  - `autoScreenshotEnabled` (bool, default: false) — Master toggle
  - `autoScreenshotAchievement` (bool, default: true) — Screenshot on achievement earned
  - `autoScreenshotBossKill` (bool, default: true) — Screenshot on boss kill
  - `autoScreenshotLevelUp` (bool, default: true) — Screenshot on level up
  - `autoScreenshotDelay` (number, default: 1) — Delay in seconds before taking screenshot
  - `autoScreenshotChat` (bool, default: true) — Print notification to chat

### General (Interface page)
- **Cutscene skipping:** Listens for `CINEMATIC_START` (in-engine) and `PLAY_MOVIE` (pre-rendered) events
  - `PLAY_MOVIE` uses `C_MovieInfo.GetMovieSeen(movieID)` to check if already watched; skips via `GameMovieFinished()`
  - `CINEMATIC_START` has no movie ID; uses a session-local `watchedMovies` table so in-engine cinematics play once per session then skip; skips via `CinematicFrame_CancelCinematic()`
- **Talking Head:** Listens for `TALKINGHEAD_REQUESTED`, hides `TalkingHeadFrame` immediately
- **Combat:** Listens for `PLAYER_REGEN_DISABLED` event (fires when entering combat). Closes the World Map (`WorldMapFrame:Hide()`) and/or bags (`CloseAllBags()`) on combat start
- **Options (WaffleOptionsDB keys):**
  - `skipCutscenes` (bool, default: false) — Master toggle for auto-skipping cutscenes
  - `skipCutscenesOnlyWatched` (bool, default: true) — Only skip cutscenes that have been watched before
  - `hideTalkingHead` (bool, default: false) — Hide Talking Head popups
  - `combatHideMap` (bool, default: true) — Auto-hide World Map when entering combat
  - `combatHideBags` (bool, default: true) — Auto-close bags when entering combat

### Dungeon & Raid (split across 7 sub-pages: Keystones, Completion Msg, Spec & Talents, Ready Check, Announcements, Combat Res, Interrupts)
- **M+ Key Reminder:** Listens for `GROUP_JOINED`, uses `C_LFGList.GetActiveEntryInfo()` / `C_LFGList.GetSearchResultInfo()` + `C_LFGList.GetActivityInfoTable()` to get group's listed key. Delayed 1s for API data availability.
- **Auto-Insert Keystone:** Listens for `CHALLENGE_MODE_KEYSTONE_RECEPTACLE_OPEN`, calls `C_ChallengeMode.SlotKeystone()` after 0.3s delay.
- **Key Result:** On `CHALLENGE_MODE_COMPLETED`, checks `C_MythicPlus.GetOwnedKeystoneLevel()` and `C_ChallengeMode.GetCompletionInfo()` after 2s delay. Reports key upgrade or depletion with optional alert sound.
- **Completion Message:** `CHALLENGE_MODE_COMPLETED` (M+), `LFG_COMPLETION_REWARD` (regular dungeons), and `ENCOUNTER_END` (raid boss kills, filtered to success=1 and instanceType="raid"). Sends customizable message to group chat via `GetGroupChatChannel()` with configurable delay via `C_Timer.After`.
- **Auto-Leave Instance:** On M+ or regular dungeon completion (reuses existing events), starts a cancellable countdown then calls `LeaveParty()` via pcall. Cancel with `/wafflecancel`.
- **Spec/Talent Reminder:** `ZONE_CHANGED_NEW_AREA` → checks `IsInMythicDungeon()` or `IsInRaidInstance()` based on user toggles. Shows current spec via `GetSpecializationInfo()`. Optionally shows active loadout name via `C_ClassTalents.GetActiveConfigID()` + `C_Traits.GetConfigInfo()`. Checks unspent talent points via `C_Traits.GetTreeCurrencyInfo()`. Optional alert sound. Logic extracted into `RunSpecAndTalentCheck()` for reuse by `/waffletest`. Separately toggleable for dungeons and raids.
- **Loot Spec Warning:** Integrated into `RunSpecAndTalentCheck()`. Uses `GetLootSpecialization()` (returns 0 if matching active spec). Warns if loot spec differs from active spec with optional alert sound.
- **Ready Check Buffs:** `READY_CHECK` event. Scans party classes via `UnitClass()`. Checks player for class buffs (Intellect 1459, Fortitude 21562, Battle Shout 6673, MotW 1126, Bronze 381748), food (Well Fed aura name match), flask (Phial/Flask aura name match) via `C_UnitAuras.GetBuffDataByIndex()`. Personal or group chat mode.
- **Role Check Auto-Accept:** Listens for `LFG_ROLE_CHECK_SHOW`, calls `CompleteLFGRoleCheck(true)` via pcall. Auto-confirms with current role.
- **Group Announcements:** `UNIT_SPELLCAST_SUCCEEDED` event. Announces when a group member places a Mage Table (spell 190336), Warlock Summoning Stone (spell 698), or a feast/buffet (table of known feast spell IDs). Each type independently toggleable. Uses `SendToChannel()` with configurable channel (print/emote/group).
- **Combat Res Tracker:** Integrated into `UNIT_SPELLCAST_SUCCEEDED` handler. Detects combat res spells (Rebirth 20484, Soulstone 20707, Raise Ally 61999, Intercession 391054) from group members.
- **Interrupt Announcements:** Integrated into `UNIT_SPELLCAST_SUCCEEDED` handler, player-only (+ pet for warlock Spell Lock). Table of interrupt spell IDs per class. Customizable message with `{spell}` placeholder. Cannot detect interrupted spell name due to CLEU restrictions.
- **Options (WaffleOptionsDB keys):**
  - `dungeonKeyReminder` (bool, default: true) — Show group key info on join
  - `dungeonAutoInsertKey` (bool, default: true) — Auto-slot keystone
  - `dungeonKeyResult` (bool, default: true) — Show key upgrade/depletion result
  - `dungeonKeyResultChannel` (string, default: "print") — Channel for key result
  - `dungeonKeyResultSound` (bool, default: true) — Alert sound on depletion
  - `dungeonKeyResultSoundID` (number, default: 11466) — Sound ID for depletion alert
  - `dungeonAutoGG` (bool, default: true) — Master toggle for completion message
  - `dungeonGGMessage` (string, default: "gg") — Customizable message
  - `dungeonGGDelay` (number, default: 4) — Delay in seconds
  - `dungeonGGMythicPlus` (bool, default: true) — Trigger on M+ completion
  - `dungeonGGRegular` (bool, default: true) — Trigger on regular dungeons
  - `dungeonGGRaidBoss` (bool, default: false) — Trigger on raid boss kill
  - `autoLeaveEnabled` (bool, default: false) — Master toggle for auto-leave instance
  - `autoLeaveDelay` (number, default: 15) — Delay in seconds before leaving
  - `autoLeaveMythicPlus` (bool, default: false) — Trigger on M+ completion
  - `autoLeaveRegular` (bool, default: true) — Trigger on regular dungeons
  - `dungeonSpecReminder` (bool, default: true) — Master toggle for spec reminder on zone entry
  - `dungeonSpecShowLoadout` (bool, default: true) — Show active talent loadout name in spec reminder
  - `dungeonSpecReminderDungeon` (bool, default: true) — Trigger spec reminder in mythic dungeons
  - `dungeonSpecReminderRaid` (bool, default: true) — Trigger spec reminder in raids
  - `dungeonSpecReminderChannel` (string, default: "print") — Channel for spec reminder
  - `dungeonUnspentWarning` (bool, default: true) — Warn about unspent talent points on zone entry
  - `dungeonUnspentChannel` (string, default: "print") — Channel for unspent warning
  - `dungeonUnspentSound` (bool, default: true) — Alert sound for unspent talents
  - `dungeonUnspentSoundID` (number, default: 11466) — Sound ID ("You are not prepared")
  - `dungeonLootSpecWarning` (bool, default: true) — Warn if loot spec differs from active spec
  - `dungeonLootSpecSound` (bool, default: false) — Play alert sound for loot spec mismatch
  - `dungeonReadyCheckBuffs` (bool, default: true) — Buff check on ready check
  - `dungeonBuffCheckMode` (string, default: "personal") — "personal" or "party"
  - `dungeonBuffCheckClassBuffs` (bool, default: true) — Check class buffs
  - `dungeonBuffCheckFood` (bool, default: true) — Check food buff
  - `dungeonBuffCheckFlask` (bool, default: true) — Check flask/phial
  - `autoRoleCheck` (bool, default: false) — Auto-confirm role check in LFG
  - `dungeonAnnounceMageTable` (bool, default: true) — Announce Mage Table placement
  - `dungeonAnnounceWarlock` (bool, default: true) — Announce Warlock Summoning Stone placement
  - `dungeonAnnounceFeast` (bool, default: true) — Announce feast/buffet placement
  - `dungeonAnnounceChannel` (string, default: "group") — Channel for group announcements
  - `dungeonCombatResTracker` (bool, default: false) — Announce combat resurrections
  - `dungeonCombatResChannel` (string, default: "print") — Channel for combat res announcements
  - `dungeonInterruptAnnounce` (bool, default: false) — Announce player interrupts
  - `dungeonInterruptMsg` (string, default: "Interrupted with {spell}!") — Customizable interrupt message
  - `dungeonInterruptChannel` (string, default: "group") — Channel for interrupt announcements

## Slash Commands

- `/waffle` — Opens the options panel
- `/waffletest` — Triggers spec/talent/loot-spec checks regardless of location (for testing)
- `/wafflecancel` — Cancels auto-leave countdown

## WoW 12.0 API Restrictions

WoW 12.0 (The War Within / Midnight) introduced major addon security changes. Be aware of these when developing features.

### DO NOT USE — Protected/Restricted
These will trigger `ADDON_ACTION_FORBIDDEN` errors:
- **`COMBAT_LOG_EVENT_UNFILTERED`** — Cannot register this event. Use `UNIT_SPELLCAST_SUCCEEDED` for spell detection instead
- **`CombatLogGetCurrentEventInfo()`** — Unavailable to addon code
- **`C_SummonInfo.ConfirmSummon()`** — Marked as PROTECTED (auto-summon may not work in all contexts)
- **`AcceptResurrect()`** — May be protected (auto-resurrect may not work in all contexts)
- **`AcceptGroup()`** — May be protected (auto-accept party may not work in all contexts)
- **`RepopMe()`** — May be protected (auto-release may not work in all contexts)
- **`AcceptQuest()` / `CompleteQuest()`** — May require hardware event (auto-quest may not work)
- **`CompleteLFGRoleCheck()`** — May be protected (auto-role-check may not work)
- **`LeaveParty()`** — May be protected (auto-leave may not work)
- **`ConfirmLootRoll()` / `ConfirmLootSlot()`** — May be protected (auto-confirm loot may not work)
- **Player action functions** — `JumpOrAscendStart()`, `MoveForwardStart()`, `FollowUnit()`, `TargetUnit()`, `CastSpell()`, `AttackTarget()`
- **Binding/macro functions** — `SetBinding()`, `SetBindingSpell()`, `CreateMacro()`, `EditMacro()`
- **Inventory functions** — `PickupInventoryItem()`, `DeleteCursorItem()`

### Restriction Tiers
- **Protected** — Always forbidden, fires `ADDON_ACTION_FORBIDDEN`
- **Hardware Event (hwevent)** — Requires user click, fires `ADDON_ACTION_BLOCKED`
- **No Combat (nocombat)** — Blocked during combat, fires `ADDON_ACTION_BLOCKED`
- **Secure Frame** — Cannot call on secure frames in combat

### Secret Values System (Instance Content)
In boss encounters, M+ runs, and instance content:
- Creature unit names, GUIDs, and IDs become "secret" (hidden from addons)
- Access to auras, cooldowns, spell casts, unit identity, and power information may be restricted
- Combat log data is restricted; alternatives: `C_DamageMeter`, `UnitThreatSituation`, `C_LossOfControl`, `C_CombatText`

### Potentially Risky APIs Used by This Addon
- `WorldMapFrame:Hide()` — Can spread taint, subject to secure frame restrictions in combat
- `CloseAllBags()` — May have combat restrictions in certain contexts
- `CinematicFrame_CancelCinematic()` — May have changed; `CinematicFinished(1)` may be needed in newer patches
- `GameMovieFinished()` — May be nil in newer patches
- `tinsert(UISpecialFrames, ...)` — Can cause taint propagation; used in Options.lua for Escape-to-close
- All potentially protected APIs are called via `pcall()` for graceful failure

### Safe APIs
- Standard event registration (`RegisterEvent()`) works for non-protected events
- `UNIT_SPELLCAST_SUCCEEDED`, `MERCHANT_SHOW`, `MAIL_SHOW`, `CONFIRM_SUMMON`, `RESURRECT_REQUEST`, `CHALLENGE_MODE_COMPLETED`, `LFG_COMPLETION_REWARD`, `CINEMATIC_START`, `PLAY_MOVIE`, `PLAYER_REGEN_DISABLED`, `READY_CHECK`, `ZONE_CHANGED_NEW_AREA`, `GROUP_JOINED`, `ENCOUNTER_END`, `PARTY_INVITE_REQUEST`, `PLAYER_DEAD`, `QUEST_DETAIL`, `QUEST_COMPLETE`, `QUEST_PROGRESS`, `GOSSIP_SHOW`, `ACHIEVEMENT_EARNED`, `PLAYER_LEVEL_UP`, `CONFIRM_LOOT_ROLL`, `LOOT_BIND_CONFIRM`, `LFG_ROLE_CHECK_SHOW` — All safe to register
- `SendChatMessage()` — Works from addon event handlers (not from `/run`)
- `Screenshot()` — Safe utility function
- `C_Container.*`, `C_Item.*`, `C_ChallengeMode.*`, `C_ClassTalents.*`, `C_Traits.*`, `C_MythicPlus.*`, `C_GossipInfo.*`, `C_FriendList.*`, `C_BattleNet.*` — Standard namespace APIs
- `GetLootSpecialization()`, `GetSpecializationInfoByID()` — Read-only spec APIs

## Conventions

- **All UI must be designed with beauty and excellent user experience in mind.** Prioritize clean, polished, ElvUI-inspired aesthetics: pixel-perfect borders, consistent spacing, thoughtful color use (green accent for interactive elements, warm gold for labels, muted grays for secondary text), hover/disabled states, and smooth visual feedback. The options panel should feel premium and intuitive.
- Chat messages use the prefix `|cff88cc88[WaffleOptions]|r`
- Uses modern WoW API (`C_Container.*`, `C_Item.*`, `Enum.ItemQuality`)
- No external libraries or dependencies
- Protected API calls are wrapped in `pcall()` for graceful failure
