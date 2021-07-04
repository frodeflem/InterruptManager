local IM = InterruptManager
local IMversion = IM:GetVersion()
IM.DropDown = {}



--[[
    
    1.68 Options overhaul
    Included options (# = implemented):
        Old features
            - Interrupter names
            - Lock bars
            - Solo mode
            - Announce
            - Announce channel
            - PUG mode
            - PUG mode channel
            - Watch target
            - Watch focus
            - Warn if ready
            - Max interrupters
        
        New features
            - # Input checking
            - # Autocomplete while typing names
            - Autofill based on group composition
            - Selectable rotation behaviour (cooldown-based? strict rotation?)
            - Reset rotation on leaving combat
            - # Per-widget basis resizing
            - # Reset all widgets
            - Possibly: Experimental player CC detection that places them last
            - Possibly: Font settings
            - Possibly: Profiles

]]





function IM:EnableResizing()
    for k,v in pairs(IM.resizableFrames) do
        v:EnableResizing()
    end
end

function IM:DisableResizing()
    for k,v in pairs(IM.resizableFrames) do
        v:DisableResizing()
    end
end

function IM:OpenConfig()
    if (not InterruptManagerConfig) then
        IM:CreateConfig(true)
    end

    InterruptManagerConfig:Show()
    IM:UnlockWarningTextFrame()
    IM:EnableResizing()
    
    if (not InterruptManagerAnchor:IsShown()) then
        InterruptManagerAnchor:Show()
        
        for k,v in pairs(IM.statusBars) do
            if (k > 5) then
                break
            end

            v:Show()
        end
    end

    for k,v in pairs(IMDB.interrupters) do
        local serverName = v.serverName
        _G["InterruptManagerConfigEditbox" .. k]:SetText(v.characterName .. (strlen(serverName) > 0 and "-" .. serverName or ""))
    end
end

function IM:CreateNameEditboxes()
    for i = 1,IMDB.maxInterrupters do
        if (not _G["InterruptManagerConfigEditbox" .. i]) then
            -- Editboxes
            local function OnTabPressed(self)
                local min = 1
                local max = IMDB.maxInterrupters
                local next = self:GetID() + (IsShiftKeyDown() and -1 or 1)

                next = (next < min and max) or (next > max and min) or next
                
                _G["InterruptManagerConfigEditbox" .. next]:SetFocus()
            end

            local f = IM:CreateInterrupterEditbox("InterruptManagerConfigEditbox" .. i, "", 0, -i*30-15)
            f:SetID(i)
            f:SetScript("OnTabPressed", OnTabPressed)

            
            -- Fill in name buttons
            IM:CreateConfigButton("InterruptManagerFillInNameButton" .. i, tostring(i), 20, -115, -i*30-20, function() IM:FillInName(i) end)
        else
            _G["InterruptManagerConfigEditbox" .. i]:Show()
            _G["InterruptManagerFillInNameButton" .. i]:Show()
        end
    end
    
    -- Hide editboxes that are > IMDB.maxInterrupters
    
    for i = 1,99 do
        if (i > IMDB.maxInterrupters and _G["InterruptManagerConfigEditbox" .. i]) then
            _G["InterruptManagerConfigEditbox" .. i]:Hide()
            _G["InterruptManagerFillInNameButton" .. i]:Hide()
        elseif (i > IMDB.maxInterrupters) then
            break
        end
    end
end

function IM:CreateConfig(dontHide)
    if (not IM.autocomplete) then
        IM.autocomplete = {}
        IM.autocomplete.frames = {}
    end

    -- Configuration box
    PlaySound(839)
    local f = CreateFrame("Frame", "InterruptManagerConfig", nil, BackdropTemplateMixin and "BackdropTemplate")
    local height = 370 + IMDB.maxInterrupters*30
    f:SetHeight(height)
    f:SetWidth(300)
    f:SetPoint("CENTER")
    f:SetParent(UIParent)
    f:SetFrameLevel(1)
    f:SetMovable(1)
    f:SetFrameStrata("HIGH")
    f:SetScript("OnMouseDown", function() InterruptManagerConfig:StartMoving() end)
    f:SetScript("OnMouseUp", function() InterruptManagerConfig:StopMovingOrSizing() end)
    f:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\AddOns\\InterruptManager\\Textures\\ConfigBorder",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = {left = 5, right = 5, top = 5, bottom = 5}
    })
    tinsert(UISpecialFrames, f:GetName())
    
    -- Configuration box title
    local f = CreateFrame("Frame", nil, nil, BackdropTemplateMixin and "BackdropTemplate")
    f:SetHeight(30)
    f:SetWidth(200)
    f:SetPoint("CENTER", "InterruptManagerConfig", "TOP", 0, -15)
    f:SetParent(InterruptManagerConfig)
    f:SetScript("OnMouseDown", function() InterruptManagerConfig:StartMoving() end)
    f:SetScript("OnMouseUp", function() InterruptManagerConfig:StopMovingOrSizing() end)
    f:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\AddOns\\InterruptManager\\Textures\\ConfigBorder",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = {left = 5, right = 5, top = 5, bottom = 5}
    })
    f:SetScript("OnShow", function() PlaySound(839) end)
    f:SetScript("OnHide", function() IM:OnCloseClick() PlaySound(840) end)
    
    local t = f:CreateFontString()
    t:SetPoint("CENTER", f, "CENTER", 0, 0)
    t:SetFont("Fonts\\FRIZQT__.TTF", 12)
    t:SetText("Interrupt Manager")
    
    local moveAll = 10-IMDB.maxInterrupters*30
    IM:CreateConfigButton("InterruptManagerCloseButton", "Close", 100, 60, moveAll-340, function() InterruptManagerConfig:Hide() end)
    IM:CreateConfigButton("InterruptManagerChatButton", "Give Feedback", 100, -60, moveAll-340, IM.OnChatClick)
    IM:CreateConfigButton("InterruptManagerHelpButton", "Help", 100, -60, moveAll-310, IM.OnHelpClick)
    IM:CreateConfigButton("InterruptManagerHelpButton", "Reset Widgets", 100, 60, moveAll-310, IM.ResetWidgets)
    IM:CreateConfigButton("InterruptManagerResetButton", "Reset Rotation", 100, 0, moveAll-60, IM.ResetRotation)

    -- Editboxes + Fill-in-name-buttons
    IM:CreateNameEditboxes()
    -- Checkboxes
    IM:CreateConfigCheckbutton("InterruptManagerSoloModeButton", "Solo mode", -80, moveAll-90, "Turn on to be warned when your target/focus is casting, regardless of your position in the queue.", IMDB.soloMode, IM.OnSoloModeToggle)
    IM:CreateConfigCheckbutton("InterruptManagerAnnounceButton", "Announce", -80, moveAll-120, "Turn on to announce when you use your interrupt spell.", IMDB.announce, IM.OnAnnounceToggle)
    IM:CreateConfigCheckbutton("InterruptManagerPUGModeButton", "PUG mode", -80, moveAll-150, "Turn on to announce whose turn it is to interrupt, in chat.", IM.pugMode, IM.OnPUGModeToggle)
    IM:CreateConfigCheckbutton("InterruptManagerWatchTargetButton", "Watch target", -80, moveAll-180, "Turn on to be warned if your target starts casting an interruptible spell while it is your turn to interrupt, or if 'Solo mode' is enabled.", IMDB.targetWarn, IM.OnTargetWatchToggle)
    IM:CreateConfigCheckbutton("InterruptManagerWatchFocusButton", "Watch focus ", -80, moveAll-210, "Turn on to be warned if your focus starts casting an interruptible spell while it is your turn to interrupt, or if 'Solo mode' is enabled.", IMDB.focusWarn, IM.OnFocusWatchToggle)
    IM:CreateConfigCheckbutton("InterruptManagerWarnWhenReadyButton", "Warn if ready", -80, moveAll-240, "Turn on to receive the mid-screen warning only if your interrupt spell is ready.", IMDB.warnWhenReady, IM.OnWarnWhenReadyToggle)
    -- DropDown menus (x, y, script, text)
    IM:CreateConfigDropDown("InterruptManagerAnnounceChannelDropDown", 80, moveAll-118, IM.AnnounceDropDown, IMDB.announceChannel)
    IM:CreateConfigDropDown("InterruptManagerPUGModeChannelDropDown", 80, moveAll-148, IM.PugModeDropDown, IMDB.pugModeChannel)
    -- Max interrupters
    IM:CreateConfigLabel("InterruptManagerMaxInterruptersLabel", -40, moveAll-270, "Max interrupters")
    local f = IM:CreateInterrupterEditbox("InterruptManagerMaxInterruptersEditbox", tostring(IMDB.maxInterrupters), 80, moveAll-263, 50)
    f:SetMaxLetters(2)
    f:SetNumeric(true)
    f:SetScript("OnEscapePressed", function() f:ClearFocus() end)
    f:SetScript("OnEnterPressed", function() f.enterPressed = true; f:ClearFocus() end)
    f:SetScript("OnEditFocusLost", function() if (f.enterPressed) then f.enterPressed = false; IMDB.maxInterrupters = tonumber(f:GetText()); IM:UpdateMaxInterrupters() else f:SetText(tostring(IMDB.maxInterrupters)) end end)
    f:SetScript("OnShow", function() f:SetText(tostring(IMDB.maxInterrupters)) end)
    
    if (not dontHide) then
        InterruptManagerConfig:Hide()
    end
