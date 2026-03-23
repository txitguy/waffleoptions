-- Wafflemations Options Panel (ElvUI-inspired, polished)

-------------------------------------------------
-- Layout Constants
-------------------------------------------------
local PANEL_WIDTH   = 680
local PANEL_HEIGHT  = 520
local SIDEBAR_WIDTH = 160
local TITLE_HEIGHT  = 30

local PAD        = 20   -- standard content padding
local SUB_PAD    = 36   -- indented sub-option padding
local CB_H       = 26   -- checkbox row height
local SEC_GAP    = 16   -- gap between major sections
local HDR_GAP    = 22   -- space consumed by a section header (label + line)
local SUB_GAP    = 20   -- space consumed by a sub-header
local CARD_PAD   = 12   -- inner padding inside group cards
local SIDEBAR_PITCH = 32 -- vertical distance between sidebar buttons

-------------------------------------------------
-- ElvUI-style color palette
-------------------------------------------------
local C = {
    bg          = {0.047, 0.047, 0.047, 0.98},
    bgInner     = {0.065, 0.065, 0.065, 1},
    sidebar     = {0.035, 0.035, 0.035, 1},
    card        = {0.08, 0.08, 0.08, 1},
    border      = {0.14, 0.14, 0.14, 1},
    borderLight = {0.22, 0.22, 0.22, 1},
    accent      = {0.4, 0.78, 0.4, 1},
    accentDim   = {0.3, 0.55, 0.3, 1},
    label       = {0.9, 0.8, 0.5, 1},
    title       = {0.92, 0.92, 0.92, 1},
    text        = {0.78, 0.78, 0.78, 1},
    textBright  = {0.92, 0.92, 0.92, 1},
    textDim     = {0.45, 0.45, 0.45, 1},
    catNormal   = {0.055, 0.055, 0.055, 1},
    catHover    = {0.09, 0.09, 0.09, 1},
    catSelected = {0.075, 0.075, 0.075, 1},
    close       = {0.6, 0.6, 0.6, 1},
    closeHover  = {0.9, 0.25, 0.25, 1},
    disabled    = {0.3, 0.3, 0.3, 1},
    disabledBg  = {0.05, 0.05, 0.05, 1},
}

local BACKDROP = {
    bgFile = "Interface\\BUTTONS\\WHITE8X8",
    edgeFile = "Interface\\BUTTONS\\WHITE8X8",
    edgeSize = 1,
}

-------------------------------------------------
-- Helper: Pixel border
-------------------------------------------------
local function CreatePixelBorder(parent, r, g, b, a)
    local f = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    f:SetPoint("TOPLEFT", -1, 1)
    f:SetPoint("BOTTOMRIGHT", 1, -1)
    f:SetBackdrop({ edgeFile = "Interface\\BUTTONS\\WHITE8X8", edgeSize = 1 })
    f:SetBackdropBorderColor(r or 0, g or 0, b or 0, a or 1)
    f:SetFrameLevel(parent:GetFrameLevel() + 1)
    return f
end

-------------------------------------------------
-- Main Frame
-------------------------------------------------
local optionsFrame = CreateFrame("Frame", "WafflemationsOptionsFrame", UIParent, "BackdropTemplate")
optionsFrame:SetSize(PANEL_WIDTH, PANEL_HEIGHT)
optionsFrame:SetPoint("CENTER")
optionsFrame:SetFrameStrata("DIALOG")
optionsFrame:SetMovable(true)
optionsFrame:EnableMouse(true)
optionsFrame:RegisterForDrag("LeftButton")
optionsFrame:SetScript("OnDragStart", optionsFrame.StartMoving)
optionsFrame:SetScript("OnDragStop", optionsFrame.StopMovingOrSizing)
optionsFrame:SetBackdrop(BACKDROP)
optionsFrame:SetBackdropColor(unpack(C.bg))
optionsFrame:SetBackdropBorderColor(0, 0, 0, 1)
optionsFrame:Hide()
tinsert(UISpecialFrames, "WafflemationsOptionsFrame")

CreatePixelBorder(optionsFrame, unpack(C.border))

-------------------------------------------------
-- Title Bar
-------------------------------------------------
local titleBar = CreateFrame("Frame", nil, optionsFrame, "BackdropTemplate")
titleBar:SetHeight(TITLE_HEIGHT)
titleBar:SetPoint("TOPLEFT", 2, -2)
titleBar:SetPoint("TOPRIGHT", -2, -2)
titleBar:SetBackdrop(BACKDROP)
titleBar:SetBackdropColor(0.055, 0.055, 0.055, 1)
titleBar:SetBackdropBorderColor(unpack(C.border))

local titleText = titleBar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
titleText:SetPoint("LEFT", 12, 0)
titleText:SetText("WAFFLEMATIONS")
titleText:SetTextColor(unpack(C.accent))

local closeBtn = CreateFrame("Button", nil, titleBar, "BackdropTemplate")
closeBtn:SetSize(TITLE_HEIGHT - 8, TITLE_HEIGHT - 8)
closeBtn:SetPoint("RIGHT", -5, 0)
closeBtn:SetBackdrop(BACKDROP)
closeBtn:SetBackdropColor(0.07, 0.07, 0.07, 1)
closeBtn:SetBackdropBorderColor(unpack(C.border))

local closeTxt = closeBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
closeTxt:SetPoint("CENTER", 0, 0)
closeTxt:SetText("x")
closeTxt:SetTextColor(unpack(C.close))

closeBtn:SetScript("OnClick", function() optionsFrame:Hide() end)
closeBtn:SetScript("OnEnter", function(self) closeTxt:SetTextColor(unpack(C.closeHover)); self:SetBackdropBorderColor(unpack(C.closeHover)) end)
closeBtn:SetScript("OnLeave", function(self) closeTxt:SetTextColor(unpack(C.close)); self:SetBackdropBorderColor(unpack(C.border)) end)

-------------------------------------------------
-- Sidebar
-------------------------------------------------
local sidebar = CreateFrame("Frame", nil, optionsFrame, "BackdropTemplate")
sidebar:SetWidth(SIDEBAR_WIDTH)
sidebar:SetPoint("TOPLEFT", 2, -(TITLE_HEIGHT + 4))
sidebar:SetPoint("BOTTOMLEFT", 2, 2)
sidebar:SetBackdrop(BACKDROP)
sidebar:SetBackdropColor(unpack(C.sidebar))
sidebar:SetBackdropBorderColor(unpack(C.border))

