-- -------------------------------------------------------------------------- --
-- ########################################################################## --
-- #  Symfonia AddOnCutsceneSystem                                          # --
-- ########################################################################## --
-- -------------------------------------------------------------------------- --

---
-- Ermöglicht es Kameraflüge, also Cutscenes, zu erstellen.
--
-- Cutscenes sind als CS-Datei vordefinierte Kameraflüge. Mit diesem Modul
-- können diese Kameraflüge gruppiert werden. Diese Gruppierung ist das, was
-- die Cutscene ausmacht.
--
-- Pro Flug können Titel und Text eingeblendet werden und eine Lua-Funktion
-- aufgerufen werden.
--
-- Flights können entweder im Internal-Mode des Mapeditors oder über externe
-- Tools erzeugt werden. Sie müssen jedoch immer in das Hauptverzeichnis der
-- Map kopiert werden.
-- <pre>maps/externalmap/.../myCutscene.cs</pre>
-- Gibt Deinen Flights passende Namen, um die Zuordnung zu erleichtern.
-- <pre>cs01_flight1.cs
--cs01_flight2.cs
--...</pre>
--
-- Während der Mapentwicklung können die CS-Dateien nicht in der Map liegen,
-- da sie bei jedem Speichern gelöscht werden. Wenn die Datei nicht vorhanden
-- ist, wird der Flight übersprungen. Sind also keine Flights da, gilt die
-- Cutscene trotzdem als abgespielt, sobald sie beendet ist. Das erleichtert
-- das Testen. Du siehst nur nix.
--
-- @within Modulbeschreibung
-- @set sort=true
--
AddOnCutsceneSystem = {};

API = API or {};

-- -------------------------------------------------------------------------- --
-- User-Space                                                                 --
-- -------------------------------------------------------------------------- --

---
-- Startet eine Cutscene.
--
-- Die einzelnen Flights einer Cutscene werden als CS-Dateien definiert.
--
-- Eine Cutscene besteht aus den einzelnen Kameraflügen, also Flights, und
-- speziellen Feldern, mit denen weitere Einstellungen gemacht werden können.
-- Siehe dazu auch das Briefing System für einen Vergleich.
--
-- Die Funktion gibt die ID der Cutscene zurück, mit der geprüft werden kann,
-- ob die Cutscene beendet ist.
-- 
-- <b>Alias</b>: StartCutscene
--
-- @param[type=table]   _Cutscene Cutscene table
-- @return[type=number] ID der Cutscene
-- @within Anwenderfunktionen
-- @usage function MyCutscene()
--     local Cutscene = {
--        CameraLookAt = {X, Y},   -- Kameraposition am Ende setzen
--        RestoreGameSpeed = true, -- Spielgeschwindigkeit wiederherstellen
--        BarOpacity = 0.39,       -- Durchsichtige Bars verwenden (Opacity = 39%)
--        BigBars = false,         -- Breite Bars verwenden (Default false)
--        HideBorderPins = true,   -- Grenzsteine ausblenden
--        FastForward = false,     -- Beschleunigt abspielen erlauben
--     };
--     local AF = API.AddFlights(Cutscene);
--
--     -- Hier erfolgt die Auflistung der Flights mit AF()
--
--     Cutscene.Starting = function(_Data)
--        -- Hier werden Aktionen vor dem Start ausgeführt.
--     end
--     Cutscene.Finished = function(_Data)
--        -- Hier kann eine abschließende Aktion ausgeführt werden.
--     end
--     return API.StartCutscene(Cutscene);
-- end
--
function API.CutsceneStart(_Cutscene)
    if GUI then
        warn("API.CutsceneStart: Cannot start cutscene from local script!");
        return;
    end

    -- Lokalisierung Texte
    for i= 1, #_Cutscene, 1 do
        if type(_Cutscene[i]) == "table" then
            if _Cutscene[i].Title and type(_Cutscene[i].Title) == "table" then
                _Cutscene[i].Title = API.Localize(_Cutscene[i].Title);
            end
            _Cutscene[i].Title = API.ConvertPlaceholders(_Cutscene[i].Title);

            if _Cutscene[i].Text and type(_Cutscene[i].Text) == "table" then
                _Cutscene[i].Text = API.Localize(_Cutscene[i].Text);
            end
            _Cutscene[i].Text = API.ConvertPlaceholders(_Cutscene[i].Text);

            if _Cutscene[i].Lines then
                for j= 1, #_Cutscene[i].Lines, 1 do
                    if _Cutscene[i].Lines[j].Title and type(_Cutscene[i].Lines[j].Title) == "table" then
                        _Cutscene[i].Lines[j].Title = API.Localize(_Cutscene[i].Lines[j].Title);
                    end
                    _Cutscene[i].Lines[j].Title = API.ConvertPlaceholders(_Cutscene[i].Lines[j].Title);
            
                    if _Cutscene[i].Lines[j].Text and type(_Cutscene[i].Lines[j].Text) == "table" then
                        _Cutscene[i].Lines[j].Text = API.Localize(_Cutscene[i].Lines[j].Text);
                    end
                    _Cutscene[i].Lines[j].Text = API.ConvertPlaceholders(_Cutscene[i].Lines[j].Text);
                end
            end
        end
    end

    return AddOnCutsceneSystem.Global:StartCutscene(_Cutscene);
