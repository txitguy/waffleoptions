local addonName = ...

-- Global addon table
WaffleOptions = {}

-- Default settings
local defaults = {
    autoRepairEnabled = true,
    autoRepairMode = "guild_first", -- "guild_first" or "personal_only"
    autoRepairChat = true,
    autoSellEnabled = true,
    autoSellChat = true,
    autoMailEnabled = true,
    autoMailChat = true,
    autoMailDeleteEmpty = true,
    autoSummonEnabled = false,
    autoSummonChatOnReceive = true,
    autoSummonChatOnAccept = true,
    autoSummonReceiveMsg = "Being summoned to {location} by {summoner}!",
    autoSummonAcceptMsg = "Summon accepted! On my way to {location}!",
    autoSummonChatParty = true,
    autoSummonChatRaid = true,
    autoSummonChatInstance = true,
    autoResOOCEnabled = true,
    autoResCombatEnabled = false,
    autoResChatOnAccept = true,
    autoResAcceptMsg = "Resurrection accepted, thanks {caster}!",
    autoResChatParty = true,
    autoResChatRaid = true,
    autoResChatInstance = true,
    combatHideMap = true,
    combatHideBags = true,
    skipCutscenes = true,
    skipCutscenesOnlyWatched = true,
    hideTalkingHead = false,
    dungeonKeyReminder = true,
    dungeonAutoInsertKey = true,
    dungeonAutoGG = true,
    dungeonGGMessage = "gg",
    dungeonGGDelay = 4,
    dungeonGGMythicPlus = true,
    dungeonGGRegular = true,
    dungeonGGRaidBoss = false,
    dungeonSpecReminder = true,
    dungeonSpecShowLoadout = true,
    dungeonSpecReminderChannel = "group",
    dungeonSpecReminderDungeon = true,
    dungeonSpecReminderRaid = true,
    dungeonUnspentWarning = true,
    dungeonUnspentChannel = "group",
    dungeonUnspentSound = true,
    dungeonUnspentSoundID = 11466, -- "You are not prepared"
    dungeonReadyCheckBuffs = true,
    dungeonBuffCheckMode = "party",
    dungeonBuffCheckClassBuffs = true,
    dungeonBuffCheckFood = true,
    dungeonBuffCheckFlask = true,
    dungeonBuffCheckDungeon = true,
    dungeonBuffCheckRaid = true,
    dungeonBuffCheckParty = false,
    dungeonAnnounceMageTable = true,
    dungeonAnnounceWarlock = true,
    dungeonAnnounceFeast = true,
    dungeonAnnounceChannel = "group",
    -- General
    showLoginMessage = true,
    -- Auto-Accept Party Invites
    autoPartyEnabled = true,
    autoPartyFriends = true,
    autoPartyGuild = true,
    -- Party Greetings
    partyGreetOnJoin = true,
    partyGreetOnJoinMessages = { "Hey everyone!", "Hello!", "Hi all!", "Howdy!" },
    partyGreetOnMemberJoin = true,
    partyGreetOnMemberJoinMessages = { "Welcome {player}!", "Hey {player}!", "Hello {player}!" },
    -- Auto-Release Spirit
    autoReleaseEnabled = true,
    autoReleaseDelay = 2,
    -- Auto-Quest
    autoQuestAccept = true,
    autoQuestComplete = true,
    autoQuestRepeatables = true,
    -- Gossip Skip
    autoGossipSkip = true,
    -- Auto-Screenshot
    autoScreenshotEnabled = false,
    autoScreenshotAchievement = true,
    autoScreenshotBossKill = true,
    autoScreenshotLevelUp = true,
    autoScreenshotDelay = 1,
    autoScreenshotChat = true,
    -- Achievement Congratulations
    achieveGratsParty = true,
    achieveGratsGuild = true,
    achieveGratsMessages = { "Grats {player}!", "Congrats {player}!", "Nice one {player}!", "Well done {player}!" },
    -- Auto-Confirm Loot
    autoConfirmLoot = true,
    -- Auto-Fill Delete
    autoFillDelete = true,
    -- Auto Role Check
    autoRoleCheck = true,
    -- Auto-Leave Instance
    autoLeaveEnabled = false,
    autoLeaveDelay = 15,
    autoLeaveMythicPlus = false,
    autoLeaveRegular = true,
    -- Key Swap Reminder
    dungeonKeySwapReminder = true,
    dungeonKeyChangeAlert = true,
    -- Key Result
    dungeonKeyResult = true,
    dungeonKeyResultChannel = "group",
    dungeonKeyResultSound = true,
    dungeonKeyResultSoundID = SOUNDKIT.LFG_DENIED or 11466,
    -- Combat Res Tracker
    dungeonCombatResTracker = true,
    dungeonCombatResChannel = "group",
    -- Interrupt Announcements
    dungeonInterruptAnnounce = true,
    dungeonInterruptMsg = "Interrupted with {spell}!",
    dungeonInterruptChannel = "group",
    -- Loot Spec Warning
    dungeonLootSpecWarning = true,
    dungeonLootSpecSound = false,
    dungeonLootSpecSoundID = 15391,
    dungeonLootSpecChannel = "group",
}

WaffleOptions.defaults = defaults

-- Initialize saved variables with defaults (called immediately so Options.lua can read DB)
local function InitDB()
    if not WaffleOptionsDB then
        WaffleOptionsDB = {}
    end
    for k, v in pairs(defaults) do
        if WaffleOptionsDB[k] == nil then
            WaffleOptionsDB[k] = v
        end
    end
end
InitDB()

-- Auto-sell gray items
local function AutoSellGrayItems()
    if not WaffleOptionsDB.autoSellEnabled then return end

    local totalSellPrice = 0
    for bag = 0, 4 do
        for slot = 1, C_Container.GetContainerNumSlots(bag) do
            local info = C_Container.GetContainerItemInfo(bag, slot)
            if info and info.quality == Enum.ItemQuality.Poor and not info.hasNoValue then
                totalSellPrice = totalSellPrice + (info.stackCount * (select(11, C_Item.GetItemInfo(info.itemID)) or 0))
                C_Container.UseContainerItem(bag, slot)
            end
        end
    end

    if totalSellPrice > 0 and WaffleOptionsDB.autoSellChat then
        print("|cff88cc88[WaffleOptions]|r Sold all gray items for " .. GetCoinTextureString(totalSellPrice) .. ".")
    end
end

-- Auto-repair gear
local function AutoRepair()
    if not WaffleOptionsDB.autoRepairEnabled then return end
    if not CanMerchantRepair() then return end

    local repairCost, canRepair = GetRepairAllCost()
    if not canRepair or repairCost <= 0 then return end

    local useGuild = false

    if WaffleOptionsDB.autoRepairMode == "guild_first" then
        if IsInGuild() and CanGuildBankRepair and CanGuildBankRepair() then
            RepairAllItems(true)
            useGuild = true
        end
    end

    if not useGuild then
        if GetMoney() >= repairCost then
            RepairAllItems(false)
        end
    end

    if WaffleOptionsDB.autoRepairChat then
        local source = useGuild and "Guild" or "Personal"
        print("|cff88cc88[WaffleOptions]|r " .. source .. " repair cost: " .. GetCoinTextureString(repairCost) .. ".")
    end
