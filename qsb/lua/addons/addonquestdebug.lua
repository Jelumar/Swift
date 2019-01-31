-- -------------------------------------------------------------------------- --
-- ########################################################################## --
-- #  Symfonia AddOnQuestDebug                                              # --
-- ########################################################################## --
-- -------------------------------------------------------------------------- --

---
-- Erweitert den mitgelieferten Debug des Spiels um eine Vielzahl nützlicher
-- neuer Möglichkeiten.
--
-- Die wichtigste Neuerung ist die Konsole, die es erlaubt Quests direkt über
-- die Eingabe von Befehlen zu steuern, einzelne einfache Lua-Kommandos im
-- Spiel auszuführen und sogar komplette Skripte zu laden.
--
-- <p><a href="API.ActivateDebugMode">Debug starten</a></p>
--
-- @within Modulbeschreibung
-- @set sort=true
--
AddOnQuestDebug = {};

API = API or {};
QSB = QSB or {};

AddOnQuestDebug = {
    Global =  {
        Data = {},
    },
    Local = {
        Data = {},
    },
}

-- -------------------------------------------------------------------------- --
-- User-Space                                                                 --
-- -------------------------------------------------------------------------- --

---
-- Aktiviert den Debug.
--
-- Der Developing Mode bietet viele Hotkeys und eine Konsole. Die Konsole ist
-- ein mächtiges Werkzeug. Es ist möglich tief in das Spiel einzugreifen und
-- sogar Funktionen während des Spiels zu überschreiben.
--
-- Die Konsole kann über <b>SHIFT + ^</b> geöffnet werden.
--
-- <p><b>Alias:</b> ActivateDebugMode</p>
--
-- <h3>Cheats</h3>
-- <table border="1">
-- <tr>
-- <td><b>Cheat</b></td>
-- <td><b>Beschreibung</b></td>
-- </tr>
-- <tr>
-- <td>SHIFT + ^</td>
-- <td>Konsole öffnen</td>
-- </tr>
-- <tr>
-- <td>CTRL + C</td>
-- <td>Zeitanzeige an/aus</td>
-- </tr>
-- <tr>
-- <td>CTRL + SHIFT + F</td>
-- <td>Nebel des Krieges abschalten</td>
-- </tr>
-- <tr>
-- <td>STRG + G</td>
-- <td>GUI ausschalten</td>
-- </tr>
-- <tr>
-- <td>ALT + F10</td>
-- <td>Selektiertes Gebäude anzünden</td>
-- </tr>
-- <tr>
-- <td>ALT + F11</td>
-- <td>Selektierte Einheit verwunden</td>
-- </tr>
-- <tr>
-- <td>ALT + F12</td>
-- <td>Alle Rechte freigeben / wieder sperren</td>
-- </tr>
-- <tr>
-- <td>CTRL + SHIFT + 1</td>
-- <td>FPS-Anzeige</td>
-- </tr>
-- <tr>
-- <td>CTRL + (Num) 4</td>
-- <td>Bogenschützen unter der Maus spawnen</td>
-- </tr>
-- <tr>
-- <td>CTRL + (Num) 5</td>
-- <td>Schwertkämpfer unter der Maus spawnen</td>
-- </tr>
-- <tr>
-- <td>CTRL + (Num) 6</td>
-- <td>Katapultkarren unter der Maus spawnen</td>
-- </tr>
-- <tr>
-- <td>CTRL + (Num) 7</td>
-- <td>Ramme unter der Maus spawnen</td>
-- </tr>
-- <tr>
-- <td>CTRL + (Num) 8</td>
-- <td>Belagerungsturm unter der Maus spawnen</td>
-- </tr>
-- <tr>
-- <td>CTRL + (Num) 9</td>
-- <td>Katapult unter der Maus spawnen</td>
-- </tr>
-- <tr>
-- <td>(Num) +</td>
-- <td>Spiel beschleunigen</td>
-- </tr>
-- <tr>
-- <td>(Num) -</td>
-- <td>Spiel verlangsamen</td>
-- </tr>
-- <tr>
-- <td>(Num) *</td>
-- <td>Geschwindigkeit zurücksetzen</td>
-- </tr>
-- <tr>
-- <td>CTRL + F1</td>
-- <td>+ 50 Gold</td>
-- </tr>
-- <tr>
-- <td>CTRL + F2</td>
-- <td>+ 10 Holz</td>
-- </tr>
-- <tr>
-- <td>CTRL + F3</td>
-- <td>+ 10 Stein</td>
-- </tr>
-- <tr>
-- <td>CTRL + F4</td>
-- <td>+ 10 Getreide</td>
-- </tr>
-- <tr>
-- <td>CTRL + F5</td>
-- <td>+ 10 Milch</td>
-- </tr>
-- <tr>
-- <td>CTRL + F6</td>
-- <td>+ 10 Kräuter</td>
-- </tr>
-- <tr>
-- <td>CTRL + F7</td>
-- <td>+ 10 Wolle</td>
-- </tr>
-- <tr>
-- <td>CTRL + F8</td>
-- <td>+ 10 auf alle Waren</td>
-- </tr>
-- <tr>
-- <td>SHIFT + F1</td>
-- <td>+ 10 Honig</td>
-- </tr>
-- <tr>
-- <td>SHIFT + F2</td>
-- <td>+ 10 Eisen</td>
-- </tr>
-- <tr>
-- <td>SHIFT + F3</td>
-- <td>+ 10 Fisch</td>
-- </tr>
-- <tr>
-- <td>SHIFT + F4</td>
-- <td>+ 10 Wild</td>
-- </tr>
-- <tr>
-- <td>CTRL + F9</td>
-- <td>Nahrung für selektiertes Gebäude erhöhen</td>
-- </tr>
-- <tr>
-- <td>SHIFT + F9</td>
-- <td>Nahrung für selektiertes Gebäude verringern</td>
-- </tr>
-- <tr>
-- <td>CTRL + F10</td>
-- <td>Kleidung für selektiertes Gebäude erhöhen</td>
-- </tr>
-- <tr>
-- <td>SHIFT + F10</td>
-- <td>Kleidung für selektiertes Gebäude verringern</td>
-- </tr>
-- <tr>
-- <td>CTRL + F11</td>
-- <td>Hygiene für selektiertes Gebäude erhöhen</td>
-- </tr>
-- <tr>
-- <td>SHIFT + F11</td>
-- <td>Hygiene für selektiertes Gebäude verringern</td>
-- </tr>
-- <tr>
-- <td>CTRL + F12</td>
-- <td>Unterhaltung für selektiertes Gebäude erhöhen</td>
-- </tr>
-- <tr>
-- <td>SHIFT + F12</td>
-- <td>Unterhaltung für selektiertes Gebäude verringern</td>
-- </tr>
-- <tr>
-- <td>ALT + CTRL + F10</td>
-- <td>Einnahmen des selektierten Gebäudes erhöhen</td>
-- </tr>
-- <tr>
-- <td>ALT + (Num) 1</td>
-- <td>Burg selektiert → Gold verringern, Werkstatt selektiert → Ware verringern</td>
-- </tr>
-- <tr>
-- <td>ALT + (Num) 2</td>
-- <td>Burg selektiert → Gold erhöhen, Werkstatt selektiert → Ware erhöhen</td>
-- </tr>
-- <tr>
-- <td>CTRL + ALT + 1</td>
-- <td>Kontrolle über Spieler 1</td>
-- </tr>
-- <tr>
-- <td>CTRL + ALT + 2</td>
-- <td>Kontrolle über Spieler 2</td>
-- </tr>
-- <tr>
-- <td>CTRL + ALT + 3</td>
-- <td>Kontrolle über Spieler 3</td>
-- </tr>
-- <tr>
-- <td>CTRL + ALT + 4</td>
-- <td>Kontrolle über Spieler 4</td>
-- </tr>
-- <tr>
-- <td>CTRL + ALT + 5</td>
-- <td>Kontrolle über Spieler 5</td>
-- </tr>
-- <tr>
-- <td>CTRL + ALT + 6</td>
-- <td>Kontrolle über Spieler 6</td>
-- </tr>
-- <tr>
-- <td>CTRL + ALT + 7</td>
-- <td>Kontrolle über Spieler 7</td>
-- </tr>
-- <tr>
-- <td>CTRL + ALT + 8</td>
-- <td>Kontrolle über Spieler 8</td>
-- </tr>
-- <tr>
-- <td>CTRL + (Num) 0</td>
-- <td>Kamera durchschalten</td>
-- </tr>
-- <tr>
-- <td>CTRL + (Num) 1</td>
-- <td>Kamerasprünge im RTS-Mode</td>
-- </tr>
-- <tr>
-- <td>CTRL + SHIFT + V</td>
-- <td>Territorien anzeigen</td>
-- </tr>
-- <tr>
-- <td>CTRL + SHIFT + B</td>
-- <td>Blocking anzeigen</td>
-- </tr>
-- <tr>
-- <td>CTRL + SHIFT + N</td>
-- <td>Gitter verstecken</td>
-- </tr>
-- <tr>
-- <td>CTRL + SHIFT + F9</td>
-- <td>DEBUG-Ausgabe einschalten</td>
-- </tr>
-- <tr>
-- <td>ALT + F9</td>
-- <td>Zufälligen Arbeiter verheiraten</td>
-- </tr>
-- </table>
--
-- <h3>Konsolenbefehle</h3>
-- <table border=1>
-- <tr>
-- <th><b>Befehl</b></th>
-- <th><b>Parameter</b></th>
-- <th><b>Beschreibung</b></th>
-- </tr>
-- <tr>
-- <td>clear</td>
-- <td></td>
-- <td>Entfernt alle Textnachrichten im Debug-Window.</td>
-- </tr>
-- <tr>
-- <td>diplomacy</td>
-- <td>PlayerID1, PlayerID2, Diplomacy</td>
-- <td>Ändert die Doplomatischen Beziehungen zwischen zwei Parteien</td>
-- </tr>
-- <tr>
-- <td>restartmap</td>
-- <td></td>
-- <td>Startet die Map sofort neu.</td>
-- </tr>
-- <tr>
-- <td>shareview</td>
-- <td>PlayerID1, PlayerID2, ActiveFlag</td>
-- <td>Teilt die Sicht zweier Parteien oder hebt es wieder auf.</td>
-- </tr>
-- <tr>
-- <td>setposition</td>
-- <td>Entity, Target</td>
-- <td>Versetzt ein Entity zu einer neuen Position.</td>
-- </tr>
-- <tr>
-- <td>version</td>
-- <td></td>
-- <td>Zeigt die Version der QSB an.</td>
-- </tr>
-- <tr>
-- <td>stop</td>
-- <td>QuestName</td>
-- <td>Unterbricht den angegebenen Quest.</td>
-- </tr>
-- <tr>
-- <td>start</td>
-- <td>QuestName</td>
-- <td>Startet den angegebenen Quest.</td>
-- </tr>
-- <tr>
-- <td>win</td>
-- <td>QuestName</td>
-- <td>Schließt den angegebenen Quest erfolgreich ab.</td>
-- </tr>
-- <tr>
-- <td>fail</td>
-- <td>QuestName</td>
-- <td>Lässt den angegebenen Quest fehlschlagen</td>
-- </tr>
-- <tr>
-- <td>restart</td>
-- <td>QuestName</td>
-- <td>Startet den angegebenen Quest neu.</td>
-- </tr>
-- <tr>
-- <td>printequal</td>
-- <td>Pattern</td>
-- <td>Gibt die Namen aller Quests aus, die das Pattern enthalten.</td>
-- </tr>
-- <tr>
-- <td>printactive</td>
-- <td></td>
-- <td>Gibt die namen aller aktiven Quests aus.</td>
-- </tr>
-- <tr>
-- <td>printdetail</td>
-- <td>QuestName</td>
-- <td>Zeigt genauere Informationen zum angegebenen Quest an.</td>
-- </tr>
-- <tr>
-- <td>gload</td>
-- <td>Path</td>
-- <td>Läd ein Skript zur Laufzeit ins globale Skript.</td>
-- </tr>
-- <tr>
-- <td>lload</td>
-- <td>Path</td>
-- <td>Läd ein Skript zur Laufzeit ins lokale Skript.</td>
-- </tr>
-- <tr>
-- <td>gexec</td>
-- <td>Command</td>
-- <td>Führt die Eingabe als Lua-Befahl im globalen Skript aus.</td>
-- </tr>
-- <tr>
-- <td>lexec</td>
-- <td>Command</td>
-- <td>Führt die Eingabe als Lua-Befahl im lokalen Skript aus.</td>
-- </tr>
-- <tr>
-- <td>collectgarbage</td>
-- <td></td>
-- <td>Löst die Garbage Collection von Lua aus.</td>
-- </tr>
-- <tr>
-- <td>dumpmemory</td>
-- <td></td>
-- <td>Zeigt die Größe des Speichers an, der von Lua belegt wird.</td>
-- </tr>
-- </table>
--
-- @param[type=boolean] _CheckAtRun Prüfe Quests zur Laufzeit
-- @param[type=boolean] _TraceQuests Aktiviert Questverfolgung
-- @param[type=boolean] _DevelopingCheats Aktiviert Cheats und Konsole
-- @param[type=boolean] _DevelopingShell Aktiviert Cheats und Konsole
-- @see Reward_DEBUG
-- @within Anwenderfunktionen
--
function API.ActivateDebugMode(_CheckAtRun, _TraceQuests, _DevelopingCheats, _DevelopingShell)
    if GUI then
        API.Bridge("API.ActivateDebugMode(" ..tostring(_CheckAtRun).. ", " ..tostring(_TraceQuests).. ", " ..tostring(_DevelopingCheats).. ", " ..tostring(_DevelopingShell).. ")");
        return;
    end
    AddOnQuestDebug.Global:ActivateDebug(_CheckAtRun, _TraceQuests, _DevelopingCheats, _DevelopingShell);
