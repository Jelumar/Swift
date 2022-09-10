--[[
Swift_3_DialogSystem/Source

Copyright (C) 2021 - 2022 totalwarANGEL - All Rights Reserved.

This file is part of Swift. Swift is created by totalwarANGEL.
You may use and modify this file unter the terms of the MIT licence.
(See https://en.wikipedia.org/wiki/MIT_License)
]]

ModuleDialogSystem = {
    Properties = {
        Name = "ModuleDialogSystem",
    },

    Global = {
        DialogPageCounter = 0,
        DialogCounter = 0,
        Dialog = {},
        DialogQueue = {},
    },
    Local = {
        Dialog = {},
    },
    -- This is a shared structure but the values are asynchronous!
    Shared = {
        Text = {
            Continue = {
                de = "{cr}{cr}{azure}(Weiter mit ESC)",
                en = "{cr}{cr}{azure}(Continue with ESC)"
            }
        },
    },
};

QSB.CinematicEventTypes.Dialog = 4;

QSB.Dialog = {
    TIMER_PER_CHAR = 0.175,
    CAMERA_ROTATIONDEFAULT = -45,
    CAMERA_ZOOMDEFAULT = 0.5,
    DLGCAMERA_ROTATIONDEFAULT = -45,
    DLGCAMERA_ZOOMDEFAULT = 0.15,
}

-- Global ------------------------------------------------------------------- --

function ModuleDialogSystem.Global:OnGameStart()
    QSB.ScriptEvents.DialogStarted = API.RegisterScriptEvent("Event_DialogStarted");
    QSB.ScriptEvents.DialogEnded = API.RegisterScriptEvent("Event_DialogEnded");
    QSB.ScriptEvents.DialogOptionSelected = API.RegisterScriptEvent("Event_DialogOptionSelected");

    for i= 1, 8 do
        self.DialogQueue[i] = {};
    end

    -- Quests can not be decided while a dialog is active. This must be done to
    -- prevent flickering when a quest ends. Dialog quests themselves must run!
    API.AddDisableDecisionCondition(function(_PlayerID, _Quest)
        if ModuleDialogSystem.Global.Dialog[_PlayerID] ~= nil then
            return _Quest.Identifier:contains("DialogSystemQuest_");
        end
        return true;
    end);
    -- Updates the dialog queue for all players
    API.StartHiResJob(function()
        ModuleDialogSystem.Global:Update();
    end);
end

function ModuleDialogSystem.Global:OnEvent(_ID, _Event, ...)
    if _ID == QSB.ScriptEvents.EscapePressed then
        if self.Dialog[arg[1]] ~= nil then
            if Logic.GetTime() - self.Dialog[arg[1]].PageStartedTime >= 1 then
                local PageID = self.Dialog[arg[1]].CurrentPage;
                local Page = self.Dialog[arg[1]][PageID];
                if not self.Dialog[arg[1]].DisableSkipping and not Page.DisableSkipping and not Page.MC then
                    self:NextPage(arg[1]);
                end
            end
        end
    elseif _ID == QSB.ScriptEvents.DialogOptionSelected then
        Logic.ExecuteInLuaLocalState(string.format(
            [[API.SendScriptEvent(QSB.ScriptEvents.DialogOptionSelected, %d, %d)]],
            arg[1], arg[2]
        ));
        ModuleDialogSystem.Global:OnOptionSelected(arg[1], arg[2]);
    end
end

function ModuleDialogSystem.Global:StartDialog(_Name, _PlayerID, _Data)
    self.DialogQueue[_PlayerID] = self.DialogQueue[_PlayerID] or {};
    self.DialogCounter = (self.DialogCounter or 0) +1;
    _Data.DialogName = "Dialog #" .. self.DialogCounter;
    ModuleDisplayCore.Global:PushCinematicEventToQueue(
        _PlayerID,
        QSB.CinematicEventTypes.Dialog,
        _Name,
        _Data
    );
    -- table.insert(self.DialogQueue[_PlayerID], {_Name, _Data});
end

function ModuleDialogSystem.Global:EndDialog(_PlayerID)
    Logic.SetGlobalInvulnerability(0);
    if self.Dialog[_PlayerID].Finished then
        self.Dialog[_PlayerID]:Finished();
    end
    API.FinishCinematicEvent(self.Dialog[_PlayerID].Name, _PlayerID);
    API.SendScriptEvent(
        QSB.ScriptEvents.DialogEnded,
        _PlayerID,
        self.Dialog[_PlayerID]
    );
    Logic.ExecuteInLuaLocalState(string.format(
        [[API.SendScriptEvent(QSB.ScriptEvents.DialogEnded, %d, %s)]],
        _PlayerID,
        table.tostring(self.Dialog[_PlayerID])
    ));
    self.Dialog[_PlayerID] = nil;
end

function ModuleDialogSystem.Global:CanStartDialog(_PlayerID)
    return  self.Dialog[_PlayerID] == nil and
            not API.IsCinematicEventActive(_PlayerID) and
            not API.IsLoadscreenVisible();
end

function ModuleDialogSystem.Global:NextDialog(_PlayerID)
    if self:CanStartDialog(_PlayerID) then
        local DialogData = ModuleDisplayCore.Global:PopCinematicEventFromQueue(_PlayerID);
        assert(DialogData[1] == QSB.CinematicEventTypes.Dialog);
        API.StartCinematicEvent(DialogData[2], _PlayerID);

        Logic.ExecuteInLuaLocalState(string.format(
            [[ModuleDialogSystem.Local:ResetTimerButtons(%d)]],
            _PlayerID
        ));

        local Dialog = DialogData[3];
        Dialog.Name = DialogData[2];
        Dialog.PlayerID = _PlayerID;
        Dialog.CurrentPage = 0;
        self.Dialog[_PlayerID] = Dialog;
        if Dialog.EnableGlobalImmortality then
            Logic.SetGlobalInvulnerability(1);
        end
        if self.Dialog[_PlayerID].Starting then
            self.Dialog[_PlayerID]:Starting();
        end
        API.SendScriptEvent(
            QSB.ScriptEvents.DialogStarted,
            _PlayerID,
            self.Dialog[_PlayerID]
        );
        Logic.ExecuteInLuaLocalState(string.format(
            [[API.SendScriptEvent(QSB.ScriptEvents.DialogStarted, %d, %s)]],
            _PlayerID,
            table.tostring(self.Dialog[_PlayerID])
        ));
        self:NextPage(_PlayerID);
    end
end

function ModuleDialogSystem.Global:NextPage(_PlayerID)
    if self.Dialog[_PlayerID] == nil then
        return;
    end

    self.Dialog[_PlayerID].CurrentPage = self.Dialog[_PlayerID].CurrentPage +1;
    self.Dialog[_PlayerID].PageStartedTime = Logic.GetTime();
    if self.Dialog[_PlayerID].PageQuest then
        API.StopQuest(self.Dialog[_PlayerID].PageQuest, true);
    end

    local PageID = self.Dialog[_PlayerID].CurrentPage;
    if PageID <= 0 then
        self:EndDialog(_PlayerID);
        return;
    end
    local Page = self.Dialog[_PlayerID][PageID];
    if type(Page) == "table" then
        if Page.MC then
            for i= 1, #Page.MC, 1 do
                if type(Page.MC[i][3]) == "function" then
                    self.Dialog[_PlayerID][PageID].MC[i].Visible = not Page.MC[i][3](_PlayerID, PageID, i)
                end
            end
        end

        if PageID <= #self.Dialog[_PlayerID] then
            if self.Dialog[_PlayerID][PageID].Action then
                self.Dialog[_PlayerID][PageID]:Action();
            end
            self.Dialog[_PlayerID].PageQuest = self:DisplayPage(_PlayerID, PageID);
        else
            self:EndDialog(_PlayerID);
        end
    elseif type(Page) == "number" or type(Page) == "string" then
        local Target = self:GetPageIDByName(_PlayerID, self.Dialog[_PlayerID][PageID]);
        self.Dialog[_PlayerID].CurrentPage = Target -1;
        self:NextPage(_PlayerID);
    else
        self:EndDialog(_PlayerID);
    end
end

function ModuleDialogSystem.Global:OnOptionSelected(_PlayerID, _OptionID)
    if self.Dialog[_PlayerID] == nil then
        return;
    end
    local PageID = self.Dialog[_PlayerID].CurrentPage;
    if type(self.Dialog[_PlayerID][PageID]) ~= "table" then
        return;
    end
    local Page = self.Dialog[_PlayerID][PageID];
    if Page.MC then
        local Option;
        for i= 1, #Page.MC, 1 do
            if Page.MC[i].ID == _OptionID then
                Option = Page.MC[i];
            end
        end
        if Option ~= nil then
            local Target = Option[2];
            if type(Option[2]) == "function" then
                Target = Option[2](_PlayerID, PageID, _OptionID);
            end
            self.Dialog[_PlayerID][PageID].MC.Selected = Option.ID;
            self.Dialog[_PlayerID].CurrentPage = self:GetPageIDByName(_PlayerID, Target) -1;
            self:NextPage(_PlayerID);
        end
    end
end

function ModuleDialogSystem.Global:DisplayPage(_PlayerID, _PageID)
    if self.Dialog[_PlayerID] == nil then
        return;
    end

    self.DialogPageCounter = self.DialogPageCounter +1;
    local Page = self.Dialog[_PlayerID][_PageID];
    local PrevQuestName = "DialogSystemQuest_" .._PlayerID.. "_" ..(self.DialogPageCounter-1);
    local QuestName = "DialogSystemQuest_" .._PlayerID.. "_" ..self.DialogPageCounter;
    local QuestText = API.ConvertPlaceholders(API.Localize(Page.Text));
    local Extension = "";
    if not self.Dialog[_PlayerID].DisableSkipping and not Page.DisableSkipping and not Page.MC then
        Extension = API.ConvertPlaceholders(API.Localize(ModuleDialogSystem.Shared.Text.Continue));
    end
    local Sender = Page.Sender or _PlayerID;
    local AutoSkip = (self.Dialog[_PlayerID].DisableSkipping or Page.DisableSkipping) == true;
    API.CreateQuest {
        Name        = QuestName,
        Suggestion  = QuestText .. Extension,
        Sender      = (Sender == -1 and _PlayerID) or Sender,
        Receiver    = _PlayerID,

        Goal_NoChange(),
        Trigger_Time(0),
    }
    -- Using a inline job because quest do not really tick and there is no
    -- point in assigning quest durations.
    API.StartJob(function(_AutoSkip, _PlayerID, _StartTime, _Duration)
        if not _AutoSkip then
            return true;
        end
        if Logic.GetTime() >= _StartTime+_Duration then
            ModuleDialogSystem.Global:NextPage(_PlayerID);
            return true;
        end
    end, AutoSkip, _PlayerID, Logic.GetTime(), 12)

    Logic.ExecuteInLuaLocalState(string.format(
        [[ModuleDialogSystem.Local:DisplayPage(%d, %s)]],
        _PlayerID,
        table.tostring(Page)
    ));
    return QuestName;
end

function ModuleDialogSystem.Global:GetCurrentDialog(_PlayerID)
    return self.Dialog[_PlayerID];
end

function ModuleDialogSystem.Global:GetCurrentDialogPage(_PlayerID)
    if self.Dialog[_PlayerID] then
        local PageID = self.Dialog[_PlayerID].CurrentPage;
        return self.Dialog[_PlayerID][PageID];
    end
end

function ModuleDialogSystem.Global:GetPageIDByName(_PlayerID, _Name)
    if type(_Name) == "string" then
        if self.Dialog[_PlayerID] ~= nil then
            for i= 1, #self.Dialog[_PlayerID], 1 do
                if type(self.Dialog[_PlayerID][i]) == "table" and self.Dialog[_PlayerID][i].Name == _Name then
                    return i;
                end
            end
        end
        return 0;
    end
    return _Name;
end

function ModuleDialogSystem.Global:Update()
    for i= 1, 8 do
        if self:CanStartDialog(i) then
            local Next = ModuleDisplayCore.Global:LookUpCinematicInFromQueue(i);
            if Next and Next[1] == QSB.CinematicEventTypes.Dialog then
                self:NextDialog(i);
            end
        end
    end
end

-- Local -------------------------------------------------------------------- --

function ModuleDialogSystem.Local:OnGameStart()
    QSB.ScriptEvents.DialogStarted = API.RegisterScriptEvent("Event_DialogStarted");
    QSB.ScriptEvents.DialogEnded = API.RegisterScriptEvent("Event_DialogEnded");
    QSB.ScriptEvents.DialogOptionSelected = API.RegisterScriptEvent("Event_DialogOptionSelected");

    self:OverrideTimerButtonClicked();
    API.StartHiResJob(function()
        ModuleDialogSystem.Local:Update();
    end);
end

function ModuleDialogSystem.Local:OnEvent(_ID, _Event, ...)
    if _ID == QSB.ScriptEvents.DialogStarted then
        ModuleDialogSystem.Local:StartDialog(arg[1], arg[2]);
    elseif _ID == QSB.ScriptEvents.DialogEnded then
        ModuleDialogSystem.Local:EndDialog(arg[1], arg[2]);
    elseif _ID == QSB.ScriptEvents.QuestTrigger then
        -- Enforce the actor when the quest starts
        local Quest = Quests[arg[1]];
        if Quest then
            local Actor = g_PlayerPortrait[Quest.SendingPlayer];
            SetPortraitWithCameraSettings("/InGame/Root/Normal/AlignBottomLeft/Message/MessagePortrait", Actor);
            -- Update only when no event is active
            if GUI.GetPlayerID() == Quest.ReceivingPlayer then
                if not self:IsAnyCinematicEventActive(Quest.ReceivingPlayer) then
                    XGUIEng.ShowWidget("/InGame/Root/Normal/AlignBottomLeft/Message/Update", 1);
                    XGUIEng.ShowWidget("/InGame/Root/Normal/AlignBottomLeft/SubTitles/Update", 1);
                else
                    XGUIEng.ShowWidget("/InGame/Root/Normal/AlignBottomLeft/Message/QuestObjectives", 0);
                end
            end
        end
    end
end

function ModuleDialogSystem.Local:OverrideTimerButtonClicked()
    GUI_Interaction.TimerButtonClicked_Orig_ModuleDialogSystem = GUI_Interaction.TimerButtonClicked;
    GUI_Interaction.TimerButtonClicked = function ()
        local CurrentWidgetID = XGUIEng.GetCurrentWidgetID();
        local MotherContainerName = XGUIEng.GetWidgetNameByID(XGUIEng.GetWidgetsMotherID(CurrentWidgetID));
        local TimerNumber = tonumber(MotherContainerName);
        local QuestIndex = g_Interaction.TimerQuests[TimerNumber];

        XGUIEng.ShowWidget("/InGame/Root/Normal/AlignBottomLeft/Message/Update", 1);
        XGUIEng.ShowWidget("/InGame/Root/Normal/AlignBottomLeft/SubTitles/Update", 1);
        if not (g_Interaction.CurrentMessageQuestIndex == QuestIndex and not QuestLog.IsQuestLogShown()) then
            ModuleDialogSystem.Local:ResetTimerButtons(GUI.GetPlayerID());
        end
        GUI_Interaction.TimerButtonClicked_Orig_ModuleDialogSystem();
    end
end

function ModuleDialogSystem.Local:StartDialog(_PlayerID, _Data)
    if GUI.GetPlayerID() == _PlayerID then
        API.DeactivateNormalInterface();
        API.DeactivateBorderScroll();
        XGUIEng.ShowWidget("/InGame/Root/Normal/AlignBottomLeft/Message", 1);
        XGUIEng.ShowWidget("/InGame/Root/Normal/AlignBottomLeft/Message/Update", 0);
        XGUIEng.ShowWidget("/InGame/Root/Normal/AlignBottomLeft/SubTitles", 1);
        XGUIEng.ShowWidget("/InGame/Root/3dWorldView", 0);
        Input.CutsceneMode();
        GUI.ClearSelection();

        self.Dialog[_PlayerID] = self.Dialog[_PlayerID] or {};

        -- Subtitles position backup
        self.Dialog[_PlayerID].SubtitlesPosition = {
            XGUIEng.GetWidgetScreenPosition("/InGame/Root/Normal/AlignBottomLeft/SubTitles")
        };

        -- Make camera backup
        self.Dialog[_PlayerID].Backup = {
            Rotation = Camera.RTS_GetRotationAngle(),
            Zoom     = Camera.RTS_GetZoomFactor(),
            Position = {Camera.RTS_GetLookAtPosition()},
            Speed    = Game.GameTimeGetFactor(_PlayerID),
        };

        if not _Data.EnableFoW then
            Display.SetRenderFogOfWar(0);
        end
        if not _Data.EnableBorderPins then
            Display.SetRenderBorderPins(0);
        end
        if not Framework.IsNetworkGame() then
            Game.GameTimeSetFactor(_PlayerID, 1);
        end
    end
end

function ModuleDialogSystem.Local:EndDialog(_PlayerID, _Data)
    if GUI.GetPlayerID() == _PlayerID then
        XGUIEng.SetText("/InGame/Root/Normal/AlignBottomLeft/SubTitles/VoiceText1", "");
        XGUIEng.ShowWidget("/InGame/Root/3dWorldView", 1);
        XGUIEng.ShowWidget("/InGame/Root/Normal/AlignBottomLeft/Message", 1);
        XGUIEng.ShowWidget("/InGame/Root/Normal/AlignBottomLeft/Message/QuestObjectives", 0);
        XGUIEng.ShowWidget("/InGame/Root/Normal/AlignBottomLeft/Message/MessagePortrait", 0);
        XGUIEng.ShowWidget("/InGame/Root/Normal/AlignBottomLeft/Message/Update", 0);
        XGUIEng.ShowWidget("/InGame/Root/Normal/AlignBottomLeft/SubTitles", 1);
        XGUIEng.ShowWidget("/InGame/Root/Normal/AlignBottomLeft/SubTitles/BG", 0);
        XGUIEng.ShowWidget("/InGame/Root/Normal/AlignBottomLeft/SubTitles/VoiceText1", 0);
        XGUIEng.ShowWidget("/InGame/Root/Normal/AlignBottomLeft/SubTitles/Update", 0);
        Input.GameMode();

        -- Load subtitles backup
        self:ResetSubtitlesPosition(_PlayerID);

        -- Load camera backup
        Camera.RTS_FollowEntity(0);
        if self.Dialog[_PlayerID].Backup then
            if _Data.RestoreCamera then
                Camera.RTS_SetRotationAngle(self.Dialog[_PlayerID].Backup.Rotation);
                Camera.RTS_SetZoomFactor(self.Dialog[_PlayerID].Backup.Zoom);
                Camera.RTS_SetLookAtPosition(
                    self.Dialog[_PlayerID].Backup.Position[1],
                    self.Dialog[_PlayerID].Backup.Position[2]
                );
            end
            if _Data.RestoreGameSpeed and not Framework.IsNetworkGame() then
                Game.GameTimeSetFactor(_PlayerID, self.Dialog[_PlayerID].Backup.Speed);
            end
        end

        self.Dialog[_PlayerID] = nil;
        API.ActivateNormalInterface();
        API.ActivateBorderScroll();
        Display.SetRenderFogOfWar(1);
        Display.SetRenderBorderPins(1);
    end
end

function ModuleDialogSystem.Local:DisplayPage(_PlayerID, _PageData)
    if GUI.GetPlayerID() == _PlayerID then
        GUI.ClearSelection();

        self.Dialog[_PlayerID].PageData = _PageData;
        if _PageData.Sender ~= -1 then
            XGUIEng.ShowWidget("/InGame/Root/Normal/AlignBottomLeft/Message", 1);
            XGUIEng.ShowAllSubWidgets("/InGame/Root/Normal/AlignBottomLeft/Message", 1);
            XGUIEng.ShowWidget("/InGame/Root/Normal/AlignBottomLeft/Message/QuestLog", 0);
            XGUIEng.ShowWidget("/InGame/Root/Normal/AlignBottomLeft/Message/Update", 0);
            XGUIEng.ShowWidget("/InGame/Root/Normal/AlignBottomLeft/SubTitles/Update", 1);
            self:ResetPlayerPortrait(_PageData.Sender, _PageData.Head);
            self:ResetSubtitlesPosition(_PlayerID);
            self:SetSubtitlesText(_PlayerID);
            self:SetSubtitlesPosition(_PlayerID);
        else
            XGUIEng.ShowWidget("/InGame/Root/Normal/AlignBottomLeft/Message/MessagePortrait", 0);
            XGUIEng.ShowWidget("/InGame/Root/Normal/AlignBottomLeft/Message", 1);
            XGUIEng.ShowWidget("/InGame/Root/Normal/AlignBottomLeft/SubTitles", 1);
            XGUIEng.ShowWidget("/InGame/Root/Normal/AlignBottomLeft/SubTitles/Update", 1);
            self:ResetSubtitlesPosition(_PlayerID);
            self:SetSubtitlesText(_PlayerID);
            self:SetSubtitlesPosition(_PlayerID);
        end

        if _PageData.Title then
            local Title = API.ConvertPlaceholders(_PageData.Title);
            if Title:find("^[A-Za-Z0-9_]+/[A-Za-Z0-9_]+$") then
                Title = XGUIEng.GetStringTableText(Title);
            end
            if Title:sub(1, 1) ~= "{" then
                Title = "{center}" ..Title;
            end
            XGUIEng.SetText("/InGame/Root/Normal/AlignBottomLeft/Message/MessagePortrait/PlayerName", Title);
        end
        if _PageData.Target then
            Camera.RTS_FollowEntity(GetID(_PageData.Target));
        else
            Camera.RTS_FollowEntity(0);
        end
        if _PageData.Position then
            Camera.RTS_SetLookAtPosition(_PageData.Position.X, _PageData.Position.Y);
        end
        if _PageData.Zoom then
            Camera.RTS_SetZoomFactor(_PageData.Zoom);
        end
        if _PageData.Rotation then
            Camera.RTS_SetRotationAngle(_PageData.Rotation);
        end
        if _PageData.MC then
            self:SetOptionsDialogContent(_PlayerID);
        end
    end
end

function ModuleDialogSystem.Local:SetSubtitlesText(_PlayerID)
    local PageData = self.Dialog[_PlayerID].PageData;
    local MotherWidget = "/InGame/Root/Normal/AlignBottomLeft/SubTitles";
    local QuestText = API.ConvertPlaceholders(API.Localize(PageData.Text));
    local Extension = "";
    if not self.Dialog[_PlayerID].DisableSkipping and not PageData.DisableSkipping and not PageData.MC then
        Extension = API.ConvertPlaceholders(API.Localize(ModuleDialogSystem.Shared.Text.Continue));
    end
    XGUIEng.SetText(MotherWidget.. "/VoiceText1", QuestText .. Extension);
end

function ModuleDialogSystem.Local:SetSubtitlesPosition(_PlayerID)
    local PageData = self.Dialog[_PlayerID].PageData;
    local MotherWidget = "/InGame/Root/Normal/AlignBottomLeft/SubTitles";
    local Height = XGUIEng.GetTextHeight(MotherWidget.. "/VoiceText1", true);
    local W, H = XGUIEng.GetWidgetSize(MotherWidget.. "/VoiceText1");

    local X,Y = XGUIEng.GetWidgetLocalPosition(MotherWidget);
    if PageData.Sender ~= -1 then
        XGUIEng.SetWidgetSize(MotherWidget.. "/BG", W + 10, Height + 120);
        Y = 675 - Height;
        XGUIEng.SetWidgetLocalPosition(MotherWidget, X, Y);
    else
        XGUIEng.SetWidgetSize(MotherWidget.. "/BG", W + 10, Height + 35);
        Y = 1115 - Height;
        XGUIEng.SetWidgetLocalPosition(MotherWidget, 46, Y);
    end
end

function ModuleDialogSystem.Local:ResetPlayerPortrait(_PlayerID, _HeadModel)
    local PortraitWidget = "/InGame/Root/Normal/AlignBottomLeft/Message/MessagePortrait/3DPortraitFaceFX";
    local Actor = g_PlayerPortrait[_PlayerID];
    if _HeadModel then
        if not Models["Heads_" .. tostring(_HeadModel)] then
            _HeadModel = "H_NPC_Generic_Trader";
        end
        Actor = _HeadModel;
    end
    XGUIEng.ShowWidget("/InGame/Root/Normal/AlignBottomLeft/Message/MessagePortrait", 1);
    XGUIEng.ShowWidget("/InGame/Root/Normal/AlignBottomLeft/Message/QuestObjectives", 0);
    SetPortraitWithCameraSettings(PortraitWidget, Actor);
    GUI.PortraitWidgetSetRegister(PortraitWidget, "Mood_Friendly", 1,2,0);
    GUI.PortraitWidgetSetRegister(PortraitWidget, "Mood_Angry", 1,2,0);
end

function ModuleDialogSystem.Local:ResetSubtitlesPosition(_PlayerID)
    local Position = self.Dialog[_PlayerID].SubtitlesPosition;
    local SubtitleWidget = "/InGame/Root/Normal/AlignBottomLeft/SubTitles";
    XGUIEng.SetWidgetScreenPosition(SubtitleWidget, Position[1], Position[2]);
end

function ModuleDialogSystem.Local:SetOptionsDialogContent(_PlayerID)
    local Widget = "/InGame/SoundOptionsMain/RightContainer/SoundProviderComboBoxContainer";
    local PageData = self.Dialog[_PlayerID].PageData;

    local Listbox = XGUIEng.GetWidgetID(Widget .. "/ListBox");
    XGUIEng.ListBoxPopAll(Listbox);
    self.Dialog[_PlayerID].MCSelectionOptionsMap = {};
    for i=1, #PageData.MC, 1 do
        if PageData.MC[i].Visible ~= false then
            XGUIEng.ListBoxPushItem(Listbox, PageData.MC[i][1]);
            table.insert(self.Dialog[_PlayerID].MCSelectionOptionsMap, PageData.MC[i].ID);
        end
    end
    XGUIEng.ListBoxSetSelectedIndex(Listbox, 0);

    self:SetOptionsDialogPosition(_PlayerID);
    self.Dialog[_PlayerID].MCSelectionIsShown = true;
end

function ModuleDialogSystem.Local:SetOptionsDialogPosition(_PlayerID)
    local Screen = {GUI.GetScreenSize()};
    local PortraitWidget = "/InGame/SoundOptionsMain/RightContainer/SoundProviderComboBoxContainer";
    local PageData = self.Dialog[_PlayerID].PageData;

    self.Dialog[_PlayerID].MCSelectionBoxPosition = {
        XGUIEng.GetWidgetScreenPosition(PortraitWidget)
    };

    -- Choice
    local ChoiceSize = {XGUIEng.GetWidgetScreenSize(PortraitWidget)};
    local CX = math.ceil((Screen[1] * 0.06) + (ChoiceSize[1] /2));
    local CY = math.ceil(Screen[2] - (ChoiceSize[2] + 60 * (Screen[2]/540)));
    if PageData.Sender == -1 then
        CX = 15 * (Screen[1]/960);
        CY = math.ceil(Screen[2] - (ChoiceSize[2] + 0 * (Screen[2]/540)));
    end
    XGUIEng.SetWidgetScreenPosition(PortraitWidget, CX, CY);
    XGUIEng.PushPage(PortraitWidget, false);
    XGUIEng.ShowWidget(PortraitWidget, 1);

    -- Text
    if PageData.Sender == -1 then
        local TextWidget = "/InGame/Root/Normal/AlignBottomLeft/SubTitles";
        local DX,DY = XGUIEng.GetWidgetLocalPosition(TextWidget);
        XGUIEng.SetWidgetLocalPosition(TextWidget, DX, DY-220);
    end
end

function ModuleDialogSystem.Local:OnOptionSelected(_PlayerID)
    local Widget = "/InGame/SoundOptionsMain/RightContainer/SoundProviderComboBoxContainer";
    local Position = self.Dialog[_PlayerID].MCSelectionBoxPosition;
    XGUIEng.SetWidgetScreenPosition(Widget, Position[1], Position[2]);
    XGUIEng.ShowWidget(Widget, 0);
    XGUIEng.PopPage();

    local Selected = XGUIEng.ListBoxGetSelectedIndex(Widget .. "/ListBox")+1;
    local AnswerID = self.Dialog[_PlayerID].MCSelectionOptionsMap[Selected];
    API.BroadcastScriptEventToGlobal(
        QSB.ScriptEvents.DialogOptionSelected,
        _PlayerID,
        AnswerID
    );
end

function ModuleDialogSystem.Local:ResetTimerButtons(_PlayerID)
    if GUI.GetPlayerID() ~= _PlayerID then
        return;
    end
    local MainWidget = "/InGame/Root/Normal/AlignTopLeft/QuestTimers/";
    for i= 1,6 do
        local ButtonWidget = MainWidget ..i.. "/TimerButton";
        local QuestIndex = g_Interaction.TimerQuests[i];
        if QuestIndex ~= nil then
            local Quest = Quests[QuestIndex];
            if g_Interaction.CurrentMessageQuestIndex == QuestIndex and not QuestLog.IsQuestLogShown() then
                g_Interaction.CurrentMessageQuestIndex = nil;
                g_VoiceMessageIsRunning = false;
                g_VoiceMessageEndTime = nil;
                XGUIEng.ShowWidget("/InGame/Root/Normal/AlignBottomLeft/Message/MessagePortrait", 0);
                XGUIEng.ShowWidget(QuestLog.Widget.Main, 0);
                XGUIEng.ShowWidget("/InGame/Root/Normal/AlignBottomLeft/SubTitles", 0);
                XGUIEng.ShowAllSubWidgets("/InGame/Root/Normal/AlignBottomLeft/Message/QuestObjectives", 0);
                XGUIEng.HighLightButton(ButtonWidget, 0);
            end
            if Quest then
                self:ResetPlayerPortrait(Quest.SendingPlayer);
            end
        end
    end
end

function ModuleDialogSystem.Local:IsAnyCinematicEventActive(_PlayerID)
    for k, v in pairs(ModuleDisplayCore.Local.CinematicEventStatus[_PlayerID]) do
        if v == 1 then
            return true;
        end
    end
    return false;
end

function ModuleDialogSystem.Local:Update()
    for i= 1, 8 do
        if GUI.GetPlayerID() == i and self.Dialog[i] then
            -- Multiple Choice
            if self.Dialog[i].MCSelectionIsShown then
                local Widget = "/InGame/SoundOptionsMain/RightContainer/SoundProviderComboBoxContainer";
                if XGUIEng.IsWidgetShown(Widget) == 0 then
                    self.Dialog[i].MCSelectionIsShown = false;
                    self:OnOptionSelected(i);
                end
            end
        end
    end
end

-- -------------------------------------------------------------------------- --

Swift:RegisterModule(ModuleDialogSystem);

