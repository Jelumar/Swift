-- Core API ----------------------------------------------------------------- --

---
-- Stellt wichtige Kernfunktionen bereit.
--
-- @within Beschreibung
-- @set sort=true
--
Swift = Swift or {};

---
-- Installiert Swift.
--
-- @within Anwenderfunktionen
-- @local
--
function API.Install()
    Swift:LoadCore();
    Swift:LoadModules();
end

-- Lua base functions

function API.OverrideTable()
    ---
    -- Vergleicht zwei Tables anhand der übergebenen Vergleichsfunktion.
    -- @param[type=table]    t1 Table 1
    -- @param[type=table]    t2 Table 2
    -- @param[type=function] fx Vergleichsfunktion
    -- @within table
    --
    table.compare = function(t1, t2, fx)
        assert(type(t1) == "table");
        assert(type(t2) == "table");
        fx = fx or function(t1, t2)
            return tostring(t1) < tostring(t2);
        end
        assert(type(fx) == "function");
        return fx(t1, t2);
    end

    ---
    -- Prüft, ob ein Table identisch zu einem anderen ist. Zwei Tables sind
    -- gleich, wenn ihre Inhalte gleich sind.
    -- @param[type=table] t1 Table 1
    -- @param[type=table] t2 Table 2
    -- @within table
    --
    table.equals = function(t1, t2)
        assert(type(t1) == "table");
        assert(type(t2) == "table");
        for k, v in pairs(t1) do
            if type(v) == "table" then
                if not t2[k] or not table.equals(t2[k], v) then
                    return false;
                end
            elseif type(v) ~= "thread" and type(v) ~= "userdata" then
                if not t2[k] or t2[k] ~= v then
                    return false;
                end
            end
        end
        return true;
    end
    
    ---
    -- Prüft, ob ein Element in einer eindimensionenen Table enthalten ist.
    -- @param[type=table] t Table
    -- @param             e Element
    -- @within table
    --
    table.contains = function (t, e)
        assert(type(t) == "table");
        for k, v in ipairs(t) do
            if v == e then return true; end
        end
        return false;
    end

    ---
    -- Erzeugt eine Deep Copy der Tabelle und schreibt alle Werte optional in
    -- eine weitere Tabelle.
    -- @param[type=table] t1 Quelle
    -- @param[type=table] t2 (Optional) Ziel
    -- @return[type=table] Deep Copy
    -- @within table
    --
    table.copy = function (t1, t2)
        assert(type(t1) == "table");
        assert(type(t2) == "table");
        return Swift:CopyTable(t1, t2);
    end

    ---
    -- Kehr die Reihenfolge aller Elemente in einer Array Table um.
    -- @param[type=table] t1 Table
    -- @return[type=table] Invertierte Table
    -- @within table
    --
    table.invert = function (t1)
        assert(type(t1) == "table");
        local t2 = {};
        for i= #t1, 1, -1 do
            table.insert(t2, t1[i]);
        end
        return t2;
    end

    ---
    -- Fügt ein Element am Anfang einer Tabelle ein.
    -- @param[type=table] t Table
    -- @param             e Element
    -- @within table
    --
    table.push = function (t, e)
        assert(type(t) == "table");
        table.insert(t, 1, e);
    end

    ---
    -- Entfernt das erste Element einer Table und gibt es zurück.
    -- @param[type=table] t Table
    -- @return Element
    -- @within table
    --
    table.pop = function (t)
        assert(type(t) == "table");
        return table.remove(t, 1);
    end

    ---
    -- Serialisiert eine Table als String. Funktionen, Threads und Upvalues
    -- können nicht serialisiert werden.
    -- @param[type=table] t Table
    -- @return[type=string] Serialisierte Table
    -- @within table
    --
    table.tostring = function(t)
        assert(type(t) == "table");
        local s = "{";
        for k, v in pairs(t) do
            local key;
            if (tonumber(k)) then
                key = ""..k;
            else
                key = "\""..k.."\"";
            end
            if type(v) == "table" then
                s = s .. "[" .. key .. "] = " .. table.tostring(v) .. ", ";
            elseif type(v) == "number" then
                s = s .. "[" .. key .. "] = " .. v .. ", ";
            elseif type(v) == "string" then
                s = s .. "[" .. key .. "] = \"" .. v .. "\", ";
            elseif type(v) == "boolean" or type(v) == "nil" then
                s = s .. "[" .. key .. "] = " .. tostring(v) .. ", ";
            else
                s = s .. "[" .. key .. "] = \"" .. tostring(v) .. "\", ";
            end
        end
        s = s .. "}";
        return s;
    end
