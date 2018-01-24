-- -------------------------------------------------------------------------- --
-- ########################################################################## --
-- #  Symfonia BundleBriefingSystem                                         # --
-- ########################################################################## --
-- -------------------------------------------------------------------------- --

---
-- Ermöglicht das Erstellen von s.g. Briefings und Cutscenes zur szenischen
-- Untermalung der Handlung. Es werden viele Features unterstützt, die es im
-- original Briefing System nicht gab. Wie z.B. Multiple Choice, Splashscreens,
-- Z-Achse, Menüstrukturen, Vorwärts- und Rückwärtssprünge, ....
--
-- @module BundleBriefingSystem
-- @set sort=true
--

API = API or {};
QSB = QSB or {};

-- -------------------------------------------------------------------------- --
-- User-Space                                                                 --
-- -------------------------------------------------------------------------- --

---
--
--
function API.GetCurrentBriefing()
    return BriefingSystem.currBriefing;
end
GetCurrentBriefing = API.GetCurrentBriefing

---
--
--
function API.GetPageOfCurrentBriefing(_PageNumber)
    return BriefingSystem.currBriefing[_PageNumber];
end
GetCurrentBriefingPage = API.GetPageOfCurrentBriefing

---
--
--
function API.GetSelectedDialogOption(_Page)
    if _Page.mc and _Page.mc.given then
        return _Page.mc.given;
    end
    return 0;
end
MCGetSelectedAnswer = API.GetSelectedDialogOption

---
--
--
function API.IsBriefingFinished(_BriefingID)
    return BundleBriefingSystem.Global.PlayedBriefings[_BriefingID] == true;
end
IsBriefingFinished = API.IsBriefingFinished

