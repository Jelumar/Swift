--[[
Swift_0_Core/Swift

Copyright (C) 2021 - 2022 totalwarANGEL - All Rights Reserved.

This file is part of Swift. Swift is created by totalwarANGEL.
You may use and modify this file unter the terms of the MIT licence.
(See https://en.wikipedia.org/wiki/MIT_License)
]]

API = API or {};
QSB = QSB or {};
SCP = SCP or {
    Core = {}
};

QSB.Version = "Version 3.0.0 BETA (1.1.18-3)";
QSB.Language = "de";
QSB.HumanPlayerID = 1;
QSB.ScriptCommandSequence = 2;
QSB.ScriptCommands = {};
QSB.ScriptEvents = {};
QSB.CustomVariable = {};

Swift = Swift or {};

ParameterType = ParameterType or {};
g_QuestBehaviorVersion = 1;
g_QuestBehaviorTypes = {};

---
-- AddOn Versionsnummer
-- @local
--
g_GameExtraNo = 0;
if Framework then
    g_GameExtraNo = Framework.GetGameExtraNo();
elseif MapEditor then
    g_GameExtraNo = MapEditor.GetGameExtraNo();
end

-- Core  -------------------------------------------------------------------- --

Swift = {
    m_ModuleRegister            = {};
    m_BehaviorRegister          = {};
    m_ScriptEventRegister       = {};
    m_ScriptEventListener       = {};
    m_ScriptCommandRegister     = {};
    m_AIProperties              = {};
    m_Language                  = "de";
    m_Environment               = "global";
    m_ProcessDebugCommands      = false;
    m_NoQuicksaveConditions     = {};
    m_LogLevel                  = 2;
    m_FileLogLevel              = 3;
};

function Swift:LoadCore()
    self:OverrideString();
    self:OverrideTable();
    self:OverrideMath();
    self:DetectEnvironment();
    self:DetectLanguage();

    if self:IsGlobalEnvironment() then
        self:InitalizeDebugModeGlobal();
        self:InitalizeScriptCommands();
        self:InitalizeEventsGlobal();
        self:InitalizeAIVariables();
        self:InstallBehaviorGlobal();
        self:OverrideQuestSystemGlobal();
        self:InitalizeCallbackGlobal();
        self:OverrideOnMPGameStart();
        self:DisableLogicFestival();
        self:InitalizeBugfixesGlobal();
    end

    if self:IsLocalEnvironment() then
        self:InitalizeDebugModeLocal();
        self:InitalizeEventsLocal();
        self:InstallBehaviorLocal();
        self:OverrideDoQuicksave();
        self:AlterQuickSaveHotkey();
        self:InitalizeCallbackLocal();
        self:ValidateTerritories();
        self:InitalizeBugfixesLocal();

        -- Saving human player ID makes only sense in singleplayer context
        -- 'cause in multiplayer there would be more than one.
        -- FIXME Find sufficient solution for this!
        if not Framework.IsNetworkGame() then
            local HumanID = GUI.GetPlayerID();
            GUI.SendScriptCommand("QSB.HumanPlayerID = " ..HumanID);
            QSB.HumanPlayerID = HumanID;
        end
        StartSimpleHiResJob("Swift_EventJob_WaitForLoadScreenHidden");
    end
    self:LoadExternFiles();
    self:LoadBehaviors();
    -- Copy texture positions
    if self:IsLocalEnvironment() then
        StartSimpleJobEx(function()
            if Logic.GetTime() > 1 then
                for k, v in pairs(g_TexturePositions) do
                    for kk, vv in pairs(v) do
                        Swift:DispatchScriptCommand(
                            QSB.ScriptCommands.UpdateTexturePosition,
                            GUI.GetPlayerID(),
                            k,
                            kk,
                            vv
                        );
                    end
                end
                return true;
            end
        end);
    end
end

-- Modules

function Swift:LoadModules()
    for i= 1, #self.m_ModuleRegister, 1 do
        if self:IsGlobalEnvironment() then 
            self.m_ModuleRegister[i]["Local"] = nil;
            if self.m_ModuleRegister[i]["Global"].OnGameStart then
                self.m_ModuleRegister[i]["Global"]:OnGameStart();
            end
        end
        if self:IsLocalEnvironment() then
            self.m_ModuleRegister[i]["Global"] = nil;
            if self.m_ModuleRegister[i]["Local"].OnGameStart then
                self.m_ModuleRegister[i]["Local"]:OnGameStart();
            end
        end
    end
end

function Swift:RegisterModule(_Module)
    if (type(_Module) ~= "table") then
        assert(false, "Modules must be tables!");
        return;
    end
    if _Module.Properties == nil or _Module.Properties.Name == nil then
        assert(false, "Expected name for Module!");
        return;
    end
    table.insert(self.m_ModuleRegister, _Module);
end

function Swift:IsModuleRegistered(_Name)
    for k, v in pairs(self.m_ModuleRegister) do
        return v.Properties and v.Properties.Name == _Name;
    end
end

-- Random Seed

function Swift:CreateRandomSeed()
    local Seed = 0;
    local MapName = Framework.GetCurrentMapName();
    local MapType = Framework.GetCurrentMapTypeAndCampaignName();
    local SeedString = Framework.GetMapGUID(MapName, MapType);
    for PlayerID = 1, 8 do
        if Logic.PlayerGetIsHumanFlag(PlayerID) and Logic.PlayerGetGameState(PlayerID) ~= 0 then
            if GUI.GetPlayerID() == PlayerID then
                local PlayerName = Logic.GetPlayerName(PlayerID);
                local DateText = Framework.GetSystemTimeDateString();
                SeedString = SeedString .. PlayerName .. " " .. DateText;
                for s in SeedString:gmatch(".") do
                    Seed = Seed + ((tonumber(s) ~= nil and tonumber(s)) or s:byte());
                end
                if Framework.IsNetworkGame() then
                    Swift:DispatchScriptCommand(QSB.ScriptCommands.ProclaimateRandomSeed, 0, Seed);
                else
                    GUI.SendScriptCommand("SCP.Core.ProclaimateRandomSeed(" ..Seed.. ")");
                end
            end
            break;
        end
    end
end

function Swift:OverrideOnMPGameStart()
    GameCallback_OnMPGameStart = function()
        Trigger.RequestTrigger(Events.LOGIC_EVENT_EVERY_TURN, "", "VictoryConditionHandler", 1)
    end
end

-- Predicate Connectors

NOT = function(_ID, _Predicate)
    local Predicate = table.copy(_Predicate);
    local Function = table.remove(Predicate, 1);
    return not Function(_ID, unpack(Predicate));
end

XOR = function(_ID, ...)
    local Predicates = table.copy(arg);
    local Truths = 0;
    for i= 1, #Predicates do
        local Predicate = table.remove(Predicates[i], 1);
        Truths = Truths + ((Predicate(_ID, unpack(Predicates[i])) and 1) or 0);
    end
    return Truths == 1;
end

ALL = function(_ID, ...)
    local Predicates = table.copy(arg);
    for i= 1, #Predicates do
        local Predicate = table.remove(Predicates[i], 1);
        if not Predicate(_ID, unpack(Predicates[i])) then
            return false;
        end
    end
    return true;
end

ANY = function(_ID, ...)
    local Predicates = table.copy(arg);
    for i= 1, #Predicates do
        local Predicate = table.remove(Predicates[i], 1);
        if Predicate(_ID, unpack(Predicates[i])) then
            return true;
        end
    end
    return false;
end

-- Quests

function Swift:OverrideQuestSystemGlobal()
    QuestTemplate.Trigger_Orig_QSB_Core = QuestTemplate.Trigger
    QuestTemplate.Trigger = function(_quest)
        QuestTemplate.Trigger_Orig_QSB_Core(_quest);
        for i=1,_quest.Objectives[0] do
            if _quest.Objectives[i].Type == Objective.Custom2 and _quest.Objectives[i].Data[1].SetDescriptionOverwrite then
                local Desc = _quest.Objectives[i].Data[1]:SetDescriptionOverwrite(_quest);
                Swift:ChangeCustomQuestCaptionText(Desc, _quest);
                break;
            end
        end
        Swift:SendQuestStateEvent(_quest.Identifier, "QuestTrigger");
    end

    QuestTemplate.Interrupt_Orig_QSB_Core = QuestTemplate.Interrupt;
    QuestTemplate.Interrupt = function(_Quest)
        _Quest:Interrupt_Orig_QSB_Core();

        for i=1, _Quest.Objectives[0] do
            if _Quest.Objectives[i].Type == Objective.Custom2 and _Quest.Objectives[i].Data[1].Interrupt then
                _Quest.Objectives[i].Data[1]:Interrupt(_Quest, i);
            end
        end
        for i=1, _Quest.Triggers[0] do
            if _Quest.Triggers[i].Type == Triggers.Custom2 and _Quest.Triggers[i].Data[1].Interrupt then
                _Quest.Triggers[i].Data[1]:Interrupt(_Quest, i);
            end
        end

        Swift:SendQuestStateEvent(_Quest.Identifier, "QuestInterrupt");
    end

    QuestTemplate.Fail_Orig_QSB_Core = QuestTemplate.Fail;
    QuestTemplate.Fail = function(_Quest)
        _Quest:Fail_Orig_QSB_Core();
        Swift:SendQuestStateEvent(_Quest.Identifier, "QuestFailure");
    end

    QuestTemplate.Success_Orig_QSB_Core = QuestTemplate.Success;
    QuestTemplate.Success = function(_Quest)
        _Quest:Success_Orig_QSB_Core();
        Swift:SendQuestStateEvent(_Quest.Identifier, "QuestSuccess");
    end
end

function Swift:SendQuestStateEvent(_QuestName, _StateName)
    local QuestID = API.GetQuestID(_QuestName);
    if Quests[QuestID] then
        Swift:DispatchScriptEvent(QSB.ScriptEvents[_StateName], QuestID);
        Logic.ExecuteInLuaLocalState(string.format(
            [[Swift:DispatchScriptEvent(QSB.ScriptEvents["%s"], %d)]],
            _StateName,
            QuestID
        ));
    end
end

function Swift:ChangeCustomQuestCaptionText(_Text, _Quest)
    if _Quest and _Quest.Visible then
        _Quest.QuestDescription = _Text;
        Logic.ExecuteInLuaLocalState([[
            XGUIEng.ShowWidget("/InGame/Root/Normal/AlignBottomLeft/Message/QuestObjectives/Custom/BGDeco",0)
            local identifier = "]].._Quest.Identifier..[["
            for i=1, Quests[0] do
                if Quests[i].Identifier == identifier then
                    local text = Quests[i].QuestDescription
                    XGUIEng.SetText("/InGame/Root/Normal/AlignBottomLeft/Message/QuestObjectives/Custom/Text", "]].._Text..[[")
                    break
                end
            end
        ]]);
    end
end

-- Behavior

function Swift:LoadBehaviors()
    for i= 1, #self.m_BehaviorRegister, 1 do
        local Behavior = self.m_BehaviorRegister[i];

        if not _G["B_" .. Behavior.Name].new then
            _G["B_" .. Behavior.Name].new = function(self, ...)
                local arg = {...};
                local behavior = table.copy(self);
                -- Raw parameters
                behavior.i47ya_6aghw_frxil = {};
                -- Overhead parameters
                behavior.v12ya_gg56h_al125 = {};
                for i= 1, #arg, 1 do
                    table.insert(behavior.v12ya_gg56h_al125, arg[i]);
                    if self.Parameter and self.Parameter[i] ~= nil then
                        behavior:AddParameter(i-1, arg[i]);
                    else
                        table.insert(behavior.i47ya_6aghw_frxil, arg[i]);
                    end
                end
                return behavior;
            end
        end
    end
end

function Swift:RegisterBehavior(_Behavior)
    if self:IsLocalEnvironment() then
        return;
    end
    if type(_Behavior) ~= "table" or _Behavior.Name == nil then
        assert(false, "Behavior is invalid!");
        return;
    end
    if _Behavior.RequiresExtraNo and _Behavior.RequiresExtraNo > g_GameExtraNo then
        return;
    end
    if not _G["B_" .. _Behavior.Name] then
        error(string.format("Behavior %s does not exist!", _Behavior.Name));
        return;
    end

    for i= 1, #g_QuestBehaviorTypes, 1 do
        if g_QuestBehaviorTypes[i].Name == _Behavior.Name then
            return;
        end
    end
    table.insert(g_QuestBehaviorTypes, _Behavior);
    table.insert(self.m_BehaviorRegister, _Behavior);
end

-- Load files

function Swift:LoadExternFiles()
    if Mission_LoadFiles then
        local FilesList = Mission_LoadFiles();
        for i= 1, #FilesList, 1 do
            if type(FilesList[i]) == "function" then
                FilesList[i]();
            else
                Script.Load(FilesList[i]);
            end
        end
    end
end

-- Environment Detection

function Swift:DetectEnvironment()
    self.m_Environment = (nil ~= GUI and "local") or "global";
end

function Swift:IsGlobalEnvironment()
    return "global" == self.m_Environment;
end

function Swift:IsLocalEnvironment()
    return "local" == self.m_Environment;
end

function Swift:ValidateTerritories()
    local InvalidTerritories = false;
    local Territories = {Logic.GetTerritories()};
    for i= 1, #Territories, 1 do
        local x, y = GUI.ComputeTerritoryPosition(Territories[i]);
        if not x or not y then
            error("Territory " ..Territories[i].. " is invalid!");
            InvalidTerritories = true;
        end
    end
    if InvalidTerritories then
        error ("A territory must have a size greater 0 and no separated areas!");
    end
end

-- History Edition

function Swift:IsHistoryEdition()
    return Network.IsNATReady ~= nil;
end

function Swift:IsCommunityPatch()
    return Entities.U_PolarBear ~= nil;
end

function Swift:OverrideDoQuicksave()
    -- Quicksave must not be possible while loading map
    self:AddBlockQuicksaveCondition(function()
        return GUI and XGUIEng.IsWidgetShownEx("/LoadScreen/LoadScreen") ~= 0;
    end);

    KeyBindings_SaveGame_Orig_Module_SaveGame = KeyBindings_SaveGame;
    KeyBindings_SaveGame = function(...)
        if not Swift:CanDoQuicksave(unpack(arg)) then
            return;
        end
        KeyBindings_SaveGame_Orig_Module_SaveGame();
    end
end

function Swift:AlterQuickSaveHotkey()
    StartSimpleHiResJobEx(function()
        Input.KeyBindDown(
            Keys.ModifierControl + Keys.S,
            "KeyBindings_SaveGame(true)",
            2,
            false
        );
        return true;
    end);
end

function Swift:AddBlockQuicksaveCondition(_Function)
    table.insert(self.m_NoQuicksaveConditions, _Function);
end

function Swift:CanDoQuicksave(...)
    for i= 1, #self.m_NoQuicksaveConditions, 1 do
        if self.m_NoQuicksaveConditions[i](unpack(arg)) then
            return false;
        end
    end
    return true;
end

-- Logging

LOG_LEVEL_ALL     = 4;
LOG_LEVEL_INFO    = 3;
LOG_LEVEL_WARNING = 2;
LOG_LEVEL_ERROR   = 1;
LOG_LEVEL_OFF     = 0;

function Swift:Log(_Text, _Level, _Verbose)
    if Swift.m_FileLogLevel >= _Level then
        local Level = _Text:sub(1, _Text:find(":"));
        local Text = _Text:sub(_Text:find(":")+1);
        Text = string.format(
            " (%s) %s%s",
            Swift.m_Environment,
            Framework.GetSystemTimeDateString(),
            Text
        )
        Framework.WriteToLog(Level .. Text);
    end
    if _Verbose then
        if self:IsGlobalEnvironment() then
            if Swift.m_LogLevel >= _Level then
                Logic.ExecuteInLuaLocalState(string.format(
                    [[GUI.AddStaticNote("%s")]],
                    _Text
                ));
            end
            return;
        end
        if Swift.m_LogLevel >= _Level then
            GUI.AddStaticNote(_Text);
        end
    end
end

function Swift:SetLogLevel(_ScreenLogLevel, _FileLogLevel)
    if self:IsGlobalEnvironment() then
        Logic.ExecuteInLuaLocalState(string.format(
            [[Swift.m_FileLogLevel = %d]],
            (_FileLogLevel or 0)
        ));
        Logic.ExecuteInLuaLocalState(string.format(
            [[Swift.m_LogLevel = %d]],
            (_ScreenLogLevel or 0)
        ));
        self.m_FileLogLevel = (_FileLogLevel or 0);
        self.m_LogLevel = (_ScreenLogLevel or 0);
    end
end

-- note that debug is a reserved word in normal lua but in settlers lua debug
-- is removed so it does not matter.
function debug(_Text, _Silent)
    Swift:Log("DEBUG: " .._Text, LOG_LEVEL_ALL, not _Silent);
end
function info(_Text, _Silent)
    Swift:Log("INFO: " .._Text, LOG_LEVEL_INFO, not _Silent);
end
function warn(_Text, _Silent)
    Swift:Log("WARNING: " .._Text, LOG_LEVEL_WARNING, not _Silent);
end
function error(_Text, _Silent)
    Swift:Log("ERROR: " .._Text, LOG_LEVEL_ERROR, not _Silent);
end

-- Lua base functions

function Swift:OverrideTable()
    API.OverrideTable();
end

function Swift:OverrideString()
    API.OverrideString();
end

function Swift:OverrideMath()
    API.OverrideMath();
end

function Swift:ConvertTableToString(_Table)
    assert(type(_Table) == "table");
    local String = "{";
    for k, v in pairs(_Table) do
        local key;
        if (tonumber(k)) then
            key = ""..k;
        else
            key = "\""..k.."\"";
        end
        if type(v) == "table" then
            String = String .. "[" .. key .. "] = " .. table.tostring(v) .. ", ";
        elseif type(v) == "number" then
            String = String .. "[" .. key .. "] = " .. v .. ", ";
        elseif type(v) == "string" then
            String = String .. "[" .. key .. "] = \"" .. v .. "\", ";
        elseif type(v) == "boolean" or type(v) == "nil" then
            String = String .. "[" .. key .. "] = " .. tostring(v) .. ", ";
        else
            String = String .. "[" .. key .. "] = \"" .. tostring(v) .. "\", ";
        end
    end
    String = String .. "}";
    return String;
end

-- Local Script Command

function Swift:InitalizeScriptCommands()
    Swift:CreateScriptCommand("Cmd_SendScriptEvent", API.SendScriptEvent);
    Swift:CreateScriptCommand("Cmd_GlobalQsbLoaded", SCP.Core.GlobalQsbLoaded);
    Swift:CreateScriptCommand("Cmd_ProclaimateRandomSeed", SCP.Core.ProclaimateRandomSeed);
    Swift:CreateScriptCommand("Cmd_RegisterLoadscreenHidden", SCP.Core.LoadscreenHidden);
    Swift:CreateScriptCommand("Cmd_UpdateCustomVariable", SCP.Core.UpdateCustomVariable);
    Swift:CreateScriptCommand("Cmd_UpdateTexturePosition", SCP.Core.UpdateTexturePosition);
end

function Swift:CreateScriptCommand(_Name, _Function)
    if not self:IsGlobalEnvironment() then
        return 0;
    end
    QSB.ScriptCommandSequence = QSB.ScriptCommandSequence +1;
    local ID = QSB.ScriptCommandSequence;
    local Name = _Name;
    if string.find(_Name, "^Cmd_") then
        Name = string.sub(_Name, 5);
    end
    self.m_ScriptCommandRegister[ID] = {Name, _Function};
    Logic.ExecuteInLuaLocalState(string.format(
        [[
            local ID = %d
            local Name = "%s"
            Swift.m_ScriptCommandRegister[ID] = Name
            QSB.ScriptCommands[Name] = ID
        ]],
        ID,
        Name
    ));
    QSB.ScriptCommands[Name] = ID;
    return ID;
end

function Swift:DispatchScriptCommand(_ID, ...)
    if not self:IsLocalEnvironment() then
        return;
    end
    assert(_ID ~= nil);
    if self.m_ScriptCommandRegister[_ID] then
        local PlayerID = GUI.GetPlayerID();
        local NamePlayerID = 8;
        local PlayerName = Logic.GetPlayerName(NamePlayerID);
        local Parameters = self:EncodeScriptCommandParameters(unpack(arg));
        GUI.SetPlayerName(NamePlayerID, Parameters);

        if Framework.IsNetworkGame() and self:IsHistoryEdition() then
            GUI.SetSoldierPaymentLevel(_ID);
        else
            GUI.SendScriptCommand(string.format(
                [[Swift:ProcessScriptCommand(%d, %d)]],
                arg[1],
                _ID
            ));
        end
        debug(string.format(
            "Dispatching script command %s to global.",
            self.m_ScriptCommandRegister[_ID]
        ), true);

        GUI.SetPlayerName(NamePlayerID, PlayerName);
        GUI.SetSoldierPaymentLevel(PlayerSoldierPaymentLevel[PlayerID]);
    end
end

function Swift:ProcessScriptCommand(_PlayerID, _ID)
    if not self.m_ScriptCommandRegister[_ID] then
        return;
    end
    local PlayerName = Logic.GetPlayerName(8);
    local Parameters = self:DecodeScriptCommandParameters(PlayerName);
    local PlayerID = table.remove(Parameters, 1);
    if PlayerID ~= 0 and PlayerID ~= _PlayerID then
        return;
    end
    debug(string.format(
        "Processing script command %s in global.",
        self.m_ScriptCommandRegister[_ID][1]
    ), true);
    self.m_ScriptCommandRegister[_ID][2](unpack(Parameters));
end

function Swift:EncodeScriptCommandParameters(...)
    local Query = "";
    for i= 1, #arg do
        local Parameter = arg[i];
        if type(Parameter) == "string" then
            Parameter = string.replaceAll(Parameter, '#', "<<<HT>>>");
            Parameter = string.replaceAll(Parameter, '"', "<<<QT>>>");
            if Parameter:len() == 0 then
                Parameter = "<<<ES>>>";
            end
        -- FIXME This covers only array tables!
        -- (But we shouldn't encourage passing objects anyway!)
        elseif type(Parameter) == "table" then
            Parameter = "{" ..table.concat(Parameter, ",") .."}";
        end
        if string.len(Query) > 0 then
            Query = Query .. "#";
        end
        Query = Query .. tostring(Parameter);
    end
    return Query;
end

function Swift:DecodeScriptCommandParameters(_Query)
    local Parameters = {};
    for k, v in pairs(string.slice(_Query, "#")) do
        local Value = v;
        Value = string.replaceAll(Value, "<<<HT>>>", '#');
        Value = string.replaceAll(Value, "<<<QT>>>", '"');
        Value = string.replaceAll(Value, "<<<ES>>>", '');
        if Value == nil then
            Value = nil;
        elseif Value == "true" or Value == "false" then
            Value = Value == "true";
        elseif string.indexOf(Value, "{") == 1 then
            -- FIXME This covers only array tables!
            -- (But we shouldn't encourage passing objects anyway!)
            local ValueTable = string.slice(string.sub(Value, 2, string.len(Value)-1), ",");
            Value = {};
            for i= 1, #ValueTable do
                Value[i] = (tonumber(ValueTable[i]) ~= nil and tonumber(ValueTable[i]) or ValueTable);
            end
        elseif tonumber(Value) ~= nil then
            Value = tonumber(Value);
        end
        table.insert(Parameters, Value);
    end
    return Parameters;
end

-- Script Events

function Swift:InitalizeEventsGlobal()
    QSB.ScriptEvents.SaveGameLoaded = Swift:CreateScriptEvent("Event_SaveGameLoaded", nil);
    QSB.ScriptEvents.EscapePressed = Swift:CreateScriptEvent("Event_EscapePressed", nil);
    QSB.ScriptEvents.QuestFailure = Swift:CreateScriptEvent("Event_QuestFailure", nil);
    QSB.ScriptEvents.QuestInterrupt = Swift:CreateScriptEvent("Event_QuestInterrupt", nil);
    QSB.ScriptEvents.QuestReset = Swift:CreateScriptEvent("Event_QuestReset", nil);
    QSB.ScriptEvents.QuestSuccess = Swift:CreateScriptEvent("Event_QuestSuccess", nil);
    QSB.ScriptEvents.QuestTrigger = Swift:CreateScriptEvent("Event_QuestTrigger", nil);
    QSB.ScriptEvents.CustomValueChanged = Swift:CreateScriptEvent("Event_CustomValueChanged", nil);
    QSB.ScriptEvents.LanguageSet = Swift:CreateScriptEvent("Event_LanguageSet", nil);
end
function Swift:InitalizeEventsLocal()
    QSB.ScriptEvents.SaveGameLoaded = Swift:CreateScriptEvent("Event_SaveGameLoaded", nil);
    QSB.ScriptEvents.EscapePressed = Swift:CreateScriptEvent("Event_EscapePressed", nil);
    QSB.ScriptEvents.QuestFailure = Swift:CreateScriptEvent("Event_QuestFailure", nil);
    QSB.ScriptEvents.QuestInterrupt = Swift:CreateScriptEvent("Event_QuestInterrupt", nil);
    QSB.ScriptEvents.QuestReset = Swift:CreateScriptEvent("Event_QuestReset", nil);
    QSB.ScriptEvents.QuestSuccess = Swift:CreateScriptEvent("Event_QuestSuccess", nil);
    QSB.ScriptEvents.QuestTrigger = Swift:CreateScriptEvent("Event_QuestTrigger", nil);
    QSB.ScriptEvents.CustomValueChanged = Swift:CreateScriptEvent("Event_CustomValueChanged", nil);
    QSB.ScriptEvents.LanguageSet = Swift:CreateScriptEvent("Event_LanguageSet", nil);
end

function Swift:CreateScriptEvent(_Name, _Function)
    for i= 1, #self.m_ScriptEventRegister, 1 do
        if self.m_ScriptEventRegister[i][1] == _Name then
            return 0;
        end
    end
    local ID = #self.m_ScriptEventRegister+1;
    debug(string.format("Create script event %s", _Name), true);
    self.m_ScriptEventRegister[ID] = {_Name, _Function};
    return ID;
end

function Swift:DispatchScriptEvent(_ID, ...)
    if not self.m_ScriptEventRegister[_ID] then
        return;
    end
    -- Dispatch module events
    for i= 1, #self.m_ModuleRegister, 1 do
        local Env = "Local";
        if self:IsGlobalEnvironment() then
            Env = "Global";
        end
        if self.m_ModuleRegister[i][Env] and self.m_ModuleRegister[i][Env].OnEvent then
            debug(string.format(
                "Dispatching %s script event %s to Module %s",
                Env:lower(),
                self.m_ScriptEventRegister[_ID][1],
                self.m_ModuleRegister[i].Properties.Name
            ), true);
            self.m_ModuleRegister[i][Env]:OnEvent(_ID, self.m_ScriptEventRegister[_ID], unpack(arg));
        end
    end
    -- Call event callback
    if GameCallback_QSB_OnEventReceived then
        GameCallback_QSB_OnEventReceived(_ID, unpack(arg));
    end
    -- Call event listeners
    if self.m_ScriptEventListener[_ID] then
        for k, v in pairs(self.m_ScriptEventListener[_ID]) do
            if tonumber(k) then
                v(_ID, unpack(arg));
            end
        end
    end
end

function Swift:IsAllowedEventParameter(_Parameter)
    if type(_Parameter) == "function" or type(_Parameter) == "thread" or type(_Parameter) == "userdata" then
        return false;
    elseif type(_Parameter) == "table" then
        for k, v in pairs(_Parameter) do
            if type(k) ~= "number" and k ~= "n" then
                return false;
            end
            if type(v) == "function" or type(v) == "thread" or type(v) == "userdata" then
                return false;
            end
        end
    end
    return true;
end

-- AI

function Swift:InitalizeAIVariables()
    for i= 1, 8 do
        self.m_AIProperties[i] = {};
    end
end

function Swift:DisableLogicFestival()
    Swift.Logic_StartFestival = Logic.StartFestival;
    Logic.StartFestival = function(_PlayerID, _Type)
        if Logic.PlayerGetIsHumanFlag(_PlayerID) ~= true then
            if Swift.m_AIProperties[_PlayerID].ForbidFestival == true then
                return;
            end
        end
        Swift.Logic_StartFestival(_PlayerID, _Type);
    end
end

-- Custom Variable

function Swift:GetCustomVariable(_Name)
    return QSB.CustomVariable[_Name];
end

function Swift:SetCustomVariable(_Name, _Value)
    Swift:UpdateCustomVariable(_Name, _Value);
    local Value = tostring(_Value);
    if type(_Value) ~= "number" then
        Value = [["]] ..Value.. [["]];
    end
    if GUI then
        Swift:DispatchScriptCommand(QSB.ScriptCommands.UpdateCustomVariable, 0, _Name, Value);
    else
        Logic.ExecuteInLuaLocalState(string.format(
            [[Swift:UpdateCustomVariable("%s", %s)]],
            _Name,
            Value
        ));
    end
end

function Swift:UpdateCustomVariable(_Name, _Value)
    if QSB.CustomVariable[_Name] then
        local Old = QSB.CustomVariable[_Name];
        QSB.CustomVariable[_Name] = _Value;
        Swift:DispatchScriptEvent(
            QSB.ScriptEvents.CustomValueChanged,
            _Name,
            Old,
            _Value
        );
    else
        QSB.CustomVariable[_Name] = _Value;
        Swift:DispatchScriptEvent(
            QSB.ScriptEvents.CustomValueChanged,
            _Name,
            nil,
            _Value
        );
    end
end

-- Language

function Swift:DetectLanguage()
    self.m_Language = (Network.GetDesiredLanguage() == "de" and "de") or "en";
    QSB.Language = self.m_Language;
end

function Swift:ChangeSystemLanguage(_Language)
    local OldLanguage = self.m_Language;
    local NewLanguage = _Language;
    self.m_Language = _Language;
    QSB.Language = self.m_Language;

    Swift:DispatchScriptEvent(QSB.ScriptEvents.LanguageSet, OldLanguage, NewLanguage);
    Logic.ExecuteInLuaLocalState(string.format(
        [[
            local OldLanguage = "%s"
            local NewLanguage = "%s"
            Swift.m_Language = NewLanguage
            QSB.Language = NewLanguage
            Swift:DispatchScriptEvent(QSB.ScriptEvents.LanguageSet, OldLanguage, NewLanguage)
        ]],
        OldLanguage,
        NewLanguage
    ));
end

function Swift:GetTextOfDesiredLanguage(_Table)
    if type(_Table) == "table" then
        if _Table[QSB.Language] then
            return _Table[QSB.Language];
        end
        return "ERROR_NO_TEXT";
    end
    return "ERROR_NO_TEXT";
end

function Swift:Localize(_Text)
    local LocalizedText;
    if type(_Text) == "table" then
        LocalizedText = {};
        if _Text.en == nil and _Text[QSB.Language] == nil then
            for k,v in pairs(_Text) do
                if type(v) == "table" then
                    LocalizedText[k] = self:Localize(v);
                end
            end
        else
            LocalizedText = Swift:GetTextOfDesiredLanguage(_Text);
        end
    else
        LocalizedText = tostring(_Text);
    end
    return LocalizedText;
end

-- Utils

function Swift:ToBoolean(_Input)
    if type(_Input) == "boolean" then
        return _Input;
    end
    if _Input == 1 or string.find(string.lower(tostring(_Input)), "^[1tjy\\+].*$") then
        return true;
    end
    return false;
end

function Swift:CopyTable(_Table1, _Table2)
    _Table1 = _Table1 or {};
    _Table2 = _Table2 or {};
    for k, v in pairs(_Table1) do
        if "table" == type(v) then
            _Table2[k] = _Table2[k] or {};
            for kk, vv in pairs(self:CopyTable(v, _Table2[k])) do
                _Table2[k][kk] = _Table2[k][kk] or vv;
            end
        else
            _Table2[k] = v;
        end
    end
    return _Table2;
end

-- Jobs

function Swift_EventJob_WaitForLoadScreenHidden()
    if XGUIEng.IsWidgetShownEx("/LoadScreen/LoadScreen") == 0 then
        Swift:DispatchScriptCommand(QSB.ScriptCommands.RegisterLoadscreenHidden, GUI.GetPlayerID());
        Swift.m_LoadScreenHidden = true;
        return true;
    end
end

function Swift_EventJob_PostTexturesToGlobal()
    if Logic.GetTime() > 1 then
        for k, v in pairs(g_TexturePositions) do
            for kk, vv in pairs(v) do
                Swift:DispatchScriptCommand(QSB.ScriptCommands.UpdateTexturePosition, GUI.GetPlayerID(), k, kk, v);
            end
        end
        return true;
    end
end