end

function API.OverrideString()
    -- TODO: Implement!

    ---
    -- Gibt true zurück, wenn der Teil-String enthalten ist.
    -- @param[type=string] s Pattern
    -- @return[type=boolean] Pattern vorhanden
    -- @within string
    --
    string.contains = function (self, s)
        return self:find(s) ~= nil;
    end

    ---
    -- Gibt die Position des Teil-String im String zurück.
    -- @param[type=string] s Pattern
    -- @return[type=number] Startindex
    -- @return[type=number] Endindex
    -- @within string
    --
    string.indexOf = function (self, s)
        return self:find(s);
    end
end

---
-- Aktiviert oder deaktiviert Optionen des Debug Mode.
--
-- <b>Hinweis:</b> Du kannst alle Optionen unbegrenzt oft beliebig ein-
-- und ausschalten.
--
-- @param[type=boolean] _CheckAtRun       Custom Behavior prüfen an/aus
-- @param[type=boolean] _TraceQuests      Quest Trace an/aus
-- @param[type=boolean] _DevelopingCheats Cheats an/aus
-- @param[type=boolean] _DevelopingShell  Eingabeaufforderung an/aus
-- @within Anwenderfunktionen
--
function API.ActivateDebugMode(_CheckAtRun, _TraceQuests, _DevelopingCheats, _DevelopingShell)
    Swift:ActivateDebugMode(
        _CheckAtRun == true,
        _TraceQuests == true,
        _DevelopingCheats == true,
        _DevelopingShell == true
    );
end

---
-- Prüft, ob der Debug Behavior überprüfen darf.
--
-- <b>Hinweis:</b> Module müssen die Behandlung dieser Option selbst
-- inmpelentieren. Das Core Modul übernimmt diese Aufgabe nicht!
--
-- @return[type=boolean] Option Aktiv
-- @within Anwenderfunktionen
--
function API.IsDebugBehaviorCheckActive()
    return Swift.m_CheckAtRun == true;
end

---
-- Prüft, ob Quest Trace benutzt wird.
--
-- @return[type=boolean] Option Aktiv
-- @within Anwenderfunktionen
--
function API.IsDebugQuestTraceActive()
    return Swift.m_TraceQuests == true;
end

---
-- Prüft, ob die Cheats aktiviert sind.
--
-- @return[type=boolean] Option Aktiv
-- @within Anwenderfunktionen
--
function API.IsDebugCheatsActive()
    return Swift.m_DevelopingCheats == true;
end

---
-- Prüft, ob die Eingabeaufforderung aktiv ist.
--
-- <b>Hinweis:</b> Viele Kommandos müssen von Modulen implementiert werden.
-- Siehe die Doku dieser Module.
--
-- @return[type=boolean] Option Aktiv
-- @within Anwenderfunktionen
--
function API.IsDebugShellActive()
    return Swift.m_DevelopingShell == true;
end

---
-- Legt ein neues Script Event an. Dem Event kann optional eine Funktion
-- mitgegeben werden, die ausgeführt werden kann.
--
-- @param[type=string]   _Name     Identifier des Event
-- @param[type=function] _Function (Optional) Funktionsreferenz
-- @return[type=number] ID des neuen Script Event
-- @within Anwenderfunktionen
--
function API.RegisterScriptEvent(_Name, _Function)
    return Swift:CreateScriptEvent(_Name, _Function);
end

---
-- Löscht ein initialisieres Script Event.
--
-- @param[type=number] _ID ID des Event
-- @within Anwenderfunktionen
--
function API.RemoveScriptEvent(_ID)
    return Swift:RemoveScriptEvent(_ID);
end

---
-- Sendet das Script Event mit der übergebenen ID und überträgt optional
-- Parameter.
--
-- @param[type=number] _ID ID des Event
-- @param              ... Optionale Parameter
-- @within Anwenderfunktionen
--
function API.SendScriptEvent(_ID, ...)
    Swift:DispatchScriptEvent(_ID, unpack(arg));