end

-- Auto-collect mail
local mail = {
    processing = false,
    index = 0,
    totalMoney = 0,
    itemsCollected = 0,
}

local function FinishMailProcessing()
    if not mail.processing then return end
    mail.processing = false

    if WaffleOptionsDB.autoMailChat and mail.totalMoney > 0 then
        print("|cff88cc88[WaffleOptions]|r Collected " .. GetCoinTextureString(mail.totalMoney) .. " from mail.")
    end
    if WaffleOptionsDB.autoMailChat and mail.itemsCollected > 0 then
        print("|cff88cc88[WaffleOptions]|r Collected items from " .. mail.itemsCollected .. " mail(s).")
    end
end

local function DeleteNextEmptyMail()
    if not mail.processing then return end

    while mail.index >= 1 do
        local _, _, _, _, money, CODAmount, _, hasItem = GetInboxHeaderInfo(mail.index)
        local isEmpty = (not money or money == 0) and not hasItem and (not CODAmount or CODAmount == 0)
        if isEmpty and InboxItemCanDelete(mail.index) then
            DeleteInboxItem(mail.index)
            mail.index = mail.index - 1
            C_Timer.After(0.15, DeleteNextEmptyMail)
            return
        end
        mail.index = mail.index - 1
    end

    FinishMailProcessing()
end

local function CollectNextMail()
    if not mail.processing then return end

    while mail.index >= 1 do
        local _, _, _, _, money, CODAmount, _, hasItem = GetInboxHeaderInfo(mail.index)

        if CODAmount and CODAmount > 0 then
            -- Skip COD mail
            mail.index = mail.index - 1
        else
            local didSomething = false
            if money and money > 0 then
                mail.totalMoney = mail.totalMoney + money
                TakeInboxMoney(mail.index)
                didSomething = true
            end
            if hasItem then
                AutoLootMailItem(mail.index)
                mail.itemsCollected = mail.itemsCollected + 1
                didSomething = true
            end

            mail.index = mail.index - 1
            if didSomething then
                C_Timer.After(0.5, CollectNextMail)
                return
            end
        end
    end

    -- Collection done, start delete phase if enabled
    if WaffleOptionsDB.autoMailDeleteEmpty then
        mail.index = GetInboxNumItems()
        C_Timer.After(0.5, DeleteNextEmptyMail)
    else
        FinishMailProcessing()
    end
end

local mailWaitingForData = false

local function StartMailCollection()
    if not WaffleOptionsDB.autoMailEnabled then return end
    if mail.processing then return end

    local numItems = GetInboxNumItems()
    if numItems == 0 then
        -- Inbox might not be populated yet; request data and wait
        if not mailWaitingForData then
            mailWaitingForData = true
            CheckInbox()
        end
        return
    end

    mailWaitingForData = false
    mail.processing = true
    mail.index = numItems
    mail.totalMoney = 0
    mail.itemsCollected = 0

    C_Timer.After(0.5, CollectNextMail)
end

local function HandleMailInboxUpdate()
    if mailWaitingForData then
        mailWaitingForData = false
        StartMailCollection()
    end
end

local function StopMailCollection()
    mail.processing = false
end

-- Auto-summon
local function GetGroupChatChannel()
    if IsInGroup(LE_PARTY_CATEGORY_INSTANCE) then
        return "INSTANCE_CHAT", "instance"
    elseif IsInRaid() then
        return "RAID", "raid"
    elseif IsInGroup() then
        return "PARTY", "party"
    end
    return nil, nil
end

local function IsSummonChatEnabledForGroup(groupType)
    if groupType == "party" then return WaffleOptionsDB.autoSummonChatParty end
    if groupType == "raid" then return WaffleOptionsDB.autoSummonChatRaid end
    if groupType == "instance" then return WaffleOptionsDB.autoSummonChatInstance end
    return false
end

local function FormatSummonMsg(template, summoner, location)
    local msg = template
    msg = msg:gsub("{summoner}", summoner or "Unknown")
    msg = msg:gsub("{location}", location or "Unknown")
    return msg
end

local function HandleSummon()
    local summoner = C_SummonInfo.GetSummonConfirmSummoner() or "Unknown"
    local location = C_SummonInfo.GetSummonConfirmAreaName() or "Unknown"
    local channel, groupType = GetGroupChatChannel()

    local chatEnabled = channel and groupType and IsSummonChatEnabledForGroup(groupType)

    -- Chat on receive (only if auto-accept is OFF to prevent spam)
    if not WaffleOptionsDB.autoSummonEnabled and WaffleOptionsDB.autoSummonChatOnReceive and chatEnabled then
        local msg = FormatSummonMsg(WaffleOptionsDB.autoSummonReceiveMsg, summoner, location)
        SendChatMessage(msg, channel)
    end

    -- Auto-accept
    if WaffleOptionsDB.autoSummonEnabled then
        C_SummonInfo.ConfirmSummon()
        print("|cff88cc88[WaffleOptions]|r Auto-accepted summon to " .. location .. " from " .. summoner .. ".")

        -- Chat on accept
        if WaffleOptionsDB.autoSummonChatOnAccept and chatEnabled then
            local msg = FormatSummonMsg(WaffleOptionsDB.autoSummonAcceptMsg, summoner, location)
            SendChatMessage(msg, channel)
        end
    end
end

-- Auto-resurrect
local function IsResChatEnabledForGroup(groupType)
    if groupType == "party" then return WaffleOptionsDB.autoResChatParty end
    if groupType == "raid" then return WaffleOptionsDB.autoResChatRaid end
    if groupType == "instance" then return WaffleOptionsDB.autoResChatInstance end
    return false
end

local function HandleResurrect(casterName)
    local inCombat = UnitAffectingCombat("player")

    if inCombat and not WaffleOptionsDB.autoResCombatEnabled then return end
    if not inCombat and not WaffleOptionsDB.autoResOOCEnabled then return end

    local caster = casterName or "someone"

    AcceptResurrect()
    StaticPopup_Hide("RESURRECT_NO_TIMER")
    StaticPopup_Hide("RESURRECT_NO_SICKNESS")
    StaticPopup_Hide("RESURRECT")

    print("|cff88cc88[WaffleOptions]|r Auto-accepted " .. (inCombat and "combat " or "") .. "resurrection from " .. caster .. ".")

    -- Chat announce
    if WaffleOptionsDB.autoResChatOnAccept then
        local channel, groupType = GetGroupChatChannel()
        if channel and groupType and IsResChatEnabledForGroup(groupType) then
            local msg = WaffleOptionsDB.autoResAcceptMsg:gsub("{caster}", caster)
            SendChatMessage(msg, channel)
        end
    end