end
StartCutscene = API.CutsceneStart;

---
-- Prüft, ob zur Zeit eine Cutscene aktiv ist.
-- 
-- <b>Alias</b>: IsCutsceneActive
-- 
-- @return[type=boolean] Kameraflug ist aktiv
-- @within Anwenderfunktionen
--
function API.CutsceneIsActive()
    if GUI then
        return AddOnCutsceneSystem.Local:IsCutsceneActive();
    end
    return AddOnCutsceneSystem.Global:IsCutsceneActive();
end
IsCutsceneActive = API.CutsceneIsActive;

---
-- Ändert den Titel des aktuellen Flight.
-- @param[type=string] _Text Anzeigetext
-- @within Anwenderfunktionen
-- @usage API.PrintCutsceneHeadline("Das ist der neue Titel");
--
function API.PrintCutsceneHeadline(_Text)
    if not API.CutsceneIsActive() then
        return;
    end
    if type(_Text) == "table" then
        _Text = API.Localize(_Text);
    end
    if not GUI then
        Logic.ExecuteInLuaLocalState([[API.PrintCutsceneHeadline("]].._Text..[[")]]);
        return;
    end
    AddOnCutsceneSystem.Local:PrintCutsceneHeadline(_Text);
end

---
-- Ändert den Text des aktuellen Flight.
-- @param[type=string] _Text Anzeigetext
-- @within Anwenderfunktionen
-- @usage API.PrintCutsceneText("Schaut mal, neuer Text! Wie wunderbar!");
--
function API.PrintCutsceneText(_Text)
    if not API.CutsceneIsActive() then
        return;
    end
    if type(_Text) == "table" then
        _Text = API.Localize(_Text);
    end
    if not GUI then
        Logic.ExecuteInLuaLocalState([[API.PrintCutsceneText("]].._Text..[[")]]);
        return;
    end
    AddOnCutsceneSystem.Local:PrintCutsceneText(_Text);
end

---
-- Setzt die Geschwindigkeit für den schnellen Vorlauf für alle Cutscenes.
--
-- Beim schnellen Vorlauf wird der Kameraflug beschleunigt ausgeführt. Die
-- Spielgeschwindigkeit wird dabei auch beschleunigt!
--
-- <b>Alias</b>: SetCutsceneFastForwardSpeed
-- 
-- @param[type=number] _Speed Geschwindigkeit
-- @within Anwenderfunktionen
-- @usage API.CutsceneSetFastForwardSpeed(6);
--
function API.CutsceneSetFastForwardSpeed(_Speed)
    if not GUI then
        Logic.ExecuteInLuaLocalState("API.CutsceneSetFastForwardSpeed(" .._Speed.. ")");
        return;
    end
    if type(_Speed) ~= "number" or _Speed < 1 then
        error("API.CutsceneSetFastForwardSpeed: _Speed (" ..tostring(_Speed).. ") is wrong!");
        return;
    end
    AddOnCutsceneSystem.Local.Data.FastForward.Speed = _Speed;
end
SetCutsceneFastForwardSpeed = API.CutsceneSetFastForwardSpeed;

---
-- Erzeugt die Funktionen zur Erstellung von Flights in einer Cutsceme und
-- bindet sie an die Cutscene. Diese Funktion muss vor dem Start einer
-- Cutscene aufgerufen werden um Flights hinzuzufügen.
-- <ul>
-- <li><a href="#AF">AF</a></li>
-- </ul>
--
-- <b>Alias</b>: AddFlights
--
-- @param[type=table] _Cutscene Cutscene Definition
-- @return[type=function] <a href="#AF">AF</a>
-- @within Anwenderfunktionen
--
-- @usage local AF = API.AddFlights(Briefing);
--
function API.AddFlights(_Cutscene)
    if GUI then
        return;
    end
    _Cutscene.GetFlight = function(self, _NameOrID)
        local ID = AddOnCutsceneSystem.Global:GetPageIDByName(_NameOrID);
        return BundleBriefingSystem.Global.Data.CurrentCutscene[ID];
    end
    
    local AF = function(_Flight)
        _Cutscene.Length = (_Cutscene.Length or 0) +1;
        table.insert(_Cutscene, _Flight);
        return _Flight;
    end
    return AF;
end
AddFlights = API.AddFlights;

---
-- Erstellt einen Flight für eine Cutscene.
--
-- @param[type=table] _Flight Spezifikation des Flight
-- @return[type=table] Refernez auf den Flight
-- @within Cutscene
-- @usage AF {
--     Flight = "some_file", -- .cs wird nicht mit angegeben!
--     Title  = "Angezeigter Titel",
--     Text   = "Angezeigter Text",
--     Action = function(_Data)
--         -- Aktion für den Flight ausführen
--     end,
-- }
--
function AF(_Flight)
    API.Note("Please use the method provided by API.AddFlights!");
end

-- -------------------------------------------------------------------------- --
-- Application-Space                                                          --
-- -------------------------------------------------------------------------- --

