-- Wafflemations Options Panel (ElvUI-inspired)

local PANEL_WIDTH = 580
local PANEL_HEIGHT = 440
local SIDEBAR_WIDTH = 150
local TITLE_HEIGHT = 28

-- ElvUI-style color palette
local C = {
    bg          = {0.055, 0.055, 0.055, 0.98},  -- near-black panel bg
    bgInner     = {0.075, 0.075, 0.075, 1},      -- content area
    sidebar     = {0.04, 0.04, 0.04, 1},          -- sidebar darker
    border      = {0.15, 0.15, 0.15, 1},          -- pixel border
    borderLight = {0.25, 0.25, 0.25, 1},          -- subtle dividers
    accent      = {0.4, 0.78, 0.4, 1},            -- green accent
    accentDim   = {0.3, 0.55, 0.3, 1},            -- muted accent
    title       = {0.9, 0.9, 0.9, 1},             -- title text
    text        = {0.78, 0.78, 0.78, 1},           -- body text
    textDim     = {0.5, 0.5, 0.5, 1},             -- secondary text
    catNormal   = {0.065, 0.065, 0.065, 1},        -- cat button bg
    catHover    = {0.1, 0.1, 0.1, 1},              -- cat hover
    catSelected = {0.08, 0.08, 0.08, 1},           -- cat selected bg
    label       = {0.9, 0.8, 0.5, 1},            -- warm gold for labels
    close       = {0.7, 0.7, 0.7, 1},
    closeHover  = {0.9, 0.25, 0.25, 1},
}

local BACKDROP_OUTER = {
    bgFile = "Interface\\BUTTONS\\WHITE8X8",
    edgeFile = "Interface\\BUTTONS\\WHITE8X8",
    edgeSize = 1,
}

local BACKDROP_INNER = {
    bgFile = "Interface\\BUTTONS\\WHITE8X8",
    edgeFile = "Interface\\BUTTONS\\WHITE8X8",
    edgeSize = 1,
}

-------------------------------------------------
-- Helper: Pixel border inset frame
-------------------------------------------------
local function CreatePixelBorder(parent, r, g, b, a)
    local border = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    border:SetPoint("TOPLEFT", -1, 1)
    border:SetPoint("BOTTOMRIGHT", 1, -1)
    border:SetBackdrop({
        edgeFile = "Interface\\BUTTONS\\WHITE8X8",
        edgeSize = 1,
    })
    border:SetBackdropBorderColor(r or 0, g or 0, b or 0, a or 1)
    border:SetFrameLevel(parent:GetFrameLevel() + 1)
    return border
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
optionsFrame:SetBackdrop(BACKDROP_OUTER)
optionsFrame:SetBackdropColor(unpack(C.bg))
optionsFrame:SetBackdropBorderColor(0, 0, 0, 1)
optionsFrame:Hide()
tinsert(UISpecialFrames, "WafflemationsOptionsFrame")

-- Outer glow border (double-border ElvUI look)
CreatePixelBorder(optionsFrame, unpack(C.border))

-------------------------------------------------
-- Title Bar
-------------------------------------------------
local titleBar = CreateFrame("Frame", nil, optionsFrame, "BackdropTemplate")
titleBar:SetHeight(TITLE_HEIGHT)
titleBar:SetPoint("TOPLEFT", 2, -2)
titleBar:SetPoint("TOPRIGHT", -2, -2)
titleBar:SetBackdrop(BACKDROP_INNER)
titleBar:SetBackdropColor(0.065, 0.065, 0.065, 1)
titleBar:SetBackdropBorderColor(unpack(C.border))

local titleText = titleBar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
titleText:SetPoint("LEFT", 10, 0)
titleText:SetText("WAFFLEMATIONS")
titleText:SetTextColor(unpack(C.accent))

local closeButton = CreateFrame("Button", nil, titleBar, "BackdropTemplate")
closeButton:SetSize(18, 18)
closeButton:SetPoint("RIGHT", -4, 0)
closeButton:SetBackdrop(BACKDROP_INNER)
closeButton:SetBackdropColor(0.08, 0.08, 0.08, 1)
closeButton:SetBackdropBorderColor(unpack(C.border))

local closeText = closeButton:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
closeText:SetPoint("CENTER", 0, 0)
closeText:SetText("x")
closeText:SetTextColor(unpack(C.close))

