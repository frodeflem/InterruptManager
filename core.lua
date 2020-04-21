local IM = InterruptManager
IM.rotation = {}

--[[

    Todo:
        - Instance profiles
        - Profiles in general?
        - Reset button on resizing widgets
        - Font settings (font, scale)
        - Autofill based on group composition
        - Check for conditions that cause players to be unable to interrupt
        - WeakAuras integration

]]

--[[
local dataz = {
    ["parent"] = "InterruptManager",
    ["xOffset"] = 0,
    ["untrigger"] = {
    },
    ["mirror"] = false,
    ["yOffset"] = 0,
    ["regionType"] = "texture",
    ["disjunctive"] = "all",
    ["blendMode"] = "BLEND",
    ["activeTriggerMode"] = -10,
    ["conditions"] = {
    },
    ["anchorPoint"] = "CENTER",
    ["actions"] = {
        ["start"] = {
        },
        ["finish"] = {
        },
        ["init"] = {
        },
    },
    ["texture"] = "Textures\\SpellActivationOverlays\\Eclipse_Sun",
    ["animation"] = {
        ["start"] = {
            ["duration_type"] = "seconds",
            ["type"] = "none",
        },
        ["main"] = {
            ["duration_type"] = "seconds",
            ["type"] = "none",
        },
        ["finish"] = {
            ["duration_type"] = "seconds",
            ["type"] = "none",
        },
    },
    ["internalVersion"] = 3,
    ["desaturate"] = false,
    ["selfPoint"] = "CENTER",
    ["id"] = "New 2",
    ["rotation"] = 0,
    ["frameStrata"] = 1,
    ["anchorFrameType"] = "SCREEN",
    ["discrete_rotation"] = 0,
    ["width"] = 200,
    ["numTriggers"] = 1,
    ["trigger"] = {
        ["type"] = "aura",
        ["subeventSuffix"] = "_CAST_START",
        ["event"] = "Health",
        ["unit"] = "player",
        ["spellIds"] = {
        },
        ["showOn"] = "showOnActive",
        ["subeventPrefix"] = "SPELL",
        ["names"] = {
        },
        ["debuffType"] = "HELPFUL",
    },
    ["height"] = 200,
    ["rotate"] = true,
    ["load"] = {
        ["talent2"] = {
            ["multi"] = {
            },
        },
        ["talent"] = {
            ["multi"] = {
            },
        },
        ["class"] = {
            ["multi"] = {
            },
        },
        ["difficulty"] = {
            ["multi"] = {
            },
        },
        ["race"] = {
            ["multi"] = {
            },
        },
        ["role"] = {
            ["multi"] = {
            },
        },
        ["pvptalent"] = {
            ["multi"] = {
            },
        },
        ["spec"] = {
            ["multi"] = {
            },
        },
        ["faction"] = {
            ["multi"] = {
            },
        },
        ["ingroup"] = {
            ["multi"] = {
            },
        },
        ["size"] = {
            ["multi"] = {
            },
        },
    },
    ["color"] = {
        [1] = 1,
        [2] = 1,
        [3] = 1,
        [4] = 0.75,
    },
}

local function ExtractWeakAuraUnitName(id)
    local name = "unknown"
    
    local trigger = WeakAuras.GetData(id).trigger
    if (trigger.type == "aura") then
        name = trigger.specificUnit
    elseif (trigger.type == "status") then
        name = trigger.unit
    end
    
    return name
end

function IM:ScanWeakAuras()
    -- WeakAuras.DeleteOption(data)
    -- WeakAuras.Add(data)
    local db = WeakAurasSaved
    
    if (not db or type(db.displays) ~= "table") then
        return
    end
    
    for k,v in pairs(db.displays) do
        local data = WeakAuras.GetData(k)
        if (type(data) ~= "table") then
            return
        end
        
        if (k == "InterruptManager" and (data.regionType == "group" or data.regionType == "dynamicgroup")) then
            print("Found Weak Auras group!")
            
            for k2,v2 in pairs(data.controlledChildren) do
                print(ExtractWeakAuraUnitName(v2))
            end
            
            --local trigger = data.
        end
    end
end

function Test()
    IM:ScanWeakAuras()
    WeakAuras.Add(dataz)
    if (WeakAurasOptions) then
        WeakAuras.NewDisplayButton(dataz)
    end
    WeakAuras.ReloadAll()
end
]]





