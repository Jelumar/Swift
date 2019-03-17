-- -------------------------------------------------------------------------- --
-- ########################################################################## --
-- # Global Script - <MAPNAME>                                              # --
-- # © <AUTHOR>                                                             # --
-- ########################################################################## --
-- -------------------------------------------------------------------------- --

-- Trage hier den Pfad ein, wo Deine Inhalte liegen.
g_ContentPath = "maps/externalmap/" ..Framework.GetCurrentMapName() .. "/";

-- Globaler Namespace für Deine Variablen
g_Mission = {};

-- -------------------------------------------------------------------------- --

-- Läd die Kartenskripte der Mission.
function Mission_LoadFiles()
    Script.Load("E:/Repositories/symfonia/var/qsb.lua");

    -- Füge hier weitere Skriptdateien hinzu.
end

-- Setzt Voreinstellungen für KI-Spieler.
-- (Spielerfarbe, AI-Blacklist, etc)
function Mission_InitPlayers()
end

-- Setzt den Monat, mit dem das Spiel beginnt.
function Mission_SetStartingMonth()
    Logic.SetMonthOffset(3);
end

-- Setzt Handelsangebote der Nichtspielerparteien.
function Mission_InitMerchants()
end

-- Wird aufgerufen, wenn das Spiel gestartet wird.
function Mission_FirstMapAction()
    Mission_LoadFiles();
    API.Install();
    InitKnightTitleTables();

    -- Mapeditor-Einstellungen werden geladen
    if Framework.IsNetworkGame() ~= true then
        Startup_Player();
        Startup_StartGoods();
        Startup_Diplomacy();
    end

    API.ActivateDebugMode(true, true, true, true);

    -- Startet die Mapeditor-Quests
    CreateQuests();

    MyWeatherEvent = WeatherEvent:New();
    MyWeatherEvent.Loop = function(_Data)
        if _Data.Duration <= 36 then
            BundleWeatherManipulation.Global:AddEvent(MyWeatherEvent, "EventA", 120);
            BundleWeatherManipulation.Global:StopEvent();
            BundleWeatherManipulation.Global:ActivateEvent();
        end
    end
    
    BundleWeatherManipulation.Global:AddEvent(MyWeatherEvent, "EventA", 120);
    -- BundleWeatherManipulation.Global:AddEvent(MyWeatherEvent, "EventA", 120);
end

-- -------------------------------------------------------------------------- --