AddOnCutsceneSystem = {
    Global = {
        Data = {
            CurrentCutscene = {},
            CutsceneQueue = {},
            CutsceneActive = false,
        },
    },
    Local = {
        Data = {
            CurrentCutscene = {},
            CurrentFlight = 1,
            CutsceneActive = false,
            CinematicActive = false,
            FastForward = {
                Active = false,
                Indent = 1,
                Speed = 15,
            },
            Fader = {
                Animation = {},
                From = 1.0,
                To = 0.0,
                TimeStamp = 0,
                Duration = 0,
                Callback = nil,
                Widget = "/InGame/Fader/Element",      
                Page = "/InGame/Fader" 
            }
        },
    },

    Text = {
        FastForwardActivate   = {de = "Beschleunigen", en = "Fast Forward"},
        FastForwardDeactivate = {de = "Zurücksetzen",  en = "Normal Speed"},
        FastFormardMessage    = {de = "SCHNELLER VORLAUF",  en = "FAST FORWARD"},
    }
}

-- Global Script ---------------------------------------------------------------

---
-- Initalisiert das Bundle im globalen Skript.
-- @within Internal
-- @local
--
function AddOnCutsceneSystem.Global:Install()
end

---
-- Startet die Cutscene im globalen Skript. Es wird eine neue ID für die
-- Cutscene erzeugt und zurückgegeben. Die Cutscehe wird als CurrentCutscene
-- gespeichert und in das lokale Skript kopiert.
--
-- Damit keine Briefings starten, wird die entsprechende Variable im
-- Briefingsystem true gesetzt.
--
-- @param[type=table]   _Cutscene Cutscene table
-- @return[type=number] ID der Cutscene
-- @within Internal
-- @local
--
function AddOnCutsceneSystem.Global:StartCutscene(_Cutscene, _ID)
    if not _ID then
        BundleBriefingSystem.Global.Data.BriefingID = BundleBriefingSystem.Global.Data.BriefingID +1;
        _ID = BundleBriefingSystem.Global.Data.BriefingID;
    end

    if API.IsLoadscreenVisible() or self:IsCutsceneActive() then
        table.insert(self.Data.CutsceneQueue, {_Cutscene, _ID});
        if not self.Data.CutsceneQueueJobID then
            self.Data.CutsceneQueueJobID = StartSimpleHiResJobEx(AddOnCutsceneSystem.Global.CutsceneQueueController);
        end
        return _ID;
    end
    if _Cutscene.Starting then
        _Cutscene:Starting();
    end

    self.Data.CurrentCutscene = _Cutscene;
    self.Data.CurrentCutscene.ID = BundleBriefingSystem.Global.Data.BriefingID;
    self.Data.CurrentCutscene.BarOpacity = self.Data.CurrentCutscene.BarOpacity or 1;
    self.Data.CurrentCutscene.Length = self.Data.CurrentCutscene.Length or #_Cutscene;
    if self.Data.CurrentCutscene.BigBars == nil then
        self.Data.CurrentCutscene.BigBars = false;
    end
    local Cutscene = API.ConvertTableToString(self.Data.CurrentCutscene);
    Logic.ExecuteInLuaLocalState("AddOnCutsceneSystem.Local:StartCutscene(" ..Cutscene.. ")");
    self.Data.CutsceneActive = true;
    BundleBriefingSystem.Global.Data.BriefingActive = true;
    BundleBriefingSystem.Global.Data.DisplayIngameCutscene = true;

    return BundleBriefingSystem.Global.Data.BriefingID;
end

---
-- Stoppt die Cutscene im globalen Skript. Falls eine Finished-Funktion für
-- die Cutscene definiert ist, wird diese ausgeführt. Wenn weitere Cutscenes
-- in der Warteschlange stehen, wird die nächste Cutscene gestartet. Die
-- aktuelle Cutscene wird als beendet vermerkt.
--
-- Das Starten von Briefings wird wieder erlaubt.
--
-- @within Internal
-- @local
--
function AddOnCutsceneSystem.Global:StopCutscene()
    BundleBriefingSystem.Global.Data.BriefingActive = false;
    BundleBriefingSystem.Global.Data.DisplayIngameCutscene = false;

    local CutsceneID = self.Data.CurrentCutscene.ID;
    BundleBriefingSystem.Global.Data.FinishedBriefings[CutsceneID] = true;
    Logic.ExecuteInLuaLocalState("AddOnCutsceneSystem.Local:StopCutscene()");

    if self.Data.CurrentCutscene.Finished then
        self.Data.CurrentCutscene:Finished();
    end
    self.Data.CutsceneActive = false;
end

---
-- Gibt die Flight-ID zum angegebenen Flight-Namen zurück.
--
-- Wenn kein Flight gefunden wird, der den angegebenen Namen hat, wird 0
-- zurückgegeben. Wenn eine Flight-ID angegeben wird, wird diese zurückgegeben.
--
-- @param[type=string] _FlightName Name des Flight
-- @return[type=number] ID des Flight
-- @within Internal
-- @local
--
function AddOnCutsceneSystem.Global:GetPageIDByName(_FlightName)
    if self.Data.CurrentCutscene then
        if type(_FlightName) == "number" then
            return _FlightName;
        end
        for i= 1, self.Data.CurrentCutscene.Length, 1 do
            local Flight = self.Data.CurrentCutscene[i];
            if Flight and type(Flight) == "table" and Flight.Flight == _FlightName then
                return i;
            end
        end
    end
    return 0;