end

-- Combat auto-hide
local function HandleCombatStart()
    if WaffleOptionsDB.combatHideMap and WorldMapFrame and WorldMapFrame:IsShown() then
        HideUIPanel(WorldMapFrame)
    end
    if WaffleOptionsDB.combatHideBags then
        CloseAllBags()
    end
    -- Close WaffleOptions panel in combat
    local wof = _G["WaffleOptionsFrame"]
    if wof and wof:IsShown() then
        wof:Hide()
        print("|cff88cc88[WaffleOptions]|r Options panel closed — cannot be open during combat.")
    end
end

-- Skip cutscenes
local watchedMovies = {}

local function HandleCinematic()
    if not WaffleOptionsDB.skipCutscenes then return end
    if WaffleOptionsDB.skipCutscenesOnlyWatched then
        -- For in-engine cinematics, no movie ID is available; skip if seen this session
        if not watchedMovies["cinematic"] then
            watchedMovies["cinematic"] = true
            return
        end
    end
    CinematicFrame_CancelCinematic()
end

local function HandleMovie(movieID)
    if not WaffleOptionsDB.skipCutscenes then return end
    if WaffleOptionsDB.skipCutscenesOnlyWatched then
        if not C_MovieInfo.GetMovieSeen(movieID) then
            return
        end
    end
    GameMovieFinished()
end

-- Hide Talking Head
local function HandleTalkingHead()
    if not WaffleOptionsDB.hideTalkingHead then return end
    if TalkingHeadFrame and TalkingHeadFrame:IsShown() then
        TalkingHeadFrame:Hide()
    end
end

-- Dungeon: M+ key reminder on group join
local function HandleGroupJoined()
    if not WaffleOptionsDB.dungeonKeyReminder then return end
    C_Timer.After(1, function()
        local activeEntry = C_LFGList.GetActiveEntryInfo()
        if activeEntry then
            local activityInfo = C_LFGList.GetActivityInfoTable(activeEntry.activityID)
            if activityInfo and activityInfo.isMythicPlusActivity then
                local mapName = activityInfo.fullName or activityInfo.shortName or "Unknown Dungeon"
                print("|cff88cc88[WaffleOptions]|r Group key: " .. mapName)
                return
            end
        end
        -- Try search result info if we applied to a group
        local apps = C_LFGList.GetApplications()
        if apps then
            for _, resultID in ipairs(apps) do
                local result = C_LFGList.GetSearchResultInfo(resultID)
                if result and result.activityID then
                    local activityInfo = C_LFGList.GetActivityInfoTable(result.activityID)
                    if activityInfo and activityInfo.isMythicPlusActivity then
                        local mapName = activityInfo.fullName or activityInfo.shortName or "Unknown Dungeon"
                        print("|cff88cc88[WaffleOptions]|r Group key: " .. mapName)
                        return
                    end
                end
            end
        end
    end)
end

-- Dungeon: Auto-insert keystone (hook the keystone frame when it loads)
local keystoneHooked = false
local function SetupKeystoneAutoInsert()
    if keystoneHooked then return end
    if ChallengeKeystoneFrame then
        keystoneHooked = true
        ChallengeKeystoneFrame:HookScript("OnShow", function()
            if not WaffleOptionsDB.dungeonAutoInsertKey then return end
            C_Timer.After(0.3, function()
                C_ChallengeMode.SlotKeystone()
            end)
        end)
    end
end

-- Dungeon: End of dungeon message
local function SendDungeonGG()
    if not WaffleOptionsDB.dungeonAutoGG then return end
    local channel = GetGroupChatChannel()
    if not channel then return end
    local msg = WaffleOptionsDB.dungeonGGMessage or "gg"
    local delay = tonumber(WaffleOptionsDB.dungeonGGDelay) or 0
    C_Timer.After(delay, function()
        if IsInGroup() then
            SendChatMessage(msg, channel)
        end
    end)
end

-- Keystone change tracking
local trackedKeyLevel = nil
local trackedKeyMapID = nil
local keystoneWatchActive = false

local function GetKeystoneInfo()
    local level = C_MythicPlus.GetOwnedKeystoneLevel()
    local mapID = C_MythicPlus.GetOwnedKeystoneChallengeMapID()
    return level, mapID
end

local function StartKeystoneWatch()
    if keystoneWatchActive then return end
    keystoneWatchActive = true
    trackedKeyLevel, trackedKeyMapID = GetKeystoneInfo()
end

local function StopKeystoneWatch()
    keystoneWatchActive = false
end

local function CheckKeystoneChanged()
    if not keystoneWatchActive then return end
    if not WaffleOptionsDB.dungeonKeyChangeAlert then return end
    local newLevel, newMapID = GetKeystoneInfo()
    if not newLevel or not newMapID then return end
    if (newLevel ~= trackedKeyLevel) or (newMapID ~= trackedKeyMapID) then
        local mapName = C_ChallengeMode.GetMapUIInfo(newMapID)
        print("|cff88cc88[WaffleOptions]|r Keystone changed: " .. (mapName or "?") .. " +" .. newLevel)
        trackedKeyLevel = newLevel
        trackedKeyMapID = newMapID
    end
end

-- Auto-leave instance timer
local leaveTimer = nil

local function CancelAutoLeave()
    if leaveTimer then
        leaveTimer:Cancel()
        leaveTimer = nil
        print("|cff88cc88[WaffleOptions]|r Auto-leave cancelled.")
    end
end

local function StartAutoLeave()
    if not WaffleOptionsDB.autoLeaveEnabled then return end
    if leaveTimer then return end
    local delay = tonumber(WaffleOptionsDB.autoLeaveDelay) or 15
    print("|cff88cc88[WaffleOptions]|r Leaving group in " .. delay .. " seconds. Type /wafflecancel to cancel.")
    leaveTimer = C_Timer.NewTimer(delay, function()
        leaveTimer = nil
        pcall(LeaveParty)
        print("|cff88cc88[WaffleOptions]|r Left group automatically.")
    end)
end