end
ActivateDebugMode = API.ActivateDebugMode;

-- -------------------------------------------------------------------------- --
-- Rewards                                                                    --
-- -------------------------------------------------------------------------- --

---
-- Aktiviert den Debug.
--
-- @param[type=boolean] _CheckAtRun Prüfe Quests zur Laufzeit
-- @param[type=boolean] _TraceQuests Aktiviert Questverfolgung
-- @param[type=boolean] _DevelopingCheats Aktiviert Cheats und Konsole
-- @param[type=boolean] _DevelopingShell Aktiviert Cheats und Konsole
-- @see API.ActivateDebugMode
--
-- @within Reward
--
function Reward_DEBUG(...)
    return b_Reward_DEBUG:new(...);
end

b_Reward_DEBUG = {
    Name = "Reward_DEBUG",
    Description = {
        en = "Reward: Start the debug mode. See documentation for more information.",
        de = "Lohn: Startet den Debug-Modus. Für mehr Informationen siehe Dokumentation.",
    },
    Parameter = {
        { ParameterType.Custom,     en = "Check quest while runtime", de = "Quests zur Laufzeit prüfen" },
        { ParameterType.Custom,     en = "Use quest trace", de = "Questverfolgung" },
        { ParameterType.Custom,     en = "Activate developing cheats", de = "Cheats aktivieren" },
        { ParameterType.Custom,     en = "Activate developing shell", de = "Eingabe aktivieren" },
    },
}