closeButton:SetScript("OnClick", function() optionsFrame:Hide() end)
closeButton:SetScript("OnEnter", function(self)
    closeText:SetTextColor(unpack(C.closeHover))
    self:SetBackdropBorderColor(unpack(C.closeHover))
end)
closeButton:SetScript("OnLeave", function(self)
    closeText:SetTextColor(unpack(C.close))
    self:SetBackdropBorderColor(unpack(C.border))
end)

-------------------------------------------------
-- Sidebar
-------------------------------------------------
local sidebar = CreateFrame("Frame", nil, optionsFrame, "BackdropTemplate")
sidebar:SetWidth(SIDEBAR_WIDTH)
sidebar:SetPoint("TOPLEFT", 2, -(TITLE_HEIGHT + 4))
sidebar:SetPoint("BOTTOMLEFT", 2, 2)
sidebar:SetBackdrop(BACKDROP_INNER)
sidebar:SetBackdropColor(unpack(C.sidebar))
sidebar:SetBackdropBorderColor(unpack(C.border))

-------------------------------------------------
-- Content Area (with scroll frame)
-------------------------------------------------
local contentBg = CreateFrame("Frame", nil, optionsFrame, "BackdropTemplate")
contentBg:SetPoint("TOPLEFT", sidebar, "TOPRIGHT", 2, 0)
contentBg:SetPoint("BOTTOMRIGHT", -2, 2)
contentBg:SetBackdrop(BACKDROP_INNER)
contentBg:SetBackdropColor(unpack(C.bgInner))
contentBg:SetBackdropBorderColor(unpack(C.border))

-- Author text pinned to bottom (above scroll, always visible)
local authorText = contentBg:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
authorText:SetPoint("BOTTOMLEFT", 16, 8)
authorText:SetText("Created by |cff66cc66Waffle Taco|r")
authorText:SetTextColor(unpack(C.textDim))

-- Scroll frame fills content area above the author line
local scrollFrame = CreateFrame("ScrollFrame", nil, contentBg)
scrollFrame:SetPoint("TOPLEFT", 1, -1)
scrollFrame:SetPoint("BOTTOMRIGHT", -10, 22)

-- Scrollbar (ElvUI-style thin track)
local scrollBar = CreateFrame("Slider", nil, contentBg, "BackdropTemplate")
scrollBar:SetWidth(6)
scrollBar:SetPoint("TOPRIGHT", -2, -2)
scrollBar:SetPoint("BOTTOMRIGHT", -2, 22)
scrollBar:SetBackdrop({
    bgFile = "Interface\\BUTTONS\\WHITE8X8",
    edgeFile = "Interface\\BUTTONS\\WHITE8X8",
    edgeSize = 1,
})
scrollBar:SetBackdropColor(0.04, 0.04, 0.04, 1)
scrollBar:SetBackdropBorderColor(unpack(C.border))
scrollBar:SetMinMaxValues(0, 1)
scrollBar:SetValue(0)
scrollBar:SetValueStep(1)
scrollBar:SetObeyStepOnDrag(true)

local scrollThumb = scrollBar:CreateTexture(nil, "OVERLAY")
scrollThumb:SetColorTexture(unpack(C.accentDim))
scrollThumb:SetSize(6, 40)
scrollBar:SetThumbTexture(scrollThumb)

scrollBar:SetScript("OnValueChanged", function(self, value)
    scrollFrame:SetVerticalScroll(value)
end)

-- Mouse wheel scrolling
local function OnMouseWheel(self, delta)
    local current = scrollBar:GetValue()
    local minVal, maxVal = scrollBar:GetMinMaxValues()
    local step = 30
    local newVal = current - (delta * step)
    newVal = math.max(minVal, math.min(maxVal, newVal))
    scrollBar:SetValue(newVal)
end
scrollFrame:SetScript("OnMouseWheel", OnMouseWheel)
contentBg:SetScript("OnMouseWheel", OnMouseWheel)

-- Container for all category content frames
local contentArea = CreateFrame("Frame", nil, scrollFrame)
contentArea:SetWidth(scrollFrame:GetWidth() or (PANEL_WIDTH - SIDEBAR_WIDTH - 18))
scrollFrame:SetScrollChild(contentArea)