local function HandleMythicPlusComplete()
    if WaffleOptionsDB.dungeonGGMythicPlus then
        SendDungeonGG()
    end
    -- Key swap reminder
    if WaffleOptionsDB.dungeonKeySwapReminder then
        C_Timer.After(3, function()
            if IsInGroup() then
                print("|cff88cc88[WaffleOptions]|r Don't forget to trade keys with your group before leaving!")
            end
        end)
    end
    -- Start watching for keystone changes (key trades)
    if WaffleOptionsDB.dungeonKeyChangeAlert then
        C_Timer.After(2.5, function()
            StartKeystoneWatch()
        end)
    end
    -- Key result
    if WaffleOptionsDB.dungeonKeyResult then
        C_Timer.After(2, function()
            local keyLevel = C_MythicPlus.GetOwnedKeystoneLevel()
            local mapID = C_MythicPlus.GetOwnedKeystoneChallengeMapID()
            if keyLevel and mapID then
                local mapName = C_ChallengeMode.GetMapUIInfo(mapID)
                local _, _, _, onTime = C_ChallengeMode.GetCompletionInfo()
                if onTime then
                    SendToChannel(WaffleOptionsDB.dungeonKeyResultChannel,
                        "|cff88cc88[WaffleOptions]|r Key upgraded! New key: " .. (mapName or "?") .. " +" .. keyLevel)
                else
                    SendToChannel(WaffleOptionsDB.dungeonKeyResultChannel,
                        "|cffff4444[WaffleOptions]|r Key depleted. New key: " .. (mapName or "?") .. " +" .. keyLevel)
                    if WaffleOptionsDB.dungeonKeyResultSound then
                        PlaySound(WaffleOptionsDB.dungeonKeyResultSoundID or SOUNDKIT.LFG_DENIED or 11466, "Master")
                    end
                end
            end
        end)
    end
    -- Auto-leave
    if WaffleOptionsDB.autoLeaveMythicPlus then
        StartAutoLeave()
    end
end

local function HandleDungeonComplete()
    if WaffleOptionsDB.dungeonGGRegular then
        SendDungeonGG()
    end
    -- Auto-leave
    if WaffleOptionsDB.autoLeaveRegular then
        StartAutoLeave()
    end
end

local function HandleEncounterEnd(encounterID, encounterName, difficultyID, groupSize, success)
    if success ~= 1 then return end
    -- GG message for raid bosses
    local _, instanceType = GetInstanceInfo()
    if WaffleOptionsDB.dungeonGGRaidBoss and instanceType == "raid" then
        SendDungeonGG()
    end
    -- Auto-screenshot on boss kill
    if WaffleOptionsDB.autoScreenshotEnabled and WaffleOptionsDB.autoScreenshotBossKill then
        local delay = tonumber(WaffleOptionsDB.autoScreenshotDelay) or 1
        C_Timer.After(delay, function()
            Screenshot()
            if WaffleOptionsDB.autoScreenshotChat then
                print("|cff88cc88[WaffleOptions]|r Screenshot saved (Boss: " .. (encounterName or "Unknown") .. ").")
            end
        end)
    end
end

-- Dungeon: Send message to a specific channel
local function SendToChannel(channelSetting, msg)
    if channelSetting == "print" then
        print(msg)
    elseif channelSetting == "emote" then
        -- Strip color codes for emote
        local clean = msg:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""):gsub("|", "")
        SendChatMessage(clean, "EMOTE")
    elseif channelSetting == "group" then
        local channel = GetGroupChatChannel()
        if channel then
            local clean = msg:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""):gsub("|", "")
            SendChatMessage(clean, channel)
        else
            print(msg)
        end
    end
end

-- Dungeon/Raid: Spec/talent reminder
local function IsInMythicDungeon()
    local _, instanceType, difficultyID = GetInstanceInfo()
    if instanceType ~= "party" then return false end
    -- Mythic (M0) = 23, Mythic Keystone (M+) = 8
    return difficultyID == 23 or difficultyID == 8
end

local function IsInRaidInstance()
    local _, instanceType = GetInstanceInfo()
    return instanceType == "raid"
end

local function RunSpecAndTalentCheck()
        -- Spec reminder
        if WaffleOptionsDB.dungeonSpecReminder then
            local specIndex = GetSpecialization()
            if specIndex then
                local _, specName = GetSpecializationInfo(specIndex)
                if specName then
                    local msg = "|cff88cc88[WaffleOptions]|r Current spec: |cffffffff" .. specName .. "|r"
                    -- Show active loadout name
                    if WaffleOptionsDB.dungeonSpecShowLoadout then
                        local specID = GetSpecializationInfo(specIndex)
                        local loadoutName = nil
                        if specID then
                            -- GetActiveConfigID returns the working copy (named after spec)
                            -- GetConfigIDsBySpecID returns saved loadouts with user-given names
                            -- We need to find which saved loadout is currently active
                            local activeConfigID = C_ClassTalents.GetActiveConfigID()
                            local savedIDs = C_ClassTalents.GetConfigIDsBySpecID(specID)
                            if savedIDs then
                                if #savedIDs == 1 then
                                    -- Only one loadout — that's the active one
                                    local ci = C_Traits.GetConfigInfo(savedIDs[1])
                                    if ci and ci.name and ci.name ~= "" then
                                        loadoutName = ci.name
                                    end
                                elseif #savedIDs > 1 and activeConfigID then
                                    -- Multiple loadouts: compare node selections to find which matches
                                    local activeInfo = C_Traits.GetConfigInfo(activeConfigID)
                                    if activeInfo and activeInfo.treeIDs and activeInfo.treeIDs[1] then
                                        local treeID = activeInfo.treeIDs[1]
                                        local activeNodes = C_Traits.GetTreeNodes(treeID)
                                        -- Build a fingerprint of active config's node selections
                                        local activeSelections = {}
                                        if activeNodes then
                                            for _, nodeID in ipairs(activeNodes) do
                                                local nodeInfo = C_Traits.GetNodeInfo(activeConfigID, nodeID)
                                                if nodeInfo and nodeInfo.activeEntry then
                                                    activeSelections[nodeID] = nodeInfo.activeEntry.entryID .. "-" .. nodeInfo.activeEntry.rank
                                                end
                                            end
                                        end
                                        -- Compare each saved config against active
                                        local bestMatch, bestCount = nil, 0
                                        for _, savedID in ipairs(savedIDs) do
                                            local matchCount = 0
                                            local total = 0
                                            for nodeID, activeVal in pairs(activeSelections) do
                                                total = total + 1
                                                local savedNode = C_Traits.GetNodeInfo(savedID, nodeID)
                                                if savedNode and savedNode.activeEntry then
                                                    local savedVal = savedNode.activeEntry.entryID .. "-" .. savedNode.activeEntry.rank
                                                    if savedVal == activeVal then
                                                        matchCount = matchCount + 1
                                                    end
                                                end
                                            end
                                            if matchCount > bestCount then
                                                bestCount = matchCount
                                                bestMatch = savedID
                                            end
                                        end
                                        if bestMatch then
                                            local ci = C_Traits.GetConfigInfo(bestMatch)
                                            if ci and ci.name and ci.name ~= "" then
                                                loadoutName = ci.name
                                            end
                                        end
                                    end
                                end
                            end
                        end
                        if loadoutName then
                            msg = msg .. " - Loadout: |cff00ff00" .. loadoutName .. "|r"
                        end
                    end
                    SendToChannel(WaffleOptionsDB.dungeonSpecReminderChannel, msg)
                end
            end
        end

        -- Unspent talent warning (separate feature)
        if WaffleOptionsDB.dungeonUnspentWarning then
            local configID = C_ClassTalents.GetActiveConfigID()
            if configID then
                local configInfo = C_Traits.GetConfigInfo(configID)
                if configInfo then
                    local totalUnspent = 0
                    for _, treeID in ipairs(configInfo.treeIDs) do
                        local treeCurrencyInfo = C_Traits.GetTreeCurrencyInfo(configID, treeID, false)
                        if treeCurrencyInfo then
                            for _, currency in ipairs(treeCurrencyInfo) do
                                -- Only count currencies where some points have been spent
                                -- (filters out pool caps / sub-currencies with spent=0)
                                if currency.quantity and currency.quantity > 0 and currency.spent and currency.spent > 0 then
                                    totalUnspent = totalUnspent + currency.quantity
                                end
                            end
                        end
                    end
                    if totalUnspent > 0 then
                        SendToChannel(WaffleOptionsDB.dungeonUnspentChannel,
                            "|cffff4444[WaffleOptions] WARNING:|r You have " .. totalUnspent .. " unspent talent point(s)!")
                        if WaffleOptionsDB.dungeonUnspentSound then
                            PlaySound(WaffleOptionsDB.dungeonUnspentSoundID or 11466, "Master")
                        end
                    end
                end
            end
        end

        -- Loot spec warning
        if WaffleOptionsDB.dungeonLootSpecWarning then
            local lootSpecID = GetLootSpecialization()
            if lootSpecID ~= 0 then
                local specIndex = GetSpecialization()
                if specIndex then
                    local currentSpecID = GetSpecializationInfo(specIndex)
                    if currentSpecID and lootSpecID ~= currentSpecID then
                        local _, lootSpecName = GetSpecializationInfoByID(lootSpecID)
                        SendToChannel(WaffleOptionsDB.dungeonLootSpecChannel,
                            "|cffff8800[WaffleOptions]|r Loot spec is set to |cffffffff" ..
                            (lootSpecName or "Unknown") .. "|r (differs from active spec!)")
                        if WaffleOptionsDB.dungeonLootSpecSound then
                            PlaySound(WaffleOptionsDB.dungeonLootSpecSoundID or 15391, "Master")
                        end
                    end
                end
            end
        end