end

function IM:OnWarnWhenReadyToggle()
    IMDB.warnWhenReady = not IMDB.warnWhenReady

    if (IMDB.warnWhenReady) then
        DEFAULT_CHAT_FRAME:AddMessage("InterruptManager: You will now receive a warning to interrupt only if your interrupt spell is ready.", 1, 0.5, 0)
        -- IM:SendAddonMessage("pugmode:true")
    else
        DEFAULT_CHAT_FRAME:AddMessage("InterruptManager: You will now receive a warning to interrupt even when your interrupt spell is not ready.", 1, 0.5, 0)
    end
end

function IM:UpdateMaxInterrupters()
    if (InterruptManagerConfig) then
        local moveAll = 10-IMDB.maxInterrupters*30
        local height = 370 + IMDB.maxInterrupters*30
        InterruptManagerConfig:SetHeight(height)
        InterruptManagerResetButton:SetPoint("TOP", InterruptManagerConfig, "TOP", 0, moveAll-60)
        InterruptManagerSoloModeButton:SetPoint("TOP", InterruptManagerConfig, "TOP", -80, moveAll-90)
        InterruptManagerAnnounceChannelDropDown:SetPoint("TOP", InterruptManagerConfig, "TOP", 80, moveAll-118)
        InterruptManagerAnnounceButton:SetPoint("TOP", InterruptManagerConfig, "TOP", -80, moveAll-120)
        InterruptManagerPUGModeChannelDropDown:SetPoint("TOP", InterruptManagerConfig, "TOP", 80, moveAll-148)
        InterruptManagerPUGModeButton:SetPoint("TOP", InterruptManagerConfig, "TOP", -80, moveAll-150)
        InterruptManagerWatchTargetButton:SetPoint("TOP", InterruptManagerConfig, "TOP", -80, moveAll-180)
        InterruptManagerWatchFocusButton:SetPoint("TOP", InterruptManagerConfig, "TOP", -80, moveAll-210)
        InterruptManagerWarnWhenReadyButton:SetPoint("TOP", InterruptManagerConfig, "TOP", -80, moveAll-240)
        InterruptManagerMaxInterruptersEditbox:SetPoint("TOP", InterruptManagerConfig, "TOP", 80, moveAll-263)
        InterruptManagerMaxInterruptersLabel:SetPoint("TOP", InterruptManagerConfig, "TOP", -40, moveAll-270)
        InterruptManagerHelpButton:SetPoint("TOP", InterruptManagerConfig, "TOP", 0, moveAll-310)
        InterruptManagerCloseButton:SetPoint("TOP", InterruptManagerConfig, "TOP", 60, moveAll-340)
        InterruptManagerChatButton:SetPoint("TOP", InterruptManagerConfig, "TOP", -60, moveAll-340)
        IM:CreateNameEditboxes()
    end
    
    IM:UpdateStatusBarCount()
end

function IM:OnHelpClick()
    if (InterruptManagerNewFeatures and InterruptManagerNewFeatures:IsShown()) then
        InterruptManagerNewFeatures:Hide()
    else
        IM:InitializeNewFeatures(1)
    end
end

function IM:OnChatClick()
    if (IsShiftKeyDown()) then
        BNSendFriendInvite("Horse#2529", "Halp with addon plz!")
    else
        DEFAULT_CHAT_FRAME:AddMessage("InterruptManager: Shift-click to attempt to contact author (will send friend invitation to Horse#2529, Europe only).", 1, 0.5, 0)
    end
end

function IM:PugModeDropDown()
    local function OnClick(self, arg1)
        IMDB.pugModeChannel = arg1
        UIDropDownMenu_SetText(InterruptManagerPUGModeChannelDropDown, arg1)
    end
    
    local info = UIDropDownMenu_CreateInfo()
    local c = IMDB.pugModeChannel
    
    info.func = OnClick
    
    info.text, info.checked, info.arg1 = "Say", c == "SAY", "SAY"
    UIDropDownMenu_AddButton(info)
    
    info.text, info.checked, info.arg1 = "Yell", c == "YELL", "YELL"
    UIDropDownMenu_AddButton(info)

    info.text, info.checked, info.arg1 = "Instance, party or raid", c == "INSTANCE_CHAT", "INSTANCE_CHAT"
    UIDropDownMenu_AddButton(info)
    
    info.text, info.checked, info.arg1 = "Party", c == "PARTY", "PARTY"
    UIDropDownMenu_AddButton(info)
    
    info.text, info.checked, info.arg1 = "Raid", c == "RAID", "RAID"
    UIDropDownMenu_AddButton(info)
    
    info.text, info.checked, info.arg1 = "Raid Warning", c == "RAID_WARNING", "RAID_WARNING"
    UIDropDownMenu_AddButton(info)
    
    info.text, info.checked, info.arg1 = "Whisper", c == "WHISPER", "WHISPER"
    UIDropDownMenu_AddButton(info)
end

