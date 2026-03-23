-- WaffleOptions Options Panel (ElvUI-inspired, polished)

-------------------------------------------------
-- Layout Constants
-------------------------------------------------
local PANEL_WIDTH   = 680
local PANEL_HEIGHT  = 700
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
local optionsFrame = CreateFrame("Frame", "WaffleOptionsFrame", UIParent, "BackdropTemplate")
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

-- Close on Escape without tainting UISpecialFrames
optionsFrame:SetScript("OnKeyDown", function(self, key)
    if key == "ESCAPE" then
        self:SetPropagateKeyboardInput(false)
        self:Hide()
    else
        self:SetPropagateKeyboardInput(true)
    end
end)
optionsFrame:SetPropagateKeyboardInput(true)

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
titleText:SetText("WAFFLEOPTIONS")
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
-- Category System (collapsible sections)
-------------------------------------------------
local categories = {}
local contentFrames = {}
local selectedCategory = nil
local sidebarItems = {}      -- ordered list: {type, name, frame, section}
local activeDropdowns = {}   -- track open dropdown lists

local function CloseAllDropdowns()
    for _, dd in ipairs(activeDropdowns) do
        dd:Hide()
    end
end

local function SelectCategory(name)
    CloseAllDropdowns()
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

local function LayoutSidebar()
    local y = -6
    for _, item in ipairs(sidebarItems) do
        if item.type == "divider" then
            item.frame:ClearAllPoints()
            item.frame:SetPoint("TOPLEFT", 10, y + 2)
            y = y - 8
        elseif item.type == "header" then
            item.frame:ClearAllPoints()
            item.frame:SetPoint("TOPLEFT", 5, y)
            item.frame:SetPoint("RIGHT", sidebar, "RIGHT", -5, 0)
            y = y - SIDEBAR_PITCH
        elseif item.type == "item" then
            item.frame:ClearAllPoints()
            item.frame:SetPoint("TOPLEFT", 5, y)
            item.frame:SetPoint("RIGHT", sidebar, "RIGHT", -5, 0)
            y = y - SIDEBAR_PITCH
        end
    end
end

local function CreateSidebarSection(name)
    local f = CreateFrame("Frame", nil, sidebar)
    f:SetHeight(28)

    local lbl = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    lbl:SetPoint("LEFT", 8, 0)
    lbl:SetText(name)
    lbl:SetTextColor(unpack(C.label))

    tinsert(sidebarItems, { type = "header", name = name, frame = f })
    return f
end

local function CreateCategoryButton(name, section)
    local btn = CreateFrame("Button", nil, sidebar)
    btn:SetHeight(28)

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

    local indent = section and 20 or 12
    local lbl = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    lbl:SetPoint("LEFT", indent, 0)
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
    tinsert(sidebarItems, { type = "item", name = name, frame = btn, section = section })
    return btn
end