-- Update scroll range when content area or scroll frame size changes
local function UpdateScrollRange()
    local contentHeight = contentArea:GetHeight() or 0
    local viewHeight = scrollFrame:GetHeight() or 1
    local maxScroll = math.max(0, contentHeight - viewHeight)
    scrollBar:SetMinMaxValues(0, maxScroll)
    scrollBar:SetShown(maxScroll > 0)
    -- Clamp current value
    if scrollBar:GetValue() > maxScroll then
        scrollBar:SetValue(maxScroll)
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

local function SelectCategory(name)
    if selectedCategory == name then return end
    selectedCategory = name
    for catName, btn in pairs(categories) do
        if catName == name then
            btn.bg:SetColorTexture(unpack(C.catSelected))
            btn.highlight:SetColorTexture(unpack(C.accent))
            btn.highlight:Show()
            btn.label:SetTextColor(unpack(C.accent))
        else
            btn.bg:SetColorTexture(unpack(C.catNormal))
            btn.highlight:Hide()
            btn.label:SetTextColor(unpack(C.text))
        end
    end
    for catName, frame in pairs(contentFrames) do
        frame:SetShown(catName == name)
    end
    -- Reset scroll to top on category change
    scrollBar:SetValue(0)
end

local function CreateCategoryButton(name, index)
    local btn = CreateFrame("Button", nil, sidebar)
    btn:SetHeight(28)
    btn:SetPoint("TOPLEFT", 4, -4 - (index - 1) * 30)
    btn:SetPoint("RIGHT", sidebar, "RIGHT", -4, 0)

    local bg = btn:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(unpack(C.catNormal))
    btn.bg = bg

    -- Left accent stripe (ElvUI-style selected indicator)
    local highlight = btn:CreateTexture(nil, "ARTWORK")
    highlight:SetWidth(2)
    highlight:SetPoint("TOPLEFT", 0, 0)
    highlight:SetPoint("BOTTOMLEFT", 0, 0)
    highlight:SetColorTexture(unpack(C.accent))
    highlight:Hide()
    btn.highlight = highlight

    local label = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    label:SetPoint("LEFT", 10, 0)
    label:SetText(name)
    label:SetTextColor(unpack(C.text))
    btn.label = label

    btn:SetScript("OnClick", function() SelectCategory(name) end)
    btn:SetScript("OnEnter", function()
        if selectedCategory ~= name then
            bg:SetColorTexture(unpack(C.catHover))
            label:SetTextColor(1, 1, 1)
        end
    end)
    btn:SetScript("OnLeave", function()
        if selectedCategory ~= name then
            bg:SetColorTexture(unpack(C.catNormal))
            label:SetTextColor(unpack(C.text))
        end
    end)

    categories[name] = btn
    return btn
end

local function CreateContentFrame(name, height)
    local frame = CreateFrame("Frame", nil, contentArea)
    frame:SetPoint("TOPLEFT", 0, 0)
    frame:SetPoint("RIGHT", contentArea, "RIGHT", 0, 0)
    frame:SetHeight(height or 400)
    frame:Hide()
    frame:SetScript("OnShow", function(self)
        contentArea:SetHeight(self:GetHeight())
        UpdateScrollRange()
    end)
    contentFrames[name] = frame
    return frame
end

-------------------------------------------------
-- Helper: Section header
-------------------------------------------------
local function CreateSectionHeader(parent, text, y)
    local label = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    label:SetPoint("TOPLEFT", 16, y)
    label:SetText(text)
    label:SetTextColor(unpack(C.label))

    local line = parent:CreateTexture(nil, "ARTWORK")
    line:SetHeight(1)
    line:SetPoint("TOPLEFT", 16, y - 16)
    line:SetPoint("RIGHT", -16, 0)
    line:SetColorTexture(unpack(C.borderLight))

    return y - 28
end