function IM:AnnounceDropDown()
    local function OnClick(self, arg1)
        IMDB.announceChannel = arg1
        UIDropDownMenu_SetText(InterruptManagerAnnounceChannelDropDown, arg1)
    end
    
    local info = UIDropDownMenu_CreateInfo()
    local c = IMDB.announceChannel
    
    info.func = OnClick
    
    info.text, info.checked, info.arg1 = "Say", c == "SAY", "SAY"
    UIDropDownMenu_AddButton(info)
    
    info.text, info.checked, info.arg1 = "Yell", c == "YELL", "YELL"
    UIDropDownMenu_AddButton(info)

    info.text, info.checked, info.arg1 = "Instance, party or raid", c == "INSTANCE_CHAT", "INSTANCE_CHAT"
    UIDropDownMenu_AddButton(info)
    
    info.text, info.checked, info.arg1 = "Party", c == "PARTY", "PARTY"
    UIDropDownMenu_AddButton(info)
    
    info.text, info.checked, info.arg1 = "Raid", c == "RAID", "RAID"
    UIDropDownMenu_AddButton(info)
    
    info.text, info.checked, info.arg1 = "Raid Warning", c == "RAID_WARNING", "RAID_WARNING"
    UIDropDownMenu_AddButton(info)
end

function IM:CreateConfigDropDown(name, x, y, script, text)
    local f = CreateFrame("Frame", name, InterruptManagerConfig, "UIDropDownMenuTemplate")
    f:SetPoint("TOP", "InterruptManagerConfig", "TOP", x, y)
    UIDropDownMenu_SetWidth(f, 80)
    UIDropDownMenu_Initialize(f, script)
    UIDropDownMenu_SetText(f, text)
end

function IM:CreateConfigLabel(name, x, y, text)
    local f = CreateFrame("Frame", name, InterruptManagerConfig)
    f:SetPoint("TOP", InterruptManagerConfig, "TOP", x, y)
    local t = f:CreateFontString("$parentText")
    t:SetFont("Fonts\\FRIZQT__.TTF", 12)
    t:SetText(text)
    
    f:SetSize(t:GetStringWidth(), 12)
    t:SetAllPoints(f)
end

function IM:CreateFontString(name, parent, flags, supportCyrillic)
    local t = parent:CreateFontString(name)
    -- t:SetFontObject(GameFontNormal)
    t.font = ""
    t.flags = ""

    if (LOCALE_koKR) then
        t:SetFont("Fonts\\2002.TTF", 12, flags)
        t.font = "Fonts\\2002.TTF"
    elseif (LOCALE_zhCN) then
        t:SetFont("Fonts\\ARKai_T.ttf", 12, flags)
        t.font = "Fonts\\ARKai_T.ttf"
    elseif (LOCALE_zhTW) then
        t:SetFont("Fonts\\blei00d.TTF", 12, flags)
        t.font = "Fonts\\blei00d.TTF"
    elseif (LOCALE_ruRU) then
        t:SetFont("Fonts\\FRIZQT___CYR.TTF", 12, flags)
        t.font = "Fonts\\FRIZQT___CYR.TTF"
    else
        t:SetFont("Fonts\\FRIZQT___CYR.TTF", 12, flags)
        t.font = "Fonts\\FRIZQT___CYR.TTF"


        -- if (supportCyrillic) then
        --     -- Well, this is dirty as hell, but I couldn't find another way to get a font that changes
        --     -- to cyrillic frizqt when needed...
        --     t.OldSetText = t.SetText

        --     function t:SetText(text)
        --         local height, flags = select(2, self:GetFont())
        --         self:SetFont("Fonts\\FRIZQT__.TTF", height, flags)

        --         for i = 1, strlen(text) do
        --             local b = string.byte(text, i)
        --             if (b == 209 or b == 208) then
        --                 self:SetFont("Fonts\\FRIZQT___CYR.TTF", height, flags)
        --                 break
        --             end
        --         end
                
        --         self:OldSetText(text)
        --     end
        -- end
    end

    function t:SetFontSize(size)
        self:SetFont(t.font, size, flags)
    end

    t:SetTextColor(1,1,1)
    return t
end

function IM:CreateConfigCheckbutton(name, text, x, y, tooltip, checked, script)
    local f = CreateFrame("CheckButton", name, InterruptManagerConfig, "ChatConfigCheckButtonTemplate")
    f:SetSize(20, 20)
    f:SetPoint("TOP", "InterruptManagerConfig", "TOP", x, y)
    f:SetFrameLevel(2)
    f:SetScript("OnClick", function() PlaySound(80) script() end)
    f:SetChecked(checked)
    f:SetNormalTexture("Interface\\AddOns\\InterruptManager\\Textures\\ConfigCheckboxUp")
    f:SetPushedTexture("Interface\\AddOns\\InterruptManager\\Textures\\ConfigCheckboxDown")
    f:SetHighlightTexture("Interface\\AddOns\\InterruptManager\\Textures\\ConfigButtonHighlight",0)
    f:SetCheckedTexture("Interface\\AddOns\\InterruptManager\\Textures\\ConfigCheckboxChecked")
    f:SetDisabledTexture("Interface\\AddOns\\InterruptManager\\Textures\\ConfigButtonDisabled")
    f.tooltip = tooltip
    local t = f:CreateFontString(name .. "Text")
    t:SetPoint("LEFT", _G[name], "LEFT", 25, 0)
    t:SetFont("Fonts\\FRIZQT__.TTF", 12)
    t:SetText(text)
end

function IM:GetAutocompleteNames(input)
    local nameTable = {}

    input = string.lower(input)

    if (IsInRaid()) then
        for i = 1, GetNumGroupMembers() do
            local name = IM:GetFullUnitName("raid" .. i)

            local stringStart, stringEnd = string.find(string.lower(name), string.lower(input))
            if (stringStart == 1 and stringEnd > 0) then
                tinsert(nameTable, name)
            end
        end
    else
        local name = IM:GetFullUnitName("player")
        
        local stringStart, stringEnd = string.find(string.lower(name), string.lower(input))
        if (stringStart == 1 and stringEnd > 0) then
            tinsert(nameTable, name)
        end

        for i = 1, GetNumGroupMembers() - 1 do
            local name = IM:GetFullUnitName("party" .. i)

            local stringStart, stringEnd = string.find(string.lower(name), string.lower(input))
            if (stringStart == 1 and stringEnd > 0) then
                tinsert(nameTable, name)
            end
        end
    end

    return nameTable
end

function IM:SetAutocompleteFocus(frame)
    if (IM.autocomplete.currentFocus) then
        IM.autocomplete.currentFocus.highlight1:Hide()
        IM.autocomplete.currentFocus.highlight2:Hide()
    end

    IM.autocomplete.currentFocus = frame
    frame.highlight1:Show()
    frame.highlight2:Show()
end