---
--
--
function API.GetPageFunctions(_Page)
    ---
    -- Erstellt eine Seite in normaler Syntax oder als Cutscene.
    -- AP kann auch fόr Sprungbefehle genutzt werden. Dabei wird der
    -- Index der Zielseite angebenen.
    -- Fόr Multiple Choice dienen leere AP-Seiten als Signal, dass
    -- ein Briefing an dieser Stelle endet.
    -- 
    -- _Page	Seite
    --
    -- return table
    --
    local AP = function(_Page)
        if _Page and type(_Page) == "table" then
            local lang = (Network.GetDesiredLanguage() == "de" and "de") or "en";
            if type(_Page.title) == "table" then
                _Page.title = _Page.title[lang];
            end
            _Page.title = _Page.title or "";
            if type(_Page.text) == "table" then
                _Page.text = _Page.text[lang];
            end
            _Page.text = _Page.text or "";

            -- Multiple Choice Support
            if _Page.mc then
                if _Page.mc.answers then
                    _Page.mc.amount  = #_Page.mc.answers;
                    assert(_Page.mc.amount >= 1);
                    _Page.mc.current = 1;

                    for i=1, _Page.mc.amount do
                        if _Page.mc.answers[i] then
                            if type(_Page.mc.answers[i][1]) == "table" then
                                _Page.mc.answers[i][1] = _Page.mc.answers[i][1][lang];
                            end
                        end
                    end
                end
                if type(_Page.mc.title) == "table" then
                    _Page.mc.title = _Page.mc.title [lang];
                end
                if type(_Page.mc.text) == "table" then
                    _Page.mc.text = _Page.mc.text[lang];
                end
            end

            -- Cutscene Support
            if _Page.view then
                _Page.flyTime  = _Page.view.FlyTime or 0;
                _Page.duration = _Page.view.Duration or 0;
            else
                if type(_Page.position) == "table" then
                    if not _Page.position.X then
                        _Page.zOffset = _Page.position[2];
                        _Page.position = _Page.position[1];
                    elseif _Page.position.Z then
                        _Page.zOffset = _Page.position.Z;
                    end
                end

                if _Page.lookAt ~= nil then
                    local lookAt = _Page.lookAt;
                    if type(lookAt) == "table" then
                        _Page.zOffset = lookAt[2];
                        lookAt = lookAt[1];
                    end

                    if type(lookAt) == "string" or type(lookAt) == "number" then
                        local eID    = GetID(lookAt);
                        local ori    = Logic.GetEntityOrientation(eID);
                        if Logic.IsBuilding(eID) == 0 then
                            ori = ori + 90;
                        end
                        local tpCh = 0.085 * string.len(_Page.text);

                        _Page.position = eID;
                        _Page.duration = _Page.duration or tpCh;
                        _Page.flyTime  = _Page.flyTime;
                        _Page.rotation = (_Page.rotation or 0) +ori;
                    end
                end
            end
            table.insert(_briefing, _Page);
        else
            -- Sprόnge, Rόcksprόnge und Abbruch
            table.insert(_briefing, (_Page ~= nil and _Page) or -1);
        end
        return _Page;
    end
    
    ---
    -- Erstellt eine Seite in vereinfachter Syntax. Es wird davon
    -- Ausgegangen, dass das Entity ein Siedler ist. Die Kamera
    -- schaut den Siedler an.
    --
    -- _entity			Zielentity
    -- _title			Titel der Seite
    -- _text			Text der Seite
    -- _dialogCamera	Nahsicht an/aus
    -- _action			Callback-Funktion
    -- 
    -- return table
    --
    local ASP = function(_entity, _title, _text, _dialogCamera, _action)
        local Entity = Logic.GetEntityName(GetID(_entity));
        assert(Entity ~= nil and Entity ~= "");
        
        local page  = {};
        page.zoom   = (_dialogCamera == true and 2400 ) or 6250;
        page.angle  = (_dialogCamera == true and 40 ) or 47;
        page.lookAt = {Entity, 100};
        page.title  = _title;
        page.text   = _text or "";
        page.action = _action;
        return AP(page);
    end

    ---
    -- Erstellt eine Multiple Choise Seite in vereinfachter Syntax. Es
    -- wird davon Ausgegangen, dass das Entity ein Siedler ist. Die
    -- Kamera schaut den Siedler an.
    --
    -- _entity			Zielentity
    -- _title			Titel der Seite
    -- _text			Text der Seite
    -- _dialogCamera	Nahsicht an/aus
    -- ...				Liste der Antworten und Sprungziele
    --
    -- return table
    --
    local ASMC = function(_entity, _title, _text, _dialogCamera, ...)
        local Entity = Logic.GetEntityName(GetID(_entity));
        assert(Entity ~= nil and Entity ~= "");
        
        local page    = {};
        page.zoom     = (_dialogCamera == true and 2400 ) or 6250;
        page.angle    = (_dialogCamera == true and 40 ) or 47;
        page.lookAt   = {Entity, 100};
        page.barStyle = "big";

        page.mc = {
            title = _title,
            text = _text,
            answers = {}
        };
        local args = {...};
        for i=1, #args-1, 2 do
            page.mc.answers[#page.mc.answers+1] = {args[i], args[i+1]};
        end
        return AP(page);
    end
    return AP, ASP, ASMC;
end
AddPages = API.GetPageFunctions

---
--
--
function API.SetQuestsPaused(_Flag)
    BundleBriefingSystem.Global.Data.QuestsPausedWhileBriefingActive = _Flag == true;
end
PauseQuestsDuringBriefings = API.SetQuestsPaused


---
-- Schreibt eine Nachricht in die untere Ausagbezeile. Optional kann
-- ein Schatten gesetzt werden.
--
-- _text		Text
-- _darkshadow	Schattentyp
--
function API.GUIMessage(_text, _darkshadow)
    local text = _text;
    _darkshadow = (_darkshadow == true and "{darkshadow}") or _darkshadow;
    _text = ((_darkshadow ~= nil and _darkshadow) or "") .. _text;
    Logic.ExecuteInLuaLocalState([[Message("]]..text..[[")]]);
end
GUI_NoteDown = API.GUIMessage

---
--
--
function API.GUINote(_text, _toLog)
    if _toLog then
        Framework.WriteToLog(string.format(
            "%10d Message: %s",
            Logic.GetTimeMs(),
            _text
        ));
    end
    -- print notes in briefings
    if IsBriefingActive() then
        Logic.ExecuteInLuaLocalState([[
            BriefingSystem.PushInformationText("]].._text..[[")
        ]]);
        return;
    end
    Logic.DEBUG_AddNote(_text);
end
GUI_Note = API.GUINote

-- -------------------------------------------------------------------------- --
-- Application-Space                                                          --
-- -------------------------------------------------------------------------- --

BundleBriefingSystem = {
    Global = {
        Data = {
            QuestsPausedWhileBriefingActive = true,
            BriefingID = 0,
            PlayedBriefings = {},
        }
    },
    Local = {
        Data = {}
    },
    Shared = {
        Colors = {
            Blue1   = "{@color:70,70,255,255}",
            Blue2   = "{@color:153,210,234,255}",
            White   = "{@color:255,255,255,255}",
            Red     = "{@color:255,32,32,255}",
            Yellow  = "{@color:244,184,0,255}",
            Green   = "{@color:173,255,47,255}",
            Orange  = "{@color:255,127,0,255}",
            Mint    = "{@color:0,255,255,255}",
            Gray    = "{@color:180,180,180,255}",
            Trans   = "{@color:0,0,0,0}",
        }
    },
}

-- Global Script ---------------------------------------------------------------

---
-- Initialisiert das Bundle im globalen Skript.
-- @within Application-Space
-- @local
--
function BundleBriefingSystem.Global:Install()
    self:InitalizeSystem()
end

---
--
--
function BundleBriefingSystem.Global:InitalizeSystem()
    Quest_Loop = function(_arguments)
        local self = JobQueue_GetParameter(_arguments)

        if self.LoopCallback ~= nil then
            self:LoopCallback()
        end

        if self.State == QuestState.NotTriggered then
            local triggered = true
            for i = 1, self.Triggers[0] do
                triggered = triggered and self:IsTriggerActive(self.Triggers[i])
            end
            if triggered then
                self:SetMsgKeyOverride()
                self:SetIconOverride()
                self:Trigger()
            end

        elseif self.State == QuestState.Active then
            local allTrue = true
            local anyFalse = false
            for i = 1, self.Objectives[0] do
                local completed = self:IsObjectiveCompleted(self.Objectives[i])

                -- Wenn ein Briefing lδuft, vergeht keine Zeit in laufenden Quests
                if IsBriefingActive() then
                    if BundleBriefingSystem.Global.Data.QuestsPausedWhileBriefingActive == true then
                        self.StartTime = self.StartTime +1;
                    end
                end

                if self.Objectives[i].Type == Objective.Deliver and completed == nil then
                    if self.Objectives[i].Data[4] == nil then
                        self.Objectives[i].Data[4] = 0
                    end
                    if self.Objectives[i].Data[3] ~= nil then
                        self.Objectives[i].Data[4] = self.Objectives[i].Data[4] + 1
                    end

                    local st = self.StartTime
                    local sd = self.Duration
                    local dt = self.Objectives[i].Data[4]
                    local sum = self.StartTime + self.Duration - self.Objectives[i].Data[4]
                    if self.Duration > 0 and self.StartTime + self.Duration + self.Objectives[i].Data[4] < Logic.GetTime() then
                        completed = false
                    end
                else
                    if self.Duration > 0 and self.StartTime + self.Duration < Logic.GetTime() then
                        if completed == nil and
                            (self.Objectives[i].Type == Objective.Protect or self.Objectives[i].Type == Objective.Dummy or self.Objectives[i].Type == Objective.NoChange) then
                            completed = true
                        elseif completed == nil or self.Objectives[i].Type == Objective.DummyFail then
                            completed = false
                       end
                    end
                end
                allTrue = (completed == true) and allTrue
                anyFalse = completed == false or anyFalse
            end

            if allTrue then
                self:Success()
            elseif anyFalse then
                self:Fail()
            end

        else
            if self.IsEventQuest == true then
                Logic.ExecuteInLuaLocalState("StopEventMusic(nil, "..self.ReceivingPlayer..")")
            end

            if self.Result == QuestResult.Success then
                for i = 1, self.Rewards[0] do
                    self:AddReward(self.Rewards[i])
                end
            elseif self.Result == QuestResult.Failure then
                for i = 1, self.Reprisals[0] do
                    self:AddReprisal(self.Reprisals[i])
                end
            end

            if self.EndCallback ~= nil then
                self:EndCallback()
            end

            return true
        end
    end

    -- Briefing System Beginn ----------------------------------------------

    BriefingSystem = {
        isActive = false,
        waitList = {},
        isInitialized = false,
        maxMarkerListEntry = 0,
        currBriefingIndex = 0,
        loadScreenHidden = false
    };

    BriefingSystem.BRIEFING_CAMERA_ANGLEDEFAULT = 43;
    BriefingSystem.BRIEFING_CAMERA_ROTATIONDEFAULT = -45;
    BriefingSystem.BRIEFING_CAMERA_ZOOMDEFAULT = 6250;
    BriefingSystem.BRIEFING_CAMERA_FOVDEFAULT = 42;
    BriefingSystem.BRIEFING_DLGCAMERA_ANGLEDEFAULT = 29;
    BriefingSystem.BRIEFING_DLGCAMERA_ROTATIONDEFAULT = -45;
    BriefingSystem.BRIEFING_DLGCAMERA_ZOOMDEFAULT = 3400;
    BriefingSystem.BRIEFING_DLGCAMERA_FOVDEFAULT = 25;
    BriefingSystem.STANDARDTIME_PER_PAGE = 1;
    BriefingSystem.SECONDS_PER_CHAR = 0.05;
    BriefingSystem.COLOR1 = "{@color:255,250,0,255}";
    BriefingSystem.COLOR2 = "{@color:255,255,255,255}";
    BriefingSystem.COLOR3 = "{@color:250,255,0,255}";
    BriefingSystem.BRIEFING_FLYTIME = 0;
    BriefingSystem.POINTER_HORIZONTAL = 1;
    BriefingSystem.POINTER_VERTICAL = 4;
    BriefingSystem.POINTER_VERTICAL_LOW = 5;
    BriefingSystem.POINTER_VERTICAL_HIGH = 6;
    BriefingSystem.ANIMATED_MARKER = 1;
    BriefingSystem.STATIC_MARKER = 2;
    BriefingSystem.POINTER_PERMANENT_MARKER = 6;
    BriefingSystem.ENTITY_PERMANENT_MARKER = 8;
    BriefingSystem.SIGNAL_MARKER = 0;
    BriefingSystem.ATTACK_MARKER = 3;
    BriefingSystem.CRASH_MARKER = 4;
    BriefingSystem.POINTER_MARKER = 5;
    BriefingSystem.ENTITY_MARKER = 7;
    BriefingSystem.BRIEFING_EXPLORATION_RANGE = 6000;
    BriefingSystem.SKIPMODE_ALL = 1;
    BriefingSystem.SKIPMODE_PERPAGE = 2;
    BriefingSystem.DEFAULT_EXPLORE_ENTITY = "XD_Camera";

    ---
    -- Startet ein Briefing im Cutscene Mode und deaktiviert alle nicht
    -- erlaubten Operationen, wie seitenweises άberspringen oder eine
    -- Multiple Choice Seite.
    --
    -- _briefing	Briefing-Tabelle
    --
    -- return table
    --
    function BriefingSystem.StartCutscene(_briefing)
        -- Seitenweises abbrechen ist nicht erlaubt!
        _briefing.skipPerPage = false;

        for i=1, #_briefing, 1 do
            -- Multiple Choice ist ebenfalls nicht erlaubt
            if _briefing[i].mc then
                return;
            end
        end

        return BriefingSystem.StartBriefing(_briefing, true);
    end
    StartCutscene = BriefingSystem.StartCutscene;

    ---
    -- Startet ein briefing. Im Cutscene Mode wird die normale Kamera
    -- deaktiviert und durch die Cutsene Kamera ersetzt. Auίerdem
    -- kφnnen Grenzsteine ausgeblendet und der Himmel angezeigt werden.
    -- Die Okklusion wird abgeschaltet Alle Δnderungen werden nach dem
    -- Briefing automatisch zurόckgesetzt.
    -- Lδuft bereits ein Briefing, kommt das neue in die Warteschlange.
    -- Es wird die ID des erstellten Briefings zurόckgegeben.
    --
    -- _briefing		Briefing-Table
    -- _cutsceneMode	Cutscene-Mode nutzen?
    --
    -- return number
    --
    function BriefingSystem.StartBriefing(_briefing, _cutsceneMode)
        -- view wird nur Ausgefόhrt, wenn es sich um eine Cutscene handelt
        -- CutsceneMode = false -> alte Berechnung und Syntax
        _cutsceneMode = _cutsceneMode or false;
        Logic.ExecuteInLuaLocalState([[
            BriefingSystem.Flight.systemEnabled = ]]..tostring(not _cutsceneMode)..[[
        ]]);

        -- Briefing ID erzeugen
        BundleBriefingSystem.Global.BriefingID = BundleBriefingSystem.Global.BriefingID +1;
        _briefing.UniqueBriefingID = BundleBriefingSystem.Global.BriefingID;

        if #_briefing > 0 then
            _briefing[1].duration = (_briefing[1].duration or 0) + 0.1;
        end

        -- Grenzsteine ausblenden
        if _briefing.hideBorderPins then
            Logic.ExecuteInLuaLocalState([[Display.SetRenderBorderPins(0)]]);
        end
        
        -- Himmel anzeigen
        if _briefing.showSky then
            Logic.ExecuteInLuaLocalState([[Display.SetRenderSky(1)]]);
        end

        -- Okklusion abschalten
        Logic.ExecuteInLuaLocalState([[
            Display.SetUserOptionOcclusionEffect(0)
        ]]);

        -- callback όberschreiben
        _briefing.finished_OrigMODULEBRIEFING = _briefing.finished;
        _briefing.finished = function(self)
            -- Grenzsteine einschalten
            if _briefing.hideBorderPins then
                Logic.ExecuteInLuaLocalState([[Display.SetRenderBorderPins(1)]]);
            end
            
            --
            if _briefing.showSky then
                Logic.ExecuteInLuaLocalState([[Display.SetRenderSky(0)]]);
            end

            -- Okklusion einschalten, wenn sie aktiv war
            Logic.ExecuteInLuaLocalState([[
                if Options.GetIntValue("Display", "Occlusion", 0) > 0 then
                    Display.SetUserOptionOcclusionEffect(1)
                end
            ]]);

            _briefing.finished_OrigMODULEBRIEFING(self);
            BundleBriefingSystem.Global.PlayedBriefings[_briefing.UniqueBriefingID] = true;
        end

        -- Briefing starten
        if BriefingSystem.isActive then
            table.insert(BriefingSystem.waitList, _briefing);
            if not BriefingSystem.waitList.Job then
                BriefingSystem.waitList.Job = StartSimpleJob("BriefingSystem_WaitForBriefingEnd");
            end
        else
            BriefingSystem.ExecuteBriefing(_briefing);
        end
        return BundleBriefingSystem.Global.BriefingID;
    end
    StartBriefing = BriefingSystem.StartBriefing;

    function BriefingSystem.EndBriefing()
        BriefingSystem.isActive = false;
        Logic.SetGlobalInvulnerability(0);
        local briefing = BriefingSystem.currBriefing;
        BriefingSystem.currBriefing = nil;
        BriefingSystem[BriefingSystem.currBriefingIndex] = nil;
        Logic.ExecuteInLuaLocalState("BriefingSystem.EndBriefing()");
        EndJob(BriefingSystem.job);
        if briefing.finished then
            briefing:finished();
        end
    end

    function BriefingSystem_WaitForBriefingEnd()
        if not BriefingSystem.isActive and BriefingSystem.loadScreenHidden then
            BriefingSystem.ExecuteBriefing(table.remove(BriefingSystem.waitList), 1);
            if #BriefingSystem.waitList == 0 then
                BriefingSystem.waitList.Job = nil;
                return true;
            end
        end
    end

    function BriefingSystem.ExecuteBriefing(_briefing)
        if not BriefingSystem.isInitialized then
            Logic.ExecuteInLuaLocalState("BriefingSystem.InitializeBriefingSystem()");
            BriefingSystem.isInitialized = true;
        end
        BriefingSystem.isActive = true;
        BriefingSystem.currBriefing = _briefing;
        BriefingSystem.currBriefingIndex = BriefingSystem.currBriefingIndex + 1;
        BriefingSystem[BriefingSystem.currBriefingIndex] = _briefing;
        BriefingSystem.timer = 0;
        BriefingSystem.page = 0;
        BriefingSystem.skipPlayers = {};
        BriefingSystem.disableSkipping = BriefingSystem.currBriefing.disableSkipping;
        BriefingSystem.skipAll = BriefingSystem.currBriefing.skipAll;
        BriefingSystem.skipPerPage = not BriefingSystem.skipAll and BriefingSystem.currBriefing.skipPerPage;

        if not _briefing.disableGlobalInvulnerability then
            Logic.SetGlobalInvulnerability(1);
        end

        Logic.ExecuteInLuaLocalState("BriefingSystem.PrepareBriefing()");
        BriefingSystem.currBriefing = BriefingSystem.RemoveObsolateAnswers(BriefingSystem.currBriefing);
        BriefingSystem.job = Trigger.RequestTrigger(Events.LOGIC_EVENT_EVERY_TURN, "BriefingSystem_Condition_Briefing", "BriefingSystem_Action_Briefing", 1);
        if not BriefingSystem.loadScreenHidden then
            Logic.ExecuteInLuaLocalState("BriefingSystem.Briefing(true)");
        elseif BriefingSystem_Action_Briefing() then
            EndJob(BriefingSystem.job);
        end
    end

    -- Entfernt Multiple Choice Optionen, wenn die Remove Condition
    -- zutrifft. Diese Optionen sind dann nicht mehr auswδhlbar.

    function BriefingSystem.RemoveObsolateAnswers(_briefing)
        if _briefing then
            local i = 1;
            while (_briefing[i] ~= nil and #_briefing >= i)
            do
                if type(_briefing[i]) == "table" and _briefing[i].mc and _briefing[i].mc.answers then
                    local aswID = 1;
                    local j = 1;
                    while (_briefing[i].mc.answers[j] ~= nil)
                    do
                        -- vorhandene IDs dόrfen sich nicht mehr δndern
                        if not _briefing[i].mc.answers[j].ID then
                            _briefing[i].mc.answers[j].ID = aswID;
                        end
                        if type(_briefing[i].mc.answers[j][3]) == "function" and _briefing[i].mc.answers[j][3](_briefing[i].mc.answers[j]) then
                            Logic.ExecuteInLuaLocalState([[
                                local b = BriefingSystem.currBriefing
                                if b and b[]]..i..[[] and b[]]..i..[[].mc then
                                    table.remove(BriefingSystem.currBriefing[]]..i..[[].mc.answers, ]]..j..[[)
                                end
                            ]]);
                            table.remove(_briefing[i].mc.answers,j);
                            j = j -1;
                        end
                        aswID = aswID +1;
                        j = j +1;
                    end
                    if #_briefing[i].mc.answers == 0 then
                        local lang = Network.GetDesiredLanguage();
                        _briefing[i].mc.answers[1] = {(lang == "de" and "ENDE") or "END", 999999};
                    end
                end
                i = i +1;
            end
        end
        return _briefing;
    end

    function BriefingSystem.IsBriefingActive()
        return BriefingSystem.isActive;
    end
    IsBriefingActive = BriefingSystem.IsBriefingActive

    function BriefingSystem_Condition_Briefing()
        if not BriefingSystem.loadScreenHidden then
            return false;
        end
        BriefingSystem.timer = BriefingSystem.timer - 0.1;
        return BriefingSystem.timer <= 0;
    end

    function BriefingSystem_Action_Briefing()
        BriefingSystem.page = BriefingSystem.page + 1;

        local page;
        if BriefingSystem.currBriefing then
            page = BriefingSystem.currBriefing[BriefingSystem.page];
        end

        if not BriefingSystem.skipAll and not BriefingSystem.disableSkipping then
            for i = 1, 8 do
                if BriefingSystem.skipPlayers[i] ~= BriefingSystem.SKIPMODE_ALL then
                    BriefingSystem.skipPlayers[i] = nil;
                    if type(page) == "table" and page.skipping == false then
                        Logic.ExecuteInLuaLocalState("BriefingSystem.EnableBriefingSkipButton(" .. i .. ", false)");
                    else
                        Logic.ExecuteInLuaLocalState("BriefingSystem.EnableBriefingSkipButton(" .. i .. ", true)");
                    end
                end
            end
        end

        if not page or page == -1 then
            BriefingSystem.EndBriefing();
            return true;
        elseif type(page) == "number" and page > 0 then
            BriefingSystem.timer = 0;
            BriefingSystem.page  = page-1;
            return;
        end

        if page.mc then
            Logic.ExecuteInLuaLocalState('XGUIEng.ShowWidget("/InGame/ThroneRoom/Main/Skip", 0)');
            BriefingSystem.currBriefing[BriefingSystem.page].duration = 99999999;
        else
            local nextPage = BriefingSystem.currBriefing[BriefingSystem.page+1];
            if not BriefingSystem.disableSkipping then
                Logic.ExecuteInLuaLocalState('XGUIEng.ShowWidget("/InGame/ThroneRoom/Main/Skip", 1)');
            end
        end
        BriefingSystem.timer = page.duration or BriefingSystem.STANDARDTIME_PER_PAGE;

        if page.explore then
            page.exploreEntities = {};
            if type(page.explore) == "table" then
                if #page.explore > 0 or page.explore.default then
                    for pId = 1, 8 do
                        local playerExplore = page.explore[player] or page.explore.default;
                        if playerExplore then
                            if type(playerExplore) == "table" then
                                BriefingSystem.CreateExploreEntity(page, playerExplore.exploration, playerExplore.type or Entities[BriefingSystem.DEFAULT_EXPLORE_ENTITY], pId, playerExplore.position);
                            else
                                BriefingSystem.CreateExploreEntity(page, playerExplore, Entities[BriefingSystem.DEFAULT_EXPLORE_ENTITY], pId);
                            end
                        end
                    end
                else
                    BriefingSystem.CreateExploreEntity(page, page.explore.exploration, page.explore.type or Entities[BriefingSystem.DEFAULT_EXPLORE_ENTITY], 1, page.explore.position);
                end
            else
                BriefingSystem.CreateExploreEntity(page, page.explore, Entities[BriefingSystem.DEFAULT_EXPLORE_ENTITY], 1);
            end
        end
        if page.pointer then
            local pointer = page.pointer;
            page.pointerList = {};
            if type(pointer) == "table" then
                if #pointer > 0 then
                    for i = 1, #pointer do
                        BriefingSystem.CreatePointer(page, pointer[i]);
                    end
                else
                    BriefingSystem.CreatePointer(page, pointer);
                end
            else
                BriefingSystem.CreatePointer(page, { type = pointer, position = page.position or page.followEntity });
            end
        end
        if page.marker then
            BriefingSystem.maxMarkerListEntry = BriefingSystem.maxMarkerListEntry + 1;
            page.markerList = BriefingSystem.maxMarkerListEntry;
        end
        Logic.ExecuteInLuaLocalState("BriefingSystem.Briefing()");
        if page.action then
            if page.actionArg and #page.actionArg > 0 then
                page:action(unpack(page.actionArg));
            else
                page:action();
            end
        end
    end

    function BriefingSystem.SkipBriefing(_player)
        if not BriefingSystem.disableSkipping then
            if BriefingSystem.skipPerPage then
                BriefingSystem.SkipBriefingPage(_player);
                return;
            end
            BriefingSystem.skipPlayers[_player] = BriefingSystem.SKIPMODE_ALL;
            for i = 1, 8, 1 do
                if Logic.PlayerGetIsHumanFlag(i) and BriefingSystem.skipPlayers[i] ~= BriefingSystem.SKIPMODE_ALL then
                    Logic.ExecuteInLuaLocalState("BriefingSystem.EnableBriefingSkipButton(" .. _player .. ", false)");
                    return;
                end
            end
            EndJob(BriefingSystem.job);
            BriefingSystem.EndBriefing();
        end
    end

    function BriefingSystem.SkipBriefingPage(_player)
        if not BriefingSystem.disableSkipping then
            if not BriefingSystem.LastSkipTimeStemp or Logic.GetTimeMs() > BriefingSystem.LastSkipTimeStemp + 500 then
                BriefingSystem.LastSkipTimeStemp = Logic.GetTimeMs();
                if not BriefingSystem.skipPlayers[_player] then
                    BriefingSystem.skipPlayers[_player] = BriefingSystem.SKIPMODE_PERPAGE;
                end
                for i = 1, 8, 1 do
                    if Logic.PlayerGetIsHumanFlag(_player) and not BriefingSystem.skipPlayers[_player] then
                        if BriefingSystem.skipPerPage then
                            Logic.ExecuteInLuaLocalState("BriefingSystem.EnableBriefingSkipButton(" .. _player .. ", false)");
                        end
                        return;
                    end
                end
                if BriefingSystem.skipAll then
                    BriefingSystem.SkipBriefing(_player);
                elseif BriefingSystem_Action_Briefing() then
                    EndJob(BriefingSystem.job);
                end
            end
        end
    end

    function BriefingSystem.CreateExploreEntity(_page, _exploration, _entityType, _player, _position)
        local position = _position or _page.position;
        if position then
            if type(position) == "table" and (position[_player] or position.default or position.playerPositions) then
                position = position[_player] or position.default;
            end
            if position then
                local tPosition = type(position);
                if tPosition == "string" or tPosition == "number" then
                    position = GetPosition(position);
                end
            end
        end
        if not position then
            local followEntity = _page.followEntity;
            if type(followEntity) == "table" then
                followEntity = followEntity[_player] or followEntity.default;
            end
            if followEntity then
                position = GetPosition(followEntity);
            end
        end
        assert(position);
        local entity = Logic.CreateEntity(_entityType, position.X, position.Y, 0, _player);
        assert(entity ~= 0);
        Logic.SetEntityExplorationRange(entity, _exploration / 100);
        table.insert(_page.exploreEntities, entity);
    end

    function BriefingSystem.CreatePointer(_page, _pointer)
        local pointerType = _pointer.type or BriefingSystem.POINTER_VERTICAL;
        local position = _pointer.position;
        assert(position);
        if pointerType / BriefingSystem.POINTER_VERTICAL >= 1 then
            local entity = position;
            if type(position) == "table" then
                local _;
                _, entity = Logic.GetEntitiesInArea(0, position.X, position.Y, 50, 1);
            else
                position = GetPosition(position);
            end
            local effectType = EGL_Effects.E_Questmarker_low;
            if pointerType == BriefingSystem.POINTER_VERTICAL_HIGH then
                effectType = EGL_Effects.E_Questmarker;
            elseif pointerType ~= BriefingSystem.POINTER_VERTICAL_LOW then
                if entity ~= 0 then
                    if Logic.IsBuilding(entity) == 1 then
                        pointerType = EGL_Effects.E_Questmarker;
                    end
                end
            end
            table.insert(_page.pointerList, { id = Logic.CreateEffect(effectType, position.X, position.Y, _pointer.player or 0), type = pointerType });
        else
            assert(pointerType == BriefingSystem.POINTER_HORIZONTAL);
            if type(position) ~= "table" then
                position = GetPosition(position);
            end
            table.insert(_page.pointerList, { id = Logic.CreateEntityOnUnblockedLand(Entities.E_DirectionMarker, position.X, position.Y, _pointer.orientation or 0, _pointer.player or 0), type = pointerType });
        end
    end

    function BriefingSystem.DestroyPageMarker(_page, _index)
        if _page.marker then
            Logic.ExecuteInLuaLocalState("BriefingSystem.DestroyPageMarker(" .. _page.markerList .. ", " .. _index .. ")");
        end
    end

    function BriefingSystem.RedeployPageMarkers(_page, _position)
        if _page.marker then
            if type(_position) ~= "table" then
                _position = GetPosition(_position);
            end
            Logic.ExecuteInLuaLocalState("BriefingSystem.RedeployMarkerList(" .. _page.markerList .. ", " .. _position.X .. ", " .. _position.Y .. ")");
        end
    end

    function BriefingSystem.RedeployPageMarker(_page, _index, _position)
        if _page.marker then
            if type(_position) ~= "table" then
                _position = GetPosition(_position);
            end
            Logic.ExecuteInLuaLocalState("BriefingSystem.RedeployMarkerOfList(" .. _page.markerList .. ", " .. _index .. ", " .. _position.X .. ", " .. _position.Y .. ")");
        end
    end

    function BriefingSystem.RefreshPageMarkers(_page)
        if _page.marker then
            Logic.ExecuteInLuaLocalState("BriefingSystem.RefreshMarkerList(" .. _page.markerList .. ")");
        end
    end

    function BriefingSystem.RefreshPageMarker(_page, _index)
        if _page.marker then
            Logic.ExecuteInLuaLocalState("BriefingSystem.RefreshMarkerOfList(" .. _page.markerList .. ", " .. _index .. ")");
        end
    end

    function BriefingSystem.ResolveBriefingPage(_page)
        if _page.explore and _page.exploreEntities then
            for i, v in ipairs(_page.exploreEntities) do
                Logic.DestroyEntity(v);
            end
            _page.exploreEntities = nil;
        end
        if _page.pointer and _page.pointerList then
            for i, v in ipairs(_page.pointerList) do
                if v.type ~= BriefingSystem.POINTER_HORIZONTAL then
                    Logic.DestroyEffect(v.id);
                else
                    Logic.DestroyEntity(v.id);
                end
            end
            _page.pointerList = nil;
        end
        if _page.marker and _page.markerList then
            Logic.ExecuteInLuaLocalState("BriefingSystem.DestroyMarkerList(" .. _page.markerList .. ")");
            _page.markerList = nil;
        end
    end
    ResolveBriefingPage = BriefingSystem.ResolveBriefingPage;

    ---
    -- Wenn eine Antwort ausgewδhlt wurde, wird der entsprechende
    -- Sprung durchgefόhrt. Wenn remove = true ist, wird die Option
    -- fόr den Rest des Briefings deaktiviert (fόr Rόcksprόnge).
    --
    -- _aswID			Index der Antwort
    -- _currentPage		Aktuelle Seite
    -- _currentAnswer	Gegebene Antwort
    --
    function BriefingSystem.OnConfirmed(_aswID, _currentPage, _currentAnswer)
        BriefingSystem.timer = 0
        local page = BriefingSystem.currBriefing[BriefingSystem.page];
        local pageNumber = BriefingSystem.page;
        local current = _currentPage;
        local jump = page.mc.answers[current][2];
        BriefingSystem.currBriefing[pageNumber].mc.given = _aswID;
        if type(jump) == "function" then
            BriefingSystem.page = jump(page.mc.answers[_currentAnswer])-1;
        else
            BriefingSystem.page = jump-1;
        end
        if page.mc.answers[current] and page.mc.answers[current].remove then
            table.remove(BriefingSystem.currBriefing[pageNumber].mc.answers, _currentAnswer);
            if #BriefingSystem.currBriefing[pageNumber].mc.answers < _currentAnswer then
                BriefingSystem.currBriefing[pageNumber].mc.current = #BriefingSystem.currBriefing[pageNumber].mc.answers
            end
            Logic.ExecuteInLuaLocalState([[
                table.remove(BriefingSystem.currBriefing[]]..pageNumber..[[].mc.answers, ]].._currentAnswer..[[)
                if #BriefingSystem.currBriefing[]]..pageNumber..[[].mc.answers < ]].._currentAnswer..[[ then
                    BriefingSystem.currBriefing[]]..pageNumber..[[].mc.current = #BriefingSystem.currBriefing[]]..pageNumber..[[].mc.answers
                end
            ]]);
        end
        BriefingSystem.currBriefing = BriefingSystem.RemoveObsolateAnswers(BriefingSystem.currBriefing);
    end
end

-- Local Script ----------------------------------------------------------------

---
-- Initialisiert das Bundle im lokalen Skript.
-- @within Application-Space
-- @local
--
function BundleBriefingSystem.Local:Install()
    self:InitalizeSystem()
end


function BundleBriefingSystem.Local:InitalizeSystem()
    if not InitializeFader then
        Script.Load("Script\\MainMenu\\Fader.lua");
    end

    BriefingSystem = {
        listOfMarkers = {},
        markerUniqueID = 2 ^ 10,
        Flight = {systemEnabled = true},
        InformationTextQueue = {},
    };

    function BriefingSystem.InitializeBriefingSystem()
        BriefingSystem.GlobalSystem = Logic.CreateReferenceToTableInGlobaLuaState("BriefingSystem");
        assert(BriefingSystem.GlobalSystem);
        if not BriefingSystem.GlobalSystem.loadScreenHidden then
            BriefingSystem.StartLoadScreenSupervising();
        end
        -- Escape deactivated to avoid errors with mc briefings
        BriefingSystem.GameCallback_Escape = GameCallback_Escape;
        GameCallback_Escape = function()
            if not BriefingSystem.IsBriefingActive() then
                BriefingSystem.GameCallback_Escape();
            end
        end
        BriefingSystem.Flight.Job = Trigger.RequestTrigger(Events.LOGIC_EVENT_EVERY_TURN, nil, "ThroneRoomCameraControl", 0);
    end

    function BriefingSystem.StartLoadScreenSupervising()
        if not BriefingSystem_LoadScreenSupervising() then
            Trigger.RequestTrigger(Events.LOGIC_EVENT_EVERY_TURN, nil, "BriefingSystem_LoadScreenSupervising", 1);
        end
    end

    function BriefingSystem_LoadScreenSupervising()
        if  XGUIEng.IsWidgetShownEx("/LoadScreen/LoadScreen") == 0 then
            GUI.SendScriptCommand("BriefingSystem.loadScreenHidden = true;");
            return true;
        end
    end

    function BriefingSystem.PrepareBriefing()
        BriefingSystem.barType = nil;
        BriefingSystem.InformationTextQueue = {};
        BriefingSystem.currBriefing = BriefingSystem.GlobalSystem[BriefingSystem.GlobalSystem.currBriefingIndex];
        Trigger.EnableTrigger(BriefingSystem.Flight.Job);

        local isLoadScreenVisible = XGUIEng.IsWidgetShownEx("/LoadScreen/LoadScreen") == 1;
        if isLoadScreenVisible then
            XGUIEng.PopPage();
        end
        XGUIEng.ShowWidget("/InGame/Root/3dOnScreenDisplay", 0);
        XGUIEng.ShowWidget("/InGame/Root/Normal", 0);
        XGUIEng.ShowWidget("/InGame/ThroneRoom", 1);
        XGUIEng.ShowWidget("/InGame/ThroneRoom/Main/Skip", BriefingSystem.GlobalSystem.disableSkipping and 0 or 1);
        BriefingSystem.EnableBriefingSkipButton(nil, true);
        XGUIEng.PushPage("/InGame/ThroneRoomBars", false);
        XGUIEng.PushPage("/InGame/ThroneRoomBars_2", false);
        XGUIEng.PushPage("/InGame/ThroneRoom/Main", false);
        XGUIEng.PushPage("/InGame/ThroneRoomBars_Dodge", false);
        XGUIEng.PushPage("/InGame/ThroneRoomBars_2_Dodge", false);
        XGUIEng.ShowWidget("/InGame/ThroneRoom/Main/DialogTopChooseKnight", 1);
        XGUIEng.ShowWidget("/InGame/ThroneRoom/Main/DialogTopChooseKnight/Frame", 0);
        XGUIEng.ShowWidget("/InGame/ThroneRoom/Main/DialogTopChooseKnight/DialogBG", 0);
        XGUIEng.ShowWidget("/InGame/ThroneRoom/Main/DialogTopChooseKnight/FrameEdges", 0);
        XGUIEng.ShowWidget("/InGame/ThroneRoom/Main/DialogBottomRight3pcs", 0);
        XGUIEng.ShowWidget("/InGame/ThroneRoom/Main/KnightInfoButton", 0);
        XGUIEng.ShowWidget("/InGame/ThroneRoom/Main/Briefing", 0);
        XGUIEng.ShowWidget("/InGame/ThroneRoom/Main/BackButton", 0);
        XGUIEng.ShowWidget("/InGame/ThroneRoom/Main/TitleContainer", 0);
        XGUIEng.ShowWidget("/InGame/ThroneRoom/Main/StartButton", 0);
        XGUIEng.SetText("/InGame/ThroneRoom/Main/MissionBriefing/Text", " ");
        XGUIEng.SetText("/InGame/ThroneRoom/Main/MissionBriefing/Title", " ");
        XGUIEng.SetText("/InGame/ThroneRoom/Main/MissionBriefing/Objectives", " ");

        -- page.information Text
        local screen = {GUI.GetScreenSize()};
        local yAlign = 350 * (screen[2]/1080);
        XGUIEng.ShowWidget("/InGame/ThroneRoom/KnightInfo", 1);
        XGUIEng.ShowAllSubWidgets("/InGame/ThroneRoom/KnightInfo", 0);
        XGUIEng.ShowWidget("/InGame/ThroneRoom/KnightInfo/Text", 1);
        XGUIEng.PushPage("/InGame/ThroneRoom/KnightInfo", false);
        XGUIEng.SetText("/InGame/ThroneRoom/KnightInfo/Text", "Horst Hackebeil");
        XGUIEng.SetTextColor("/InGame/ThroneRoom/KnightInfo/Text", 255, 255, 255, 255);
        XGUIEng.SetWidgetScreenPosition("/InGame/ThroneRoom/KnightInfo/Text", 100, yAlign);

        local page = BriefingSystem.currBriefing[1];
        BriefingSystem.SetBriefingPageWidgetAppearance(page);
        BriefingSystem.SetBriefingPageTextPosition(page);

        if not Framework.IsNetworkGame() and Game.GameTimeGetFactor() ~= 0 then
            Game.GameTimeSetFactor(GUI.GetPlayerID(), 1);
        end
        if BriefingSystem.currBriefing.restoreCamera then
            BriefingSystem.cameraRestore = { Camera.RTS_GetLookAtPosition() };
        end
        BriefingSystem.selectedEntities = { GUI.GetSelectedEntities() };
        GUI.ClearSelection();
        GUI.ForbidContextSensitiveCommandsInSelectionState();
        GUI.ActivateCutSceneState();
        GUI.SetFeedbackSoundOutputState(0);
        GUI.EnableBattleSignals(false);
        Mouse.CursorHide();
        Camera.SwitchCameraBehaviour(5);
        Input.CutsceneMode();
        InitializeFader();
        g_Fade.To = 0;
        SetFaderAlpha(0);

        if isLoadScreenVisible then
            XGUIEng.PushPage("/LoadScreen/LoadScreen", false);
        end
        if BriefingSystem.currBriefing.hideFoW then
            Display.SetRenderFogOfWar(0);
            GUI.MiniMap_SetRenderFogOfWar(0);
        end
    end

    function BriefingSystem.EndBriefing()
        if BriefingSystem.faderJob then
            Trigger.UnrequestTrigger(BriefingSystem.faderJob);
            BriefingSystem.faderJob = nil;
        end
        if BriefingSystem.currBriefing.hideFoW then
            Display.SetRenderFogOfWar(1);
            GUI.MiniMap_SetRenderFogOfWar(1);
        end

        g_Fade.To = 0;
        SetFaderAlpha(0);
        XGUIEng.PopPage();
        Display.UseStandardSettings();
        Input.GameMode();
        local x, y = Camera.ThroneRoom_GetPosition();
        Camera.SwitchCameraBehaviour(0);
        Camera.RTS_SetLookAtPosition(x, y);
        Mouse.CursorShow();
        GUI.EnableBattleSignals(true);
        GUI.SetFeedbackSoundOutputState(1);
        GUI.ActivateSelectionState();
        GUI.PermitContextSensitiveCommandsInSelectionState();
        for _, v in ipairs(BriefingSystem.selectedEntities) do
            if not Logic.IsEntityDestroyed(v) then
                GUI.SelectEntity(v);
            end
        end
        if BriefingSystem.currBriefing.restoreCamera then
            Camera.RTS_SetLookAtPosition(unpack(BriefingSystem.cameraRestore));
        end
        if not Framework.IsNetworkGame() then
            Game.GameTimeSetFactor(GUI.GetPlayerID(), 1);
        end

        XGUIEng.PopPage();
        XGUIEng.PopPage();
        XGUIEng.PopPage();
        XGUIEng.PopPage();
        XGUIEng.PopPage();
        XGUIEng.ShowWidget("/InGame/ThroneRoom", 0);
        XGUIEng.ShowWidget("/InGame/ThroneRoomBars", 0);
        XGUIEng.ShowWidget("/InGame/ThroneRoomBars_2", 0);
        XGUIEng.ShowWidget("/InGame/ThroneRoomBars_Dodge", 0);
        XGUIEng.ShowWidget("/InGame/ThroneRoomBars_2_Dodge", 0);
        XGUIEng.ShowWidget("/InGame/Root/Normal", 1);
        XGUIEng.ShowWidget("/InGame/Root/3dOnScreenDisplay", 1);
        Trigger.DisableTrigger(BriefingSystem.Flight.Job);

        BriefingSystem.ConvertInformationToNote();
    end

    function BriefingSystem.Briefing(_prepareBriefingStart)
        if not _prepareBriefingStart then
            if BriefingSystem.faderJob then
                Trigger.UnrequestTrigger(BriefingSystem.faderJob);
                BriefingSystem.faderJob = nil;
            end
        end
        local page = BriefingSystem.currBriefing[_prepareBriefingStart and 1 or BriefingSystem.GlobalSystem.page];
        if not page then
            return;
        end
        local barStyle = page.barStyle;
        if barStyle == nil then
            barStyle = BriefingSystem.currBriefing.barStyle;
        end

        -- local paintItBlack = page.blackPage ~= nil and not page.mc;
        BriefingSystem.SetBriefingPageWidgetAppearance(page, barStyle);
        BriefingSystem.SetBriefingPageTextPosition(page);

        local player = GUI.GetPlayerID();
        if page.text then
            local doNotCalc = page.duration ~= nil;
            local smallBarShown = ((barStyle == "small" or barStyle == "transsmall") and not page.splashscreen);
            if type(page.text) == "string" then
                BriefingSystem.ShowBriefingText(page.text, doNotCalc, smallBarShown);
            elseif page.text[player] or page.text.default then
                for i = 1, player do
                    if page.text[i] and Logic.GetIsHumanFlag(i) then
                        doNotCalc = true;
                    end
                end
                BriefingSystem.ShowBriefingText(page.text[player] or page.text.default, doNotCalc, smallBarShown);
            end
        end
        if page.title then
            if type(page.title) == "string" then
                BriefingSystem.ShowBriefingTitle(page.title);
            elseif page.title[player] or page.title.default then
                BriefingSystem.ShowBriefingTitle(page.title[player] or page.title.default);
            end
        end
        if page.mc then
            BriefingSystem.Briefing_MultipleChoice();
        end

        if not _prepareBriefingStart then
            if page.faderAlpha then
                if type(page.faderAlpha) == "table" then
                    g_Fade.To = page.faderAlpha[player] or page.faderAlpha.default or 0;
                else
                    g_Fade.To = page.faderAlpha;
                end
                g_Fade.Duration = 0;
            end
            if page.fadeIn then
                local fadeIn = page.fadeIn;
                if type(fadeIn) == "table" then
                    fadeIn = fadeIn[player] or fadeIn.default;
                end
                if type(fadeIn) ~= "number" then
                    fadeIn = page.duration;
                    if not fadeIn then
                        fadeIn = BriefingSystem.timer;
                    end
                end
                if fadeIn < 0 then
                    BriefingSystem.faderJob = Trigger.RequestTrigger(Events.LOGIC_EVENT_EVERY_TURN, nil, "BriefingSystem_CheckFader", 1, {}, { 1, math.abs(fadeOut) });
                else
                    FadeIn(fadeIn);
                end
            end
            if page.fadeOut then
                local fadeOut = page.fadeOut;
                if type(fadeOut) == "table" then
                    fadeOut = fadeOut[player] or fadeOut.default;
                end
                if type(fadeOut) ~= "number" then
                    fadeOut = page.duration;
                    if not fadeOut then
                        fadeOut = BriefingSystem.timer;
                    end
                end
                if fadeOut < 0 then
                    BriefingSystem.faderJob = Trigger.RequestTrigger(Events.LOGIC_EVENT_EVERY_TURN, nil, "BriefingSystem_CheckFader", 1, {}, { 0, math.abs(fadeOut) });
                else
                    FadeOut(fadeOut);
                end
            end
        else
            local faderValue = (page.fadeOut and 0) or (page.fadeIn and 1) or page.faderValue;
            if faderValue then
                g_Fade.To = faderValue;
                g_Fade.Duration = 0;
            end

        end
        local dialogCamera = page.dialogCamera;
        if type(dialogCamera) == "table" then
            dialogCamera = dialogCamera[player];
            if dialogCamera == nil then
                dialogCamera = page.dialogCamera.default;
            end
        end
        dialogCamera = dialogCamera and "DLG" or "";

        local rotation = page.rotation or BriefingSystem.GlobalSystem["BRIEFING_" .. dialogCamera .. "CAMERA_ROTATIONDEFAULT"];
        if type(rotation) == "table" then
            rotation = rotation[player] or rotation.default;
        end
        local angle = page.angle or BriefingSystem.GlobalSystem["BRIEFING_" .. dialogCamera .. "CAMERA_ANGLEDEFAULT"];
        if type(angle) == "table" then
            angle = angle[player] or angle.default;
        end
        local zoom = page.zoom or BriefingSystem.GlobalSystem["BRIEFING_" .. dialogCamera .. "CAMERA_ZOOMDEFAULT"];
        if type(zoom) == "table" then
            zoom = zoom[player] or zoom.default;
        end
        local FOV = page.FOV or BriefingSystem.GlobalSystem["BRIEFING_" .. dialogCamera .. "CAMERA_FOVDEFAULT"];
        BriefingSystem.CutsceneStopFlight();
        BriefingSystem.StopFlight();

        ----------------------------------------------------------------
        -- Cutscenes by totalwarANGEL                                 --
        ----------------------------------------------------------------
        -- Initialisierung der Kameraanimation

        if page.view then
            -- Flight speichern
            if BriefingSystem.GlobalSystem.page == 1 then -- or (page.view.FlyTime == nil or page.view.FlyTime == 0) then
                BriefingSystem.CutsceneSaveFlight(page.view.Position, page.view.LookAt, FOV);
            end

            -- Kamera bewegen
            BriefingSystem.CutsceneFlyTo(page.view.Position,
                                         page.view.LookAt,
                                         FOV,
                                         page.flyTime or 0);

        ----------------------------------------------------------------

        elseif page.position then
            local position = page.position;
            if type(position) == "table" and (position[player] or position.default or position.playerPositions) then
                position = position[player] or position.default;
            end
            if position then
                local ttype = type(position);
                if ttype == "string" or ttype == "number" then
                    position = GetPosition(position);
                elseif ttype == "table" then
                    position = { X = position.X, Y = position.Y, Z = position.Z};
                end

                -- Z-Achsen-Fix
                local height = position.Z or Display.GetTerrainHeight(position.X,position.Y);
                if page.zOffset then
                    height = height + page.zOffset;
                end
                position.Z = height;

                Display.SetCameraLookAtEntity(0);

                if BriefingSystem.GlobalSystem.page == 1 then
                    BriefingSystem.SaveFlight(position, rotation, angle, zoom, FOV);
                end
                BriefingSystem.FlyTo(position, rotation, angle, zoom, FOV, page.flyTime or BriefingSystem.GlobalSystem.BRIEFING_FLYTIME);
            end

        elseif page.followEntity then
            local followEntity = page.followEntity;
            if type(followEntity) == "table" then
                followEntity = followEntity[player] or followEntity.default;
            end
            followEntity = GetEntityId(followEntity);
            Display.SetCameraLookAtEntity(followEntity);

            local pos = GetPosition(followEntity);
            pos.Z = pos.Z or nil;
            local height = Display.GetTerrainHeight(pos.X,pos.Y);
            if page.zOffset then
                height = height + page.zOffset;
            end
            pos.Z = height;

            if BriefingSystem.GlobalSystem.page == 1 then
                BriefingSystem.SaveFlight(pos, rotation, angle, zoom, FOV);
            end
            BriefingSystem.FollowFlight(followEntity, rotation, angle, zoom, FOV, page.flyTime or 0, height);
        end

        if not _prepareBriefingStart then
            if page.marker then
                local marker = page.marker;
                if type(marker) == "table" then
                    if #marker > 0 then
                        for _, v in ipairs(marker) do
                            if not v.player or v.player == GUI.GetPlayerID() then
                                BriefingSystem.CreateMarker(v, v.type, page.markerList, v.display, v.R, v.G, v.B, v.Alpha);
                            else
                                table.insert(BriefingSystem.listOfMarkers[page.markerList], {});
                            end
                        end
                    else
                        if not v.player or v.player == GUI.GetPlayerID() then
                            BriefingSystem.CreateMarker(marker, marker.type, page.markerList, marker.display, marker.R, marker.G, marker.B, marker.Alpha);
                        else
                            table.insert(BriefingSystem.listOfMarkers[page.markerList], {});
                        end
                    end
                else
                    BriefingSystem.CreateMarker(page, marker, page.markerList);
                end
            end
        end
    end

    function OnSkipButtonPressed()
        local index = BriefingSystem.GlobalSystem.page;
        if BriefingSystem.currBriefing[index] and not BriefingSystem.currBriefing[index].mc then
            GUI.SendScriptCommand("BriefingSystem.SkipBriefing(" .. GUI.GetPlayerID() .. ")");
        end
    end

    function BriefingSystem.SkipBriefingPage()
        local index = BriefingSystem.GlobalSystem.page;
        if BriefingSystem.currBriefing[index] and not BriefingSystem.currBriefing[index].mc then
            GUI.SendScriptCommand("BriefingSystem.SkipBriefingPage(" .. GUI.GetPlayerID() .. ")");
        end
    end

    ---
    -- Zeigt die Rahmen an. Dabei gibt es schmale Rahmen, breite Rahmen
    -- und jeweils noch transparente Versionen. Es kann auch gar kein
    -- Rahmen angezeigt werden.
    --
    -- _type	Typ der Bar
    --
    function BriefingSystem.ShowBriefingBar(_type)
        _type = _type or "big";
        -- set overwrite
        if _type == nil then
            _type = BriefingSystem.currBriefing.barStyle;
        end
        assert(_type == 'big' or _type == 'small' or _type == 'nobar' or _type == 'transbig' or _type == 'transsmall');
        -- set bars
        local flag_big = (_type == "big" or _type == "transbig") and 1 or 0;
        local flag_small = (_type == "small" or _type == "transsmall") and 1 or 0;
        local alpha = (_type == "transsmall" or _type == "transbig") and 100 or 255;
        if _type == 'nobar' then
            flag_small = 0;
            flag_big = 0;
        end

        XGUIEng.ShowWidget("/InGame/ThroneRoomBars", flag_big);
        XGUIEng.ShowWidget("/InGame/ThroneRoomBars_2", flag_small);
        XGUIEng.ShowWidget("/InGame/ThroneRoomBars_Dodge", flag_big);
        XGUIEng.ShowWidget("/InGame/ThroneRoomBars_2_Dodge", flag_small);

        XGUIEng.SetMaterialAlpha("/InGame/ThroneRoomBars/BarBottom", 1, alpha);
        XGUIEng.SetMaterialAlpha("/InGame/ThroneRoomBars/BarTop", 1, alpha);
        XGUIEng.SetMaterialAlpha("/InGame/ThroneRoomBars_2/BarBottom", 1, alpha);
        XGUIEng.SetMaterialAlpha("/InGame/ThroneRoomBars_2/BarTop", 1, alpha);

        BriefingSystem.barType = _type;
    end

    ---
    --
    --
    function BriefingSystem.ShowBriefingText(_text, _doNotCalc, _smallBar)
        local text = XGUIEng.GetStringTableText(_text);
        if text == "" then
            text = _text;
        end
        if not _doNotCalc then
            GUI.SendScriptCommand("BriefingSystem.timer = " .. (BriefingSystem.GlobalSystem.STANDARDTIME_PER_PAGE + BriefingSystem.GlobalSystem.SECONDS_PER_CHAR * string.len(text)) .. ";");
        end
        if _smallBar then
            text = "{cr}{cr}{cr}" .. text;
        end
        XGUIEng.ShowWidget("/InGame/ThroneRoom/Main/MissionBriefing/Text", 1);
        XGUIEng.SetText("/InGame/ThroneRoom/Main/MissionBriefing/Text", "{center}"..text);
    end

    ---
    --
    --
    function BriefingSystem.ShowBriefingTitle(_title)
        local title = XGUIEng.GetStringTableText(_title);
        if title == "" then
            title = _title;
        end
        if BriefingSystem.GlobalSystem and string.sub(title, 1, 1) ~= "{" then
            title = BriefingSystem.GlobalSystem.COLOR1 .. "{center}{darkshadow}" .. title;
        end
        XGUIEng.ShowWidget("/InGame/ThroneRoom/Main/DialogTopChooseKnight/ChooseYourKnight", 1);
        XGUIEng.SetText("/InGame/ThroneRoom/Main/DialogTopChooseKnight/ChooseYourKnight", title);
    end

    ---
    --
    --
    function BriefingSystem.SchowBriefingAnswers(_page)
        local Screen = {GUI.GetScreenSize()};
        local Widget = "/InGame/SoundOptionsMain/RightContainer/SoundProviderComboBoxContainer";
        BriefingSystem.OriginalBoxPosition = {
            XGUIEng.GetWidgetScreenPosition(Widget)
        };

        local listbox = XGUIEng.GetWidgetID(Widget .. "/ListBox");
        XGUIEng.ListBoxPopAll(listbox);
        for i=1, _page.mc.amount, 1 do
            if _page.mc.answers[i] then
                XGUIEng.ListBoxPushItem(listbox, _page.mc.answers[i][1]);
            end
        end
        XGUIEng.ListBoxSetSelectedIndex(listbox, 0);

        local wSize = {XGUIEng.GetWidgetScreenSize(Widget)};
        local xFactor = (Screen[1]/1920);
        local xFix = math.ceil((Screen[1]/2) - (wSize[1] /2));
        local yFix = math.ceil(Screen[2] - (wSize[2]-20));
        XGUIEng.SetWidgetScreenPosition(Widget, xFix, yFix);
        XGUIEng.PushPage(Widget, false);
        XGUIEng.ShowWidget(Widget, 1);

        BriefingSystem.MCSelectionIsShown = true;
    end

    ---
    -- Zeigt alle Nachrichten in der Warteschlange an und schreibt
    -- sie in das KnightInfo Widget.
    --
    function BriefingSystem.ShowInformationText()
        XGUIEng.SetText("/InGame/ThroneRoom/KnightInfo/Text", "");
        local text = "";
        for i=1, #BriefingSystem.InformationTextQueue do
            text = text .. BriefingSystem.InformationTextQueue[i][1] .. "{cr}";
        end
        XGUIEng.SetText("/InGame/ThroneRoom/KnightInfo/Text", text);
    end

    ---
    -- Konvertiert die Notizen zu einer Debug Note und zeigt sie im
    -- Debug Window an. Dies passiert dann, wenn ein Briefing endet
    -- aber die Anzeigezeit einer oder mehrerer Nachrichten noch nicht
    -- abgelaufen ist.
    --
    function BriefingSystem.ConvertInformationToNote()
        for i=1, #BriefingSystem.InformationTextQueue do
            GUI.AddNote(BriefingSystem.InformationTextQueue[i][1]);
        end
    end

    ---
    -- Fόgt einen text in die Warteschlange ein.
    --
    -- _text	Nachricht
    --
    function BriefingSystem.PushInformationText(_text)
        local length = string.len(_text) * 5;
        length = (length < 800 and 800) or length;
        table.insert(BriefingSystem.InformationTextQueue, {_text, length});
    end

    ---
    -- Entfernt einen Text aus der Warteschlange.
    --
    function BriefingSystem.PopInformationText()
        table.remove(BriefingSystem.InformationTextQueue, 1);
    end

    ---
    -- Kontrolliert die ANzeige der Notizen wδhrend eines Briefings.
    -- Die Nachrichten werden solange angezeigt, wie ihre Anzeigezeit
    -- noch nicht abgelaufen ist.
    --
    function BriefingSystem.ControlInformationText()
        for i=1, #BriefingSystem.InformationTextQueue do
            BriefingSystem.InformationTextQueue[i][2] = BriefingSystem.InformationTextQueue[i][2] -1;
            if BriefingSystem.InformationTextQueue[i][2] <= 0 then
                BriefingSystem.PopInformationText();
                break;
            end
        end
        BriefingSystem.ShowInformationText();
    end

    ---
    -- Setzt den Text, den Titel und die Antworten einer Multiple Choice
    -- Seite. Setzt auίerdem die Dauer der Seite auf 11 1/2 Tage (in
    -- der echten Welt). Leider ist es ohne grφίeren Δnderungen nicht
    -- mφglich die Anzeigezeit einer Seite auf unendlich zu setzen.
    -- Es ist aber allgemein unwahrscheinlich, dass der Spieler 11,5
    -- Tage vor dem Briefing sitzt, ohne etwas zu tun.
    -- Das Fehlverhalten in diesem Fall ist unerforscht. Es wόrde dann
    -- wahrscheinlich die 1 Antwort selektiert.
    --
    function BriefingSystem.Briefing_MultipleChoice()
        local page = BriefingSystem.currBriefing[BriefingSystem.GlobalSystem.page];

        if page and page.mc then
            -- set title
            if page.mc.title then
                BriefingSystem.ShowBriefingTitle(page.mc.title);
            end
            -- set text
            if page.mc.text then
                BriefingSystem.ShowBriefingText(page.mc.text, true);
            end
            -- set answers
            if page.mc.answers then
                BriefingSystem.SchowBriefingAnswers(page);
            end
            -- set page length
            GUI.SendScriptCommand("BriefingSystem.currBriefing[BriefingSystem.page].dusation = 999999");
        end
    end

    ---
    -- Eine Antwort wurde ausgewδhlt (lokales Skript). Die Auswahl wird
    -- gepopt und ein Event an das globale Skript gesendet. Das Event
    -- erhδlt die Page ID, den Index der selektierten Antwort in der
    -- Listbox und die reale ID der Antwort in der Table.
    --
    function BriefingSystem.OnConfirmed()
        local Widget = "/InGame/SoundOptionsMain/RightContainer/SoundProviderComboBoxContainer";
        local Position = BriefingSystem.OriginalBoxPosition;
        XGUIEng.SetWidgetScreenPosition(Widget, Position[1], Position[2]);
        XGUIEng.ShowWidget(Widget, 0);
        XGUIEng.PopPage();

        local page = BriefingSystem.currBriefing[BriefingSystem.GlobalSystem.page];
        if page.mc then
            local index  = BriefingSystem.GlobalSystem.page;
            local listboxidx = XGUIEng.ListBoxGetSelectedIndex(Widget .. "/ListBox")+1;
            BriefingSystem.currBriefing[index].mc.current = listboxidx;
            local answer = BriefingSystem.currBriefing[index].mc.current;
            local pageID = BriefingSystem.currBriefing[index].mc.answers[answer].ID;

            GUI.SendScriptCommand([[BriefingSystem.OnConfirmed(]]..pageID..[[,]]..page.mc.current..[[,]]..answer..[[)]]);
        end
    end

    function BriefingSystem.CreateMarker(_t, _markerType, _markerList, _r, _g, _b, _alpha)
        local position = _t.position;
        if position then
            if type(position) == "table" then
                if position[GUI.GetPlayerID()] or position.default or position.playerPositions then
                    position = position[GUI.GetPlayerID()] or position.default;
                end
            end
        end
        if not position then
            position = _t.followEntity;
            if type(position) == "table" then
                position = position[GUI.GetPlayerID()] or position.default;
            end
        end
        assert(position);
        if type(position) ~= "table" then
            position = GetPosition(position);
        end

        if _markerList and not BriefingSystem.listOfMarkers[_markerList] then
            BriefingSystem.listOfMarkers[_markerList] = {};
        end

        while GUI.IsMinimapSignalExisting(BriefingSystem.markerUniqueID) == 1 do
            BriefingSystem.markerUniqueID = BriefingSystem.markerUniqueID + 1;
        end
        assert(type(_markerType) == "number" and _markerType > 0);
        _r = _r or 32;
        _g = _g or 245;
        _b = _b or 110;
        _alpha = _alpha or 255;
        GUI.CreateMinimapSignalRGBA(BriefingSystem.markerUniqueID, position.X, position.Y, _r, _g, _b, _alpha, _markerType);
        if _markerList then
            table.insert(BriefingSystem.listOfMarkers[_markerList], { ID = BriefingSystem.markerUniqueID, X = position.X, Y = position.Y, R = _r, G = _g, B = _b, Alpha = _alpha, type = _markerType });
        end
        BriefingSystem.markerUniqueID = BriefingSystem.markerUniqueID + 1;
    end

    function BriefingSystem.DestroyMarkerList(_index)
        if BriefingSystem.listOfMarkers[_index] then
            for _, v in ipairs(BriefingSystem.listOfMarkers[_index]) do
                if v.ID and GUI.IsMinimapSignalExisting(v.ID) == 1 then
                    GUI.DestroyMinimapSignal(v.ID);
                end
            end
            BriefingSystem.listOfMarkers[_index] = nil;
        end
    end

    function BriefingSystem.DestroyMarkerOfList(_index, _marker)
        if BriefingSystem.listOfMarkers[_index] then
            local marker = BriefingSystem.listOfMarkers[_index][_marker];
            if marker and marker.ID and GUI.IsMinimapSignalExisting(marker.ID) == 1 then
                GUI.DestroyMinimapSignal(marker.ID);
                marker.ID = nil;
            end
        end
    end

    function BriefingSystem.RedeployMarkerList(_index, _x, _y)
        if BriefingSystem.listOfMarkers[_index] then
            for _, v in ipairs(BriefingSystem.listOfMarkers[_index]) do
                if v.ID then
                    v.X = _x;
                    v.Y = _y;
                    if GUI.IsMinimapSignalExisting(v.ID) == 1 then
                        GUI.RedeployMinimapSignal(v.ID, _x, _y);
                    else
                        GUI.CreateMinimapSignalRGBA(v.ID, _x, _y, v.R, v.G, v.B, v.Alpha, v.type);
                    end
                end
            end
        end
    end

    function BriefingSystem.RedeployMarkerOfList(_index, _marker, _x, _y)
        if BriefingSystem.listOfMarkers[_index] then
            local marker = BriefingSystem.listOfMarkers[_index][_marker];
            if marker and marker.ID then
                marker.X = _x;
                marker.Y = _y;
                if GUI.IsMinimapSignalExisting(marker.ID) == 1 then
                    GUI.RedeployMinimapSignal(marker.ID, _x, _y);
                else
                    GUI.CreateMinimapSignalRGBA(marker.ID, _x, _y, marker.R, marker.G, marker.B, marker.Alpha, marker.type);
                end
            end
        end
    end

    function BriefingSystem.RefreshMarkerList(_index)
        if BriefingSystem.listOfMarkers[_index] then
            for _, v in ipairs(BriefingSystem.listOfMarkers[_index]) do
                if v.ID then
                    if GUI.IsMinimapSignalExisting(v.ID) == 1 then
                        GUI.RedeployMinimapSignal(v.ID, v.X, v.Y);
                    else
                        GUI.CreateMinimapSignalRGBA(v.ID, v.X, v.Y, v.R, v.G, v.B, v.Alpha, v.type);
                    end
                end
            end
        end
    end

    function BriefingSystem.RefreshMarkerOfList(_index, _marker)
        if BriefingSystem.listOfMarkers[_index] then
            local marker = BriefingSystem.listOfMarkers[_index][_marker];
            if marker and marker.ID then
                if GUI.IsMinimapSignalExisting(marker.ID) == 1 then
                    GUI.RedeployMinimapSignal(marker.ID, marker.X, marker.Y);
                else
                    GUI.CreateMinimapSignalRGBA(marker.ID, marker.X, marker.Y, marker.R, marker.G, marker.B, marker.Alpha, marker.type);
                end
            end
        end
    end

    function BriefingSystem.EnableBriefingSkipButton(_player, _flag)
        if _player == nil or _player == GUI.GetPlayerID() then
            XGUIEng.DisableButton("/InGame/ThroneRoom/Main/Skip", _flag and 0 or 1);
        end
    end

    function BriefingSystem_CheckFader(_fadeIn, _timerValue)
        if BriefingSystem.GlobalSystem.timer < _timerValue then
            if _fadeIn == 1 then
                FadeIn(_timerValue);
            else
                FadeOut(_timerValue);
            end
            BriefingSystem.faderJob = nil;
            return true;
        end
    end

    function ThroneRoomCameraControl()
        if Camera.GetCameraBehaviour(5) == 5 then
            local flight = BriefingSystem.Flight;

            -- ---------------------------------------------------------
            -- Briefing Notation von OldMacDonald
            -- ---------------------------------------------------------

            -- Dies steuert die altbekannte Notation, entwickelt von OMD.
            -- Bis auf wenige Erweiterungen von totalwarANGEL ist es wie
            -- zum ursόrunglichen Release der letzten Version.

            if flight.systemEnabled then
                local startTime = flight.StartTime;
                local flyTime = flight.FlyTime;
                local startPosition = flight.StartPosition or flight.EndPosition;
                local endPosition = flight.EndPosition;
                local startRotation = flight.StartRotation or flight.EndRotation;
                local endRotation = flight.EndRotation;
                local startZoomAngle = flight.StartZoomAngle or flight.EndZoomAngle;
                local endZoomAngle = flight.EndZoomAngle;
                local startZoomDistance = flight.StartZoomDistance or flight.EndZoomDistance;
                local endZoomDistance = flight.EndZoomDistance;
                local startFOV = flight.StartFOV or flight.EndFOV;
                local endFOV = flight.EndFOV;
                local currTime = Logic.GetTimeMs() / 1000;
                local math = math;
                if flight.Follow then
                    local currentPosition = GetPosition(flight.Follow);
                    if endPosition.X ~= currentPosition.X and endPosition.Y ~= currentPosition.Y then
                        flight.StartPosition = endPosition;
                        flight.EndPosition = currentPosition;
                    end
                    if flight.StartPosition and Logic.IsEntityMoving(GetEntityId(flight.Follow)) then

                        local orientation = math.rad(Logic.GetEntityOrientation(GetEntityId(flight.Follow)));
                        local x1, y1, x2, y2 = flight.StartPosition.X, flight.StartPosition.Y, currentPosition.X, currentPosition.Y;
                        x1 = x1 - x2;
                        y1 = y1 - y2;
                        local distance = math.sqrt( x1 * x1 + y1 * y1 ) * 10;
                        local disttoend = distance * (flyTime - currTime + startTime);
                        local disttostart = distance * (currTime + startTime);
                        endPosition = { X = currentPosition.X + math.cos(orientation) * distance, Y = currentPosition.Y + math.sin(orientation) * distance }

                        flight.FollowTemp = flight.FollowTemp or {};
                        local factor = BriefingSystem.InterpolationFactor(currTime, currTime, 1, flight.FollowTemp);
                        x1, y1, z1 = BriefingSystem.GetCameraPosition(currentPosition, endPosition, factor);
                        startPosition = { X = x1, Y = y1, Z = z1 };
                    else
                        startPosition = currentPosition;
                    end
                    endPosition = startPosition;
                end


                local factor = BriefingSystem.InterpolationFactor(startTime, currTime, flyTime, flight);
                local lookAtX, lookAtY, lookAtZ = BriefingSystem.GetCameraPosition(startPosition, endPosition, factor);
                Camera.ThroneRoom_SetLookAt(lookAtX, lookAtY, lookAtZ);
                local zoomDistance = startZoomDistance + (endZoomDistance - startZoomDistance) * factor;
                local zoomAngle = startZoomAngle + (endZoomAngle - startZoomAngle) * factor;
                local rotation = startRotation + (endRotation - startRotation) * factor;
                local line = zoomDistance * math.cos(math.rad(zoomAngle));
                Camera.ThroneRoom_SetPosition(
                    lookAtX + math.cos(math.rad(rotation - 90)) * line,
                    lookAtY + math.sin(math.rad(rotation - 90)) * line,
                    lookAtZ + (zoomDistance) * math.sin(math.rad(zoomAngle))
                );
                Camera.ThroneRoom_SetFOV(startFOV + (endFOV - startFOV) * factor);

            -- ---------------------------------------------------------
            -- Cutscene notation by totalwarANGEL
            -- ---------------------------------------------------------

            -- Die Cutscene Notation von totalwarANGEL ermφglicht es viele
            -- Kameraeffekte einfacher umzusetzen, da man die Kamera όber
            -- eine Position und eine Blickrichtung steuert.

            else
                local cutscene = BriefingSystem.Flight.Cutscene;

                if cutscene then
                    local StartPosition = cutscene.StartPosition or cutscene.EndPosition;
                    local EndPosition = cutscene.EndPosition;
                    local StartLookAt = cutscene.StartLookAt or cutscene.EndLookAt;
                    local EndLookAt = cutscene.EndLookAt;
                    local StartFOV = cutscene.StartFOV or cutscene.EndFOV;
                    local EndFOV = cutscene.EndFOV;
                    local StartTime = cutscene.StartTime;
                    local FlyTime = cutscene.FlyTime;
                    local CurrTime = Logic.GetTimeMs()/1000;

                    local Factor = BriefingSystem.InterpolationFactor(StartTime, CurrTime, FlyTime, cutscene);

                    -- Setzt das Blickziel der Kamera zum Animationsbeginn
                    if not StartLookAt.X then
                        local CamPos = GetPosition(StartLookAt[1], (StartLookAt[2] or 0));
                        if StartLookAt[3] then
                            CamPos.X = CamPos.X + StartLookAt[3] * math.cos( math.rad(StartLookAt[4]) );
                            CamPos.Y = CamPos.Y + StartLookAt[3] * math.sin( math.rad(StartLookAt[4]) );
                        end
                        StartLookAt = CamPos;
                    end

                    -- Setzt das Blickziel der Kamera zum Animationsende
                    if not EndLookAt.X then
                        local CamPos = GetPosition(EndLookAt[1], (EndLookAt[2] or 0));
                        if EndLookAt[3] then
                            CamPos.X = CamPos.X + EndLookAt[3] * math.cos( math.rad(EndLookAt[4]) );
                            CamPos.Y = CamPos.Y + EndLookAt[3] * math.sin( math.rad(EndLookAt[4]) );
                        end
                        EndLookAt = CamPos;
                    end
                    local lookAtX, lookAtY, lookAtZ = BriefingSystem.CutsceneGetPosition(StartLookAt, EndLookAt, Factor);
                    Camera.ThroneRoom_SetLookAt(lookAtX, lookAtY, lookAtZ);

                    -- Setzt die Startposition der Kamera
                    -- Positionstabelle {X= x, Y= y, Z= z}

                    if not StartPosition.X then
                        local CamPos = GetPosition(StartPosition[1], (StartPosition[2] or 0));
                        if StartPosition[3] then
                            CamPos.X = CamPos.X + StartPosition[3] * math.cos( math.rad(StartPosition[4]) );
                            CamPos.Y = CamPos.Y + StartPosition[3] * math.sin( math.rad(StartPosition[4]) );
                        end
                        StartPosition = CamPos;
                    end

                    -- Setzt die Endposition der Kamera
                    -- Positionstabelle {X= x, Y= y, Z= z}

                    if not EndPosition.X then
                        local CamPos = GetPosition(EndPosition[1], (EndPosition[2] or 0));
                        if EndPosition[3] then
                            CamPos.X = CamPos.X + EndPosition[3] * math.cos( math.rad(EndPosition[4]) );
                            CamPos.Y = CamPos.Y + EndPosition[3] * math.sin( math.rad(EndPosition[4]) );
                        end
                        EndPosition = CamPos;
                    end

                    local posX, posY, posZ = BriefingSystem.CutsceneGetPosition(StartPosition, EndPosition, Factor);
                    Camera.ThroneRoom_SetPosition(posX, posY, posZ);

                    -- Setzt den Bildschirmausschnitt
                    Camera.ThroneRoom_SetFOV(StartFOV + (EndFOV - StartFOV) * Factor);
                end
            end

            ----------------------------------------------------------------

            -- Notizen im Briefing
            -- Blendet zusδtzlichen Text wδhrend eines Briefings ein. Siehe
            -- dazu Kommentar bei der Funktion.

            BriefingSystem.ControlInformationText();

            -- Multiple Choice ist bestδtigt, wenn das Auswahlfeld
            -- verschwindet. In diesem Fall hat der Spieler geklickt.

            if BriefingSystem.MCSelectionIsShown then
                local Widget = "/InGame/SoundOptionsMain/RightContainer/SoundProviderComboBoxContainer";
                if XGUIEng.IsWidgetShown(Widget) == 0 then
                    BriefingSystem.MCSelectionIsShown = false;
                    BriefingSystem.OnConfirmed();
                end
            end
        end
    end

    function ThroneRoomLeftClick()
    end

    --------------------------------------------------------------------
    -- Cutscene Functions by totalwarANGEL
    --------------------------------------------------------------------

    function BriefingSystem.CutsceneGetPosition(_Start, _End, _Factor)
        local X = _Start.X + (_End.X - _Start.X) * _Factor;
        local Y = _Start.Y + (_End.Y - _Start.Y) * _Factor;
        local Z = _Start.Z + (_End.Z - _Start.Z) * _Factor;
        return X, Y, Z;
    end

    function BriefingSystem.CutsceneSaveFlight(_cameraPosition, _cameraLookAt, _FOV)
        BriefingSystem.Flight.Cutscene = BriefingSystem.Flight.Cutscene or {};
        BriefingSystem.Flight.Cutscene.StartPosition = _cameraPosition;
        BriefingSystem.Flight.Cutscene.StartLookAt = _cameraLookAt;
        BriefingSystem.Flight.Cutscene.StartFOV = _FOV;
        BriefingSystem.Flight.Cutscene.StartTime = Logic.GetTimeMs()/1000;
        BriefingSystem.Flight.Cutscene.FlyTime = 0;
    end

    function BriefingSystem.CutsceneFlyTo(_cameraPosition, _cameraLookAt, _FOV, _time)
        BriefingSystem.Flight.Cutscene = BriefingSystem.Flight.Cutscene or {};
        BriefingSystem.Flight.Cutscene.StartTime = Logic.GetTimeMs()/1000;
        BriefingSystem.Flight.Cutscene.FlyTime = _time;
        BriefingSystem.Flight.Cutscene.EndPosition = _cameraPosition;
        BriefingSystem.Flight.Cutscene.EndLookAt = _cameraLookAt;
        BriefingSystem.Flight.Cutscene.EndFOV = _FOV;
    end

    function BriefingSystem.CutsceneStopFlight()
        BriefingSystem.Flight.Cutscene = BriefingSystem.Flight.Cutscene or {};
        BriefingSystem.Flight.Cutscene.StartPosition = BriefingSystem.Flight.Cutscene.EndPosition;
        BriefingSystem.Flight.Cutscene.StartLookAt = BriefingSystem.Flight.Cutscene.EndLookAt;
        BriefingSystem.Flight.Cutscene.StartFOV = BriefingSystem.Flight.Cutscene.EndFOV;
    end

    --------------------------------------------------------------------

    function BriefingSystem.InterpolationFactor(_start, _curr, _total, _dataContainer)
        local factor = 1;

        if _start + _total > _curr then
            factor = (_curr - _start) / _total;
            if _dataContainer and _curr == _dataContainer.TempLastLogicTime then
                factor = factor + (Framework.GetTimeMs() - _dataContainer.TempLastFrameworkTime) / _total / 1000 * Game.GameTimeGetFactor(GUI.GetPlayerID());
            else
                _dataContainer.TempLastLogicTime = _curr;
                _dataContainer.TempLastFrameworkTime = Framework.GetTimeMs();
            end
        end
        if factor > 1 then
            factor = 1;
        end
        return factor;
    end

    function BriefingSystem.GetCameraPosition(_start, _end, _factor)
        local lookAtX = _start.X + (_end.X - _start.X) * _factor;
        local lookAtY = _start.Y + (_end.Y - _start.Y) * _factor;
        local lookAtZ;
        if _start.Z or _end.Z then
            lookAtZ = (_start.Z or Display.GetTerrainHeight(_start.X, _start.Y)) + ((_end.Z or Display.GetTerrainHeight(_end.X, _end.Y)) - (_start.Z or Display.GetTerrainHeight(_start.X, _start.Y))) * _factor;
        else
            lookAtZ = Display.GetTerrainHeight(lookAtX, lookAtY) * ((_start.ZRelative or 1) + ((_end.ZRelative or 1) - (_start.ZRelative or 1)) * _factor) + ((_start.ZAdd or 0) + ((_end.ZAdd or 0) - (_start.ZAdd or 0))) * _factor;
        end
        return lookAtX, lookAtY, lookAtZ;
    end

    function BriefingSystem.SaveFlight(_position, _rotation, _angle, _distance, _FOV)
        BriefingSystem.Flight.StartZoomAngle = _angle;
        BriefingSystem.Flight.StartZoomDistance = _distance;
        BriefingSystem.Flight.StartRotation = _rotation;
        BriefingSystem.Flight.StartPosition = _position;
        BriefingSystem.Flight.StartFOV = _FOV;
    end

    function BriefingSystem.FlyTo(_position, _rotation, _angle, _distance, _FOV, _time)
        local flight = BriefingSystem.Flight;
        flight.StartTime = Logic.GetTimeMs()/1000;
        flight.FlyTime = _time;
        flight.EndPosition = _position;
        flight.EndRotation = _rotation;
        flight.EndZoomAngle = _angle;
        flight.EndZoomDistance = _distance;
        flight.EndFOV = _FOV;
    end

    function BriefingSystem.StopFlight()
        local flight = BriefingSystem.Flight;
        flight.StartZoomAngle = flight.EndZoomAngle;
        flight.StartZoomDistance = flight.EndZoomDistance;
        flight.StartRotation = flight.EndRotation;
        flight.StartPosition = flight.EndPosition;
        flight.StartFOV = flight.EndFOV;
        if flight.Follow then
            flight.StartPosition = GetPosition(flight.Follow);
            flight.Follow = nil;
        end
    end

    function BriefingSystem.FollowFlight(_follow, _rotation, _angle, _distance, _FOV, _time, _Z)
        local pos = GetPosition(_follow); pos.Z = _Z or 0;
        BriefingSystem.FlyTo(pos, _rotation, _angle, _distance, _FOV, _time);
        BriefingSystem.Flight.StartPosition = nil;
        BriefingSystem.Flight.Follow = _follow;
    end

    function BriefingSystem.IsBriefingActive()
        return BriefingSystem.GlobalSystem ~= nil and BriefingSystem.GlobalSystem.isActive;
    end
    IsBriefingActive = BriefingSystem.IsBriefingActive;

    function BriefingSystem.SetBriefingPageTextPosition(_page)
        local size = {GUI.GetScreenSize()};

        -- set title position
        local x,y = XGUIEng.GetWidgetScreenPosition("/InGame/ThroneRoom/Main/DialogTopChooseKnight/ChooseYourKnight");
        XGUIEng.SetWidgetScreenPosition("/InGame/ThroneRoom/Main/DialogTopChooseKnight/ChooseYourKnight", x, 65);

        -- reset widget position with backup
        if not _page.mc then
            if BriefingSystem.BriefingTextPositionBackup then
                local pos = BriefingSystem.BriefingTextPositionBackup;
                XGUIEng.SetWidgetScreenPosition("/InGame/ThroneRoom/Main/MissionBriefing/Text", pos[1], pos[2]);
            end

            -- text at the mittle
            if _page.splashscreen then
                if _page.centered then
                    local Height = 0;
                    if _page.text then
                        -- Textlδnge
                        local Length = string.len(_page.text);
                        Height = Height + math.ceil((Length/80));

                        -- Zeilenumbrόche
                        local CarriageReturn = 0;
                        local s,e = string.find(_page.text, "{cr}");
                        while (e) do
                            CarriageReturn = CarriageReturn + 1;
                            s,e = string.find(_page.text, "{cr}", e+1);
                        end
                        Height = Height + math.floor((CarriageReturn/2));

                        -- Relativ
                        local Screen = {GUI.GetScreenSize()};
                        Height = (Screen[2]/2) - (Height*10);
                    end

                    XGUIEng.SetWidgetScreenPosition("/InGame/ThroneRoom/Main/DialogTopChooseKnight/ChooseYourKnight", x, 0 + Height);

                    local x,y = XGUIEng.GetWidgetScreenPosition("/InGame/ThroneRoom/Main/MissionBriefing/Text");
                    if not BriefingSystem.BriefingTextPositionBackup then
                        BriefingSystem.BriefingTextPositionBackup = {x, y};
                    end
                    XGUIEng.SetWidgetScreenPosition("/InGame/ThroneRoom/Main/MissionBriefing/Text", x, 38 + Height);
                end
            end

            return;
        end

        -- move title to very top if mc page contains text
        local x,y = XGUIEng.GetWidgetScreenPosition("/InGame/ThroneRoom/Main/DialogTopChooseKnight/ChooseYourKnight");
        if _page.mc.text and _page.mc.text ~= "" then
            XGUIEng.SetWidgetScreenPosition("/InGame/ThroneRoom/Main/DialogTopChooseKnight/ChooseYourKnight",x,5);
        end

        -- move the text up to the top
        local x,y = XGUIEng.GetWidgetScreenPosition("/InGame/ThroneRoom/Main/MissionBriefing/Text");
        if not BriefingSystem.BriefingTextPositionBackup then
            BriefingSystem.BriefingTextPositionBackup = {x, y};
        end
        XGUIEng.SetWidgetScreenPosition("/InGame/ThroneRoom/Main/MissionBriefing/Text",x,42);
    end

    function BriefingSystem.SetBriefingPageWidgetAppearance(_page, _style)
        local BG = "/InGame/ThroneRoomBars_2/BarTop";
        local BB = "/InGame/ThroneRoomBars_2/BarBottom";
        local size = {GUI.GetScreenSize()};

        if not _page.splashscreen then
            XGUIEng.SetMaterialTexture(BG, 1, "");
            XGUIEng.SetMaterialTexture(BB, 1, "");
            XGUIEng.SetMaterialColor(BG, 1, 0, 0, 0, 255);
            XGUIEng.SetMaterialColor(BB, 1, 0, 0, 0, 255);

            if BriefingSystem.BriefingBarSizeBackup then
                local pos = BriefingSystem.BriefingBarSizeBackup;
                XGUIEng.SetWidgetSize(BG, pos[1], pos[2]);
                BriefingSystem.BriefingBarSizeBackup = nil;
            end

            BriefingSystem.ShowBriefingBar(_style);
            return;
        end

        if _page.splashscreen == true then
            XGUIEng.SetMaterialTexture(BG, 1, "");
            XGUIEng.SetMaterialColor(BG, 1, 0, 0, 0, 255);
        else
            local u0 = 0;
            local u1 = 1;
            local v0 = 0;
            local v1 = 1;

            local resolution = math.floor((size[1]/size[2]) * 10);
            if resolution == 13 then
                u0 = 0.125;
                u1 = 0.875;
                v0 = 0;
                v1 = 1;
            end

            -- Invertiertes X spiegelt
            if _page.splashscreen.invertX then
                local tmp = u0;
                u0 = u1;
                u1 = tmp;
            end

            -- Invertiertes Y dreht um 180°
            if _page.splashscreen.invertY then
                local tmp = v0;
                v0 = v1;
                v1 = tmp;
            end

            -- Einfδrben
            if _page.splashscreen.color then
                local c = _page.splashscreen.color;
                XGUIEng.SetMaterialColor(BG, 1, c[1], c[2], c[3], 225);
                XGUIEng.SetMaterialAlpha(BG, 1, c[4]);
            else
                XGUIEng.SetMaterialColor(BG, 1, 255, 255, 255, 255);
                XGUIEng.SetMaterialAlpha(BG, 1, 255);
            end

            XGUIEng.SetMaterialColor(BB, 1, 0, 0, 0, 0);
            XGUIEng.SetMaterialTexture(BG, 1, _page.splashscreen.image);
            XGUIEng.SetMaterialUV(BG, 1, u0, v0, u1, v1);
        end

        if not BriefingSystem.BriefingBarSizeBackup then
            local x,y = XGUIEng.GetWidgetSize(BG);
            BriefingSystem.BriefingBarSizeBackup = {x, y};
        end

        local BarX    = BriefingSystem.BriefingBarSizeBackup[1];
        local _, BarY = XGUIEng.GetWidgetSize("/InGame/ThroneRoomBars");
        XGUIEng.SetWidgetSize(BG, BarX, BarY);

        XGUIEng.ShowWidget("/InGame/ThroneRoomBars", 0);
        XGUIEng.ShowWidget("/InGame/ThroneRoomBars_2", 1);
        XGUIEng.ShowWidget("/InGame/ThroneRoomBars_Dodge", 0);
        XGUIEng.ShowWidget("/InGame/ThroneRoomBars_2_Dodge", 0);
        XGUIEng.ShowWidget(BG, 1);
    end
end

-- Share -----------------------------------------------------------------------

---
--
--
function BundleBriefingSystem:GetColorTable()
    return self.Shared.Colors;
end

-- -------------------------------------------------------------------------- --

Core:RegisterBundle("BundleBriefingSystem");

--[[
----------------------------------------------------------------------------
    Reward_Briefing
    added by totalwarANGEL
    Ruft eine Funktion im Skript auf, die eine Briefing-ID zurόck gibt.
    Diese wird dann in der Quest gespeichert und kann mit Trigger_Briefing
    verwendet werden.
    Die letzte Zeile der Funktion, die das Briefing erstellt und startet,
    sieht demzufolge so aus: return StartBriefing(briefing)
----------------------------------------------------------------------------
    Argument        | Beschreibung
  ------------------|---------------------------------------
    Funktion        | Funktion, die das Briefing erstellt
                    | und die ID zurόck gibt.
----------------------------------------------------------------------------
]]

b_Reward_Briefing = {
    Name = "Reward_Briefing",
    Description = {
        en = "Reward: Calls a function that creates a briefing and saves the returned briefing ID into the quest.",
        de = "Lohn: Ruft eine Funktion auf, die ein Briefing erzeugt und die zurueckgegebene ID in der Quest speichert.",
    },
    Parameter = {
        { ParameterType.Default, en = "Briefing function", de = "Funktion mit Briefing" },
    },
}

function b_Reward_Briefing:GetRewardTable()
    return { Reward.Custom,{self, self.CustomFunction} }
end

function b_Reward_Briefing:AddParameter(__index_, __parameter_)
    if (__index_ == 0) then
        self.Function = __parameter_;
    end
end

function b_Reward_Briefing:CustomFunction(__quest_)
    local BriefingID = _G[self.Function](self, __quest_);
    local QuestID = GetQuestID(__quest_.Identifier);
    Quests[QuestID].EmbeddedBriefing = BriefingID;
    if not BriefingID and QSB.DEBUG_CheckAtRun then
        local Text = __quest_.Identifier..": "..self.Name..": '"..self.Function.."' has not returned anything!"
        if IsBriefingActive() then
            GUI_Note(Text);
        end
        dbg(Text);
    end
end

function b_Reward_Briefing:DEBUG(__quest_)
    if not type(_G[self.Function]) == "function" then
        dbg(__quest_.Identifier..": "..self.Name..": '"..self.Function.."' was not found!");
        return true;
    end
    return false;
end

function b_Reward_Briefing:Reset(__quest_)
    local QuestID = GetQuestID(__quest_.Identifier);
    Quests[QuestID].EmbeddedBriefing = nil;
end

AddQuestBehavior(b_Reward_Briefing)

--[[
----------------------------------------------------------------------------
    Reprisal_Briefing
    added by totalwarANGEL
    Ruft eine Funktion im Skript auf, die eine Briefing-ID zurόck gibt.
    Diese wird dann in der Quest gespeichert und kann mit Trigger_Briefing
    verwendet werden.
    Die letzte Zeile der Funktion, die das Briefing erstellt und startet,
    sieht demzufolge so aus: return StartBriefing(briefing)
----------------------------------------------------------------------------
    Argument        | Beschreibung
  ------------------|---------------------------------------
    Funktion        | Funktion, die das Briefing erstellt
                    | und die ID zurόck gibt.
----------------------------------------------------------------------------
]]

b_Reprisal_Briefing = {
    Name = "Reprisal_Briefing",
    Description = {
        en = "Reprisal: Calls a function that creates a briefing and saves the returned briefing ID into the quest.",
        de = "Vergeltung: Ruft eine Funktion auf, die ein Briefing erzeugt und die zurueckgegebene ID in der Quest speichert.",
    },
    Parameter = {
        { ParameterType.Default, en = "Briefing function", de = "Funktion mit Briefing" },
    },
}

function b_Reprisal_Briefing:GetReprisalTable()
    return { Reprisal.Custom,{self, self.CustomFunction} }
end

function b_Reprisal_Briefing:AddParameter(__index_, __parameter_)
    if (__index_ == 0) then
        self.Function = __parameter_;
    end
end

function b_Reprisal_Briefing:CustomFunction(__quest_)
    local BriefingID = _G[self.Function](self, __quest_);
    local QuestID = GetQuestID(__quest_.Identifier);
    Quests[QuestID].EmbeddedBriefing = BriefingID;
    if not BriefingID and QSB.DEBUG_CheckAtRun then
        local Text = __quest_.Identifier..": "..self.Name..": '"..self.Function.."' has not returned anything!"
        if IsBriefingActive() then
            GUI_Note(Text);
        end
        dbg(Text);
    end
end

function b_Reprisal_Briefing:DEBUG(__quest_)
    if not type(_G[self.Function]) == "function" then
        dbg(__quest_.Identifier..": "..self.Name..": '"..self.Function.."' was not found!");
        return true;
    end
    return false;
end

function b_Reprisal_Briefing:Reset(__quest_)
    local QuestID = GetQuestID(__quest_.Identifier);
    Quests[QuestID].EmbeddedBriefing = nil;
end

AddQuestBehavior(b_Reprisal_Briefing)

--[[
----------------------------------------------------------------------------
    Trigger_Briefing
    added by totalwarANGEL
    Starte eine Quest nachdem ein eingebettetes Briefing in einer anderen Quest
    beendet ist. Questname muss demzufolge einen Quest referenzieren, in dem ein
    Briefing mit Reward_Briefing oder Reprisal_Briefing integriert wurde.
----------------------------------------------------------------------------
    Argument        | Beschreibung
  ------------------|---------------------------------------
    Questname       | Questname einer Quest mit Briefing
    Wartezeit       | Wartezeit in Sekunden
----------------------------------------------------------------------------
]]

b_Trigger_Briefing = {
    Name = "Trigger_Briefing",
    Description = {
        en = "Trigger: after an embedded briefing of another quest has finished.",
        de = "Ausloeser: wenn das eingebettete Briefing der angegebenen Quest beendet ist.",
    },
    Parameter = {
        { ParameterType.QuestName, en = "Quest name", de = "Questname" },
        { ParameterType.Number,  en = "Wait time",  de = "Wartezeit" },
    },
}

function b_Trigger_Briefing:GetTriggerTable()
    return { Triggers.Custom2,{self, self.CustomFunction} }
end

function b_Trigger_Briefing:AddParameter(__index_, __parameter_)
    if (__index_ == 0) then
        self.Quest = __parameter_;
    elseif (__index_ == 1) then
        self.WaitTime = tonumber(__parameter_) or 0
    end
end

function b_Trigger_Briefing:CustomFunction(__quest_)
    local QuestID = GetQuestID(self.Quest);
    if IsBriefingFinished(Quests[QuestID].EmbeddedBriefing) then
        if self.WaitTime and self.WaitTime > 0 then
            self.WaitTimeTimer = self.WaitTimeTimer or Logic.GetTime();
            if Logic.GetTime() >= self.WaitTimeTimer + self.WaitTime then
                return true;
            end
        else
            return true;
        end
    end
    return false;
end

function b_Trigger_Briefing:Interrupt(__quest_)
    local QuestID = GetQuestID(self.Quest);
    Quests[QuestID].EmbeddedBriefing = nil;
    self.WaitTimeTimer = nil
end

function b_Trigger_Briefing:Reset(__quest_)
    local QuestID = GetQuestID(self.Quest);
    Quests[QuestID].EmbeddedBriefing = nil;
    self.WaitTimeTimer = nil
end

function b_Trigger_Briefing:DEBUG(__quest_)
    if tonumber(self.WaitTime) == nil or self.WaitTime < 0 then
        dbg(__quest_.Identifier.." "..self.Name..": waittime is nil or below 0!");
        return true;
    elseif not IsValidQuest(self.Quest) then
        dbg(__quest_.Identifier.." "..self.Name..": '"..self.Quest.."' is not a valid quest!");
        return true;
    end
    return false;
end