-------------------------------------------------
-- Content Area + Scroll
-------------------------------------------------
local contentBg = CreateFrame("Frame", nil, optionsFrame, "BackdropTemplate")
contentBg:SetPoint("TOPLEFT", sidebar, "TOPRIGHT", 2, 0)
contentBg:SetPoint("BOTTOMRIGHT", -2, 2)
contentBg:SetBackdrop(BACKDROP)
contentBg:SetBackdropColor(unpack(C.bgInner))
contentBg:SetBackdropBorderColor(unpack(C.border))

-- Author line pinned at bottom
local authorText = contentBg:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
authorText:SetPoint("BOTTOMRIGHT", -PAD, 8)
authorText:SetText("Created by |cff66cc66Waffle Taco|r")
authorText:SetTextColor(unpack(C.textDim))

-- Scroll frame
local scrollFrame = CreateFrame("ScrollFrame", nil, contentBg)
scrollFrame:SetPoint("TOPLEFT", 1, -1)
scrollFrame:SetPoint("BOTTOMRIGHT", -10, 24)

-- Scrollbar
local scrollBar = CreateFrame("Slider", nil, contentBg, "BackdropTemplate")
scrollBar:SetWidth(5)
scrollBar:SetPoint("TOPRIGHT", -3, -3)
scrollBar:SetPoint("BOTTOMRIGHT", -3, 24)
scrollBar:SetBackdrop(BACKDROP)
scrollBar:SetBackdropColor(0.035, 0.035, 0.035, 1)
scrollBar:SetBackdropBorderColor(unpack(C.border))
scrollBar:SetMinMaxValues(0, 1)
scrollBar:SetValue(0)
scrollBar:SetValueStep(1)
scrollBar:SetObeyStepOnDrag(true)

local scrollThumb = scrollBar:CreateTexture(nil, "OVERLAY")
scrollThumb:SetColorTexture(unpack(C.accentDim))
scrollThumb:SetSize(5, 40)
scrollBar:SetThumbTexture(scrollThumb)

scrollBar:SetScript("OnValueChanged", function(self, val)
    scrollFrame:SetVerticalScroll(val)
end)

local function OnMouseWheel(_, delta)
    local cur = scrollBar:GetValue()
    local lo, hi = scrollBar:GetMinMaxValues()
    scrollBar:SetValue(math.max(lo, math.min(hi, cur - delta * 30)))
end
scrollFrame:SetScript("OnMouseWheel", OnMouseWheel)
contentBg:SetScript("OnMouseWheel", OnMouseWheel)
scrollFrame:EnableMouseWheel(true)

local contentArea = CreateFrame("Frame", nil, scrollFrame)
contentArea:SetWidth(PANEL_WIDTH - SIDEBAR_WIDTH - 18)
scrollFrame:SetScrollChild(contentArea)

local function UpdateScrollRange()
    local ch = contentArea:GetHeight() or 0
    local vh = scrollFrame:GetHeight() or 1
    local maxS = math.max(0, ch - vh)
    scrollBar:SetMinMaxValues(0, maxS)
    scrollBar:SetShown(maxS > 0)
    if scrollBar:GetValue() > maxS then scrollBar:SetValue(maxS) end
    -- Scale thumb
    if ch > 0 and vh > 0 and ch > vh then
        local track = scrollBar:GetHeight() or 1
        local thumb = math.max(20, track * (vh / ch))
        scrollThumb:SetHeight(thumb)
    else
        scrollThumb:SetHeight(40)
    end
end

scrollFrame:SetScript("OnSizeChanged", function(self)
    contentArea:SetWidth(self:GetWidth())
    UpdateScrollRange()
end)

-------------------------------------------------
-- Category System
-------------------------------------------------
local categories = {}
local contentFrames = {}
local selectedCategory = nil
local sidebarDividerY = nil -- set after About button

local function SelectCategory(name)
    if selectedCategory == name then return end
    selectedCategory = name
    for cn, btn in pairs(categories) do
        if cn == name then
            btn.bg:SetColorTexture(unpack(C.catSelected))
            btn.stripe:Show()
            btn.label:SetTextColor(unpack(C.accent))
        else
            btn.bg:SetColorTexture(unpack(C.catNormal))
            btn.stripe:Hide()
            btn.label:SetTextColor(unpack(C.text))
        end
    end
    for cn, f in pairs(contentFrames) do f:SetShown(cn == name) end
    scrollBar:SetValue(0)
end

local function CreateCategoryButton(name, index)
    local btn = CreateFrame("Button", nil, sidebar)
    btn:SetHeight(28)
    btn:SetPoint("TOPLEFT", 5, -6 - (index - 1) * SIDEBAR_PITCH)
    btn:SetPoint("RIGHT", sidebar, "RIGHT", -5, 0)

    local bg = btn:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(unpack(C.catNormal))
    btn.bg = bg

    local stripe = btn:CreateTexture(nil, "ARTWORK")
    stripe:SetWidth(2)
    stripe:SetPoint("TOPLEFT", 0, -1)
    stripe:SetPoint("BOTTOMLEFT", 0, 1)
    stripe:SetColorTexture(unpack(C.accent))
    stripe:Hide()
    btn.stripe = stripe

    local lbl = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    lbl:SetPoint("LEFT", 12, 0)
    lbl:SetText(name)
    lbl:SetTextColor(unpack(C.text))
    btn.label = lbl

    btn:SetScript("OnClick", function() SelectCategory(name) end)
    btn:SetScript("OnEnter", function()
        if selectedCategory ~= name then bg:SetColorTexture(unpack(C.catHover)); lbl:SetTextColor(unpack(C.textBright)) end
    end)
    btn:SetScript("OnLeave", function()
        if selectedCategory ~= name then bg:SetColorTexture(unpack(C.catNormal)); lbl:SetTextColor(unpack(C.text)) end
    end)

    categories[name] = btn
    return btn
end