function IM:CreateAutocompleteFrames(parent, matches)
    local width, height = parent:GetSize()

    for k,v in pairs(matches) do
        local f = IM.autocomplete.frames[k]

        if (f and not f:IsShown()) then
            f:Show()
            f:SetPoint("TOP", parent, "BOTTOM", 0, (1-k) * height)
            f.text:SetText(v)
            f:SetParent(parent)
        else
            -- We have to create a new frame
            local function OnEnter(self)
                IM:SetAutocompleteFocus(self)
            end

            local function OnClick(self)
                self:GetParent():SetText(self.text:GetText())
                self:GetParent():ClearFocus()
            end

            f = CreateFrame("Button", nil, parent)
            f:SetSize(width, height)
            f:SetPoint("TOP", parent, "BOTTOM", 0, (1-k) * height)
            f:SetScript("OnEnter", OnEnter)
            f:SetScript("OnClick", OnClick)
            f:SetID(k)

            local t = f:CreateTexture()
            t:SetAllPoints(f)
            t:SetColorTexture(0.1, 0.1, 0.5)
            t:SetDrawLayer("ARTWORK", 0)

            local t = f:CreateTexture()
            t:SetPoint("CENTER", f, "CENTER")
            t:SetSize(width - 3, height - 3)
            t:SetColorTexture(0.1, 0.1, 0.1)
            t:SetDrawLayer("ARTWORK", 1)

            local t = f:CreateTexture()
            f.highlight1 = t
            t:SetPoint("CENTER", f, "CENTER")
            t:SetSize(width - 3, height - 3)
            t:SetColorTexture(1, 1, 1)
            t:SetDrawLayer("ARTWORK", 2)
            t:Hide()

            local t = f:CreateTexture()
            f.highlight2 = t
            t:SetPoint("CENTER", f, "CENTER")
            t:SetSize(width - 6, height - 6)
            t:SetColorTexture(0.2, 0.2, 0.2)
            t:SetDrawLayer("ARTWORK", 3)
            t:Hide()

            local t = f:CreateFontString()
            f.text = t
            t:SetAllPoints(f)
            t:SetFont("Fonts\\FRIZQT__.TTF", 12)
            t:SetDrawLayer("ARTWORK", 7)
            t:SetText(v)

            tinsert(IM.autocomplete.frames, f)
        end

        if (not IM.autocomplete.currentFocus or not IM.autocomplete.currentFocus:IsShown()) then
            IM:SetAutocompleteFocus(f)
        end
    end

    IM.autocomplete.numVisibleFrames = #matches
end

function IM:CreateInterrupterEditbox(name, text, x, y, width, height)
    local function OnTextChanged(self)
        local text = self:GetText()

        if (IM.autocomplete) then
            for k,v in pairs(IM.autocomplete.frames) do
                v:Hide()
            end
        end

        if (strlen(text) > 0) then
            local matches = IM:GetAutocompleteNames(text)
            IM:CreateAutocompleteFrames(self, matches)
        end
    end

    local function OnEditFocusGained(self)
        self:HighlightText()
        self:SetScript("OnTextChanged", OnTextChanged)
        OnTextChanged(self)
    end

    local function OnEditFocusLost(self)
        self:HighlightText(0,0)
        self:SetScript("OnTextChanged", nil)
        
        for k,v in pairs(IM.autocomplete.frames) do
            v:Hide()
        end
    end

    local function OnEnterPressed(self)
        if (IM.autocomplete.currentFocus and IM.autocomplete.currentFocus:IsShown()) then
            self:SetText(IM.autocomplete.currentFocus.text:GetText())

            local min = 1
            local max = IMDB.maxInterrupters
            local next = self:GetID() + (IsShiftKeyDown() and -1 or 1)

            next = (next < min and max) or (next > max and min) or next
            
            _G["InterruptManagerConfigEditbox" .. next]:SetFocus()
        end
    end

    local function OnEscapePressed(self)
        self:ClearFocus()
    end

    local function OnKeyDown(self, ...)
        local key = ...

        if (key == "DOWN" or key == "UP") then
            local currentFocusIndex = IM.autocomplete.currentFocus:GetID()

            if (key == "DOWN" and currentFocusIndex < IM.autocomplete.numVisibleFrames) then
                currentFocusIndex = currentFocusIndex + 1
            elseif (key == "UP" and currentFocusIndex > 1) then
                currentFocusIndex = currentFocusIndex - 1
            end

            IM:SetAutocompleteFocus(IM.autocomplete.frames[currentFocusIndex])
        end
    end

    local f = IM:CreateEditbox(name, InterruptManagerConfig)
    f:SetSize((width or 200), (height or 30))
    f:SetPoint("TOP", "InterruptManagerConfig", "TOP", x, y)
    f:Insert(text)
    f:SetScript("OnEscapePressed", OnEscapePressed)
    f:SetScript("OnEnterPressed", OnEnterPressed)
    f:SetScript("OnEditFocusGained", OnEditFocusGained)
    f:SetScript("OnEditFocusLost", OnEditFocusLost)
    f:SetScript("OnKeyDown", OnKeyDown)
    
    return f
end

function IM:CreateEditbox(name, parent)
    local function OnEditFocusGained(self)
        self:HighlightText()
    end

    local function OnEditFocusLost(self)
        self:HighlightText(0,0)
    end

    local function OnEnterPressed(self)
        self:ClearFocus()
    end

    local function OnEscapePressed(self)
        self:ClearFocus()
    end

    local function OnInputLanguageChanged(self, language)
        print(language)
    end

    local f = CreateFrame("Editbox", name, parent, BackdropTemplateMixin and "BackdropTemplate")
    f:SetFontObject(GameFontNormal)
    f:SetFrameLevel(2)
    f:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\AddOns\\InterruptManager\\Textures\\ConfigBorder",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = {left = 5,right = 5,top = 5,bottom = 5}
    })
    f:SetAutoFocus(false)
    f:ClearFocus()
    f:SetTextColor(1,1,1)
    f:SetMaxLetters(50)
    f:SetTextInsets(9,0,0,0)
    f:SetScript("OnEscapePressed", OnEscapePressed)
    f:SetScript("OnEnterPressed", OnEnterPressed)
    f:SetScript("OnEditFocusGained", OnEditFocusGained)
    f:SetScript("OnEditFocusLost", OnEditFocusLost)
    f:SetScript("OnInputLanguageChanged", OnInputLanguageChanged)
    
    return f
end

function IM:CreateConfigButton(name, text, width, x, y, script, tooltip)
    local f = CreateFrame("Button", name)
    if (text ~= "Close") then
        f:SetScript("OnClick", function() IM:Debug(name); PlaySound(80) script() end)
    else
        f:SetScript("OnClick", function() IM:Debug(name); script() end) -- Let's not have the close button play a sound other than the "close" sound...
    end
    f:SetHeight(20)
    f:SetWidth(width)
    f:SetParent(InterruptManagerConfig)
    f:SetPoint("TOP", "InterruptManagerConfig", "TOP", x, y)
    f:SetFrameLevel(2)
    f:SetNormalTexture("Interface\\AddOns\\InterruptManager\\Textures\\ConfigButtonUp")
    f:SetPushedTexture("Interface\\AddOns\\InterruptManager\\Textures\\ConfigButtonDown")
    f:SetHighlightTexture("Interface\\AddOns\\InterruptManager\\Textures\\ConfigButtonHighlight", 0)
    f:SetDisabledTexture("Interface\\AddOns\\InterruptManager\\Textures\\ConfigButtonDisabled")
    f.tooltip = tooltip
    
    local font = f:CreateFontString()
    f:SetFontString(font)
    f:SetPushedTextOffset(-1, -1)
    font:SetFont("Fonts\\FRIZQT__.TTF", 12)
    font:SetText(text)
    font:SetTextColor(0, 0, 0)
end

function IM:FillInName(i)
    -- Called when clicking on a numbered button to the left of editboxes
    if (UnitExists("target")) then
        local characterName = UnitName("target")
        local serverName = select(2, UnitName("target"))
        
        if (not serverName or serverName == "") then
            serverName = GetRealmName()
        end

        _G["InterruptManagerConfigEditbox" .. i]:SetText(characterName .. "-" .. serverName)
    else
        _G["InterruptManagerConfigEditbox" .. i]:SetText("")
    end
end

