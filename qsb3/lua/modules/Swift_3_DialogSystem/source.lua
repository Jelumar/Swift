--[[
Swift_3_DialogSystem/Source

Copyright (C) 2021 totalwarANGEL - All Rights Reserved.

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
        Dialog = {},
        DialogQueue = {},

        Text = {
            Continue = {
                de = "{cr}{cr}{azure}(Weiter mit ESC)",
                en = "{cr}{cr}{azure}(Continue with ESC)"
            }
        },
    },
    Local = {
        Dialog = {},
    },
    -- This is a shared structure but the values are asynchronous!
    Shared = {},
};

-- Global ------------------------------------------------------------------- --

function ModuleDialogSystem.Global:OnGameStart()
    for i= 1, 8 do
        ModuleDialogSystem.Global.DialogQueue[i] = {};
    end
    
    StartSimpleHiResJobEx(function()
        for i= 1, 8 do
            if ModuleDialogSystem.Global:CanStartDialog(i) then
                if #ModuleDialogSystem.Global.DialogQueue[i] > 0 then
                    ModuleDialogSystem.Global:NextDialog(i);
                end
            end
        end
    end);
end

function ModuleDialogSystem.Global:OnEvent(_ID, _Event, _PlayerID)
    if _ID == QSB.ScriptEvents.EscapePressed then
        if self.Dialog[_PlayerID] ~= nil then
            if Logic.GetTime() - self.Dialog[_PlayerID].PageStartedTime >= 6 then
                self:NextPage(_PlayerID);
            end
        end
    end
end

function ModuleDialogSystem.Global:StartDialog(_Name, _PlayerID, _Data)
    self.DialogQueue[_PlayerID] = self.DialogQueue[_PlayerID] or {};
    table.insert(self.DialogQueue[_PlayerID], {_Name, _Data});
end

function ModuleDialogSystem.Global:EndDialog(_PlayerID)
    API.FinishCinematicEvent(self.Dialog[_PlayerID].Name);
    if self.Dialog[_PlayerID].Finished then
        self.Dialog[_PlayerID]:Finished();
    end
    self.Dialog[_PlayerID] = nil;
    if #self.DialogQueue[_PlayerID] > 0 then
        return;
    end
    Logic.ExecuteInLuaLocalState(string.format(
        "ModuleDialogSystem.Local:EndDialog(%d)",
        _PlayerID
    ));
end

function ModuleDialogSystem.Global:CanStartDialog(_PlayerID)
    return self.Dialog[_PlayerID] == nil and not API.IsCinematicEventActive(_PlayerID);
end