end

local function HandleZoneChanged()
    C_Timer.After(1, function()
        local inDungeon = IsInMythicDungeon()
        local inRaid = IsInRaidInstance()
        if inDungeon and WaffleOptionsDB.dungeonSpecReminderDungeon then
            RunSpecAndTalentCheck()
        elseif inRaid and WaffleOptionsDB.dungeonSpecReminderRaid then
            RunSpecAndTalentCheck()
        end
    end)
end

-- Dungeon: Ready check buff announcements
local CLASS_BUFFS = {
    MAGE    = { spell = 1459,   name = "Arcane Intellect" },
    PRIEST  = { spell = 21562,  name = "Power Word: Fortitude" },
    WARRIOR = { spell = 6673,   name = "Battle Shout" },
    DRUID   = { spell = 1126,   name = "Mark of the Wild" },
    EVOKER  = { spell = 381748, name = "Blessing of the Bronze" },
}

local function UnitHasBuff(unit, spellID)
    for i = 1, 40 do
        local aura = C_UnitAuras.GetBuffDataByIndex(unit, i)
        if not aura then break end
        if aura.spellId == spellID then return true end
    end
    return false
end

local function UnitHasAnyFoodBuff(unit)
    for i = 1, 40 do
        local aura = C_UnitAuras.GetBuffDataByIndex(unit, i)
        if not aura then break end
        if aura.spellId then
            local name = aura.name or ""
            if name == "Well Fed" or name == "Feeling Well Fed" then return true end
        end
    end
    return false
end

local function UnitHasFlaskBuff(unit)
    for i = 1, 40 do
        local aura = C_UnitAuras.GetBuffDataByIndex(unit, i)
        if not aura then break end
        if aura.spellId then
            local name = aura.name or ""
            if name:find("Phial") or name:find("Flask") then return true end
        end
    end
    return false
end

local function GetGroupUnits()
    local units = {}
    local prefix = IsInRaid() and "raid" or "party"
    local count = IsInRaid() and GetNumGroupMembers() or GetNumGroupMembers() - 1
    for i = 1, count do
        local unit = prefix .. i
        if UnitExists(unit) then
            tinsert(units, unit)
        end
    end
    -- In party mode, player is not included in "partyN" units
    if not IsInRaid() then
        tinsert(units, "player")
    end
    return units
end

local function GetPartyClasses()
    local classes = {}
    local units = GetGroupUnits()
    for _, unit in ipairs(units) do
        local _, classToken = UnitClass(unit)
        if classToken then
            classes[classToken] = true
        end
    end
    return classes
end

local function HandleReadyCheck()
    if not WaffleOptionsDB.dungeonReadyCheckBuffs then return end

    -- Check context toggles
    local _, instanceType = GetInstanceInfo()
    if instanceType == "party" and not WaffleOptionsDB.dungeonBuffCheckDungeon then return end
    if instanceType == "raid" and not WaffleOptionsDB.dungeonBuffCheckRaid then return end
    if instanceType == "none" and IsInGroup() and not WaffleOptionsDB.dungeonBuffCheckParty then return end

    local units = GetGroupUnits()
    local partyClasses = GetPartyClasses()
    local output = {}

    for _, unit in ipairs(units) do
        local unitName = UnitName(unit) or unit
        local missing = {}

        -- Check class buffs on this unit
        if WaffleOptionsDB.dungeonBuffCheckClassBuffs then
            for classToken, buffInfo in pairs(CLASS_BUFFS) do
                if partyClasses[classToken] and not UnitHasBuff(unit, buffInfo.spell) then
                    tinsert(missing, buffInfo.name)
                end
            end
        end

        -- Check food
        if WaffleOptionsDB.dungeonBuffCheckFood and not UnitHasAnyFoodBuff(unit) then
            tinsert(missing, "Food (Well Fed)")
        end

        -- Check flask
        if WaffleOptionsDB.dungeonBuffCheckFlask and not UnitHasFlaskBuff(unit) then
            tinsert(missing, "Flask/Phial")
        end

        if #missing > 0 then
            tinsert(output, unitName .. ": " .. table.concat(missing, ", "))
        end
    end

    if #output == 0 then return end

    if WaffleOptionsDB.dungeonBuffCheckMode == "party" then
        local channel = GetGroupChatChannel()
        if channel then
            SendChatMessage("[WaffleOptions] Missing buffs:", channel)
            for _, line in ipairs(output) do
                SendChatMessage("  " .. line, channel)
            end
        end
    else
        print("|cffff8800[WaffleOptions]|r Missing buffs:")
        for _, line in ipairs(output) do
            print("  |cffff8800-|r " .. line)
        end
    end
end