function IM:GetUnitName(unit)
    -- Returns "no [unit]" if unit doesn't exist
    -- Returns "Playername-Realmname" if unit is from a different realm
    -- Returns "Playername" if unit is from the same realm
    if (UnitExists(unit)) then
        local name, realm = UnitName(unit)
        
        if (realm and realm ~= "") then
            return name .. "-" .. realm
        else
            return name
        end
    else
        return "no " .. unit
    end
end

function IM:OnSoloModeToggle()
    IMDB.soloMode = not IMDB.soloMode

    if (IMDB.soloMode) then
        DEFAULT_CHAT_FRAME:AddMessage("InterruptManager: Solo mode enabled. You will now be warned when your target/focus starts casting a spell, regardless of your position in the queue.", 1, 0.5, 0)
    else
        DEFAULT_CHAT_FRAME:AddMessage("InterruptManager: Solo mode disabled.", 1, 0.5, 0)
    end
end

function IM:OnAnnounceToggle()
    IMDB.announce = not IMDB.announce

    if (IMDB.announce) then
        DEFAULT_CHAT_FRAME:AddMessage("InterruptManager: Announce enabled.", 1, 0.5, 0)
    else
        DEFAULT_CHAT_FRAME:AddMessage("InterruptManager: Announce disabled.", 1, 0.5, 0)
    end
end

function IM:OnPUGModeToggle()
    IM.pugMode = not IM.pugMode

    if (IM.pugMode) then
        DEFAULT_CHAT_FRAME:AddMessage("InterruptManager: PUG mode enabled. You will now announce when someone uses their interrupt ability, and whose turn it is next. This option is automatically disabled when you log in.", 1, 0.5, 0)
        IM:SendAddonMessage("pugmode:true")
    else
        DEFAULT_CHAT_FRAME:AddMessage("InterruptManager: PUG mode disabled.", 1, 0.5, 0)
    end
end

function IM:OnTargetWatchToggle()
    IMDB.targetWarn = not IMDB.targetWarn

    if (IMDB.targetWarn) then
        DEFAULT_CHAT_FRAME:AddMessage("InterruptManager: You will now be warned if your target starts casting a spell when it is your turn to interrupt.", 1, 0.5, 0)
    else
        DEFAULT_CHAT_FRAME:AddMessage("InterruptManager: You will no longer be warned when your target starts casting a spell.", 1, 0.5, 0)
    end
end

function IM:OnFocusWatchToggle()
    IMDB.focusWarn = not IMDB.focusWarn

    if (IMDB.focusWarn) then
        DEFAULT_CHAT_FRAME:AddMessage("InterruptManager: You will now be warned if your focus starts casting a spell when it is your turn to interrupt.", 1, 0.5, 0)
    else
        DEFAULT_CHAT_FRAME:AddMessage("InterruptManager: You will no longer be warned when your focus starts casting a spell.", 1, 0.5, 0)
    end
end

IM.warnOnce = true
function IM:BroadcastInterrupters()
    local msg = "rotationinfo:"
    
    for i = 1,IMDB.maxInterrupters do
        local text = _G["InterruptManagerConfigEditbox" .. i]:GetText()
        
        if (text ~= "") then
            msg = msg .. text .. ","
        end
    end
    
    IM:SendAddonMessage(msg)
    IM:SendAddonMessage("versioninfo:" .. IMversion)
end

function IM:ResetRotation()
    for i = 1, IMDB.maxInterrupters do
        _G["InterruptManagerConfigEditbox" .. i]:SetText("")
    end

    wipe(IMDB.interrupters)

    for k,v in pairs(IM.statusBars) do
        v.text:SetText("")
        v:SetValue(0)
    end
end

function IM:ResetWidgets()
    for k,v in pairs(IM.resizableFrames) do
        v:ResetToDefault()
    end
end

function IM:CreateInterrupter(characterName, serverName, i)
    -- This function takes care of conditioning the name into the proper format, so that
    -- it can take a player's "Charactername" as input, but only if they are from the same
    -- realm. "Charactername-Realmname" will always work.

    local interrupter = {}

    interrupter.characterName = characterName
    interrupter.serverName = serverName
    interrupter.displayName = characterName

    -- interrupter[i].name must contain the interrupter's name as seen in the combat log
    if (interrupter.serverName == GetRealmName()) then
        interrupter.name = interrupter.characterName
    else
        interrupter.name = interrupter.characterName .. "-" .. interrupter.serverName
    end

    -- Prevent duplicates
    for k,v in pairs(IMDB.interrupters) do
        if (v.name == interrupter.name) then
            return
        end
    end
    
    interrupter.ready = true
    if (i == 1) then interrupter.next = true else interrupter.next = false end
    interrupter.cooldown = 0
    interrupter.readyTime = GetTime() + #IMDB.interrupters * 0.01
    
    return interrupter
end