local function CreateSidebarDivider(afterIndex)
    local y = -6 - afterIndex * SIDEBAR_PITCH + 2
    local line = sidebar:CreateTexture(nil, "ARTWORK")
    line:SetHeight(1)
    line:SetPoint("TOPLEFT", 10, y)
    line:SetPoint("RIGHT", sidebar, "RIGHT", -10, 0)
    line:SetColorTexture(unpack(C.borderLight))
end

local function CreateContentFrame(name, height)
    local f = CreateFrame("Frame", nil, contentArea)
    f:SetPoint("TOPLEFT", 0, 0)
    f:SetPoint("RIGHT", contentArea, "RIGHT", 0, 0)
    f:SetHeight(height or 400)
    f:Hide()
    f:SetScript("OnShow", function(self)
        contentArea:SetHeight(self:GetHeight())
        UpdateScrollRange()
    end)
    contentFrames[name] = f
    return f
end

-------------------------------------------------
-- Helper: Group card
-------------------------------------------------
local function CreateGroupCard(parent, x, y, w, h)
    local card = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    card:SetPoint("TOPLEFT", x, y)
    card:SetSize(w, h)
    card:SetBackdrop(BACKDROP)
    card:SetBackdropColor(unpack(C.card))
    card:SetBackdropBorderColor(unpack(C.border))
    return card
end

-------------------------------------------------
-- Helper: Section header (gold label + divider)
-------------------------------------------------
local function CreateSectionHeader(parent, text, y)
    local lbl = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    lbl:SetPoint("TOPLEFT", PAD, y)
    lbl:SetText(text)
    lbl:SetTextColor(unpack(C.label))

    local line = parent:CreateTexture(nil, "ARTWORK")
    line:SetHeight(1)
    line:SetPoint("TOPLEFT", PAD, y - 16)
    line:SetPoint("RIGHT", -PAD, 0)
    line:SetColorTexture(unpack(C.borderLight))

    return y - HDR_GAP
end

-------------------------------------------------
-- Helper: Sub-header (smaller label + divider)
-------------------------------------------------
local function CreateSubHeader(parent, text, y)
    local lbl = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    lbl:SetPoint("TOPLEFT", PAD, y)
    lbl:SetText(text)
    lbl:SetTextColor(unpack(C.label))

    local line = parent:CreateTexture(nil, "ARTWORK")
    line:SetHeight(1)
    line:SetPoint("TOPLEFT", PAD, y - 14)
    line:SetPoint("RIGHT", -PAD, 0)
    line:SetColorTexture(unpack(C.borderLight))

    return y - SUB_GAP
end

-------------------------------------------------
-- Helper: Checkbox
-------------------------------------------------
local function CreateCheckbox(parent, label, y, dbKey, indent)
    local xOff = indent or PAD
    local size = 18
    local btn = CreateFrame("Button", nil, parent, "BackdropTemplate")
    btn:SetSize(size, size)
    btn:SetPoint("TOPLEFT", xOff, y)
    btn:SetBackdrop(BACKDROP)
    btn:SetBackdropColor(0.1, 0.1, 0.1, 1)
    btn:SetBackdropBorderColor(unpack(C.border))
    btn.disabled = false

    local check = btn:CreateTexture(nil, "OVERLAY")
    check:SetSize(size - 6, size - 6)
    check:SetPoint("CENTER")
    check:SetColorTexture(unpack(C.accent))
    btn.check = check

    local txt = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    txt:SetPoint("LEFT", btn, "RIGHT", 8, 0)
    txt:SetText(label)
    txt:SetTextColor(unpack(C.text))
    btn.text = txt

    local function UpdateVisual()
        if btn.disabled then
            check:Hide()
            btn:SetBackdropColor(unpack(C.disabledBg))
            btn:SetBackdropBorderColor(0.08, 0.08, 0.08, 1)
            txt:SetTextColor(unpack(C.disabled))
            return
        end
        btn:SetBackdropColor(0.1, 0.1, 0.1, 1)
        if WafflemationsDB[dbKey] then
            check:Show()
            btn:SetBackdropBorderColor(unpack(C.accentDim))
        else
            check:Hide()
            btn:SetBackdropBorderColor(unpack(C.border))
        end
        txt:SetTextColor(unpack(C.text))
    end
    btn.UpdateVisual = UpdateVisual

    function btn:SetDisabled(state)
        self.disabled = state
        UpdateVisual()
    end

    btn:SetScript("OnClick", function()
        if btn.disabled then return end
        WafflemationsDB[dbKey] = not WafflemationsDB[dbKey]
        UpdateVisual()
        if btn.onChanged then btn.onChanged() end
    end)
    btn:SetScript("OnEnter", function(self)
        if self.disabled then return end
        self:SetBackdropBorderColor(unpack(C.accent))
        txt:SetTextColor(unpack(C.textBright))
    end)
    btn:SetScript("OnLeave", function(self)
        if self.disabled then return end
        UpdateVisual()
    end)

    btn:SetScript("OnShow", UpdateVisual)
    UpdateVisual()
    return btn, y - CB_H
end