function IM:GetVersion() return 169 end
local interruptSpells = IM.GetInterruptSpells()

function IM:Debug(string)
    if (IM.debug) then
        print(string)
    end
end

function IM:InitializeSavedVariables()
    if (not IMDB) then
        IMDB = {}
    end

    IMDB.resizableFrames = IMDB.resizableFrames or {}

    IMDB.anchorAlpha = IMDB.anchorAlpha or 0.2
    IMDB.statusBarAlpha = IMDB.statusBarAlpha or 1
    IMDB.statusBarTextAlpha = IMDB.statusBarTextAlpha or 1
    IMDB.iconAlpha = IMDB.iconAlpha or 0.4
    IMDB.iconTextAlpha = IMDB.iconTextAlpha or 1
    
    IMDB.announce = IMDB.announce or false
    IMDB.targetWarn = IMDB.targetWarn or true
    IMDB.focusWarn = IMDB.focusWarn or false
    IMDB.warnWhenReady = IMDB.warnWhenReady or true
    IMDB.announceChannel = IMDB.announceChannel or "SAY"
    IMDB.pugModeChannel = IMDB.pugModeChannel or "SAY"
    IMDB.numVisibleStatusBars = IMDB.numVisibleStatusBars or 5
    IMDB.maxInterrupters = IMDB.maxInterrupters or 5
    
    IMDB.version = IM.GetVersion()
end

function IM:UpdateStatusBarCount()
    -- This function will create the necessary amount of status bars
    if (not IM.statusBars) then
        IM.statusBars = {}
    end

    for k,v in pairs(IM.statusBars) do
        if (not IMDB.interrupters[k]) then
            v:Hide()
        end
    end

    for i = 1, IMDB.maxInterrupters do
        if (IMDB.interrupters[i]) then
            if (not IM.statusBars[i]) then
                local f = CreateFrame("StatusBar", "InterruptManagerStatusBar" .. i, InterruptManagerAnchor)
                local width, height = f:GetParent():GetSize()
                local fontSize = 0.58 * height / IMDB.numVisibleStatusBars
                local barHeight = height / IMDB.numVisibleStatusBars
                f:SetOrientation("HORIZONTAL")
                f:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
                f:SetStatusBarColor(0, 1, 0, IMDB.statusBarAlpha)
                f:SetFrameLevel(3)
                f:SetID(i)
                f:SetMinMaxValues(0, 1)
                f:SetValue(0)
                tinsert(IM.statusBars, f)
                
                -- f.text = f:CreateFontString()
                f.text = IM:CreateFontString(nil, f, nil, true)
                f.text:SetPoint("LEFT", f, "LEFT", 5, 0)
                f.text:SetJustifyH("LEFT")
                f.text:SetTextColor(1, 1, 1, IMDB.statusBarTextAlpha)
                
                f.cooldownText = IM:CreateFontString(nil, f, "OUTLINE")
                f.cooldownText:SetPoint("RIGHT", f, "RIGHT", 3, 0)
                f.cooldownText:SetJustifyH("LEFT")
                f.cooldownText:SetTextColor(1, 1, 1, IMDB.statusBarTextAlpha)

                
                local g = CreateFrame("Frame", "InterruptManagerIcon" .. i, f)
                f.icon = g
                g:SetPoint("RIGHT", f, "LEFT")
                
                local t = g:CreateTexture()
                t:SetAllPoints(g)
                t:SetColorTexture(0, 0, 0, IMDB.iconAlpha)
                
                local t = IM:CreateFontString(nil, g)
                g.text = t
                t:SetAllPoints(g)
                t:SetText(i)
                t:SetTextColor(1, 1, 1, IMDB.iconTextAlpha)



                local function OnValueChanged(self, value)
                    if (value <= 0) then
                        self.cooldownText:SetText("")
                    else
                        self.cooldownText:SetText(roundString(value, 1))
                    end
                end

                f:SetScript("OnValueChanged", OnValueChanged)

                function f:UpdateSize()
                    if (IMDB.numVisibleStatusBars == 0) then
                        return
                    end

                    local width, height = self:GetParent():GetSize()
                    local fontSize = 0.62 * height / IMDB.numVisibleStatusBars
                    local barHeight = height / IMDB.numVisibleStatusBars
                    local iconWidth = barHeight

                    if (iconWidth > width / 7) then
                        iconWidth = width / 7
                    end

                    if (fontSize > width / 15) then
                        fontSize = width / 15
                    end

                    self:SetSize(width - iconWidth, barHeight)
                    self:SetPoint("TOPRIGHT", InterruptManagerAnchor, "TOPRIGHT", 0, (1 - self:GetID()) * barHeight)

                    self.text:SetSize(width - 5, barHeight)
                    self.text:SetFontSize(fontSize)

                    self.cooldownText:SetSize(2 * barHeight, barHeight)
                    self.cooldownText:SetFontSize(fontSize)

                    self.icon:SetSize(iconWidth, barHeight)
                    self.icon.text:SetFontSize(fontSize)
                end

                f:UpdateSize()
            else
                IM.statusBars[i]:Show()
            end
        end
    end