function IM:SetRotation()
    IM:Debug("Set Rotation")
    
    wipe(IMDB.interrupters)
    IM.selfReference = nil
    
    for i = 1, IMDB.maxInterrupters do
        local text = _G["InterruptManagerConfigEditbox" .. i]:GetText()

        if (text ~= "") then
            local interrupter = IM:CreateInterrupter(IM:GetCharacterName(text), IM:GetServerName(text), i)
            if (interrupter) then
                tinsert(IMDB.interrupters, interrupter)

                if (interrupter.name == UnitName("player")) then
                    IM.selfReference = interrupter
                end
            end
        end
    end

    IM.positionReferences = {unpack(IMDB.interrupters)}

    IM:UpdateUnitReferences()
    IM:UpdateStatusBarCount()
    IM:SetNumVisibleStatusBars(#IMDB.interrupters)
    IM:CheckDuplicateCharacterNames()
    IM:UpdateInterruptRotation()
end

function IM:UnlockWarningTextFrame()
    local text = "Interrupt now!"
    InterruptManagerText:AddMessage(text, 1,0.5,1)
    InterruptManagerText:SetTimeVisible(3600)
    InterruptManagerText.text = text
end

function IM:LockWarningTextFrame()
    InterruptManagerText:SetTimeVisible(0)
end

function IM:InputCheck_InterrupterNames()
    -- Attempts to correct input to an appropriate format
    -- After doing so, returns true if all interrupter names are valid, false otherwise
    -- Also prints an error message if player was not found in the raid

    for i = 1, IMDB.maxInterrupters do
        local text = _G["InterruptManagerConfigEditbox" .. i]:GetText()

        if (strlen(text) > 0) then
            local characterName = IM:GetCharacterName(text)
            local serverName, ambiguousServerName = IM:GetServerName(text)

            if (not strfind(text, "-")) then
                if (serverName and serverName ~= "") then
                    text = characterName .. "-" .. serverName
                    _G["InterruptManagerConfigEditbox" .. i]:SetText(text)
                end
            end

            if (ambiguousServerName) then
                DEFAULT_CHAT_FRAME:AddMessage("InterruptManager: The name " .. text .. " is ambiguous. Please specify realm name.", 1, 0.5, 0)
                return false
            end


            -- Skip the "missing"-check if PUG mode is enabled
            local missing = not IM.pugMode

            if (IsInRaid()) then
                for i = 1, GetNumGroupMembers() do
                    if (IM:GetFullUnitName("raid" .. i) == text) then
                        missing = false
                    end
                end       
            elseif (IsInGroup()) then
                for i = 1, GetNumGroupMembers() - 1 do
                    if (IM:GetFullUnitName("party" .. i) == text) then
                        missing = false
                    end
                end
            end

            if (text == IM:GetFullName(UnitName("player"))) then missing = false end
            
            if (missing and IM.warnOnce) then
                DEFAULT_CHAT_FRAME:AddMessage("InterruptManager: " .. text .. " is missing from the group. InterruptManager will not work as intended unless you set the rotation while all rotation members are in your group.", 1, 0.5, 0)
                IM.warnOnce = false
            elseif (missing) then
                DEFAULT_CHAT_FRAME:AddMessage("InterruptManager: " .. text .. " is missing from the group.")
            end
        end
    end

    return true
end

function IM:OnCloseClick()
    InterruptManagerConfig:Hide()
    IM:DisableResizing()
    IM:LockWarningTextFrame()

    if (InterruptManagerNewFeatures) then
        InterruptManagerNewFeatures:Hide()
        InterruptManagerNewFeatures.previousItem:hideFunc()
    end

    if (IM:InputCheck_InterrupterNames()) then
        IM:SetRotation()
        
        IMDB.leader = true
        
        if (IsInGroup() or IsInRaid()) then
            IM:BroadcastInterrupters()
        end
    else
        IM:UpdateStatusBarCount()
        IM:SetNumVisibleStatusBars(#IMDB.interrupters)
        IM:CheckDuplicateCharacterNames()
        IM:UpdateInterruptRotation()
    end
end

function IM:SendAddonMessage(msg)
    local channel
    if (IsInRaid(LE_PARTY_CATEGORY_INSTANCE) or IsInGroup(LE_PARTY_CATEGORY_INSTANCE)) then
        channel = "INSTANCE_CHAT"
    elseif (IsInRaid()) then
        channel = "RAID"
    elseif (IsInGroup()) then
        channel = "PARTY"
    else
        local playerName = UnitName("player")
        C_ChatInfo.SendAddonMessage("InterruptManager", msg, "WHISPER", playerName)
        return
    end
    
    C_ChatInfo.SendAddonMessage("InterruptManager", msg, channel)
end

function IM:ReceiveRotationInfo(msg, sender)
    -- TODO: Clean this function up......
    
    -- Message example
    -- playername,[playername,][playername,][playername,][playername,]
    local db = IMDB.interrupters
    local temp = strfind(sender, "-")
    local realmName = strsub(sender, temp+1)
    
    -- Don't proceed unless player's name is in the message
    if (not strfind(msg, UnitName("player"))) then return end
    IMDB.leader = false
    
    local interrupterNames = {}
    
    -- Create config if it isn't created yet, because we will be inserting text into the config editboxes
    if (not InterruptManagerConfig) then
        IM:CreateConfig(true)
    end
    
    IMDB.leader = false
    
    for i = 1,99 do
        -- If message is empty, remove all text in the editbox, in case there are more players in the previous, locally stored rotation, than in the most recently broadcast one
        if (msg == "" and _G["InterruptManagerConfigEditbox" .. i]) then
            _G["InterruptManagerConfigEditbox" .. i]:SetText("")
        elseif (msg == "" and not _G["InterruptManagerConfigEditbox" .. i]) then
            break
        else
            local nameEnd = strfind(msg, ",") -- Find first ","
            local name = strsub(msg, 1, nameEnd-1) -- Use all text up until first ","

            -- if (strfind(name, GetRealmName())) then -- If sender is from a different realm, remove "-[yourRealm]" from the names of players from your own realm
            --     name = IM:GetCharacterName(name)
            -- end
            msg = strsub(msg, nameEnd+1) -- Remove the extracted name from the message for further interpreting
            tinsert(interrupterNames, name)
        end
    end
    
    if (IMDB.maxInterrupters < #interrupterNames) then
        IMDB.maxInterrupters = #interrupterNames
        IM:UpdateMaxInterrupters()
    end
    
    for k,v in pairs(interrupterNames) do
        _G["InterruptManagerConfigEditbox" .. k]:SetText(v)
    end
    
    IM:SendAddonMessage("versioninfo:" .. IMversion) -- Broadcasting version will produce a message if someone else has a higher version
    
    if (InterruptManagerConfig:IsShown()) then
        InterruptManagerConfig:Hide()
    else
        IM:SetRotation()
    end
end

function IM:ReceivePugModeInfo(msg)
    -- Message examples
    -- true
    -- false
    if (msg == "true") then
        if (InterruptManagerConfig) then
            InterruptManagerPUGModeButton:SetChecked(false)
        end

        IM.pugMode = false
    end
end

function IM:ReceiveVersionInfo(msg, sender)
    local otherVersion = tonumber(msg)
    local myVersion = tonumber(IM:GetVersion())
    
    if (otherVersion > myVersion) then
        if (not IM.newVersionNoticed) then
            DEFAULT_CHAT_FRAME:AddMessage("InterruptManager: An update is available for InterruptManager.", 1, 0.5, 0)
            IM.newVersionNoticed = true
        end
    elseif (otherVersion < 154 and not IM.newVersionNoticed) then
        DEFAULT_CHAT_FRAME:AddMessage("InterruptManager: " .. sender .. " is using a version that does not support more than 5 interrupters.", 1, 0.5, 0)
        IM.newVersionNoticed = true
    end
end

function IM:AddonMessageReceived(...)
    -- This is super ugly, but the neat way did for unknown reasons not work.
    -- All function calls were made with two arguments, msg and sender.
    -- The called functions would receive three arguments, arg1 = nil, arg2 = sender, arg3 = msg.
    -- Yes, in the reverse order compared to the function call.
    local msg, _, sender, noRealmNameSender = select(2, ...)

    IM:Debug((noRealmNameSender or "no sender") .. " (" .. (sender or "no sender") .. "): " .. (msg or "no message") .. ", self=" .. UnitName("player") .. "-" .. GetRealmName())
    
    if (sender == UnitName("player") .. "-" .. GetRealmName()) then
        IM:Debug("Filtered own message")
        return
    end
    
    if (strfind(msg, "rotationinfo:")) then
        msg = gsub(msg, "rotationinfo:", "")
        IM:ReceiveRotationInfo(msg, sender)
    
    elseif (strfind(msg, "versioninfo:")) then
        msg = gsub(msg, "versioninfo:", "")
        IM:ReceiveVersionInfo(msg, sender)
        
    -- Disabled in 1.69 to temporarily fix issue that prevents enabling of PUG mode
    -- elseif (strfind(msg, "pugmode:")) then
    --     msg = gsub(msg, "pugmode:", "")
    --     IM:ReceivePugModeInfo(msg, sender)
    end
end

function round(num, dec)
    local number = string.format("%." .. dec .. "f", tostring(num))
    return tonumber(number)
end

function roundString(num,dec)
    return string.format("%." .. dec .. "f", tostring(num))
end

function IM:CreateResizableFrame(frameType, frameName, parent)
    -- This is for storing the actual object reference
    if (not IM.resizableFrames) then
        IM.resizableFrames = {}
    end

    -- This is for storing the object's properties between sessions
    if (not IMDB.resizableFrames[frameName]) then
        IMDB.resizableFrames[frameName] = {}
    end

    local g = CreateFrame(frameType, frameName, parent)
    g:SetMovable(false)
    IM.resizableFrames[frameName] = g


    local function OnEscapePressed(self)
        self:ClearFocus()
    end

    local function OnEnter(self)
        self.highlight:SetColorTexture(1, 1, 1, 0.4)
    end

    local function OnLeave(self)
        self.highlight:SetColorTexture(1, 1, 1, 0.2)
    end


    --------------------------------------
    --------- X Position editbox ---------
    do
        local function OnEnterPressed(self)
            if (self:GetText() == "") then
                return
            end

            local p = self:GetParent()
            local table = IMDB.resizableFrames[p:GetName()]

            table.x = floor(self:GetText())

            p:UpdatePoint()
            self:HighlightText()
        end

        local xPos = IM:CreateEditbox(nil, g)
        g.xPos = xPos
        xPos:SetPoint("TOP", g, "BOTTOM", -50, -15)
        xPos:SetSize(62, 30)
        xPos:SetNumeric(true)
        xPos:SetScript("OnEscapePressed", OnEscapePressed)
        xPos:SetScript("OnEnterPressed", OnEnterPressed)

        local t = IM:CreateFontString(nil, xPos)
        t:SetSize(20, 20)
        t:SetPoint("RIGHT", xPos, "LEFT", 3, 0)
        t:SetText("x")
    end

    --------------------------------------
    --------- Y Position editbox ---------
    do
        local function OnEnterPressed(self)
            if (self:GetText() == "") then
                return
            end

            local p = self:GetParent()
            local table = IMDB.resizableFrames[p:GetName()]
            
            table.y = floor(self:GetText())

            p:UpdatePoint()
            self:HighlightText()
        end

        local yPos = IM:CreateEditbox(nil, g)
        g.yPos = yPos
        yPos:SetPoint("TOP", g, "BOTTOM", 50, -15)
        yPos:SetSize(62, 30)
        yPos:SetNumeric(true)
        yPos:SetScript("OnEscapePressed", OnEscapePressed)
        yPos:SetScript("OnEnterPressed", OnEnterPressed)

        local t = IM:CreateFontString(nil, yPos)
        t:SetSize(20, 20)
        t:SetPoint("RIGHT", yPos, "LEFT", 3, 0)
        t:SetText("y")
    end

    ---------------------------------
    --------- Width editbox ---------
    do
        local function OnEnterPressed(self)
            if (self:GetText() == "") then
                return
            end

            local p = self:GetParent()
            local table = IMDB.resizableFrames[p:GetName()]
            
            table.width = floor(self:GetText())

            p:UpdateSize()
            self:HighlightText()
        end

        local width = IM:CreateEditbox(nil, g)
        g.width = width
        width:SetPoint("BOTTOM", g, "TOP", -50, 15)
        width:SetSize(62, 30)
        width:SetNumeric(true)
        width:SetScript("OnEscapePressed", OnEscapePressed)
        width:SetScript("OnEnterPressed", OnEnterPressed)

        local t = IM:CreateFontString(nil, width)
        t:SetSize(50, 20)
        t:SetPoint("BOTTOM", width, "TOP", 0, -3)
        t:SetText("Width")
    end

    ---------------------------------
    --------- Height editbox ---------
    do
        local function OnEnterPressed(self)
            if (self:GetText() == "") then
                return
            end

            local p = self:GetParent()
            local table = IMDB.resizableFrames[p:GetName()]
            
            table.height = floor(self:GetText())

            p:UpdateSize()
            self:HighlightText()
        end

        local height = IM:CreateEditbox(nil, g)
        g.height = height
        height:SetPoint("BOTTOM", g, "TOP", 50, 15)
        height:SetSize(62, 30)
        height:SetNumeric(true)
        height:SetScript("OnEscapePressed", OnEscapePressed)
        height:SetScript("OnEnterPressed", OnEnterPressed)

        local t = IM:CreateFontString(nil, height)
        t:SetSize(50, 20)
        t:SetPoint("BOTTOM", height, "TOP", 0, -3)
        t:SetText("Height")
    end

    -----------------------------------
    --------- Bottom drag bar ---------
    do
        local function OnUpdate(self)
            local p = self:GetParent()
            local table = IMDB.resizableFrames[p:GetName()]
            local currentMousePos = {GetCursorPosition()}
            local delta = floor((self.mouseStart[2] - currentMousePos[2]) / UIParent:GetEffectiveScale())

            if (self.sizeStart[2] + delta < 3) then
                delta = 3 - self.sizeStart[2]
            end

            table.y = self.pointStart[2] - delta
            table.height = self.sizeStart[2] + delta

            p:UpdatePoint()
            p:UpdateSize()
        end

        local function OnMouseDown(self)
            local table = IMDB.resizableFrames[self:GetParent():GetName()]
            self.mouseStart = {GetCursorPosition()}
            self.sizeStart = {table.width, table.height}
            self.pointStart = {table.x, table.y}
            self:SetScript("OnUpdate", OnUpdate)
        end

        local function OnMouseUp(self)
            self:SetScript("OnUpdate", nil)
        end

        local bottomDrag = CreateFrame("Frame", nil, g)
        g.bottomDrag = bottomDrag
        bottomDrag:SetPoint("TOP", g, "BOTTOM")
        bottomDrag:SetScript("OnEnter", OnEnter)
        bottomDrag:SetScript("OnLeave", OnLeave)
        bottomDrag:SetScript("OnMouseDown", OnMouseDown)
        bottomDrag:SetScript("OnMouseUp", OnMouseUp)
        
        local t = bottomDrag:CreateTexture()
        bottomDrag.highlight = t
        t:SetAllPoints(bottomDrag)
        t:SetColorTexture(1, 1, 1, 0.2)
    end

    --------------------------------
    --------- Top drag bar ---------
    do
        local function OnUpdate(self)
            local p = self:GetParent()
            local table = IMDB.resizableFrames[p:GetName()]
            local currentMousePos = {GetCursorPosition()}
            local delta = floor((self.mouseStart[2] - currentMousePos[2]) / UIParent:GetEffectiveScale())

            if (self.sizeStart[2] - delta < 3) then
                delta = self.sizeStart[2] - 3
            end

            table.height = self.sizeStart[2] - delta
            p:UpdateSize()
        end

        local function OnMouseDown(self)
            local table = IMDB.resizableFrames[self:GetParent():GetName()]
            self.mouseStart = {GetCursorPosition()}
            self.sizeStart = {table.width, table.height}
            self:SetScript("OnUpdate", OnUpdate)
        end

        local function OnMouseUp(self)
            self:SetScript("OnUpdate", nil)
        end

        local topDrag = CreateFrame("Frame", nil, g)
        g.topDrag = topDrag
        topDrag:SetPoint("BOTTOM", g, "TOP")
        topDrag:SetScript("OnEnter", OnEnter)
        topDrag:SetScript("OnLeave", OnLeave)
        topDrag:SetScript("OnMouseDown", OnMouseDown)
        topDrag:SetScript("OnMouseUp", OnMouseUp)
        
        local t = topDrag:CreateTexture()
        topDrag.highlight = t
        t:SetAllPoints(topDrag)
        t:SetColorTexture(1, 1, 1, 0.2)
    end

    ---------------------------------
    --------- Left drag bar ---------
    do
        local function OnUpdate(self)
            local p = self:GetParent()
            local table = IMDB.resizableFrames[p:GetName()]
            local currentMousePos = {GetCursorPosition()}
            local delta = floor((self.mouseStart[1] - currentMousePos[1]) / UIParent:GetEffectiveScale())

            if (self.sizeStart[1] + delta < 3) then
                delta = 3 - self.sizeStart[1]
            end

            table.x = self.pointStart[1] - delta
            table.width = self.sizeStart[1] + delta

            p:UpdatePoint()
            p:UpdateSize()
        end

        local function OnMouseDown(self)
            local table = IMDB.resizableFrames[self:GetParent():GetName()]
            self.mouseStart = {GetCursorPosition()}
            self.sizeStart = {table.width, table.height}
            self.pointStart = {table.x, table.y}
            self:SetScript("OnUpdate", OnUpdate)
        end

        local function OnMouseUp(self)
            self:SetScript("OnUpdate", nil)
        end

        local leftDrag = CreateFrame("Frame", nil, g)
        g.leftDrag = leftDrag
        leftDrag:SetPoint("RIGHT", g, "LEFT")
        leftDrag:SetScript("OnEnter", OnEnter)
        leftDrag:SetScript("OnLeave", OnLeave)
        leftDrag:SetScript("OnMouseDown", OnMouseDown)
        leftDrag:SetScript("OnMouseUp", OnMouseUp)
        
        local t = leftDrag:CreateTexture()
        leftDrag.highlight = t
        t:SetAllPoints(leftDrag)
        t:SetColorTexture(1, 1, 1, 0.2)
    end

    ----------------------------------
    --------- Right drag bar ---------
    do
        local function OnUpdate(self)
            local p = self:GetParent()
            local table = IMDB.resizableFrames[p:GetName()]
            local currentMousePos = {GetCursorPosition()}
            local delta = floor((self.mouseStart[1] - currentMousePos[1]) / UIParent:GetEffectiveScale())

            if (self.sizeStart[1] - delta < 3) then
                delta = self.sizeStart[1] - 3
            end

            table.width = self.sizeStart[1] - delta
            p:UpdateSize()
        end

        local function OnMouseDown(self)
            local table = IMDB.resizableFrames[self:GetParent():GetName()]
            self.mouseStart = {GetCursorPosition()}
            self.sizeStart = {table.width, table.height}
            self:SetScript("OnUpdate", OnUpdate)
        end

        local function OnMouseUp(self)
            self:SetScript("OnUpdate", nil)
        end

        local rightDrag = CreateFrame("Frame", nil, g)
        g.rightDrag = rightDrag
        rightDrag:SetPoint("LEFT", g, "RIGHT")
        rightDrag:SetScript("OnEnter", OnEnter)
        rightDrag:SetScript("OnLeave", OnLeave)
        rightDrag:SetScript("OnMouseDown", OnMouseDown)
        rightDrag:SetScript("OnMouseUp", OnMouseUp)
        
        local t = rightDrag:CreateTexture()
        rightDrag.highlight = t
        t:SetAllPoints(rightDrag)
        t:SetColorTexture(1, 1, 1, 0.2)
    end

    -----------------------------------
    --------- Center drag bar ---------
    do
        local function OnUpdate(self)
            local p = self:GetParent()
            local table = IMDB.resizableFrames[p:GetName()]
            local currentMousePos = {GetCursorPosition()}
            local xDelta = floor((self.mouseStart[1] - currentMousePos[1]) / UIParent:GetEffectiveScale())
            local yDelta = floor((self.mouseStart[2] - currentMousePos[2]) / UIParent:GetEffectiveScale())

            table.x = self.pointStart[1] - xDelta
            table.y = self.pointStart[2] - yDelta

            p:UpdatePoint()
        end

        local function OnMouseDown(self)
            local table = IMDB.resizableFrames[self:GetParent():GetName()]
            self.mouseStart = {GetCursorPosition()}
            self.pointStart = {table.x, table.y}
            self:SetScript("OnUpdate", OnUpdate)
        end
    
        local function OnMouseUp(self)
            self:SetScript("OnUpdate", nil)
        end

        local function OnLeave(self)
            self.highlight:SetColorTexture(1, 1, 1, 0)
        end

        local centerDrag = CreateFrame("Frame", nil, g)
        g.centerDrag = centerDrag
        centerDrag:SetAllPoints(g)
        centerDrag:SetScript("OnEnter", OnEnter)
        centerDrag:SetScript("OnLeave", OnLeave)
        centerDrag:SetScript("OnMouseDown", OnMouseDown)
        centerDrag:SetScript("OnMouseUp", OnMouseUp)

        local t = centerDrag:CreateTexture()
        centerDrag.highlight = t
        t:SetAllPoints(centerDrag)
        t:SetColorTexture(1, 1, 1, 0)
    end



    function g:ResetToDefault()
        local table = IMDB.resizableFrames[self:GetName()]

        table.point = table.defaultPoint
        table.region = table.defaultRegion
        table.relativePoint = table.defaultRelativePoint
        table.x = table.defaultX
        table.y = table.defaultY

        table.width = table.defaultWidth
        table.height = table.defaultHeight

        self:UpdatePoint()
        self:UpdateSize()
    end

    function g:UpdateSize()
        local table = IMDB.resizableFrames[self:GetName()]

        self:SetSize(table.width, table.height)
        self.width:SetText(table.width)
        self.height:SetText(table.height)
    end

    function g:UpdatePoint()
        local table = IMDB.resizableFrames[self:GetName()]
        
        self:SetPoint(table.point, _G[table.region], table.relativePoint, table.x, table.y)
        self.xPos:SetText(table.x)
        self.yPos:SetText(table.y)
    end

    function g:SetDefaultPoint(point, region, relativePoint, x, y)
        local table = IMDB.resizableFrames[self:GetName()]

        region = region:GetName()
        x = floor(x)
        y = floor(y)

        table.point = table.point or point
        table.region = table.region or region
        table.relativePoint = table.relativePoint or relativePoint
        table.x = table.x or x
        table.y = table.y or y

        table.defaultPoint = point
        table.defaultRegion = region
        table.defaultRelativePoint = relativePoint
        table.defaultX = x
        table.defaultY = y

        self:UpdatePoint()
    end

    function g:SetDefaultSize(width, height)
        local table = IMDB.resizableFrames[self:GetName()]

        width = floor(width)
        height = floor(height)

        table.width = table.width or width
        table.height = table.height or height

        table.defaultWidth = width
        table.defaultHeight = height

        self:UpdateSize()
    end

    function g:EnableResizing()
        self:SetMovable(true)
        self.width:Show()
        self.height:Show()
        self.xPos:Show()
        self.yPos:Show()
        self.centerDrag:Show()
        self.bottomDrag:Show()
        self.topDrag:Show()
        self.leftDrag:Show()
        self.rightDrag:Show()
    end

    function g:DisableResizing()
        self:SetMovable(false)
        self.width:Hide()
        self.height:Hide()
        self.xPos:Hide()
        self.yPos:Hide()
        self.centerDrag:Hide()
        self.bottomDrag:Hide()
        self.topDrag:Hide()
        self.leftDrag:Hide()
        self.rightDrag:Hide()
    end

    local function OnSizeChanged(self, ...)
        local width, height = self:GetSize()

        self.bottomDrag:SetSize(width, 10)
        self.topDrag:SetSize(width, 10)
        self.leftDrag:SetSize(10, height)
        self.rightDrag:SetSize(10, height)
    end

    g:SetScript("OnSizeChanged", OnSizeChanged)
    g:DisableResizing()

    return g
end