end

---
-- Prüft, ob eine Cutscene aktiv ist.
-- @param[type=boolean] Cutscene ist aktiv
-- @within Internal
-- @local
--
function AddOnCutsceneSystem.Global:IsCutsceneActive()
    return IsBriefingActive() == true or self.Data.CutsceneActive == true;
end

---
-- Steuert die Cutscene-Warteschlange.
-- @within Internal
-- @local
--
function AddOnCutsceneSystem.Global.CutsceneQueueController()
    if #AddOnCutsceneSystem.Global.Data.CutsceneQueue == 0 then
        AddOnCutsceneSystem.Global.Data.CutsceneQueueJobID = nil;
        return true;
    end
    
    if not API.IsLoadscreenVisible() and not AddOnCutsceneSystem.Global:IsCutsceneActive() then
        local Next = table.remove(AddOnCutsceneSystem.Global.Data.CutsceneQueue, 1);
        AddOnCutsceneSystem.Global:StartCutscene(Next[1], Next[2]);
    end
end

-- Local Script ----------------------------------------------------------------

---
-- Initalisiert das Bundle im lokalen Skript.
--
-- @within Internal
-- @local
--
function AddOnCutsceneSystem.Local:Install()
    StartSimpleHiResJobEx(AddOnCutsceneSystem.Local.DisplayFastForwardMessage);

    self:OverrideGameCallbackEscape();
    self:OverrideUpdateFader();
end

---
-- Startet die Cutscene im lokalen Skript. Die Spielansicht wird versteckt
-- und der Cinematic Mode aktiviert.
--
-- @param[type=table] _Cutscene Cutscene table
-- @within Internal
-- @local
--
function AddOnCutsceneSystem.Local:StartCutscene(_Cutscene)
    BundleBriefingSystem.Local.Data.DisplayIngameCutscene = true;

    self.Data.CurrentFlight = 1;
    self.Data.CurrentCutscene = _Cutscene;
    self.Data.CutsceneActive = true;
    
    Display.SetRenderSky(1);
    if self.Data.CurrentCutscene.HideBorderPins then
        Display.SetRenderBorderPins(0);
    end
    if Game.GameTimeGetFactor() ~= 0 then
        if self.Data.CurrentCutscene.RestoreGameSpeed and not self.Data.GaneSpeedBackup then
            self.Data.GaneSpeedBackup = Game.GameTimeGetFactor();
            if self.Data.GaneSpeedBackup < 1 then
                self.Data.GaneSpeedBackup = 1;
            end
        end
        Game.GameTimeSetFactor(GUI.GetPlayerID(), 1);
    end
    self.Data.SelectedEntities = {GUI.GetSelectedEntities()};
    
    if not self.Data.CinematicActive then
        self:ActivateCinematicMode();
    end

    self:NextFlight();
end

---
-- Stoppt die Cutscene im lokalen Skript. Hier wird der Cinematic Mode
-- deaktiviert und die Spielansicht wiederhergestellt.
--
-- @within Internal
-- @local
--
function AddOnCutsceneSystem.Local:StopCutscene()
    if self.Data.CurrentCutscene.CameraLookAt then 
        Camera.RTS_SetLookAtPosition(unpack(self.Data.CurrentCutscene.CameraLookAt));
    end
    for k, v in pairs(self.Data.SelectedEntities) do
        GUI.SelectEntity(v);
    end
    Display.SetRenderBorderPins(1);
    Display.SetRenderSky(0);

    local GameSpeed = (self.Data.GaneSpeedBackup or 1);
    Game.GameTimeSetFactor(GUI.GetPlayerID(), GameSpeed);
    self.Data.GaneSpeedBackup = nil;

    BundleBriefingSystem.Local.Data.DisplayIngameCutscene = false;
    self:DeactivateCinematicMode();
    self.Data.CutsceneActive = false;
    self.Data.FastForward.Active = false;
end

---
-- Prüft, ob eine Cutscene aktiv ist.
--
-- @param[type=boolean] Cutscene ist aktiv
-- @within Internal
-- @local
--
function AddOnCutsceneSystem.Local:IsCutsceneActive()
    return IsBriefingActive() == true or self.Data.CutsceneActive == true;
end

---
-- Springt zum angegebenen Flight der Cutscene.
--
-- @param _NameOrID Flight Name oder ID
-- @within Internal
-- @local
--
function AddOnCutsceneSystem.Local:JumpToFlight(_NameOrID)
    if self.Data.CurrentCutscene then
        if type(_NameOrID) == "string" then
            for i= 1, #self.Data.CurrentCutscene, 1 do
                if self.Data.CurrentCutscene[i] and self.Data.CurrentCutscene[i].Flight == _NameOrID then
                    self.Data.CurrentFlight = i -1;
                    self:FlightFinished();
                    return;
                end
            end
        else
            if self.Data.CurrentCutscene[_NameOrID] then
                self.Data.CurrentFlight = _NameOrID -1;
                self:FlightFinished();
                return;
            end
        end
    end
    -- Im Falle einer Fehleingabe, muss es trotzdem weiter gehen. Darum wird
    -- hier noch mal :FlightFinished aufgerufen.
    self:FlightFinished();