end

function IM:OnLoad()
    --IM.debug = true
    IM:Debug("InterruptManager debug enabled")

    if (IMDB) then
        IM.previousVersion = IMDB.version or 0
    else
        IM.previousVersion = 0
    end
    
    if (not IMDB or not IMDB.version or IMDB.version < 168) then
        IMDB = {}
        IMDB.interrupters = {}
    end

    IM:UpdateUnitReferences()
    IM.positionReferences = {unpack(IMDB.interrupters)}
    for k,v in pairs(IMDB.interrupters) do
        if (v.name == UnitName("player")) then
            IM.selfReference = v
        end
    end
    
    IM:InitializeSavedVariables()
    
    -- Create the bars
    do
        local function OnSizeChanged(self, ...)
            local width, height = self:GetSize()
    
            self.bottomDrag:SetSize(width, 10)
            self.topDrag:SetSize(width, 10)
            self.leftDrag:SetSize(10, height)
            self.rightDrag:SetSize(10, height)

            for k,v in pairs(IM.statusBars) do
                v:UpdateSize()
            end
        end

        local f = IM:CreateResizableFrame("Frame", "InterruptManagerAnchor", UIParent)
        f:SetDefaultSize(180, 100)
        f:SetDefaultPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", GetScreenWidth() / 2 - 90, GetScreenHeight() * 0.15)
        f:SetScript("OnSizeChanged", OnSizeChanged)
        
        local t = f:CreateTexture()
        t:SetColorTexture(0, 0, 0, IMDB.anchorAlpha)
        t:SetAllPoints(f)
        
        IM:UpdateStatusBarCount()
    end
    
    -- Create the mid-screen warning text frame
    do
        local f = IM:CreateResizableFrame("MessageFrame", "InterruptManagerText", UIParent)
        f:SetDefaultSize(500, 50)
        f:SetDefaultPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", GetScreenWidth() / 2 - 250, GetScreenHeight() * 0.8)
        f:SetFontObject(BossEmoteNormalHuge)
        f:SetScript("OnMouseDown", nil)
        f:SetScript("OnMouseUp", nil)
        f.isDragging = false

        local t = f:CreateTexture()
        f.texture = t
        t:SetAllPoints(f)

        local fontPath = f:GetFont()
        f:SetFont(fontPath, 35, "OUTLINE")
        f:SetFadeDuration(0.4)
    end
    

    local function OnUpdate()
        for k,v in pairs(IM.statusBars) do
            local interrupter = IM.positionReferences[k]

            if (interrupter and not interrupter.ready) then
                -- Interrupt spell ready/not ready
                if (interrupter.readyTime - GetTime() <= 0) then
                    v:SetValue(0)
                    interrupter.ready = true
                    return
                end
                
                -- Update StatusBar values
                v:SetValue(interrupter.readyTime - GetTime())
            end
        end
    end
    
    local f = InterruptManagerFrame
    f:UnregisterEvent("ADDON_LOADED")
    f:RegisterEvent("CHAT_MSG_ADDON")
    f:RegisterEvent("CHAT_MSG_SYSTEM")
    f:RegisterEvent("UNIT_SPELLCAST_START")
    f:RegisterEvent("UNIT_SPELLCAST_STOP")
    f:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    f:RegisterEvent("UNIT_FLAGS")
    f:RegisterEvent("GROUP_ROSTER_UPDATE")
    f:RegisterEvent("LOADING_SCREEN_DISABLED")
    f:RegisterEvent("PLAYER_TARGET_CHANGED")
    f:RegisterEvent("PLAYER_FOCUS_CHANGED")
    f:RegisterEvent("LOADING_SCREEN_DISABLED")
    f:SetScript("OnUpdate", OnUpdate)
    
    C_ChatInfo.RegisterAddonMessagePrefix("InterruptManager")