function ModuleDialogSystem.Global:NextDialog(_PlayerID)
    if self:CanStartDialog() then
        local Dialog = table.remove(self.DialogQueue[_PlayerID], 1);
        API.StartCinematicEvent(Dialog[1], _PlayerID);

        Dialog.Name = Dialog[1];
        Dialog.CurrentPage = 0;
        self.Dialog[_PlayerID] = Dialog;
        if self.Dialog[_PlayerID].Starting then
            self.Dialog[_PlayerID]:Starting();
        end

        Logic.ExecuteInLuaLocalState(string.format(
            "ModuleDialogSystem.Local:StartDialog(%d)",
            _PlayerID
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
    if self.DialogQueue[_PlayerID].PageQuest then
        API.StopQuest(self.DialogQueue[_PlayerID].PageQuest, true);
    end

    local PageID = self.Dialog[_PlayerID].CurrentPage;
    if PageID <= #self.Dialog[_PlayerID][2] then
        if self.Dialog[_PlayerID][2][PageID].Action then
            self.Dialog[_PlayerID][2][PageID]:Action();
        end
        self.DialogQueue[_PlayerID].PageQuest = self:DisplayPage(_PlayerID, PageID);
    else
        self:EndDialog(_PlayerID);
    end
end

function ModuleDialogSystem.Global:DisplayPage(_PlayerID, _PageID)
    if self.Dialog[_PlayerID] == nil then
        return;
    end

    self.DialogPageCounter = self.DialogPageCounter +1;
    local Page = self.Dialog[_PlayerID][2][_PageID];
    local QuestName = "DialogSystemQuest_" .._PlayerID.. "_" ..self.DialogPageCounter;
    local QuestText = API.ConvertPlaceholders(API.Localize(Page.Text));
    local Extension  = API.ConvertPlaceholders(API.Localize(self.Text.Continue));
    AddQuest {
        Name        = QuestName,
        Suggestion  = QuestText .. Extension,
        Sender      = Page.Sender or _PlayerID,
        Receiver    = _PlayerID,

        Goal_NoChange(),
        Trigger_Time(0),
    }

    Logic.ExecuteInLuaLocalState(string.format(
        [[ModuleDialogSystem.Local:DisplayPage(%d, %s)]],
        _PlayerID,
        table.tostring(Page)
    ));
    return QuestName;
end

-- Local -------------------------------------------------------------------- --

function ModuleDialogSystem.Local:OnGameStart()
end

function ModuleDialogSystem.Local:StartDialog(_PlayerID)
    if GUI.GetPlayerID() == _PlayerID then
        API.DeactivateNormalInterface();
        API.DeactivateBorderScroll();
        XGUIEng.ShowWidget("/InGame/Root/Normal/AlignBottomLeft/Message", 1);
        XGUIEng.ShowWidget("/InGame/Root/Normal/AlignBottomLeft/SubTitles", 1);
        XGUIEng.ShowWidget("/InGame/Root/3dWorldView", 0);
        GUI.ClearSelection();

        -- Make camera backup
        if not self.Dialog[_PlayerID] then
            self.Dialog[_PlayerID] = {
                Rotation = Camera.RTS_GetRotationAngle();
                Zoom     = Camera.RTS_GetZoomFactor();
                Position = {Camera.RTS_GetLookAtPosition()}
            };
        end
    end
end

function ModuleDialogSystem.Local:EndDialog(_PlayerID)
    if GUI.GetPlayerID() == _PlayerID then
        API.ActivateNormalInterface();
        API.ActivateBorderScroll();
        XGUIEng.ShowWidget("/InGame/Root/Normal/AlignBottomLeft/Message", 0);
        XGUIEng.ShowWidget("/InGame/Root/Normal/AlignBottomLeft/SubTitles", 0);
        XGUIEng.ShowWidget("/InGame/Root/3dWorldView", 1);

        -- Load camera backup
        Camera.RTS_FollowEntity(0);
        if self.Dialog[_PlayerID] then
            Camera.RTS_SetRotationAngle(self.Dialog[_PlayerID].Rotation);
            Camera.RTS_SetZoomFactor(self.Dialog[_PlayerID].Zoom);
            Camera.RTS_SetLookAtPosition(
                self.Dialog[_PlayerID].Position[1],
                self.Dialog[_PlayerID].Position[2]
            );
            self.Dialog[_PlayerID] = nil;
        end
    end
end

function ModuleDialogSystem.Local:DisplayPage(_PlayerID, _PageData)
    if GUI.GetPlayerID() == _PlayerID then
        GUI.ClearSelection();
        if _PageData.Target then
            Camera.RTS_FollowEntity(GetID(_PageData.Target));
        else
            Camera.RTS_FollowEntity(0);
        end
        if _PageData.Position then
            Camera.RTS_ScrollSetLookAt(_PageData.Position.X, _PageData.Position.Y);
        end
        if _PageData.Zoom then
            Camera.RTS_SetZoomFactorMin(_PageData.Zoom -0.00001);
            Camera.RTS_SetZoomFactor(_PageData.Zoom);
            Camera.RTS_SetZoomFactorMax(_PageData.Zoom +0.00001);
        end
        if _PageData.Rotation then
            Camera.RTS_SetRotationAngle(_PageData.Rotation);
        end
    end
end

-- -------------------------------------------------------------------------- --

Swift:RegisterModules(ModuleDialogSystem);