function b_Reward_DEBUG:GetRewardTable(__quest_)
    return { Reward.Custom, {self, self.CustomFunction} }
end

function b_Reward_DEBUG:AddParameter(_Index, _Parameter)
    if (_Index == 1) then
        self.CheckWhileRuntime = AcceptAlternativeBoolean(_Parameter)
    elseif (_Index == 2) then
        self.UseQuestTrace = AcceptAlternativeBoolean(_Parameter)
    elseif (_Index == 3) then
        self.DelepoingCheats = AcceptAlternativeBoolean(_Parameter)
    elseif (_Index == 3) then
        self.DelepoingShell = AcceptAlternativeBoolean(_Parameter)
    end
end

function b_Reward_DEBUG:CustomFunction(__quest_)
    API.ActivateDebugMode(self.CheckWhileRuntime, self.UseQuestTrace, self.DelepoingCheats, self.DelepoingShell);
end

function b_Reward_DEBUG:GetCustomData(_Index)
    return {"true","false"};
end

Core:RegisterBehavior(b_Reward_DEBUG);

-- -------------------------------------------------------------------------- --
-- Application-Space                                                          --
-- -------------------------------------------------------------------------- --

-- Global Script ---------------------------------------------------------------

---
-- Initalisiert das Bundle im globalen Skript.
--
-- @within Internal
-- @local
--
function AddOnQuestDebug.Global:Install()

    AddOnQuestDebug.Global.Data.DebugCommands = {
        -- groupless commands
        {"clear",               AddOnQuestDebug.Global.Clear,},
        {"diplomacy",           AddOnQuestDebug.Global.Diplomacy,},
        {"restartmap",          AddOnQuestDebug.Global.RestartMap,},
        {"shareview",           AddOnQuestDebug.Global.ShareView,},
        {"setposition",         AddOnQuestDebug.Global.SetPosition,},
        {"version",             AddOnQuestDebug.Global.ShowVersion,},
        -- quest control
        {"win",                 AddOnQuestDebug.Global.QuestSuccess,      true,},
        {"winall",              AddOnQuestDebug.Global.QuestSuccess,      false,},
        {"fail",                AddOnQuestDebug.Global.QuestFailure,      true,},
        {"failall",             AddOnQuestDebug.Global.QuestFailure,      false,},
        {"stop",                AddOnQuestDebug.Global.QuestInterrupt,    true,},
        {"stopall",             AddOnQuestDebug.Global.QuestInterrupt,    false,},
        {"start",               AddOnQuestDebug.Global.QuestTrigger,      true,},
        {"startall",            AddOnQuestDebug.Global.QuestTrigger,      false,},
        {"restart",             AddOnQuestDebug.Global.QuestReset,        true,},
        {"restartall",          AddOnQuestDebug.Global.QuestReset,        false,},
        {"printequal",          AddOnQuestDebug.Global.PrintQuests,       1,},
        {"printactive",         AddOnQuestDebug.Global.PrintQuests,       2,},
        {"printdetail",         AddOnQuestDebug.Global.PrintQuests,       3,},
        -- loading scripts into running game and execute them
        {"lload",               AddOnQuestDebug.Global.LoadScript,        true},
        {"gload",               AddOnQuestDebug.Global.LoadScript,        false},
        -- execute short lua commands
        {"lexec",               AddOnQuestDebug.Global.ExecuteCommand,    true},
        {"gexec",               AddOnQuestDebug.Global.ExecuteCommand,    false},
        -- garbage collector printouts
        {"collectgarbage",      AddOnQuestDebug.Global.CollectGarbage,},
        {"dumpmemory",          AddOnQuestDebug.Global.CountLuaLoad,},
    }

    for k,v in pairs(_G) do
        if type(v) == "table" and v.Name and k == "b_"..v.Name and v.CustomFunction and not v.CustomFunction2 then
            v.CustomFunction2 = v.CustomFunction;
            v.CustomFunction = function(self, __quest_)
                if AddOnQuestDebug.Global.Data.CheckAtRun then
                    if self.DEBUG and not self.FOUND_ERROR and self:DEBUG(__quest_) then
                        self.FOUND_ERROR = true;
                    end
                end
                if not self.FOUND_ERROR then
                    return self:CustomFunction2(__quest_);
                end
            end
        end
    end

    self:OverwriteCreateQuests();

    API.AddSaveGameAction(self.OnSaveGameLoad);