-- Auto-Accept Party Invites
local function IsPlayerFriend(name)
    -- Check character friends
    local numFriends = C_FriendList.GetNumFriends()
    for i = 1, numFriends do
        local info = C_FriendList.GetFriendInfoByIndex(i)
        if info and info.name and Ambiguate(info.name, "none") == Ambiguate(name, "none") then
            return true
        end
    end
    -- Check BNet friends
    local numBNet = BNGetNumFriends()
    for i = 1, numBNet do
        local numAccounts = C_BattleNet.GetFriendNumGameAccounts(i)
        for j = 1, numAccounts do
            local accountInfo = C_BattleNet.GetFriendGameAccountInfo(i, j)
            if accountInfo and accountInfo.characterName then
                if Ambiguate(accountInfo.characterName, "none") == Ambiguate(name, "none") then
                    return true
                end
            end
        end
    end
    return false
end

local function IsPlayerGuildmate(name)
    local numMembers = GetNumGuildMembers()
    for i = 1, numMembers do
        local guildName = GetGuildRosterInfo(i)
        if guildName and Ambiguate(guildName, "none") == Ambiguate(name, "none") then
            return true
        end
    end
    return false
end

local function HandlePartyInvite(inviterName)
    if not WaffleOptionsDB.autoPartyEnabled then return end
    local accepted = false
    if WaffleOptionsDB.autoPartyFriends and IsPlayerFriend(inviterName) then
        accepted = true
    end
    if not accepted and WaffleOptionsDB.autoPartyGuild and IsPlayerGuildmate(inviterName) then
        accepted = true
    end
    if accepted then
        pcall(AcceptGroup)
        StaticPopup_Hide("PARTY_INVITE")
        StaticPopup_Hide("PARTY_INVITE_XREALM")
        print("|cff88cc88[WaffleOptions]|r Auto-accepted party invite from " .. inviterName .. ".")
    end
end

