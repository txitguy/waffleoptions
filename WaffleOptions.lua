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
    skipCutscenes = false,
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
    dungeonSpecReminderChannel = "print",
    dungeonSpecReminderDungeon = true,
    dungeonSpecReminderRaid = true,
    dungeonUnspentWarning = true,
    dungeonUnspentChannel = "print",
    dungeonUnspentSound = true,
    dungeonUnspentSoundID = 11466, -- "You are not prepared"
    dungeonReadyCheckBuffs = true,
    dungeonBuffCheckMode = "personal",
    dungeonBuffCheckClassBuffs = true,
    dungeonBuffCheckFood = true,
    dungeonBuffCheckFlask = true,
    dungeonAnnounceMageTable = true,
    dungeonAnnounceWarlock = true,
    dungeonAnnounceFeast = true,
    dungeonAnnounceChannel = "group",
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
                C_Timer.After(0.15, CollectNextMail)
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

local function StartMailCollection()
    if not WaffleOptionsDB.autoMailEnabled then return end
    if mail.processing then return end

    local numItems = GetInboxNumItems()
    if numItems == 0 then return end

    mail.processing = true
    mail.index = numItems
    mail.totalMoney = 0
    mail.itemsCollected = 0

    C_Timer.After(0.5, CollectNextMail)
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
        WorldMapFrame:Hide()
    end
    if WaffleOptionsDB.combatHideBags then
        CloseAllBags()
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

local function HandleMythicPlusComplete()
    if WaffleOptionsDB.dungeonGGMythicPlus then
        SendDungeonGG()
    end
end

local function HandleDungeonComplete()
    if WaffleOptionsDB.dungeonGGRegular then
        SendDungeonGG()
    end
end

local function HandleEncounterEnd(encounterID, encounterName, difficultyID, groupSize, success)
    if success ~= 1 then return end
    if not WaffleOptionsDB.dungeonGGRaidBoss then return end
    -- Only trigger in raid instances
    local _, instanceType = GetInstanceInfo()
    if instanceType ~= "raid" then return end
    SendDungeonGG()
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

local function PlayerHasBuff(spellID)
    for i = 1, 40 do
        local aura = C_UnitAuras.GetBuffDataByIndex("player", i)
        if not aura then break end
        if aura.spellId == spellID then return true end
    end
    return false
end

local function PlayerHasAnyFoodBuff()
    for i = 1, 40 do
        local aura = C_UnitAuras.GetBuffDataByIndex("player", i)
        if not aura then break end
        -- "Well Fed" and food buffs are generally in the "Food & Drink" category
        if aura.spellId then
            local name = aura.name or ""
            if name == "Well Fed" or name == "Feeling Well Fed" then return true end
        end
    end
    return false
end

local function PlayerHasFlaskBuff()
    for i = 1, 40 do
        local aura = C_UnitAuras.GetBuffDataByIndex("player", i)
        if not aura then break end
        if aura.spellId then
            local name = aura.name or ""
            -- Phials and flasks typically contain these words
            if name:find("Phial") or name:find("Flask") then return true end
        end
    end
    return false
end

local function GetPartyClasses()
    local classes = {}
    local prefix = IsInRaid() and "raid" or "party"
    local count = IsInRaid() and GetNumGroupMembers() or GetNumGroupMembers() - 1
    for i = 1, count do
        local unit = prefix .. i
        if UnitExists(unit) then
            local _, classToken = UnitClass(unit)
            if classToken then
                classes[classToken] = true
            end
        end
    end
    -- Include player
    local _, playerClass = UnitClass("player")
    if playerClass then classes[playerClass] = true end
    return classes
end

local function HandleReadyCheck()
    if not WaffleOptionsDB.dungeonReadyCheckBuffs then return end

    local missing = {}
    local partyClasses = GetPartyClasses()

    -- Check class buffs
    if WaffleOptionsDB.dungeonBuffCheckClassBuffs then
        for classToken, buffInfo in pairs(CLASS_BUFFS) do
            if partyClasses[classToken] and not PlayerHasBuff(buffInfo.spell) then
                tinsert(missing, buffInfo.name)
            end
        end
    end

    -- Check food
    if WaffleOptionsDB.dungeonBuffCheckFood and not PlayerHasAnyFoodBuff() then
        tinsert(missing, "Food (Well Fed)")
    end

    -- Check flask
    if WaffleOptionsDB.dungeonBuffCheckFlask and not PlayerHasFlaskBuff() then
        tinsert(missing, "Flask/Phial")
    end

    if #missing == 0 then return end

    local msg = "Missing buffs: " .. table.concat(missing, ", ")

    if WaffleOptionsDB.dungeonBuffCheckMode == "party" then
        local channel = GetGroupChatChannel()
        if channel then
            SendChatMessage("[WaffleOptions] " .. msg, channel)
        end
    else
        print("|cffff8800[WaffleOptions]|r " .. msg)
    end
end

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

local function HandleGroupUtilitySpellcast(unit, _, spellID)
    if not IsInGroup() then return end
    if not UnitIsPlayer(unit) then return end

    local msg
    local unitName = UnitName(unit)

    if spellID == MAGE_TABLE_SPELL and WaffleOptionsDB.dungeonAnnounceMageTable then
        msg = unitName .. " placed a Mage Table!"
    elseif spellID == WARLOCK_SUMMON_SPELL and WaffleOptionsDB.dungeonAnnounceWarlock then
        msg = unitName .. " placed a Summoning Stone!"
    elseif FEAST_SPELLS[spellID] and WaffleOptionsDB.dungeonAnnounceFeast then
        msg = unitName .. " placed a feast!"
    end

    if msg then
        SendToChannel(WaffleOptionsDB.dungeonAnnounceChannel, "|cff88cc88[WaffleOptions]|r " .. msg)
    end
end

-- Event handling
local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("MERCHANT_SHOW")
frame:RegisterEvent("MAIL_SHOW")
frame:RegisterEvent("MAIL_CLOSED")
frame:RegisterEvent("CONFIRM_SUMMON")
frame:RegisterEvent("RESURRECT_REQUEST")
frame:RegisterEvent("PLAYER_REGEN_DISABLED")
frame:RegisterEvent("CINEMATIC_START")
frame:RegisterEvent("PLAY_MOVIE")
frame:RegisterEvent("TALKINGHEAD_REQUESTED")
frame:RegisterEvent("GROUP_JOINED")
frame:RegisterEvent("CHALLENGE_MODE_COMPLETED")
frame:RegisterEvent("LFG_COMPLETION_REWARD")
frame:RegisterEvent("ENCOUNTER_END")
frame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
frame:RegisterEvent("READY_CHECK")
frame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
frame:SetScript("OnEvent", function(self, event, ...)
    local arg1, arg2, arg3, arg4, arg5 = ...
    if event == "ADDON_LOADED" then
        if arg1 == addonName then
            InitDB()
            SetupKeystoneAutoInsert()
            print("|cff88cc88[WaffleOptions]|r Loaded. Type /waffle for options.")
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
        HandleGroupUtilitySpellcast(arg1, arg2, arg3)
    end
end)

-- Slash command
SLASH_WAFFLEMATIONS1 = "/waffle"
SlashCmdList["WAFFLEMATIONS"] = function()
    if WaffleOptions.ToggleOptions then
        WaffleOptions.ToggleOptions()
    end
end

-- Test command: triggers dungeon checks regardless of location
SLASH_WAFFLETEST1 = "/waffletest"
SlashCmdList["WAFFLETEST"] = function()
    print("|cff88cc88[WaffleOptions]|r Running dungeon checks (test mode)...")
    RunSpecAndTalentCheck()
end