-------------------------------------------------
-- Helper: Checkbox (ElvUI flat style)
-------------------------------------------------
local function CreateCheckbox(parent, label, x, y, dbKey)
    local size = 18
    local btn = CreateFrame("Button", nil, parent, "BackdropTemplate")
    btn:SetSize(size, size)
    btn:SetPoint("TOPLEFT", x, y)
    btn:SetBackdrop(BACKDROP_INNER)
    btn:SetBackdropColor(0.1, 0.1, 0.1, 1)
    btn:SetBackdropBorderColor(unpack(C.border))
    btn.disabled = false

    local check = btn:CreateTexture(nil, "OVERLAY")
    check:SetSize(size - 6, size - 6)
    check:SetPoint("CENTER")
    check:SetColorTexture(unpack(C.accent))
    btn.check = check

    local text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    text:SetPoint("LEFT", btn, "RIGHT", 8, 0)
    text:SetText(label)
    text:SetTextColor(unpack(C.text))

    local function UpdateVisual()
        if btn.disabled then
            check:Hide()
            btn:SetBackdropColor(0.06, 0.06, 0.06, 1)
            btn:SetBackdropBorderColor(0.1, 0.1, 0.1, 1)
            text:SetTextColor(0.35, 0.35, 0.35)
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
        text:SetTextColor(unpack(C.text))
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
        text:SetTextColor(1, 1, 1)
    end)
    btn:SetScript("OnLeave", function(self)
        if self.disabled then return end
        UpdateVisual()
    end)

    UpdateVisual()
    return btn
end

-------------------------------------------------
-- Helper: Radio Button Group (ElvUI flat style)
-------------------------------------------------
local function CreateRadioGroup(parent, x, y, label, options, dbKey)
    local header = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    header:SetPoint("TOPLEFT", x, y)
    header:SetText(label)
    header:SetTextColor(unpack(C.label))

    local buttons = {}

    local function UpdateAll()
        for _, b in ipairs(buttons) do
            local selected = (WafflemationsDB[dbKey] == b.optValue)
            if selected then
                b.dot:Show()
                b.ring:SetBackdropBorderColor(unpack(C.accentDim))
            else
                b.dot:Hide()
                b.ring:SetBackdropBorderColor(unpack(C.border))
            end
        end
    end

    for i, opt in ipairs(options) do
        local size = 16
        local btn = CreateFrame("Button", nil, parent, "BackdropTemplate")
        btn:SetSize(size, size)
        btn:SetPoint("TOPLEFT", x + 10, y - 6 - (i * 22))
        btn:SetBackdrop(BACKDROP_INNER)
        btn:SetBackdropColor(0.1, 0.1, 0.1, 1)
        btn:SetBackdropBorderColor(unpack(C.border))
        btn.ring = btn

        local dot = btn:CreateTexture(nil, "OVERLAY")
        dot:SetSize(size - 6, size - 6)
        dot:SetPoint("CENTER")
        dot:SetColorTexture(unpack(C.accent))
        dot:Hide()
        btn.dot = dot

        local text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        text:SetPoint("LEFT", btn, "RIGHT", 8, 0)
        text:SetText(opt.label)
        text:SetTextColor(unpack(C.text))

        btn:SetScript("OnClick", function()
            WafflemationsDB[dbKey] = opt.value
            UpdateAll()
        end)
        btn:SetScript("OnEnter", function(self)
            self:SetBackdropBorderColor(unpack(C.accent))
            text:SetTextColor(1, 1, 1)
        end)
        btn:SetScript("OnLeave", function(self)
            local selected = (WafflemationsDB[dbKey] == opt.value)
            self:SetBackdropBorderColor(selected and C.accentDim[1] or C.border[1], selected and C.accentDim[2] or C.border[2], selected and C.accentDim[3] or C.border[3], 1)
            text:SetTextColor(unpack(C.text))
        end)

        btn.optValue = opt.value
        buttons[i] = btn
    end

    UpdateAll()
    return buttons
end

-------------------------------------------------
-- Helper: Description text
-------------------------------------------------
local function CreateDescription(parent, text, y)
    local desc = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    desc:SetPoint("TOPLEFT", 16, y)
    desc:SetPoint("RIGHT", -16, 0)
    desc:SetJustifyH("LEFT")
    desc:SetSpacing(3)
    desc:SetText(text)
    desc:SetTextColor(unpack(C.textDim))
    return desc
end