end

---
-- Startet den nächsten Flight.
--
-- @within Internal
-- @local
--
function AddOnCutsceneSystem.Local:NextFlight()
    local FlightIndex = self.Data.CurrentFlight;
    local CurrentFlight = self.Data.CurrentCutscene[FlightIndex];
    if not CurrentFlight then
        return;
    end
    if type(CurrentFlight) ~= "table" then
        self:JumpToFlight(CurrentFlight);
    else
        if Camera.IsValidCutscene(CurrentFlight.Flight) then
            Camera.StartCutscene(CurrentFlight.Flight);
        else
            self:FlightFinished();
        end
    end
end

---
-- Script Event: Flight wurde gestartet.
-- @param[type=number] _Duration Dauer in Turns
-- @within Internal
-- @local
--
function AddOnCutsceneSystem.Local:FlightStarted(_Duration)
    if self:IsCutsceneActive() then
        local FlightIndex = self.Data.CurrentFlight;
        local CurrentFlight = self.Data.CurrentCutscene[FlightIndex];
        if not CurrentFlight then
            return;
        end

        local Flight  = CurrentFlight.Flight;
        local Title   = CurrentFlight.Title or "";
        local Text    = CurrentFlight.Text or "";
        local Action  = CurrentFlight.Action;

        -- Setze Title
        self:PrintCutsceneHeadline(Title);
        -- Setze Text
        self:PrintCutsceneText(Text);
        -- Führe Action aus
        if Action then
            GUI.SendScriptCommand("AddOnCutsceneSystem.Global.Data.CurrentCutscene[" ..FlightIndex.. "]:Action()");
        end

        -- Wechselnder Text eines Flights
        if CurrentFlight.Lines then
            local TextDurationMs = (_Duration *100) / #CurrentFlight.Lines;
            local SwitchTime = 1;
            for i= 1, #CurrentFlight.Lines, 1 do
                StartSimpleHiResJobEx(
                    function(_StartTime, _ExchangeTime, _Title, _Text)
                        if Logic.GetTimeMs() >= _StartTime + _ExchangeTime then
                            AddOnCutsceneSystem.Local:PrintCutsceneHeadline(_Title);
                            AddOnCutsceneSystem.Local:PrintCutsceneText(_Text);
                            return true;
                        end
                    end,
                    Logic.GetTimeMs(),
                    SwitchTime,
                    CurrentFlight.Lines[i].Title or "",
                    CurrentFlight.Lines[i].Text or ""
                );
                SwitchTime = SwitchTime + TextDurationMs;
            end
        end

        XGUIEng.ShowWidget("/InGame/ThroneRoom/Main/Skip", (self.Data.CurrentCutscene.FastForward and 1) or 0);

        -- Handle fader
        if CurrentFlight.FadeIn then
            self:FadeIn(CurrentFlight.FadeIn);
        end
        if CurrentFlight.FadeOut then
            StartSimpleHiResJobEx(function(_Time, _FadeOut)
                if Logic.GetTimeMs() > _Time - (_FadeOut * 1000) then
                    self:FadeOut(_FadeOut);
                    return true;
                end
            end, Logic.GetTimeMs() + (_Duration*100), CurrentFlight.FadeOut);
        end
    end
end
CutsceneFlightStarted = function(_Duration)
    AddOnCutsceneSystem.Local:FlightStarted(_Duration);
end

---
-- Script Event: Flight ist beendet.
-- @within Internal
-- @local
--
function AddOnCutsceneSystem.Local:FlightFinished()
    if self:IsCutsceneActive() then
        local FlightIndex = self.Data.CurrentFlight;
        if FlightIndex == #self.Data.CurrentCutscene then
            GUI.SendScriptCommand("AddOnCutsceneSystem.Global:StopCutscene()");
            return true;
        end
        self.Data.CurrentFlight = self.Data.CurrentFlight +1;
        self:SetFaderAlpha(1);
        self:NextFlight();
    end
end
CutsceneFlightFinished = function()
    AddOnCutsceneSystem.Local:FlightFinished();
end

---
-- Setzt den Titel des aktuellen Flight.
-- @param[type=string] _Text Anzeigetext
-- @within Internal
-- @local
--
function AddOnCutsceneSystem.Local:PrintCutsceneHeadline(_Text)
    _Text = API.ConvertPlaceholders(_Text);
    if string.sub(_Text, 1, 1) ~= "{" then
        _Text = "{@color:255,250,0,255}{center}{darkshadow}" .. _Text;
    end
    XGUIEng.SetText("/InGame/ThroneRoom/Main/DialogTopChooseKnight/ChooseYourKnight", _Text);
end