end

---
-- Aktiviert den Debug.
--
-- Der Developing Mode bietet viele Hotkeys und eine Konsole. Die Konsole ist
-- ein mächtiges Werkzeug. Es ist möglich tief in das Spiel einzugreifen und
-- sogar Funktionen während des Spiels zu überschreiben.
--
-- @param _CheckAtRun [boolean] Prüfe Quests zur Laufzeit
-- @param _TraceQuests [boolean] Aktiviert Questverfolgung
-- @param _Cheats [boolean] Aktiviert Cheats
-- @param _Shell [boolean] Aktiviert Konsole
-- @within Internal
-- @local
--
function AddOnQuestDebug.Global:ActivateDebug(_CheckAtRun, _TraceQuests, _Cheats, _Shell)
    if self.Data.DebugModeIsActive then
        return;
    end
    self.Data.DebugModeIsActive = true;

    self.Data.CheckAtRun       = _CheckAtRun == true;
    self.Data.TraceQuests      = _TraceQuests == true;
    self.Data.DevelopingCheats = _Cheats == true;
    self.Data.DevelopingShell  = _Shell == true;

    self:ActivateQuestTrace();
    self:ActivateDevelopingCheats();
    self:ActivateDevelopingShell();
end

---
-- Aktiviert die Questverfolgung. Jede Statusänderung wird am Bildschirm
-- angezeigt.
--
-- @within Internal
-- @local
--
function AddOnQuestDebug.Global:ActivateQuestTrace()
    if self.Data.TraceQuests then
        DEBUG_EnableQuestDebugKeys();
        DEBUG_QuestTrace(true);
    end
end