-------------------------------------------------
-- Helper: Text input (ElvUI flat style)
-------------------------------------------------
local function CreateTextInput(parent, label, x, y, width, dbKey)
    local lbl = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    lbl:SetPoint("TOPLEFT", x, y)
    lbl:SetText(label)
    lbl:SetTextColor(unpack(C.label))

    local box = CreateFrame("EditBox", nil, parent, "BackdropTemplate")
    box:SetSize(width, 22)
    box:SetPoint("TOPLEFT", x, y - 16)
    box:SetBackdrop(BACKDROP_INNER)
    box:SetBackdropColor(0.06, 0.06, 0.06, 1)
    box:SetBackdropBorderColor(unpack(C.border))
    box:SetFontObject("GameFontNormalSmall")
    box:SetTextColor(unpack(C.text))
    box:SetTextInsets(6, 6, 0, 0)
    box:SetAutoFocus(false)
    box:SetMaxLetters(200)

    box:SetText(WafflemationsDB[dbKey] or "")
    box:SetScript("OnEnterPressed", function(self)
        WafflemationsDB[dbKey] = self:GetText()
        self:ClearFocus()
    end)
    box:SetScript("OnEscapePressed", function(self)
        self:SetText(WafflemationsDB[dbKey] or "")
        self:ClearFocus()
    end)
    box:SetScript("OnEditFocusLost", function(self)
        WafflemationsDB[dbKey] = self:GetText()
        self:SetBackdropBorderColor(unpack(C.border))
    end)
    box:SetScript("OnEditFocusGained", function(self)
        self:SetBackdropBorderColor(unpack(C.accent))
    end)

    return box
end

-------------------------------------------------
-- Welcome Category
-------------------------------------------------
CreateCategoryButton("About", 1)
local welcomeContent = CreateContentFrame("About", 280)

local welcomeTitle = welcomeContent:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
welcomeTitle:SetPoint("TOPLEFT", 20, -20)
welcomeTitle:SetText("Wafflemations")
welcomeTitle:SetTextColor(unpack(C.accent))

local welcomeVersion = welcomeContent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
welcomeVersion:SetPoint("TOPLEFT", 20, -42)
welcomeVersion:SetText("v1.0.0  |  Interface 12.0.1")
welcomeVersion:SetTextColor(unpack(C.textDim))

local wDivider = welcomeContent:CreateTexture(nil, "ARTWORK")
wDivider:SetHeight(1)
wDivider:SetPoint("TOPLEFT", 20, -58)
wDivider:SetPoint("RIGHT", -20, 0)
wDivider:SetColorTexture(unpack(C.borderLight))

local welcomeDesc = welcomeContent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
welcomeDesc:SetPoint("TOPLEFT", 20, -74)
welcomeDesc:SetPoint("RIGHT", -20, 0)
welcomeDesc:SetJustifyH("LEFT")
welcomeDesc:SetSpacing(5)
welcomeDesc:SetText(
    "Various gameplay automations for World of Warcraft,\n" ..
    "saving you time on repetitive tasks.\n\n" ..
    "|cff66cc66General|r  -  Cutscene skipping, Talking Head\n" ..
    "|cff66cc66Auto-Repair|r  -  Repairs gear at merchants\n" ..
    "|cff66cc66Auto-Sell|r  -  Sells gray items at vendors\n" ..
    "|cff66cc66Auto-Mail|r  -  Collects mail from your mailbox\n" ..
    "|cff66cc66Auto-Summon|r  -  Accepts summons automatically\n" ..
    "|cff66cc66Auto-Resurrect|r  -  Accepts resurrections automatically\n" ..
    "|cff66cc66Combat|r  -  Auto-hide UI elements in combat\n\n" ..
    "Select a category on the left to configure."
)
welcomeDesc:SetTextColor(unpack(C.text))

-------------------------------------------------
-- General Category
-------------------------------------------------
CreateCategoryButton("General", 2)
local generalContent = CreateContentFrame("General", 200)

local yPos = CreateSectionHeader(generalContent, "Cutscenes", -16)
CreateCheckbox(generalContent, "Auto-skip cutscenes", 16, yPos, "skipCutscenes")
CreateCheckbox(generalContent, "Only skip already-watched cutscenes", 16, yPos - 28, "skipCutscenesOnlyWatched")

CreateDescription(generalContent,
    "When 'only watched' is enabled, cutscenes play the first time and are skipped on repeat viewings.",
    yPos - 64)

yPos = yPos - 100
local thHeader = CreateSectionHeader(generalContent, "Talking Head", yPos)
CreateCheckbox(generalContent, "Hide Talking Head popups", 16, thHeader, "hideTalkingHead")

-------------------------------------------------
-- Auto-Repair Category
-------------------------------------------------
CreateCategoryButton("Auto-Repair", 3)
local repairContent = CreateContentFrame("Auto-Repair", 200)