---
-- Setzt den Text des aktuellen Flight.
-- @param[type=string] _Text Anzeigetext
-- @within Internal
-- @local
--
function AddOnCutsceneSystem.Local:PrintCutsceneText(_Text)
    _Text = API.ConvertPlaceholders(_Text);
    if string.sub(_Text, 1, 1) ~= "{" then
        _Text = "{center}" .. _Text;
    end
    if not self.Data.CurrentCutscene.BigBars then
        _Text = "{cr}{cr}{cr}" .. _Text;
    end
    XGUIEng.SetText("/InGame/ThroneRoom/Main/MissionBriefing/Text", _Text);
end

---
-- Steuert die Wiedergabe der Cutscenes.
-- @within Internal
-- @local
--
function AddOnCutsceneSystem.Local:ThroneRoomCameraControl()
    if self:IsCutsceneActive() then
        if self.Data.FastForward.Active == false then
            XGUIEng.SetText("/InGame/ThroneRoom/Main/Skip", "{center}" ..API.Localize(AddOnCutsceneSystem.Text.FastForwardActivate));
        else 
            XGUIEng.SetText("/InGame/ThroneRoom/Main/Skip", "{center}" ..API.Localize(AddOnCutsceneSystem.Text.FastForwardDeactivate));
        end
    end
end

---
-- Steuert Reaktionen auf Klicks des Spielers.
-- @within Internal
-- @local
--
function AddOnCutsceneSystem.Local:ThroneRoomLeftClick()
    if self:IsCutsceneActive() then
        if self.Data.CurrentCutscene.LeftClick then
            self.Data.CurrentCutscene:LeftClick();
        end
    end
end

---
-- Startet oder beendet den schnellen Vorlauf, wenn der Spieler den Skip-Button
-- klickt. Außerdem wird der Text des Skip-Button gesetzt und ein Flag gesetzt.
-- @within Internal
-- @local
--
function AddOnCutsceneSystem.Local:NextButtonPressed()
    if self:IsCutsceneActive() then
        if Game.GameTimeGetFactor() > 1 then
            Game.GameTimeSetFactor(GUI.GetPlayerID(), 1);
            self.Data.FastForward.Active = false;
        else
            Game.GameTimeSetFactor(GUI.GetPlayerID(), self.Data.FastForward.Speed);
            self.Data.FastForward.Active = true;
        end
    end
end

---
-- Initialisiert den Fader. Bei diesem Fader handelt es sich um eine leicht
-- abgewandelte Version des normalen Fader. Dieser Fader verhält sich relativ
-- zur Spielgeschwindigkeit.
-- @return[type=boolean] Fading läuft gerade
-- @within Internal
-- @local
--
function AddOnCutsceneSystem.Local:InitializeFader()
    self.Data.Fader.Animation = {};
    XGUIEng.PushPage(self.Data.Fader.Page, false);
end

---
-- Prüft, ob gerade ein Fading-Prozess läuft.
-- @return[type=boolean] Fading läuft gerade
-- @within Internal
-- @local
--
function AddOnCutsceneSystem.Local:IsFading()
	return self.Data.CutsceneActive and #self.Data.Fader.Animation > 0;
end

---
-- Blendet zur Fader-Maske aus. Callback wird am Ende ausgeführt.
-- @param[type=number] _Duration Dauer in Sekunden
-- @param[type=number] _Callback (optional) Callback-Funktion
-- @within Internal
-- @local
--
function AddOnCutsceneSystem.Local:FadeOut(_Duration, _Callback)
    table.insert(self.Data.Fader.Animation, {
        From = 0,
        To = 1,
        TimeStamp = Logic.GetTimeMs(),
        Duration = _Duration,
        Callback = _Callback,
    });
end

---
-- Blendet von der Fader-Maske ein. Callback wird am Ende ausgeführt.
-- @param[type=number] _Duration Dauer in Sekunden
-- @param[type=number] _Callback (optional) Callback-Funktion
-- @within Internal
-- @local
--
function AddOnCutsceneSystem.Local:FadeIn(_Duration, _Callback)
    table.insert(self.Data.Fader.Animation, {
        From = 1,
        To = 0,
        TimeStamp = Logic.GetTimeMs(),
        Duration = _Duration,
        Callback = _Callback,
    });
end

---
-- Setzt den Alpha-Wert der Fader-Maske auf den angegebenen Wert.
-- @param[type=number] _Alpha Alpha-Wert
-- @within Internal
-- @local
--
function AddOnCutsceneSystem.Local:SetFaderAlpha(_Alpha)
	if XGUIEng.IsWidgetExisting(self.Data.Fader.Widget) == 0 then
		return;
	end
	XGUIEng.SetMaterialColor(self.Data.Fader.Widget,0,0,0,0,255 * _Alpha);
	XGUIEng.SetMaterialColor(self.Data.Fader.Widget,1,0,0,0,255 * _Alpha);
end

---
-- Berechnet die lineare Interpolation des Alpha der Fader-Maske.
-- @param[type=number] _A Startwert
-- @param[type=number] _B Endwert
-- @param[type=number] _T Zeitfaktor
-- @return[number] Interpolationsfaktor
-- @within Internal
-- @local
--
function AddOnCutsceneSystem.Local:LERP(_A, _B, _T)
    return _A + ((_B - _A) * _T);