---
-- <p>Aktiviert die Cheats.</p>
-- <p>Es werden die Development-Cheats benutzt und um einige neue erweitert.</p>
--
-- @within Internal
-- @local
--
function AddOnQuestDebug.Global:ActivateDevelopingCheats()
    if self.Data.DevelopingCheats then
        Logic.ExecuteInLuaLocalState("AddOnQuestDebug.Local:ActivateDevelopingCheats()");
    end
end

---
-- <p>Aktiviert die Shell.</p>
-- <p>Der Debug stellt einige zusätzliche Tastenkombinationen bereit:</p>
-- <p>Die Konsole des Debug wird mit SHIFT + ^ geöffnet.</p>
-- <p>Die Konsole bietet folgende Kommandos:</p>
--
-- @within Internal
-- @local
--
function AddOnQuestDebug.Global:ActivateDevelopingShell()
    if self.Data.DevelopingShell then
        Logic.ExecuteInLuaLocalState("AddOnQuestDebug.Local:ActivateDevelopingShell()");
    end
end

---
-- Ließt eingegebene Kommandos und führt entsprechende Funktionen aus.
--
-- Für die Zerlegung der Kommandizeile wird der Tokenizer benutzt.
--
-- Für die Nutzung im LuaDebugger des Spiels, müssen Kommandos mit
-- eval() aufgerufen werden.
--
-- @within Internal
-- @local
-- @see AddOnQuestDebug.Global:Tokenize
--
function AddOnQuestDebug.Global:Parser(_Input)
    local Results = {};
    local Commands = self:Tokenize(_Input);
    for k, v in pairs(Commands) do
        local Action = string.lower(v[1]);
        for i= 1, #AddOnQuestDebug.Global.Data.DebugCommands, 1 do
            if v[1] == AddOnQuestDebug.Global.Data.DebugCommands[i][1] then
                local SelectedCommand = AddOnQuestDebug.Global.Data.DebugCommands[i];
                for j=2, #v, 1 do
                    local Number = tonumber(v[j]);
                    if Number then
                        v[j] = Number;
                    end
                end

                local CommandResult = SelectedCommand[2](v, SelectedCommand[3]);
                if CommandResult then
                    table.insert(Results, CommandResult);
                end
            end
        end
    end
    return Results;
end
function eval(_Input)
    return AddOnQuestDebug.Global:Parser(_Input);
end

---
-- Zerlegt den Eingabestring in einzelne Kommandos und gibt diese als Table
-- zurück. Unterschiedliche Kommandos werden mit && abgetrennt und entsprechend
-- als mehrere Einträge im Table angelegt. Mit dem Wiederholungszeichen &
-- wird das Komanndo für alle angegebenen Eingaben wiederholt.
--
-- Beispiel:
--
-- <pre>
-- Eingabe:
-- "win QuestA & QuestB && fail QuestC && stop QuestD & Quest E"
--
-- Ausgabe:
-- {
-- {"win", "QuestA"}
-- {"win", "QuestB"}
-- {"fail", "QuestC"}
-- {"stop", "QuestD"}
-- {"stop", "QuestE"}
-- }</pre>
--
-- @return Table mit Tokens
-- @within Internal
-- @local
--
function AddOnQuestDebug.Global:Tokenize(_Input)
    local Commands = {};
    local DAmberCommands = {_Input};
    local AmberCommands = {_Input};

    -- parse & delimiter
    local s, e = string.find(_Input, "%s+&&%s+");
    if s then
        DAmberCommands = {};
        while (s) do
            local tmp = string.sub(_Input, 1, s-1);
            table.insert(DAmberCommands, tmp);
            _Input = string.sub(_Input, e+1);
            s, e = string.find(_Input, "%s+&&%s+");
        end
        if string.len(_Input) > 0 then 
            table.insert(DAmberCommands, _Input);
        end
    end

    -- parse & delimiter
    if #DAmberCommands > 0 then
        AmberCommands = {};
    end
    for i= 1, #DAmberCommands, 1 do
        local s, e = string.find(DAmberCommands[i], "%s+&%s+");
        if s then
            local LastCommand = "";
            while (s) do
                local tmp = string.sub(DAmberCommands[i], 1, s-1);
                table.insert(AmberCommands, LastCommand .. tmp);
                if string.find(tmp, " ") then
                    LastCommand = string.sub(tmp, 1, string.find(tmp, " ")-1) .. " ";
                end
                DAmberCommands[i] = string.sub(DAmberCommands[i], e+1);
                s, e = string.find(DAmberCommands[i], "%s+&%s+");
            end
            if string.len(DAmberCommands[i]) > 0 then 
                table.insert(AmberCommands, LastCommand .. DAmberCommands[i]);
            end
        else
            table.insert(AmberCommands, DAmberCommands[i]);
        end
    end

    -- parse spaces
    for i= 1, #AmberCommands, 1 do
        local CommandLine = {};
        local s, e = string.find(AmberCommands[i], "%s+");
        if s then
            while (s) do
                local tmp = string.sub(AmberCommands[i], 1, s-1);
                table.insert(CommandLine, tmp);
                AmberCommands[i] = string.sub(AmberCommands[i], e+1);
                s, e = string.find(AmberCommands[i], "%s+");
            end
            table.insert(CommandLine, AmberCommands[i]);
        else
            table.insert(CommandLine, AmberCommands[i]);
        end
        table.insert(Commands, CommandLine);
    end

    return Commands;
end