local yPos = CreateSectionHeader(repairContent, "Auto-Repair", -16)
CreateCheckbox(repairContent, "Enable Auto-Repair", 16, yPos, "autoRepairEnabled")
CreateCheckbox(repairContent, "Show repair cost in chat", 16, yPos - 28, "autoRepairChat")

CreateRadioGroup(repairContent, 16, yPos - 72, "Repair Mode", {
    { label = "Guild first, then personal gold", value = "guild_first" },
    { label = "Personal gold only", value = "personal_only" },
}, "autoRepairMode")

-------------------------------------------------
-- Auto-Sell Category
-------------------------------------------------
CreateCategoryButton("Auto-Sell", 4)
local sellContent = CreateContentFrame("Auto-Sell", 120)

yPos = CreateSectionHeader(sellContent, "Auto-Sell", -16)
CreateCheckbox(sellContent, "Enable Auto-Sell gray items", 16, yPos, "autoSellEnabled")
CreateCheckbox(sellContent, "Show sell total in chat", 16, yPos - 28, "autoSellChat")

-------------------------------------------------
-- Auto-Mail Category
-------------------------------------------------
CreateCategoryButton("Auto-Mail", 5)
local mailContent = CreateContentFrame("Auto-Mail", 200)

yPos = CreateSectionHeader(mailContent, "Auto-Mail", -16)
CreateCheckbox(mailContent, "Enable Auto-Collect mail", 16, yPos, "autoMailEnabled")
CreateCheckbox(mailContent, "Show collected gold in chat", 16, yPos - 28, "autoMailChat")
CreateCheckbox(mailContent, "Auto-delete empty mail", 16, yPos - 56, "autoMailDeleteEmpty")

CreateDescription(mailContent,
    "Automatically collects items and gold from your mailbox when opened. COD mail is always skipped.",
    yPos - 96)

-------------------------------------------------
-- Auto-Summon Category
-------------------------------------------------
CreateCategoryButton("Auto-Summon", 6)
local summonContent = CreateContentFrame("Auto-Summon", 480)

yPos = CreateSectionHeader(summonContent, "Auto-Summon", -16)
local summonEnabledCB = CreateCheckbox(summonContent, "Enable Auto-Accept summons", 16, yPos, "autoSummonEnabled")

yPos = yPos - 40
local receiveHeader = summonContent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
receiveHeader:SetPoint("TOPLEFT", 16, yPos)
receiveHeader:SetText("Chat on Summon Received")
receiveHeader:SetTextColor(unpack(C.label))

local receiveNote = summonContent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
receiveNote:SetPoint("TOPLEFT", 16, yPos - 14)
receiveNote:SetPoint("RIGHT", -16, 0)
receiveNote:SetJustifyH("LEFT")
receiveNote:SetText("Disabled when auto-accept is on to prevent chat spam.")
receiveNote:SetTextColor(unpack(C.textDim))

local receiveLine = summonContent:CreateTexture(nil, "ARTWORK")
receiveLine:SetHeight(1)
receiveLine:SetPoint("TOPLEFT", 16, yPos - 28)
receiveLine:SetPoint("RIGHT", -16, 0)
receiveLine:SetColorTexture(unpack(C.borderLight))

local receiveChatCB = CreateCheckbox(summonContent, "Announce when summon received", 16, yPos - 40, "autoSummonChatOnReceive")

-- Link: disable receive chat checkbox when auto-accept is on
local function UpdateReceiveState()
    receiveChatCB:SetDisabled(WafflemationsDB.autoSummonEnabled)
end
summonEnabledCB.onChanged = UpdateReceiveState
UpdateReceiveState()
CreateTextInput(summonContent, "Receive Message  ({summoner} and {location} are replaced)", 16, yPos - 66, 370, "autoSummonReceiveMsg")

yPos = yPos - 112
local acceptHeader = summonContent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
acceptHeader:SetPoint("TOPLEFT", 16, yPos)
acceptHeader:SetText("Chat on Summon Accepted")
acceptHeader:SetTextColor(unpack(C.label))

local acceptLine = summonContent:CreateTexture(nil, "ARTWORK")
acceptLine:SetHeight(1)
acceptLine:SetPoint("TOPLEFT", 16, yPos - 14)
acceptLine:SetPoint("RIGHT", -16, 0)
acceptLine:SetColorTexture(unpack(C.borderLight))