end

---
-- Überschreibt das Game Callback Escape, sodass während einer Cutscene nicht
-- abgebrochen werden kann..
-- @within Internal
-- @local
--
function AddOnCutsceneSystem.Local:OverrideGameCallbackEscape()
    AddOnCutsceneSystem.Local.GameCallback_Escape = GameCallback_Escape;
    GameCallback_Escape = function()
        if not AddOnCutsceneSystem.Local:IsCutsceneActive() then
            AddOnCutsceneSystem.Local.GameCallback_Escape();
        end
    end
end

---
-- Überschreibt die Update-Funktion des normalen Fader, sodass während einer
-- Cutscene Spielzeit statt Realzeit verwendet wird.
-- @within Internal
-- @local
--
function AddOnCutsceneSystem.Local:OverrideUpdateFader()
    UpdateFader_Orig_CutsceneSystem = UpdateFader;
    UpdateFader = function()
        if AddOnCutsceneSystem.Local.Data.CutsceneActive then
            AddOnCutsceneSystem.Local:UpdateFader();
        else
            UpdateFader_Orig_CutsceneSystem();
        end
    end
end

---
-- Aktualisiert den Alpha-Wert der Fader-Maske, wenn eine Cutscene aktiv ist.
-- @within Internal
-- @local
--
function AddOnCutsceneSystem.Local:UpdateFader()
    if self.Data.CutsceneActive == true then
        local Animation = self.Data.Fader.Animation[1];
        if Animation then
            local Time = Logic.GetTimeMs();
            local Progress = (Time - Animation.TimeStamp) / (Animation.Duration * 1000);
            local Alpha = self:LERP(Animation.From, Animation.To, Progress);
            self:SetFaderAlpha(Alpha);
            if Time >= Animation.TimeStamp + (Animation.Duration * 1000)  then
                if Animation.Callback ~= nil then
                    Animation:Callback();
                end
                table.remove(self.Data.Fader.Animation, 1);
            end
        else
            self:SetFaderAlpha(0);
        end
    end
end

---
-- Aktiviert den Cinematic Mode. Alle selektierten Entities werden gespeichert
-- und anschließend deselektiert. Optional wird die Kameraposition und die
-- Spielgeschwindigkeit ebenfalls gespeichert.
-- @within Internal
-- @local
--
function AddOnCutsceneSystem.Local:ActivateCinematicMode()
    self.Data.CinematicActive = true;
    
    local LoadScreenVisible = API.IsLoadscreenVisible();
    if LoadScreenVisible then
        XGUIEng.PopPage();
    end

    local ScreenX, ScreenY = GUI.GetScreenSize();
    XGUIEng.ShowWidget("/InGame/Root/3dOnScreenDisplay", 0);
    XGUIEng.ShowWidget("/InGame/Root/Normal", 0);
    XGUIEng.ShowWidget("/InGame/ThroneRoom", 1);
    XGUIEng.PushPage("/InGame/ThroneRoomBars", false);
    XGUIEng.PushPage("/InGame/ThroneRoomBars_2", false);
    XGUIEng.PushPage("/InGame/ThroneRoom/Main", false);
    XGUIEng.PushPage("/InGame/ThroneRoomBars_Dodge", false);
    XGUIEng.PushPage("/InGame/ThroneRoomBars_2_Dodge", false);
    XGUIEng.ShowWidget("/InGame/ThroneRoom/Main/Skip", 1);
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
    XGUIEng.ShowWidget("/InGame/ThroneRoom/Main/MissionBriefing/Text", 1);
    XGUIEng.ShowWidget("/InGame/ThroneRoom/Main/MissionBriefing/Title", 1);
    XGUIEng.ShowWidget("/InGame/ThroneRoom/Main/MissionBriefing/Objectives", 1);

    XGUIEng.SetText("/InGame/ThroneRoom/Main/MissionBriefing/Text", " ");
    XGUIEng.SetText("/InGame/ThroneRoom/Main/MissionBriefing/Title", " ");
    XGUIEng.SetText("/InGame/ThroneRoom/Main/MissionBriefing/Objectives", " ");

    local x,y = XGUIEng.GetWidgetScreenPosition("/InGame/ThroneRoom/Main/DialogTopChooseKnight/ChooseYourKnight");
    XGUIEng.SetWidgetScreenPosition("/InGame/ThroneRoom/Main/DialogTopChooseKnight/ChooseYourKnight", x, 65 * (ScreenY/1080));

    XGUIEng.SetWidgetPositionAndSize("/InGame/ThroneRoom/KnightInfo/Objectives", 2, 0, 2000, 20);
    XGUIEng.PushPage("/InGame/ThroneRoom/KnightInfo", false);
    XGUIEng.ShowAllSubWidgets("/InGame/ThroneRoom/KnightInfo", 0);
    XGUIEng.ShowWidget("/InGame/ThroneRoom/KnightInfo/Text", 1);
    XGUIEng.SetText("/InGame/ThroneRoom/KnightInfo/Text", " ");
    XGUIEng.SetWidgetPositionAndSize("/InGame/ThroneRoom/KnightInfo/Text", 200, 300, 1000, 10);
    XGUIEng.ShowWidget("/InGame/ThroneRoom/KnightInfo/LeftFrame", 1);
    XGUIEng.ShowAllSubWidgets("/InGame/ThroneRoom/KnightInfo/LeftFrame", 0);
    XGUIEng.ShowWidget("/InGame/ThroneRoom/KnightInfo/KnightBG", 1);
    XGUIEng.SetWidgetPositionAndSize("/InGame/ThroneRoom/KnightInfo/KnightBG", 0, 6000, 400, 600);
    XGUIEng.SetMaterialAlpha("/InGame/ThroneRoom/KnightInfo/KnightBG", 0, 0);

    BundleBriefingSystem.Local:SetBarStyle(self.Data.CurrentCutscene.BarOpacity, self.Data.CurrentCutscene.BigBars);

    if not self.Data.SkipButtonTextBackup then
        self.Data.SkipButtonTextBackup = XGUIEng.GetText("/InGame/ThroneRoom/Main/Skip");
    end

    GUI.ClearSelection();
    GUI.ForbidContextSensitiveCommandsInSelectionState();
    GUI.ActivateCutSceneState();
    GUI.SetFeedbackSoundOutputState(0);
    GUI.EnableBattleSignals(false);
    Input.CutsceneMode();
    Display.SetRenderFogOfWar(0);
    Display.SetUserOptionOcclusionEffect(0);
    Camera.SwitchCameraBehaviour(0);

    self:InitializeFader();
    self:SetFaderAlpha(0);

    if LoadScreenVisible then
        XGUIEng.PushPage("/LoadScreen/LoadScreen", false);
    end