---
-- Führt die Garbage Collection aus um nicht benötigten Speicher freizugeben.
--
-- Die Garbage Collection wird von Lua automatisch in Abständen ausgeführt.
-- Mit dieser Funktion kann man nachhelfen, sollten die Intervalle zu lang
-- sein und der Speicher vollgemüllt werden.
--
-- @within Internal
-- @local
--
function AddOnQuestDebug.Global.CollectGarbage()
    collectgarbage();
    Logic.ExecuteInLuaLocalState("AddOnQuestDebug.Local:CollectGarbage()");
end

---
-- Gibt die Speicherauslastung von Lua zurück.
--
-- @within Internal
-- @local
--
function AddOnQuestDebug.Global.CountLuaLoad()
    Logic.ExecuteInLuaLocalState("AddOnQuestDebug.Local:CountLuaLoad()");
    local LuaLoad = collectgarbage("count");
    API.StaticNote("Global Lua Size: " ..LuaLoad);
end

---
-- Zeigt alle Quests nach einem Filter an.
--
-- @within Internal
-- @local
--
function AddOnQuestDebug.Global.PrintQuests(_Arguments, _Flags)
    local questText = ""
    local counter   = 0;

    local accept = function(_quest, _state)
        return _quest.State == _state;
    end

    if _Flags == 3 then
        return AddOnQuestDebug.PrintDetail(_Arguments);
    end

    if _Flags == 1 then
        accept = function(_quest, _arg)
            return string.find(_quest.Identifier, _arg);
        end
    elseif _Flags == 2 then
        _Arguments[2] = QuestState.Active;
    end

    for i= 1, Quests[0] do
        if Quests[i] then
            if accept(Quests[i], _Arguments[2]) then
                counter = counter +1;
                if counter <= 15 then
                    questText = questText .. ((questText:len() > 0 and "{cr}") or "");
                    questText = questText ..  Quests[i].Identifier;
                end
            end
        end
    end

    if counter >= 15 then
        questText = questText .. "{cr}{cr}(" .. (counter-15) .. " weitere Ergebnis(se) gefunden!)";
    end

    Logic.ExecuteInLuaLocalState([[
        GUI.ClearNotes()
        GUI.AddStaticNote("]]..questText..[[")
    ]]);

    questText = string.gsub(questText, "{cr}", "\n");
    return questText;
end

---
--
--
function AddOnQuestDebug.Global.PrintDetail(_Arguments)
    local questText = "";
    local questID = GetQuestID(string.gsub(_Arguments[2], " ", ""));

    if Quests[questID] then
        local state        = (Quests[questID].State == QuestState.NotTriggered and "not triggered") or
                              (Quests[questID].State == QuestState.Active and "active") or
                                "over";
        local result        = (Quests[questID].Result == QuestResult.Success and "success") or
                              (Quests[questID].Result == QuestResult.Failure and "failure") or
                              (Quests[questID].Result == QuestResult.Interrupted and "interrupted") or
                                "undecided";

        questText = questText .. "Name: " .. Quests[questID].Identifier .. "{cr}";
        questText = questText .. "State: " .. state .. "{cr}";
        questText = questText .. "Result: " .. result .. "{cr}";
        questText = questText .. "Sender: " .. Quests[questID].SendingPlayer .. "{cr}";
        questText = questText .. "Receiver: " .. Quests[questID].ReceivingPlayer .. "{cr}";
        questText = questText .. "Duration: " .. Quests[questID].Duration .. "{cr}";
        questText = questText .. "Start Text: "  .. tostring(Quests[questID].QuestStartMsg) .. "{cr}";
        questText = questText .. "Failure Text: " .. tostring(Quests[questID].QuestFailureMsg) .. "{cr}";
        questText = questText .. "Success Text: " .. tostring(Quests[questID].QuestSuccessMsg) .. "{cr}";
        questText = questText .. "Description: " .. tostring(Quests[questID].QuestDescription) .. "{cr}";
        questText = questText .. "Objectives: " .. #Quests[questID].Objectives .. "{cr}";
        questText = questText .. "Reprisals: " .. #Quests[questID].Reprisals .. "{cr}";
        questText = questText .. "Rewards: " .. #Quests[questID].Rewards .. "{cr}";
        questText = questText .. "Triggers: " .. #Quests[questID].Triggers .. "{cr}";
    else
        questText = questText .. tostring(_Arguments[2]) .. " not found!";
    end

    Logic.ExecuteInLuaLocalState([[
        GUI.ClearNotes()
        GUI.AddStaticNote("]]..questText..[[")
    ]]);

    questText = string.gsub(questText, "{cr}", "\n");
    return questText;
end

---
-- Läd ein Lua-Skript in das Enviorment.
--
-- @within Internal
-- @local
--
function AddOnQuestDebug.Global.LoadScript(_Arguments, _Flags)
    if _Arguments[2] then
        if _Flags == true then
            Logic.ExecuteInLuaLocalState([[Script.Load("]].._Arguments[2]..[[")]]);
        elseif _Flags == false then
            Script.Load(_Arguments[2]);
        end
        if not AddOnQuestDebug.Global.Data.SurpassMessages then
            Logic.DEBUG_AddNote("load script ".._Arguments[2]);
        end
    end
end

---
-- Führt ein Lua-Kommando im Enviorment aus.
--
-- @within Internal
-- @local
--
function AddOnQuestDebug.Global.ExecuteCommand(_Arguments, _Flags)
    if _Arguments[2] then
        local args = "";
        for i=2,#_Arguments do
            args = args .. " " .. _Arguments[i];
        end

        if _Flags == true then
            Logic.ExecuteInLuaLocalState([[]]..args..[[]]);
        elseif _Flags == false then
            Logic.ExecuteInLuaLocalState([[GUI.SendScriptCommand("]]..args..[[")]]);
        end
    end