end

---
-- Wandelt underschiedliche Darstellungen einer Boolean in eine echte um.
--
-- Jeder String, der mit j, t, y oder + beginnt, wird als true interpretiert.
-- Alles andere als false.
--
-- Ist die Eingabe bereits ein Boolean wird es direkt zurückgegeben.
--
-- <p><b>Alias:</b> AcceptAlternativeBoolean</p>
--
-- @param _Value Wahrheitswert
-- @return[type=boolean] Wahrheitswert
-- @within Anwenderfunktionen
-- @local
--
-- @usage local Bool = API.ToBoolean("+")  --> Bool = true
-- local Bool = API.ToBoolean("no") --> Bool = false
--
function API.ToBoolean(_Value)
    return Swift:ToBoolean(_Value);
end
AcceptAlternativeBoolean = API.ToBoolean;

---
-- Rundet eine Dezimalzahl kaufmännisch ab.
--
-- <b>Hinweis</b>: Es wird manuell gerundet um den Rundungsfehler in der
-- History Edition zu umgehen.
--
-- <p><b>Alias:</b> Round</p>
--
-- @param[type=string] _Value         Zu rundender Wert
-- @param[type=string] _DecimalDigits Maximale Dezimalstellen
-- @return[type=number] Abgerundete Zahl
-- @within Anwenderfunktionen
--
function API.Round(_Value, _DecimalDigits)
    _DecimalDigits = _DecimalDigits or 2;
    _DecimalDigits = (_DecimalDigits < 0 and 0) or _DecimalDigits;
    local Value = tostring(_Value);
    if tonumber(Value) == nil then
        return 0;
    end
    local s,e = Value:find(".", 1, true);
    if e then
        local Overhead = nil;
        if Value:len() > e + _DecimalDigits then
            if _DecimalDigits > 0 then
                local TmpNum;
                if tonumber(Value:sub(e+_DecimalDigits+1, e+_DecimalDigits+1)) >= 5 then
                    TmpNum = tonumber(Value:sub(e+1, e+_DecimalDigits)) +1;
                    Overhead = (_DecimalDigits == 1 and TmpNum == 10);
                else
                    TmpNum = tonumber(Value:sub(e+1, e+_DecimalDigits));
                end
                Value = Value:sub(1, e-1);
                if (tostring(TmpNum):len() >= _DecimalDigits) then
                    Value = Value .. "." ..TmpNum;
                end
            else
                local NewValue = tonumber(Value:sub(1, e-1));
                if tonumber(Value:sub(e+_DecimalDigits+1, e+_DecimalDigits+1)) >= 5 then
                    NewValue = NewValue +1;
                end
                Value = NewValue;
            end
        else
            Value = (Overhead and (tonumber(Value) or 0) +1) or
                     Value .. string.rep("0", Value:len() - (e + _DecimalDigits))
        end
    end
    return tonumber(Value);
end
Round = API.Round;

---
-- Gibt die ID des Quests mit dem angegebenen Namen zurück. Existiert der
-- Quest nicht, wird nil zurückgegeben.
--
-- <p><b>Alias:</b> GetQuestID</p>
--
-- @param[type=string] _Name Name des Quest
-- @return[type=number] ID des Quest
-- @within Anwenderfunktionen
--
function API.GetQuestID(_Name)
    if type(_Name) == "number" then
        return _Name;
    end
    for k, v in pairs(Quests) do
        if v and k > 0 then
            if v.Identifier == _Name then
                return k;
            end
        end
    end
end
GetQuestID = API.GetQuestID;

---
-- Prüft, ob zu der angegebenen ID ein Quest existiert. Wird ein Questname
-- angegeben wird dessen Quest-ID ermittelt und geprüft.
--
-- <p><b>Alias:</b> IsValidQuest</p>
--
-- @param[type=number] _QuestID ID oder Name des Quest
-- @return[type=boolean] Quest existiert
-- @within Anwenderfunktionen
--
function API.IsValidQuest(_QuestID)
    return Quests[_QuestID] ~= nil or Quests[API.GetQuestID(_QuestID)] ~= nil;
end
IsValidQuest = API.IsValidQuest;