end

---
-- Stoppt den Cinematic Mode. Die Selektion wird wiederhergestellt. Falls
-- aktiviert, werden auch Kameraposition und Spielgeschwindigkeit auf ihre
-- alten Werte zurückgesetzt.
-- @within Internal
-- @local
--
function AddOnCutsceneSystem.Local:DeactivateCinematicMode()
    self.Data.CinematicActive = false;

    if not self.Data.SkipButtonTextBackup then
        XGUIEng.SetText("/InGame/ThroneRoom/Main/Skip", self.Data.SkipButtonTextBackup);
        self.Data.SkipButtonTextBackup =  nil;
    end

    self.Data.Fader.To = 0;
    self:SetFaderAlpha(0);

    XGUIEng.PopPage();
    Camera.SwitchCameraBehaviour(0);
    Display.UseStandardSettings();
    Input.GameMode();
    GUI.EnableBattleSignals(true);
    GUI.SetFeedbackSoundOutputState(1);
    GUI.ActivateSelectionState();
    GUI.PermitContextSensitiveCommandsInSelectionState();
    Display.SetRenderFogOfWar(1);
    if Options.GetIntValue("Display", "Occlusion", 0) > 0 then
        Display.SetUserOptionOcclusionEffect(1);
    end

    XGUIEng.PopPage();
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
    XGUIEng.SetText("/InGame/ThroneRoom/Main/MissionBriefing/Objectives", " ");
end

---
-- Steuert die Nachricht bei aktiven schnellen Vorlauf von Cutscenes.
-- @within Internal
-- @local
--
function AddOnCutsceneSystem.Local.DisplayFastForwardMessage()
    if AddOnCutsceneSystem.Local.Data.CutsceneActive == true then
        if AddOnCutsceneSystem.Local.Data.FastForward.Active then
            -- Realzeit ermitteln
            local RealTime = API.RealTimeGetSecondsPassedSinceGameStart();
            if not AddOnCutsceneSystem.Local.Data.FastForward.RealTime then
                AddOnCutsceneSystem.Local.Data.FastForward.RealTime = RealTime;
            end
            -- Einrückung anpassen
            if AddOnCutsceneSystem.Local.Data.FastForward.RealTime < RealTime then
                AddOnCutsceneSystem.Local.Data.FastForward.Indent = AddOnCutsceneSystem.Local.Data.FastForward.Indent +1;
                if AddOnCutsceneSystem.Local.Data.FastForward.Indent > 4 then
                    AddOnCutsceneSystem.Local.Data.FastForward.Indent = 1;
                end
                AddOnCutsceneSystem.Local.Data.FastForward.RealTime = RealTime;
            end
            -- Message anzeigen
            local Text = "{cr}{cr}" ..API.Localize(AddOnCutsceneSystem.Text.FastFormardMessage);
            local Indent = string.rep("  ", AddOnCutsceneSystem.Local.Data.FastForward.Indent);
            XGUIEng.SetText("/InGame/ThroneRoom/Main/MissionBriefing/Objectives", Text..Indent.. ". . .");
        else
            XGUIEng.SetText("/InGame/ThroneRoom/Main/MissionBriefing/Objectives", " ");
        end
    end
end

-- -------------------------------------------------------------------------- --

Core:RegisterBundle("AddOnCutsceneSystem");
 