-- Party Greetings
local function SendRandomGreeting(dbKey, replacements)
    local messages = WaffleOptionsDB[dbKey]
    if not messages or #messages == 0 then return end
    local channel = GetGroupChatChannel()
    if not channel then return end
    local msg = messages[math.random(#messages)]
    if replacements then
        for token, value in pairs(replacements) do
            msg = msg:gsub("{" .. token .. "}", value)
        end
    end
    SendChatMessage(msg, channel)
end

local lastRoster = {}

local function GetCurrentRoster()
    local roster = {}
    if not IsInGroup() then return roster end
    local prefix = IsInRaid() and "raid" or "party"
    local count = GetNumGroupMembers()
    if IsInRaid() then
        for i = 1, count do
            local name = UnitName(prefix .. i)
            if name then roster[name] = true end
        end
    else
        for i = 1, count - 1 do
            local name = UnitName(prefix .. i)
            if name then roster[name] = true end
        end
    end
    return roster
end

local function HandleGroupJoinGreeting()
    if not WaffleOptionsDB.partyGreetOnJoin then return end
    C_Timer.After(2, function()
        if IsInGroup() then
            SendRandomGreeting("partyGreetOnJoinMessages")
        end
        lastRoster = GetCurrentRoster()
    end)
end

local function HandleGroupRosterUpdate()
    if not IsInGroup() then
        wipe(lastRoster)
        return
    end
    local newRoster = GetCurrentRoster()
    if WaffleOptionsDB.partyGreetOnMemberJoin and next(lastRoster) then
        -- Find new members
        local newNames = {}
        for name in pairs(newRoster) do
            if not lastRoster[name] and name ~= UnitName("player") then
                tinsert(newNames, name)
            end
        end
        if #newNames > 0 then
            C_Timer.After(1, function()
                if IsInGroup() then
                    local joinedName = newNames[1]
                    SendRandomGreeting("partyGreetOnMemberJoinMessages", { player = joinedName })
                end
            end)
        end
    end
    lastRoster = newRoster
end

-- Auto-Release Spirit
local function HandlePlayerDead()
    if not WaffleOptionsDB.autoReleaseEnabled then return end
    local inInstance = IsInInstance()
    if inInstance then return end
    local delay = tonumber(WaffleOptionsDB.autoReleaseDelay) or 2
    C_Timer.After(delay, function()
        if UnitIsDead("player") and not IsInInstance() then
            pcall(RepopMe)
            print("|cff88cc88[WaffleOptions]|r Auto-released spirit.")
        end
    end)
end

-- Auto-Quest
local function HandleQuestDetail()
    if IsShiftKeyDown() then return end
    if not WaffleOptionsDB.autoQuestAccept then return end
    -- Skip non-repeatable quests if repeatables-only not set (we accept all when enabled)
    pcall(AcceptQuest)
end

local function HandleQuestComplete()
    if IsShiftKeyDown() then return end
    if not WaffleOptionsDB.autoQuestComplete then return end
    -- Don't auto-complete if there are multiple reward choices
    local numChoices = GetNumQuestChoices()
    if numChoices > 1 then return end
    pcall(CompleteQuest)
end

local function HandleQuestProgress()
    if IsShiftKeyDown() then return end
    if not WaffleOptionsDB.autoQuestComplete then return end
    if IsQuestCompletable() then
        pcall(CompleteQuest)
    end
end

-- Gossip Skip
local function HandleGossipShow()
    if IsShiftKeyDown() then return end
    if not WaffleOptionsDB.autoGossipSkip then return end
    local options = C_GossipInfo.GetOptions()
    if options and #options == 1 then
        C_GossipInfo.SelectOption(options[1].gossipOptionID)
    end
end

-- Achievement Congratulations
local achieveGratsCooldown = {}

local function HandleChatMsgAchievement(_, playerName)
    if not playerName then return end
    -- Strip realm name for display
    local shortName = Ambiguate(playerName, "none")
    -- Don't congratulate yourself
    if shortName == UnitName("player") then return end

    -- Check if player is in our party/raid
    local inParty = false
    if IsInGroup() then
        local prefix = IsInRaid() and "raid" or "party"
        local count = IsInRaid() and GetNumGroupMembers() or (GetNumGroupMembers() - 1)
        for i = 1, count do
            local unitName = UnitName(prefix .. i)
            if unitName and Ambiguate(unitName, "none") == shortName then
                inParty = true
                break
            end
        end
    end

    -- Check if player is in our guild
    local inGuild = false
    if IsInGuild() then
        local numMembers = GetNumGuildMembers()
        for i = 1, numMembers do
            local guildName = GetGuildRosterInfo(i)
            if guildName and Ambiguate(guildName, "none") == shortName then
                inGuild = true
                break
            end
        end
    end

    -- Determine where to send (guild takes priority to reduce spam)
    local channel = nil
    if inGuild and WaffleOptionsDB.achieveGratsGuild then
        channel = "GUILD"
    elseif inParty and WaffleOptionsDB.achieveGratsParty and not (inGuild and WaffleOptionsDB.achieveGratsGuild) then
        local groupChannel = GetGroupChatChannel()
        if groupChannel then channel = groupChannel end
    end

    if not channel then return end

    -- Cooldown: don't spam if multiple achievements come in quick succession
    local now = GetTime()
    if achieveGratsCooldown[shortName] and (now - achieveGratsCooldown[shortName]) < 10 then return end
    achieveGratsCooldown[shortName] = now

    local messages = WaffleOptionsDB.achieveGratsMessages
    if not messages or #messages == 0 then return end
    local msg = messages[math.random(#messages)]
    msg = msg:gsub("{player}", shortName)
    C_Timer.After(1 + math.random() * 2, function()
        SendChatMessage(msg, channel)
    end)
end

-- Auto-Screenshot
local function HandleAchievementEarned(achievementID)
    if not WaffleOptionsDB.autoScreenshotEnabled then return end
    if not WaffleOptionsDB.autoScreenshotAchievement then return end
    local _, name = GetAchievementInfo(achievementID)
    local delay = tonumber(WaffleOptionsDB.autoScreenshotDelay) or 1
    C_Timer.After(delay, function()
        Screenshot()
        if WaffleOptionsDB.autoScreenshotChat then
            print("|cff88cc88[WaffleOptions]|r Screenshot saved (Achievement: " .. (name or "Unknown") .. ").")
        end
    end)
end

local function HandleLevelUp(newLevel)
    if not WaffleOptionsDB.autoScreenshotEnabled then return end
    if not WaffleOptionsDB.autoScreenshotLevelUp then return end
    local delay = tonumber(WaffleOptionsDB.autoScreenshotDelay) or 1
    C_Timer.After(delay, function()
        Screenshot()
        if WaffleOptionsDB.autoScreenshotChat then
            print("|cff88cc88[WaffleOptions]|r Screenshot saved (Level " .. newLevel .. ").")
        end
    end)
end

-- Auto-Confirm Loot Rolls
local function HandleConfirmLootRoll(rollID, rollType)
    if not WaffleOptionsDB.autoConfirmLoot then return end
    pcall(ConfirmLootRoll, rollID, rollType)
    StaticPopup_Hide("CONFIRM_LOOT_ROLL")
end

local function HandleLootBindConfirm(lootSlot)
    if not WaffleOptionsDB.autoConfirmLoot then return end
    pcall(ConfirmLootSlot, lootSlot)
    StaticPopup_Hide("LOOT_BIND_CONFIRM")
end

-- Auto-Fill Delete Text (hook popup OnShow)
local function SetupAutoFillDelete()
    local popupTypes = { "DELETE_ITEM", "DELETE_GOOD_ITEM", "DELETE_QUEST_ITEM", "DELETE_GOOD_QUEST_ITEM" }
    for _, which in ipairs(popupTypes) do
        local info = StaticPopupDialogs[which]
        if info then
            local origOnShow = info.OnShow
            info.OnShow = function(self, ...)
                if origOnShow then origOnShow(self, ...) end
                if WaffleOptionsDB.autoFillDelete and self.EditBox then
                    self.EditBox:SetText(DELETE_ITEM_CONFIRM_STRING or "DELETE")
                end
            end
        end
    end
end

-- Auto Role Check
local function HandleRoleCheckShow()
    if not WaffleOptionsDB.autoRoleCheck then return end
    pcall(CompleteLFGRoleCheck, true)
end

-- Combat Res Tracker
local COMBAT_RES_SPELLS = {
    [20484]  = "Rebirth",           -- Druid
    [20707]  = "Soulstone",         -- Warlock
    [61999]  = "Raise Ally",        -- Death Knight
    [391054] = "Intercession",      -- Paladin
}

-- Interrupt Announcements
local INTERRUPT_SPELLS = {
    [1766]   = "Kick",              -- Rogue
    [6552]   = "Pummel",            -- Warrior
    [183752] = "Disrupt",           -- Demon Hunter
    [47528]  = "Mind Freeze",       -- Death Knight
    [116705] = "Spear Hand Strike", -- Monk
    [96231]  = "Rebuke",            -- Paladin
    [57994]  = "Wind Shear",        -- Shaman
    [2139]   = "Counterspell",      -- Mage
    [19647]  = "Spell Lock",        -- Warlock (pet)
    [351338] = "Quell",             -- Evoker
    [93321]  = "Skull Bash",        -- Druid (Feral/Guardian)
    [106839] = "Skull Bash",        -- Druid (alt ID)
    [187707] = "Muzzle",           -- Hunter
}

-- Group utility announcements (mage table, warlock summon, feasts)
local MAGE_TABLE_SPELL = 190336   -- Conjure Refreshment Table
local WARLOCK_SUMMON_SPELL = 698  -- Ritual of Summoning

local FEAST_SPELLS = {
    -- The War Within
    [462704] = true, -- Feast of the Midnight Masquerade
    [462694] = true, -- Feast of the Divine Day
    [461858] = true, -- Bountiful Delicacy Platter
    [461874] = true, -- Everything Stew Surprise
    [461880] = true, -- Outsider's Grand Banquet
    -- Dragonflight
    [382423] = true, -- Grand Banquet of the Kaja'mite
    [383063] = true, -- Yusa's Hearty Stew
    [382427] = true, -- Hoard of Draconic Delicacies
    -- Shadowlands
    [307157] = true, -- Feast of Gluttonous Hedonism
    [308458] = true, -- Surprisingly Palatable Feast
    [359336] = true, -- Empty Kettle of Stone Soup
}

local function HandleSpellcastSucceeded(unit, _, spellID)
    -- Interrupt announcements (player only)
    if (unit == "player" or unit == "pet") and WaffleOptionsDB.dungeonInterruptAnnounce then
        local interruptName = INTERRUPT_SPELLS[spellID]
        if interruptName then
            local msg = (WaffleOptionsDB.dungeonInterruptMsg or "Interrupted with {spell}!"):gsub("{spell}", interruptName)
            C_Timer.After(0, function()
                SendToChannel(WaffleOptionsDB.dungeonInterruptChannel, "|cff88cc88[WaffleOptions]|r " .. msg)
            end)
        end
    end

    -- Group utility announcements and combat res tracker require being in a group
    if not IsInGroup() then return end
    if not UnitIsPlayer(unit) then return end

    local unitName = UnitName(unit)

    -- Combat res tracker
    if WaffleOptionsDB.dungeonCombatResTracker and COMBAT_RES_SPELLS[spellID] then
        local resName = COMBAT_RES_SPELLS[spellID]
        C_Timer.After(0, function()
            SendToChannel(WaffleOptionsDB.dungeonCombatResChannel,
                "|cff88cc88[WaffleOptions]|r " .. unitName .. " used " .. resName .. "!")
        end)
    end

    -- Group utility announcements
    local msg
    if spellID == MAGE_TABLE_SPELL and WaffleOptionsDB.dungeonAnnounceMageTable then
        msg = unitName .. " placed a Mage Table!"
    elseif spellID == WARLOCK_SUMMON_SPELL and WaffleOptionsDB.dungeonAnnounceWarlock then
        msg = unitName .. " placed a Summoning Stone!"
    elseif FEAST_SPELLS[spellID] and WaffleOptionsDB.dungeonAnnounceFeast then
        msg = unitName .. " placed a feast!"
    end

    if msg then
        C_Timer.After(0, function()
            SendToChannel(WaffleOptionsDB.dungeonAnnounceChannel, "|cff88cc88[WaffleOptions]|r " .. msg)
        end)
    end
end

-- Event handling
local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("MERCHANT_SHOW")
frame:RegisterEvent("MAIL_SHOW")
frame:RegisterEvent("MAIL_CLOSED")
frame:RegisterEvent("MAIL_INBOX_UPDATE")
frame:RegisterEvent("CONFIRM_SUMMON")
frame:RegisterEvent("RESURRECT_REQUEST")
frame:RegisterEvent("PLAYER_REGEN_DISABLED")
frame:RegisterEvent("CINEMATIC_START")
frame:RegisterEvent("PLAY_MOVIE")
frame:RegisterEvent("TALKINGHEAD_REQUESTED")
frame:RegisterEvent("GROUP_JOINED")
frame:RegisterEvent("GROUP_ROSTER_UPDATE")
frame:RegisterEvent("BAG_UPDATE")
frame:RegisterEvent("CHALLENGE_MODE_COMPLETED")
frame:RegisterEvent("LFG_COMPLETION_REWARD")
frame:RegisterEvent("ENCOUNTER_END")
frame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
frame:RegisterEvent("READY_CHECK")
frame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
frame:RegisterEvent("PARTY_INVITE_REQUEST")
frame:RegisterEvent("PLAYER_DEAD")
frame:RegisterEvent("QUEST_DETAIL")
frame:RegisterEvent("QUEST_COMPLETE")
frame:RegisterEvent("QUEST_PROGRESS")
frame:RegisterEvent("GOSSIP_SHOW")
frame:RegisterEvent("ACHIEVEMENT_EARNED")
frame:RegisterEvent("CHAT_MSG_ACHIEVEMENT")
frame:RegisterEvent("CHAT_MSG_GUILD_ACHIEVEMENT")
frame:RegisterEvent("PLAYER_LEVEL_UP")
frame:RegisterEvent("CONFIRM_LOOT_ROLL")
frame:RegisterEvent("LOOT_BIND_CONFIRM")
frame:RegisterEvent("LFG_ROLE_CHECK_SHOW")
frame:SetScript("OnEvent", function(self, event, ...)
    local arg1, arg2, arg3, arg4, arg5 = ...
    if event == "ADDON_LOADED" then
        if arg1 == addonName then
            InitDB()
            SetupKeystoneAutoInsert()
            SetupAutoFillDelete()
            if WaffleOptionsDB.showLoginMessage then
                print("|cff88cc88[WaffleOptions]|r Loaded. Type /waffle for options.")
            end
        end
        -- Try hooking keystone frame whenever any addon loads (it's load-on-demand)
        SetupKeystoneAutoInsert()
    elseif event == "MERCHANT_SHOW" then
        AutoSellGrayItems()
        AutoRepair()
    elseif event == "MAIL_SHOW" then
        StartMailCollection()
    elseif event == "MAIL_CLOSED" then
        StopMailCollection()
        mailWaitingForData = false
    elseif event == "MAIL_INBOX_UPDATE" then
        HandleMailInboxUpdate()
    elseif event == "CONFIRM_SUMMON" then
        HandleSummon()
    elseif event == "RESURRECT_REQUEST" then
        HandleResurrect(arg1)
    elseif event == "PLAYER_REGEN_DISABLED" then
        HandleCombatStart()
    elseif event == "CINEMATIC_START" then
        HandleCinematic()
    elseif event == "PLAY_MOVIE" then
        HandleMovie(arg1)
    elseif event == "TALKINGHEAD_REQUESTED" then
        HandleTalkingHead()
    elseif event == "GROUP_JOINED" then
        HandleGroupJoined()
        HandleGroupJoinGreeting()
    elseif event == "GROUP_ROSTER_UPDATE" then
        HandleGroupRosterUpdate()
        if not IsInGroup() then StopKeystoneWatch() end
    elseif event == "BAG_UPDATE" then
        CheckKeystoneChanged()
    elseif event == "CHALLENGE_MODE_COMPLETED" then
        HandleMythicPlusComplete()
    elseif event == "LFG_COMPLETION_REWARD" then
        HandleDungeonComplete()
    elseif event == "ENCOUNTER_END" then
        HandleEncounterEnd(arg1, arg2, arg3, arg4, arg5)
    elseif event == "ZONE_CHANGED_NEW_AREA" then
        HandleZoneChanged()
    elseif event == "READY_CHECK" then
        HandleReadyCheck()
    elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
        HandleSpellcastSucceeded(arg1, arg2, arg3)
    elseif event == "PARTY_INVITE_REQUEST" then
        HandlePartyInvite(arg1)
    elseif event == "PLAYER_DEAD" then
        HandlePlayerDead()
    elseif event == "QUEST_DETAIL" then
        HandleQuestDetail()
    elseif event == "QUEST_COMPLETE" then
        HandleQuestComplete()
    elseif event == "QUEST_PROGRESS" then
        HandleQuestProgress()
    elseif event == "GOSSIP_SHOW" then
        HandleGossipShow()
    elseif event == "ACHIEVEMENT_EARNED" then
        HandleAchievementEarned(arg1)
    elseif event == "CHAT_MSG_ACHIEVEMENT" or event == "CHAT_MSG_GUILD_ACHIEVEMENT" then
        HandleChatMsgAchievement(arg1, arg2)
    elseif event == "PLAYER_LEVEL_UP" then
        HandleLevelUp(arg1)
    elseif event == "CONFIRM_LOOT_ROLL" then
        HandleConfirmLootRoll(arg1, arg2)
    elseif event == "LOOT_BIND_CONFIRM" then
        HandleLootBindConfirm(arg1)
    elseif event == "LFG_ROLE_CHECK_SHOW" then
        HandleRoleCheckShow()
    end
end)

-- Slash command
SLASH_WAFFLEMATIONS1 = "/waffle"
SlashCmdList["WAFFLEMATIONS"] = function()
    if InCombatLockdown() then
        print("|cff88cc88[WaffleOptions]|r Options panel cannot be opened during combat.")
        return
    end
    if WaffleOptions.ToggleOptions then
        WaffleOptions.ToggleOptions()
    end
end

-- Cancel auto-leave command
SLASH_WAFFLECANCEL1 = "/wafflecancel"
SlashCmdList["WAFFLECANCEL"] = function()
    CancelAutoLeave()
end

-- Test command: triggers dungeon checks regardless of location
SLASH_WAFFLETEST1 = "/waffletest"
SlashCmdList["WAFFLETEST"] = function()
    print("|cff88cc88[WaffleOptions]|r Running dungeon checks (test mode)...")
    RunSpecAndTalentCheck()
end