---
-- Prüft den angegebenen Questnamen auf verbotene Zeichen.
--
-- <p><b>Alias:</b> IsValidQuestName</p>
--
-- @param[type=number] _Name Name des Quest
-- @return[type=boolean] Name ist gültig
-- @within Anwenderfunktionen
--
function API.IsValidQuestName(_Name)
    return string.find(_Name, "^[A-Za-z0-9_ @ÄÖÜäöüß]+$") ~= nil;
end
IsValidQuestName = API.IsValidQuestName;

---
-- Lässt den Quest fehlschlagen.
--
-- Der Status wird auf Over und das Resultat auf Failure gesetzt.
--
-- <p><b>Alias:</b> FailQuestByName</p>
--
-- @param[type=string]  _QuestName Name des Quest
-- @param[type=boolean] _NoMessage Meldung nicht anzeigen
-- @within Anwenderfunktionen
--
function API.FailQuest(_QuestName, _NoMessage)
    local Quest = Quests[GetQuestID(_QuestName)];
    if Quest then
        if not _NoMessage then
            Logic.DEBUG_AddNote("fail quest " .._QuestName);
        end
        Quest:RemoveQuestMarkers();
        Quest:Fail();
        Swift:DispatchScriptEvent(QSB.ScriptEvents.QuestFailure, QuestID);
    end
end
FailQuestByName = API.FailQuest;

---
-- Startet den Quest neu.
--
-- Der Quest muss beendet sein um ihn wieder neu zu starten. Wird ein Quest
-- neu gestartet, müssen auch alle Trigger wieder neu ausgelöst werden, außer
-- der Quest wird manuell getriggert.
--
-- Alle Änderungen an Standardbehavior müssen hier berücksichtigt werden. Wird
-- ein Standardbehavior in einem Bundle verändert, muss auch diese Funktion
-- angepasst oder überschrieben werden.
--
-- <p><b>Alias:</b> RestartQuestByName</p>
--
-- @param[type=string]  _QuestName Name des Quest
-- @param[type=boolean] _NoMessage Meldung nicht anzeigen
-- @within Anwenderfunktionen
--
function API.RestartQuest(_QuestName, _NoMessage)
    local QuestID = GetQuestID(_QuestName);
    local Quest = Quests[QuestID];
    if Quest then
        if not _NoMessage then
            Logic.DEBUG_AddNote("restart quest " .._QuestName);
        end

        if Quest.Objectives then
            local questObjectives = Quest.Objectives;
            for i = 1, questObjectives[0] do
                local objective = questObjectives[i];
                objective.Completed = nil
                local objectiveType = objective.Type;

                if objectiveType == Objective.Deliver then
                    local data = objective.Data;
                    data[3] = nil;
                    data[4] = nil;
                    data[5] = nil;

                elseif g_GameExtraNo and g_GameExtraNo >= 1 and objectiveType == Objective.Refill then
                    objective.Data[2] = nil;

                elseif objectiveType == Objective.Protect or objectiveType == Objective.Object then
                    local data = objective.Data;
                    for j=1, data[0], 1 do
                        data[-j] = nil;
                    end

                elseif objectiveType == Objective.DestroyEntities and objective.Data[1] == 2 and objective.DestroyTypeAmount then
                    objective.Data[3] = objective.DestroyTypeAmount;
                elseif objectiveType == Objective.DestroyEntities and objective.Data[1] == 3 then
                    objective.Data[4] = nil;

                elseif objectiveType == Objective.Distance then
                    if objective.Data[1] == -65565 then
                        objective.Data[4].NpcInstance = nil;
                    end

                elseif objectiveType == Objective.Custom2 and objective.Data[1].Reset then
                    objective.Data[1]:Reset(Quest, i);
                end
            end
        end

        local function resetCustom(_type, _customType)
            local Quest = Quest;
            local behaviors = Quest[_type];
            if behaviors then
                for i = 1, behaviors[0] do
                    local behavior = behaviors[i];
                    if behavior.Type == _customType then
                        local behaviorDef = behavior.Data[1];
                        if behaviorDef and behaviorDef.Reset then
                            behaviorDef:Reset(Quest, i);
                        end
                    end
                end
            end
        end

        resetCustom("Triggers", Triggers.Custom2);
        resetCustom("Rewards", Reward.Custom);
        resetCustom("Reprisals", Reprisal.Custom);

        -- Quest Output zurücksetzen
        if Quest.Visible_OrigDebug then
            Quest.Visible = Quest.Visible_OrigDebug;
            Quest.Visible_OrigDebug = nil;
        end
        if Quest.ShowEndMessage then
            Quest.ShowEndMessage = Quest.ShowEndMessage_OrigDebug;
            Quest.ShowEndMessage_OrigDebug = nil;
        end
        if Quest.QuestStartMsg_OrigDebug then
            Quest.QuestStartMsg = Quest.QuestStartMsg_OrigDebug;
            Quest.QuestStartMsg_OrigDebug = nil;
        end
        if Quest.QuestSuccessMsg_OrigDebug then
            Quest.QuestSuccessMsg = Quest.QuestSuccessMsg_OrigDebug;
            Quest.QuestSuccessMsg_OrigDebug = nil;
        end
        if Quest.QuestFailureMsg_OrigDebug then
            Quest.QuestFailureMsg = Quest.QuestFailureMsg_OrigDebug;
            Quest.QuestFailureMsg_OrigDebug = nil;
        end

        Quest.Result = nil;
        local OldQuestState = Quest.State;
        Quest.State = QuestState.NotTriggered;
        Logic.ExecuteInLuaLocalState("LocalScriptCallback_OnQuestStatusChanged("..Quest.Index..")");
        if OldQuestState == QuestState.Over then
            StartSimpleJobEx(_G[QuestTemplate.Loop], Quest.QueueID);
        end
        Swift:DispatchScriptEvent(QSB.ScriptEvents.QuestReset, QuestID);
        return QuestID, Quest;
    end