end

---
-- Konsolenbefehl: Leert das Debug Window.
--
-- @within Internal
-- @local
--
function AddOnQuestDebug.Global.Clear()
    Logic.ExecuteInLuaLocalState("GUI.ClearNotes()");
end

---
-- Konsolenbefehl: Ändert die Diplomatie zwischen zwei Spielern.
--
-- @within Internal
-- @local
--
function AddOnQuestDebug.Global.Diplomacy(_Arguments)
    SetDiplomacyState(_Arguments[2], _Arguments[3], _Arguments[4]);
end

---
--  Konsolenbefehl: Startet die Map umgehend neu.
--
-- @within Internal
-- @local
--
function AddOnQuestDebug.Global.RestartMap()
    Logic.ExecuteInLuaLocalState("Framework.RestartMap()");
end

---
-- Konsolenbefehl: Aktiviert/deaktiviert die geteilte Sicht zweier Spieler.
--
-- @within Internal
-- @local
--
function AddOnQuestDebug.Global.ShareView(_Arguments)
    Logic.SetShareExplorationWithPlayerFlag(_Arguments[2], _Arguments[3], _Arguments[4]);
end

---
-- Konsolenbefehl: Setzt die Position eines Entity.
--
-- @within Internal
-- @local
--
function AddOnQuestDebug.Global.SetPosition(_Arguments)
    local entity = GetID(_Arguments[2]);
    local target = GetID(_Arguments[3]);
    local x,y,z  = Logic.EntityGetPos(target);
    if Logic.IsBuilding(target) == 1 then
        x,y = Logic.GetBuildingApproachPosition(target);
    end
    Logic.DEBUG_SetSettlerPosition(entity, x, y);
end

---
-- Konsolenbefehl: Zeigt die Version der QSB an.
--
-- @within Internal
-- @local
--
function AddOnQuestDebug.Global.ShowVersion()
    API.Bridge("GUI.AddStaticNote(QSB.Version)");
    return QSB.Version;
end

---
-- Sucht nach allen Quests, auf die den angegebenen Namen enthalten und gibt
-- die Namen der gefundenen Quests zurück.
--
-- @within Internal
-- @local
--
function AddOnQuestDebug.Global.FindQuestNames(_Pattern, _ExactName)
    local FoundQuests = FindQuestsByName(_Pattern, _ExactName);
    if #FoundQuests == 0 then
        return {};
    end
    local NamesOfFoundQuests = {};
    for i= 1, #FoundQuests, 1 do
        table.insert(NamesOfFoundQuests, FoundQuests[i].Identifier);
    end
    return NamesOfFoundQuests;
end

---
-- Beendet einen Quest, oder mehrere Quests mit ähnlichen Namen, erfolgreich.
--
-- @within Internal
-- @local
--
function AddOnQuestDebug.Global.QuestSuccess(_QuestName, _ExactName)
    local FoundQuests = AddOnQuestDebug.Global.FindQuestNames(_QuestName[2], _ExactName);
    if #FoundQuests == 0 then
        return;
    end
    API.WinAllQuests(unpack(FoundQuests));
end

---
-- Lässt einen Quest, oder mehrere Quests mit ähnlichen Namen, fehlschlagen.
--
-- @within Internal
-- @local
--
function AddOnQuestDebug.Global.QuestFailure(_QuestName, _ExactName)
    local FoundQuests = AddOnQuestDebug.Global.FindQuestNames(_QuestName[2], _ExactName);
    if #FoundQuests == 0 then
        return;
    end
    API.FailAllQuests(unpack(FoundQuests));
end

---
-- Stoppt einen Quest, oder mehrere Quests mit ähnlichen Namen.
--
-- @within Internal
-- @local
--
function AddOnQuestDebug.Global.QuestInterrupt(_QuestName, _ExactName)
    local FoundQuests = AddOnQuestDebug.Global.FindQuestNames(_QuestName[2], _ExactName);
    if #FoundQuests == 0 then
        return;
    end
    API.StopAllQuests(unpack(FoundQuests));
end

---
-- Startet einen Quest, oder mehrere Quests mit ähnlichen Namen.
--
-- @within Internal
-- @local
--
function AddOnQuestDebug.Global.QuestTrigger(_QuestName, _ExactName)
    local FoundQuests = AddOnQuestDebug.Global.FindQuestNames(_QuestName[2], _ExactName);
    if #FoundQuests == 0 then
        return;
    end
    API.StartAllQuests(unpack(FoundQuests));
end

---
-- Setzt den Quest / die Quests zurück, sodass er neu gestartet werden kann.
--
-- @within Internal
-- @local
--
function AddOnQuestDebug.Global.QuestReset(_QuestName, _ExactName)
    local FoundQuests = AddOnQuestDebug.Global.FindQuestNames(_QuestName[2], _ExactName);
    if #FoundQuests == 0 then
        return;
    end
    API.RestartAllQuests(unpack(FoundQuests));
end