end

function IM_OnEvent(self, event, ...)
    if (_G["IM_" .. event]) then
        _G["IM_" .. event](...)
    else
        print("Unhandled event registered by InterruptManager: " .. event)
    end
end

function IM:SetNumVisibleStatusBars(numVisibleStatusBars)
    -- Update anchor size
    if (numVisibleStatusBars == 0) then
        InterruptManagerAnchor:Hide()
    else
        InterruptManagerAnchor:Show()
        IMDB.resizableFrames["InterruptManagerAnchor"].height = floor(IMDB.resizableFrames["InterruptManagerAnchor"].height * (numVisibleStatusBars / IMDB.numVisibleStatusBars))
        IM.resizableFrames["InterruptManagerAnchor"]:UpdateSize()
        IMDB.numVisibleStatusBars = numVisibleStatusBars
    end
end

function IM:IsUnitOffline(unit)
    if (not UnitExists(unit) or not UnitIsConnected(unit)) then
        return true
    else
        return false
    end
end

function IM:IsUnitDead(unit)
    if (unit and UnitIsDead(unit)) then -- Removed UnitBuff(unit, "Feign Death") with 8.0 API changes
        return true
    else
        return false
    end
end

function IM:CheckDuplicateCharacterNames()
    for k1,v1 in pairs(IMDB.interrupters) do
        for k2,v2 in pairs(IMDB.interrupters) do
            if (v1.characterName == v2.characterName and k1 ~= k2) then
                v1.displayName = v1.characterName .. "-" .. v1.serverName
                break
            end
        end
    end
end

function StandardSortFunction(a, b)
    -- Returns true if a should be placed before b
    if (a.available and b.available) then
        return a.readyTime < b.readyTime
    elseif (not a.available and not b.available) then
        return a.readyTime < b.readyTime
    elseif (a.available) then
        return true
    else
        return false
    end
end

function IM:UpdateInterruptRotation()
    for k,v in pairs(IMDB.interrupters) do
        if (IM:IsUnitOffline(v.unit)) then
            v.offline = true
        else
            v.offline = false
        end

        if (IM:IsUnitDead(v.unit)) then
            v.dead = true
        else
            v.dead = false
        end

        if (v.offline or v.dead) then
            v.available = false
        else
            v.available = true
        end
    end

    table.sort(IM.positionReferences, StandardSortFunction)
    
    -- Update the UI to reflect the updated rotation
    for k,v in pairs(IM.statusBars) do
        local interrupter = IM.positionReferences[k]
        if (not interrupter) then
            break
        end

        if (interrupter.offline) then
            v.text:SetText("(Offline) " .. interrupter.displayName)
        elseif (interrupter.dead) then
            v.text:SetText("(Dead) " .. interrupter.displayName)
        else
            v.text:SetText(interrupter.displayName)
        end

        v:SetMinMaxValues(0, interrupter.cooldown)
    end
end