CreateCheckbox(summonContent, "Announce when summon accepted", 16, yPos - 26, "autoSummonChatOnAccept")
CreateTextInput(summonContent, "Accept Message  ({summoner} and {location} are replaced)", 16, yPos - 52, 370, "autoSummonAcceptMsg")

yPos = yPos - 100
local chanHeader = summonContent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
chanHeader:SetPoint("TOPLEFT", 16, yPos)
chanHeader:SetText("Enable Chat Per Group Type")
chanHeader:SetTextColor(unpack(C.label))

local chanLine = summonContent:CreateTexture(nil, "ARTWORK")
chanLine:SetHeight(1)
chanLine:SetPoint("TOPLEFT", 16, yPos - 14)
chanLine:SetPoint("RIGHT", -16, 0)
chanLine:SetColorTexture(unpack(C.borderLight))

CreateCheckbox(summonContent, "Party", 16, yPos - 26, "autoSummonChatParty")
CreateCheckbox(summonContent, "Raid", 16, yPos - 54, "autoSummonChatRaid")
CreateCheckbox(summonContent, "Instance (LFG/LFR)", 16, yPos - 82, "autoSummonChatInstance")

-------------------------------------------------
-- Auto-Resurrect Category
-------------------------------------------------
CreateCategoryButton("Auto-Resurrect", 7)
local resContent = CreateContentFrame("Auto-Resurrect", 420)

yPos = CreateSectionHeader(resContent, "Auto-Resurrect", -16)
CreateCheckbox(resContent, "Auto-accept out-of-combat resurrections", 16, yPos, "autoResOOCEnabled")
CreateCheckbox(resContent, "Auto-accept combat resurrections", 16, yPos - 28, "autoResCombatEnabled")

yPos = yPos - 72
local resChatHeader = resContent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
resChatHeader:SetPoint("TOPLEFT", 16, yPos)
resChatHeader:SetText("Chat on Resurrection Accepted")
resChatHeader:SetTextColor(unpack(C.label))

local resChatLine = resContent:CreateTexture(nil, "ARTWORK")
resChatLine:SetHeight(1)
resChatLine:SetPoint("TOPLEFT", 16, yPos - 14)
resChatLine:SetPoint("RIGHT", -16, 0)
resChatLine:SetColorTexture(unpack(C.borderLight))

CreateCheckbox(resContent, "Announce when resurrection accepted", 16, yPos - 26, "autoResChatOnAccept")
CreateTextInput(resContent, "Accept Message  ({caster} is replaced)", 16, yPos - 52, 370, "autoResAcceptMsg")

yPos = yPos - 100
local resChanHeader = resContent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
resChanHeader:SetPoint("TOPLEFT", 16, yPos)
resChanHeader:SetText("Enable Chat Per Group Type")
resChanHeader:SetTextColor(unpack(C.label))

local resChanLine = resContent:CreateTexture(nil, "ARTWORK")
resChanLine:SetHeight(1)
resChanLine:SetPoint("TOPLEFT", 16, yPos - 14)
resChanLine:SetPoint("RIGHT", -16, 0)
resChanLine:SetColorTexture(unpack(C.borderLight))

CreateCheckbox(resContent, "Party", 16, yPos - 26, "autoResChatParty")
CreateCheckbox(resContent, "Raid", 16, yPos - 54, "autoResChatRaid")
CreateCheckbox(resContent, "Instance (LFG/LFR)", 16, yPos - 82, "autoResChatInstance")

-------------------------------------------------
-- Combat Category
-------------------------------------------------
CreateCategoryButton("Combat", 8)
local combatContent = CreateContentFrame("Combat", 140)

yPos = CreateSectionHeader(combatContent, "Combat", -16)
CreateCheckbox(combatContent, "Auto-hide World Map on combat start", 16, yPos, "combatHideMap")
CreateCheckbox(combatContent, "Auto-close bags on combat start", 16, yPos - 28, "combatHideBags")

CreateDescription(combatContent,
    "Automatically closes these UI panels when you enter combat to keep your screen clear.",
    yPos - 68)

-------------------------------------------------
-- Select default category
-------------------------------------------------
SelectCategory("About")

-------------------------------------------------
-- Toggle function
-------------------------------------------------
function Wafflemations.ToggleOptions()
    if optionsFrame:IsShown() then
        optionsFrame:Hide()
    else
        optionsFrame:Show()
    end
end