local function CreateSidebarDivider()
    local line = sidebar:CreateTexture(nil, "ARTWORK")
    line:SetHeight(1)
    line:SetPoint("RIGHT", sidebar, "RIGHT", -10, 0)
    line:SetColorTexture(unpack(C.borderLight))
    tinsert(sidebarItems, { type = "divider", frame = line })
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
        if WaffleOptionsDB[dbKey] then
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
        WaffleOptionsDB[dbKey] = not WaffleOptionsDB[dbKey]
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
            local sel = (WaffleOptionsDB[dbKey] == b.optValue)
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

        btn:SetScript("OnClick", function() WaffleOptionsDB[dbKey] = opt.value; UpdateAll() end)
        btn:SetScript("OnEnter", function(self) self:SetBackdropBorderColor(unpack(C.accent)); t:SetTextColor(unpack(C.textBright)) end)
        btn:SetScript("OnLeave", function(self)
            local sel = (WaffleOptionsDB[dbKey] == opt.value)
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

    box:SetText(WaffleOptionsDB[dbKey] or "")
    box:SetScript("OnEnterPressed", function(self) WaffleOptionsDB[dbKey] = self:GetText(); self:ClearFocus() end)
    box:SetScript("OnEscapePressed", function(self) self:SetText(WaffleOptionsDB[dbKey] or ""); self:ClearFocus() end)
    box:SetScript("OnEditFocusLost", function(self) WaffleOptionsDB[dbKey] = self:GetText(); self:SetBackdropBorderColor(unpack(C.border)) end)
    box:SetScript("OnEditFocusGained", function(self) self:SetBackdropBorderColor(unpack(C.accent)) end)

    return box, y - 46
end

-------------------------------------------------
-- Helper: Editable string list (add/remove items)
-------------------------------------------------
local function CreateStringList(parent, label, y, dbKey)
    local lbl = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    lbl:SetPoint("TOPLEFT", PAD, y)
    lbl:SetText(label)
    lbl:SetTextColor(unpack(C.label))

    local listContainer = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    listContainer:SetPoint("TOPLEFT", PAD, y - 16)
    listContainer:SetSize(390, 120)
    listContainer:SetBackdrop(BACKDROP)
    listContainer:SetBackdropColor(0.04, 0.04, 0.04, 1)
    listContainer:SetBackdropBorderColor(unpack(C.border))

    -- Scroll frame for list items
    local listScroll = CreateFrame("ScrollFrame", nil, listContainer)
    listScroll:SetPoint("TOPLEFT", 2, -2)
    listScroll:SetPoint("BOTTOMRIGHT", -10, 2)
    listScroll:EnableMouseWheel(true)

    local listContent = CreateFrame("Frame", nil, listScroll)
    listContent:SetWidth(378)
    listContent:SetHeight(1)
    listScroll:SetScrollChild(listContent)

    -- Scrollbar
    local lsBar = CreateFrame("Slider", nil, listContainer, "BackdropTemplate")
    lsBar:SetWidth(5)
    lsBar:SetPoint("TOPRIGHT", -3, -3)
    lsBar:SetPoint("BOTTOMRIGHT", -3, 3)
    lsBar:SetBackdrop(BACKDROP)
    lsBar:SetBackdropColor(0.035, 0.035, 0.035, 1)
    lsBar:SetBackdropBorderColor(unpack(C.border))
    lsBar:SetMinMaxValues(0, 1)
    lsBar:SetValue(0)
    lsBar:SetValueStep(1)
    lsBar:SetObeyStepOnDrag(true)

    local lsThumb = lsBar:CreateTexture(nil, "OVERLAY")
    lsThumb:SetColorTexture(unpack(C.accentDim))
    lsThumb:SetSize(5, 30)
    lsBar:SetThumbTexture(lsThumb)

    lsBar:SetScript("OnValueChanged", function(_, val)
        listScroll:SetVerticalScroll(val)
    end)

    local function UpdateListScrollbar()
        local contentH = listContent:GetHeight()
        local viewH = listScroll:GetHeight()
        local maxS = math.max(0, contentH - viewH)
        lsBar:SetMinMaxValues(0, maxS)
        lsBar:SetShown(maxS > 0)
        if contentH > 0 and viewH > 0 and contentH > viewH then
            local track = lsBar:GetHeight()
            lsThumb:SetHeight(math.max(20, track * (viewH / contentH)))
        end
    end

    listScroll:SetScript("OnMouseWheel", function(_, delta)
        local cur = lsBar:GetValue()
        local lo, hi = lsBar:GetMinMaxValues()
        lsBar:SetValue(math.max(lo, math.min(hi, cur - delta * 22)))
    end)

    local ITEM_H = 22
    local items = {}

    local function Rebuild()
        for _, row in ipairs(items) do row:Hide() end
        wipe(items)
        local msgs = WaffleOptionsDB[dbKey] or {}
        for i, msg in ipairs(msgs) do
            local row = CreateFrame("Frame", nil, listContent)
            row:SetHeight(ITEM_H)
            row:SetPoint("TOPLEFT", 0, -(i - 1) * ITEM_H)
            row:SetPoint("RIGHT", listContent, "RIGHT", 0, 0)

            local rowBg = row:CreateTexture(nil, "BACKGROUND")
            rowBg:SetAllPoints()
            rowBg:SetColorTexture(0, 0, 0, 0)

            local rowText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            rowText:SetPoint("LEFT", 8, 0)
            rowText:SetPoint("RIGHT", row, "RIGHT", -26, 0)
            rowText:SetJustifyH("LEFT")
            rowText:SetText(msg)
            rowText:SetTextColor(unpack(C.text))

            -- Remove button
            local removeBtn = CreateFrame("Button", nil, row)
            removeBtn:SetSize(18, 18)
            removeBtn:SetPoint("RIGHT", -4, 0)
            local removeTxt = removeBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            removeTxt:SetPoint("CENTER")
            removeTxt:SetText("|cffaa3333x|r")

            removeBtn:SetScript("OnEnter", function()
                removeTxt:SetText("|cffff4444x|r")
                rowBg:SetColorTexture(0.15, 0.05, 0.05, 0.5)
            end)
            removeBtn:SetScript("OnLeave", function()
                removeTxt:SetText("|cffaa3333x|r")
                rowBg:SetColorTexture(0, 0, 0, 0)
            end)
            removeBtn:SetScript("OnClick", function()
                tremove(WaffleOptionsDB[dbKey], i)
                Rebuild()
            end)

            row:SetScript("OnEnter", function() rowBg:SetColorTexture(unpack(C.catHover)) end)
            row:SetScript("OnLeave", function() rowBg:SetColorTexture(0, 0, 0, 0) end)

            tinsert(items, row)
        end
        listContent:SetHeight(math.max(1, #msgs * ITEM_H))
        lsBar:SetValue(0)
        C_Timer.After(0, UpdateListScrollbar)
    end

    -- Add input row
    local addBox = CreateFrame("EditBox", nil, parent, "BackdropTemplate")
    addBox:SetSize(340, 24)
    addBox:SetPoint("TOPLEFT", listContainer, "BOTTOMLEFT", 0, -4)
    addBox:SetBackdrop(BACKDROP)
    addBox:SetBackdropColor(0.05, 0.05, 0.05, 1)
    addBox:SetBackdropBorderColor(unpack(C.border))
    addBox:SetFontObject("GameFontNormalSmall")
    addBox:SetTextColor(unpack(C.text))
    addBox:SetTextInsets(8, 8, 0, 0)
    addBox:SetAutoFocus(false)
    addBox:SetMaxLetters(200)

    local addBtn = CreateFrame("Button", nil, parent, "BackdropTemplate")
    addBtn:SetSize(46, 24)
    addBtn:SetPoint("LEFT", addBox, "RIGHT", 4, 0)
    addBtn:SetBackdrop(BACKDROP)
    addBtn:SetBackdropColor(0.1, 0.1, 0.1, 1)
    addBtn:SetBackdropBorderColor(unpack(C.border))

    local addBtnText = addBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    addBtnText:SetPoint("CENTER")
    addBtnText:SetText("Add")
    addBtnText:SetTextColor(unpack(C.accent))

    addBtn:SetScript("OnEnter", function(self) self:SetBackdropBorderColor(unpack(C.accent)) end)
    addBtn:SetScript("OnLeave", function(self) self:SetBackdropBorderColor(unpack(C.border)) end)

    local function DoAdd()
        local txt = addBox:GetText()
        if txt and txt:trim() ~= "" then
            if not WaffleOptionsDB[dbKey] then WaffleOptionsDB[dbKey] = {} end
            tinsert(WaffleOptionsDB[dbKey], txt:trim())
            addBox:SetText("")
            Rebuild()
        end
        addBox:ClearFocus()
    end

    addBtn:SetScript("OnClick", DoAdd)
    addBox:SetScript("OnEnterPressed", DoAdd)
    addBox:SetScript("OnEscapePressed", function(self) self:SetText(""); self:ClearFocus() end)
    addBox:SetScript("OnEditFocusGained", function(self) self:SetBackdropBorderColor(unpack(C.accent)) end)
    addBox:SetScript("OnEditFocusLost", function(self) self:SetBackdropBorderColor(unpack(C.border)) end)

    parent:HookScript("OnShow", Rebuild)
    Rebuild()

    -- Total height: label(16) + list(120) + gap(4) + addRow(24) = 164
    return listContainer, y - 164
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
-- General alerts
AddSound("RAID_WARNING",           "Raid Warning")
AddSound("READY_CHECK",            "Ready Check")
AddSound("ALARM_CLOCK_WARNING_3",  "Alarm Clock")
AddSound("PVP_THROUGH_QUEUE",      "Queue Ready")
AddSound("MAP_PING",               "Map Ping")
AddSound("GM_CHAT_WARNING",        "GM Warning")
-- Progression
AddSound("LEVEL_UP",               "Level Up")
AddSound("UI_70_BOOST_THANKSFORPLAYING_SMALLER", "Quest Complete Fanfare")
-- Loot & rewards
AddSound("UI_EPICLOOT_TOAST",      "Epic Loot Toast")
AddSound("UI_LEGENDARY_LOOT_TOAST", "Legendary Loot Toast")
AddSound("UI_RAID_LOOT_TOAST_LESSER_ITEM_WON", "Raid Loot Won")
AddSound("UI_WARFORGED_ITEM_LOOT_TOAST", "Warforged Loot Toast")
-- Boss & combat
AddSound("UI_RAID_BOSS_WHISPER",   "Boss Whisper")
AddSound("UI_RAID_BOSS_DEFEATED",  "Boss Defeated")
-- PvP
AddSound("PVP_FLAG_TAKEN_HORDE",   "PvP Flag Taken (Horde)")
AddSound("PVP_FLAG_TAKEN_ALLIANCE","PvP Flag Taken (Alliance)")
AddSound("BATTLEGROUND_WARNING",   "Battleground Warning")
-- UI & misc
AddSound("TELL_MESSAGE",           "Whisper Received")
AddSound("UI_BONUS_EVENT_SYSTEM_VIGNETTES", "Bonus Event / Vignette")
AddSound("LFG_DENIED",             "LFG Denied")
AddSound("UI_GROUP_FINDER_RECEIVE_APPLICATION", "Group Finder Application")
AddSound("UI_SCENARIO_STAGE_END",  "Scenario Stage End")
AddSound("UI_QUEST_ROLLING_FORWARD_01", "Quest Rolling")
AddSound("AUCTION_WINDOW_OPEN",    "Auction House Open")
AddSound("UI_PET_BATTLES_TRAP_READY", "Pet Battle Trap Ready")
AddSound("UI_GARRISON_TOAST",      "Garrison Toast")
-- Named / iconic sounds by ID
tinsert(ALERT_SOUNDS, { id = 11466, name = "You Are Not Prepared (Illidan)" })
tinsert(ALERT_SOUNDS, { id = 15391, name = "Algalon - Beware" })
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

    local dropArrow = dropBtn:CreateTexture(nil, "OVERLAY")
    dropArrow:SetSize(16, 16)
    dropArrow:SetPoint("RIGHT", -4, 0)
    dropArrow:SetTexture(-1985)
    dropArrow:SetRotation(math.pi)
    dropArrow:SetVertexColor(0.78, 0.78, 0.78, 1)

    -- Play preview button
    local playBtn = CreateFrame("Button", nil, parent, "BackdropTemplate")
    playBtn:SetSize(28, 24)
    playBtn:SetPoint("LEFT", dropBtn, "RIGHT", 6, 0)
    playBtn:SetBackdrop(BACKDROP)
    playBtn:SetBackdropColor(0.1, 0.1, 0.1, 1)
    playBtn:SetBackdropBorderColor(unpack(C.border))

    local playIcon = playBtn:CreateTexture(nil, "ARTWORK")
    playIcon:SetSize(16, 16)
    playIcon:SetPoint("CENTER")
    playIcon:SetAtlas("chatframe-button-icon-voicechat")

    playBtn:SetScript("OnEnter", function(self)
        self:SetBackdropBorderColor(unpack(C.accent))
        playIcon:SetAtlas("chatframe-button-icon-voicechat-on")
    end)
    playBtn:SetScript("OnLeave", function(self)
        self:SetBackdropBorderColor(unpack(C.border))
        playIcon:SetAtlas("chatframe-button-icon-voicechat")
    end)
    playBtn:SetScript("OnClick", function()
        PlaySound(WaffleOptionsDB[dbKey] or 11466, "Master")
    end)

    local LIST_ITEM_H = 22
    local MAX_VISIBLE = 14
    local listH = math.min(#ALERT_SOUNDS, MAX_VISIBLE) * LIST_ITEM_H + 4

    local listFrame = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    listFrame:SetSize(300, listH)
    listFrame:SetBackdrop(BACKDROP)
    listFrame:SetBackdropColor(0.04, 0.04, 0.04, 0.98)
    listFrame:SetBackdropBorderColor(unpack(C.border))
    listFrame:SetFrameStrata("TOOLTIP")
    listFrame:SetFrameLevel(100)
    listFrame:Hide()
    listFrame:SetClampedToScreen(true)
    tinsert(activeDropdowns, listFrame)

    -- Scroll frame inside dropdown
    local listScroll = CreateFrame("ScrollFrame", nil, listFrame)
    listScroll:SetPoint("TOPLEFT", 2, -2)
    listScroll:SetPoint("BOTTOMRIGHT", -10, 2)
    listScroll:EnableMouseWheel(true)

    local listContent = CreateFrame("Frame", nil, listScroll)
    listContent:SetWidth(288)
    listContent:SetHeight(#ALERT_SOUNDS * LIST_ITEM_H)
    listScroll:SetScrollChild(listContent)

    -- Scrollbar
    local listScrollBar = CreateFrame("Slider", nil, listFrame, "BackdropTemplate")
    listScrollBar:SetWidth(5)
    listScrollBar:SetPoint("TOPRIGHT", -3, -3)
    listScrollBar:SetPoint("BOTTOMRIGHT", -3, 3)
    listScrollBar:SetBackdrop(BACKDROP)
    listScrollBar:SetBackdropColor(0.035, 0.035, 0.035, 1)
    listScrollBar:SetBackdropBorderColor(unpack(C.border))
    listScrollBar:SetMinMaxValues(0, 1)
    listScrollBar:SetValue(0)
    listScrollBar:SetValueStep(1)
    listScrollBar:SetObeyStepOnDrag(true)

    local listScrollThumb = listScrollBar:CreateTexture(nil, "OVERLAY")
    listScrollThumb:SetColorTexture(unpack(C.accentDim))
    listScrollThumb:SetSize(5, 30)
    listScrollBar:SetThumbTexture(listScrollThumb)

    listScrollBar:SetScript("OnValueChanged", function(_, val)
        listScroll:SetVerticalScroll(val)
    end)

    local function UpdateListScroll()
        local contentH = #ALERT_SOUNDS * LIST_ITEM_H
        local viewH = listScroll:GetHeight()
        local maxS = math.max(0, contentH - viewH)
        listScrollBar:SetMinMaxValues(0, maxS)
        listScrollBar:SetShown(maxS > 0)
        if contentH > 0 and viewH > 0 and contentH > viewH then
            local track = listScrollBar:GetHeight()
            listScrollThumb:SetHeight(math.max(20, track * (viewH / contentH)))
        end
    end

    listFrame:SetScript("OnShow", function()
        listScroll:SetVerticalScroll(0)
        listScrollBar:SetValue(0)
        C_Timer.After(0, UpdateListScroll)
    end)

    listScroll:SetScript("OnMouseWheel", function(_, delta)
        local cur = listScrollBar:GetValue()
        local lo, hi = listScrollBar:GetMinMaxValues()
        listScrollBar:SetValue(math.max(lo, math.min(hi, cur - delta * LIST_ITEM_H * 3)))
    end)

    local function UpdateDisplay()
        local currentID = WaffleOptionsDB[dbKey] or 11466
        for _, s in ipairs(ALERT_SOUNDS) do
            if s.id == currentID then
                dropText:SetText(s.name)
                return
            end
        end
        dropText:SetText("Sound #" .. currentID)
    end

    for i, sound in ipairs(ALERT_SOUNDS) do
        local item = CreateFrame("Button", nil, listContent)
        item:SetHeight(LIST_ITEM_H)
        item:SetPoint("TOPLEFT", 0, -(i - 1) * LIST_ITEM_H)
        item:SetPoint("RIGHT", listContent, "RIGHT", 0, 0)

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

        local itemPlayIcon = itemPlay:CreateTexture(nil, "ARTWORK")
        itemPlayIcon:SetSize(14, 14)
        itemPlayIcon:SetPoint("CENTER")
        itemPlayIcon:SetAtlas("chatframe-button-icon-voicechat")

        itemPlay:SetScript("OnClick", function()
            PlaySound(sound.id, "Master")
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
            WaffleOptionsDB[dbKey] = sound.id
            UpdateDisplay()
            listFrame:Hide()
        end)
    end

    dropBtn:SetScript("OnClick", function()
        if listFrame:IsShown() then
            listFrame:Hide()
        else
            CloseAllDropdowns()
            listFrame:ClearAllPoints()
            listFrame:SetPoint("TOPLEFT", dropBtn, "BOTTOMLEFT", 0, -2)
            listFrame:Show()
        end
    end)
    dropBtn:SetScript("OnEnter", function(self) self:SetBackdropBorderColor(unpack(C.accent)) end)
    dropBtn:SetScript("OnLeave", function(self)
        if not listFrame:IsShown() then self:SetBackdropBorderColor(unpack(C.border)) end
    end)
    listFrame:HookScript("OnHide", function() dropBtn:SetBackdropBorderColor(unpack(C.border)) end)
    optionsFrame:HookScript("OnHide", function() listFrame:Hide() end)

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
CreateCategoryButton("About", nil)
CreateSidebarDivider()
local aboutContent = CreateContentFrame("About", 610)

local aboutTitle = aboutContent:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
aboutTitle:SetPoint("TOP", 0, -24)
aboutTitle:SetText("WaffleOptions")
aboutTitle:SetTextColor(unpack(C.accent))

local aboutVer = aboutContent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
aboutVer:SetPoint("TOP", aboutTitle, "BOTTOM", 0, -6)
aboutVer:SetText("@project-version@  |  Interface 12.0.1  |  by Waffle Taco")
aboutVer:SetTextColor(unpack(C.textDim))

local aboutLogo = aboutContent:CreateTexture(nil, "ARTWORK")
aboutLogo:SetSize(128, 128)
aboutLogo:SetPoint("TOP", aboutVer, "BOTTOM", 0, -14)
aboutLogo:SetTexture("Interface\\AddOns\\WaffleOptions\\WaffleOptions")
aboutLogo:SetTexCoord(0.05, 0.95, 0.05, 0.95)

local aboutDesc = aboutContent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
aboutDesc:SetPoint("TOP", aboutLogo, "BOTTOM", 0, -14)
aboutDesc:SetWidth(PANEL_WIDTH - SIDEBAR_WIDTH - PAD * 2 - 30)
aboutDesc:SetJustifyH("CENTER")
aboutDesc:SetWordWrap(true)
aboutDesc:SetText("WaffleOptions is a lightweight gameplay automation addon for World of Warcraft. It handles the repetitive tasks you do every session — repairing gear, selling junk, collecting mail, accepting summons and resurrections, turning in quests, and more. It also provides helpful reminders for dungeons and raids like spec checks, buff warnings, key results, and interrupt announcements. Every feature is independently toggleable with customizable messages, sounds, and channels.")
aboutDesc:SetTextColor(unpack(C.text))
aboutDesc:SetSpacing(2)

local discordLabel = aboutContent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
discordLabel:SetPoint("TOP", aboutDesc, "BOTTOM", 0, -16)
discordLabel:SetText("Discord: |cff5865F2discord.gg/CHay7xDM6m|r")
discordLabel:SetTextColor(unpack(C.textDim))

local discordURL = "https://discord.gg/CHay7xDM6m"
local discordBox = CreateFrame("EditBox", nil, aboutContent, "InputBoxTemplate")
discordBox:SetSize(220, 20)
discordBox:SetPoint("TOP", discordLabel, "BOTTOM", 0, -6)
discordBox:SetAutoFocus(false)
discordBox:SetText(discordURL)
discordBox:SetCursorPosition(0)
discordBox:SetScript("OnTextChanged", function(self) self:SetText(discordURL) self:SetCursorPosition(0) end)
discordBox:SetScript("OnEditFocusGained", function(self) self:HighlightText() end)
discordBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)

local aboutHint = aboutContent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
aboutHint:SetPoint("TOP", discordBox, "BOTTOM", 0, -14)
aboutHint:SetText("Select a category on the left to configure.")
aboutHint:SetTextColor(unpack(C.textDim))

do
    local loginCB = CreateCheckbox(aboutContent, "Show login message", 0, "showLoginMessage")
    loginCB:ClearAllPoints()
    loginCB:SetPoint("BOTTOMLEFT", PAD, 14)
end

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
    for k, v in pairs(WaffleOptions.defaults) do
        WaffleOptionsDB[k] = v
    end
    confirmOverlay:Hide()
    print("|cff88cc88[WaffleOptions]|r All settings have been reset to defaults.")
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
-- General Section
-------------------------------------------------
CreateSidebarSection("General")

do -- Interface
    CreateCategoryButton("Interface", "General")
    local f = CreateContentFrame("Interface", 340)
    local y = CreateSectionHeader(f, "Cutscenes", -PAD)
    local skipCB, y = CreateCheckbox(f, "Auto-skip cutscenes", y, "skipCutscenes")
    local onlyWatchedCB, y = CreateCheckbox(f, "Only skip already-watched cutscenes", y, "skipCutscenesOnlyWatched", SUB_PAD)
    local function Update() onlyWatchedCB:SetDisabled(not WaffleOptionsDB.skipCutscenes) end
    skipCB.onChanged = Update
    f:HookScript("OnShow", Update)
    CreateDescription(f, "When 'only watched' is enabled, cutscenes play once then auto-skip on repeat viewings.", y - 4)
    y = y - 36
    y = CreateSectionHeader(f, "Talking Head", y)
    local _, y = CreateCheckbox(f, "Hide Talking Head popups", y, "hideTalkingHead")
    y = y - SEC_GAP
    y = CreateSectionHeader(f, "Combat", y)
    local _, y = CreateCheckbox(f, "Auto-hide World Map on combat start", y, "combatHideMap")
    local _, y = CreateCheckbox(f, "Auto-close bags on combat start", y, "combatHideBags")
    CreateDescription(f, "Automatically closes these UI panels when you enter combat to keep your screen clear.", y - 4)
end

do -- Repair & Sell
    CreateCategoryButton("Repair & Sell", "General")
    local f = CreateContentFrame("Repair & Sell", 540)
    local y = CreateSectionHeader(f, "Auto-Repair", -PAD)
    local repairCB, y = CreateCheckbox(f, "Enable Auto-Repair", y, "autoRepairEnabled")
    local repairChat, y = CreateCheckbox(f, "Show repair cost in chat", y, "autoRepairChat", SUB_PAD)
    local function UR() repairChat:SetDisabled(not WaffleOptionsDB.autoRepairEnabled) end
    repairCB.onChanged = UR; f:HookScript("OnShow", UR)
    y = y - SEC_GAP
    local _, y = CreateRadioGroup(f, y, "Repair Mode", {
        { label = "Guild first, then personal gold", value = "guild_first" },
        { label = "Personal gold only", value = "personal_only" },
    }, "autoRepairMode")
    y = y - SEC_GAP * 2
    y = CreateSectionHeader(f, "Auto-Sell", y)
    local sellCB, y = CreateCheckbox(f, "Enable Auto-Sell gray items", y, "autoSellEnabled")
    local sellChat = CreateCheckbox(f, "Show sell total in chat", y, "autoSellChat", SUB_PAD)
    local function US() sellChat:SetDisabled(not WaffleOptionsDB.autoSellEnabled) end
    sellCB.onChanged = US; f:HookScript("OnShow", US)
    y = y - CB_H - SEC_GAP * 2
    y = CreateSectionHeader(f, "Loot Confirmations", y)
    local _, y = CreateCheckbox(f, "Auto-confirm loot roll and BoP dialogs", y, "autoConfirmLoot")
    CreateDescription(f, "Automatically confirms Need/Greed roll dialogs and Bind-on-Pickup prompts.", y - 4)
    y = y - 36
    y = CreateSectionHeader(f, "Delete Confirmation", y)
    local _, y = CreateCheckbox(f, "Auto-fill DELETE text in delete dialogs", y, "autoFillDelete")
    CreateDescription(f, "Fills in the DELETE text automatically so you only need to click the confirm button.", y - 4)
end

do -- Mail
    CreateCategoryButton("Mail", "General")
    local f = CreateContentFrame("Mail", 220)
    local y = CreateSectionHeader(f, "Auto-Collect Mail", -PAD)
    local _, y = CreateCheckbox(f, "Enable Auto-Collect mail", y, "autoMailEnabled")
    local _, y = CreateCheckbox(f, "Show collected gold in chat", y, "autoMailChat")
    local _, y = CreateCheckbox(f, "Auto-delete empty mail", y, "autoMailDeleteEmpty")
    CreateDescription(f, "Automatically collects items and gold from your mailbox when opened. COD mail is always skipped.", y - 6)
end

do -- Summon
    CreateCategoryButton("Summon", "General")
    local f = CreateContentFrame("Summon", 520)
    local y = CreateSectionHeader(f, "Auto-Summon", -PAD)
    local enableCB, y = CreateCheckbox(f, "Enable Auto-Accept summons", y, "autoSummonEnabled")
    y = y - SEC_GAP
    y = CreateSubHeader(f, "Chat on Summon Received", y)
    CreateDescription(f, "Disabled when auto-accept is on to prevent chat spam.", y)
    y = y - 16
    local receiveCB, y = CreateCheckbox(f, "Announce when summon received", y, "autoSummonChatOnReceive")
    local _, y = CreateTextInput(f, "Receive Message  ({summoner} and {location} are replaced)", y - 4, 390, "autoSummonReceiveMsg")
    local function UR() receiveCB:SetDisabled(WaffleOptionsDB.autoSummonEnabled) end
    enableCB.onChanged = UR; f:HookScript("OnShow", UR)
    y = y - SEC_GAP
    y = CreateSubHeader(f, "Chat on Summon Accepted", y)
    local _, y = CreateCheckbox(f, "Announce when summon accepted", y, "autoSummonChatOnAccept")
    local _, y = CreateTextInput(f, "Accept Message  ({summoner} and {location} are replaced)", y - 4, 390, "autoSummonAcceptMsg")
    y = y - SEC_GAP
    y = CreateSubHeader(f, "Enable Chat Per Group Type", y)
    local _, y = CreateCheckbox(f, "Party", y, "autoSummonChatParty")
    local _, y = CreateCheckbox(f, "Raid", y, "autoSummonChatRaid")
    CreateCheckbox(f, "Instance (LFG/LFR)", y, "autoSummonChatInstance")
end

do -- Resurrect
    CreateCategoryButton("Resurrect", "General")
    local f = CreateContentFrame("Resurrect", 610)
    local y = CreateSectionHeader(f, "Auto-Release Spirit", -PAD)
    local _, y = CreateCheckbox(f, "Enable Auto-Release on death", y, "autoReleaseEnabled")
    local _, y = CreateTextInput(f, "Delay (seconds)", y - 4, 120, "autoReleaseDelay")
    CreateDescription(f, "Automatically releases your spirit on death in the open world only. Does not trigger in dungeons, raids, or PvP instances.", y - 4)
    y = y - 36
    y = CreateSectionHeader(f, "Auto-Resurrect", y)
    local _, y = CreateCheckbox(f, "Auto-accept out-of-combat resurrections", y, "autoResOOCEnabled")
    local _, y = CreateCheckbox(f, "Auto-accept combat resurrections", y, "autoResCombatEnabled")
    y = y - SEC_GAP
    y = CreateSubHeader(f, "Chat on Resurrection Accepted", y)
    local _, y = CreateCheckbox(f, "Announce when resurrection accepted", y, "autoResChatOnAccept")
    local _, y = CreateTextInput(f, "Accept Message  ({caster} is replaced)", y - 4, 390, "autoResAcceptMsg")
    y = y - SEC_GAP
    y = CreateSubHeader(f, "Enable Chat Per Group Type", y)
    local _, y = CreateCheckbox(f, "Party", y, "autoResChatParty")
    local _, y = CreateCheckbox(f, "Raid", y, "autoResChatRaid")
    local _, y = CreateCheckbox(f, "Instance (LFG/LFR)", y, "autoResChatInstance")
    y = y - SEC_GAP * 2
    y = CreateSectionHeader(f, "Combat Res Tracker", y)
    local _, y = CreateCheckbox(f, "Announce combat resurrections in group", y, "dungeonCombatResTracker")
    y = y - SEC_GAP
    CreateRadioGroup(f, y, "Tracker Channel", {
        { label = "Print (local chat only)", value = "print" },
        { label = "Emote", value = "emote" },
        { label = "Party / Raid / Instance", value = "group" },
    }, "dungeonCombatResChannel")
end

do -- Party
    CreateCategoryButton("Party", "General")
    local f = CreateContentFrame("Party", 620)
    local y = CreateSectionHeader(f, "Auto-Accept Party Invites", -PAD)
    local enableCB, y = CreateCheckbox(f, "Enable Auto-Accept party invites", y, "autoPartyEnabled")
    local friendsCB, y = CreateCheckbox(f, "Accept from friends", y, "autoPartyFriends", SUB_PAD)
    local guildCB, y = CreateCheckbox(f, "Accept from guildmates", y, "autoPartyGuild", SUB_PAD)
    local function U()
        local off = not WaffleOptionsDB.autoPartyEnabled
        friendsCB:SetDisabled(off); guildCB:SetDisabled(off)
    end
    enableCB.onChanged = U; f:HookScript("OnShow", U)
    CreateDescription(f, "Automatically accepts party invites from friends and/or guildmates. May not work in all contexts due to WoW security restrictions.", y - 4)

    y = y - 36
    y = CreateSectionHeader(f, "Greet on Join", y)
    local _, y = CreateCheckbox(f, "Send a greeting when I join a group", y, "partyGreetOnJoin")
    local _, y = CreateStringList(f, "Greetings (one is chosen at random)", y - 4, "partyGreetOnJoinMessages")

    y = y - SEC_GAP * 2
    y = CreateSectionHeader(f, "Greet New Members", y)
    local _, y = CreateCheckbox(f, "Send a greeting when someone joins my group", y, "partyGreetOnMemberJoin")
    CreateStringList(f, "Greetings (one is chosen at random, {player} = their name)", y - 4, "partyGreetOnMemberJoinMessages")
end

do -- Quests
    CreateCategoryButton("Quests", "General")
    local f = CreateContentFrame("Quests", 380)
    local y = CreateSectionHeader(f, "Auto-Quest", -PAD)
    local acceptCB, y = CreateCheckbox(f, "Auto-accept quests", y, "autoQuestAccept")
    local repeatCB, y = CreateCheckbox(f, "Include repeatable quests (dailies/weeklies)", y, "autoQuestRepeatables", SUB_PAD)
    local _, y = CreateCheckbox(f, "Auto-complete quests", y, "autoQuestComplete")
    local function U() repeatCB:SetDisabled(not WaffleOptionsDB.autoQuestAccept) end
    acceptCB.onChanged = U; f:HookScript("OnShow", U)
    CreateDescription(f, "Hold Shift to temporarily disable and interact manually. Quests with multiple reward choices are never auto-completed.", y - 4)
    y = y - 36
    y = CreateSectionHeader(f, "Gossip Skip", y)
    local _, y = CreateCheckbox(f, "Auto-select single-option NPC gossip", y, "autoGossipSkip")
    CreateDescription(f, "Skips NPC dialog when there is only one gossip option (e.g., flight masters). Hold Shift to override.", y - 4)
end

do -- Achievements
    CreateCategoryButton("Achievements", "General")
    local f = CreateContentFrame("Achievements", 600)
    local y = CreateSectionHeader(f, "Auto-Screenshot", -PAD)
    local enableCB, y = CreateCheckbox(f, "Enable Auto-Screenshot", y, "autoScreenshotEnabled")
    local achieveCB, y = CreateCheckbox(f, "On achievement earned", y, "autoScreenshotAchievement", SUB_PAD)
    local bossCB, y = CreateCheckbox(f, "On boss kill", y, "autoScreenshotBossKill", SUB_PAD)
    local levelCB, y = CreateCheckbox(f, "On level up", y, "autoScreenshotLevelUp", SUB_PAD)
    local chatCB, y = CreateCheckbox(f, "Show notification in chat", y, "autoScreenshotChat", SUB_PAD)
    local _, y = CreateTextInput(f, "Delay (seconds, for UI toasts to appear)", y - 4, 120, "autoScreenshotDelay")
    local function U()
        local off = not WaffleOptionsDB.autoScreenshotEnabled
        achieveCB:SetDisabled(off); bossCB:SetDisabled(off)
        levelCB:SetDisabled(off); chatCB:SetDisabled(off)
    end
    enableCB.onChanged = U; f:HookScript("OnShow", U)

    y = y - SEC_GAP * 2
    y = CreateSectionHeader(f, "Congratulate Player Achievements", y)
    local _, y = CreateCheckbox(f, "Congratulate party members", y, "achieveGratsParty")
    local _, y = CreateCheckbox(f, "Congratulate guild members", y, "achieveGratsGuild")
    CreateDescription(f, "If a player is in both your party and guild, the message is sent to guild only to reduce spam. Uses a 10-second cooldown per player.", y - 4)
    y = y - 36
    CreateStringList(f, "Messages (one is chosen at random, {player} = their name)", y, "achieveGratsMessages")
end

-------------------------------------------------
-- Dungeons & Raids Section
-------------------------------------------------
CreateSidebarSection("Dungeons & Raids")

do -- Keystones
    CreateCategoryButton("Keystones", "Dungeons & Raids")
    local f = CreateContentFrame("Keystones", 530)
    local y = CreateSectionHeader(f, "Keystone", -PAD)
    local _, y = CreateCheckbox(f, "Show key reminder when joining M+ group", y, "dungeonKeyReminder")
    local _, y = CreateCheckbox(f, "Auto-insert keystone at font of power", y, "dungeonAutoInsertKey")
    y = y - SEC_GAP * 2
    y = CreateSectionHeader(f, "Key Swap", y)
    local _, y = CreateCheckbox(f, "Remind to trade keys after M+ completion", y, "dungeonKeySwapReminder")
    local _, y = CreateCheckbox(f, "Alert when your keystone changes", y, "dungeonKeyChangeAlert")
    y = y - SEC_GAP * 2
    y = CreateSectionHeader(f, "Key Result", y)
    local resultCB, y = CreateCheckbox(f, "Show key upgrade/depletion result", y, "dungeonKeyResult")
    local soundCB, y = CreateCheckbox(f, "Play alert sound on depletion", y, "dungeonKeyResultSound", SUB_PAD)
    local _, y = CreateSoundPicker(f, y, "dungeonKeyResultSoundID")
    y = y - SEC_GAP
    CreateRadioGroup(f, y, "Result Channel", {
        { label = "Print (local chat only)", value = "print" },
        { label = "Emote", value = "emote" },
        { label = "Party / Raid / Instance", value = "group" },
    }, "dungeonKeyResultChannel")
    local function U() soundCB:SetDisabled(not WaffleOptionsDB.dungeonKeyResult) end
    resultCB.onChanged = U; f:HookScript("OnShow", U)
end

do -- Completion Message
    CreateCategoryButton("Completion", "Dungeons & Raids")
    local f = CreateContentFrame("Completion", 520)
    local y = CreateSectionHeader(f, "Completion Message", -PAD)
    local ggCB, y = CreateCheckbox(f, "Send message on completion", y, "dungeonAutoGG")
    local ggM, y = CreateCheckbox(f, "Trigger on M+ completion", y, "dungeonGGMythicPlus", SUB_PAD)
    local ggR, y = CreateCheckbox(f, "Trigger on regular dungeon completion", y, "dungeonGGRegular", SUB_PAD)
    local ggRaid, y = CreateCheckbox(f, "Trigger on raid boss kill", y, "dungeonGGRaidBoss", SUB_PAD)
    local _, y = CreateTextInput(f, "Message", y - 4, 390, "dungeonGGMessage")
    local _, y = CreateTextInput(f, "Delay (seconds, 0 = instant)", y - 4, 120, "dungeonGGDelay")
    local function UG()
        local off = not WaffleOptionsDB.dungeonAutoGG
        ggM:SetDisabled(off); ggR:SetDisabled(off); ggRaid:SetDisabled(off)
    end
    ggCB.onChanged = UG; f:HookScript("OnShow", UG)
    y = y - SEC_GAP * 2
    y = CreateSectionHeader(f, "Auto-Leave Instance", y)
    local leaveCB, y = CreateCheckbox(f, "Automatically leave group after completion", y, "autoLeaveEnabled")
    local leaveM, y = CreateCheckbox(f, "Trigger on M+ completion", y, "autoLeaveMythicPlus", SUB_PAD)
    local leaveR, y = CreateCheckbox(f, "Trigger on regular dungeon completion", y, "autoLeaveRegular", SUB_PAD)
    local _, y = CreateTextInput(f, "Delay (seconds)", y - 4, 120, "autoLeaveDelay")
    CreateDescription(f, "Type /wafflecancel to abort the auto-leave countdown. Disabled by default for safety.", y - 4)
    local function UL()
        local off = not WaffleOptionsDB.autoLeaveEnabled
        leaveM:SetDisabled(off); leaveR:SetDisabled(off)
    end
    leaveCB.onChanged = UL; f:HookScript("OnShow", UL)
end

do -- Spec & Talents
    CreateCategoryButton("Spec & Talents", "Dungeons & Raids")
    local f = CreateContentFrame("Spec & Talents", 740)
    local y = CreateSectionHeader(f, "Spec Reminder", -PAD)
    local _, y = CreateCheckbox(f, "Remind current spec on zone entry", y, "dungeonSpecReminder")
    local _, y = CreateCheckbox(f, "Show active talent loadout name", y, "dungeonSpecShowLoadout", SUB_PAD)
    local _, y = CreateCheckbox(f, "Trigger in mythic dungeons", y, "dungeonSpecReminderDungeon", SUB_PAD)
    local _, y = CreateCheckbox(f, "Trigger in raids", y, "dungeonSpecReminderRaid", SUB_PAD)
    y = y - SEC_GAP
    local _, y = CreateRadioGroup(f, y, "Spec Reminder Channel", {
        { label = "Print (local chat only)", value = "print" },
        { label = "Emote", value = "emote" },
        { label = "Party / Raid / Instance", value = "group" },
    }, "dungeonSpecReminderChannel")
    y = y - SEC_GAP * 2
    y = CreateSectionHeader(f, "Unspent Talents Warning", y)
    local unspentCB, y = CreateCheckbox(f, "Warn about unspent talents on zone entry", y, "dungeonUnspentWarning")
    local unspentSound, y = CreateCheckbox(f, "Play alert sound", y, "dungeonUnspentSound", SUB_PAD)
    local _, y = CreateSoundPicker(f, y, "dungeonUnspentSoundID")
    y = y - SEC_GAP
    local _, y = CreateRadioGroup(f, y, "Warning Channel", {
        { label = "Print (local chat only)", value = "print" },
        { label = "Emote", value = "emote" },
        { label = "Party / Raid / Instance", value = "group" },
    }, "dungeonUnspentChannel")
    local function UU() unspentSound:SetDisabled(not WaffleOptionsDB.dungeonUnspentWarning) end
    unspentCB.onChanged = UU; f:HookScript("OnShow", UU)
    y = y - SEC_GAP * 2
    y = CreateSectionHeader(f, "Loot Spec Warning", y)
    local lootCB, y = CreateCheckbox(f, "Warn if loot spec differs from active spec", y, "dungeonLootSpecWarning")
    local lootSound, y = CreateCheckbox(f, "Play alert sound", y, "dungeonLootSpecSound", SUB_PAD)
    local _, y = CreateSoundPicker(f, y, "dungeonLootSpecSoundID")
    y = y - SEC_GAP
    CreateRadioGroup(f, y, "Loot Spec Warning Channel", {
        { label = "Print (local chat only)", value = "print" },
        { label = "Emote", value = "emote" },
        { label = "Party / Raid / Instance", value = "group" },
    }, "dungeonLootSpecChannel")
    local function ULS() lootSound:SetDisabled(not WaffleOptionsDB.dungeonLootSpecWarning) end
    lootCB.onChanged = ULS; f:HookScript("OnShow", ULS)
end

do -- Ready Check
    CreateCategoryButton("Ready Check", "Dungeons & Raids")
    local f = CreateContentFrame("Ready Check", 550)
    local y = CreateSectionHeader(f, "Ready Check Buffs", -PAD)
    local buffCB, y = CreateCheckbox(f, "Check buffs on ready check", y, "dungeonReadyCheckBuffs")
    y = y - SEC_GAP
    y = CreateSubHeader(f, "Check In", y)
    local dungeonBuffCB, y = CreateCheckbox(f, "Dungeons", y, "dungeonBuffCheckDungeon", SUB_PAD)
    local raidBuffCB, y = CreateCheckbox(f, "Raids", y, "dungeonBuffCheckRaid", SUB_PAD)
    local partyBuffCB, y = CreateCheckbox(f, "Open world parties", y, "dungeonBuffCheckParty", SUB_PAD)
    y = y - SEC_GAP
    local _, y = CreateRadioGroup(f, y, "Announcement Channel", {
        { label = "Personal (local chat only)", value = "personal" },
        { label = "Party / Raid / Instance", value = "party" },
    }, "dungeonBuffCheckMode")
    y = y - SEC_GAP * 2
    y = CreateSubHeader(f, "Buffs to Check", y)
    local classCB, y = CreateCheckbox(f, "Class buffs (based on group composition)", y, "dungeonBuffCheckClassBuffs", SUB_PAD)
    local foodCB, y = CreateCheckbox(f, "Food (Well Fed)", y, "dungeonBuffCheckFood", SUB_PAD)
    local flaskCB = CreateCheckbox(f, "Flask / Phial", y, "dungeonBuffCheckFlask", SUB_PAD)
    local function U()
        local off = not WaffleOptionsDB.dungeonReadyCheckBuffs
        classCB:SetDisabled(off); foodCB:SetDisabled(off); flaskCB:SetDisabled(off)
        dungeonBuffCB:SetDisabled(off); raidBuffCB:SetDisabled(off); partyBuffCB:SetDisabled(off)
    end
    buffCB.onChanged = U; f:HookScript("OnShow", U)
    y = y - CB_H - SEC_GAP * 2
    y = CreateSectionHeader(f, "Role Check", y)
    local _, y = CreateCheckbox(f, "Auto-confirm role check in LFG queues", y, "autoRoleCheck")
    CreateDescription(f, "Automatically accepts role checks with your current selected role.", y - 4)
end

do -- Announcements
    CreateCategoryButton("Announcements", "Dungeons & Raids")
    local f = CreateContentFrame("Announcements", 610)
    local y = CreateSectionHeader(f, "Group Announcements", -PAD)
    local _, y = CreateCheckbox(f, "Announce Mage Table", y, "dungeonAnnounceMageTable")
    local _, y = CreateCheckbox(f, "Announce Warlock Summoning Stone", y, "dungeonAnnounceWarlock")
    local _, y = CreateCheckbox(f, "Announce Feast / Buffet", y, "dungeonAnnounceFeast")
    y = y - SEC_GAP
    local _, y = CreateRadioGroup(f, y, "Announcement Channel", {
        { label = "Print (local chat only)", value = "print" },
        { label = "Emote", value = "emote" },
        { label = "Party / Raid / Instance", value = "group" },
    }, "dungeonAnnounceChannel")

    y = y - SEC_GAP * 2
    y = CreateSectionHeader(f, "Interrupt Announcements", y)
    local _, y = CreateCheckbox(f, "Announce your successful interrupts", y, "dungeonInterruptAnnounce")
    local _, y = CreateTextInput(f, "Message  ({spell} is replaced with interrupt name)", y - 4, 390, "dungeonInterruptMsg")
    y = y - SEC_GAP
    local _, y = CreateRadioGroup(f, y, "Interrupt Channel", {
        { label = "Print (local chat only)", value = "print" },
        { label = "Emote", value = "emote" },
        { label = "Party / Raid / Instance", value = "group" },
    }, "dungeonInterruptChannel")
    CreateDescription(f, "Announces your own interrupts only. Cannot detect group member interrupts due to WoW API restrictions.", y - 20)
end

-------------------------------------------------
-- Default selection
-------------------------------------------------
LayoutSidebar()
SelectCategory("About")

-------------------------------------------------
-- Public toggle
-------------------------------------------------
function WaffleOptions.ToggleOptions()
    if optionsFrame:IsShown() then
        optionsFrame:Hide()
    else
        optionsFrame:Show()
    end
end