end
RestartQuestByName = API.RestartQuest;

---
-- Startet den Quest sofort, sofern er existiert.
--
-- Dabei ist es unerheblich, ob die Bedingungen zum Start erfüllt sind.
--
-- <p><b>Alias:</b> StartQuestByName</p>
--
-- @param[type=string]  _QuestName Name des Quest
-- @param[type=boolean] _NoMessage Meldung nicht anzeigen
-- @within Anwenderfunktionen
--
function API.StartQuest(_QuestName, _NoMessage)
    local Quest = Quests[GetQuestID(_QuestName)];
    if Quest then
        if not _NoMessage then
            Logic.DEBUG_AddNote("start quest " .._QuestName);
        end
        Quest:SetMsgKeyOverride();
        Quest:SetIconOverride();
        Quest:Trigger();
        Swift:DispatchScriptEvent(QSB.ScriptEvents.QuestTrigger, QuestID);
    end
end
StartQuestByName = API.StartQuest;

---
-- Unterbricht den Quest.
--
-- Der Status wird auf Over und das Resultat auf Interrupt gesetzt. Sind Marker
-- gesetzt, werden diese entfernt.
--
-- <p><b>Alias:</b> StopQuestByName</p>
--
-- @param[type=string]  _QuestName Name des Quest
-- @param[type=boolean] _NoMessage Meldung nicht anzeigen
-- @within Anwenderfunktionen
--
function API.StopQuest(_QuestName, _NoMessage)
    local Quest = Quests[GetQuestID(_QuestName)];
    if Quest then
        if not _NoMessage then
            Logic.DEBUG_AddNote("interrupt quest " .._QuestName);
        end
        Quest:RemoveQuestMarkers();
        Quest:Interrupt(-1);
        Swift:DispatchScriptEvent(QSB.ScriptEvents.QuestInterrupt, QuestID);
    end
end
StopQuestByName = API.StopQuest;

---
-- Gewinnt den Quest.
--
-- Der Status wird auf Over und das Resultat auf Success gesetzt.
--
-- <p><b>Alias:</b> WinQuestByName</p>
--
-- @param[type=string]  _QuestName Name des Quest
-- @param[type=boolean] _NoMessage Meldung nicht anzeigen
-- @within Anwenderfunktionen
--
function API.WinQuest(_QuestName, _NoMessage)
    local Quest = Quests[GetQuestID(_QuestName)];
    if Quest then
        if not _NoMessage then
            Logic.DEBUG_AddNote("win quest " .._QuestName);
        end
        Quest:RemoveQuestMarkers();
        Quest:Success();
        Swift:DispatchScriptEvent(QSB.ScriptEvents.QuestSuccess, QuestID);
    end
end
WinQuestByName = API.WinQuest;