-------------------------------------------------
-- Helper: Radio Group
-------------------------------------------------
local function CreateRadioGroup(parent, y, label, options, dbKey)
    local lbl = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    lbl:SetPoint("TOPLEFT", PAD, y)
    lbl:SetText(label)
    lbl:SetTextColor(unpack(C.label))

    local buttons = {}
    local function UpdateAll()
        for _, b in ipairs(buttons) do
            local sel = (WafflemationsDB[dbKey] == b.optValue)
            b.dot:SetShown(sel)
            b.ring:SetBackdropBorderColor(sel and C.accentDim[1] or C.border[1], sel and C.accentDim[2] or C.border[2], sel and C.accentDim[3] or C.border[3], 1)
        end
    end

    local curY = y
    for i, opt in ipairs(options) do
        local sz = 16
        curY = curY - 22
        local btn = CreateFrame("Button", nil, parent, "BackdropTemplate")
        btn:SetSize(sz, sz)
        btn:SetPoint("TOPLEFT", PAD + 12, curY)
        btn:SetBackdrop(BACKDROP)
        btn:SetBackdropColor(0.1, 0.1, 0.1, 1)
        btn:SetBackdropBorderColor(unpack(C.border))
        btn.ring = btn

        local dot = btn:CreateTexture(nil, "OVERLAY")
        dot:SetSize(sz - 6, sz - 6)
        dot:SetPoint("CENTER")
        dot:SetColorTexture(unpack(C.accent))
        dot:Hide()
        btn.dot = dot

        local t = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        t:SetPoint("LEFT", btn, "RIGHT", 8, 0)
        t:SetText(opt.label)
        t:SetTextColor(unpack(C.text))

        btn:SetScript("OnClick", function() WafflemationsDB[dbKey] = opt.value; UpdateAll() end)
        btn:SetScript("OnEnter", function(self) self:SetBackdropBorderColor(unpack(C.accent)); t:SetTextColor(unpack(C.textBright)) end)
        btn:SetScript("OnLeave", function(self)
            local sel = (WafflemationsDB[dbKey] == opt.value)
            self:SetBackdropBorderColor(sel and C.accentDim[1] or C.border[1], sel and C.accentDim[2] or C.border[2], sel and C.accentDim[3] or C.border[3], 1)
            t:SetTextColor(unpack(C.text))
        end)

        btn:SetScript("OnShow", UpdateAll)
        btn.optValue = opt.value
        buttons[i] = btn
    end

    UpdateAll()
    return buttons, curY - 6
end

-------------------------------------------------
-- Helper: Description
-------------------------------------------------
local function CreateDescription(parent, text, y)
    local d = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    d:SetPoint("TOPLEFT", PAD, y)
    d:SetPoint("RIGHT", -PAD, 0)
    d:SetJustifyH("LEFT")
    d:SetSpacing(3)
    d:SetText(text)
    d:SetTextColor(unpack(C.textDim))
    return d
end

-------------------------------------------------
-- Helper: Text input
-------------------------------------------------
local function CreateTextInput(parent, label, y, width, dbKey)
    local lbl = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    lbl:SetPoint("TOPLEFT", PAD, y)
    lbl:SetText(label)
    lbl:SetTextColor(unpack(C.label))

    local box = CreateFrame("EditBox", nil, parent, "BackdropTemplate")
    box:SetSize(width, 24)
    box:SetPoint("TOPLEFT", PAD, y - 16)
    box:SetBackdrop(BACKDROP)
    box:SetBackdropColor(0.05, 0.05, 0.05, 1)
    box:SetBackdropBorderColor(unpack(C.border))
    box:SetFontObject("GameFontNormalSmall")
    box:SetTextColor(unpack(C.text))
    box:SetTextInsets(8, 8, 0, 0)
    box:SetAutoFocus(false)
    box:SetMaxLetters(200)

    box:SetText(WafflemationsDB[dbKey] or "")
    box:SetScript("OnEnterPressed", function(self) WafflemationsDB[dbKey] = self:GetText(); self:ClearFocus() end)
    box:SetScript("OnEscapePressed", function(self) self:SetText(WafflemationsDB[dbKey] or ""); self:ClearFocus() end)
    box:SetScript("OnEditFocusLost", function(self) WafflemationsDB[dbKey] = self:GetText(); self:SetBackdropBorderColor(unpack(C.border)) end)
    box:SetScript("OnEditFocusGained", function(self) self:SetBackdropBorderColor(unpack(C.accent)) end)

    return box, y - 46
end

-------------------------------------------------
-- Helper: Sound picker (dropdown + play button)
-------------------------------------------------
-- Curated alert sound list
local ALERT_SOUNDS = {}
local function AddSound(key, label)
    if SOUNDKIT[key] then
        tinsert(ALERT_SOUNDS, { id = SOUNDKIT[key], name = label })
    end
end
AddSound("RAID_WARNING",           "Raid Warning")
AddSound("READY_CHECK",            "Ready Check")
AddSound("ALARM_CLOCK_WARNING_3",  "Alarm Clock")
AddSound("PVP_THROUGH_QUEUE",      "Queue Ready")
AddSound("MAP_PING",               "Map Ping")
AddSound("LEVEL_UP",               "Level Up")
AddSound("UI_EPICLOOT_TOAST",      "Epic Loot Toast")
AddSound("UI_RAID_BOSS_WHISPER",   "Boss Whisper")
AddSound("GM_CHAT_WARNING",        "GM Warning")
AddSound("UI_70_BOOST_THANKSFORPLAYING_SMALLER", "Quest Complete Fanfare")
-- "You are not prepared" (Illidan)
tinsert(ALERT_SOUNDS, { id = 11466, name = "You Are Not Prepared" })
table.sort(ALERT_SOUNDS, function(a, b) return a.name < b.name end)