function IM_LOADING_SCREEN_DISABLED()
    IM:UpdateStatusBarCount()
    IM:SetNumVisibleStatusBars(#IMDB.interrupters)
    IM:UpdateInterruptRotation()
    
    -- Status bars aren't updated while loading screen is enabled, nor when the value they are supposed to display is <= 0
    -- which can result in them not being updated if said value reaches 0 during the loading screen
    -- This is the fix:
    for k,v in pairs(IM.statusBars) do
        local interrupter = IM.positionReferences[k]

        if (interrupter and not v.ready) then
            -- Interrupt spell ready/not ready
            if (interrupter.readyTime - GetTime() <= 0) then
                interrupter.ready = true
                v:SetValue(0)
            end
        end
    end
end

function IM:UpdateUnitReferences()
    -- Store names in a temp table, cause table lookup is faster than iterating through it,
    -- and raids are potentially large
    local temp = {}
    
    if (IsInRaid()) then
        for i = 1, GetNumGroupMembers() do
            local unit = "raid" .. i
            local unitName = IM:GetFullUnitName(unit)

            temp[unitName] = unit
        end

    else
        local unit = "player"
        local unitName = IM:GetFullUnitName(unit)

        temp[unitName] = unit

        for i = 1, GetNumGroupMembers() - 1 do
            local unit = "party" .. i
            local unitName = IM:GetFullUnitName(unit)

            temp[unitName] = unit
        end
    end

    for k,v in pairs(IMDB.interrupters) do
        v.unit = temp[v.characterName .. "-" .. v.serverName]
    end
end

function IM_GROUP_ROSTER_UPDATE()
    IM:UpdateInterruptRotation()
    IM:UpdateUnitReferences()
end

function IM_UNIT_FLAGS(...)
    local unit = ...
    local unitName = UnitName(unit)
    
    IM:UpdateInterruptRotation()
end

function IM_UNIT_SPELLCAST_START(...)
    local unit = ...
    
    if (unit == "focus" and (#IMDB.interrupters > 0 or IMDB.soloMode)) then
        local startTime, endTime, _, _, interruptImmune = select(4, UnitCastingInfo("focus"))

        if (not interruptImmune and IMDB.focusWarn and UnitCanAttack("player", "focus")) then
            if (IMDB.soloMode or IM.positionReferences[1].name == UnitName("player")) then

                if (IMDB.warnWhenReady and IM.selfReference and not IM.selfReference.ready) then
                    return
                end
            
                local timeVisible = 10
                if (startTime and endTime) then
                    timeVisible = (endTime - startTime) / 1000
                end
                
                local text
                if (IMDB.targetWarn) then
                    text = "Interrupt now! (focus)"
                else
                    text = "Interrupt now!"
                end
                
                InterruptManagerText:AddMessage(text, 1,0.5,1)
                InterruptManagerText:SetTimeVisible(timeVisible)
                InterruptManagerText.text = text
                PlaySoundFile("Interface\\AddOns\\InterruptManager\\Sounds\\InterruptNow.ogg")
            end
        end

    elseif (unit == "target" and (#IMDB.interrupters > 0 or IMDB.soloMode)) then
        local startTime, endTime, _, _, interruptImmune = select(4, UnitCastingInfo("target"))

        if (not interruptImmune and IMDB.targetWarn and UnitCanAttack("player", "target")) then
            if (IMDB.soloMode or IM.positionReferences[1].name == UnitName("player")) then

                if (IMDB.warnWhenReady and IM.selfReference and not IM.selfReference.ready) then
                    return
                end

                local timeVisible = 10
                if (startTime and endTime) then
                    timeVisible = (endTime - startTime) / 1000
                end

                local text
                if (IMDB.focusWarn) then
                    text = "Interrupt now! (target)"
                else
                    text = "Interrupt now!"
                end
                
                InterruptManagerText:AddMessage(text, 1,1,1)
                InterruptManagerText:SetTimeVisible(timeVisible)
                InterruptManagerText.text = text
                PlaySoundFile("Interface\\AddOns\\InterruptManager\\Sounds\\InterruptNow.ogg")
            end
        end
    end
end

function IM_UNIT_SPELLCAST_STOP(...)
    local unit = ...
    
    if (unit == "target" and (InterruptManagerText.text == "Interrupt now! (target)" or InterruptManagerText.text == "Interrupt now!")) then
        InterruptManagerText:SetTimeVisible(0)

    elseif (unit == "focus" and (InterruptManagerText.text == "Interrupt now! (focus)" or InterruptManagerText.text == "Interrupt now!")) then
        InterruptManagerText:SetTimeVisible(0)
    end
end

-- [Function to prevent system message spam] --
ChatFrame_AddMessageEventFilter("CHAT_MSG_SYSTEM", function(self, event, msg)
    if(strfind(msg, "No player named ")) then
        --return true
    end
end)
local AntiSpam = {{},{}}
function IM_CHAT_MSG_SYSTEM(...)
    local text = ...
    if (strfind(text, "No player named ")) then
        if (not tContains(AntiSpam[1],text)) then
            DEFAULT_CHAT_FRAME:AddMessage(text,1,1,0)
            tinsert(AntiSpam[1],text)
            tinsert(AntiSpam[2],GetTime()+1)
        else
            for k,v in pairs(AntiSpam[1]) do
                if (v == text) then
                    if (GetTime() >= AntiSpam[2][k]) then
                        AntiSpam[2][k] = GetTime()+1
                        DEFAULT_CHAT_FRAME:AddMessage(text,1,1,0)
                    end
                end
            end
        end
    end
end

function IM_CHAT_MSG_ADDON(...)
    local prefix = ...
    if (prefix == "InterruptManager") then
        IM:AddonMessageReceived(...)
    end
end

function IM_ADDON_LOADED(...)
    local addonName = ...
    if (addonName == "InterruptManager") then
        IM:OnLoad()
    end
end

function IM_COMBAT_LOG_EVENT_UNFILTERED()
    local _, event, _, sourceGUID, sourceName, _, _, _, _, _, _, spellId, spellName = CombatLogGetCurrentEventInfo()
    
    if (event == "SPELL_CAST_SUCCESS") then
        if (tContains(interruptSpells.spellId, spellId)) then
            -- If an interrupt spell was cast
            IM:InterruptUsed(sourceName, spellId)
            
            -- Announce my interrupt
            if (sourceGUID == UnitGUID("player") and IMDB.announce) then
                IM:AnnounceMyInterrupt(spellName)
            end
        end
    end
end

function IM_PLAYER_REGEN_DISABLED()

end

function IM_PLAYER_REGEN_ENABLED()
    
end

function IM_PLAYER_TARGET_CHANGED()
    if (UnitCastingInfo("target")) then
        IM_UNIT_SPELLCAST_START("target")
    else
        IM_UNIT_SPELLCAST_STOP("target")
    end
end

function IM_PLAYER_FOCUS_CHANGED()
    if (UnitCastingInfo("focus")) then
        IM_UNIT_SPELLCAST_START("focus")
    else
        IM_UNIT_SPELLCAST_STOP("focus")
    end
end

local f = CreateFrame("Frame", "InterruptManagerFrame", UIParent)
f:SetScript("OnEvent", IM_OnEvent)
f:RegisterEvent("ADDON_LOADED")

function IM:GetFullUnitName(unit)
    local characterName, serverName = UnitName(unit)

    if (serverName and serverName ~= "") then
        return characterName .. "-" .. serverName
    else
        return characterName .. "-" .. GetRealmName()
    end
end

function IM:GetFullName(text)
    -- Returns "Charactername-Servername" with "Charactername" or "Charactername-Servername" as input
    return IM:GetCharacterName(text) .. "-" .. IM:GetServerName(text)
end

function IM:GetCharacterName(text)
    -- Returns "Charactername", with "Charactername" or "Charactername-Servername" as input
    return string.find(text, "-") and string.match(text, "(.+)-") or text
end

function IM:GetServerName(text)
    -- Returns "Servername", with "Charactername" (in that case, returns GetRealmName()) or "Charactername-Servername" as input
    local textContainsServerName = string.find(text, "-")

    if (textContainsServerName) then
        return string.find(text, "-") and string.match(text, "-(.+)") or GetRealmName()
    else
        local serverNames = {}
        
        if (IsInRaid()) then
            for i = 1, GetNumGroupMembers() do
                local characterName, serverName = UnitName("raid" .. i)
                if (string.find(characterName, text)) then
                    tinsert(serverNames, serverName)
                end
            end
        else
            local characterName = UnitName("player")

            if (string.find(characterName, text)) then
                tinsert(serverNames, GetRealmName())
            end

            for i = 1, GetNumGroupMembers() - 1 do
                local characterName, serverName = UnitName("party" .. i)

                if (not serverName or serverName == "") then
                    serverName = GetRealmName()
                end

                if (string.find(characterName, text)) then
                    tinsert(serverNames, serverName)
                end
            end
        end

        if (#serverNames == 0) then
            return ""
        else
            return unpack(serverNames)
        end
    end
end

function IM:GetAnnounceChannel(c)
    local channel

    if (c == "RAID_WARNING" and IsInRaid(LE_PARTY_CATEGORY_HOME) and (UnitIsGroupLeader("player") or UnitIsGroupAssistant("player"))) then
        channel = "RAID_WARNING"
    elseif ((c == "RAID" or c == "RAID_WARNING") and IsInRaid(LE_PARTY_CATEGORY_HOME)) then
        channel = "RAID"
    elseif ((c == "RAID" or c == "PARTY") and IsInGroup(LE_PARTY_CATEGORY_HOME)) then
        channel = "PARTY"
    elseif (c == "INSTANCE_CHAT") then
        if (IsInGroup(LE_PARTY_CATEGORY_INSTANCE) or IsInRaid(LE_PARTY_CATEGORY_INSTANCE)) then
            channel = "INSTANCE_CHAT"
        elseif (IsInRaid(LE_PARTY_CATEGORY_HOME)) then
            channel = "RAID"
        elseif (IsInGroup(LE_PARTY_CATEGORY_HOME)) then
            channel = "PARTY"
        -- else
        --     channel = "SAY"
        end
    elseif (c == "YELL") then
        channel = "YELL"
    else
        channel = "SAY"
    end

    return channel
end

function IM:PugModeInterruptHandler()
    if (#IMDB.interrupters > 0 and IM.pugMode and IMDB.leader) then
        local c = IMDB.pugModeChannel
        
        if (c == "WHISPER") then
            SendChatMessage("InterruptManager: You are interrupting next", "WHISPER", nil, IM.positionReferences[1].name)
        else
            local channel = IM:GetAnnounceChannel(c)
            IM:Debug(c)

            if (channel) then
                SendChatMessage("Interrupting next: " .. IM.positionReferences[1].displayName, channel)
            end
        end
    end
end

function IM:HideOutgoingWhisper(...)
    local event, msg = ...

    if (msg == "InterruptManager: You are interrupting next") then
        return true
    else
        return false
    end
end
ChatFrame_AddMessageEventFilter("CHAT_MSG_WHISPER_INFORM", IM.HideOutgoingWhisper)

function IM:InterruptUsed(sourceName, spellId)
    for k,v in pairs(IMDB.interrupters) do
        if (sourceName == v.name) then
            for k2,v2 in pairs(interruptSpells.spellId) do
                if (v2 == spellId) then
                    v.cooldown = interruptSpells.cooldown[k2]
                    v.readyTime = GetTime() + v.cooldown
                    v.ready = false
                    IM:UpdateInterruptRotation()
                    IM:PugModeInterruptHandler()
                end
            end
        end
    end
end

-- Function for announcing my own interrupt, as well as interrupt rotation in pug-mode
function IM:AnnounceMyInterrupt(spellName)
    local c = IMDB.announceChannel
    local channel = IM:GetAnnounceChannel(c)
    
    if (channel) then
        SendChatMessage("Used " .. spellName, channel)
    end
end

SLASH_INTERRUPTMANAGER1 = '/im'
SLASH_INTERRUPTMANAGER2 = '/ima'
SLASH_INTERRUPTMANAGER3 = '/interruptmanager'
function SlashCmdList.INTERRUPTMANAGER(msg, editbox)
    IM:OpenConfig()
    IM:InitializeNewFeatures()
end