---
-- Überschreibt CreateQuests, sodass Assistentenquests über das Skript erzeugt
-- werden um diese sinnvoll überprüfen zu können.
--
-- @within Internal
-- @local
--
function AddOnQuestDebug.Global.OverwriteCreateQuests()
    AddOnQuestDebug.Global.Data.CreateQuestsOriginal = CreateQuests;
    CreateQuests = function()
        local QuestNames = Logic.Quest_GetQuestNames()
        for i=1, #QuestNames, 1 do
            local QuestName = QuestNames[i]
            local QuestData = {Logic.Quest_GetQuestParamter(QuestName)};

            -- Behavior ermitteln
            local Behaviors = {};
            local Amount = Logic.Quest_GetQuestNumberOfBehaviors(QuestName);
            if Amount > 0 then
                for j=0, Amount-1, 1 do
                    local Name = Logic.Quest_GetQuestBehaviorName(QuestName, j);
                    local Template = GetBehaviorTemplateByName(Name);
                    assert(Template ~= nil);

                    local Parameters = Logic.Quest_GetQuestBehaviorParameter(QuestName, j);
                    table.insert(Behaviors, Template:new(unpack(Parameters)));
                end

                API.CreateQuest {
                    Name        = QuestName,
                    Sender      = QuestData[1],
                    Receiver    = QuestData[2],
                    Time        = QuestData[4],
                    Description = QuestData[5],
                    Suggestion  = QuestData[6],
                    Failure     = QuestData[7],
                    Success     = QuestData[8],

                    unpack(Behaviors),
                };
            end
        end
    end
end

---
-- Stellt den Debug nach dem Laden eines Spielstandes wieder her.
--
-- @param _Arguments Argumente der überschriebenen Funktion
-- @param _Original  Referenz auf Save-Funktion
-- @within Internal
-- @local
--
function AddOnQuestDebug.Global.OnSaveGameLoad(_Arguments, _Original)
    AddOnQuestDebug.Global:ActivateDevelopingCheats();
    AddOnQuestDebug.Global:ActivateDevelopingShell();
    AddOnQuestDebug.Global:ActivateQuestTrace();
end

-- Local Script ----------------------------------------------------------------

---
-- Initalisiert das Bundle im lokalen Skript.
--
-- @within Internal
-- @local
--
function AddOnQuestDebug.Local:Install()

end

---
-- Führt die Garbage Collection aus um nicht benötigten Speicher freizugeben.
--
-- Die Garbage Collection wird von Lua automatisch in Abständen ausgeführt.
-- Mit dieser Funktion kann man nachhelfen, sollten die Intervalle zu lang
-- sein und der Speicher vollgemüllt werden.
--
-- @within Internal
-- @local
--
function AddOnQuestDebug.Local:CollectGarbage()
    collectgarbage();
end

---
-- Gibt die Speicherauslastung von Lua zurück.
--
-- @within Internal
-- @local
--
function AddOnQuestDebug.Local:CountLuaLoad()
    local LuaLoad = collectgarbage("count");
    API.StaticNote("Local Lua Size: " ..LuaLoad)
end

---
-- Aktiviert die Development Cheats des Spiels.
--
-- @see AddOnQuestDebug.Global:ActivateDevelopingCheats
-- @within Internal
-- @local
--
function AddOnQuestDebug.Local:ActivateDevelopingCheats()
    KeyBindings_EnableDebugMode(1);
    KeyBindings_EnableDebugMode(2);
    KeyBindings_EnableDebugMode(3);
    XGUIEng.ShowWidget("/InGame/Root/Normal/AlignTopLeft/GameClock",1);
end

---
-- Aktiviert die Kommandokonsole.
--
-- @see AddOnQuestDebug.Global:ActivateDevelopingShell
-- @within Internal
-- @local
--
function AddOnQuestDebug.Local:ActivateDevelopingShell()
    GUI_Chat.Abort = function() end

    GUI_Chat.Confirm = function()
        Input.GameMode();
        XGUIEng.ShowWidget("/InGame/Root/Normal/ChatInput",0);
        AddOnQuestDebug.Local.Data.ChatBoxInput = XGUIEng.GetText("/InGame/Root/Normal/ChatInput/ChatInput");
        g_Chat.JustClosed = 1;
        Game.GameTimeSetFactor( GUI.GetPlayerID(), 1 );
    end

    QSB_DEBUG_InputBoxJob = function()
        if not AddOnQuestDebug.Local.Data.BoxShown then
            Input.ChatMode();
            Game.GameTimeSetFactor( GUI.GetPlayerID(), 0 );
            XGUIEng.ShowWidget("/InGame/Root/Normal/ChatInput", 1);
            XGUIEng.SetText("/InGame/Root/Normal/ChatInput/ChatInput", "");
            XGUIEng.SetFocus("/InGame/Root/Normal/ChatInput/ChatInput");
            AddOnQuestDebug.Local.Data.BoxShown = true
        elseif AddOnQuestDebug.Local.Data.ChatBoxInput then
            AddOnQuestDebug.Local.Data.ChatBoxInput = string.gsub(AddOnQuestDebug.Local.Data.ChatBoxInput,"'","\'");
            GUI.SendScriptCommand("AddOnQuestDebug.Global:Parser('"..AddOnQuestDebug.Local.Data.ChatBoxInput.."')");
            AddOnQuestDebug.Local.Data.BoxShown = nil;
            return true;
        end
    end

    Input.KeyBindDown(Keys.ModifierShift + Keys.OemPipe, "StartSimpleJob('QSB_DEBUG_InputBoxJob')", 2);
end

Core:RegisterBundle("AddOnQuestDebug");