local function CreateSoundPicker(parent, y, dbKey)
    local lbl = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    lbl:SetPoint("TOPLEFT", SUB_PAD, y)
    lbl:SetText("Alert Sound")
    lbl:SetTextColor(unpack(C.label))

    -- Dropdown toggle button
    local dropBtn = CreateFrame("Button", nil, parent, "BackdropTemplate")
    dropBtn:SetSize(200, 24)
    dropBtn:SetPoint("TOPLEFT", SUB_PAD, y - 16)
    dropBtn:SetBackdrop(BACKDROP)
    dropBtn:SetBackdropColor(0.06, 0.06, 0.06, 1)
    dropBtn:SetBackdropBorderColor(unpack(C.border))

    local dropText = dropBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    dropText:SetPoint("LEFT", 8, 0)
    dropText:SetTextColor(unpack(C.text))

    local dropArrow = dropBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    dropArrow:SetPoint("RIGHT", -8, 0)
    dropArrow:SetText("v")
    dropArrow:SetTextColor(unpack(C.textDim))

    -- Play preview button
    local playBtn = CreateFrame("Button", nil, parent, "BackdropTemplate")
    playBtn:SetSize(50, 24)
    playBtn:SetPoint("LEFT", dropBtn, "RIGHT", 6, 0)
    playBtn:SetBackdrop(BACKDROP)
    playBtn:SetBackdropColor(0.1, 0.1, 0.1, 1)
    playBtn:SetBackdropBorderColor(unpack(C.border))

    local playText = playBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    playText:SetPoint("CENTER")
    playText:SetText("Play")
    playText:SetTextColor(unpack(C.accent))

    playBtn:SetScript("OnEnter", function(self) self:SetBackdropBorderColor(unpack(C.accent)) end)
    playBtn:SetScript("OnLeave", function(self) self:SetBackdropBorderColor(unpack(C.border)) end)
    playBtn:SetScript("OnClick", function()
        PlaySound(WafflemationsDB[dbKey] or 11466, "Master")
    end)

    -- Simple dropdown list (no scroll needed for small lists)
    local LIST_ITEM_H = 22

    local listFrame = CreateFrame("Frame", nil, dropBtn, "BackdropTemplate")
    listFrame:SetPoint("TOPLEFT", dropBtn, "BOTTOMLEFT", 0, -2)
    listFrame:SetSize(300, #ALERT_SOUNDS * LIST_ITEM_H + 4)
    listFrame:SetBackdrop(BACKDROP)
    listFrame:SetBackdropColor(0.04, 0.04, 0.04, 0.98)
    listFrame:SetBackdropBorderColor(unpack(C.border))
    listFrame:SetFrameStrata("TOOLTIP")
    listFrame:Hide()

    local function UpdateDisplay()
        local currentID = WafflemationsDB[dbKey] or 11466
        for _, s in ipairs(ALERT_SOUNDS) do
            if s.id == currentID then
                dropText:SetText(s.name)
                return
            end
        end
        dropText:SetText("Sound #" .. currentID)
    end

    for i, sound in ipairs(ALERT_SOUNDS) do
        local item = CreateFrame("Button", nil, listFrame)
        item:SetHeight(LIST_ITEM_H)
        item:SetPoint("TOPLEFT", 2, -(i - 1) * LIST_ITEM_H - 2)
        item:SetPoint("RIGHT", listFrame, "RIGHT", -2, 0)

        local itemBg = item:CreateTexture(nil, "BACKGROUND")
        itemBg:SetAllPoints()
        itemBg:SetColorTexture(0, 0, 0, 0)

        local itemText = item:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        itemText:SetPoint("LEFT", 8, 0)
        itemText:SetPoint("RIGHT", item, "RIGHT", -30, 0)
        itemText:SetJustifyH("LEFT")
        itemText:SetText(sound.name)
        itemText:SetTextColor(unpack(C.text))

        -- Play button per row
        local itemPlay = CreateFrame("Button", nil, item, "BackdropTemplate")
        itemPlay:SetSize(22, 18)
        itemPlay:SetPoint("RIGHT", -4, 0)
        itemPlay:SetBackdrop(BACKDROP)
        itemPlay:SetBackdropColor(0.07, 0.07, 0.07, 1)
        itemPlay:SetBackdropBorderColor(unpack(C.border))

        local itemPlayIcon = itemPlay:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        itemPlayIcon:SetPoint("CENTER", 1, 0)
        itemPlayIcon:SetText("|cff66cc66>|r")

        itemPlay:SetScript("OnClick", function()
            PlaySound(sound.id, "Master")
        end)
        itemPlay:SetScript("OnEnter", function(self)
            self:SetBackdropBorderColor(unpack(C.accent))
            itemBg:SetColorTexture(unpack(C.catHover))
            itemText:SetTextColor(unpack(C.textBright))
        end)
        itemPlay:SetScript("OnLeave", function(self)
            self:SetBackdropBorderColor(unpack(C.border))
            itemBg:SetColorTexture(0, 0, 0, 0)
            itemText:SetTextColor(unpack(C.text))
        end)

        item:SetScript("OnEnter", function()
            itemBg:SetColorTexture(unpack(C.catHover))
            itemText:SetTextColor(unpack(C.textBright))
        end)
        item:SetScript("OnLeave", function()
            itemBg:SetColorTexture(0, 0, 0, 0)
            itemText:SetTextColor(unpack(C.text))
        end)
        item:SetScript("OnClick", function()
            WafflemationsDB[dbKey] = sound.id
            UpdateDisplay()
            listFrame:Hide()
        end)
    end

    dropBtn:SetScript("OnClick", function()
        listFrame:SetShown(not listFrame:IsShown())
    end)
    dropBtn:SetScript("OnEnter", function(self) self:SetBackdropBorderColor(unpack(C.accent)) end)
    dropBtn:SetScript("OnLeave", function(self)
        if not listFrame:IsShown() then self:SetBackdropBorderColor(unpack(C.border)) end
    end)
    listFrame:SetScript("OnHide", function() dropBtn:SetBackdropBorderColor(unpack(C.border)) end)

    dropBtn:SetScript("OnShow", UpdateDisplay)
    UpdateDisplay()

    return dropBtn, y - 48
end

--=========================================================
--  CATEGORIES
--=========================================================

-------------------------------------------------
-- About
-------------------------------------------------
CreateCategoryButton("About", 1)
CreateSidebarDivider(1) -- line after About
local aboutContent = CreateContentFrame("About", 320)

local aboutTitle = aboutContent:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
aboutTitle:SetPoint("TOP", 0, -24)
aboutTitle:SetText("Wafflemations")
aboutTitle:SetTextColor(unpack(C.accent))

local aboutVer = aboutContent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
aboutVer:SetPoint("TOP", aboutTitle, "BOTTOM", 0, -6)
aboutVer:SetText("v1.0.0  |  Interface 12.0.1")
aboutVer:SetTextColor(unpack(C.textDim))

local aboutDiv = aboutContent:CreateTexture(nil, "ARTWORK")
aboutDiv:SetHeight(1)
aboutDiv:SetPoint("TOPLEFT", PAD + 20, -72)
aboutDiv:SetPoint("RIGHT", -(PAD + 20), 0)
aboutDiv:SetColorTexture(unpack(C.borderLight))

local features = {
    { "General",        "Cutscenes, Talking Head, Combat" },
    { "Repair & Sell",  "Auto-repair gear and sell gray items" },
    { "Mail",           "Collects mail from your mailbox" },
    { "Summon",         "Accepts summons automatically" },
    { "Resurrect",      "Accepts resurrections automatically" },
    { "Dungeon",        "M+ keys, end-of-dungeon, buff checks" },
}
local fy = -90
for _, feat in ipairs(features) do
    local bullet = aboutContent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    bullet:SetPoint("TOPLEFT", PAD + 10, fy)
    bullet:SetText("|cff66cc66" .. feat[1] .. "|r")

    local desc = aboutContent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    desc:SetPoint("LEFT", bullet, "RIGHT", 6, 0)
    desc:SetText("- " .. feat[2])
    desc:SetTextColor(unpack(C.text))

    fy = fy - 18
end

local aboutHint = aboutContent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
aboutHint:SetPoint("TOPLEFT", PAD + 10, fy - 10)
aboutHint:SetText("Select a category on the left to configure.")
aboutHint:SetTextColor(unpack(C.textDim))

-- Reset confirmation overlay
local confirmOverlay = CreateFrame("Frame", nil, optionsFrame, "BackdropTemplate")
confirmOverlay:SetAllPoints()
confirmOverlay:SetFrameLevel(optionsFrame:GetFrameLevel() + 20)
confirmOverlay:SetBackdrop(BACKDROP)
confirmOverlay:SetBackdropColor(0, 0, 0, 0.8)
confirmOverlay:SetBackdropBorderColor(0, 0, 0, 0)
confirmOverlay:EnableMouse(true)
confirmOverlay:Hide()

local confirmBox = CreateFrame("Frame", nil, confirmOverlay, "BackdropTemplate")
confirmBox:SetSize(320, 130)
confirmBox:SetPoint("CENTER", 0, 20)
confirmBox:SetBackdrop(BACKDROP)
confirmBox:SetBackdropColor(unpack(C.bg))
confirmBox:SetBackdropBorderColor(unpack(C.border))
CreatePixelBorder(confirmBox, unpack(C.border))

local confirmTitle = confirmBox:CreateFontString(nil, "OVERLAY", "GameFontNormal")
confirmTitle:SetPoint("TOP", 0, -16)
confirmTitle:SetText("Reset All Settings?")
confirmTitle:SetTextColor(unpack(C.label))

local confirmDesc = confirmBox:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
confirmDesc:SetPoint("TOP", confirmTitle, "BOTTOM", 0, -10)
confirmDesc:SetText("This will reset all options to their defaults.\nThis cannot be undone.")
confirmDesc:SetTextColor(unpack(C.text))
confirmDesc:SetJustifyH("CENTER")

local confirmYes = CreateFrame("Button", nil, confirmBox, "BackdropTemplate")
confirmYes:SetSize(100, 26)
confirmYes:SetPoint("BOTTOMRIGHT", confirmBox, "BOTTOM", -8, 16)
confirmYes:SetBackdrop(BACKDROP)
confirmYes:SetBackdropColor(0.5, 0.15, 0.15, 1)
confirmYes:SetBackdropBorderColor(unpack(C.border))

local confirmYesTxt = confirmYes:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
confirmYesTxt:SetPoint("CENTER")
confirmYesTxt:SetText("Reset")
confirmYesTxt:SetTextColor(1, 0.8, 0.8)

confirmYes:SetScript("OnEnter", function(self)
    self:SetBackdropColor(0.65, 0.2, 0.2, 1)
    self:SetBackdropBorderColor(0.8, 0.3, 0.3, 1)
end)
confirmYes:SetScript("OnLeave", function(self)
    self:SetBackdropColor(0.5, 0.15, 0.15, 1)
    self:SetBackdropBorderColor(unpack(C.border))
end)
confirmYes:SetScript("OnClick", function()
    for k, v in pairs(Wafflemations.defaults) do
        WafflemationsDB[k] = v
    end
    confirmOverlay:Hide()
    print("|cff88cc88[Wafflemations]|r All settings have been reset to defaults.")
    ReloadUI()
end)

local confirmNo = CreateFrame("Button", nil, confirmBox, "BackdropTemplate")
confirmNo:SetSize(100, 26)
confirmNo:SetPoint("BOTTOMLEFT", confirmBox, "BOTTOM", 8, 16)
confirmNo:SetBackdrop(BACKDROP)
confirmNo:SetBackdropColor(0.1, 0.1, 0.1, 1)
confirmNo:SetBackdropBorderColor(unpack(C.border))

local confirmNoTxt = confirmNo:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
confirmNoTxt:SetPoint("CENTER")
confirmNoTxt:SetText("Cancel")
confirmNoTxt:SetTextColor(unpack(C.text))

confirmNo:SetScript("OnEnter", function(self)
    self:SetBackdropColor(0.15, 0.15, 0.15, 1)
    self:SetBackdropBorderColor(unpack(C.accent))
end)
confirmNo:SetScript("OnLeave", function(self)
    self:SetBackdropColor(0.1, 0.1, 0.1, 1)
    self:SetBackdropBorderColor(unpack(C.border))
end)
confirmNo:SetScript("OnClick", function() confirmOverlay:Hide() end)

-- Reset button on About page
local resetBtn = CreateFrame("Button", nil, aboutContent, "BackdropTemplate")
resetBtn:SetSize(140, 28)
resetBtn:SetPoint("BOTTOMRIGHT", -PAD, 10)
resetBtn:SetBackdrop(BACKDROP)
resetBtn:SetBackdropColor(0.12, 0.12, 0.12, 1)
resetBtn:SetBackdropBorderColor(unpack(C.border))

local resetTxt = resetBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
resetTxt:SetPoint("CENTER")
resetTxt:SetText("Reset to Defaults")
resetTxt:SetTextColor(unpack(C.text))

resetBtn:SetScript("OnEnter", function(self)
    self:SetBackdropBorderColor(unpack(C.closeHover))
    resetTxt:SetTextColor(1, 0.8, 0.8)
end)
resetBtn:SetScript("OnLeave", function(self)
    self:SetBackdropBorderColor(unpack(C.border))
    resetTxt:SetTextColor(unpack(C.text))
end)
resetBtn:SetScript("OnClick", function() confirmOverlay:Show() end)

-------------------------------------------------
-- General
-------------------------------------------------
CreateCategoryButton("General", 2)
local generalContent = CreateContentFrame("General", 340)

local y = CreateSectionHeader(generalContent, "Cutscenes", -PAD)
local skipCB, y = CreateCheckbox(generalContent, "Auto-skip cutscenes", y, "skipCutscenes")
local onlyWatchedCB, y = CreateCheckbox(generalContent, "Only skip already-watched cutscenes", y, "skipCutscenesOnlyWatched", SUB_PAD)

local function UpdateOnlyWatchedState()
    onlyWatchedCB:SetDisabled(not WafflemationsDB.skipCutscenes)
end
skipCB.onChanged = UpdateOnlyWatchedState
generalContent:HookScript("OnShow", UpdateOnlyWatchedState)
CreateDescription(generalContent,
    "When 'only watched' is enabled, cutscenes play once then auto-skip on repeat viewings.",
    y - 4)

y = y - 36
y = CreateSectionHeader(generalContent, "Talking Head", y)
local _, y = CreateCheckbox(generalContent, "Hide Talking Head popups", y, "hideTalkingHead")

y = y - SEC_GAP
y = CreateSectionHeader(generalContent, "Combat", y)
local _, y = CreateCheckbox(generalContent, "Auto-hide World Map on combat start", y, "combatHideMap")
local _, y = CreateCheckbox(generalContent, "Auto-close bags on combat start", y, "combatHideBags")
CreateDescription(generalContent,
    "Automatically closes these UI panels when you enter combat to keep your screen clear.",
    y - 4)

-------------------------------------------------
-- Repair & Sell
-------------------------------------------------
CreateCategoryButton("Repair & Sell", 3)
local repairSellContent = CreateContentFrame("Repair & Sell", 360)

y = CreateSectionHeader(repairSellContent, "Auto-Repair", -PAD)
local repairEnableCB, y = CreateCheckbox(repairSellContent, "Enable Auto-Repair", y, "autoRepairEnabled")
local repairChatCB, y = CreateCheckbox(repairSellContent, "Show repair cost in chat", y, "autoRepairChat", SUB_PAD)

local function UpdateRepairChatState()
    repairChatCB:SetDisabled(not WafflemationsDB.autoRepairEnabled)
end
repairEnableCB.onChanged = UpdateRepairChatState
repairSellContent:HookScript("OnShow", UpdateRepairChatState)

y = y - SEC_GAP
local _, y = CreateRadioGroup(repairSellContent, y, "Repair Mode", {
    { label = "Guild first, then personal gold", value = "guild_first" },
    { label = "Personal gold only", value = "personal_only" },
}, "autoRepairMode")

y = y - SEC_GAP * 2
y = CreateSectionHeader(repairSellContent, "Auto-Sell", y)
local sellEnableCB, y = CreateCheckbox(repairSellContent, "Enable Auto-Sell gray items", y, "autoSellEnabled")
local sellChatCB = CreateCheckbox(repairSellContent, "Show sell total in chat", y, "autoSellChat", SUB_PAD)

local function UpdateSellChatState()
    sellChatCB:SetDisabled(not WafflemationsDB.autoSellEnabled)
end
sellEnableCB.onChanged = UpdateSellChatState
repairSellContent:HookScript("OnShow", UpdateSellChatState)

-------------------------------------------------
-- Mail
-------------------------------------------------
CreateCategoryButton("Mail", 4)
local mailContent = CreateContentFrame("Mail", 220)

y = CreateSectionHeader(mailContent, "Auto-Collect Mail", -PAD)
local _, y = CreateCheckbox(mailContent, "Enable Auto-Collect mail", y, "autoMailEnabled")
local _, y = CreateCheckbox(mailContent, "Show collected gold in chat", y, "autoMailChat")
local _, y = CreateCheckbox(mailContent, "Auto-delete empty mail", y, "autoMailDeleteEmpty")

CreateDescription(mailContent,
    "Automatically collects items and gold from your mailbox when opened. COD mail is always skipped.",
    y - 6)

-------------------------------------------------
-- Auto-Summon
-------------------------------------------------
CreateCategoryButton("Summon", 5)
local summonContent = CreateContentFrame("Summon", 520)

y = CreateSectionHeader(summonContent, "Auto-Summon", -PAD)
local summonEnabledCB, y = CreateCheckbox(summonContent, "Enable Auto-Accept summons", y, "autoSummonEnabled")

y = y - SEC_GAP
y = CreateSubHeader(summonContent, "Chat on Summon Received", y)
local receiveNote = CreateDescription(summonContent,
    "Disabled when auto-accept is on to prevent chat spam.",
    y)
y = y - 16
local receiveChatCB, y = CreateCheckbox(summonContent, "Announce when summon received", y, "autoSummonChatOnReceive")
local _, y = CreateTextInput(summonContent, "Receive Message  ({summoner} and {location} are replaced)", y - 4, 390, "autoSummonReceiveMsg")

-- Link: disable receive checkbox when auto-accept is on
local function UpdateReceiveState()
    receiveChatCB:SetDisabled(WafflemationsDB.autoSummonEnabled)
end
summonEnabledCB.onChanged = UpdateReceiveState
summonContent:HookScript("OnShow", UpdateReceiveState)

y = y - SEC_GAP
y = CreateSubHeader(summonContent, "Chat on Summon Accepted", y)
local _, y = CreateCheckbox(summonContent, "Announce when summon accepted", y, "autoSummonChatOnAccept")
local _, y = CreateTextInput(summonContent, "Accept Message  ({summoner} and {location} are replaced)", y - 4, 390, "autoSummonAcceptMsg")

y = y - SEC_GAP
y = CreateSubHeader(summonContent, "Enable Chat Per Group Type", y)
local _, y = CreateCheckbox(summonContent, "Party", y, "autoSummonChatParty")
local _, y = CreateCheckbox(summonContent, "Raid", y, "autoSummonChatRaid")
CreateCheckbox(summonContent, "Instance (LFG/LFR)", y, "autoSummonChatInstance")

-------------------------------------------------
-- Auto-Resurrect
-------------------------------------------------
CreateCategoryButton("Resurrect", 6)
local resContent = CreateContentFrame("Resurrect", 420)

y = CreateSectionHeader(resContent, "Auto-Resurrect", -PAD)
local _, y = CreateCheckbox(resContent, "Auto-accept out-of-combat resurrections", y, "autoResOOCEnabled")
local _, y = CreateCheckbox(resContent, "Auto-accept combat resurrections", y, "autoResCombatEnabled")

y = y - SEC_GAP
y = CreateSubHeader(resContent, "Chat on Resurrection Accepted", y)
local _, y = CreateCheckbox(resContent, "Announce when resurrection accepted", y, "autoResChatOnAccept")
local _, y = CreateTextInput(resContent, "Accept Message  ({caster} is replaced)", y - 4, 390, "autoResAcceptMsg")

y = y - SEC_GAP
y = CreateSubHeader(resContent, "Enable Chat Per Group Type", y)
local _, y = CreateCheckbox(resContent, "Party", y, "autoResChatParty")
local _, y = CreateCheckbox(resContent, "Raid", y, "autoResChatRaid")
CreateCheckbox(resContent, "Instance (LFG/LFR)", y, "autoResChatInstance")

-------------------------------------------------
-- Dungeon
-------------------------------------------------
CreateCategoryButton("Dungeon", 7)
local dungeonContent = CreateContentFrame("Dungeon", 900)

-- Keystone section
y = CreateSectionHeader(dungeonContent, "Keystone", -PAD)
local _, y = CreateCheckbox(dungeonContent, "Show key reminder when joining M+ group", y, "dungeonKeyReminder")
local _, y = CreateCheckbox(dungeonContent, "Auto-insert keystone at font of power", y, "dungeonAutoInsertKey")

-- End of Dungeon section
y = y - SEC_GAP * 2
y = CreateSectionHeader(dungeonContent, "End of Dungeon", y)
local ggEnableCB, y = CreateCheckbox(dungeonContent, "Send message at end of dungeon", y, "dungeonAutoGG")
local ggMsgInput, y = CreateTextInput(dungeonContent, "Message", y - 4, 390, "dungeonGGMessage")
local ggDelayInput, y = CreateTextInput(dungeonContent, "Delay (seconds, 0 = instant)", y - 4, 120, "dungeonGGDelay")
local ggMythicCB, y = CreateCheckbox(dungeonContent, "Trigger on M+ completion", y - 4, "dungeonGGMythicPlus", SUB_PAD)
local ggRegularCB, y = CreateCheckbox(dungeonContent, "Trigger on regular dungeon completion", y, "dungeonGGRegular", SUB_PAD)

local function UpdateGGState()
    local off = not WafflemationsDB.dungeonAutoGG
    ggMythicCB:SetDisabled(off)
    ggRegularCB:SetDisabled(off)
end
ggEnableCB.onChanged = UpdateGGState
dungeonContent:HookScript("OnShow", UpdateGGState)

-- Spec Reminder section
y = y - SEC_GAP * 2
y = CreateSectionHeader(dungeonContent, "Spec Reminder", y)
local _, y = CreateCheckbox(dungeonContent, "Remind current spec when entering a mythic dungeon", y, "dungeonSpecReminder")
local _, y = CreateCheckbox(dungeonContent, "Show active talent loadout name", y, "dungeonSpecShowLoadout", SUB_PAD)
y = y - SEC_GAP
local _, y = CreateRadioGroup(dungeonContent, y, "Spec Reminder Channel", {
    { label = "Print (local chat only)", value = "print" },
    { label = "Emote", value = "emote" },
    { label = "Party / Raid / Instance", value = "group" },
}, "dungeonSpecReminderChannel")

-- Unspent Talents Warning section
y = y - SEC_GAP * 2
y = CreateSectionHeader(dungeonContent, "Unspent Talents Warning", y)
local unspentCB, y = CreateCheckbox(dungeonContent, "Warn about unspent talents when entering a mythic dungeon", y, "dungeonUnspentWarning")
local unspentSoundCB, y = CreateCheckbox(dungeonContent, "Play alert sound", y, "dungeonUnspentSound", SUB_PAD)
local _, y = CreateSoundPicker(dungeonContent, y, "dungeonUnspentSoundID")
y = y - SEC_GAP
local _, y = CreateRadioGroup(dungeonContent, y, "Warning Channel", {
    { label = "Print (local chat only)", value = "print" },
    { label = "Emote", value = "emote" },
    { label = "Party / Raid / Instance", value = "group" },
}, "dungeonUnspentChannel")

local function UpdateUnspentSoundState()
    unspentSoundCB:SetDisabled(not WafflemationsDB.dungeonUnspentWarning)
end
unspentCB.onChanged = UpdateUnspentSoundState
dungeonContent:HookScript("OnShow", UpdateUnspentSoundState)

-- Ready Check Buffs section
y = y - SEC_GAP * 2
y = CreateSectionHeader(dungeonContent, "Ready Check Buffs", y)
local buffCheckCB, y = CreateCheckbox(dungeonContent, "Check buffs on ready check", y, "dungeonReadyCheckBuffs")

y = y - SEC_GAP
local _, y = CreateRadioGroup(dungeonContent, y, "Announcement Mode", {
    { label = "Personal (local chat only)", value = "personal" },
    { label = "Announce to group chat", value = "party" },
}, "dungeonBuffCheckMode")

y = y - SEC_GAP
y = CreateSubHeader(dungeonContent, "Buffs to Check", y)
local buffClassCB, y = CreateCheckbox(dungeonContent, "Class buffs (based on group composition)", y, "dungeonBuffCheckClassBuffs", SUB_PAD)
local buffFoodCB, y = CreateCheckbox(dungeonContent, "Food (Well Fed)", y, "dungeonBuffCheckFood", SUB_PAD)
local buffFlaskCB = CreateCheckbox(dungeonContent, "Flask / Phial", y, "dungeonBuffCheckFlask", SUB_PAD)

local function UpdateBuffCheckState()
    local off = not WafflemationsDB.dungeonReadyCheckBuffs
    buffClassCB:SetDisabled(off)
    buffFoodCB:SetDisabled(off)
    buffFlaskCB:SetDisabled(off)
end
buffCheckCB.onChanged = UpdateBuffCheckState
dungeonContent:HookScript("OnShow", UpdateBuffCheckState)

-------------------------------------------------
-- Default selection
-------------------------------------------------
SelectCategory("About")

-------------------------------------------------
-- Public toggle
-------------------------------------------------
function Wafflemations.ToggleOptions()
    if optionsFrame:IsShown() then
        optionsFrame:Hide()
    else
        optionsFrame:Show()
    end
end
