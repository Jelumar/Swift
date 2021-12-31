--[[
Swift_2_Typewriter/Source

Copyright (C) 2021 totalwarANGEL - All Rights Reserved.

This file is part of Swift. Swift is created by totalwarANGEL.
You may use and modify this file unter the terms of the MIT licence.
(See https://en.wikipedia.org/wiki/MIT_License)
]]

ModuleTypewriter = {
    Properties = {
        Name = "ModuleTypewriter",
    },

    Global = {
        TypewriterEventData = {},
        TypewriterEventQueue = {},
        TypewriterEventCounter = 0,
    },
    Local = {},
    -- This is a shared structure but the values are asynchronous!
    Shared = {};
}

-- Global Script ---------------------------------------------------------------

function ModuleTypewriter.Global:OnGameStart()
    QSB.ScriptEvents.TypewriterStarted = API.RegisterScriptEvent("Event_TypewriterStarted");
    QSB.ScriptEvents.TypewriterEnded = API.RegisterScriptEvent("Event_TypewriterEnded");

    for i= 1, 8 do
        self.TypewriterEventQueue[i] = {};
    end
    StartSimpleHiResJobEx(function()
        ModuleTypewriter.Global:ControlTypewriter();
    end);
end

function ModuleTypewriter.Global:StartTypewriter(_Data)
    self.TypewriterEventCounter = self.TypewriterEventCounter +1;
    local EventName = "CinematicEvent_Typewriter" ..self.TypewriterEventCounter;
    _Data.Name = EventName;
    if API.IsLoadscreenVisible() or API.IsCinematicEventActive(_Data.PlayerID) then
        table.insert(self.TypewriterEventQueue[_Data.PlayerID], _Data);
        return _Data.Name;
    end
    return self:PlayTypewriter(_Data);
end

function ModuleTypewriter.Global:PlayTypewriter(_Data)
    local ID = API.StartCinematicEvent(_Data.Name, _Data.PlayerID);
    _Data.ID = ID;
    _Data.TextTokens = self:TokenizeText(_Data);
    self.TypewriterEventData[_Data.PlayerID] = _Data;
    Logic.ExecuteInLuaLocalState(string.format(
        [[
        if GUI.GetPlayerID() == %d then
            API.ActivateColoredScreen(%d, %d, %d, %d);
            API.DeactivateNormalInterface();
            API.DeactivateBorderScroll(%d);
            Input.CutsceneMode()
            GUI.ClearNotes()
        end
        ]],
        _Data.PlayerID,
        _Data.Color.R,
        _Data.Color.G,
        _Data.Color.B,
        _Data.Color.A,
        _Data.TargetEntity
    ));

    API.SendScriptEvent(QSB.ScriptEvents.TypewriterStarted, _Data.PlayerID, _Data);
    Logic.ExecuteInLuaLocalState(string.format(
        [[API.SendScriptEvent(%d, %d, %s)]],
        QSB.ScriptEvents.TypewriterStarted,
        _Data.PlayerID,
        table.tostring(_Data)
    ));
    return _Data.Name;
end

function ModuleTypewriter.Global:FinishTypewriter(_PlayerID)
    if self.TypewriterEventData[_PlayerID] then
        local EventData = table.copy(self.TypewriterEventData[_PlayerID]);
        local EventPlayer = self.TypewriterEventData[_PlayerID].PlayerID;
        Logic.ExecuteInLuaLocalState(string.format(
            [[
            if GUI.GetPlayerID() == %d then
                API.DeactivateColoredScreen()
                API.ActivateNormalInterface()
                API.ActivateBorderScroll()
                Input.GameMode()
                GUI.ClearNotes()
            end
            ]],
            _PlayerID
        ));
        self.TypewriterEventData[_PlayerID]:Callback();
        self.TypewriterEventData[_PlayerID] = nil;

        API.FinishCinematicEvent(EventData.Name, EventPlayer);
        API.SendScriptEvent(QSB.ScriptEvents.TypewriterEnded, EventPlayer, EventData);
        Logic.ExecuteInLuaLocalState(string.format(
            [[API.SendScriptEvent(%d, %d, %s)]],
            QSB.ScriptEvents.TypewriterEnded,
            EventPlayer,
            table.tostring(EventData)
        ));
    end
end

function ModuleTypewriter.Global:TokenizeText(_Data)
    local TextTokens = {};
    _Data.Text = _Data.Text:gsub("%s+", " ");
    local TempTokens = {};
    local Text = _Data.Text;
    while (true) do
        local s1, e1 = Text:find("{");
        local s2, e2 = Text:find("}");
        if not s1 or not s2 then
            table.insert(TempTokens, Text);
            break;
        end
        if s1 > 1 then
            table.insert(TempTokens, Text:sub(1, s1 -1));
        end
        table.insert(TempTokens, Text:sub(s1, e2));
        Text = Text:sub(e2 +1);
    end

    local LastWasPlaceholder = false;
    for i= 1, #TempTokens, 1 do
        if TempTokens[i]:find("{") then
            local Index = #TextTokens;
            if LastWasPlaceholder then
                TextTokens[Index] = TextTokens[Index] .. TempTokens[i];
            else
                table.insert(TextTokens, Index+1, TempTokens[i]);
            end
            LastWasPlaceholder = true;
        else
            local Index = 1;
            while (Index <= #TempTokens[i]) do
                if string.byte(TempTokens[i]:sub(Index, Index)) == 195 then
                    table.insert(TextTokens, TempTokens[i]:sub(Index, Index+1));
                    Index = Index +1;
                else
                    table.insert(TextTokens, TempTokens[i]:sub(Index, Index));
                end
                Index = Index +1;
            end
            LastWasPlaceholder = false;
        end
    end
    return TextTokens;
end

function ModuleTypewriter.Global:ControlTypewriter()
    -- Check queue for next event
    for k, v in pairs(self.TypewriterEventQueue) do
        if not API.IsLoadscreenVisible() and not API.IsCinematicEventActive(k) then
            if #v > 0 then
                local Data = table.remove(self.TypewriterEventQueue[k], 1);
                self:PlayTypewriter(Data);
            end
        end
    end

    -- Perform active events
    for k, v in pairs(self.TypewriterEventData) do
        if self.TypewriterEventData[k].Delay > 0 then
            self.TypewriterEventData[k].Delay = self.TypewriterEventData[k].Delay -1;
            -- Just my paranoia...
            Logic.ExecuteInLuaLocalState(string.format(
                [[if GUI.GetPlayerID() == %d then GUI.ClearNotes() end]],
                self.TypewriterEventData[k].PlayerID
            ));
        end
        if self.TypewriterEventData[k].Delay == 0 then
            self.TypewriterEventData[k].Index = v.Index + v.CharSpeed;
            if v.Index > #self.TypewriterEventData[k].TextTokens then
                self.TypewriterEventData[k].Index = #self.TypewriterEventData[k].TextTokens;
            end
            local Index = math.floor(v.Index + 0.5);
            local Text = "";
            for i= 1, Index, 1 do
                Text = Text .. self.TypewriterEventData[k].TextTokens[i];
            end
            Logic.ExecuteInLuaLocalState(string.format(
                [[
                if GUI.GetPlayerID() == %d then
                    GUI.ClearNotes()
                    GUI.AddNote("]] ..Text.. [[");
                end
                ]],
                self.TypewriterEventData[k].PlayerID
            ));
            if Index == #self.TypewriterEventData[k].TextTokens then
                self.TypewriterEventData[k].Waittime = v.Waittime -1;
                if v.Waittime <= 0 then
                    self:FinishTypewriter(k);
                end
            end
        end
    end
end

-- Local Script ----------------------------------------------------------------

function ModuleTypewriter.Local:OnGameStart()
    QSB.ScriptEvents.TypewriterStarted = API.RegisterScriptEvent("Event_TypewriterStarted");
    QSB.ScriptEvents.TypewriterEnded = API.RegisterScriptEvent("Event_TypewriterEnded");
end

-- -------------------------------------------------------------------------- --

Swift:RegisterModule(ModuleTypewriter);

