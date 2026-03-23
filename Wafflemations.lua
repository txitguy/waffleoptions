local addonName = ...

-- Global addon table
Wafflemations = {}

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
}

Wafflemations.defaults = defaults

-- Initialize saved variables with defaults (called immediately so Options.lua can read DB)
local function InitDB()
    if not WafflemationsDB then
        WafflemationsDB = {}
    end
    for k, v in pairs(defaults) do
        if WafflemationsDB[k] == nil then
            WafflemationsDB[k] = v
        end
    end
end
InitDB()

-- Auto-sell gray items
local function AutoSellGrayItems()
    if not WafflemationsDB.autoSellEnabled then return end

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

    if totalSellPrice > 0 and WafflemationsDB.autoSellChat then
        print("|cff88cc88[Wafflemations]|r Sold all gray items for " .. GetCoinTextureString(totalSellPrice) .. ".")
    end
end

-- Auto-repair gear
local function AutoRepair()
    if not WafflemationsDB.autoRepairEnabled then return end
    if not CanMerchantRepair() then return end

    local repairCost, canRepair = GetRepairAllCost()
    if not canRepair or repairCost <= 0 then return end

    local useGuild = false

    if WafflemationsDB.autoRepairMode == "guild_first" then
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

    if WafflemationsDB.autoRepairChat then
        local source = useGuild and "Guild" or "Personal"
        print("|cff88cc88[Wafflemations]|r " .. source .. " repair cost: " .. GetCoinTextureString(repairCost) .. ".")
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

    if WafflemationsDB.autoMailChat and mail.totalMoney > 0 then
        print("|cff88cc88[Wafflemations]|r Collected " .. GetCoinTextureString(mail.totalMoney) .. " from mail.")
    end
    if WafflemationsDB.autoMailChat and mail.itemsCollected > 0 then
        print("|cff88cc88[Wafflemations]|r Collected items from " .. mail.itemsCollected .. " mail(s).")
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
    if WafflemationsDB.autoMailDeleteEmpty then
        mail.index = GetInboxNumItems()
        C_Timer.After(0.5, DeleteNextEmptyMail)
    else
        FinishMailProcessing()
    end
end

local function StartMailCollection()
    if not WafflemationsDB.autoMailEnabled then return end
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
    if groupType == "party" then return WafflemationsDB.autoSummonChatParty end
    if groupType == "raid" then return WafflemationsDB.autoSummonChatRaid end
    if groupType == "instance" then return WafflemationsDB.autoSummonChatInstance end
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
    if not WafflemationsDB.autoSummonEnabled and WafflemationsDB.autoSummonChatOnReceive and chatEnabled then
        local msg = FormatSummonMsg(WafflemationsDB.autoSummonReceiveMsg, summoner, location)
        SendChatMessage(msg, channel)
    end

    -- Auto-accept
    if WafflemationsDB.autoSummonEnabled then
        C_SummonInfo.ConfirmSummon()
        print("|cff88cc88[Wafflemations]|r Auto-accepted summon to " .. location .. " from " .. summoner .. ".")

        -- Chat on accept
        if WafflemationsDB.autoSummonChatOnAccept and chatEnabled then
            local msg = FormatSummonMsg(WafflemationsDB.autoSummonAcceptMsg, summoner, location)
            SendChatMessage(msg, channel)
        end
    end
end

-- Auto-resurrect
local function IsResChatEnabledForGroup(groupType)
    if groupType == "party" then return WafflemationsDB.autoResChatParty end
    if groupType == "raid" then return WafflemationsDB.autoResChatRaid end
    if groupType == "instance" then return WafflemationsDB.autoResChatInstance end
    return false
end

local function HandleResurrect(casterName)
    local inCombat = UnitAffectingCombat("player")

    if inCombat and not WafflemationsDB.autoResCombatEnabled then return end
    if not inCombat and not WafflemationsDB.autoResOOCEnabled then return end

    local caster = casterName or "someone"

    AcceptResurrect()
    StaticPopup_Hide("RESURRECT_NO_TIMER")
    StaticPopup_Hide("RESURRECT_NO_SICKNESS")
    StaticPopup_Hide("RESURRECT")

    print("|cff88cc88[Wafflemations]|r Auto-accepted " .. (inCombat and "combat " or "") .. "resurrection from " .. caster .. ".")

    -- Chat announce
    if WafflemationsDB.autoResChatOnAccept then
        local channel, groupType = GetGroupChatChannel()
        if channel and groupType and IsResChatEnabledForGroup(groupType) then
            local msg = WafflemationsDB.autoResAcceptMsg:gsub("{caster}", caster)
            SendChatMessage(msg, channel)
        end
    end
end

-- Combat auto-hide
local function HandleCombatStart()
    if WafflemationsDB.combatHideMap and WorldMapFrame and WorldMapFrame:IsShown() then
        WorldMapFrame:Hide()
    end
    if WafflemationsDB.combatHideBags then
        CloseAllBags()
    end
end

-- Skip cutscenes
local watchedMovies = {}

local function HandleCinematic()
    if not WafflemationsDB.skipCutscenes then return end
    if WafflemationsDB.skipCutscenesOnlyWatched then
        -- For in-engine cinematics, no movie ID is available; skip if seen this session
        if not watchedMovies["cinematic"] then
            watchedMovies["cinematic"] = true
            return
        end
    end
    CinematicFrame_CancelCinematic()
end

local function HandleMovie(movieID)
    if not WafflemationsDB.skipCutscenes then return end
    if WafflemationsDB.skipCutscenesOnlyWatched then
        if not C_MovieInfo.GetMovieSeen(movieID) then
            return
        end
    end
    GameMovieFinished()
end

-- Hide Talking Head
local function HandleTalkingHead()
    if not WafflemationsDB.hideTalkingHead then return end
    if TalkingHeadFrame and TalkingHeadFrame:IsShown() then
        TalkingHeadFrame:Hide()
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
frame:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == addonName then
        InitDB()
        print("|cff88cc88[Wafflemations]|r Loaded. Type /waffle for options.")
        self:UnregisterEvent("ADDON_LOADED")
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
    end
end)

-- Slash command
SLASH_WAFFLEMATIONS1 = "/waffle"
SlashCmdList["WAFFLEMATIONS"] = function()
    if Wafflemations.ToggleOptions then
        Wafflemations.ToggleOptions()
    end
end
