-- -------------------------------------------------------------------------- --
-- ########################################################################## --
-- #  Symfonia Core                                                         # --
-- ########################################################################## --
-- -------------------------------------------------------------------------- --

---
-- Die Hauptaufgabe des Framework ist es, Funktionen zur Installation und der
-- Verwaltung der einzelnen Bundles bereitzustellen. Bundles sind in sich
-- geschlossene Module, die wenig bis gar keine Abhänigkeiten haben. Damit
-- das funktioniert, muss das Framework auch allgemeingültige Funktionen
-- bereitstellen, auf die Bundles aufbauen können.
--
-- Im Framework werden zudem überschriebene Spielfunktionen angelegt und so
-- aufbereitet, dass Bundles ihre Inhalte einfach ergänzen können. Dies wird
-- jedoch nicht für alle Funktionen des Spiels möglich sein.
--
-- Wie die einzelnen Bundles ist auch das Framework in einen User- und einen
-- Application-Space aufgeteilt. Der User-Space enthält Funktionen innerhalb
-- der Bibliothek "API". Alle Bundles ergänzen ihre User-Space-Funktionen dort.
-- Außer den Aliases auf API-Funktionen und den Behavior-Funktionen sind keine
-- anderen öffentlichen Funktionen für den Anwendern sichtbar zu machen!
-- Sinn des User-Space ist es, Funktionsaufrufe, die zum Teil nur in einer
-- Skriptumgebung bekannt sind zu verallgemeinern. Wird die Funktion nun aus
-- der falschen Umgebung aufgerufen, wird der Aufruf an die richtige Umgebung
-- weitergereicht oder, falls dies nicht möglich ist, abgebrochen. Dies soll
-- Fehler vermeiden.
--
-- Im Application-Space liegen die privaten Funktionen und Variablen, die
-- nicht in der Dokumentation erscheinen. Sie sind mit einem Local-Tag zu
-- versehen! Der Nutzer soll diese Funktionen in der Regel nicht anfassen,
-- daher muss er auch nicht wissen, dass es sie gibt!
--
-- Ziel der Teilung zwischen User-Space und Application-Space ist es, dem
-- Anwender eine saubere und leicht verständliche Oberfläche zu Bieten, mit
-- der er einfach arbeiten kann. Kenntnis über die komplexen Prozesse hinter
-- den Kulissen sind dafür nicht notwendig.
--
-- @script SymfoniaCore
-- @set sort=true
--

API = API or {};
QSB = QSB or {};

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

-- -------------------------------------------------------------------------- --
-- User-Space                                                                 --
-- -------------------------------------------------------------------------- --

---
-- Initialisiert alle verfügbaren Bundles und führt ihre Install-Methode aus.
--
-- Bundles werden immer getrennt im globalen und im lokalen Skript gestartet.
-- Diese Funktion muss zwingend im globalen und lokalen Skript ausgeführt
-- werden, bevor die QSB verwendet werden kann.
-- @within User-Space
--
function API.Install()
    Core:InitalizeBundles();
end

-- Tables --------------------------------------------------------------------

---
-- Kopiert eine komplette Table und gibt die Kopie zurück. Wenn ein Ziel
-- angegeben wird, ist die zurückgegebene Table eine vereinigung der 2
-- angegebenen Tables.
-- Die Funktion arbeitet rekursiv und ist für beide Arten von Index. Die
-- Funktion kann benutzt werden, um Klassen zu instanzieren.
--
-- <b>Alias:</b> CopyTableRecursive
--
-- @param _Source    Quelltabelle
-- @param _Dest      Zieltabelle
-- @return Kopie der Tabelle
-- @within User-Space
-- @usage Table = {1, 2, 3, {a = true}}
-- Copy = API.InstanceTable(Table)
--
function API.InstanceTable(_Source, _Dest)
    _Dest = _Dest or {};
    assert(type(_Source) == "table")
    assert(type(_Dest) == "table")
    
    for k, v in pairs(_Source) do
        if type(v) == "table" then
            _Dest[k] = API.InstanceTable(v);
        else
            _Dest[k] = v;
        end
    end
    return _Dest;
end
CopyTableRecursive = API.InstanceTable;

---
-- Sucht in einer Table nach einem Wert. Das erste Aufkommen des Suchwerts
-- wird als Erfolg gewertet.
--
-- <b>Alias:</b> Inside
--
-- @param _Data     Datum, das gesucht wird
-- @param _Table    Tabelle, die durchquert wird
-- @return booelan: Wert gefunden
-- @within User-Space
-- @usage Table = {1, 2, 3, {a = true}}
-- local Found = API.TraverseTable(3, Table)
--
function API.TraverseTable(_Data, _Table)
    for k,v in pairs(_Table) do
        if v == _Data then
            return true;
        end
    end
    return false;
end
Inside = API.TraverseTable;

---
-- Schreibt ein genaues Abbild der Table ins Log. Funktionen, Threads und
-- Metatables werden als Adresse geschrieben.
--
-- @param _Table Tabelle, die gedumpt wird
-- @param _Name Optionaler Name im Log
-- @within User-Space
-- @usage Table = {1, 2, 3, {a = true}}
-- API.DumpTable(Table)
--
function API.DumpTable(_Table, _Name)
    local Start = "{";
    if _Name then
        Start = _Name.. " = \n" ..Start;
    end
    Framework.WriteToLog(Start);
    
    for k, v in pairs(_Table) do
        if type(v) == "table" then
            Framework.WriteToLog("[" ..k.. "] = ");
            API.DumpTable(v);
        elseif type(v) == "string" then
            Framework.WriteToLog("[" ..k.. "] = \"" ..v.. "\"");
        else
            Framework.WriteToLog("[" ..k.. "] = " ..tostring(v));
        end
    end
    Framework.WriteToLog("}");
end

-- Quests ----------------------------------------------------------------------

---
-- Gibt die ID des Quests mit dem angegebenen Namen zurück. Existiert der
-- Quest nicht, wird nil zurückgegeben.
--
-- <b>Alias:</b> GetQuestID
--
-- @param _Name     Identifier des Quest
-- @return number: ID des Quest
-- @within User-Space
--
function API.GetQuestID(_Name)
    for i=1, Quests[0] do
        if Quests[i].Identifier == _Name then
            return i;
        end
    end
end
GetQuestID = API.GetQuestID;

---
-- Prüft, ob die ID zu einem Quest gehört bzw. der Quest existiert. Es kann
-- auch ein Questname angegeben werden.
--
-- <b>Alias:</b> IsValidQuest
--
-- @param _QuestID   ID oder Name des Quest
-- @return boolean: Quest existiert
-- @within User-Space
--
function API.IsValidateQuest(_QuestID)
    return Quests[_QuestID] ~= nil or Quests[self:GetQuestID(_QuestID)] ~= nil;
end
IsValidQuest = API.IsValidateQuest;

---
-- Lässt eine Liste von Quests fehlschlagen.
--
-- Der Status wird auf Over und das Resultat auf Failure gesetzt.
--
-- <b>Alias:</b> FailQuestsByName
--
-- @param ...  Liste mit Quests
-- @within User-Space
--
function API.FailAllQuests(...)
    for i=1, #args, 1 do
        API.FailQuest(args[i]);
    end
end
FailQuestsByName = API.FailAllQuests;

---
-- Lässt den Quest fehlschlagen.
--
-- Der Status wird auf Over und das Resultat auf Failure gesetzt.
--
-- <b>Alias:</b> FailQuestByName
--
-- @param _QuestName  Name des Quest
-- @within User-Space
--
function API.FailQuest(_QuestName)
    local Quest = Quests[GetQuestID(_QuestName)];
    if Quest then
        Quest:RemoveQuestMarkers();
        Quest:Fail();
    end
end
FailQuestByName = API.FailQuest;

---
-- Startet eine Liste von Quests neu.
--
-- <b>Alias:</b> StartQuestsByName
--
-- @param ...  Liste mit Quests
-- @within User-Space
--
function API.RestartAllQuests(...)
    for i=1, #args, 1 do
        API.RestartQuest(args[i]);
    end
end
RestartQuestsByName = API.RestartAllQuests;

---
-- Startet den Quest neu.
--
-- Der Quest muss beendet sein um ihn wieder neu zu starten. Wird ein Quest
-- neu gestartet, müssen auch alle Trigger wieder neu ausgelöst werden, außer
-- der Quest wird manuell getriggert.
--
-- Alle Änderungen an Standardbehavior müssen hier berücksichtigt werden. Wird 
-- ein Standardbehavior in einem Bundle verändern, muss auch diese Funktion 
-- angepasst oder überschrieben werden.
--
-- <b>Alias:</b> RestartQuestByName
--
-- @param _QuestName  Name des Quest
-- @within User-Space
--
function API.RestartQuest(_QuestName)
    local QuestID = GetQuestID(_QuestName);
    local Quest = Quests[QuestID];
    if Quest then
        if Quest.Objectives then
            local questObjectives = Quest.Objectives;
            for i = 1, questObjectives[0] do
                local objective = questObjectives[i];
                objective.Completed = nil
                local objectiveType = objective.Type;
                if objectiveType == Objective.Deliver then
                    local data = objective.Data;
                    data[3] = nil
                    data[4] = nil
                    data[5] = nil
                elseif g_GameExtraNo and g_GameExtraNo >= 1 and objectiveType == Objective.Refill then
                    objective.Data[2] = nil
                elseif objectiveType == Objective.Protect or objectiveType == Objective.Object then
                    local data = objective.Data;
                    for j=1, data[0], 1 do
                        data[-j] = nil
                    end
                elseif objectiveType == Objective.DestroyEntities and objective.Data[1] ~= 1 and objective.DestroyTypeAmount then
                    objective.Data[3] = objective.DestroyTypeAmount;

                elseif objectiveType == Objective.Distance then
                    if objective.Data[1] == -65565 then
                        objective.Data[4].NpcInstance = nil;
                    end

                elseif objectiveType == Objective.Custom2 and objective.Data[1].Reset then
                    objective.Data[1]:Reset(Quest, i)
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

        Quest.Result = nil
        local OldQuestState = Quest.State
        Quest.State = QuestState.NotTriggered
        Logic.ExecuteInLuaLocalState("LocalScriptCallback_OnQuestStatusChanged("..Quest.Index..")")
        if OldQuestState == QuestState.Over then
            Trigger.RequestTrigger(Events.LOGIC_EVENT_EVERY_SECOND, "", QuestTemplate.Loop, 1, 0, { Quest.QueueID })
        end
        return QuestID, Quest;
    end
end
RestartQuestByName = API.RestartQuest;

---
-- Startet eine Liste von Quests.
--
-- <b>Alias:</b> StartQuestsByName
--
-- @param ...  Liste mit Quests
-- @within User-Space
--
function API.StartAllQuests(...)
    for i=1, #args, 1 do
        API.StartQuest(args[i]);
    end
end
StartQuestsByName = API.StartAllQuests;

---
-- Startet den Quest sofort, sofern er existiert.
--
-- Dabei ist es unerheblich, ob die Bedingungen zum Start erfüllt sind.
--
-- <b>Alias:</b> StartQuestByName
--
-- @param _QuestName  Name des Quest
-- @within User-Space
--
function API.StartQuest(_QuestName)
    local Quest = Quests[GetQuestID(_QuestName)];
    if Quest then
        Quest:SetMsgKeyOverride();
        Quest:SetIconOverride();
        Quest:Trigger();
    end
end
StartQuestByName = API.StartQuest;

---
-- Unterbricht eine Liste von Quests.
--
-- <b>Alias:</b> StopQuestsByName
--
-- @param ...  Liste mit Quests
-- @within User-Space
--
function API.StopAllQuests(...)
    for i=1, #args, 1 do
        API.StopQuest(args[i]);
    end
end
StopQuestwByName = API.StopAllQuests;

---
-- Unterbricht den Quest.
--
-- Der Status wird auf Over und das Resultat auf Interrupt gesetzt. Sind Marker
-- gesetzt, werden diese entfernt.
--
-- <b>Alias:</b> StopQuestByName
--
-- @param _QuestName  Name des Quest
-- @within User-Space
--
function API.StopQuest(_QuestName)
    local Quest = Quests[GetQuestID(_QuestName)];
    if Quest then
        Quest:RemoveQuestMarkers();
        Quest:Interrupt(-1);
    end
end
StopQuestByName = API.StopQuest;

---
-- Gewinnt eine Liste von Quests.
--
-- Der Status wird auf Over und das Resultat auf Success gesetzt.
--
-- <b>Alias:</b> WinQuestsByName
--
-- @param ...  Liste mit Quests
-- @within User-Space
--
function API.WinAllQuests(...)
    for i=1, #args, 1 do
        API.WinQuest(args[i]);
    end
end
WinQuestsByName = API.WinAllQuests;

---
-- Gewinnt den Quest.
--
-- Der Status wird auf Over und das Resultat auf Success gesetzt.
--
-- <b>Alias:</b> WinQuestByName
--
-- @param _QuestName  Name des Quest
-- @within User-Space
--
function API.WinQuest(_QuestName)
    local Quest = Quests[GetQuestID(_QuestName)];
    if Quest then
        Quest:RemoveQuestMarkers();
        Quest:Success();
    end
end
WinQuestByName = API.WinQuest;

-- Messages --------------------------------------------------------------------

---
-- Schreibt eine Nachricht in das Debug Window. Der Text erscheint links am
-- Bildschirm und ist nicht statisch.
--
-- <b>Alias:</b> GUI_Note
--
-- @param _Message Anzeigetext
-- @within User-Space
--
function API.Note(_Message)
    _Message = tostring(_Message);
    local MessageFunc = Logic.DEBUG_AddNote;
    if GUI then
        MessageFunc = GUI.AddNote;
    end
    MessageFunc(_Message);
end
GUI_Note = API.Note;

---
-- Schreibt eine Nachricht in das Debug Window. Der Text erscheint links am
-- Bildschirm und verbleibt dauerhaft am Bildschirm.
--
-- @param _Message Anzeigetext
-- @within User-Space
--
function API.StaticNote(_Message)
    _Message = tostring(_Message);
    if not GUI then
        Logic.ExecuteInLuaLocalState('GUI.AddStaticNote("' .._Message.. '")');
        return;
    end
    GUI.AddStaticNote(_Message);
end

---
-- Löscht alle Nachrichten im Debug Window.
--
-- @within User-Space
--
function API.ClearNotes()
    if not GUI then
        Logic.ExecuteInLuaLocalState('GUI.ClearNotes()');
        return;
    end
    GUI.ClearNotes();
end

---
-- Schreibt eine einzelne Zeile Text ins Log. Vor dem Text steh, ob aus dem
-- globalen oder lokalen Skript geschrieben wurde und bei welchem Turn des
-- Spiels die Nachricht gesendet wurde.
--
-- @param _Message Nachricht für's Log
-- @within User-Space
--
function API.Log(_Message)
    local Env  = (GUI and "Local") or "Global";
    local Turn = Logic.GetTimeMs();
    Framework.WriteToLog(Env.. ":" ..Turn.. ": " .._Message);
end

---
-- Schreibt eine Nachricht in das Nachrichtenfenster unten in der Mitte.
--
-- @param _Message Anzeigetext
-- @within User-Space
--
function API.Message(_Message)
    _Message = tostring(_Message);
    if not GUI then
        Logic.ExecuteInLuaLocalState('Message("' .._Message.. '")');
        return;
    end
    Message(_Message);
end

---
-- Schreibt eine Fehlermeldung auf den Bildschirm und ins Log.
-- 
-- <b>Alias:</b> dbg
--
-- @param _Message Anzeigetext
-- @within User-Space
--
function API.Dbg(_Message)
    if QSB.Log.CurrentLevel >= QSB.Log.Level.ERROR then
        API.StaticNote("DEBUG: " .._Message)
    end
    API.Log("DEBUG: " .._Message);
end
dbg = API.Dbg;

---
-- Schreibt eine Warnungsmeldung auf den Bildschirm und ins Log.
-- 
-- <p><b>Alias:</b> warn</p>
--
-- @param _Message Anzeigetext
-- @within User-Space
--
function API.Warn(_Message)
    if QSB.Log.CurrentLevel >= QSB.Log.Level.WARNING then
        API.StaticNote("WARNING: " .._Message)
    end
    API.Log("WARNING: " .._Message);
end
warn = API.Warn;

---
-- Schreibt eine Information auf den Bildschirm und ins Log.
-- 
-- <b>Alias:</b> info
-- 
-- @param _Message Anzeigetext
-- @within User-Space
--
function API.Info(_Message)
    if QSB.Log.CurrentLevel >= QSB.Log.Level.INFO then
        API.StaticNote("WARNING: " .._Message)
    end
    API.Log("INFO: " .._Message);
end
info = API.Info;

-- Log Levels
QSB.Log = {
    Level = {
        OFF      = 90000,
        ERROR    = 3000,
        WARNING  = 2000,
        INFO     = 1000,
    },
}

-- Aktuelles Level
QSB.Log.CurrentLevel = QSB.Log.Level.INFO;

---
-- Setzt das Log-Level für die aktuelle Skriptumgebung.
--
-- Als Voreinstellung werden alle Meldungen immer angezeigt!
-- 
-- Das Log-Level bestimmt, welche Meldungen ausgegeben und welche unterdrückt
-- werden. Somit können Debug-Meldungen unterdrückt, während Fehlermeldungen
-- angezeigt werden.
--
-- <table border="1">
-- <tr>
-- <th>
-- Level
-- </th>
-- <th>
-- Beschreibung
-- </th>
-- </tr>
-- <td>
-- QSB.Log.Level.OFF
-- </td>
-- <td>
-- Alle Meldungen werden unterdrückt.
-- </td>
-- <tr>
-- <td>
-- QSB.Log.Level.ERROR
-- </td>
-- <td>
-- Es werden nur Fehler angezeigt.
-- </td>
-- </tr>
-- <tr>
-- <td>
-- QSB.Log.Level.WARNING
-- </td>
-- <td>
-- Es werden nur Warnungen und Fehler angezeigt.
-- </td>
-- </tr>
-- <tr>
-- <td>
-- QSB.Log.Level.INFO
-- </td>
-- <td>
-- Es werden Meldungen aller Stufen angezeigt.
-- </td>
-- </tr>
-- </table>
-- 
-- @param _Level Level
-- @within User-Space
--
function API.SetLogLevel(_Level)
    assert(type(_Level) == "number");
    QSB.Log.CurrentLevel = _Level;
end

-- Entities --------------------------------------------------------------------

---
-- Sendet einen Handelskarren zu dem Spieler. Startet der Karren von einem
-- Gebäude, wird immer die Position des Eingangs genommen.
--
-- <b>Alias:</b> SendCart
--
-- @param _position            Position
-- @param _player              Zielspieler
-- @param _good                Warentyp
-- @param _amount              Warenmenge
-- @param _cartOverlay         (optional) Overlay für Goldkarren
-- @param _ignoreReservation   (optional) Marktplatzreservation ignorieren
-- @return number: Entity-ID des erzeugten Wagens
-- @within User-Space
-- @usage -- API-Call
-- API.SendCart(Logic.GetStoreHouse(1), 2, Goods.G_Grain, 45)
-- -- Legacy-Call mit ID-Speicherung
-- local ID = SendCart("Position_1", 5, Goods.G_Wool, 5)
--
function API.SendCart(_position, _player, _good, _amount, _cartOverlay, _ignoreReservation)
    local eID = GetID(_position);
    if not IsExisting(eID) then
        return;
    end
    local ID;
    local x,y,z = Logic.EntityGetPos(eID);
    local resCat = Logic.GetGoodCategoryForGoodType(_good);
    local orientation = 0;
    if Logic.IsBuilding(eID) == 1 then
        x,y = Logic.GetBuildingApproachPosition(eID);
        orientation = Logic.GetEntityOrientation(eID)-90;
    end

    if resCat == GoodCategories.GC_Resource then
        ID = Logic.CreateEntityOnUnblockedLand(Entities.U_ResourceMerchant, x, y,orientation,_player)
    elseif _good == Goods.G_Medicine then
        ID = Logic.CreateEntityOnUnblockedLand(Entities.U_Medicus, x, y,orientation,_player)
    elseif _good == Goods.G_Gold then
        if _cartOverlay then
            ID = Logic.CreateEntityOnUnblockedLand(_cartOverlay, x, y,orientation,_player)
        else
            ID = Logic.CreateEntityOnUnblockedLand(Entities.U_GoldCart, x, y,orientation,_player)
        end
    else
        ID = Logic.CreateEntityOnUnblockedLand(Entities.U_Marketer, x, y,orientation,_player)
    end
    Logic.HireMerchant( ID, _player, _good, _amount, _player, _ignoreReservation)
    return ID
end
SendCart = API.SendCart;

---
-- Ersetzt ein Entity mit einem neuen eines anderen Typs. Skriptname,
-- Rotation, Position und Besitzer werden übernommen.
--
-- <b>Alias:</b> ReplaceEntity
--
-- @param _Entity     Entity
-- @param _Type       Neuer Typ
-- @param _NewOwner   (optional) Neuer Besitzer
-- @return number: Entity-ID des Entity
-- @within User-Space
-- @usage API.ReplaceEntity("Stein", Entities.XD_ScriptEntity)
--
function API.ReplaceEntity(_Entity, _Type, _NewOwner)
    local eID = GetID(_Entity);
    if eID == 0 then
        return;
    end
    local pos = GetPosition(eID);
    local player = _NewOwner or Logic.EntityGetPlayer(eID);
    local orientation = Logic.GetEntityOrientation(eID);
    local name = Logic.GetEntityName(eID);
    DestroyEntity(eID);
    if Logic.IsEntityTypeInCategory(_Type, EntityCategories.Soldier) == 1 then
        return CreateBattalion(player, _Type, pos.X, pos.Y, 1, name, orientation);
    else
        return CreateEntity(player, _Type, pos, name, orientation);
    end
end
ReplaceEntity = API.ReplaceEntity;

---
-- Rotiert ein Entity, sodass es zum Ziel schaut.
--
-- <b>Alias:</b> LookAt
--
-- @param _entity           Entity
-- @param _entityToLookAt   Ziel
-- @param _offsetEntity     Winkel-Offset
-- @within User-Space
-- @usage API.LookAt("Hakim", "Alandra")
--
function API.LookAt(_entity, _entityToLookAt, _offsetEntity)
    local entity = GetEntityId(_entity);
    local entityTLA = GetEntityId(_entityToLookAt);
    assert( not (Logic.IsEntityDestroyed(entity) or Logic.IsEntityDestroyed(entityTLA)), "LookAt: One Entity is wrong or dead");
    local eX, eY = Logic.GetEntityPosition(entity);
    local eTLAX, eTLAY = Logic.GetEntityPosition(entityTLA);
    local orientation = math.deg( math.atan2( (eTLAY - eY) , (eTLAX - eX) ) );
    if Logic.IsBuilding(entity) then
        orientation = orientation - 90;
    end
    _offsetEntity = _offsetEntity or 0;
    Logic.SetOrientation(entity, orientation + _offsetEntity);
end
LookAt = API.LookAt;

---
-- Lässt zwei Entities sich gegenseitig anschauen.
--
-- @param _entity           Erstes Entity
-- @param _entityToLookAt   Zweites Entity
-- @within User-Space
-- @usage API.Confront("Hakim", "Alandra")
--
function API.Confront(_entity, _entityToLookAt)
    API.LookAt(_entity, _entityToLookAt);
    API.LookAt(_entityToLookAt, _entity);
end

---
-- Bestimmt die Distanz zwischen zwei Punkten. Es können Entity-IDs,
-- Skriptnamen oder Positionstables angegeben werden.
--
-- <b>Alias:</b> GetDistance
--
-- @param _pos1 Erste Vergleichsposition
-- @param _pos2 Zweite Vergleichsposition
-- @return number: Entfernung zwischen den Punkten
-- @within User-Space
-- @usage local Distance = API.GetDistance("HQ1", Logic.GetKnightID(1))
--
function API.GetDistance( _pos1, _pos2 )
    _pos1 = ((type(_pos1) == "string" or type(_pos1) == "number") and _pos1) or GetPosition(_pos1);
    _pos2 = ((type(_pos2) == "string" or type(_pos2) == "number") and _pos2) or GetPosition(_pos2);
    if type(_pos1) ~= "table" or type(_pos2) ~= "table" then
        return;
    end
    return math.sqrt(((_pos1.X - _pos2.X)^2) + ((_pos1.Y - _pos2.Y)^2));
end
GetDistance = API.GetDistance;

---
-- Prüft, ob eine Positionstabelle eine gültige Position enthält.
--
-- <b>Alias:</b> IsValidPosition
--
-- @param _pos Positionstable
-- @return boolean: Position ist valide
-- @within User-Space
--
function API.ValidatePosition(_pos)
    if type(_pos) == "table" then
        if (_pos.X ~= nil and type(_pos.X) == "number") and (_pos.Y ~= nil and type(_pos.Y) == "number") then
            local world = {Logic.WorldGetSize()}
            if _pos.X <= world[1] and _pos.X >= 0 and _pos.Y <= world[2] and _pos.Y >= 0 then
                return true;
            end
        end
    end
    return false;
end
IsValidPosition = API.ValidatePosition;

---
-- Lokalisiert ein Entity auf der Map. Es können sowohl Skriptnamen als auch
-- IDs verwendet werden. Wenn das Entity nicht gefunden wird, wird eine
-- Tabelle mit XYZ = 0 zurückgegeben.
--
-- <b>Alias:</b> GetPosition
--
-- @param _Entity   Entity, dessen Position bestimmt wird.
-- @return table: Positionstabelle {X= x, Y= y, Z= z}
-- @within User-Space
-- @usage local Position = API.LocateEntity("Hans")
--
function API.LocateEntity(_Entity)
    if (type(_Entity) == "table") then
        return _Entity;
    end
    if (not IsExisting(_Entity)) then
        return {X= 0, Y= 0, Z= 0};
    end
    local x, y, z = Logic.EntityGetPos(GetID(_Entity));
    return {X= x, Y= y, Z= z};
end
GetPosition = API.LocateEntity;

---
-- Aktiviert ein interaktives Objekt, sodass es benutzt werden kann.
--
-- Der State bestimmt, ob es immer aktiviert werden kann, oder ob der Spieler
-- einen Helden benutzen muss. Wird der Parameter weggelassen, muss immer ein
-- Held das Objekt aktivieren.
--
-- <b>Alias:</b> InteractiveObjectActivate
--
-- @param _ScriptName  Skriptname des IO
-- @param _State       Aktivierungszustand
-- @within User-Space
-- @usage API.ActivateIO("Haus1", 0)
-- @usage API.ActivateIO("Hut1")
--
function API.ActivateIO(_ScriptName, _State)
    State = State or 0;
    if GUI then
        GUI.SendScriptCommand('API.AcrivateIO("' .._ScriptName.. '", ' ..State..')');
        return;
    end
    if not IsExisting(eName) then
        return
    end
    Logic.InteractiveObjectSetAvailability(GetID(eName), true);
    for i = 1, 8 do
        Logic.InteractiveObjectSetPlayerState(GetID(eName), i, State);
    end
end
InteractiveObjectActivate = API.AcrivateIO;

---
-- Deaktiviert ein Interaktives Objekt, sodass es nicht mehr vom Spieler
-- aktiviert werden kann.
--
-- <b>Alias:</b> InteractiveObjectDeactivate
--
-- @param _ScriptName Skriptname des IO
-- @within User-Space
-- @usage API.DeactivateIO("Hut1")
--
function API.DeactivateIO(_ScriptName)
    if GUI then
        GUI.SendScriptCommand('API.DeactivateIO("' .._ScriptName.. '")');
        return;
    end
    if not IsExisting(_ScriptName) then
        return;
    end
    Logic.InteractiveObjectSetAvailability(GetID(_ScriptName), false);
    for i = 1, 8 do
        Logic.InteractiveObjectSetPlayerState(GetID(_ScriptName), i, 2);
    end
end
InteractiveObjectDeactivate = API.DeactivateIO;

---
-- Ermittelt alle Entities in der Kategorie auf dem Territorium und gibt
-- sie als Liste zurück.
--
-- <b>Alias:</b> GetEntitiesOfCategoryInTerritory
--
-- @param _player    PlayerID [0-8] oder -1 für alle
-- @param _category  Kategorie, der die Entities angehören
-- @param _territory Zielterritorium
-- @within User-Space
-- @usage local Found = API.GetEntitiesOfCategoryInTerritory(1, EntityCategories.Hero, 5)
--
function API.GetEntitiesOfCategoryInTerritory(_player, _category, _territory)
    local PlayerEntities = {};
    local Units = {};
    if (_player == -1) then
        for i=0,8 do
            local NumLast = 0;
            repeat
                Units = { Logic.GetEntitiesOfCategoryInTerritory(_territory, i, _category, NumLast) };
                PlayerEntities = Array_Append(PlayerEntities, Units);
                NumLast = NumLast + #Units;
            until #Units == 0;
        end
    else
        local NumLast = 0;
        repeat
            Units = { Logic.GetEntitiesOfCategoryInTerritory(_territory, _player, _category, NumLast) };
            PlayerEntities = Array_Append(PlayerEntities, Units);
            NumLast = NumLast + #Units;
        until #Units == 0;
    end
    return PlayerEntities;
end
GetEntitiesOfCategoryInTerritory = API.GetEntitiesOfCategoryInTerritory;

-- Overwrite -------------------------------------------------------------------

---
-- Schickt einen Skriptbefehl an die jeweils andere Skriptumgebung.
--
-- Wird diese Funktion als dem globalen Skript aufgerufen, sendet sie den
-- Befehl an das lokale Skript. Wird diese Funktion im lokalen Skript genutzt,
-- wird der Befehl an das globale Skript geschickt.
--
-- @param _Command Lua-Befehl als String
-- @param _Flag    FIXME
--
function API.Bridge(_Command, _Flag)
    if not GUI then
        Logic.ExecuteInLuaLocalState(_Command)
    else
        GUI.SendScriptCommand(_Command, _Flag)
    end
end

---
-- Konvertiert alternative Wahrheitswertangaben in der QSB in eine Boolean.
--
-- <p>Wahrheitsert true: true, "true", "yes", "on", "+"</p>
-- <p>Wahrheitswert false: false, "false", "no", "off", "-"</p>
--
-- <b>Alias:</b> AcceptAlternativeBoolean
-- 
-- @param _Value Wahrheitswert
-- @return boolean: Wahrheitswert
-- @within User-Space
--
-- @usage local Bool = API.ToBoolean("+")  --> Bool = true
-- local Bool = API.ToBoolean("no") --> Bool = false
--
function API.ToBoolean(_Value)
    return Core:ToBoolean(_Value);
end
AcceptAlternativeBoolean = API.ToBoolean;

---
-- Hängt eine Funktion an Mission_OnSaveGameLoaded an, sodass sie nach dem
-- Laden eines Spielstandes ausgeführt wird.
--
-- @param _Function Funktion, die ausgeführt werden soll
-- @within User-Space
-- @usage SaveGame = function()
--     API.Note("foo")
-- end
-- API.AddSaveGameAction(SaveGame)
--
function API.AddSaveGameAction(_Function)
    return Core:AppendFunction("Mission_OnSaveGameLoaded", _Function)
end

-- -------------------------------------------------------------------------- --
-- Application-Space                                                          --
-- -------------------------------------------------------------------------- --

Core = {
    Data = {
        Append = {
            Functions = {},
            Fields = {},
        },
        BundleInitializerList = {},
    }
}

---
-- Initialisiert alle verfügbaren Bundles und führt ihre Install-Methode aus.
-- Bundles werden immer getrennt im globalen und im lokalen Skript gestartet.
-- @within Application-Space
-- @local
--
function Core:InitalizeBundles()
    if not GUI then
        self:SetupGobal_HackCreateQuest();
        self:SetupGlobal_HackQuestSystem();
    end

    for k,v in pairs(self.Data.BundleInitializerList) do
        if not GUI then
            if v.Global ~= nil and v.Global.Install ~= nil then
                v.Global:Install();
            end
        else
            if v.Local ~= nil and v.Local.Install ~= nil then
                v.Local:Install();
            end
        end
    end
end

---
-- FIXME
-- @within Application-Space
-- @local
--
function Core:SetupGobal_HackCreateQuest()
    CreateQuest = function(_QuestName, _QuestGiver, _QuestReceiver, _QuestHidden, _QuestTime, _QuestDescription, _QuestStartMsg, _QuestSuccessMsg, _QuestFailureMsg)
        local Triggers = {}
        local Goals = {}
        local Reward = {}
        local Reprisal = {}
        local NumberOfBehavior = Logic.Quest_GetQuestNumberOfBehaviors(_QuestName)
        for i=0,NumberOfBehavior-1 do
            local BehaviorName = Logic.Quest_GetQuestBehaviorName(_QuestName, i)
            local BehaviorTemplate = GetBehaviorTemplateByName(BehaviorName)
            assert( BehaviorTemplate, "No template for name: " .. BehaviorName .. " - using an invalid QuestSystemBehavior.lua?!" )
            local NewBehavior = {}
            Table_Copy(NewBehavior, BehaviorTemplate)
            local Parameter = Logic.Quest_GetQuestBehaviorParameter(_QuestName, i)
            for j=1,#Parameter do
                NewBehavior:AddParameter(j-1, Parameter[j])
            end
            if (NewBehavior.GetGoalTable ~= nil) then
                Goals[#Goals + 1] = NewBehavior:GetGoalTable()
                Goals[#Goals].Context = NewBehavior
                Goals[#Goals].FuncOverrideIcon = NewBehavior.GetIcon
                Goals[#Goals].FuncOverrideMsgKey = NewBehavior.GetMsgKey
            end
            if (NewBehavior.GetTriggerTable ~= nil) then
                Triggers[#Triggers + 1] = NewBehavior:GetTriggerTable()
            end
            if (NewBehavior.GetReprisalTable ~= nil) then
                Reprisal[#Reprisal + 1] = NewBehavior:GetReprisalTable()
            end
            if (NewBehavior.GetRewardTable ~= nil) then
                Reward[#Reward + 1] = NewBehavior:GetRewardTable()
            end
        end
        if (#Triggers == 0) or (#Goals == 0) then
            return
        end
        if Core:CheckQuestName(_QuestName) then
            local QuestID = QuestTemplate:New(_QuestName, _QuestGiver, _QuestReceiver,
                                                    Goals,
                                                    Triggers,
                                                    assert( tonumber(_QuestTime) ),
                                                    Reward,
                                                    Reprisal,
                                                    nil, nil,
                                                    (not _QuestHidden or ( _QuestStartMsg and _QuestStartMsg ~= "") ),
                                                    (not _QuestHidden or ( _QuestSuccessMsg and _QuestSuccessMsg ~= "") or ( _QuestFailureMsg and _QuestFailureMsg ~= "") ),
                                                    _QuestDescription, _QuestStartMsg, _QuestSuccessMsg, _QuestFailureMsg)
            g_QuestNameToID[_QuestName] = QuestID
        else
            dbg("Quest '"..tostring(questName).."': invalid questname! Contains forbidden characters!");
        end
    end
end

---
-- FIXME
-- @within Application-Space
-- @local
--
function Core:SetupGlobal_HackQuestSystem()
    QuestTemplate.Trigger_Orig_QSB_Core = QuestTemplate.Trigger
    QuestTemplate.Trigger = function(_quest)
        QuestTemplate.Trigger_Orig_QSB_Core(_quest);
        for i=1,_quest.Objectives[0] do
            if _quest.Objectives[i].Type == Objective.Custom2 and _quest.Objectives[i].Data[1].SetDescriptionOverwrite then
                local Desc = _quest.Objectives[i].Data[1]:SetDescriptionOverwrite(_quest);
                Core:ChangeCustomQuestCaptionText(_quest.Identifier, Desc);
                break;
            end
        end
    end

    QuestTemplate.Interrupt_Orig_QSB_Core = QuestTemplate.Interrupt;
    QuestTemplate.Interrupt = function(_quest)
        QuestTemplate.Interrupt_Orig_QSB_Core(_quest);
        for i=1, _quest.Objectives[0] do
            if _quest.Objectives[i].Type == Objective.Custom2 and _quest.Objectives[i].Data[1].Interrupt then
                _quest.Objectives[i].Data[1]:Interrupt(_quest, i);
            end
        end
        for i=1, _quest.Triggers[0] do
            if _quest.Triggers[i].Type == Triggers.Custom2 and _quest.Triggers[i].Data[1].Interrupt then
                _quest.Triggers[i].Data[1]:Interrupt(_quest, i);
            end
        end
    end
end

---
-- Registiert ein Bundle, sodass es initialisiert wird.
--
-- @param _Bundle Name des Moduls
-- @within Application-Space
-- @local
--
function Core:RegisterBundle(_Bundle)
    local text = string.format("Error while initialize bundle '%s': does not exist!", tostring(_Bundle));
    assert(_G[_Bundle] ~= nil, text);
    table.insert(self.Data.BundleInitializerList, _G[_Bundle]);
end

---
-- Bereitet ein Behavior für den Einsatz im Assistenten und im Skript vor.
-- Erzeugt zudem den Konstruktor.
--
-- @param _Behavior    Behavior-Objekt
-- @within Application-Space
-- @local
--
function Core:RegisterBehavior(_Behavior)
    if GUI then
        return;
    end
    if _Behavior.RequiresExtraNo and _Behavior.RequiresExtraNo > g_GameExtraNo then
        return;
    end

    if not _G["b_" .. _Behavior.Name] then
        dbg("AddQuestBehavior: can not find ".. _Behavior.Name .."!");
    else
        if not _G["b_" .. _Behavior.Name].new then
            _G["b_" .. _Behavior.Name].new = function(self, ...)
                local behavior = API.InstanceTable(self);
                if self.Parameter then
                    for i=1,table.getn(self.Parameter) do
                        behavior:AddParameter(i-1, arg[i]);
                    end
                end
                return behavior;
            end
        end
        table.insert(g_QuestBehaviorTypes, _Behavior);
    end
end

---
-- Prüft, ob der Questname formal korrekt ist. Questnamen dürfen i.d.R. nur
-- die Zeichen A-Z, a-7, 0-9, - und _ enthalten.
--
-- @param _Name     Quest
-- @return boolean: Questname ist fehlerfrei
-- @within Application-Space
-- @local
--
function Core:CheckQuestName(_Name)
    return not string.find(_Name, "[ \"§$%&/\(\)\[\[\?ß\*+#,;:\.^\<\>\|]");
end

---
-- Ändert den Text des Beschreibungsfensters eines Quests. Die Beschreibung
-- wird erst dann aktualisiert, wenn der Quest ausgeblendet wird.
--
-- @param _Text   Neuer Text
-- @param _Quest  Identifier des Quest
-- @within Application-Space
-- @local
--
function Core:ChangeCustomQuestCaptionText(_Text, _Quest)
    _Quest.QuestDescription = _Text;
    Logic.ExecuteInLuaLocalState([[
        XGUIEng.ShowWidget("/InGame/Root/Normal/AlignBottomLeft/Message/QuestObjectives/Custom/BGDeco",0)
        local identifier = "]].._Quest.Identifier..[["
        for i=1, Quests[0] do
            if Quests[i].Identifier == identifier then
                local text = Quests[i].QuestDescription
                XGUIEng.SetText("/InGame/Root/Normal/AlignBottomLeft/Message/QuestObjectives/Custom/Text", "]].._Text..[[")
                break;
            end
        end
    ]]);
end

---
-- Erweitert eine Funktion um eine andere Funktion.
--
-- Jede hinzugefügte Funktion wird nach der Originalfunktion ausgeführt. Es
-- ist möglich eine neue Funktion an einem bestimmten Index einzufügen. Diese
-- Funktion ist nicht gedacht, um sie direkt auszuführen. Für jede Funktion
-- im Spiel sollte eine API-Funktion erstellt werden.
--
-- @param _FunctionName
-- @param _AppendFunction
-- @param _Index
-- @within Application-Space
-- @local
--
function Core:AppendFunction(_FunctionName, _AppendFunction, _Index)
    if not self.Data.Append.Functions[_FunctionName] then
        self.Data.Append.Functions[_FunctionName] = {
            Original = self:GetFunctionInString(_FunctionName),
            Attachments = {}
        };

        local batch = function(...)
            self.Data.Append.Functions[_FunctionName].Original(unpack(arg));
            for k, v in pairs(self.Data.Append.Functions[_FunctionName].Attachments) do
                v(unpack(arg))
            end
        end
        self:ReplaceFunction(_FunctionName, batch);
    end

    _Index = _Index or #self.Data.Append.Functions[_FunctionName].Attachments;
    table.insert(self.Data.Append.Functions[_FunctionName].Attachments, _Index, _AppendFunction);
end

---
-- Überschreibt eine Funktion mit einer anderen.
--
-- Wenn es sich um eine Funktion innerhalb einer Table handelt, dann darf sie
-- sich nicht tiefer als zwei Ebenen under dem Toplevel befinden.
--
-- @local
-- @within Application-Space
-- @usage A = {foo = function() API.Note("bar") end}
-- B = function() API.Note("muh") end
-- Core:ReplaceFunction("A.foo", B)
-- -- A.foo() == B() => "muh"
--
function Core:ReplaceFunction(_FunctionName, _NewFunction)
    local s, e = _FunctionName:find("%.");
    if s then
        local FirstLayer  = _FunctionName:sub(1, s-1);
        local SecondLayer = _FunctionName:sub(e+1, _FunctionName:len());
        local s, e = SecondLayer:find("%.");
        if s then
            local tmp = SecondLayer;
            local SecondLayer = tmp:sub(1, s-1);
            local ThirdLayer = tmp:sub(e+1, tmp:len());
            _G[FirstLayer][SecondLayer][ThirdLayer] = _NewFunction;
        else
            _G[FirstLayer][SecondLayer] = _NewFunction;
        end
    else
        _G[_FunctionName] = _NewFunction;
        return;
    end
end

---
-- Sucht eine Funktion mit dem angegebenen Namen.
--
-- Ist die Funktionen innerhalb einer Table, so sind alle Ebenen bis zum
-- Funktionsnamen mit anzugeben, abgetrennt durch einen Punkt.
--
-- @param _FunctionName Name der Funktion
-- @param _Reference    Aktuelle Referenz (für Rekursion)
-- @return function: Gefundene Funktion
-- @within Application-Space
-- @local
--
function Core:GetFunctionInString(_FunctionName, _Reference)
    -- Wenn wir uns in der ersten Rekursionsebene beinden, suche in _G
    if not _Reference then
        local s, e = _FunctionName:find("%.");
        if s then
            local FirstLayer = _FunctionName:sub(1, s-1);
            local Rest = _FunctionName:sub(e+1, _FunctionName:len());
            return self:GetFunctionInString(Rest, _G[FirstLayer]);
        else
            return _G[_FunctionName];
        end
    end
    -- Andernfalls suche in der Referenz
    if type(_Reference) == "table" then
        local s, e = _FunctionName:find("%.");
        if s then
            local FirstLayer = _FunctionName:sub(1, s-1);
            local Rest = _FunctionName:sub(e+1, _FunctionName:len());
            return self:GetFunctionInString(Rest, _Reference[FirstLayer]);
        else
            return _Reference[_FunctionName];
        end
    end
end

---
-- Wandelt underschiedliche Darstellungen einer Boolean in eine echte um.
--
-- @param _Input Boolean-Darstellung
-- @return boolean: Konvertierte Boolean
-- @within Application-Space
-- @local
--
function Core:ToBoolean(_Input)
    local Suspicious = tostring(_Input);
    if Suspicious == true or Suspicious == "true" or Suspicious == "Yes" or Suspicious == "On" or Suspicious == "+" then
        return true;
    end
    if Suspicious == false or Suspicious == "false" or Suspicious == "No" or Suspicious == "Off" or Suspicious == "-" then
        return false;
    end
    return false;
end

-- -------------------------------------------------------------------------- --
-- ########################################################################## --
-- #  Symfonia BundleClassicBehaviors                                       # --
-- ########################################################################## --
-- -------------------------------------------------------------------------- --

---
-- Dieses Bundle enthält alle Behavior, die aus der QSB 3.9 PlusB bekannt sind.
--
-- Die Behavior sind weitesgehend unverändert und es dürfte keine Probleme mit
-- Inkompatibelität geben, wenn die QSB ausgetauscht wird.
--
-- @module BundleClassicBehaviors
-- @set sort=true
--

API = API or {};
QSB = QSB or {};

QSB.EffectNameToID    = QSB.EffectNameToID or {};
QSB.InitalizedObjekts = QSB.InitalizedObjekts or {};
QSB.DestroyedSoldiers = QSB.DestroyedSoldiers or {};

-- -------------------------------------------------------------------------- --
-- User-Space                                                                 --
-- -------------------------------------------------------------------------- --

-- Hier siehst du... nichts! ;)

-- -------------------------------------------------------------------------- --
-- Goals                                                                      --
-- -------------------------------------------------------------------------- --

---
-- Ein Interaktives Objekt muss benutzt werden.
--
-- @param _ScriptName Skriptname des interaktiven Objektes
-- @return Table mit Behavior
-- @within Goal
--
function Goal_ActivateObject(...)
    return b_Goal_ActivateObject:new(...);
end

b_Goal_ActivateObject = {
    Name = "Goal_ActivateObject",
    Description = {
        en = "Goal: Activate an interactive object",
        de = "Ziel: Aktiviere ein interaktives Objekt",
    },
    Parameter = {
        { ParameterType.ScriptName, en = "Object name", de = "Skriptname" },
    },
}

function b_Goal_ActivateObject:GetGoalTable(_Quest)
    return {Objective.Object, { self.ScriptName } }
end

function b_Goal_ActivateObject:AddParameter(_Index, _Parameter)
   if _Index == 0 then
        self.ScriptName = _Parameter
   end
end

function b_Goal_ActivateObject:GetMsgKey()
    return "Quest_Object_Activate"
end

Core:RegisterBehavior(b_Goal_ActivateObject);

-- -------------------------------------------------------------------------- --

---
-- Einem Spieler müssen Rohstoffe oder Waren gesendet werden.
--
-- In der Regel wird zum Auftraggeber gesendet. Es ist aber möglich auch zu
-- einem anderen Zielspieler schicken zu lassen. Wird ein Wagen gefangen
-- genommen, dann muss erneut geschickt werden. Optional kann auch gesagt
-- werden, dass keine erneute Forderung erfolgt, wenn der Karren von einem
-- Feind abgefangen wird.
--
-- @param _GoodType      Typ der Ware
-- @param _GoodAmount    Menga der Ware
-- @param _OtherTarget   Anderes Ziel als Auftraggeber
-- @param _IgnoreCapture Bei Gefangennahme nicht erneut schicken
-- @return Table mit Behavior
-- @within Goal
--
function Goal_Deliver(...)
    return b_Goal_Deliver:new(...)
end

b_Goal_Deliver = {
    Name = "Goal_Deliver",
    Description = {
        en = "Goal: Deliver goods to quest giver or to another player.",
        de = "Ziel: Liefere Waren zum Auftraggeber oder zu einem anderen Spieler.",
    },
    Parameter = {
        { ParameterType.Custom, en = "Type of good", de = "Ressourcentyp" },
        { ParameterType.Number, en = "Amount of good", de = "Ressourcenmenge" },
        { ParameterType.Custom, en = "To different player", de = "Anderer Empfänger" },
        { ParameterType.Custom, en = "Ignore capture", de = "Abfangen ignorieren" },
    },
}


function b_Goal_Deliver:GetGoalTable(_Quest)
    local GoodType = Logic.GetGoodTypeID(self.GoodTypeName)
    return { Objective.Deliver, GoodType, self.GoodAmount, self.OverrideTarget, self.IgnoreCapture }
end

function b_Goal_Deliver:AddParameter(_Index, _Parameter)
    if (_Index == 0) then
        self.GoodTypeName = _Parameter
    elseif (_Index == 1) then
        self.GoodAmount = _Parameter * 1
    elseif (_Index == 2) then
        self.OverrideTarget = tonumber(_Parameter)
    elseif (_Index == 3) then
        self.IgnoreCapture = AcceptAlternativeBoolean(_Parameter)
    end
end

function b_Goal_Deliver:GetCustomData( _Index )
    local Data = {}
    if _Index == 0 then
        for k, v in pairs( Goods ) do
            if string.find( k, "^G_" ) then
                table.insert( Data, k )
            end
        end
        table.sort( Data )
    elseif _Index == 2 then
        table.insert( Data, "-" )
        for i = 1, 8 do
            table.insert( Data, i )
        end
    elseif _Index == 3 then
        table.insert( Data, "true" )
        table.insert( Data, "false" )
    else
        assert( false )
    end
    return Data
end

function b_Goal_Deliver:GetMsgKey()
    local GoodType = Logic.GetGoodTypeID(self.GoodTypeName)
    local GC = Logic.GetGoodCategoryForGoodType( GoodType )

    local tMapping = {
        [GoodCategories.GC_Clothes] = "Quest_Deliver_GC_Clothes",
        [GoodCategories.GC_Entertainment] = "Quest_Deliver_GC_Entertainment",
        [GoodCategories.GC_Food] = "Quest_Deliver_GC_Food",
        [GoodCategories.GC_Gold] = "Quest_Deliver_GC_Gold",
        [GoodCategories.GC_Hygiene] = "Quest_Deliver_GC_Hygiene",
        [GoodCategories.GC_Medicine] = "Quest_Deliver_GC_Medicine",
        [GoodCategories.GC_Water] = "Quest_Deliver_GC_Water",
        [GoodCategories.GC_Weapon] = "Quest_Deliver_GC_Weapon",
        [GoodCategories.GC_Resource] = "Quest_Deliver_Resources",
    }

    if GC then
        local Key = tMapping[GC]
        if Key then
            return Key
        end
    end
    return "Quest_Deliver_Goods"
end

Core:RegisterBehavior(b_Goal_Deliver);

-- -------------------------------------------------------------------------- --

---
-- Es muss ein bestimmter Diplomatiestatus zu einer anderen Datei erreicht
-- werden.
--
-- Dabei muss, je nach angegebener Relation entweder wenigstens oder auch
-- minbdestens erreicht werden.
--
-- Muss z.B. mindestens der Status Handelspartner erreicht werden (mit der
-- Relation >=), so ist der Quest auch dann erfüllt, wenn der Spieler
--  Verbündeter wird.
--
-- Im Gegenzug, bei der Relation <=, wäre der Quest erfüllt, sobald der
-- Spieler Handelspartner oder einen niedrigeren Status erreicht.
--
-- @param _PlayerID Partei, die Entdeckt werden muss
-- @param _State    Diplomatiestatus
-- @return Table mit Behavior
-- @within Goal
--
function Goal_Diplomacy(...)
    return b_Goal_Diplomacy:new(...);
end

b_Goal_Diplomacy = {
    Name = "Goal_Diplomacy",
    Description = {
        en = "Goal: Reach a diplomatic state",
        de = "Ziel: Erreiche einen bestimmten Diplomatiestatus zu einem anderen Spieler.",
    },
    Parameter = {
        { ParameterType.PlayerID, en = "Party", de = "Partei" },
        { ParameterType.DiplomacyState, en = "Relation", de = "Beziehung" },
    },
}

function b_Goal_Diplomacy:GetGoalTable(_Quest)
    return { Objective.Diplomacy, self.PlayerID, DiplomacyStates[self.DiplState] }
end

function b_Goal_Diplomacy:AddParameter(_Index, _Parameter)
    if (_Index == 0) then
        self.PlayerID = _Parameter * 1
    elseif (_Index == 1) then
        self.DiplState = _Parameter
    end
end

function b_Goal_Diplomacy:GetIcon()
    return {6,3};
end

Core:RegisterBehavior(b_Goal_Diplomacy);

-- -------------------------------------------------------------------------- --

---
-- Das Heimatterritorium des Spielers muss entdeckt werden.
--
-- Das Heimatterritorium ist immer das, wo sich Burg oder Lagerhaus der
-- zu entdeckenden Partei befinden.
--
-- @param _PlayerID ID der zu entdeckenden Partei
-- @return Table mit Behavior
-- @within Goal
--
function Goal_DiscoverPlayer(...)
    return b_Goal_DiscoverPlayer:new(...);
end

b_Goal_DiscoverPlayer = {
    Name = "Goal_DiscoverPlayer",
    Description = {
        en = "Goal: Discover the home territory of another player.",
        de = "Ziel: Entdecke das Heimatterritorium eines Spielers.",
    },
    Parameter = {
        { ParameterType.PlayerID, en = "Player", de = "Spieler" },
    },
}

function b_Goal_DiscoverPlayer:GetGoalTable()
    return {Objective.Discover, 2, { self.PlayerID } }
end

function b_Goal_DiscoverPlayer:AddParameter(_Index, _Parameter)
    if (_Index == 0) then
        self.PlayerID = _Parameter * 1
    end
end

function b_Goal_DiscoverPlayer:GetMsgKey()
    local tMapping = {
        [PlayerCategories.BanditsCamp] = "Quest_Discover",
        [PlayerCategories.City] = "Quest_Discover_City",
        [PlayerCategories.Cloister] = "Quest_Discover_Cloister",
        [PlayerCategories.Harbour] = "Quest_Discover",
        [PlayerCategories.Village] = "Quest_Discover_Village",
    }
    local PlayerCategory = GetPlayerCategoryType(self.PlayerID)
    if PlayerCategory then
        local Key = tMapping[PlayerCategory]
        if Key then
            return Key
        end
    end
    return "Quest_Discover"
end

Core:RegisterBehavior(b_Goal_DiscoverPlayer);

-- -------------------------------------------------------------------------- --

---
-- Ein Territorium muss erstmalig vom Auftragnehmer betreten werden.
--
-- @param _Territory Name oder ID des Territorium
-- @return Table mit Behavior
-- @within Goal
--
function Goal_DiscoverTerritory(...)
    return b_Goal_DiscoverTerritory:new(...);
end

b_Goal_DiscoverTerritory = {
    Name = "Goal_DiscoverTerritory",
    Description = {
        en = "Goal: Discover a territory",
        de = "Ziel: Entdecke ein Territorium",
    },
    Parameter = {
        { ParameterType.TerritoryName, en = "Territory", de = "Territorium" },
    },
}

function b_Goal_DiscoverTerritory:GetGoalTable()
    return { Objective.Discover, 1, { self.TerritoryID  } }
end

function b_Goal_DiscoverTerritory:AddParameter(_Index, _Parameter)
    if (_Index == 0) then
        self.TerritoryID = tonumber(_Parameter)
        if not self.TerritoryID then
            self.TerritoryID = GetTerritoryIDByName(_Parameter)
        end
        assert( self.TerritoryID > 0 )
    end
end

function b_Goal_DiscoverTerritory:GetMsgKey()
    return "Quest_Discover_Territory"
end

Core:RegisterBehavior(b_Goal_DiscoverTerritory);

-- -------------------------------------------------------------------------- --

---
-- Eine andere Partei muss besiegt werden.
--
-- Die Partei gilt als besiegt, wenn ein Hauptgebäude (Burg, Kirche, Lager)
-- zerstört wurde. <b>Achtung:</b> Funktioniert nicht bei Banditen!
--
-- @param _PlayerID ID des Spielers
-- @return Table mit Behavior
-- @within Goal
--
function Goal_DestroyPlayer(...)
    return b_Goal_DestroyPlayer:new(...);
end

b_Goal_DestroyPlayer = {
    Name = "Goal_DestroyPlayer",
    Description = {
        en = "Goal: Destroy a player (destroy a main building)",
        de = "Ziel: Zerstöre einen Spieler (ein Hauptgebäude muss zerstört werden).",
    },
    Parameter = {
        { ParameterType.PlayerID, en = "Player", de = "Spieler" },
    },
}

function b_Goal_DestroyPlayer:GetGoalTable()
    assert( self.PlayerID <= 8 and self.PlayerID >= 1, "Error in " .. self.Name .. ": GetGoalTable: PlayerID is invalid")
    return { Objective.DestroyPlayers, self.PlayerID }
end

function b_Goal_DestroyPlayer:AddParameter(_Index, _Parameter)
    if (_Index == 0) then
        self.PlayerID = _Parameter * 1
    end
end

function b_Goal_DestroyPlayer:GetMsgKey()
    local tMapping = {
        [PlayerCategories.BanditsCamp] = "Quest_DestroyPlayers_Bandits",
        [PlayerCategories.City] = "Quest_DestroyPlayers_City",
        [PlayerCategories.Cloister] = "Quest_DestroyPlayers_Cloister",
        [PlayerCategories.Harbour] = "Quest_DestroyEntities_Building",
        [PlayerCategories.Village] = "Quest_DestroyPlayers_Village",
    }

    local PlayerCategory = GetPlayerCategoryType(self.PlayerID)
    if PlayerCategory then
        local Key = tMapping[PlayerCategory]
        if Key then
            return Key
        end
    end
    return "Quest_DestroyEntities_Building"
end

Core:RegisterBehavior(b_Goal_DestroyPlayer)

-- -------------------------------------------------------------------------- --

---
-- Es sollen Informationen aus der Burg gestohlen werden.
--
-- Der Spieler muss einen Dieb entsenden um Informationen aus der Burg zu
-- stehlen. <b>Achtung:</b> Das ist nur bei Feinden möglich!
--
-- @param _PlayerID ID der Partei
-- @return Table mit Behavior
-- @within Goal
--
function Goal_StealInformation(...)
    return b_Goal_StealInformation:new(...);
end

b_Goal_StealInformation = {
    Name = "Goal_StealInformation",
    Description = {
        en = "Goal: Steal information from another players castle",
        de = "Ziel: Stehle Informationen aus der Burg eines Spielers",
    },
    Parameter = {
        { ParameterType.PlayerID, en = "Player", de = "Spieler" },
    },
}

function b_Goal_StealInformation:GetGoalTable()

    local Target = Logic.GetHeadquarters(self.PlayerID)
    if not Target or Target == 0 then
        Target = Logic.GetStoreHouse(self.PlayerID)
    end
    assert( Target and Target ~= 0 )
    return {Objective.Steal, 1, { Target } }

end

function b_Goal_StealInformation:AddParameter(_Index, _Parameter)

    if (_Index == 0) then
        self.PlayerID = _Parameter * 1
    end

end

function b_Goal_StealInformation:GetMsgKey()
    return "Quest_Steal_Info"

end

Core:RegisterBehavior(b_Goal_StealInformation);

-- -------------------------------------------------------------------------- --

---
-- Alle Einheiten des Spielers müssen zerstört werden.
--
-- @param _PlayerID ID des Spielers
-- @return Table mit Behavior
-- @within Goal
--
function Goal_DestroyAllPlayerUnits(...)
    return b_Goal_DestroyAllPlayerUnits:new(...);
end

b_Goal_DestroyAllPlayerUnits = {
    Name = "Goal_DestroyAllPlayerUnits",
    Description = {
        en = "Goal: Destroy all units owned by player (be careful with script entities)",
        de = "Ziel: Zerstöre alle Einheiten eines Spielers (vorsicht mit Script-Entities)",
    },
    Parameter = {
        { ParameterType.PlayerID, en = "Player", de = "Spieler" },
    },
}

function b_Goal_DestroyAllPlayerUnits:GetGoalTable()
    return { Objective.DestroyAllPlayerUnits, self.PlayerID }
end

function b_Goal_DestroyAllPlayerUnits:AddParameter(_Index, _Parameter)
    if (_Index == 0) then
        self.PlayerID = _Parameter * 1
    end
end

function b_Goal_DestroyAllPlayerUnits:GetMsgKey()
    local tMapping = {
        [PlayerCategories.BanditsCamp] = "Quest_DestroyPlayers_Bandits",
        [PlayerCategories.City] = "Quest_DestroyPlayers_City",
        [PlayerCategories.Cloister] = "Quest_DestroyPlayers_Cloister",
        [PlayerCategories.Harbour] = "Quest_DestroyEntities_Building",
        [PlayerCategories.Village] = "Quest_DestroyPlayers_Village",
    }

    local PlayerCategory = GetPlayerCategoryType(self.PlayerID)
    if PlayerCategory then
        local Key = tMapping[PlayerCategory]
        if Key then
            return Key
        end
    end
    return "Quest_DestroyEntities"
end

Core:RegisterBehavior(b_Goal_DestroyAllPlayerUnits);

-- -------------------------------------------------------------------------- --

---
-- Ein benanntes Entity muss zerstört werden.
--
-- @param _ScriptName Skriptname des Ziels
-- @return Table mit Behavior
-- @within Goal
--
function Goal_DestroyScriptEntity(...)
    return b_Goal_DestroyScriptEntity:new(...);
end

b_Goal_DestroyScriptEntity = {
    Name = "Goal_DestroyScriptEntity",
    Description = {
        en = "Goal: Destroy an entity",
        de = "Ziel: Zerstöre eine Entität",
    },
    Parameter = {
        { ParameterType.ScriptName, en = "Script name", de = "Skriptname" },
    },
}

function b_Goal_DestroyScriptEntity:GetGoalTable()
    return {Objective.DestroyEntities, 1, { self.ScriptName } }
end

function b_Goal_DestroyScriptEntity:AddParameter(_Index, _Parameter)
    if (_Index == 0) then
        self.ScriptName = _Parameter
    end
end

function b_Goal_DestroyScriptEntity:GetMsgKey()
    if Logic.IsEntityAlive(self.ScriptName) then
        local ID = GetID(self.ScriptName)
        if ID and ID ~= 0 then
            ID = Logic.GetEntityType( ID )
            if ID and ID ~= 0 then
                if Logic.IsEntityTypeInCategory( ID, EntityCategories.AttackableBuilding ) == 1 then
                    return "Quest_DestroyEntities_Building"

                elseif Logic.IsEntityTypeInCategory( ID, EntityCategories.AttackableAnimal ) == 1 then
                    return "Quest_DestroyEntities_Predators"

                elseif Logic.IsEntityTypeInCategory( ID, EntityCategories.Hero ) == 1 then
                    return "Quest_Destroy_Leader"

                elseif Logic.IsEntityTypeInCategory( ID, EntityCategories.Military ) == 1
                    or Logic.IsEntityTypeInCategory( ID, EntityCategories.AttackableSettler ) == 1
                    or Logic.IsEntityTypeInCategory( ID, EntityCategories.AttackableMerchant ) == 1  then

                    return "Quest_DestroyEntities_Unit"
                end
            end
        end
    end
    return "Quest_DestroyEntities"
end

Core:RegisterBehavior(b_Goal_DestroyScriptEntity);

-- -------------------------------------------------------------------------- --

---
-- Eine Menge an Entities eines Typs müssen zerstört werden.
--
-- Wenn Raubtiere zerstört werden sollen, muss Spieler 0 als Besitzer
-- angegeben werden.
--
-- @param _EntityType Typ des Entity
-- @param _Amount     Menge an Entities des Typs
-- @param _PlayerID   Besitzer des Entity
-- @return Table mit Behavior
-- @within Goal
--
function Goal_DestroyType(...)
    return b_Goal_DestroyType:new(...);
end

b_Goal_DestroyType = {
    Name = "Goal_DestroyType",
    Description = {
        en = "Goal: Destroy entity types",
        de = "Ziel: Zerstöre Entitätstypen",
    },
    Parameter = {
        { ParameterType.Custom, en = "Type name", de = "Typbezeichnung" },
        { ParameterType.Number, en = "Amount", de = "Anzahl" },
        { ParameterType.Custom, en = "Player", de = "Spieler" },
    },
}

function b_Goal_DestroyType:GetGoalTable(_Quest)
    return {Objective.DestroyEntities, 2, Entities[self.EntityName], self.Amount, self.PlayerID }
end

function b_Goal_DestroyType:AddParameter(_Index, _Parameter)
    if (_Index == 0) then
        self.EntityName = _Parameter
    elseif (_Index == 1) then
        self.Amount = _Parameter * 1
        self.DestroyTypeAmount = self.Amount
    elseif (_Index == 2) then
        self.PlayerID = _Parameter * 1
    end
end

function b_Goal_DestroyType:GetCustomData( _Index )
    local Data = {}
    if _Index == 0 then
        for k, v in pairs( Entities ) do
            if string.find( k, "^[ABU]_" ) then
                table.insert( Data, k )
            end
        end
        table.sort( Data )
    elseif _Index == 2 then
        for i = 0, 8 do
            table.insert( Data, i )
        end
    else
        assert( false )
    end
    return Data
end

function b_Goal_DestroyType:GetMsgKey()
    local ID = self.EntityName
    if Logic.IsEntityTypeInCategory( ID, EntityCategories.AttackableBuilding ) == 1 then
        return "Quest_DestroyEntities_Building"

    elseif Logic.IsEntityTypeInCategory( ID, EntityCategories.AttackableAnimal ) == 1 then
        return "Quest_DestroyEntities_Predators"

    elseif Logic.IsEntityTypeInCategory( ID, EntityCategories.Hero ) == 1 then
        return "Quest_Destroy_Leader"

    elseif Logic.IsEntityTypeInCategory( ID, EntityCategories.Military ) == 1
        or Logic.IsEntityTypeInCategory( ID, EntityCategories.AttackableSettler ) == 1
        or Logic.IsEntityTypeInCategory( ID, EntityCategories.AttackableMerchant ) == 1  then

        return "Quest_DestroyEntities_Unit"
    end
    return "Quest_DestroyEntities"
end

Core:RegisterBehavior(b_Goal_DestroyType);

-- -------------------------------------------------------------------------- --

do
    GameCallback_EntityKilled_Orig_QSB_Goal_DestroySoldiers = GameCallback_EntityKilled;
    GameCallback_EntityKilled = function(_AttackedEntityID, _AttackedPlayerID, _AttackingEntityID, _AttackingPlayerID, _AttackedEntityType, _AttackingEntityType)
        if _AttackedPlayerID ~= 0 and _AttackingPlayerID ~= 0 then
            QSB.DestroyedSoldiers[_AttackingPlayerID] = QSB.DestroyedSoldiers[_AttackingPlayerID] or {}
            QSB.DestroyedSoldiers[_AttackingPlayerID][_AttackedPlayerID] = QSB.DestroyedSoldiers[_AttackingPlayerID][_AttackedPlayerID] or 0
            if Logic.IsEntityTypeInCategory( _AttackedEntityType, EntityCategories.Military ) == 1
            and Logic.IsEntityInCategory( _AttackedEntityID, EntityCategories.HeavyWeapon) == 0 then
                QSB.DestroyedSoldiers[_AttackingPlayerID][_AttackedPlayerID] = QSB.DestroyedSoldiers[_AttackingPlayerID][_AttackedPlayerID] +1
            end
        end
        GameCallback_EntityKilled_Orig_QSB_Goal_DestroySoldiers(_AttackedEntityID, _AttackedPlayerID, _AttackingEntityID, _AttackingPlayerID, _AttackedEntityType, _AttackingEntityType)
    end
end

---
-- Spieler A muss Soldaten von Spieler B zerstören.
--
-- @param _PlayerA Angreifende Partei
-- @param _PlayerB Zielpartei
-- @param _Amount Menga an Soldaten
-- @return Table mit Behavior
-- @within Goal
--
function Goal_DestroySoldiers(...)
    return b_Goal_DestroySoldiers:new(...);
end

b_Goal_DestroySoldiers = {
    Name = "Goal_DestroySoldiers",
    Description = {
        en = "Goal: Destroy a given amount of enemy soldiers",
        de = "Ziel: Zerstöre eine Anzahl gegnerischer Soldaten",
                },
    Parameter = {
        {ParameterType.PlayerID, en = "Attacking Player", de = "Angreifer", },
        {ParameterType.PlayerID, en = "Defending Player", de = "Verteidiger", },
        {ParameterType.Number, en = "Amount", de = "Anzahl", },
    },
}

function b_Goal_DestroySoldiers:GetGoalTable()
    return {Objective.Custom2, {self, self.CustomFunction} }
end

function b_Goal_DestroySoldiers:AddParameter(_Index, _Parameter)
    if (_Index == 0) then
        self.AttackingPlayer = _Parameter * 1
    elseif (_Index == 1) then
        self.AttackedPlayer = _Parameter * 1
    elseif (_Index == 2) then
        self.KillsNeeded = _Parameter * 1
    end
end

function b_Goal_DestroySoldiers:CustomFunction(_Quest)
    if not _Quest.QuestDescription or _Quest.QuestDescription == "" then
        local lang = (Network.GetDesiredLanguage() == "de" and "de") or "en"
        local caption = (lang == "de" and "SOLDATEN ZERST�REN {cr}{cr}von der Partei: ") or
                         "DESTROY SOLDIERS {cr}{cr}from faction: "
        local amount  = (lang == "de" and "Anzahl: ") or "Amount: "
        local party = GetPlayerName(self.AttackedPlayer);
        if party == "" or party == nil then
            party = ((lang == "de" and "Spieler ") or "Player ") .. self.AttackedPlayer
        end
        local text = "{center}" .. caption .. party .. "{cr}{cr}" .. amount .. " "..self.KillsNeeded;
        Core:ChangeCustomQuestCaptionText(text, _Quest);
    end

    local currentKills = 0;
    if QSB.DestroyedSoldiers[self.AttackingPlayer] and QSB.DestroyedSoldiers[self.AttackingPlayer][self.AttackedPlayer] then
        currentKills = QSB.DestroyedSoldiers[self.AttackingPlayer][self.AttackedPlayer]
    end
    self.SaveAmount = self.SaveAmount or currentKills
    return self.KillsNeeded <= currentKills - self.SaveAmount or nil
end

function b_Goal_DestroySoldiers:DEBUG(_Quest)
    if Logic.GetStoreHouse(self.AttackingPlayer) == 0 then
        dbg(_Quest.Identifier .. " " .. self.Name .. ": Player " .. self.AttackinPlayer .. " is dead :-(")
        return true
    elseif Logic.GetStoreHouse(self.AttackedPlayer) == 0 then
        dbg(_Quest.Identifier .. " " .. self.Name .. ": Player " .. self.AttackedPlayer .. " is dead :-(")
        return true
    elseif self.KillsNeeded < 0 then
        dbg(_Quest.Identifier .. " " .. self.Name .. ": Amount negative")
        return true
    end
end

function b_Goal_DestroySoldiers:GetIcon()
    return {7,12}
end

function b_Goal_DestroySoldiers:Reset()
    self.SaveAmount = nil
end

Core:RegisterBehavior(b_Goal_DestroySoldiers)

---
-- Eine Entfernung zwischen zwei Entities muss erreicht werden.
--
-- Je nach angegebener Relation muss die Entfernung unter- oder überschritten
-- werden um den Quest zu gewinnen.
--
-- @param _ScriptName1  Erstes Entity
-- @param _ScriptName2  Zweites Entity
-- @param _Relation     Relation
-- @param _Distance     Entfernung
-- @return Table mit Behavior
-- @within Goal
--
function Goal_EntityDistance(...)
    return b_Goal_EntityDistance:new(...);
end

b_Goal_EntityDistance = {
    Name = "Goal_EntityDistance",
    Description = {
        en = "Goal: Distance between two entities",
        de = "Ziel: Zwei Entities sollen zueinander eine Entfernung über- oder unterschreiten.",
    },
    Parameter = {
        { ParameterType.ScriptName, en = "Entity 1", de = "Entity 1" },
        { ParameterType.ScriptName, en = "Entity 2", de = "Entity 2" },
        { ParameterType.Custom, en = "Relation", de = "Relation" },
        { ParameterType.Number, en = "Distance", de = "Entfernung" },
    },
}

function b_Goal_EntityDistance:GetGoalTable(_Quest)
    return { Objective.Custom2, {self, self.CustomFunction} }
end

function b_Goal_EntityDistance:AddParameter(_Index, _Parameter)
    if (_Index == 0) then
        self.Entity1 = _Parameter
    elseif (_Index == 1) then
        self.Entity2 = _Parameter
    elseif (_Index == 2) then
        self.bRelSmallerThan = _Parameter == "<"
    elseif (_Index == 3) then
        self.Distance = _Parameter * 1
    end
end

function b_Goal_EntityDistance:CustomFunction(_Quest)
    if Logic.IsEntityDestroyed( self.Entity1 ) or Logic.IsEntityDestroyed( self.Entity2 ) then
        return false
    end
    local ID1 = GetID( self.Entity1 )
    local ID2 = GetID( self.Entity2 )
    local InRange = Logic.CheckEntitiesDistance( ID1, ID2, self.Distance )
    if ( self.bRelSmallerThan and InRange ) or ( not self.bRelSmallerThan and not InRange ) then
        return true
    end
end

function b_Goal_EntityDistance:GetCustomData( _Index )
    local Data = {}
    if _Index == 2 then
        table.insert( Data, ">" )
        table.insert( Data, "<" )
    else
        assert( false )
    end
    return Data
end

function b_Goal_EntityDistance:DEBUG(_Quest)
    if not IsExisting(self.Entity1) or not IsExisting(self.Entity2) then
        dbg("".._Quest.Identifier.." "..self.Name..": At least 1 of the entities for distance check don't exist!");
        return true;
    end
    return false;
end

Core:RegisterBehavior(b_Goal_EntityDistance);

-- -------------------------------------------------------------------------- --

---
-- Der Primary Knight des angegebenen Spielers muss sich dem Ziel nähern.
--
-- @param _PlayerID   PlayerID des Helden
-- @param _ScriptName Skriptname des Ziels
-- @return Table mit Behavior
-- @within Goal
--
function Goal_KnightDistance(...)
    return b_Goal_KnightDistance:new(...);
end

b_Goal_KnightDistance = {
    Name = "Goal_KnightDistance",
    Description = {
        en = "Goal: Bring the knight close to a given entity",
        de = "Ziel: Bringe den Ritter nah an eine bestimmte Entität",
    },
    Parameter = {
        { ParameterType.PlayerID,     en = "Player", de = "Spieler" },
        { ParameterType.ScriptName, en = "Target", de = "Ziel" },
    },
}

function b_Goal_KnightDistance:GetGoalTable()
    return {Objective.Distance, Logic.GetKnightID(self.PlayerID), self.Target, 2500, true}
end

function b_Goal_KnightDistance:AddParameter(_Index, _Parameter)
    if (_Index == 0) then
        self.PlayerID = _Parameter * 1
    elseif (_Index == 1) then
        self.Target = _Parameter
    end
end

Core:RegisterBehavior(b_Goal_KnightDistance);

---
-- Eine bestimmte Anzahl an Einheiten einer Kategorie muss sich auf dem
-- Territorium befinden.
--
-- Die gegenebe Anzahl kann entweder als Mindestwert oder als Maximalwert
-- gesucht werden.
--
-- @param _Territory  TerritoryID oder TerritoryName
-- @param _PlayerID   PlayerID der Einheiten
-- @param _Category   Kategorie der Einheiten
-- @param _Relation   Mengenrelation (< oder >=)
-- @param _Amount     Menge an Einheiten
-- @return Table mit Behavior
-- @within Goal
--
function Goal_UnitsOnTerritory(...)
    return b_Goal_UnitsOnTerritory:new(...);
end

b_Goal_UnitsOnTerritory = {
    Name = "Goal_UnitsOnTerritory",
    Description = {
        en = "Goal: Place a certain amount of units on a territory",
        de = "Ziel: Platziere eine bestimmte Anzahl Einheiten auf einem Gebiet",
    },
    Parameter = {
        { ParameterType.TerritoryNameWithUnknown, en = "Territory", de = "Territorium" },
        { ParameterType.Custom,  en = "Player", de = "Spieler" },
        { ParameterType.Custom,  en = "Category", de = "Kategorie" },
        { ParameterType.Custom,  en = "Relation", de = "Relation" },
        { ParameterType.Number,  en = "Number of units", de = "Anzahl Einheiten" },
    },
}

function b_Goal_UnitsOnTerritory:GetGoalTable(_Quest)
    return { Objective.Custom2, {self, self.CustomFunction} }
end

function b_Goal_UnitsOnTerritory:AddParameter(_Index, _Parameter)
    if (_Index == 0) then
        self.TerritoryID = tonumber(_Parameter)
        if self.TerritoryID == nil then
            self.TerritoryID = GetTerritoryIDByName(_Parameter)
        end
    elseif (_Index == 1) then
        self.PlayerID = tonumber(_Parameter) * 1
    elseif (_Index == 2) then
        self.Category = _Parameter
    elseif (_Index == 3) then
        self.bRelSmallerThan = (tostring(_Parameter) == "true" or tostring(_Parameter) == "<")
    elseif (_Index == 4) then
        self.NumberOfUnits = _Parameter * 1
    end
end

function b_Goal_UnitsOnTerritory:CustomFunction(_Quest)
    local Units = GetEntitiesOfCategoryInTerritory(self.PlayerID, EntityCategories[self.Category], self.TerritoryID);
    if self.bRelSmallerThan == false and #Units >= self.NumberOfUnits then
        return true;
    elseif self.bRelSmallerThan == true and #Units < self.NumberOfUnits then
        return true;
    end
end

function b_Goal_UnitsOnTerritory:GetCustomData( _Index )
    local Data = {}
    if _Index == 1 then
        table.insert( Data, -1 )
        for i = 1, 8 do
            table.insert( Data, i )
        end
    elseif _Index == 2 then
        for k, v in pairs( EntityCategories ) do
            if not string.find( k, "^G_" ) and k ~= "SheepPasture" then
                table.insert( Data, k )
            end
        end
        table.sort( Data );
    elseif _Index == 3 then
        table.insert( Data, ">=" )
        table.insert( Data, "<" )
    else
        assert( false )
    end
    return Data
end

function b_Goal_UnitsOnTerritory:DEBUG(_Quest)
    local territories = {Logic.GetTerritories()}
    if tonumber(self.TerritoryID) == nil or self.TerritoryID < 0 or not Inside(self.TerritoryID,territories) then
        dbg("".._Quest.Identifier.." "..self.Name..": got an invalid territoryID!");
        return true;
    elseif tonumber(self.PlayerID) == nil or self.PlayerID < 0 or self.PlayerID > 8 then
        dbg("".._Quest.Identifier.." "..self.Name..": got an invalid playerID!");
        return true;
    elseif not EntityCategories[self.Category] then
        dbg("".._Quest.Identifier.." "..self.Name..": got an invalid playerID!");
        return true;
    elseif tonumber(self.NumberOfUnits) == nil or self.NumberOfUnits < 0 then
        dbg("".._Quest.Identifier.." "..self.Name..": amount is negative or nil!");
        return true;
    end
    return false;
end

Core:RegisterBehavior(b_Goal_UnitsOnTerritory);

-- -------------------------------------------------------------------------- --

---
-- Der angegebene Spieler muss einen Buff aktivieren.
--
-- <u>Buffs</u>
-- <li>Buff_Spice: Salz</li>
-- <li>Buff_Colour: Farben</li>
-- <li>Buff_Entertainers: Entertainer anheuern</li>
-- <li>Buff_FoodDiversity: Vielfältige Nahrung</li>
-- <li>Buff_ClothesDiversity: Vielfältige Kleidung</li>
-- <li>Buff_HygieneDiversity: Vielfältige Hygiene</li>
-- <li>Buff_EntertainmentDiversity: Vielfältige Unterhaltung</li>
-- <li>Buff_Sermon: Predigt halten</li>
-- <li>Buff_Festival: Fest veranstalten</li>
-- <li>Buff_ExtraPayment: Bonussold auszahlen</li>
-- <li>Buff_HighTaxes: Hohe Steuern verlangen</li>
-- <li>Buff_NoPayment: Sold streichen</li>
-- <li>Buff_NoTaxes: Keine Steuern verlangen</li>
-- <br/>
-- <u>RdO Buffs</u>
-- <li>Buff_Gems: Edelsteine</li>
-- <li>Buff_MusicalInstrument: Musikinstrumente</li>
-- <li>Buff_Olibanum: Weihrauch</li>
--
-- @param _PlayerID Spieler, der den Buff aktivieren muss
-- @param _Buff     Buff, der aktiviert werden soll
-- @return Table mit Behavior
-- @within Goal
--
function Goal_ActivateBuff(...)
    return b_Goal_ActivateBuff:new(...);
end

b_Goal_ActivateBuff = {
    Name = "Goal_ActivateBuff",
    Description = {
        en = "Goal: Activate a buff",
        de = "Ziel: Aktiviere einen Buff",
    },
    Parameter = {
        { ParameterType.PlayerID, en = "Player", de = "Spieler" },
        { ParameterType.Custom, en = "Buff", de = "Buff" },
    },
}

function b_Goal_ActivateBuff:GetGoalTable(_Quest)
    return { Objective.Custom2, {self, self.CustomFunction} }
end

function b_Goal_ActivateBuff:AddParameter(_Index, _Parameter)
    if (_Index == 0) then
        self.PlayerID = _Parameter * 1
    elseif (_Index == 1) then
        self.BuffName = _Parameter
        self.Buff = Buffs[_Parameter]
    end
end

function b_Goal_ActivateBuff:CustomFunction(_Quest)
   if not _Quest.QuestDescription or _Quest.QuestDescription == "" then
        local lang = (Network.GetDesiredLanguage() == "de" and "de") or "en"
        local caption = (lang == "de" and "BONUS AKTIVIEREN{cr}{cr}") or "ACTIVATE BUFF{cr}{cr}"

        local tMapping = {
            ["Buff_Spice"]                        = {de = "Salz", en = "Salt"},
            ["Buff_Colour"]                        = {de = "Farben", en = "Color"},
            ["Buff_Entertainers"]                = {de = "Entertainer", en = "Entertainer"},
            ["Buff_FoodDiversity"]                = {de = "Vielf�ltige Nahrung", en = "Food diversity"},
            ["Buff_ClothesDiversity"]            = {de = "Vielf�ltige Kleidung", en = "Clothes diversity"},
            ["Buff_HygieneDiversity"]            = {de = "Vielf�ltige Reinigung", en = "Hygiene diversity"},
            ["Buff_EntertainmentDiversity"]        = {de = "Vielf�ltige Unterhaltung", en = "Entertainment diversity"},
            ["Buff_Sermon"]                        = {de = "Predigt", en = "Sermon"},
            ["Buff_Festival"]                    = {de = "Fest", en = "Festival"},
            ["Buff_ExtraPayment"]                = {de = "Sonderzahlung", en = "Extra payment"},
            ["Buff_HighTaxes"]                    = {de = "Hohe Steuern", en = "High taxes"},
            ["Buff_NoPayment"]                    = {de = "Kein Sold", en = "No payment"},
            ["Buff_NoTaxes"]                    = {de = "Keine Steuern", en = "No taxes"},
        }

        if g_GameExtraNo >= 1 then
            tMapping["Buff_Gems"]                = {de = "Edelsteine", en = "Gems"}
            tMapping["Buff_MusicalInstrument"]  = {de = "Musikinstrumente", en = "Musical instruments"}
            tMapping["Buff_Olibanum"]            = {de = "Weihrauch", en = "Olibanum"}
        end

        local text = "{center}" .. caption .. tMapping[self.BuffName][lang]
        Core:ChangeCustomQuestCaptionText(text, _Quest)
    end

    local Buff = Logic.GetBuff( self.PlayerID, self.Buff )
    if Buff and Buff ~= 0 then
        return true
    end
end

function b_Goal_ActivateBuff:GetCustomData( _Index )
    local Data = {}
    if _Index == 1 then
        Data = {
            "Buff_Spice",
            "Buff_Colour",
            "Buff_Entertainers",
            "Buff_FoodDiversity",
            "Buff_ClothesDiversity",
            "Buff_HygieneDiversity",
            "Buff_EntertainmentDiversity",
            "Buff_Sermon",
            "Buff_Festival",
            "Buff_ExtraPayment",
            "Buff_HighTaxes",
            "Buff_NoPayment",
            "Buff_NoTaxes"
        }

        if g_GameExtraNo >= 1 then
            table.insert(Data, "Buff_Gems")
            table.insert(Data, "Buff_MusicalInstrument")
            table.insert(Data, "Buff_Olibanum")
        end

        table.sort( Data )
    else
        assert( false )
    end
    return Data
end

function b_Goal_ActivateBuff:GetIcon()
    local tMapping = {
        [Buffs.Buff_Spice] = "Goods.G_Salt",
        [Buffs.Buff_Colour] = "Goods.G_Dye",
        [Buffs.Buff_Entertainers] = "Entities.U_Entertainer_NA_FireEater", --{5, 12},
        [Buffs.Buff_FoodDiversity] = "Needs.Nutrition", --{1, 1},
        [Buffs.Buff_ClothesDiversity] = "Needs.Clothes", --{1, 2},
        [Buffs.Buff_HygieneDiversity] = "Needs.Hygiene", --{16, 1},
        [Buffs.Buff_EntertainmentDiversity] = "Needs.Entertainment", --{1, 4},
        [Buffs.Buff_Sermon] = "Technologies.R_Sermon", --{4, 14},
        [Buffs.Buff_Festival] = "Technologies.R_Festival", --{4, 15},
        [Buffs.Buff_ExtraPayment]    = {1,8},
        [Buffs.Buff_HighTaxes] = {1,6},
        [Buffs.Buff_NoPayment] = {1,8},
        [Buffs.Buff_NoTaxes]    = {1,6},
    }
    if g_GameExtraNo and g_GameExtraNo >= 1 then
        tMapping[Buffs.Buff_Gems] = "Goods.G_Gems"
        tMapping[Buffs.Buff_MusicalInstrument] = "Goods.G_MusicalInstrument"
        tMapping[Buffs.Buff_Olibanum] = "Goods.G_Olibanum"
    end
    return tMapping[self.Buff]
end

function b_Goal_ActivateBuff:DEBUG(_Quest)
    if not self.Buff then
        dbg("".._Quest.Identifier.." "..self.Name..": buff '" ..self.BuffName.. "' does not exist!");
        return true;
    elseif not tonumber(self.PlayerID) or self.PlayerID < 1 or self.PlayerID > 8 then
        dbg("".._Quest.Identifier.." "..self.Name..": got an invalid playerID!");
        return true;
    end
    return false;
end

Core:RegisterBehavior(b_Goal_ActivateBuff);

-- -------------------------------------------------------------------------- --

---
-- Zwei Punkte auf der Spielwelt müssen mit einer Straße verbunden werden.
--
-- @param _Position1 Erster Endpunkt der Straße
-- @param _Position2 Zweiter Endpunkt der Straße
-- @param _OnlyRoads Keine Wege akzeptieren
-- @return Table mit Behavior
-- @within Goal
--
function Goal_BuildRoad(...)
    return b_Goal_BuildRoad:new(...)
end

b_Goal_BuildRoad = {
    Name = "Goal_BuildRoad",
    Description = {
        en = "Goal: Connect two points with a street or a road",
        de = "Ziel: Verbinde zwei Punkte mit einer Strasse oder einem Weg.",
    },
    Parameter = {
        { ParameterType.ScriptName, en = "Entity 1",     de = "Entity 1" },
        { ParameterType.ScriptName, en = "Entity 2",     de = "Entity 2" },
        { ParameterType.Custom,     en = "Only roads",     de = "Nur Strassen" },
    },
}

function b_Goal_BuildRoad:GetGoalTable(_Quest)
    return { Objective.BuildRoad, { GetID( self.Entity1 ),
                                     GetID( self.Entity2 ),
                                     false,
                                     0,
                                     self.bRoadsOnly } }

end

function b_Goal_BuildRoad:AddParameter(_Index, _Parameter)
    if (_Index == 0) then
        self.Entity1 = _Parameter
    elseif (_Index == 1) then
        self.Entity2 = _Parameter
    elseif (_Index == 2) then
        self.bRoadsOnly = AcceptAlternativeBoolean(_Parameter)
    end
end

function b_Goal_BuildRoad:GetCustomData( _Index )
    local Data
    if _Index == 2 then
        Data = {"true","false"}
    end
    return Data
end

function b_Goal_BuildRoad:DEBUG(_Quest)
    if not IsExisting(self.Entity1) or not IsExisting(self.Entity2) then
        dbg("".._Quest.Identifier.." "..self.Name..": first or second entity does not exist!");
        return true;
    end
    return false;
end

Core:RegisterBehavior(b_Goal_BuildRoad);

-- -------------------------------------------------------------------------- --


---
-- Eine Mauer muss die Bewegung eines Spielers zwischen 2 Punkten einschränken.
--
-- <b>Achtung:</b> Bei Monsun kann dieses Ziel fälschlicher Weise als erfüllt gewertet
-- werden, wenn der Weg durch Wasser blockiert wird!
--
-- @param _PlayerID  PlayerID, die blockiert wird
-- @param _Position1 Erste Position
-- @param _Position2 Zweite Position
-- @return Table mit Behavior
-- @within Goal
--
function Goal_BuildWall(...)
    return b_Goal_BuildWall:new(...)
end

b_Goal_BuildWall = {
    Name = "Goal_BuildWall",
    Description = {
        en = "Goal: Build a wall between 2 positions bo stop the movement of an (hostile) player.",
        de = "Ziel: Baue eine Mauer zwischen 2 Punkten, die die Bewegung eines (feindlichen) Spielers zwischen den Punkten verhindert.",
    },
    Parameter = {
        { ParameterType.PlayerID, en = "Enemy", de = "Feind" },
        { ParameterType.ScriptName, en = "Entity 1", de = "Entity 1" },
        { ParameterType.ScriptName, en = "Entity 2", de = "Entity 2" },
    },
}

function b_Goal_BuildWall:GetGoalTable(_Quest)
    return { Objective.Custom2, {self, self.CustomFunction} }
end

function b_Goal_BuildWall:AddParameter(_Index, _Parameter)
    if (_Index == 0) then
        self.PlayerID = _Parameter * 1
    elseif (_Index == 1) then
        self.EntityName1 = _Parameter
    elseif (_Index == 2) then
        self.EntityName2 = _Parameter
    end
end

function b_Goal_BuildWall:CustomFunction(_Quest)
    local eID1 = GetID(self.EntityName1)
    local eID2 = GetID(self.EntityName2)

    if not IsExisting(eID1) then
        return false
    end
    if not IsExisting(eID2) then
        return false
    end
    local x,y,z = Logic.EntityGetPos(eID1)
    if Logic.IsBuilding(eID1) == 1 then
        x,y = Logic.GetBuildingApproachPosition(eID1)
    end
    local Sector1 = Logic.GetPlayerSectorAtPosition(self.PlayerID, x, y)
    local x,y,z = Logic.EntityGetPos(eID2)
    if Logic.IsBuilding(eID2) == 1 then
        x,y = Logic.GetBuildingApproachPosition(eID2)
    end
    local Sector2 = Logic.GetPlayerSectorAtPosition(self.PlayerID, x, y)
    if Sector1 ~= Sector2 then
        return true
    end
    return nil
end

function b_Goal_BuildWall:GetMsgKey()
    return "Quest_Create_Wall"
end

function b_Goal_BuildWall:GetIcon()
    return {3,9}
end

function b_Goal_BuildWall:DEBUG(_Quest)
    if not IsExisting(self.EntityName1) or not IsExisting(self.EntityName2) then
        dbg("".._Quest.Identifier.." "..self.Name..": first or second entity does not exist!");
        return true;
    elseif not tonumber(self.PlayerID) or self.PlayerID < 1 or self.PlayerID > 8 then
        dbg("".._Quest.Identifier.." "..self.Name..": got an invalid playerID!");
        return true;
    end

    if GetDiplomacyState(_Quest.ReceivingPlayer, self.PlayerID) > -1 and not self.WarningPrinted then
        warn("".._Quest.Identifier.." "..self.Name..": player %d is neighter enemy or unknown to quest receiver!");
        self.WarningPrinted = true;
    end
    return false;
end

Core:RegisterBehavior(b_Goal_BuildWall);

-- -------------------------------------------------------------------------- --

---
-- Ein bestimmtes Territorium muss vom Auftragnehmer eingenommen werden.
--
-- @param _Territory Territorium-ID oder Territoriumname
-- @return Table mit Behavior
-- @within Goal
--
function Goal_Claim(...)
    return b_Goal_Claim:new(...)
end

b_Goal_Claim = {
    Name = "Goal_Claim",
    Description = {
        en = "Goal: Claim a territory",
        de = "Ziel: Erobere ein Territorium",
    },
    Parameter = {
        { ParameterType.TerritoryName, en = "Territory", de = "Territorium" },
    },
}

function b_Goal_Claim:GetGoalTable(_Quest)
    return { Objective.Claim, 1, self.TerritoryID }
end

function b_Goal_Claim:AddParameter(_Index, _Parameter)
    if (_Index == 0) then
        self.TerritoryID = tonumber(_Parameter)
        if not self.TerritoryID then
            self.TerritoryID = GetTerritoryIDByName(_Parameter)
        end
    end
end

function b_Goal_Claim:GetMsgKey()
    return "Quest_Claim_Territory"
end

Core:RegisterBehavior(b_Goal_Claim);

-- -------------------------------------------------------------------------- --

---
-- Der Auftragnehmer muss eine Menge an Territorien besitzen.
--
-- Das Heimatterritorium des Spielers wird mitgezählt!
--
-- @param _Amount Anzahl Territorien
-- @return Table mit Behavior
-- @within Goal
--
function Goal_ClaimXTerritories(...)
    return b_Goal_ClaimXTerritories:new(...)
end

b_Goal_ClaimXTerritories = {
    Name = "Goal_ClaimXTerritories",
    Description = {
        en = "Goal: Claim the given number of territories, all player territories are counted",
        de = "Ziel: Erobere die angegebene Anzahl Territorien, alle spielereigenen Territorien werden gezählt",
    },
    Parameter = {
        { ParameterType.Number, en = "Territories" , de = "Territorien" }
    },
}

function b_Goal_ClaimXTerritories:GetGoalTable(_Quest)
    return { Objective.Claim, 2, self.TerritoriesToClaim }
end

function b_Goal_ClaimXTerritories:AddParameter(_Index, _Parameter)
    if (_Index == 0) then
        self.TerritoriesToClaim = _Parameter * 1
    end
end

function b_Goal_ClaimXTerritories:GetMsgKey()
    return "Quest_Claim_Territory"
end

Core:RegisterBehavior(b_Goal_ClaimXTerritories);

-- -------------------------------------------------------------------------- --

---
-- Der Auftragnehmer muss auf dem Territorium einen Entitytyp erstellen.
--
-- @param _Type      Typ des Entity
-- @param _Amount    Menge an Entities
-- @param _Territory Territorium
-- @return Table mit Behavior
-- @within Goal
--
function Goal_Create(...)
    return b_Goal_Create:new(...);
end

b_Goal_Create = {
    Name = "Goal_Create",
    Description = {
        en = "Goal: Create Buildings/Units on a specified territory",
        de = "Ziel: Erstelle Einheiten/Gebäude auf einem bestimmten Territorium.",
    },
    Parameter = {
        { ParameterType.Entity, en = "Type name", de = "Typbezeichnung" },
        { ParameterType.Number, en = "Amount", de = "Anzahl" },
        { ParameterType.TerritoryNameWithUnknown, en = "Territory", de = "Territorium" },
    },
}

function b_Goal_Create:GetGoalTable(_Quest)
    return { Objective.Create, assert( Entities[self.EntityName] ), self.Amount, self.TerritoryID  }
end

function b_Goal_Create:AddParameter(_Index, _Parameter)
    if (_Index == 0) then
        self.EntityName = _Parameter
    elseif (_Index == 1) then
        self.Amount = _Parameter * 1
    elseif (_Index == 2) then
        self.TerritoryID = tonumber(_Parameter)
        if not self.TerritoryID then
            self.TerritoryID = GetTerritoryIDByName(_Parameter)
        end
    end
end

function b_Goal_Create:GetMsgKey()
    return Logic.IsEntityTypeInCategory( Entities[self.EntityName], EntityCategories.AttackableBuilding ) == 1 and "Quest_Create_Building" or "Quest_Create_Unit"
end

Core:RegisterBehavior(b_Goal_Create);

-- -------------------------------------------------------------------------- --

---
-- Der Auftragnehmer muss eine Menge von Rohstoffen produzieren.
--
-- @param _Type   Typ des Rohstoffs
-- @param _Amount Menge an Rohstoffen
-- @return Table mit Behavior
-- @within Goal
--
function Goal_Produce(...)
    return b_Goal_Produce:new(...);
end

b_Goal_Produce = {
    Name = "Goal_Produce",
    Description = {
        en = "Goal: Produce an amount of goods",
        de = "Ziel: Produziere eine Anzahl einer bestimmten Ware.",
    },
    Parameter = {
        { ParameterType.RawGoods, en = "Type of good", de = "Ressourcentyp" },
        { ParameterType.Number, en = "Amount of good", de = "Anzahl der Ressource" },
    },
}

function b_Goal_Produce:GetGoalTable(_Quest)
    local GoodType = Logic.GetGoodTypeID(self.GoodTypeName)
    return { Objective.Produce, GoodType, self.GoodAmount }
end

function b_Goal_Produce:AddParameter(_Index, _Parameter)
    if (_Index == 0) then
        self.GoodTypeName = _Parameter
    elseif (_Index == 1) then
        self.GoodAmount = _Parameter * 1
    end
end

function b_Goal_Produce:GetMsgKey()
    return "Quest_Produce"
end

Core:RegisterBehavior(b_Goal_Produce);

-- -------------------------------------------------------------------------- --

---
-- Der Spieler muss eine bestimmte Menge einer Ware erreichen.
--
-- @param _Type     Typ der Ware
-- @param _Amount   Menge an Waren
-- @param _Relation Mengenrelation
-- @return Table mit Behavior
-- @within Goal
--
function Goal_GoodAmount(...)
    return b_Goal_GoodAmount:new(...);
end

b_Goal_GoodAmount = {
    Name = "Goal_GoodAmount",
    Description = {
        en = "Goal: Obtain an amount of goods - either by trading or producing them",
        de = "Ziel: Beschaffe eine Anzahl Waren - entweder durch Handel oder durch eigene Produktion.",
    },
    Parameter = {
        { ParameterType.Custom, en = "Type of good", de = "Warentyp" },
        { ParameterType.Number, en = "Amount", de = "Anzahl" },
        { ParameterType.Custom, en = "Relation", de = "Relation" },
    },
}

function b_Goal_GoodAmount:GetGoalTable(_Quest)
    local GoodType = Logic.GetGoodTypeID(self.GoodTypeName)
    return { Objective.Produce, GoodType, self.GoodAmount, self.bRelSmallerThan }
end

function b_Goal_GoodAmount:AddParameter(_Index, _Parameter)
    if (_Index == 0) then
        self.GoodTypeName = _Parameter
    elseif (_Index == 1) then
        self.GoodAmount = _Parameter * 1
    elseif  (_Index == 2) then
        self.bRelSmallerThan = _Parameter == "<" or tostring(_Parameter) == "true"
    end
end

function b_Goal_GoodAmount:GetCustomData( _Index )
    local Data = {}
    if _Index == 0 then
        for k, v in pairs( Goods ) do
            if string.find( k, "^G_" ) then
                table.insert( Data, k )
            end
        end
        table.sort( Data )
    elseif _Index == 2 then
        table.insert( Data, ">=" )
        table.insert( Data, "<" )
    else
        assert( false )
    end
    return Data
end

Core:RegisterBehavior(b_Goal_GoodAmount);

-- -------------------------------------------------------------------------- --

---
-- Die Siedler des Spielers dürfen nicht aufgrund des Bedürfnisses streiken.
--
-- <u>Bedürfnisse</u>
-- <ul>
-- <li>Clothes: Kleidung</li>
-- <li>Entertainment: Unterhaltung</li>
-- <li>Nutrition: Nahrung</li>
-- <li>Hygiene: Hygiene</li>
-- <li>Medicine: Medizin</li>
-- </ul>
--
-- @param _PlayerID ID des Spielers
-- @param _Need     Bedürfnis
-- @return Table mit Behavior
-- @within Goal
--
function Goal_SatisfyNeed(...)
    return b_Goal_SatisfyNeed:new(...);
end

b_Goal_SatisfyNeed = {
    Name = "Goal_SatisfyNeed",
    Description = {
        en = "Goal: Satisfy a need",
        de = "Ziel: Erfuelle ein Beduerfnis",
    },
    Parameter = {
        { ParameterType.PlayerID, en = "Player", de = "Spieler" },
        { ParameterType.Need, en = "Need", de = "Beduerfnis" },
    },
}

function b_Goal_SatisfyNeed:GetGoalTable(_Quest)
    return { Objective.SatisfyNeed, self.PlayerID, assert( Needs[self.Need] ) }

end

function b_Goal_SatisfyNeed:AddParameter(_Index, _Parameter)

    if (_Index == 0) then
        self.PlayerID = _Parameter * 1
    elseif (_Index == 1) then
        self.Need = _Parameter
    end

end

function b_Goal_SatisfyNeed:GetMsgKey()
    local tMapping = {
        [Needs.Clothes] = "Quest_SatisfyNeed_Clothes",
        [Needs.Entertainment] = "Quest_SatisfyNeed_Entertainment",
        [Needs.Nutrition] = "Quest_SatisfyNeed_Food",
        [Needs.Hygiene] = "Quest_SatisfyNeed_Hygiene",
        [Needs.Medicine] = "Quest_SatisfyNeed_Medicine",
    }

    local Key = tMapping[Needs[self.Need]]
    if Key then
        return Key
    end

    -- No default message
end

Core:RegisterBehavior(b_Goal_SatisfyNeed);

-- -------------------------------------------------------------------------- --

---
-- Der Auftragnehmer muss eine Menge an Siedlern in der Stadt haben.
--
-- @param _Amount Menge an Siedlern
-- @return Table mit Behavior
-- @within Goal
--
function Goal_SettlersNumber(...)
    return b_Goal_SettlersNumber:new(...);
end

b_Goal_SettlersNumber = {
    Name = "Goal_SettlersNumber",
    Description = {
        en = "Goal: Get a given amount of settlers",
        de = "Ziel: Erreiche eine bestimmte Anzahl Siedler.",
    },
    Parameter = {
        { ParameterType.Number, en = "Amount", de = "Anzahl" },
    },
}

function b_Goal_SettlersNumber:GetGoalTable()
    return {Objective.SettlersNumber, 1, self.SettlersAmount }
end

function b_Goal_SettlersNumber:AddParameter(_Index, _Parameter)
    if (_Index == 0) then
        self.SettlersAmount = _Parameter * 1
    end
end

function b_Goal_SettlersNumber:GetMsgKey()
    return "Quest_NumberSettlers"
end

Core:RegisterBehavior(b_Goal_SettlersNumber);

-- -------------------------------------------------------------------------- --

---
-- Der Auftragnehmer muss eine Menge von Ehefrauen in der Stadt haben.
--
-- @param _Amount Menge an Ehefrauen
-- @return Table mit Behavior
-- @within Goal
--
function Goal_Spouses(...)
    return b_Goal_Spouses:new(...);    
end

b_Goal_Spouses = {
    Name = "Goal_Spouses",
    Description = {
        en = "Goal: Get a given amount of spouses",
        de = "Ziel: Erreiche eine bestimmte Ehefrauenanzahl",
    },
    Parameter = {
        { ParameterType.Number, en = "Amount", de = "Anzahl" },
    },
}

function b_Goal_Spouses:GetGoalTable()
    return {Objective.Spouses, self.SpousesAmount }
end

function b_Goal_Spouses:AddParameter(_Index, _Parameter)
    if (_Index == 0) then
        self.SpousesAmount = _Parameter * 1
    end
end

function b_Goal_Spouses:GetMsgKey()
    return "Quest_NumberSpouses"
end

Core:RegisterBehavior(b_Goal_Spouses);

-- -------------------------------------------------------------------------- --

---
-- Ein Spieler muss eine Menge an Soldaten haben.
--
-- <u>Relationen</u>
-- <ul>
-- <li>>= - Anzahl als Mindestmenge</li>
-- <li>< - Weniger als Anzahl</li>
-- </ul>
--
-- @param _PlayerID ID des Spielers
-- @param _Relation Mengenrelation
-- @param _Amount   Menge an Soldaten
-- @return Table mit Behavior
-- @within Goal
--
function Goal_SoldierCount(...)
    return b_Goal_SoldierCount:new(...);
end

b_Goal_SoldierCount = {
    Name = "Goal_SoldierCount",
    Description = {
        en = "Goal: Create a specified number of soldiers",
        de = "Ziel: Erreiche eine Anzahl grösser oder kleiner der angegebenen Menge Soldaten.",
    },
    Parameter = {
        { ParameterType.PlayerID, en = "Player", de = "Spieler" },
        { ParameterType.Custom, en = "Relation", de = "Relation" },
        { ParameterType.Number, en = "Number of soldiers", de = "Anzahl Soldaten" },
    },
}

function b_Goal_SoldierCount:GetGoalTable(_Quest)
    return { Objective.Custom2, {self, self.CustomFunction} }
end

function b_Goal_SoldierCount:AddParameter(_Index, _Parameter)
    if (_Index == 0) then
        self.PlayerID = _Parameter * 1
    elseif (_Index == 1) then
        self.bRelSmallerThan = tostring(_Parameter) == "true" or tostring(_Parameter) == "<"
    elseif (_Index == 2) then
        self.NumberOfUnits = _Parameter * 1
    end
end

function b_Goal_SoldierCount:CustomFunction(_Quest)
    if not _Quest.QuestDescription or _Quest.QuestDescription == "" then
        local lang = (Network.GetDesiredLanguage() == "de" and "de") or "en"
        local caption = (lang == "de" and "SOLDATENANZAHL {cr}Partei: ") or
                            "SOLDIERS {cr}faction: "
        local relation = tostring(self.bRelSmallerThan);
        local relationText = {
            ["true"]  = {de = "Weniger als", en = "Less than"},
            ["false"] = {de = "Mindestens", en = "At least"},
        };
        local party = GetPlayerName(self.PlayerID);
        if party == "" or party == nil then
            party = ((lang == "de" and "Spieler ") or "Player ") .. self.PlayerID
        end
        local text = "{center}" .. caption .. party .. "{cr}{cr}" .. relationText[relation][lang] .. " "..self.NumberOfUnits;
        Core:ChangeCustomQuestCaptionText(text, _Quest);
    end

    local NumSoldiers = Logic.GetCurrentSoldierCount( self.PlayerID )
    if ( self.bRelSmallerThan and NumSoldiers < self.NumberOfUnits ) then
        return true
    elseif ( not self.bRelSmallerThan and NumSoldiers >= self.NumberOfUnits ) then
        return true
    end
    return nil
end

function b_Goal_SoldierCount:GetCustomData( _Index )
    local Data = {}
    if _Index == 1 then

        table.insert( Data, ">=" )
        table.insert( Data, "<" )

    else
        assert( false )
    end
    return Data
end

function b_Goal_SoldierCount:GetIcon()
    return {7,11}
end

function b_Goal_SoldierCount:GetMsgKey()
    return "Quest_Create_Unit"
end

function b_Goal_SoldierCount:DEBUG(_Quest)
    if tonumber(self.NumberOfUnits) == nil or self.NumberOfUnits < 0 then
        dbg("".._Quest.Identifier.." "..self.Name..": amount can not be below 0!");
        return true;
    elseif tonumber(self.PlayerID) == nil or self.PlayerID < 1 or self.PlayerID > 8 then
        dbg("".._Quest.Identifier.." "..self.Name..": got an invalid playerID!");
        return true;
    end
    return false;
end

Core:RegisterBehavior(b_Goal_SoldierCount);

-- -------------------------------------------------------------------------- --

---
-- Der Auftragnehmer muss wenigstens einen bestimmten Titel erreichen.
--
-- @param _Title Titel, der erreicht werden muss
-- @return Table mit Behavior
-- @within Goal
--
function Goal_KnightTitle(...)
    return b_Goal_KnightTitle:new(...);
end

b_Goal_KnightTitle = {
    Name = "Goal_KnightTitle",
    Description = {
        en = "Goal: Reach a specified knight title",
        de = "Ziel: Erreiche einen vorgegebenen Titel",
    },
    Parameter = {
        { ParameterType.Custom, en = "Knight title", de = "Titel" },
    },
}

function b_Goal_KnightTitle:GetGoalTable()
    return {Objective.KnightTitle, assert( KnightTitles[self.KnightTitle] ) }
end

function b_Goal_KnightTitle:AddParameter(_Index, _Parameter)
    if (_Index == 0) then
        self.KnightTitle = _Parameter
    end
end

function b_Goal_KnightTitle:GetMsgKey()
    return "Quest_KnightTitle"
end

function b_Goal_KnightTitle:GetCustomData( _Index )
    return {"Knight", "Mayor", "Baron", "Earl", "Marquees", "Duke", "Archduke"}
end

Core:RegisterBehavior(b_Goal_KnightTitle);

-- -------------------------------------------------------------------------- --

---
-- Der angegebene Spieler muss mindestens die Menge an Festen feiern.
--
-- @param _PlayerID ID des Spielers
-- @param _Amount   Menge an Festen
-- @return Table mit Behavior
-- @within Goal
--
function Goal_Festivals(...)
    return b_Goal_Festivals:new(...);
end

b_Goal_Festivals = {
    Name = "Goal_Festivals",
    Description = {
        en = "Goal: The player has to start the given number of festivals.",
        de = "Ziel: Der Spieler muss eine gewisse Anzahl Feste gestartet haben.",
    },
    Parameter = {
        { ParameterType.PlayerID, en = "Player", de = "Spieler" },
        { ParameterType.Number, en = "Number of festivals", de = "Anzahl Feste" }
    }
};

function b_Goal_Festivals:GetGoalTable()
    return { Objective.Custom2, {self, self.CustomFunction} };
end

function b_Goal_Festivals:AddParameter(_Index, _Parameter)
    if _Index == 0 then
        self.PlayerID = tonumber(_Parameter);
    else
        assert(_Index == 1, "Error in " .. self.Name .. ": AddParameter: Index is invalid.");
        self.NeededFestivals = tonumber(_Parameter);
    end
end

function b_Goal_Festivals:CustomFunction(_Quest)
    if not _Quest.QuestDescription or _Quest.QuestDescription == "" then
        local lang = (Network.GetDesiredLanguage() == "de" and "de") or "en"
        local caption = (lang == "de" and "FESTE FEIERN {cr}{cr}Partei: ") or
                            "HOLD PARTIES {cr}{cr}faction: "
        local amount  = (lang == "de" and "Anzahl: ") or "Amount: "
        local party = GetPlayerName(self.PlayerID);
        if party == "" or party == nil then
            party = ((lang == "de" and "Spieler ") or "Player ") .. self.PlayerID
        end
        local text = "{center}" .. caption .. party .. "{cr}{cr}" .. amount .. " "..self.NeededFestivals;
        Core:ChangeCustomQuestCaptionText(text, _Quest);
    end

    if Logic.GetStoreHouse( self.PlayerID ) == 0  then
        return false
    end
    local tablesOnFestival = {Logic.GetPlayerEntities(self.PlayerID, Entities.B_TableBeer, 5,0)}
    local amount = 0
    for k=2, #tablesOnFestival do
        local tableID = tablesOnFestival[k]
        if Logic.GetIndexOnOutStockByGoodType(tableID, Goods.G_Beer) ~= -1 then
            local goodAmountOnMarketplace = Logic.GetAmountOnOutStockByGoodType(tableID, Goods.G_Beer)
            amount = amount + goodAmountOnMarketplace
        end
    end
    if not self.FestivalStarted and amount > 0 then
        self.FestivalStarted = true
        self.FestivalCounter = (self.FestivalCounter and self.FestivalCounter + 1) or 1
        if self.FestivalCounter >= self.NeededFestivals then
            self.FestivalCounter = nil
            return true
        end
    elseif amount == 0 then
        self.FestivalStarted = false
    end
end

function b_Goal_Festivals:DEBUG(_Quest)
    if Logic.GetStoreHouse( self.PlayerID ) == 0 then
        dbg(_Quest.Identifier .. ": Error in " .. self.Name .. ": Player " .. self.PlayerID .. " is dead :-(")
        return true
    elseif GetPlayerCategoryType(self.PlayerID) ~= PlayerCategories.City then
        dbg(_Quest.Identifier .. ": Error in " .. self.Name .. ":  Player "..  self.PlayerID .. " is no city")
        return true
    elseif self.NeededFestivals < 0 then
        dbg(_Quest.Identifier .. ": Error in " .. self.Name .. ": Number of Festivals is negative")
        return true
    end
    return false
end

function b_Goal_Festivals:Reset()
    self.FestivalCounter = nil
    self.FestivalStarted = nil
end

function b_Goal_Festivals:GetIcon()
    return {4,15}
end

Core:RegisterBehavior(b_Goal_Festivals)

-- -------------------------------------------------------------------------- --

---
-- Der Auftragnehmer muss eine Einheit gefangen nehmen.
--
-- @param _ScriptName Ziel
-- @return Table mit Behavior
-- @within Goal
--
function Goal_Capture(...)
    return b_Goal_Capture:new(...)
end

b_Goal_Capture = {
    Name = "Goal_Capture",
    Description = {
        en = "Goal: Capture a cart.",
        de = "Ziel: Ein Karren muss erobert werden.",
    },
    Parameter = {
        { ParameterType.ScriptName, en = "Script name", de = "Skriptname" },
    },
}

function b_Goal_Capture:GetGoalTable(_Quest)
    return { Objective.Capture, 1, { self.ScriptName } }
end

function b_Goal_Capture:AddParameter(_Index, _Parameter)
    if (_Index == 0) then
        self.ScriptName = _Parameter
    end
end

function b_Goal_Capture:GetMsgKey()
   local ID = GetID(self.ScriptName)
   if Logic.IsEntityAlive(ID) then
        ID = Logic.GetEntityType( ID )
        if ID and ID ~= 0 then
            if Logic.IsEntityTypeInCategory( ID, EntityCategories.AttackableMerchant ) == 1 then
                return "Quest_Capture_Cart"

            elseif Logic.IsEntityTypeInCategory( ID, EntityCategories.SiegeEngine ) == 1 then
                return "Quest_Capture_SiegeEngine"

            elseif Logic.IsEntityTypeInCategory( ID, EntityCategories.Worker ) == 1
                or Logic.IsEntityTypeInCategory( ID, EntityCategories.Spouse ) == 1
                or Logic.IsEntityTypeInCategory( ID, EntityCategories.Hero ) == 1 then

                return "Quest_Capture_VIPOfPlayer"

            end
        end
    end
end

Core:RegisterBehavior(b_Goal_Capture);

-- -------------------------------------------------------------------------- --

---
-- Der Auftragnehmer muss eine Menge von Einheiten eines Typs von einem
-- Spieler gefangen nehmen.
--
-- @param _Typ      Typ, der gefangen werden soll
-- @param _Amount   Menge an Einheiten
-- @param _PlayerID Besitzer der Einheiten
-- @return Table mit Behavior
-- @within Goal
--
function Goal_CaptureType(...)
    return b_Goal_CaptureType:new(...)
end

b_Goal_CaptureType = {
    Name = "Goal_CaptureType",
    Description = {
        en = "Goal: Capture specified entity types",
        de = "Ziel: Nimm bestimmte Entitätstypen gefangen",
    },
    Parameter = {
        { ParameterType.Custom,     en = "Type name", de = "Typbezeichnung" },
        { ParameterType.Number,     en = "Amount", de = "Anzahl" },
        { ParameterType.PlayerID,     en = "Player", de = "Spieler" },
    },
}

function b_Goal_CaptureType:GetGoalTable(_Quest)
    return { Objective.Capture, 2, Entities[self.EntityName], self.Amount, self.PlayerID }
end

function b_Goal_CaptureType:AddParameter(_Index, _Parameter)
    if (_Index == 0) then
        self.EntityName = _Parameter
    elseif (_Index == 1) then
        self.Amount = _Parameter * 1
    elseif (_Index == 2) then
        self.PlayerID = _Parameter * 1
    end
end

function b_Goal_CaptureType:GetCustomData( _Index )
    local Data = {}
    if _Index == 0 then
        for k, v in pairs( Entities ) do
            if string.find( k, "^U_.+Cart" ) or Logic.IsEntityTypeInCategory( v, EntityCategories.AttackableMerchant ) == 1 then
                table.insert( Data, k )
            end
        end
        table.sort( Data )
    elseif _Index == 2 then
        for i = 0, 8 do
            table.insert( Data, i )
        end
    else
        assert( false )
    end
    return Data
end

function b_Goal_CaptureType:GetMsgKey()

    local ID = self.EntityName
    if Logic.IsEntityTypeInCategory( ID, EntityCategories.AttackableMerchant ) == 1 then
        return "Quest_Capture_Cart"

    elseif Logic.IsEntityTypeInCategory( ID, EntityCategories.SiegeEngine ) == 1 then
        return "Quest_Capture_SiegeEngine"

    elseif Logic.IsEntityTypeInCategory( ID, EntityCategories.Worker ) == 1
        or Logic.IsEntityTypeInCategory( ID, EntityCategories.Spouse ) == 1
        or Logic.IsEntityTypeInCategory( ID, EntityCategories.Hero ) == 1 then

        return "Quest_Capture_VIPOfPlayer"
    end
end

Core:RegisterBehavior(b_Goal_CaptureType);

-- -------------------------------------------------------------------------- --

---
-- Der Auftragnehmer muss das angegebene Entity beschützen.
--
-- Gefangennahme (bzw. Besitzerwechsel) oder Zerstörung des Entity werden als
-- Fehlschlag gewertet.
--
-- @param _ScriptName
-- @return Table mit Behavior
-- @within Goal
--
function Goal_Protect(...)
    return b_Goal_Protect:new(...)
end

b_Goal_Protect = {
    Name = "Goal_Protect",
    Description = {
        en = "Goal: Protect an entity (entity needs a script name",
        de = "Ziel: Beschuetze eine Entität (Entität benötigt einen Skriptnamen)",
    },
    Parameter = {
        { ParameterType.ScriptName, en = "Script name", de = "Skriptname" },
    },
}

function b_Goal_Protect:GetGoalTable()
    return {Objective.Protect, { self.ScriptName }}
end

function b_Goal_Protect:AddParameter(_Index, _Parameter)
    if (_Index == 0) then
        self.ScriptName = _Parameter
    end
end

function b_Goal_Protect:GetMsgKey()
    if Logic.IsEntityAlive(self.ScriptName) then
        local ID = GetID(self.ScriptName)
        if ID and ID ~= 0 then
            ID = Logic.GetEntityType( ID )
            if ID and ID ~= 0 then
                if Logic.IsEntityTypeInCategory( ID, EntityCategories.AttackableBuilding ) == 1 then
                    return "Quest_Protect_Building"

                elseif Logic.IsEntityTypeInCategory( ID, EntityCategories.SpecialBuilding ) == 1 then
                    local tMapping = {
                        [PlayerCategories.City]        = "Quest_Protect_City",
                        [PlayerCategories.Cloister]    = "Quest_Protect_Cloister",
                        [PlayerCategories.Village]    = "Quest_Protect_Village",
                    }

                    local PlayerCategory = GetPlayerCategoryType( Logic.EntityGetPlayer(GetID(self.ScriptName)) )
                    if PlayerCategory then
                        local Key = tMapping[PlayerCategory]
                        if Key then
                            return Key
                        end
                    end

                    return "Quest_Protect_Building"

                elseif Logic.IsEntityTypeInCategory( ID, EntityCategories.Hero ) == 1 then
                    return "Quest_Protect_Knight"

                elseif Logic.IsEntityTypeInCategory( ID, EntityCategories.AttackableMerchant ) == 1 then
                    return "Quest_Protect_Cart"

                end
            end
        end
    end

    return "Quest_Protect"
end

Core:RegisterBehavior(b_Goal_Protect);

-- -------------------------------------------------------------------------- --

---
-- Der AUftragnehmer muss eine Mine mit einem Geologen wieder auffüllen.
--
-- <b>Achtung:</b> Ausschließlich im Reich des Ostens verfügbar!
--
-- @param _ScriptName Skriptname der Mine
-- @return Table mit Behavior
-- @within Goal
--
function Goal_Refill(...)
    return b_Goal_Refill:new(...)
end

b_Goal_Refill = {
    Name = "Goal_Refill",
    Description = {
        en = "Goal: Refill an object using a geologist",
        de = "Ziel: Eine Mine soll durch einen Geologen wieder aufgefuellt werden.",
    },
    Parameter = {
        { ParameterType.ScriptName, en = "Script name", de = "Skriptname" },
    },
   RequiresExtraNo = 1,
}

function b_Goal_Refill:GetGoalTable()
    return { Objective.Refill, { GetID(self.ScriptName) } }
end

function b_Goal_Refill:GetIcon()
    return {8,1,1}
end

function b_Goal_Refill:AddParameter(_Index, _Parameter)
    if (_Index == 0) then
        self.ScriptName = _Parameter
    end
end

Core:RegisterBehavior(b_Goal_Refill);

-- -------------------------------------------------------------------------- --

---
-- Der Auftragnehmer muss eine Menge an Rohstoffen in einer Mine erreichen.
--
-- <u>Relationen</u>
-- <ul>
-- <li>> - Mehr als Anzahl</li>
-- <li>< - Weniger als Anzahl</li>
-- </ul>
--
-- @param _ScriptName Skriptname der Mine
-- @param _Relation   Mengenrelation
-- @param _Amount     Menge an Rohstoffen
-- @return Table mit Behavior
-- @within Goal
--
function Goal_ResourceAmount(...)
    return b_Goal_ResourceAmount:new(...)
end

b_Goal_ResourceAmount = {
    Name = "Goal_ResourceAmount",
    Description = {
        en = "Goal: Reach a specified amount of resources in a doodad",
        de = "Ziel: In einer Mine soll weniger oder mehr als eine angegebene Anzahl an Rohstoffen sein.",
    },
    Parameter = {
        { ParameterType.ScriptName, en = "Script name", de = "Skriptname" },
        { ParameterType.Custom, en = "Relation", de = "Relation" },
        { ParameterType.Number, en = "Amount", de = "Menge" },
    },
}

function b_Goal_ResourceAmount:GetGoalTable(_Quest)
    return { Objective.Custom2, {self, self.CustomFunction} }
end

function b_Goal_ResourceAmount:AddParameter(_Index, _Parameter)
    if (_Index == 0) then
        self.ScriptName = _Parameter
    elseif (_Index == 1) then
        self.bRelSmallerThan = _Parameter == "<"
    elseif (_Index == 2) then
        self.Amount = _Parameter * 1
    end
end

function b_Goal_ResourceAmount:CustomFunction(_Quest)
    local ID = GetID(self.ScriptName)
    if ID and ID ~= 0 and Logic.GetResourceDoodadGoodType(ID) ~= 0 then
        local HaveAmount = Logic.GetResourceDoodadGoodAmount(ID)
        if ( self.bRelSmallerThan and HaveAmount < self.Amount ) or ( not self.bRelSmallerThan and HaveAmount > self.Amount ) then
            return true
        end
    end
    return nil
end

function b_Goal_ResourceAmount:GetCustomData( _Index )
    local Data = {}
    if _Index == 1 then
        table.insert( Data, ">" )
        table.insert( Data, "<" )
    else
        assert( false )
    end
    return Data
end

function b_Goal_ResourceAmount:DEBUG(_Quest)
    if not IsExisting(self.ScriptName) then
        dbg("".._Quest.Identifier.." "..self.Name..": entity '" ..self.ScriptName.. "' does not exist!");
        return true;
    elseif tonumber(self.Amount) == nil or self.Amount < 0 then
        dbg("".._Quest.Identifier.." "..self.Name..": error at amount! (nil or below 0)");
        return true;
    end
    return false;
end

Core:RegisterBehavior(b_Goal_ResourceAmount);

-- -------------------------------------------------------------------------- --

---
-- Der Quest schlägt sofort fehl.
--
-- @return Table mit Behavior
-- @within Goal
--
function Goal_InstantFailure()
    return b_Goal_InstantFailure:new()
end

b_Goal_InstantFailure = {
    Name = "Goal_InstantFailure",
    Description = {
        en = "Instant failure, the goal returns false.",
        de = "Direkter Misserfolg, das Goal sendet false.",
    },
}

function b_Goal_InstantFailure:GetGoalTable(_Quest)
    return {Objective.DummyFail};
end

Core:RegisterBehavior(b_Goal_InstantFailure);

-- -------------------------------------------------------------------------- --

---
-- Der Quest wird sofort erfüllt. 
--
-- @return Table mit Behavior
-- @within Goal
--
function Goal_InstantSuccess()
    return b_Goal_InstantSuccess:new()
end

b_Goal_InstantSuccess = {
    Name = "Goal_InstantSuccess",
    Description = {
        en = "Instant success, the goal returns true.",
        de = "Direkter Erfolg, das Goal sendet true.",
    },
}

function b_Goal_InstantSuccess:GetGoalTable(_Quest)
    return {Objective.Dummy};
end

Core:RegisterBehavior(b_Goal_InstantSuccess);

-- -------------------------------------------------------------------------- --

---
-- Der Zustand des Quests ändert sich niemals
--
-- @return Table mit Behavior
-- @within Goal
--
function Goal_NoChange()
    return b_Goal_NoChange:new()
end

b_Goal_NoChange = {
    Name = "Goal_NoChange",
    Description = {
        en = "The quest state doesn't change. Use reward functions of other quests to change the state of this quest.",
        de = "Der Questzustand wird nicht verändert. Ein Reward einer anderen Quest sollte den Zustand dieser Quest verändern.",
    },
}

function b_Goal_NoChange:GetGoalTable()
    return { Objective.NoChange }
end

Core:RegisterBehavior(b_Goal_NoChange);

-- -------------------------------------------------------------------------- --

---
-- Führt eine Funktion im Skript als Goal aus.
--
-- Die Funktion muss entweder true, false oder nichts zurückgeben.
-- <ul>
-- <li>true: Erfolgreich abgeschlossen</li>
-- <li>false: Fehlschlag</li>
-- <li>nichts: Zustand unbestimmt</li>
-- </ul>
--
-- @param _FunctionName Name der Funktion
-- @return Table mit Behavior
-- @within Goal
--
function Goal_MapScriptFunction(...)
    return b_Goal_MapScriptFunction:new(...);
end

b_Goal_MapScriptFunction = {
    Name = "Goal_MapScriptFunction",
    Description = {
        en = "Goal: Calls a function within the global map script. Return 'true' means success, 'false' means failure and 'nil' doesn't change anything.",
        de = "Ziel: Ruft eine Funktion im globalen Skript auf, die einen Wahrheitswert zurueckgibt. Rueckgabe 'true' gilt als erfuellt, 'false' als gescheitert und 'nil' ändert nichts.",
    },
    Parameter = {
        { ParameterType.Default, en = "Function name", de = "Funktionsname" },
    },
}

function b_Goal_MapScriptFunction:GetGoalTable(_Quest)
    return {Objective.Custom2, {self, self.CustomFunction}};
end

function b_Goal_MapScriptFunction:AddParameter(_Index, _Parameter)
    if (_Index == 0) then
        self.FuncName = _Parameter
    end
end

function b_Goal_MapScriptFunction:CustomFunction(_Quest)
    return _G[self.FuncName](self, _Quest);
end

function b_Goal_MapScriptFunction:DEBUG(_Quest)
    if not self.FuncName or not _G[self.FuncName] then
        dbg("".._Quest.Identifier.." "..self.Name..": function '" ..self.FuncName.. "' does not exist!");
        return true;
    end
    return false;
end

Core:RegisterBehavior(b_Goal_MapScriptFunction);

-- -------------------------------------------------------------------------- --

---
-- Eine benutzerdefinierte Variable muss einen bestimmten Wert haben.
--
-- Custom Variables können ausschließlich Zahlen enthalten.
--
-- <p>Vergleichsoperatoren</p>
-- <ul>
-- <li>== - Werte müssen gleich sein</li>
-- <li>~= - Werte müssen ungleich sein</li>
-- <li>> - Variablenwert größer Vergleichswert</li>
-- <li>>= - Variablenwert größer oder gleich Vergleichswert</li>
-- <li>< - Variablenwert kleiner Vergleichswert</li>
-- <li><= - Variablenwert kleiner oder gleich Vergleichswert</li>
-- </ul>
--
-- @param _Name     Name der Variable
-- @param _Relation Vergleichsoperator
-- @param _Value    Wert oder andere Custom Variable mit wert.
-- @return Table mit Behavior
-- @within Goal
--
function Goal_CustomVariables(...)
    return b_Goal_CustomVariables:new(...);
end

b_Goal_CustomVariables = {
    Name = "Goal_CustomVariables",
    Description = {
        en = "Goal: A customised variable has to assume a certain value.",
        de = "Ziel: Eine benutzerdefinierte Variable muss einen bestimmten Wert annehmen.",
    },
    Parameter = {
        { ParameterType.Default, en = "Name of Variable", de = "Variablenname" },
        { ParameterType.Custom,  en = "Relation", de = "Relation" },
        { ParameterType.Default, en = "Value or variable", de = "Wert oder Variable" }
    }
};

function b_Goal_CustomVariables:GetGoalTable()
    return { Objective.Custom2, {self, self.CustomFunction} };
end

function b_Goal_CustomVariables:AddParameter(_Index, _Parameter)
    if _Index == 0 then
        self.VariableName = _Parameter
    elseif _Index == 1 then
        self.Relation = _Parameter
    elseif _Index == 2 then
        local value = tonumber(_Parameter);
        value = (value ~= nil and value) or tostring(_Parameter);
        self.Value = value
    end
end

function b_Goal_CustomVariables:CustomFunction()
    if _G["QSB_CustomVariables_"..self.VariableName] then
        local Value = (type(self.Value) ~= "string" and self.Value) or _G["QSB_CustomVariables_"..self.Value];
        if self.Relation == "==" then
            if _G["QSB_CustomVariables_"..self.VariableName] == Value then
                return true;
            end
        elseif self.Relation == "~=" then
            if _G["QSB_CustomVariables_"..self.VariableName] == Value then
                return true;
            end
        elseif self.Relation == "<" then
            if _G["QSB_CustomVariables_"..self.VariableName] < Value then
                return true;
            end
        elseif self.Relation == "<=" then
            if _G["QSB_CustomVariables_"..self.VariableName] <= Value then
                return true;
            end
        elseif self.Relation == ">=" then
            if _G["QSB_CustomVariables_"..self.VariableName] >= Value then
                return true;
            end
        else
            if _G["QSB_CustomVariables_"..self.VariableName] > Value then
                return true;
            end
        end
    end
    return nil;
end

function b_Goal_CustomVariables:GetCustomData( _Index )
    return {"==", "~=", "<=", "<", ">", ">="};
end

function b_Goal_CustomVariables:DEBUG(_Quest)
    local relations = {"==", "~=", "<=", "<", ">", ">="}
    local results    = {true, false, nil}

    if not _G["QSB_CustomVariables_"..self.VariableName] then
        dbg(_Quest.Identifier.." "..self.Name..": variable '"..self.VariableName.."' do not exist!");
        return true;
    elseif not Inside(self.Relation,relations) then
        dbg(_Quest.Identifier.." "..self.Name..": '"..self.Relation.."' is an invalid relation!");
        return true;
    end
    return false;
end

Core:RegisterBehavior(b_Goal_CustomVariables)

-- -------------------------------------------------------------------------- --

---
-- Der Spieler muss im Chatdialog ein Passwort eingeben.
--
-- Es können auch mehrere Passwörter verwendet werden. Dazu muss die Liste
-- der Passwörter abgetrennt mit ; angegeben werden.
--
-- <b>Achtung:</b> Ein Passwort darf immer nur aus einem Wort bestehen!
--
-- @param _VarName   Name der Lösungsvariablen
-- @param _Message   Nachricht bei Falscheingabe
-- @param _Passwords Liste der Passwörter
-- @param _Trials    Anzahl versuche (-1 für unendlich)
-- @return Table mit Behavior
-- @within Goal
--
function Goal_InputDialog(...)
    return b_Goal_InputDialog:new(...);
end

b_Goal_InputDialog  = {
    Name = "Goal_InputDialog",
    Description = {
        en = "Goal: Player must type in something. The passwords have to be seperated by ; and whitespaces will be ignored.",
        de = "Ziel: Oeffnet einen Dialog, der Spieler muss Lösungswörter eingeben. Diese sind durch ; abzutrennen. Leerzeichen werden ignoriert.",
    },
    Parameter = {
        {ParameterType.Default, en = "ReturnVariable", de = "Name der Variable" },
        {ParameterType.Default, en = "Message", de = "Nachricht" },
        {ParameterType.Default, en = "Passwords", de = "Lösungswörter" },
        {ParameterType.Number,  en = "Trials Till Correct Password (0 = Forever)", de = "Versuche (0 = unbegrenzt)" },
    }
}

function b_Goal_InputDialog:GetGoalTable(_Quest)
    return { Objective.Custom2, {self, self.CustomFunction}}
end

function b_Goal_InputDialog:AddParameter(_Index, _Parameter)
    if (_Index == 0) then
        self.Variable = _Parameter
    elseif (_Index == 1) then
        self.Message = _Parameter
    elseif (_Index == 2) then
        local str = _Parameter;
        self.Password = {};

        str = str;
        str = string.lower(str);
        str = string.gsub(str, " ", "");
        while (string.len(str) > 0)
        do
            local s,e = string.find(str, ";");
            if e then
                table.insert(self.Password, string.sub(str, 1, e-1));
                str = string.sub(str, e+1, string.len(str));
            else
                table.insert(self.Password, str);
                str = "";
            end
        end
    elseif (_Index == 3) then
        self.TryTillCorrect = (_Parameter == nil and -1) or (_Parameter * 1)
    end
end

function b_Goal_InputDialog:CustomFunction(_Quest)
    local function Box( __returnVariable_ )
        if not self.shown then
            self:InitReturnVariable(__returnVariable_)
            self:ShowBox()
            self.shown = true
        end
    end

    if not IsBriefingActive or (IsBriefingActive and IsBriefingActive() == false) then
        if (not self.TryTillCorrect) or (self.TryTillCorrect) == -1 then
            Box( self.Variable, self.Message )
        elseif not self.shown then
            self.TryCounter = self.TryCounter or self.TryTillCorrect
            Box( self.Variable, "" )
            self.TryCounter = self.TryCounter - 1
        end

        if _G[self.Variable] then
            Logic.ExecuteInLuaLocalState([[
                GUI_Chat.Confirm = GUI_Chat.Confirm_Orig_Goal_InputDialog
                GUI_Chat.Confirm_Orig_Goal_InputDialog = nil
                GUI_Chat.Abort = GUI_Chat.Abort_Orig_Goal_InputDialog
                GUI_Chat.Abort_Orig_Goal_InputDialog = nil
            ]]);

            if self.Password then

                self.shown = nil
                _G[self.Variable] = _G[self.Variable];
                _G[self.Variable] = string.lower(_G[self.Variable]);
                _G[self.Variable] = string.gsub(_G[self.Variable], " ", "");
                if Inside(_G[self.Variable], self.Password) then
                    return true
                elseif self.TryTillCorrect and ( self.TryTillCorrect == -1 or self.TryCounter > 0 ) then
                    Logic.DEBUG_AddNote(self.Message);
                    _G[self.Variable] = nil
                    return
                else
                    Logic.DEBUG_AddNote(self.Message);
                    _G[self.Variable] = nil
                    return false
                end
            end
            return true
        end
    end
end

function b_Goal_InputDialog:ShowBox()
    Logic.ExecuteInLuaLocalState([[
        Input.ChatMode()
        XGUIEng.ShowWidget("/InGame/Root/Normal/ChatInput",1)
        XGUIEng.SetText("/InGame/Root/Normal/ChatInput/ChatInput", "")
        XGUIEng.SetFocus("/InGame/Root/Normal/ChatInput/ChatInput")
    ]])
end

function b_Goal_InputDialog:InitReturnVariable(__string_)
    Logic.ExecuteInLuaLocalState([[
        GUI_Chat.Abort_Orig_Goal_InputDialog = GUI_Chat.Abort
        GUI_Chat.Confirm_Orig_Goal_InputDialog = GUI_Chat.Confirm

        GUI_Chat.Confirm = function()
            local _variable = "]]..__string_..[["
            Input.GameMode()

            XGUIEng.ShowWidget("/InGame/Root/Normal/ChatInput",0)
            local ChatMessage = XGUIEng.GetText("/InGame/Root/Normal/ChatInput/ChatInput")
            g_Chat.JustClosed = 1
            GUI.SendScriptCommand("_G[ \"".._variable.."\" ] = \""..ChatMessage.."\"")
        end

        GUI_Chat.Abort = function() end
    ]])
end

function b_Goal_InputDialog:DEBUG(_Quest)
    if tonumber(self.TryTillCorrect) == nil or self.TryTillCorrect == 0 then
        local text = string.format("%s %s: TryTillCorrect is nil or 0!",_Quest.Identifier,self.Name);
        dbg(text);
        return true;
    elseif type(self.Message) ~= "string" then
        local text = string.format("%s %s: Message is not valid!",_Quest.Identifier,self.Name);
        dbg(text);
        return true;
    elseif type(self.Variable) ~= "string" then
        local text = string.format("%s %s: Variable is not valid!",_Quest.Identifier,self.Name);
        dbg(text);
        return true;
    end

    for k,v in pairs(self.Password) do
        if type(v) ~= "string" then
            local text = string.format("%s %s: at least 1 password is not valid!",_Quest.Identifier,self.Name);
            dbg(text);
            return true;
        end
    end
    return false;
end

function b_Goal_InputDialog:GetIcon()
    return {12,2}
end

function b_Goal_InputDialog:Reset()
    _G[self.Variable] = nil;
    self.TryCounter = nil;
    self.shown = nil;
end

Core:RegisterBehavior(b_Goal_InputDialog);

-- -------------------------------------------------------------------------- --

---
-- Lässt den Spieler zwischen zwei Antworten wählen.
--
-- Dabei kann zwischen den Labels Ja/Nein und Ok/Abbrechen gewählt werden.
--
-- <b>Hinweis:</b> Es können nur geschlossene Fragen gestellt werden. Dialoge
-- müssen also immer mit Ja oder Nein beantwortbar sein oder auf Okay und
-- Abbrechen passen.
--
-- @param _Title  Fenstertitel
-- @param _Text   Fenstertext
-- @param _Labels Label der Buttons
-- @return Table mit Behavior
-- @within Goal
--
function Goal_Decide(...)
    return b_Goal_Decide:new(...);
end

b_Goal_Decide = {
    Name = "Goal_Decide",
    Description = {
        en = "Opens a Yes/No Dialog. Decision = Quest Result",
        de = "Oeffnet einen Ja/Nein-Dialog. Die Entscheidung bestimmt das Quest-Ergebnis (ja=true, nein=false).",
    },
    Parameter = {
        { ParameterType.Default, en = "Text", de = "Text", },
        { ParameterType.Default, en = "Title", de = "Titel", },
        { ParameterType.Custom, en = "Button labels", de = "Button Beschriftung", },
    },
}

function b_Goal_Decide:GetGoalTable()
    return { Objective.Custom2, { self, self.CustomFunction } }
end

function b_Goal_Decide:AddParameter( _Index, _Parameter )
    if (_Index == 0) then
        self.Text = _Parameter
    elseif (_Index == 1) then
        self.Title = _Parameter
    elseif (_Index == 2) then
        self.Buttons = (_Parameter == "Ok/Cancel")
    end
end

function b_Goal_Decide:CustomFunction(_Quest)
    if not IsBriefingActive or (IsBriefingActive and IsBriefingActive() == false) then
        if not self.LocalExecuted then
            if QSB.DialogActive then
                return;
            end
            QSB.DialogActive = true
            local buttons = (self.Buttons and "true") or "nil"
            self.LocalExecuted = true

            local commandString = [[
                Game.GameTimeSetFactor( GUI.GetPlayerID(), 0 )
                OpenRequesterDialog(%q,
                                    %q,
                                    "Game.GameTimeSetFactor( GUI.GetPlayerID(), 1 ); GUI.SendScriptCommand( 'QSB.DecisionWindowResult = true ')",
                                    %s ,
                                    "Game.GameTimeSetFactor( GUI.GetPlayerID(), 1 ); GUI.SendScriptCommand( 'QSB.DecisionWindowResult = false ')")
            ]];
            local commandString = string.format(commandString, self.Text, "{center} " .. self.Title, buttons)
            Logic.ExecuteInLuaLocalState(commandString);

        end
        local result = QSB.DecisionWindowResult
        if result ~= nil then
            QSB.DecisionWindowResult = nil
            QSB.DialogActive = false;
            return result
        end
    end
end

function b_Goal_Decide:Reset()
    self.LocalExecuted = nil;
end

function b_Goal_Decide:GetIcon()
    return {4,12}
end

function b_Goal_Decide:GetCustomData(_Index)
    if _Index == 2 then
        return { "Yes/No", "Ok/Cancel" }
    end
end

Core:RegisterBehavior(b_Goal_Decide);

-- -------------------------------------------------------------------------- --

---
-- Der Spieler kann durch regelmäßiges Begleichen eines Tributes bessere
-- Diplomatie zu einen Spieler erreichen.
--
-- @param _GoldAmount Menge an Gold
-- @param _Periode    Zahlungsperiode in Monaten
-- @param _Time       Zeitbegrenzung
-- @param _StartMsg   Vorschlagnachricht
-- @param _SuccessMsg Erfolgsnachricht
-- @param _FailureMsg Fehlschlagnachricht
-- @param _Restart    Nach nichtbezahlen neu starten
-- @return Table mit Behavior
-- @within Goal
--
function Goal_TributeDiplomacy(...)
    return b_Goal_TributeDiplomacy:new(...);
end

b_Goal_TributeDiplomacy = {
    Name = "Goal_TributeDiplomacy",
    Description = {
        en = "Goal: AI requests periodical tribute for better Diplomacy",
        de = "Ziel: Die KI fordert einen regelmässigen Tribut fuer bessere Diplomatie. Der Questgeber ist der fordernde Spieler.",
    },
    Parameter = {
        { ParameterType.Number, en = "Amount", de = "Menge", },
        { ParameterType.Custom, en = "Length of Period in month", de = "Monate bis zur nächsten Forderung", },
        { ParameterType.Number, en = "Time to pay Tribut in seconds", de = "Zeit bis zur Zahlung in Sekunden", },
        { ParameterType.Default, en = "Start Message for TributQuest", de = "Startnachricht der Tributquest", },
        { ParameterType.Default, en = "Success Message for TributQuest", de = "Erfolgsnachricht der Tributquest", },
        { ParameterType.Default, en = "Failure Message for TributQuest", de = "Niederlagenachricht der Tributquest", },
        { ParameterType.Custom, en = "Restart if failed to pay", de = "Nicht-bezahlen beendet die Quest", },
    },
}

function b_Goal_TributeDiplomacy:GetGoalTable()
    return {Objective.Custom2, {self, self.CustomFunction} }
end

function b_Goal_TributeDiplomacy:AddParameter(_Index, _Parameter)
    if (_Index == 0) then
        self.Amount = _Parameter * 1
    elseif (_Index == 1) then
        self.PeriodLength = _Parameter * 150
    elseif (_Index == 2) then
        self.TributTime = _Parameter * 1
    elseif (_Index == 3) then
        self.StartMsg = _Parameter
    elseif (_Index == 4) then
        self.SuccessMsg = _Parameter
    elseif (_Index == 5) then
        self.FailureMsg = _Parameter
    elseif (_Index == 6) then
        self.RestartAtFailure = AcceptAlternativeBoolean(_Parameter)
    end
end

function b_Goal_TributeDiplomacy:CustomFunction(_Quest)
    if not self.Time then
        if self.PeriodLength - 150 < self.TributTime then
            Logic.DEBUG_AddNote("b_Goal_TributeDiplomacy: TributTime too long")
        end
    end
    if not self.QuestStarted then
        self.QuestStarted = QuestTemplate:New(_Quest.Identifier.."TributeBanditQuest" , _Quest.SendingPlayer, _Quest.ReceivingPlayer,
                                    {{ Objective.Deliver, {Goods.G_Gold, self.Amount}}},
                                    {{ Triggers.Time, 0 }},
                                    self.TributTime,
                                    nil, nil, nil, nil, true, true,
                                    nil,
                                    self.StartMsg,
                                    self.SuccessMsg,
                                    self.FailureMsg
                                    )
        self.Time = Logic.GetTime()
    end
    local TributeQuest = Quests[self.QuestStarted]
    if self.QuestStarted and TributeQuest.State == QuestState.Over and not self.RestartQuest then
        if TributeQuest.Result ~= QuestResult.Success then
            SetDiplomacyState( _Quest.ReceivingPlayer, _Quest.SendingPlayer, DiplomacyStates.Enemy)
            if not self.RestartAtFailure then
                return false
            end
        else
            SetDiplomacyState( _Quest.ReceivingPlayer, _Quest.SendingPlayer, DiplomacyStates.TradeContact)
        end

        self.RestartQuest = true
    end
    local storeHouse = Logic.GetStoreHouse(_Quest.SendingPlayer)
    if (storeHouse == 0 or Logic.IsEntityDestroyed(storeHouse)) then
        if self.QuestStarted and Quests[self.QuestStarted].State == QuestState.Active then
            Quests[self.QuestStarted]:Interrupt()
        end
        return true
    end
    if self.QuestStarted and self.RestartQuest and ( (Logic.GetTime() - self.Time) >= self.PeriodLength ) then
        TributeQuest.Objectives[1].Completed = nil
        TributeQuest.Objectives[1].Data[3] = nil
        TributeQuest.Objectives[1].Data[4] = nil
        TributeQuest.Objectives[1].Data[5] = nil
        TributeQuest.Result = nil
        TributeQuest.State = QuestState.NotTriggered
        Logic.ExecuteInLuaLocalState("LocalScriptCallback_OnQuestStatusChanged("..TributeQuest.Index..")")
        Trigger.RequestTrigger(Events.LOGIC_EVENT_EVERY_SECOND, "", QuestTemplate.Loop, 1, 0, { TributeQuest.QueueID })
        self.Time = Logic.GetTime()
        self.RestartQuest = nil
    end
end

function b_Goal_TributeDiplomacy:DEBUG(_Quest)
    if self.Amount < 0 then
        dbg(_Quest.Identifier .. " " .. self.Name .. ": Amount is negative")
        return true
    end
end

function b_Goal_TributeDiplomacy:Reset()
    self.Time = nil
    self.QuestStarted = nil
    self.RestartQuest = nil
end

function b_Goal_TributeDiplomacy:Interrupt(_Quest)
    if self.QuestStarted and Quests[self.QuestStarted] ~= nil then
        if Quests[self.QuestStarted].State == QuestState.Active then
            Quests[self.QuestStarted]:Interrupt()
        end
    end
end

function b_Goal_TributeDiplomacy:GetCustomData(_index)
    if (_index == 1) then
        return { "1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "11", "12"}
    elseif (_index == 6) then
        return { "true", "false" }
    end
end

Core:RegisterBehavior(b_Goal_TributeDiplomacy)

-- -------------------------------------------------------------------------- --

---
-- Erlaubt es dem Spieler ein Territorium zu mieten.
--
-- Zerstört der Spieler den Außenposten, schlägt der Quest fehl und das
-- Territorium wird an den Vermieter übergeben.
--
-- @param _Territory  Name des Territorium
-- @param _PlayerID   PlayerID des Zahlungsanforderer
-- @param _Cost       Menge an Gold
-- @param _Periode    Zahlungsperiode in Monaten
-- @param _Time       Zeitbegrenzung
-- @param _StartMsg   Vorschlagnachricht
-- @param _SuccessMsg Erfolgsnachricht
-- @param _FailMsg    Fehlschlagnachricht
-- @param _HowOften   Anzahl an Zahlungen (0 = endlos)
-- @param _OtherOwner Eroberung durch Dritte beendet Quest
-- @param _Abort      Nach nichtbezahlen abbrechen
-- @return Table mit Behavior
-- @within Goal
--
function Goal_TributeClaim(...)
    return b_Goal_TributeClaim:new(...);
end

b_Goal_TributeClaim = {
    Name = "Goal_TributeClaim",
    Description = {
        en = "Goal: AI requests periodical tribute for a specified Territory",
        de = "Ziel: Die KI fordert einen regelmässigen Tribut fuer ein Territorium. Der Questgeber ist der fordernde Spieler.",
                },
    Parameter = {
        { ParameterType.TerritoryName, en = "Territory", de = "Territorium", },
        { ParameterType.PlayerID, en = "PlayerID", de = "PlayerID", },
        { ParameterType.Number, en = "Amount", de = "Menge", },
        { ParameterType.Custom, en = "Length of Period in month", de = "Monate bis zur nächsten Forderung", },
        { ParameterType.Number, en = "Time to pay Tribut in seconds", de = "Zeit bis zur Zahlung in Sekunden", },
        { ParameterType.Default, en = "Start Message for TributQuest", de = "Startnachricht der Tributquest", },
        { ParameterType.Default, en = "Success Message for TributQuest", de = "Erfolgsnachricht der Tributquest", },
        { ParameterType.Default, en = "Failure Message for TributQuest", de = "Niederlagenachricht der Tributquest", },
        { ParameterType.Number, en = "How often to pay (0 = forerver)", de = "Anzahl der Tributquests (0 = unendlich)", },
        { ParameterType.Custom, en = "Other Owner cancels the Quest", de = "Anderer Spieler kann Quest beenden", },
        { ParameterType.Custom, en = "About if a rate is not payed", de = "Nicht-bezahlen beendet die Quest", },
    },
}

function b_Goal_TributeClaim:GetGoalTable()
    return {Objective.Custom2, {self, self.CustomFunction} }
end

function b_Goal_TributeClaim:AddParameter(_Index, _Parameter)
    if (_Index == 0) then
        self.TerritoryID = GetTerritoryIDByName(_Parameter)
    elseif (_Index == 1) then
        self.PlayerID = _Parameter * 1
    elseif (_Index == 2) then
        self.Amount = _Parameter * 1
    elseif (_Index == 3) then
        self.PeriodLength = _Parameter * 150
    elseif (_Index == 4) then
        self.TributTime = _Parameter * 1
    elseif (_Index == 5) then
        self.StartMsg = _Parameter
    elseif (_Index == 6) then
        self.SuccessMsg = _Parameter
    elseif (_Index == 7) then
        self.FailureMsg = _Parameter
    elseif (_Index == 8) then
        self.HowOften = _Parameter * 1
    elseif (_Index == 9) then
        self.OtherOwnerCancels = AcceptAlternativeBoolean(_Parameter)
    elseif (_Index == 10) then
        self.DontPayCancels = AcceptAlternativeBoolean(_Parameter)
    end
end

function b_Goal_TributeClaim:CustomFunction(_Quest)
    local Outpost = Logic.GetTerritoryAcquiringBuildingID(self.TerritoryID)
    if IsExisting(Outpost) and GetHealth(Outpost) < 25 then
        SetHealth(Outpost, 60)
    end

    if Logic.GetTerritoryPlayerID(self.TerritoryID) == _Quest.ReceivingPlayer
    or Logic.GetTerritoryPlayerID(self.TerritoryID) == self.PlayerID then
        if self.OtherOwner then
            self:RestartTributeQuest()
            self.OtherOwner = nil
        end
        if not self.Time and self.PeriodLength -20 < self.TributTime then
                Logic.DEBUG_AddNote("b_Goal_TributeClaim: TributTime too long")
        end
        if not self.Quest then
            local QuestID = QuestTemplate:New(_Quest.Identifier.."TributeClaimQuest" , self.PlayerID, _Quest.ReceivingPlayer,
                                        {{ Objective.Deliver, {Goods.G_Gold, self.Amount}}},
                                        {{ Triggers.Time, 0 }},
                                        self.TributTime,
                                        nil, nil, nil, nil, true, true,
                                        nil,
                                        self.StartMsg,
                                        self.SuccessMsg,
                                        self.FailureMsg
                                        )
            self.Quest = Quests[QuestID]
            self.Time = Logic.GetTime()
        else
            if self.Quest.State == QuestState.Over then
                if self.Quest.Result == QuestResult.Failure then
                    if IsExisting(Outpost) then
                        Logic.ChangeEntityPlayerID(Outpost, self.PlayerID);
                    end
                    Logic.SetTerritoryPlayerID(self.TerritoryID, self.PlayerID)
                    self.Time = Logic.GetTime()
                    self.Quest.State = false

                    if self.DontPayCancels then
                        _Quest:Interrupt();
                    end
                else
                    if self.Quest.Result == QuestResult.Success then
                        if Logic.GetTerritoryPlayerID(self.TerritoryID) == self.PlayerID then
                            if IsExisting(Outpost) then
                                Logic.ChangeEntityPlayerID(Outpost, _Quest.ReceivingPlayer);
                            end
                            Logic.SetTerritoryPlayerID(self.TerritoryID, _Quest.ReceivingPlayer)
                        end
                    end
                    if Logic.GetTime() >= self.Time + self.PeriodLength then
                        if self.HowOften and self.HowOften ~= 0 then
                            self.TributeCounter = self.TributeCounter or 0
                            self.TributeCounter = self.TributeCounter + 1
                            if self.TributeCounter >= self.HowOften then
                                return false
                            end
                        end
                        self:RestartTributeQuest()
                    end
                end

            elseif self.Quest.State == false then
                if Logic.GetTime() >= self.Time + self.PeriodLength then
                    self:RestartTributeQuest()
                end
            end
        end
    elseif Logic.GetTerritoryPlayerID(self.TerritoryID) == 0 and self.Quest then
        if self.Quest.State == QuestState.Active then
            self.Quest:Interrupt()
        end
    elseif Logic.GetTerritoryPlayerID(self.TerritoryID) ~= self.PlayerID then
        if self.Quest.State == QuestState.Active then
            self.Quest:Interrupt()
        end
        if self.OtherOwnerCancels then
            _Quest:Interrupt()
        end
        self.OtherOwner = true
    end
    local storeHouse = Logic.GetStoreHouse(self.PlayerID)
    if (storeHouse == 0 or Logic.IsEntityDestroyed(storeHouse)) then
        if self.Quest and self.Quest.State == QuestState.Active then
            self.Quest:Interrupt()
        end
        return true
    end
end

function b_Goal_TributeClaim:DEBUG(_Quest)

    if self.TerritoryID == 0 then
        dbg(_Quest.Identifier .. ": " .. self.Name .. ": Unknown Territory")
        return true
    elseif not self.Quest and Logic.GetStoreHouse(self.PlayerID) == 0 then
        dbg(_Quest.Identifier .. ": " .. self.Name .. ": Player " .. self.PlayerID .. " is dead. :-(")
        return true
    elseif self.Amount < 0 then
        dbg(_Quest.Identifier .. ": " .. self.Name .. ": Amount is negative")
        return true
    elseif self.PeriodLength < 1 or self.PeriodLength > 600 then
        dbg(_Quest.Identifier .. ": " .. self.Name .. ": Period Length is wrong")
        return true
    elseif self.HowOften < 0 then
        dbg(_Quest.Identifier .. ": " .. self.Name .. ": HowOften is negative")
        return true
    end

end

function b_Goal_TributeClaim:Reset()
    self.Quest = nil
    self.Time = nil
    self.OtherOwner = nil
end

function b_Goal_TributeClaim:Interrupt(_Quest)
    if type(self.Quest) == "table" then
        if self.Quest.State == QuestState.Active then
            self.Quest:Interrupt()
        end
    end
end

function b_Goal_TributeClaim:RestartTributeQuest()

    self.Time = Logic.GetTime()
    self.Quest.Objectives[1].Completed = nil
    self.Quest.Objectives[1].Data[3] = nil
    self.Quest.Objectives[1].Data[4] = nil
    self.Quest.Objectives[1].Data[5] = nil
    self.Quest.Result = nil
    self.Quest.State = QuestState.NotTriggered
    Logic.ExecuteInLuaLocalState("LocalScriptCallback_OnQuestStatusChanged("..self.Quest.Index..")")
    Trigger.RequestTrigger(Events.LOGIC_EVENT_EVERY_SECOND, "", QuestTemplate.Loop, 1, 0, { self.Quest.QueueID })

end

function b_Goal_TributeClaim:GetCustomData(_index)

    if (_index == 3) then
        return { "1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "11", "12"}
    elseif (_index == 9) or (_index == 10) then
        return { "false", "true" }
    end

end

Core:RegisterBehavior(b_Goal_TributeClaim)

-- -------------------------------------------------------------------------- --
-- Reprisal                                                                   --
-- -------------------------------------------------------------------------- --

---
-- Deaktiviert ein interaktives Objekt
--
-- @param _ScriptName Skriptname des interaktiven Objektes
-- @return Table mit Behavior
-- @within Reprisal
--
function Reprisal_ObjectDeactivate(...)
    return b_Reprisal_ObjectDeactivate:new(...);
end

b_Reprisal_ObjectDeactivate = {
    Name = "Reprisal_ObjectDeactivate",
    Description = {
        en = "Reprisal: Deactivates an interactive object",
        de = "Vergeltung: Deaktiviert ein interaktives Objekt",
    },
    Parameter = {
        { ParameterType.ScriptName, en = "Interactive object", de = "Interaktives Objekt" },
    },
}

function b_Reprisal_ObjectDeactivate:GetReprisalTable()
    return { Reprisal.Custom,{self, self.CustomFunction} }
end

function b_Reprisal_ObjectDeactivate:AddParameter(_Index, _Parameter)

    if (_Index == 0) then
        self.ScriptName = _Parameter
    end

end

function b_Reprisal_ObjectDeactivate:CustomFunction(_Quest)
    InteractiveObjectDeactivate(self.ScriptName);
end

function b_Reprisal_ObjectDeactivate:DEBUG(_Quest)
    if not Logic.IsInteractiveObject(GetID(self.ScriptName)) then
        warn("".._Quest.Identifier.." "..self.Name..": '" ..self.ScriptName.. "' is not a interactive object!");
        self.WarningPrinted = true;
    end
    local eID = GetID(self.ScriptName);
    if QSB.InitalizedObjekts[eID] and QSB.InitalizedObjekts[eID] == _Quest.Identifier then
        dbg("".._Quest.Identifier.." "..self.Name..": you can not deactivate in the same quest the object is initalized!");
        return true;
    end
    return false;
end

Core:RegisterBehavior(b_Reprisal_ObjectDeactivate);

-- -------------------------------------------------------------------------- --

---
-- Aktiviert ein interaktives Objekt.
--
-- Der Status bestimmt, wie das objekt aktiviert wird.
-- <ul>
-- <li>0: Kann nur mit Helden aktiviert werden</li>
-- <li>1: Kann immer aktiviert werden</li>
-- </ul>
--
-- @param _ScriptName Skriptname des interaktiven Objektes
-- @param _State Status des Objektes
-- @return Table mit Behavior
-- @within Reprisal
--
function Reprisal_ObjectActivate(...)
    return b_Reprisal_ObjectActivate:new(...);
end

b_Reprisal_ObjectActivate = {
    Name = "Reprisal_ObjectActivate",
    Description = {
        en = "Reprisal: Activates an interactive object",
        de = "Vergeltung: Aktiviert ein interaktives Objekt",
    },
    Parameter = {
        { ParameterType.ScriptName, en = "Interactive object",  de = "Interaktives Objekt" },
        { ParameterType.Custom,     en = "Availability",         de = "Nutzbarkeit" },
    },
}

function b_Reprisal_ObjectActivate:GetReprisalTable()
    return { Reprisal.Custom,{self, self.CustomFunction} }
end

function b_Reprisal_ObjectActivate:AddParameter(_Index, _Parameter)
    if (_Index == 0) then
        self.ScriptName = _Parameter
    elseif (_Index == 1) then
        local parameter = 0
        if _Parameter == "Always" or 1 then
            parameter = 1
        end
        self.UsingState = parameter
    end
end

function b_Reprisal_ObjectActivate:CustomFunction(_Quest)
    InteractiveObjectActivate(self.ScriptName, self.UsingState);
end

function b_Reprisal_ObjectActivate:GetCustomData( _Index )
    if _Index == 1 then
        return {"Knight only", "Always"}
    end
end

function b_Reprisal_ObjectActivate:DEBUG(_Quest)
    if not Logic.IsInteractiveObject(GetID(self.ScriptName)) then
        warn("".._Quest.Identifier.." "..self.Name..": '" ..self.ScriptName.. "' is not a interactive object!");
        self.WarningPrinted = true;
    end
    local eID = GetID(self.ScriptName);
    if QSB.InitalizedObjekts[eID] and QSB.InitalizedObjekts[eID] == _Quest.Identifier then
        dbg("".._Quest.Identifier.." "..self.Name..": you can not activate in the same quest the object is initalized!");
        return true;
    end
    return false;
end

Core:RegisterBehavior(b_Reprisal_ObjectActivate);

-- -------------------------------------------------------------------------- --

---
-- Der diplomatische Status zwischen Sender und Empfänger verschlechtert sich
-- um eine Stufe.
--
-- @return Table mit Behavior
-- @within Reprisal
--
function Reprisal_DiplomacyDecrease()
    return b_Reprisal_DiplomacyDecrease:new();
end

b_Reprisal_DiplomacyDecrease = {
    Name = "Reprisal_DiplomacyDecrease",
    Description = {
        en = "Reprisal: Diplomacy decreases slightly to another player",
        de = "Vergeltung: Der Diplomatiestatus zum Auftraggeber wird um eine Stufe verringert.",
    },
}

function b_Reprisal_DiplomacyDecrease:GetReprisalTable()
    return { Reprisal.Custom,{self, self.CustomFunction} }
end

function b_Reprisal_DiplomacyDecrease:CustomFunction(_Quest)
    local Sender = _Quest.SendingPlayer;
    local Receiver = _Quest.ReceivingPlayer;
    local State = GetDiplomacyState(Receiver, Sender);
    if State > -2 then
        SetDiplomacyState(Receiver, Sender, State-1);
    end
end

function b_Reprisal_DiplomacyDecrease:AddParameter(_Index, _Parameter)
    if (_Index == 0) then
        self.PlayerID = _Parameter * 1
    end
end

Core:RegisterBehavior(b_Reprisal_DiplomacyDecrease);

-- -------------------------------------------------------------------------- --

---
-- Änder den Diplomatiestatus zwischen zwei Spielern.
--
-- @param _Party1   ID der ersten Partei
-- @param _Party2   ID der zweiten Partei
-- @param _State    Neuer Diplomatiestatus
-- @return Table mit Behavior
-- @within Reprisal
--
function Reprisal_Diplomacy(...)
    return b_Reprisal_Diplomacy:new(...);
end

b_Reprisal_Diplomacy = {
    Name = "Reprisal_Diplomacy",
    Description = {
        en = "Reprisal: Sets Diplomacy state of two Players to a stated value.",
        de = "Vergeltung: Setzt den Diplomatiestatus zweier Spieler auf den angegebenen Wert.",
    },
    Parameter = {
        { ParameterType.PlayerID,         en = "PlayerID 1", de = "Spieler 1" },
        { ParameterType.PlayerID,         en = "PlayerID 2", de = "Spieler 2" },
        { ParameterType.DiplomacyState,   en = "Relation",   de = "Beziehung" },
    },
}

function b_Reprisal_Diplomacy:GetReprisalTable()
    return { Reprisal.Custom,{self, self.CustomFunction} }
end

function b_Reprisal_Diplomacy:AddParameter(_Index, _Parameter)
    if (_Index == 0) then
        self.PlayerID1 = _Parameter * 1
    elseif (_Index == 1) then
        self.PlayerID2 = _Parameter * 1
    elseif (_Index == 2) then
        self.Relation = DiplomacyStates[_Parameter]
    end
end

function b_Reprisal_Diplomacy:CustomFunction(_Quest)
    SetDiplomacyState(self.PlayerID1, self.PlayerID2, self.Relation);
end

function b_Reprisal_Diplomacy:DEBUG(_Quest)
    if not tonumber(self.PlayerID1) or self.PlayerID1 < 1 or self.PlayerID1 > 8 then
        dbg(_Quest.Identifier .. " " .. self.Name .. ": PlayerID 1 is invalid!");
        return true;
    elseif not tonumber(self.PlayerID2) or self.PlayerID2 < 1 or self.PlayerID2 > 8 then
        dbg(_Quest.Identifier .. " " .. self.Name .. ": PlayerID 2 is invalid!");
        return true;
    elseif not tonumber(self.Relation) or self.Relation < -2 or self.Relation > 2 then
        dbg(_Quest.Identifier .. " " .. self.Name .. ": '"..self.Relation.."' is a invalid diplomacy state!");
        return true;
    end
    return false;
end

Core:RegisterBehavior(b_Reprisal_Diplomacy);

-- -------------------------------------------------------------------------- --

---
-- Ein benanntes Entity wird zerstört.
--
-- @param _ScriptName Skriptname des Entity
-- @return Table mit Behavior
-- @within Reprisal
--
function Reprisal_DestroyEntity(...)
    return b_Reprisal_DestroyEntity:new(...);
end

b_Reprisal_DestroyEntity = {
    Name = "Reprisal_DestroyEntity",
    Description = {
        en = "Reprisal: Replaces an entity with an invisible script entity, which retains the entities name.",
        de = "Vergeltung: Ersetzt eine Entity mit einer unsichtbaren Script-Entity, die den Namen übernimmt.",
    },
    Parameter = {
        { ParameterType.ScriptName, en = "Entity", de = "Entity" },
    },
}

function b_Reprisal_DestroyEntity:GetReprisalTable()
    return { Reprisal.Custom,{self, self.CustomFunction} }
end

function b_Reprisal_DestroyEntity:AddParameter(_Index, _Parameter)
    if (_Index == 0) then
        self.ScriptName = _Parameter
    end
end

function b_Reprisal_DestroyEntity:CustomFunction(_Quest)
    ReplaceEntity(self.ScriptName, Entities.XD_ScriptEntity);
end

function b_Reprisal_DestroyEntity:DEBUG(_Quest)
    if not IsExisting(self.ScriptName) then
        warn(_Quest.Identifier.." " ..self.Name..": '" ..self.ScriptName.. "' is already destroyed!");
        self.WarningPrinted = true;
    end
    return false;
end

Core:RegisterBehavior(b_Reprisal_DestroyEntity);

-- -------------------------------------------------------------------------- --

---
-- Zerstört einen über die QSB erzeugten Effekt.
--
-- @param _EffectName Name des Effekts
-- @return Table mit Behavior
-- @within Reprisal
--
function Reprisal_DestroyEffect(...)
    return b_Reprisal_DestroyEffect:new(...);
end

b_Reprisal_DestroyEffect = {
    Name = "Reprisal_DestroyEffect",
    Description = {
        en = "Reprisal: Destroys an effect",
        de = "Vergeltung: Zerstört einen Effekt",
    },
    Parameter = {
        { ParameterType.Default, en = "Effect name", de = "Effektname" },
    }
}

function b_Reprisal_DestroyEffect:AddParameter(_Index, _Parameter)
    if _Index == 0 then
        self.EffectName = _Parameter;
    end
end

function b_Reprisal_DestroyEffect:GetReprisalTable()
    return { Reprisal.Custom, { self, self.CustomFunction } };
end

function b_Reprisal_DestroyEffect:CustomFunction(_Quest)
    if not QSB.EffectNameToID[self.EffectName] or not Logic.IsEffectRegistered(QSB.EffectNameToID[self.EffectName]) then
        return;
    end
    Logic.DestroyEffect(QSB.EffectNameToID[self.EffectName]);
end

function b_Reprisal_DestroyEffect:DEBUG(_Quest)
    if not QSB.EffectNameToID[self.EffectName] then
        dbg(_Quest.Identifier .. " " .. self.Name .. ": Effect " .. self.EffectName .. " never created")
    end
    return false;
end

Core:RegisterBehavior(b_Reprisal_DestroyEffect);

-- -------------------------------------------------------------------------- --

---
-- Der Spieler verliert das Spiel.
--
-- @return Table mit Behavior
-- @within Reprisal
--
function Reprisal_Defeat()
    return b_Reprisal_Defeat:new()
end

b_Reprisal_Defeat = {
    Name = "Reprisal_Defeat",
    Description = {
        en = "Reprisal: The player loses the game.",
        de = "Vergeltung: Der Spieler verliert das Spiel.",
    },
}

function b_Reprisal_Defeat:GetReprisalTable(_Quest)
    return {Reprisal.Defeat};
end

Core:RegisterBehavior(b_Reprisal_Defeat);

-- -------------------------------------------------------------------------- --

---
-- Zeigt die Niederlagedekoration am Quest an.
--
-- Es handelt sich dabei um reine Optik! Der Spieler wird nicht verlieren.
--
-- @return Table mit Behavior
-- @within Reprisal
--
function Reprisal_FakeDefeat()
    return b_Reprisal_FakeDefeat:new();
end

b_Reprisal_FakeDefeat = {
    Name = "Reprisal_FakeDefeat",
    Description = {
        en = "Reprisal: Displays a defeat icon for a quest",
        de = "Vergeltung: Zeigt ein Niederlage Icon fuer eine Quest an",
    },
}

function b_Reprisal_FakeDefeat:GetReprisalTable()
    return { Reprisal.FakeDefeat }
end

-- -------------------------------------------------------------------------- --

---
-- Ein Entity wird durch ein neues anderen Typs ersetzt.
--
-- Das neue Entity übernimmt Skriptname und Ausrichtung des alten Entity.
--
-- @param _Entity Skriptname oder ID des Entity
-- @param _Type   Neuer Typ des Entity
-- @param _Owner  Besitzer des Entity
-- @return Table mit Behavior
-- @within Reprisal
--
function Reprisal_ReplaceEntity(...)
    return b_Reprisal_ReplaceEntity:new(...);
end

b_Reprisal_ReplaceEntity = {
    Name = "Reprisal_ReplaceEntity",
    Description = {
        en = "Reprisal: Replaces an entity with a new one of a different type. The playerID can be changed too.",
        de = "Vergeltung: Ersetzt eine Entity durch eine neue anderen Typs. Es kann auch die Spielerzugehörigkeit geändert werden.",
    },
    Parameter = {
        { ParameterType.ScriptName, en = "Target", de = "Ziel" },
        { ParameterType.Custom, en = "New Type", de = "Neuer Typ" },
        { ParameterType.Custom, en = "New playerID", de = "Neue Spieler ID" },
    },
}

function b_Reprisal_ReplaceEntity:GetReprisalTable()
    return { Reprisal.Custom,{self, self.CustomFunction} }
end

function b_Reprisal_ReplaceEntity:AddParameter(_Index, _Parameter)
   if (_Index == 0) then
        self.ScriptName = _Parameter
    elseif (_Index == 1) then
        self.NewType = _Parameter
    elseif (_Index == 2) then
        self.PlayerID = tonumber(_Parameter);
    end
end

function b_Reprisal_ReplaceEntity:CustomFunction(_Quest)
    local eID = GetID(self.ScriptName);
    local pID = self.PlayerID;
    if pID == Logic.EntityGetPlayer(eID) then
        pID = nil;
    end
    ReplaceEntity(self.ScriptName, Entities[self.NewType], pID);
end

function b_Reprisal_ReplaceEntity:GetCustomData(_Index)
    local Data = {}
    if _Index == 1 then
        for k, v in pairs( Entities ) do
            local name = {"^M_","^XS_","^X_","^XT_","^Z_", "^XB_"}
            local found = false;
            for i=1,#name do
                if k:find(name[i]) then
                    found = true;
                    break;
                end
            end
            if not found then
                table.insert( Data, k );
            end
        end
        table.sort( Data )
    elseif _Index == 2 then
        Data = {"-","0","1","2","3","4","5","6","7","8",}
    end
    return Data
end

function b_Reprisal_ReplaceEntity:DEBUG(_Quest)
    if not Entities[self.NewType] then
        dbg(_Quest.Identifier.." "..self.Name..": got an invalid entity type!");
        return true;
    elseif self.PlayerID ~= nil and (self.PlayerID < 1 or self.PlayerID > 8) then
        dbg(_Quest.Identifier.." "..self.Name..": got an invalid playerID!");
        return true;
    end

    if not IsExisting(self.ScriptName) then
        self.WarningPrinted = true;
        warn(_Quest.Identifier.." "..self.Name..": '" ..self.ScriptName.. "' does not exist!");
    end
    return false;
end

Core:RegisterBehavior(b_Reprisal_ReplaceEntity);

-- -------------------------------------------------------------------------- --

---
-- Startet einen Quest neu.
--
-- @param _QuestName Name des Quest
-- @return Table mit Behavior
-- @within Reprisal
--
function Reprisal_QuestRestart(...)
    return b_Reprisal_QuestRestart(...)
end

b_Reprisal_QuestRestart = {
    Name = "Reprisal_QuestRestart",
    Description = {
        en = "Reprisal: Restarts a (completed) quest so it can be triggered and completed again",
        de = "Vergeltung: Startet eine (beendete) Quest neu, damit diese neu ausgelöst und beendet werden kann",
    },
    Parameter = {
        { ParameterType.QuestName, en = "Quest name", de = "Questname" },
    },
}

function b_Reprisal_QuestRestart:GetReprisalTable(_Quest)
    return { Reprisal.Custom,{self, self.CustomFunction} }
end

function b_Reprisal_QuestRestart:AddParameter(_Index, _Parameter)
    if (_Index == 0) then
        self.QuestName = _Parameter
    end
end

function b_Reprisal_QuestRestart:CustomFunction(_Quest)
    self:ResetQuest();
end

function b_Reprisal_QuestRestart:DEBUG(_Quest)
    if not Quests[GetQuestID(self.QuestName)] then
        dbg(_Quest.Identifier .. " " .. self.Name .. ": quest "..  self.QuestName .. " does not exist!")
        return true
    end
end

function b_Reprisal_QuestRestart:ResetQuest()
    RestartQuestByName(self.QuestName);
end

Core:RegisterBehavior(b_Reprisal_QuestRestart);

-- -------------------------------------------------------------------------- --

---
-- Lässt einen Quest fehlschlagen.
--
-- @param _QuestName Name des Quest
-- @return Table mit Behavior
-- @within Reprisal
--
function Reprisal_QuestFailure(...)
    return b_Reprisal_QuestFailure(...)
end

b_Reprisal_QuestFailure = {
    Name = "Reprisal_QuestFailure",
    Description = {
        en = "Reprisal: Lets another active quest fail",
        de = "Vergeltung: Lässt eine andere aktive Quest fehlschlagen",
    },
    Parameter = {
        { ParameterType.QuestName, en = "Quest name", de = "Questname" },
    },
}

function b_Reprisal_QuestFailure:GetReprisalTable()
    return { Reprisal.Custom,{self, self.CustomFunction} }
end

function b_Reprisal_QuestFailure:AddParameter(_Index, _Parameter)
    if (_Index == 0) then
        self.QuestName = _Parameter
    end
end

function b_Reprisal_QuestFailure:CustomFunction(_Quest)
    FailQuestByName(self.QuestName);
end

function b_Reprisal_QuestFailure:DEBUG(_Quest)
    if not Quests[GetQuestID(self.QuestName)] then
        dbg("".._Quest.Identifier.." "..self.Name..": got an invalid quest!");
        return true;
    end
    return false;
end

Core:RegisterBehavior(b_Reprisal_QuestFailure);

-- -------------------------------------------------------------------------- --

---
-- Wertet einen Quest als erfolgreich.
--
-- @param _QuestName Name des Quest
-- @return Table mit Behavior
-- @within Reprisal
--
function Reprisal_QuestSuccess(...)
    return b_Reprisal_QuestSuccess(...)
end

b_Reprisal_QuestSuccess = {
    Name = "Reprisal_QuestSuccess",
    Description = {
        en = "Reprisal: Completes another active quest successfully",
        de = "Vergeltung: Beendet eine andere aktive Quest erfolgreich",
    },
    Parameter = {
        { ParameterType.QuestName, en = "Quest name", de = "Questname" },
    },
}

function b_Reprisal_QuestSuccess:GetReprisalTable()
    return { Reprisal.Custom,{self, self.CustomFunction} }
end

function b_Reprisal_QuestSuccess:AddParameter(_Index, _Parameter)
    if (_Index == 0) then
        self.QuestName = _Parameter
    end
end

function b_Reprisal_QuestSuccess:CustomFunction(_Quest)
    WinQuestByName(self.QuestName);
end

function b_Reprisal_QuestSuccess:DEBUG(_Quest)
    if not Quests[GetQuestID(self.QuestName)] then
        dbg(_Quest.Identifier .. " " .. self.Name .. ": quest "..  self.QuestName .. " does not exist!")
        return true
    end
    return false;
end

Core:RegisterBehavior(b_Reprisal_QuestSuccess);

-- -------------------------------------------------------------------------- --

---
-- Triggert einen Quest.
--
-- @param _QuestName Name des Quest
-- @return Table mit Behavior
-- @within Reprisal
--
function Reprisal_QuestActivate(...)
    return b_Reprisal_QuestActivate(...)
end

b_Reprisal_QuestActivate = {
    Name = "Reprisal_QuestActivate",
    Description = {
        en = "Reprisal: Activates another quest that is not triggered yet.",
        de = "Vergeltung: Aktiviert eine andere Quest die noch nicht ausgelöst wurde.",
                },
    Parameter = {
        {ParameterType.QuestName, en = "Quest name", de = "Questname", },
    },
}

function b_Reprisal_QuestActivate:GetReprisalTable()
    return {Reprisal.Custom, {self, self.CustomFunction} }
end

function b_Reprisal_QuestActivate:AddParameter(_Index, _Parameter)
    if (_Index==0) then
        self.QuestName = _Parameter
    else
        assert(false, "Error in " .. self.Name .. ": AddParameter: Index is invalid")
    end
end

function b_Reprisal_QuestActivate:CustomFunction(_Quest)
    StartQuestByName(self.QuestName);
end

function b_Reprisal_QuestActivate:DEBUG(_Quest)
    if not IsValidQuest(self.QuestName) then
        dbg(_Quest.Identifier .. " " .. self.Name .. ": Quest: "..  self.QuestName .. " does not exist")
        return true
    end
end

Core:RegisterBehavior(b_Reprisal_QuestActivate)

-- -------------------------------------------------------------------------- --

---
-- Unterbricht einen Quest.
--
-- @param _QuestName Name des Quest
-- @return Table mit Behavior
-- @within Reprisal
--
function Reprisal_QuestInterrupt(...)
    return b_Reprisal_QuestInterrupt(...)
end

b_Reprisal_QuestInterrupt = {
    Name = "Reprisal_QuestInterrupt",
    Description = {
        en = "Reprisal: Interrupts another active quest without success or failure",
        de = "Vergeltung: Beendet eine andere aktive Quest ohne Erfolg oder Misserfolg",
    },
    Parameter = {
        { ParameterType.QuestName, en = "Quest name", de = "Questname" },
    },
}

function b_Reprisal_QuestInterrupt:GetReprisalTable()
    return { Reprisal.Custom,{self, self.CustomFunction} }
end

function b_Reprisal_QuestInterrupt:AddParameter(_Index, _Parameter)
    if (_Index == 0) then
        self.QuestName = _Parameter
    end
end

function b_Reprisal_QuestInterrupt:CustomFunction(_Quest)
    if (GetQuestID(self.QuestName) ~= nil) then

        local QuestID = GetQuestID(self.QuestName)
        local Quest = Quests[QuestID]
        if Quest.State == QuestState.Active then
            StopQuestByName(self.QuestName);
        end
    end
end

function b_Reprisal_QuestInterrupt:DEBUG(_Quest)
    if not Quests[GetQuestID(self.QuestName)] then
        dbg(_Quest.Identifier .. " " .. self.Name .. ": quest "..  self.QuestName .. " does not exist!")
        return true
    end
    return false;
end

Core:RegisterBehavior(b_Reprisal_QuestInterrupt);

-- -------------------------------------------------------------------------- --

---
-- Unterbricht einen Quest, selbst wenn dieser noch nicht ausgelöst wurde.
--
-- @param _QuestName   Name des Quest
-- @param _EndetQuests Bereits beendete unterbrechen
-- @return Table mit Behavior
-- @within Reprisal
--
function Reprisal_QuestForceInterrupt(...)
    return b_Reprisal_QuestForceInterrupt(...)
end

b_Reprisal_QuestForceInterrupt = {
    Name = "Reprisal_QuestForceInterrupt",
    Description = {
        en = "Reprisal: Interrupts another quest (even when it isn't active yet) without success or failure",
        de = "Vergeltung: Beendet eine andere Quest, auch wenn diese noch nicht aktiv ist ohne Erfolg oder Misserfolg",
    },
    Parameter = {
        { ParameterType.QuestName, en = "Quest name", de = "Questname" },
        { ParameterType.Custom, en = "Ended quests", de = "Beendete Quests" },
    },
}

function b_Reprisal_QuestForceInterrupt:GetReprisalTable()

    return { Reprisal.Custom,{self, self.CustomFunction} }

end

function b_Reprisal_QuestForceInterrupt:AddParameter(_Index, _Parameter)

    if (_Index == 0) then
        self.QuestName = _Parameter
    elseif (_Index == 1) then
        self.InterruptEnded = AcceptAlternativeBoolean(_Parameter)
    end

end

function b_Reprisal_QuestForceInterrupt:GetCustomData( _Index )
    local Data = {}
    if _Index == 1 then
        table.insert( Data, "false" )
        table.insert( Data, "true" )
    else
        assert( false )
    end
    return Data
end
function b_Reprisal_QuestForceInterrupt:CustomFunction(_Quest)
    if (GetQuestID(self.QuestName) ~= nil) then

        local QuestID = GetQuestID(self.QuestName)
        local Quest = Quests[QuestID]
        if self.InterruptEnded or Quest.State ~= QuestState.Over then
            Quest:Interrupt()
        end
    end
end

function b_Reprisal_QuestForceInterrupt:DEBUG(_Quest)
    if not Quests[GetQuestID(self.QuestName)] then
        dbg(_Quest.Identifier .. " " .. self.Name .. ": quest "..  self.QuestName .. " does not exist!")
        return true;
    end
    return false;
end

Core:RegisterBehavior(b_Reprisal_QuestForceInterrupt);

-- -------------------------------------------------------------------------- --

---
-- Führt eine Funktion im Skript als Reprisal aus.
--
-- @param _FunctionName Name der Funktion
-- @return Table mit Behavior
-- @within Reprisal
--
function Reprisal_MapScriptFunction(...)
    return b_Reprisal_MapScriptFunction:new(...);
end

b_Reprisal_MapScriptFunction = {
    Name = "Reprisal_MapScriptFunction",
    Description = {
        en = "Reprisal: Calls a function within the global map script if the quest has failed.",
        de = "Vergeltung: Ruft eine Funktion im globalen Kartenskript auf, wenn die Quest fehlschlägt.",
    },
    Parameter = {
        { ParameterType.Default, en = "Function name", de = "Funktionsname" },
    },
}

function b_Reprisal_MapScriptFunction:GetReprisalTable(_Quest)
    return {Reprisal.Custom, {self, self.CustomFunction}};
end

function b_Reprisal_MapScriptFunction:AddParameter(_Index, _Parameter)
    if (_Index == 0) then
        self.FuncName = _Parameter
    end
end

function b_Reprisal_MapScriptFunction:CustomFunction(_Quest)
    return _G[self.FuncName](self, _Quest);
end

function b_Reprisal_MapScriptFunction:DEBUG(_Quest)
    if not self.FuncName or not _G[self.FuncName] then
        dbg("".._Quest.Identifier.." "..self.Name..": function '" ..self.FuncName.. "' does not exist!");
        return true;
    end
    return false;
end

Core:RegisterBehavior(b_Reprisal_MapScriptFunction);

-- -------------------------------------------------------------------------- --

---
-- Ändert den Wert einer benutzerdefinierten Variable.
--
-- Benutzerdefinierte Variablen können ausschließlich Zahlen sein.
--
---- <p>Operatoren</p>
-- <ul>
-- <li>= - Variablenwert wird auf den Wert gesetzt</li>
-- <li>- - Variablenwert mit Wert Subtrahieren</li>
-- <li>+ - Variablenwert mit Wert addieren</li>
-- <li>* - Variablenwert mit Wert multiplizieren</li>
-- <li>/ - Variablenwert mit Wert dividieren</li>
-- <li>^ - Variablenwert mit Wert potenzieren</li>
-- </ul>
--
-- @param _Name     Name der Variable
-- @param _Operator Rechen- oder Zuweisungsoperator
-- @param _Value    Wert oder andere Custom Variable
-- @return Table mit Behavior
-- @within Reprisal
--
function Reprisal_CustomVariables(...)
    return b_Reprisal_CustomVariables:new(...);
end

b_Reprisal_CustomVariables = {
    Name = "Reprisal_CustomVariables",
    Description = {
        en = "Reprisal: Executes a mathematical operation with this variable. The other operand can be a number or another custom variable.",
        de = "Vergeltung: Fuehrt eine mathematische Operation mit der Variable aus. Der andere Operand kann eine Zahl oder eine Custom-Varible sein.",
    },
    Parameter = {
        { ParameterType.Default, en = "Name of variable", de = "Variablenname" },
        { ParameterType.Custom,  en = "Operator", de = "Operator" },
        { ParameterType.Default,  en = "Value or variable", de = "Wert oder Variable" }
    }
};

function b_Reprisal_CustomVariables:GetReprisalTable()
    return { Reprisal.Custom, {self, self.CustomFunction} };
end

function b_Reprisal_CustomVariables:AddParameter(_Index, _Parameter)
    if _Index == 0 then
        self.VariableName = _Parameter
    elseif _Index == 1 then
        self.Operator = _Parameter
    elseif _Index == 2 then
        local value = tonumber(_Parameter);
        value = (value ~= nil and value) or tostring(_Parameter);
        self.Value = value
    end
end

function b_Reprisal_CustomVariables:CustomFunction()
    _G["QSB_CustomVariables_"..self.VariableName] = _G["QSB_CustomVariables_"..self.VariableName] or 0;
    local oldValue = _G["QSB_CustomVariables_"..self.VariableName];

    if self.Operator == "=" then
        _G["QSB_CustomVariables_"..self.VariableName] = (type(self.Value) ~= "string" and self.Value) or _G["QSB_CustomVariables_"..self.Value];
    elseif self.Operator == "+" then
        _G["QSB_CustomVariables_"..self.VariableName] = oldValue + (type(self.Value) ~= "string" and self.Value) or _G["QSB_CustomVariables_"..self.Value];
    elseif self.Operator == "-" then
        _G["QSB_CustomVariables_"..self.VariableName] = oldValue - (type(self.Value) ~= "string" and self.Value) or _G["QSB_CustomVariables_"..self.Value];
    elseif self.Operator == "*" then
        _G["QSB_CustomVariables_"..self.VariableName] = oldValue * (type(self.Value) ~= "string" and self.Value) or _G["QSB_CustomVariables_"..self.Value];
    elseif self.Operator == "/" then
        _G["QSB_CustomVariables_"..self.VariableName] = oldValue / (type(self.Value) ~= "string" and self.Value) or _G["QSB_CustomVariables_"..self.Value];
    elseif self.Operator == "^" then
        _G["QSB_CustomVariables_"..self.VariableName] = oldValue ^ (type(self.Value) ~= "string" and self.Value) or _G["QSB_CustomVariables_"..self.Value];

    end
end

function b_Reprisal_CustomVariables:GetCustomData( _Index )
    return {"=", "+", "-", "*", "/", "^"};
end

function b_Reprisal_CustomVariables:DEBUG(_Quest)
    local operators = {"=", "+", "-", "*", "/", "^"};
    if not Inside(self.Operator,operators) then
        dbg(_Quest.Identifier.." "..self.Name..": got an invalid operator!");
        return true;
    elseif self.VariableName == "" then
        dbg(_Quest.Identifier.." "..self.Name..": missing name for variable!");
        return true;
    end
    return false;
end

Core:RegisterBehavior(b_Reprisal_CustomVariables)

-- -------------------------------------------------------------------------- --

---
-- Erlaubt oder verbietet einem Spieler eine Technologie.
--
-- @param _PlayerID   ID des Spielers
-- @param _Lock       Sperren/Entsperren
-- @param _Technology Name der Technologie
-- @return Table mit Behavior
-- @within Reprisal
--
function Reprisal_Technology(...)
    return b_Reprisal_Technology:new(...);
end

b_Reprisal_Technology = {
    Name = "Reprisal_Technology",
    Description = {
        en = "Reprisal: Locks or unlocks a technology for the given player",
        de = "Vergeltung: Sperrt oder erlaubt eine Technolgie fuer den angegebenen Player",
    },
    Parameter = {
        { ParameterType.PlayerID, en = "PlayerID", de = "SpielerID" },
        { ParameterType.Custom,   en = "Un / Lock", de = "Sperren/Erlauben" },
        { ParameterType.Custom,   en = "Technology", de = "Technologie" },
    },
}

function b_Reprisal_Technology:GetReprisalTable(_Quest)
    return { Reprisal.Custom, {self, self.CustomFunction} }
end

function b_Reprisal_Technology:AddParameter(_Index, _Parameter)
    if (_Index ==0) then
        self.PlayerID = _Parameter*1
    elseif (_Index == 1) then
        self.LockType = _Parameter == "Lock"
    elseif (_Index == 2) then
        self.Technology = _Parameter
    end
end

function b_Reprisal_Technology:CustomFunction(_Quest)
    if self.PlayerID
    and Logic.GetStoreHouse(self.PlayerID) ~= 0
    and Technologies[self.Technology]
    then
        if self.LockType  then
            LockFeaturesForPlayer(self.PlayerID, Technologies[self.Technology])
        else
            UnLockFeaturesForPlayer(self.PlayerID, Technologies[self.Technology])
        end
    else
        return false
    end
end

function b_Reprisal_Technology:GetCustomData(_Index)
    local Data = {}
    if (_Index == 1) then
        Data[1] = "Lock"
        Data[2] = "UnLock"
    elseif (_Index == 2) then
        for k, v in pairs( Technologies ) do
            table.insert( Data, k )
        end
    end
    return Data
end

function b_Reprisal_Technology:DEBUG(_Quest)
    if not Technologies[self.Technology] then
        dbg("".._Quest.Identifier.." "..self.Name..": got an invalid technology type!");
        return true;
    elseif tonumber(self.PlayerID) == nil or self.PlayerID < 1 or self.PlayerID > 8 then
        dbg("".._Quest.Identifier.." "..self.Name..": got an invalid playerID!");
        return true;
    end
    return false;
end

Core:RegisterBehavior(b_Reprisal_Technology);

-- -------------------------------------------------------------------------- --
-- Rewards                                                                    --
-- -------------------------------------------------------------------------- --

---
-- Deaktiviert ein interaktives Objekt
--
-- @param _ScriptName Skriptname des interaktiven Objektes
-- @return Table mit Behavior
-- @within Reward
--
function Reward_ObjectDeactivate(...)
    return b_Reward_ObjectDeactivate:new(...);
end

b_Reward_ObjectDeactivate = API.InstanceTable(b_Reprisal_ObjectDeactivate);
b_Reward_ObjectDeactivate.Name             = "Reward_ObjectDeactivate";
b_Reward_ObjectDeactivate.Description.de   = "Reward: Deactivates an interactive object";
b_Reward_ObjectDeactivate.Description.en   = "Lohn: Deaktiviert ein interaktives Objekt";
b_Reward_ObjectDeactivate.GetReprisalTable = nil;

b_Reward_ObjectDeactivate.GetRewardTable = function(self, _Quest)
    return { Reward.Custom,{self, self.CustomFunction} }
end

Core:RegisterBehavior(b_Reward_ObjectDeactivate);

-- -------------------------------------------------------------------------- --

---
-- Aktiviert ein interaktives Objekt.
--
-- Der Status bestimmt, wie das objekt aktiviert wird.
-- <ul>
-- <li>0: Kann nur mit Helden aktiviert werden</li>
-- <li>1: Kann immer aktiviert werden</li>
-- </ul>
--
-- @param _ScriptName Skriptname des interaktiven Objektes
-- @param _State Status des Objektes
-- @return Table mit Behavior
-- @within Reward
--
function Reward_ObjectActivate(...)
    return Reward_ObjectActivate:new(...);
end

b_Reward_ObjectActivate = API.InstanceTable(b_Reprisal_ObjectActivate);
b_Reward_ObjectActivate.Name             = "Reward_ObjectActivate";
b_Reward_ObjectActivate.Description.de   = "Reward: Activates an interactive object";
b_Reward_ObjectActivate.Description.en   = "Lohn: Aktiviert ein interaktives Objekt";
b_Reward_ObjectActivate.GetReprisalTable = nil;

b_Reward_ObjectActivate.GetRewardTable = function(self, _Quest)
    return { Reward.Custom,{self, self.CustomFunction} };
end

Core:RegisterBehavior(b_Reward_ObjectActivate);

-- -------------------------------------------------------------------------- --

---
-- Initialisiert ein interaktives Objekt.
--
-- Interaktive Objekte können Kosten und Belohnungen enthalten, müssen sie
-- jedoch nicht. Ist eine Wartezeit angegeben, kann das Objekt erst nach
-- Ablauf eines Cooldowns benutzt werden.
--
-- @param _ScriptName Skriptname des interaktiven Objektes
-- @param _Distance   Entfernung zur Aktivierung
-- @param _Time       Wartezeit bis zur Aktivierung
-- @param _RType1     Warentyp der Belohnung
-- @param _RAmount    Menge der Belohnung
-- @param _CType1     Typ der 1. Ware
-- @param _CAmount1   Menge der 1. Ware
-- @param _CType2     Typ der 2. Ware
-- @param _CAmount2   Menge der 2. Ware
-- @param _Status     Aktivierung (0: Held, 1: immer, 2: niemals)
-- @return Table mit Behavior
-- @within Reward
--
function Reward_ObjectInit(...)
    return Reward_ObjectInit:new(...);
end

b_Reward_ObjectInit = {
    Name = "Reward_ObjectInit",
    Description = {
        en = "Reward: Setup an interactive object with costs and rewards.",
        de = "Lohn: Initialisiert ein interaktives Objekt mit seinen Kosten und Schätzen.",
    },
    Parameter = {
        { ParameterType.ScriptName, en = "Interactive object",     de = "Interaktives Objekt" },
        { ParameterType.Number,     en = "Distance to use",     de = "Nutzungsentfernung" },
        { ParameterType.Number,     en = "Waittime",             de = "Wartezeit" },
        { ParameterType.Custom,     en = "Reward good",         de = "Belohnungsware" },
        { ParameterType.Number,     en = "Reward amount",         de = "Anzahl" },
        { ParameterType.Custom,     en = "Cost good 1",         de = "Kostenware 1" },
        { ParameterType.Number,     en = "Cost amount 1",         de = "Anzahl 1" },
        { ParameterType.Custom,     en = "Cost good 2",         de = "Kostenware 2" },
        { ParameterType.Number,     en = "Cost amount 2",         de = "Anzahl 2" },
        { ParameterType.Custom,     en = "Availability",         de = "Verfï¿½gbarkeit" },
    },
}

function b_Reward_ObjectInit:GetRewardTable()
    return { Reward.Custom,{self, self.CustomFunction} }
end

function b_Reward_ObjectInit:AddParameter(_Index, _Parameter)
    if (_Index == 0) then
        self.ScriptName = _Parameter
    elseif (_Index == 1) then
        self.Distance = _Parameter * 1
    elseif (_Index == 2) then
        self.Waittime = _Parameter * 1
    elseif (_Index == 3) then
        self.RewardType = _Parameter
    elseif (_Index == 4) then
        self.RewardAmount = tonumber(_Parameter)
    elseif (_Index == 5) then
        self.FirstCostType = _Parameter
    elseif (_Index == 6) then
        self.FirstCostAmount = tonumber(_Parameter)
    elseif (_Index == 7) then
        self.SecondCostType = _Parameter
    elseif (_Index == 8) then
        self.SecondCostAmount = tonumber(_Parameter)
    elseif (_Index == 9) then
        local parameter = nil
        if _Parameter == "Always" or 1 then
            parameter = 1
        elseif _Parameter == "Never" or 2 then
            parameter = 2
        elseif _Parameter == "Knight only" or 0 then
            parameter = 0
        end
        self.UsingState = parameter
    end
end

function b_Reward_ObjectInit:CustomFunction(_Quest)
    local eID = GetID(self.ScriptName);
    if eID == 0 then
        return;
    end
    QSB.InitalizedObjekts[eID] = _Quest.Identifier;

    Logic.InteractiveObjectClearCosts(eID);
    Logic.InteractiveObjectClearRewards(eID);

    Logic.InteractiveObjectSetInteractionDistance(eID, self.Distance);
    Logic.InteractiveObjectSetTimeToOpen(eID, self.Waittime);

    if self.RewardType and self.RewardType ~= "disabled" then
        Logic.InteractiveObjectAddRewards(eID, Goods[self.RewardType], self.RewardAmount);
    end
    if self.FirstCostType and self.FirstCostType ~= "disabled" then
        Logic.InteractiveObjectAddCosts(eID, Goods[self.FirstCostType], self.FirstCostAmount);
    end
    if self.SecondCostType and self.SecondCostType ~= "disabled" then
        Logic.InteractiveObjectAddCosts(eID, Goods[self.SecondCostType], self.SecondCostAmount);
    end

    Logic.InteractiveObjectSetAvailability(eID,true);
    if self.UsingState then
        for i=1, 8 do
            Logic.InteractiveObjectSetPlayerState(eID,i, self.UsingState);
        end
    end

    Logic.InteractiveObjectSetRewardResourceCartType(eID,Entities.U_ResourceMerchant);
    Logic.InteractiveObjectSetRewardGoldCartType(eID,Entities.U_GoldCart);
    Logic.InteractiveObjectSetCostResourceCartType(eID,Entities.U_ResourceMerchant);
    Logic.InteractiveObjectSetCostGoldCartType(eID, Entities.U_GoldCart);
    RemoveInteractiveObjectFromOpenedList(eID);
    table.insert(HiddenTreasures,eID);
end

function b_Reward_ObjectInit:GetCustomData( _Index )
    if _Index == 3 or _Index == 5 or _Index == 7 then
        local Data = {
            "-",
            "G_Beer",
            "G_Bread",
            "G_Broom",
            "G_Carcass",
            "G_Cheese",
            "G_Clothes",
            "G_Dye",
            "G_Gold",
            "G_Grain",
            "G_Herb",
            "G_Honeycomb",
            "G_Iron",
            "G_Leather",
            "G_Medicine",
            "G_Milk",
            "G_RawFish",
            "G_Salt",
            "G_Sausage",
            "G_SmokedFish",
            "G_Soap",
            "G_Stone",
            "G_Water",
            "G_Wood",
            "G_Wool",
        }

        if g_GameExtraNo >= 1 then
            Data[#Data+1] = "G_Gems"
            Data[#Data+1] = "G_MusicalInstrument"
            Data[#Data+1] = "G_Olibanum"
        end
        return Data
    elseif _Index == 9 then
        return {"-", "Knight only", "Always", "Never",}
    end
end

function b_Reward_ObjectInit:DEBUG(_Quest)
    if Logic.IsInteractiveObject(GetID(self.ScriptName)) == false then
        dbg("".._Quest.Identifier.." "..self.Name..": '"..self.ScriptName.."' is not a interactive object!");
        return true;
    end
    if self.UsingState ~= 1 and self.Distance < 50 then
        warn("".._Quest.Identifier.." "..self.Name..": distance is maybe too short!");
    end
    if self.Waittime < 0 then
        dbg("".._Quest.Identifier.." "..self.Name..": waittime must be equal or greater than 0!");
        return true;
    end
    if self.RewardType and self.RewardType ~= "-" then
        if not Goods[self.RewardType] then
            dbg("".._Quest.Identifier.." "..self.Name..": '"..self.RewardType.."' is invalid good type!");
            return true;
        elseif self.RewardAmount < 1 then
            dbg("".._Quest.Identifier.." "..self.Name..": amount can not be 0 or negative!");
            return true;
        end
    end
    if self.FirstCostType and self.FirstCostType ~= "-" then
        if not Goods[self.FirstCostType] then
            dbg("".._Quest.Identifier.." "..self.Name..": '"..self.FirstCostType.."' is invalid good type!");
            return true;
        elseif self.FirstCostAmount < 1 then
            dbg("".._Quest.Identifier.." "..self.Name..": amount can not be 0 or negative!");
            return true;
        end
    end
    if self.SecondCostType and self.SecondCostType ~= "-" then
        if not Goods[self.SecondCostType] then
            dbg("".._Quest.Identifier.." "..self.Name..": '"..self.SecondCostType.."' is invalid good type!");
            return true;
        elseif self.SecondCostAmount < 1 then
            dbg("".._Quest.Identifier.." "..self.Name..": amount can not be 0 or negative!");
            return true;
        end
    end
    return false;
end

Core:RegisterBehavior(b_Reward_ObjectInit);

-- -------------------------------------------------------------------------- --

---
-- Setzt die benutzten Wagen eines interaktiven Objektes.
--
-- In der Regel ist das Setzen der Wagen unnötig, da die voreingestellten
-- Wagen ausreichen. Will man aber z.B. eine Kutsche fahren lassen, dann
-- muss der Wagentyp geändert werden.
--
-- @param _ScriptName           Skriptname des Objektes
-- @param _CostResourceType     Wagen für Rohstoffkosten
-- @param _CostGoldType         Wagen für Goldkosten
-- @param _RewResourceType      Wagen für Rohstofflieferung
-- @param _RewGoldType          Wagen für Goldlieferung
-- @return Table mit Behavior
-- @within Reward
--
function Reward_ObjectSetCarts(...)
    return b_Reward_ObjectSetCarts:new(...);
end

b_Reward_ObjectSetCarts = {
    Name = "Reward_ObjectSetCarts",
    Description = {
        en = "Reward: Set the cart types of an interactive object.",
        de = "Lohn: Setzt die Wagentypen eines interaktiven Objektes.",
    },
    Parameter = {
        { ParameterType.ScriptName, en = "Interactive object",         de = "Interaktives Objekt" },
        { ParameterType.Default,     en = "Cost resource type",         de = "Rohstoffwagen Kosten" },
        { ParameterType.Default,     en = "Cost gold type",             de = "Goldwagen Kosten" },
        { ParameterType.Default,     en = "Reward resource type",     de = "Rohstoffwagen Schatz" },
        { ParameterType.Default,     en = "Reward gold type",         de = "Goldwagen Schatz" },
    },
}

function b_Reward_ObjectSetCarts:GetRewardTable()
    return { Reward.Custom,{self, self.CustomFunction} }
end

function b_Reward_ObjectSetCarts:AddParameter(_Index, _Parameter)
    if _Index == 0 then
        self.ScriptName = _Parameter
    elseif _Index == 1 then
        if not _Parameter or _Parameter == "default" then
            _Parameter = "U_ResourceMerchant";
        end
        self.CostResourceCart = _Parameter
    elseif _Index == 2 then
        if not _Parameter or _Parameter == "default" then
            _Parameter = "U_GoldCart";
        end
        self.CostGoldCart = _Parameter
    elseif _Index == 3 then
        if not _Parameter or _Parameter == "default" then
            _Parameter = "U_ResourceMerchant";
        end
        self.RewardResourceCart = _Parameter
    elseif _Index == 4 then
        if not _Parameter or _Parameter == "default" then
            _Parameter = "U_GoldCart";
        end
        self.RewardGoldCart = _Parameter
    end
end

function b_Reward_ObjectSetCarts:CustomFunction(_Quest)
    local eID = GetID(self.ScriptName);
    Logic.InteractiveObjectSetRewardResourceCartType(eID, Entities[self.RewardResourceCart]);
    Logic.InteractiveObjectSetRewardGoldCartType(eID, Entities[self.RewardGoldCart]);
    Logic.InteractiveObjectSetCostGoldCartType(eID, Entities[self.CostResourceCart]);
    Logic.InteractiveObjectSetCostResourceCartType(eID, Entities[self.CostGoldCart]);
end

function b_Reward_ObjectSetCarts:GetCustomData( _Index )
    if _Index == 2 or _Index == 4 then
        return {"U_GoldCart", "U_GoldCart_Mission", "U_Noblemen_Cart", "U_RegaliaCart"}
    elseif _Index == 1 or _Index == 3 then
        local Data = {"U_ResourceMerchant", "U_Medicus", "U_Marketer"}
        if g_GameExtraNo > 0 then
            table.insert(Data, "U_NPC_Resource_Monk_AS");
        end
        return Data;
    end
end

function b_Reward_ObjectSetCarts:DEBUG(_Quest)
    if (not Entities[self.CostResourceCart]) or (not Entities[self.CostGoldCart])
    or (not Entities[self.RewardResourceCart]) or (not Entities[self.RewardGoldCart]) then
        dbg("".._Quest.Identifier.." "..self.Name..": invalid cart type!");
        return true;
    end

    local eID = GetID(self.ScriptName);
    if QSB.InitalizedObjekts[eID] and QSB.InitalizedObjekts[eID] == _Quest.Identifier then
        dbg("".._Quest.Identifier.." "..self.Name..": you can not change carts in the same quest the object is initalized!");
        return true;
    end
    return false;
end

Core:RegisterBehavior(b_Reward_ObjectSetCarts);

-- -------------------------------------------------------------------------- --

---
-- Änder den Diplomatiestatus zwischen zwei Spielern.
--
-- @param _Party1   ID der ersten Partei
-- @param _Party2   ID der zweiten Partei
-- @param _State    Neuer Diplomatiestatus
-- @return Table mit Behavior
-- @within Reward
--
function Reward_Diplomacy(...)
    return b_Reward_Diplomacy:new(...);
end

b_Reward_Diplomacy = API.InstanceTable(b_Reprisal_Diplomacy);
b_Reward_Diplomacy.Name             = "Reward_ObjectDeactivate";
b_Reward_Diplomacy.Description.de   = "Reward: Sets Diplomacy state of two Players to a stated value.";
b_Reward_Diplomacy.Description.en   = "Lohn: Setzt den Diplomatiestatus zweier Spieler auf den angegebenen Wert.";
b_Reward_Diplomacy.GetReprisalTable = nil;

b_Reward_Diplomacy.GetRewardTable = function(self, _Quest)
    return { Reward.Custom,{self, self.CustomFunction} }
end

Core:RegisterBehavior(b_Reward_Diplomacy);

-- -------------------------------------------------------------------------- --

---
-- Verbessert die diplomatischen Beziehungen zwischen Sender und Empfänger
-- um einen Grad.
--
-- @return Table mit Behavior
-- @within Reward
--
function Reward_DiplomacyIncrease()
    return b_Reward_DiplomacyIncrease:new();
end

b_Reward_DiplomacyIncrease = {
    Name = "Reward_DiplomacyIncrease",
    Description = {
        en = "Reward: Diplomacy increases slightly to another player",
        de = "Lohn: Verbesserug des Diplomatiestatus zu einem anderen Spieler",
    },
}

function b_Reward_DiplomacyIncrease:GetRewardTable()
    return { Reward.Custom,{self, self.CustomFunction} }
end

function b_Reward_DiplomacyIncrease:CustomFunction(_Quest)
    local Sender = _Quest.SendingPlayer;
    local Receiver = _Quest.ReceivingPlayer;
    local State = GetDiplomacyState(Receiver, Sender);
    if State < 2 then
        SetDiplomacyState(Receiver, Sender, State+1);
    end
end

function b_Reward_DiplomacyIncrease:AddParameter(_Index, _Parameter)
    if (_Index == 0) then
        self.PlayerID = _Parameter * 1
    end
end

Core:RegisterBehavior(b_Reward_DiplomacyIncrease);

-- -------------------------------------------------------------------------- --

---
-- Erzeugt Handelsangebote im Lagerhaus des angegebenen Spielers.
--
-- Sollen Angebote gelöscht werden, muss "-" als Ware ausgewählt werden.
--
-- <b>Achtung:</b> Stadtlagerhäuser können keine Söldner anbieten!
--
-- @param _PlayerID Partei, die Anbietet
-- @param _Amount1  Menge des 1. Angebot
-- @param _Type1    Ware oder Typ des 1. Angebot
-- @param _Amount2  Menge des 2. Angebot
-- @param _Type2    Ware oder Typ des 2. Angebot
-- @param _Amount3  Menge des 3. Angebot
-- @param _Type3    Ware oder Typ des 3. Angebot
-- @param _Amount4  Menge des 4. Angebot
-- @param _Type4    Ware oder Typ des 4. Angebot
-- @return Table mit Behavior
-- @within Reward
--
function Reward_TradeOffers(...)
    return b_Reward_TradeOffers:new(...);
end

b_Reward_TradeOffers = {
    Name = "Reward_TradeOffers",
    Description = {
        en = "Reward: Deletes all existing offers for a merchant and sets new offers, if given",
        de = "Lohn: Löscht alle Angebote eines Händlers und setzt neue, wenn angegeben",
    },
    Parameter = {
        { ParameterType.Custom, en = "PlayerID", de = "PlayerID" },
        { ParameterType.Custom, en = "Amount 1", de = "Menge 1" },
        { ParameterType.Custom, en = "Offer 1", de = "Angebot 1" },
        { ParameterType.Custom, en = "Amount 2", de = "Menge 2" },
        { ParameterType.Custom, en = "Offer 2", de = "Angebot 2" },
        { ParameterType.Custom, en = "Amount 3", de = "Menge 3" },
        { ParameterType.Custom, en = "Offer 3", de = "Angebot 3" },
        { ParameterType.Custom, en = "Amount 4", de = "Menge 4" },
        { ParameterType.Custom, en = "Offer 4", de = "Angebot 4" },
    },
}

function b_Reward_TradeOffers:GetRewardTable()
    return { Reward.Custom,{self, self.CustomFunction} }
end

function b_Reward_TradeOffers:AddParameter(_Index, _Parameter)
    if (_Index == 0) then
        self.PlayerID = _Parameter
    elseif (_Index == 1) then
        self.AmountOffer1 = tonumber(_Parameter)
    elseif (_Index == 2) then
        self.Offer1 = _Parameter
    elseif (_Index == 3) then
        self.AmountOffer2 = tonumber(_Parameter)
    elseif (_Index == 4) then
        self.Offer2 = _Parameter
    elseif (_Index == 5) then
        self.AmountOffer3 = tonumber(_Parameter)
    elseif (_Index == 6) then
        self.Offer3 = _Parameter
    elseif (_Index == 7) then
        self.AmountOffer4 = tonumber(_Parameter)
    elseif (_Index == 8) then
        self.Offer4 = _Parameter
    end
end

function b_Reward_TradeOffers:CustomFunction()
    if (self.PlayerID > 1) and (self.PlayerID < 9) then
        local Storehouse = Logic.GetStoreHouse(self.PlayerID)
        Logic.RemoveAllOffers(Storehouse)
        for i =  1,4 do
            if self["Offer"..i] and self["Offer"..i] ~= "-" then
                if Goods[self["Offer"..i]] then
                    AddOffer(Storehouse, self["AmountOffer"..i], Goods[self["Offer"..i]])
                elseif Logic.IsEntityTypeInCategory(Entities[self["Offer"..i]], EntityCategories.Military) == 1 then
                    AddMercenaryOffer(Storehouse, self["AmountOffer"..i], Entities[self["Offer"..i]])
                else
                    AddEntertainerOffer (Storehouse , Entities[self["Offer"..i]])
                end
            end
        end
    end
end

function b_Reward_TradeOffers:DEBUG(_Quest)
    if Logic.GetStoreHouse(self.PlayerID ) == 0 then
        dbg(_Quest.Identifier .. ": Error in " .. self.Name .. ": Player " .. self.PlayerID .. " is dead. :-(")
        return true
    end
end

function b_Reward_TradeOffers:GetCustomData(_Index)
    local Players = { "2", "3", "4", "5", "6", "7", "8" }
    local Amount = { "1", "2", "3", "4", "5", "6", "7", "8", "9" }
    local Offers = {"-",
                    "G_Beer",
                    "G_Bow",
                    "G_Bread",
                    "G_Broom",
                    "G_Candle",
                    "G_Carcass",
                    "G_Cheese",
                    "G_Clothes",
                    "G_Cow",
                    "G_Grain",
                    "G_Herb",
                    "G_Honeycomb",
                    "G_Iron",
                    "G_Leather",
                    "G_Medicine",
                    "G_Milk",
                    "G_RawFish",
                    "G_Sausage",
                    "G_Sheep",
                    "G_SmokedFish",
                    "G_Soap",
                    "G_Stone",
                    "G_Sword",
                    "G_Wood",
                    "G_Wool",
                    "G_Salt",
                    "G_Dye",
                    "U_AmmunitionCart",
                    "U_BatteringRamCart",
                    "U_CatapultCart",
                    "U_SiegeTowerCart",
                    "U_MilitaryBandit_Melee_ME",
                    "U_MilitaryBandit_Melee_SE",
                    "U_MilitaryBandit_Melee_NA",
                    "U_MilitaryBandit_Melee_NE",
                    "U_MilitaryBandit_Ranged_ME",
                    "U_MilitaryBandit_Ranged_NA",
                    "U_MilitaryBandit_Ranged_NE",
                    "U_MilitaryBandit_Ranged_SE",
                    "U_MilitaryBow_RedPrince",
                    "U_MilitaryBow",
                    "U_MilitarySword_RedPrince",
                    "U_MilitarySword",
                    "U_Entertainer_NA_FireEater",
                    "U_Entertainer_NA_StiltWalker",
                    "U_Entertainer_NE_StrongestMan_Barrel",
                    "U_Entertainer_NE_StrongestMan_Stone",
                    }
    if g_GameExtraNo and g_GameExtraNo >= 1 then
        table.insert(Offers, "G_Gems")
        table.insert(Offers, "G_Olibanum")
        table.insert(Offers, "G_MusicalInstrument")
        table.insert(Offers, "G_MilitaryBandit_Ranged_AS")
        table.insert(Offers, "G_MilitaryBandit_Melee_AS")
        table.insert(Offers, "U_MilitarySword_Khana")
        table.insert(Offers, "U_MilitaryBow_Khana")
    end
    if (_Index == 0) then
        return Players
    elseif (_Index == 1) or (_Index == 3) or (_Index == 5) or (_Index == 7) then
        return Amount
    elseif (_Index == 2) or (_Index == 4) or (_Index == 6) or (_Index == 8) then
        return Offers
    end
end

Core:RegisterBehavior(b_Reward_TradeOffers)

-- -------------------------------------------------------------------------- --

---
-- Ein benanntes Entity wird zerstört.
--
-- @param _ScriptName Skriptname des Entity
-- @return Table mit Behavior
-- @within Reward
--
function Reward_DestroyEntity(...)
    return b_Reward_DestroyEntity:new(...);
end

b_Reward_DestroyEntity = API.InstanceTable(b_Reprisal_DestroyEntity);
b_Reward_DestroyEntity.Name = "Reward_DestroyEntity";
b_Reward_DestroyEntity.Description.en = "Reward: Replaces an entity with an invisible script entity, which retains the entities name.";
b_Reward_DestroyEntity.Description.de = "Lohn: Ersetzt eine Entity mit einer unsichtbaren Script-Entity, die den Namen übernimmt.";
b_Reward_DestroyEntity.GetReprisalTable = nil;

b_Reward_DestroyEntity.GetRewardTable = function(self, _Quest)
    return { Reward.Custom,{self, self.CustomFunction} }
end

Core:RegisterBehavior(b_Reward_DestroyEntity);

-- -------------------------------------------------------------------------- --

---
-- Zerstört einen über die QSB erzeugten Effekt.
--
-- @param _EffectName Name des Effekts
-- @return Table mit Behavior
-- @within Reward
--
function Reward_DestroyEffect(...)
    return b_Reward_DestroyEffect:new(...);
end

b_Reward_DestroyEffect = API.InstanceTable(b_Reprisal_DestroyEffect);
b_Reward_DestroyEffect.Name = "Reward_DestroyEffect";
b_Reward_DestroyEffect.Description.en = "Reward: Destroys an effect.";
b_Reward_DestroyEffect.Description.de = "Lohn: Zerstört einen Effekt.";
b_Reward_DestroyEffect.GetReprisalTable = nil;

b_Reward_DestroyEffect.GetRewardTable = function(self, _Quest)
    return { Reward.Custom, { self, self.CustomFunction } };
end

Core:RegisterBehavior(b_Reward_DestroyEffect);

-- -------------------------------------------------------------------------- --

---
-- Ersetzt ein Entity mit einem Batallion.
--
-- Ist die Position ein Gebäude, werden die Battalione am Eingang erzeugt und
-- Das Entity wird nicht ersetzt.
--
-- @param _Position    Skriptname des Entity
-- @param _PlayerID    PlayerID des Battalion
-- @param _UnitType    Einheitentyp der Soldaten
-- @param _Orientation Ausrichtung in °
-- @param _Soldiers    Anzahl an Soldaten
-- @param _HideFromAI  Vor KI verstecken
-- @return Table mit Behavior
-- @within Reward
--
function Reward_CreateBattalion(...)
    return b_Reward_CreateBattalion:new(...);
end

b_Reward_CreateBattalion = {
    Name = "Reward_CreateBattalion",
    Description = {
        en = "Reward: Replaces a script entity with a battalion, which retains the entities name",
        de = "Lohn: Ersetzt eine Script-Entity durch ein Bataillon, welches den Namen der Script-Entity übernimmt",
    },
    Parameter = {
        { ParameterType.ScriptName, en = "Script entity", de = "Script Entity" },
        { ParameterType.PlayerID, en = "Player", de = "Spieler" },
        { ParameterType.Custom, en = "Type name", de = "Typbezeichnung" },
        { ParameterType.Number, en = "Orientation (in degrees)", de = "Ausrichtung (in Grad)" },
        { ParameterType.Number, en = "Number of soldiers", de = "Anzahl Soldaten" },
        { ParameterType.Custom, en = "Hide from AI", de = "Vor KI verstecken" },
    },
}

function b_Reward_CreateBattalion:GetRewardTable()
    return { Reward.Custom,{self, self.CustomFunction} }
end

function b_Reward_CreateBattalion:AddParameter(_Index, _Parameter)
    if (_Index == 0) then
        self.ScriptNameEntity = _Parameter
    elseif (_Index == 1) then
        self.PlayerID = _Parameter * 1
    elseif (_Index == 2) then
        self.UnitKey = _Parameter
    elseif (_Index == 3) then
        self.Orientation = _Parameter * 1
    elseif (_Index == 4) then
        self.SoldierCount = _Parameter * 1
    elseif (_Index == 5) then
        self.HideFromAI = AcceptAlternativeBoolean(_Parameter)
    end
end

function b_Reward_CreateBattalion:CustomFunction(_Quest)
    if not IsExisting( self.ScriptNameEntity ) then
        return false
    end
    local pos = GetPosition(self.ScriptNameEntity)
    local NewID = Logic.CreateBattalionOnUnblockedLand( Entities[self.UnitKey], pos.X, pos.Y, self.Orientation, self.PlayerID, self.SoldierCount )
    local posID = GetID(self.ScriptNameEntity)
    if Logic.IsBuilding(posID) == 0 then
        DestroyEntity(self.ScriptNameEntity)
        Logic.SetEntityName( NewID, self.ScriptNameEntity )
    end
    if self.HideFromAI then
        AICore.HideEntityFromAI( self.PlayerID, NewID, true )
    end
end

function b_Reward_CreateBattalion:GetCustomData( _Index )
    local Data = {}
    if _Index == 2 then
        for k, v in pairs( Entities ) do
            if Logic.IsEntityTypeInCategory( v, EntityCategories.Soldier ) == 1 then
                table.insert( Data, k )
            end
        end
        table.sort( Data )
    elseif _Index == 5 then
        table.insert( Data, "false" )
        table.insert( Data, "true" )
    else
        assert( false )
    end
    return Data
end

function b_Reward_CreateBattalion:DEBUG(_Quest)
    if not Entities[self.UnitKey] then
        dbg(_Quest.Identifier .. " " .. self.Name .. ": got an invalid entity type!");
        return true;
    elseif not IsExisting(self.ScriptNameEntity) then
        dbg(_Quest.Identifier .. " " .. self.Name .. ": spawnpoint does not exist!");
        return true;
    elseif tonumber(self.PlayerID) == nil or self.PlayerID < 1 or self.PlayerID > 8 then
        dbg(_Quest.Identifier .. " " .. self.Name .. ": playerID is wrong!");
        return true;
    elseif tonumber(self.Orientation) == nil then
        dbg(_Quest.Identifier .. " " .. self.Name .. ": orientation must be a number!");
        return true;
    elseif tonumber(self.SoldierCount) == nil or self.SoldierCount < 1 then
        dbg(_Quest.Identifier .. " " .. self.Name .. ": you can not create a empty batallion!");
        return true;
    end
    return false;
end

Core:RegisterBehavior(b_Reward_CreateBattalion);

-- -------------------------------------------------------------------------- --

---
-- Erzeugt eine Menga von Battalionen an der Position.
--
-- @param _Amount      Anzahl erzeugter Battalione
-- @param _Position    Skriptname des Entity
-- @param _PlayerID    PlayerID des Battalion
-- @param _UnitType    Einheitentyp der Soldaten
-- @param _Orientation Ausrichtung in °
-- @param _Soldiers    Anzahl an Soldaten
-- @param _HideFromAI  Vor KI verstecken
-- @return Table mit Behavior
-- @within Reward
--
function Reward_CreateSeveralBattalions(...)
    return b_Reward_CreateSeveralBattalions:new(...);
end

b_Reward_CreateSeveralBattalions = {
    Name = "Reward_CreateSeveralBattalions",
    Description = {
        en = "Reward: Creates a given amount of battalions",
        de = "Lohn: Erstellt eine gegebene Anzahl Bataillone",
    },
    Parameter = {
        { ParameterType.Number, en = "Amount", de = "Anzahl" },
        { ParameterType.ScriptName, en = "Script entity", de = "Script Entity" },
        { ParameterType.PlayerID, en = "Player", de = "Spieler" },
        { ParameterType.Custom, en = "Type name", de = "Typbezeichnung" },
        { ParameterType.Number, en = "Orientation (in degrees)", de = "Ausrichtung (in Grad)" },
        { ParameterType.Number, en = "Number of soldiers", de = "Anzahl Soldaten" },
        { ParameterType.Custom, en = "Hide from AI", de = "Vor KI verstecken" },
    },
}

function b_Reward_CreateSeveralBattalions:GetRewardTable()
    return { Reward.Custom,{self, self.CustomFunction} }
end

function b_Reward_CreateSeveralBattalions:AddParameter(_Index, _Parameter)
    if (_Index == 0) then
        self.Amount = _Parameter * 1
    elseif (_Index == 1) then
        self.ScriptNameEntity = _Parameter
    elseif (_Index == 2) then
        self.PlayerID = _Parameter * 1
    elseif (_Index == 3) then
        self.UnitKey = _Parameter
    elseif (_Index == 4) then
        self.Orientation = _Parameter * 1
    elseif (_Index == 5) then
        self.SoldierCount = _Parameter * 1
    elseif (_Index == 6) then
        self.HideFromAI = AcceptAlternativeBoolean(_Parameter)
    end
end

function b_Reward_CreateSeveralBattalions:CustomFunction(_Quest)
    if not IsExisting( self.ScriptNameEntity ) then
        return false
    end
    local tID = GetID(self.ScriptNameEntity)
    local x,y,z = Logic.EntityGetPos(tID);
    if Logic.IsBuilding(tID) == 1 then
        x,y = Logic.GetBuildingApproachPosition(tID)
    end

    for i=1, self.Amount do
        local NewID = Logic.CreateBattalionOnUnblockedLand( Entities[self.UnitKey], x, y, self.Orientation, self.PlayerID, self.SoldierCount )
        Logic.SetEntityName( NewID, self.ScriptNameEntity .. "_" .. i )
        if self.HideFromAI then
            AICore.HideEntityFromAI( self.PlayerID, NewID, true )
        end
    end
end

function b_Reward_CreateSeveralBattalions:GetCustomData( _Index )
    local Data = {}
    if _Index == 3 then
        for k, v in pairs( Entities ) do
            if Logic.IsEntityTypeInCategory( v, EntityCategories.Soldier ) == 1 then
                table.insert( Data, k )
            end
        end
        table.sort( Data )
    elseif _Index == 6 then
        table.insert( Data, "false" )
        table.insert( Data, "true" )
    else
        assert( false )
    end
    return Data
end

function b_Reward_CreateSeveralBattalions:DEBUG(_Quest)
    if not Entities[self.UnitKey] then
        dbg(_Quest.Identifier .. " " .. self.Name .. ": got an invalid entity type!");
        return true;
    elseif not IsExisting(self.ScriptNameEntity) then
        dbg(_Quest.Identifier .. " " .. self.Name .. ": spawnpoint does not exist!");
        return true;
    elseif tonumber(self.PlayerID) == nil or self.PlayerID < 1 or self.PlayerID > 8 then
        dbg(_Quest.Identifier .. " " .. self.Name .. ": playerDI is wrong!");
        return true;
    elseif tonumber(self.Orientation) == nil then
        dbg(_Quest.Identifier .. " " .. self.Name .. ": orientation must be a number!");
        return true;
    elseif tonumber(self.SoldierCount) == nil or self.SoldierCount < 1 then
        dbg(_Quest.Identifier .. " " .. self.Name .. ": you can not create a empty batallion!");
        return true;
    elseif tonumber(self.Amount) == nil or self.Amount < 0 then
        dbg(_Quest.Identifier .. " " .. self.Name .. ": amount can not be negative!");
        return true;
    end
    return false;
end

Core:RegisterBehavior(b_Reward_CreateSeveralBattalions);

-- -------------------------------------------------------------------------- --

---
-- Erzeugt einen Effekt an der angegebenen Position.
--
-- @param _EffectName  Einzigartiger Effektname
-- @param _TypeName    Typ des Effekt
-- @param _PlayerID    PlayerID des Effekt
-- @param _Location    Position des Effekt
-- @param _Orientation Ausrichtung in °
-- @return Table mit Behavior
-- @within Reward
--
function Reward_CreateEffect(...)
    return b_Reward_CreateEffect:new(...);
end

b_Reward_CreateEffect = {
    Name = "Reward_CreateEffect",
    Description = {
        en = "Reward: Creates an effect at a specified position",
        de = "Lohn: Erstellt einen Effekt an der angegebenen Position",
    },
    Parameter = {
        { ParameterType.Default,    en = "Effect name", de = "Effektname" },
        { ParameterType.Custom,     en = "Type name", de = "Typbezeichnung" },
        { ParameterType.PlayerID,   en = "Player", de = "Spieler" },
        { ParameterType.ScriptName, en = "Location", de = "Ort" },
        { ParameterType.Number,     en = "Orientation (in degrees)(-1: from locating entity)", de = "Ausrichtung (in Grad)(-1: von Positionseinheit)" },
    }
}

function b_Reward_CreateEffect:AddParameter(_Index, _Parameter)

    if _Index == 0 then
        self.EffectName = _Parameter;
    elseif _Index == 1 then
        self.Type = EGL_Effects[_Parameter];
    elseif _Index == 2 then
        self.PlayerID = _Parameter * 1;
    elseif _Index == 3 then
        self.Location = _Parameter;
    elseif _Index == 4 then
        self.Orientation = _Parameter * 1;
    end

end

function b_Reward_CreateEffect:GetRewardTable(_Quest)
    return { Reward.Custom, { self, self.CustomFunction } };
end

function b_Reward_CreateEffect:CustomFunction(_Quest)
    if Logic.IsEntityDestroyed(self.Location) then
        return;
    end
    local entity = assert(GetID(self.Location), _Quest.Identifier .. "Error in " .. self.Name .. ": CustomFunction: Entity is invalid");
    if QSB.EffectNameToID[self.EffectName] and Logic.IsEffectRegistered(QSB.EffectNameToID[self.EffectName]) then
        return;
    end

    local posX, posY = Logic.GetEntityPosition(entity);
    local orientation = tonumber(self.Orientation);
    local effect = Logic.CreateEffectWithOrientation(self.Type, posX, posY, orientation, self.PlayerID);
    if self.EffectName ~= "" then
        QSB.EffectNameToID[self.EffectName] = effect;
    end
end

function b_Reward_CreateEffect:DEBUG(_Quest)
    if QSB.EffectNameToID[self.EffectName] and Logic.IsEffectRegistered(QSB.EffectNameToID[self.EffectName]) then
        dbg("".._Quest.Identifier.." "..self.Name..": effect already exists!");
        return true;
    elseif not IsExisting(self.Location) then
        sbg("".._Quest.Identifier.." "..self.Name..": location '" ..self.Location.. "' is missing!");
        return true;
    elseif self.PlayerID and (self.PlayerID < 0 or self.PlayerID > 8) then
        dbg("".._Quest.Identifier.." "..self.Name..": invalid playerID!");
        return true;
    elseif tonumber(self.Orientation) == nil then
        dbg("".._Quest.Identifier.." "..self.Name..": invalid orientation!");
        return true;
    end
end

function b_Reward_CreateEffect:GetCustomData(_Index)
    assert(_Index == 1, "Error in " .. self.Name .. ": GetCustomData: Index is invalid.");
    local types = {};
    for k, v in pairs(EGL_Effects) do
        table.insert(types, k);
    end
    table.sort(types);
    return types;
end

Core:RegisterBehavior(b_Reward_CreateEffect);

-- -------------------------------------------------------------------------- --

---
-- Ersetzt ein Entity mit dem Skriptnamen durch ein neues Entity.
--
-- Ist die Position ein Gebäude, werden die Entities am Eingang erzeugt und
-- die Position wird nicht ersetzt.
--
-- @param _ScriptName  Skriptname des Entity
-- @param _PlayerID    PlayerID des Effekt
-- @param _TypeName    Einzigartiger Effektname
-- @param _Orientation Ausrichtung in °
-- @param _HideFromAI  Vor KI verstecken
-- @return Table mit Behavior
-- @within Reward
--
function Reward_CreateEntity(...)
    return b_Reward_CreateEntity:new(...);
end

b_Reward_CreateEntity = {
    Name = "Reward_CreateEntity",
    Description = {
        en = "Reward: Replaces an entity by a new one of a given type",
        de = "Lohn: Ersetzt eine Entity durch eine neue gegebenen Typs",
    },
    Parameter = {
        { ParameterType.ScriptName, en = "Script entity", de = "Script Entity" },
        { ParameterType.PlayerID, en = "Player", de = "Spieler" },
        { ParameterType.Custom, en = "Type name", de = "Typbezeichnung" },
        { ParameterType.Number, en = "Orientation (in degrees)", de = "Ausrichtung (in Grad)" },
        { ParameterType.Custom, en = "Hide from AI", de = "Vor KI verstecken" },
    },
}

function b_Reward_CreateEntity:GetRewardTable()
    return { Reward.Custom,{self, self.CustomFunction} }
end

function b_Reward_CreateEntity:AddParameter(_Index, _Parameter)
    if (_Index == 0) then
        self.ScriptNameEntity = _Parameter
    elseif (_Index == 1) then
        self.PlayerID = _Parameter * 1
    elseif (_Index == 2) then
        self.UnitKey = _Parameter
    elseif (_Index == 3) then
        self.Orientation = _Parameter * 1
    elseif (_Index == 4) then
        self.HideFromAI = AcceptAlternativeBoolean(_Parameter)
    end
end

function b_Reward_CreateEntity:CustomFunction(_Quest)
    if not IsExisting( self.ScriptNameEntity ) then
        return false
    end
    local pos = GetPosition(self.ScriptNameEntity)
    local NewID;
    if Logic.IsEntityTypeInCategory( self.UnitKey, EntityCategories.Soldier ) == 1 then
        NewID       = Logic.CreateBattalionOnUnblockedLand( Entities[self.UnitKey], pos.X, pos.Y, self.Orientation, self.PlayerID, 1 )
        local l,s = {Logic.GetSoldiersAttachedToLeader(NewID)}
        Logic.SetOrientation(s,self.Orientation)
    else
        NewID = Logic.CreateEntityOnUnblockedLand( Entities[self.UnitKey], pos.X, pos.Y, self.Orientation, self.PlayerID )
    end
    local posID = GetID(self.ScriptNameEntity)
    if Logic.IsBuilding(posID) == 0 then
        DestroyEntity(self.ScriptNameEntity)
        Logic.SetEntityName( NewID, self.ScriptNameEntity )
    end
    if self.HideFromAI then
        AICore.HideEntityFromAI( self.PlayerID, NewID, true )
    end
end

function b_Reward_CreateEntity:GetCustomData( _Index )
    local Data = {}
    if _Index == 2 then
        for k, v in pairs( Entities ) do
            local name = {"^M_*","^XS_*","^X_*","^XT_*","^Z_*"}
            local found = false;
            for i=1,#name do
                if k:find(name[i]) then
                    found = true;
                    break;
                end
            end
            if not found then
                table.insert( Data, k );
            end
        end
        table.sort( Data )

    elseif _Index == 4 or _Index == 5 then
        table.insert( Data, "false" )
        table.insert( Data, "true" )
    else
        assert( false )
    end
    return Data
end

function b_Reward_CreateEntity:DEBUG(_Quest)
    if not Entities[self.UnitKey] then
        dbg(_Quest.Identifier .. " " .. self.Name .. ": got an invalid entity type!");
        return true;
    elseif not IsExisting(self.ScriptNameEntity) then
        dbg(_Quest.Identifier .. " " .. self.Name .. ": spawnpoint does not exist!");
        return true;
    elseif tonumber(self.PlayerID) == nil or self.PlayerID < 0 or self.PlayerID > 8 then
        dbg(_Quest.Identifier .. " " .. self.Name .. ": playerID is not valid!");
        return true;
    elseif tonumber(self.Orientation) == nil then
        dbg(_Quest.Identifier .. " " .. self.Name .. ": orientation must be a number!");
        return true;
    end
    return false;
end

Core:RegisterBehavior(b_Reward_CreateEntity);

-- -------------------------------------------------------------------------- --

---
-- Erzeugt mehrere Entities an der angegebenen Position
--
-- @param _Amount      Anzahl an Entities
-- @param _ScriptName  Skriptname des Entity
-- @param _PlayerID    PlayerID des Effekt
-- @param _TypeName    Einzigartiger Effektname
-- @param _Orientation Ausrichtung in °
-- @param _HideFromAI  Vor KI verstecken
-- @return Table mit Behavior
-- @within Reward
--
function Reward_CreateSeveralEntities(...)
    return b_Reward_CreateSeveralEntities:new(...);
end

b_Reward_CreateSeveralEntities = {
    Name = "Reward_CreateSeveralEntities",
    Description = {
        en = "Reward: Creating serveral battalions at the position of a entity. They retains the entities name and a _[index] suffix",
        de = "Lohn: Erzeugt mehrere Entities an der Position der Entity. Sie übernimmt den Namen der Script Entity und den Suffix _[index]",
    },
    Parameter = {
        { ParameterType.Number, en = "Amount", de = "Anzahl" },
        { ParameterType.ScriptName, en = "Script entity", de = "Script Entity" },
        { ParameterType.PlayerID, en = "Player", de = "Spieler" },
        { ParameterType.Custom, en = "Type name", de = "Typbezeichnung" },
        { ParameterType.Number, en = "Orientation (in degrees)", de = "Ausrichtung (in Grad)" },
        { ParameterType.Custom, en = "Hide from AI", de = "Vor KI verstecken" },
    },
}

function b_Reward_CreateSeveralEntities:GetRewardTable()
    return { Reward.Custom,{self, self.CustomFunction} }
end

function b_Reward_CreateSeveralEntities:AddParameter(_Index, _Parameter)
    if (_Index == 0) then
        self.Amount = _Parameter * 1
    elseif (_Index == 1) then
        self.ScriptNameEntity = _Parameter
    elseif (_Index == 2) then
        self.PlayerID = _Parameter * 1
    elseif (_Index == 3) then
        self.UnitKey = _Parameter
    elseif (_Index == 4) then
        self.Orientation = _Parameter * 1
    elseif (_Index == 5) then
        self.HideFromAI = AcceptAlternativeBoolean(_Parameter)
    end
end

function b_Reward_CreateSeveralEntities:CustomFunction(_Quest)
    if not IsExisting( self.ScriptNameEntity ) then
        return false
    end
    local pos = GetPosition(self.ScriptNameEntity)
    local NewID;
    for i=1, self.Amount do
        if Logic.IsEntityTypeInCategory( self.UnitKey, EntityCategories.Soldier ) == 1 then
            NewID       = Logic.CreateBattalionOnUnblockedLand( Entities[self.UnitKey], pos.X, pos.Y, self.Orientation, self.PlayerID, 1 )
            local l,s = {Logic.GetSoldiersAttachedToLeader(NewID)}
            Logic.SetOrientation(s,self.Orientation)
        else
            NewID = Logic.CreateEntityOnUnblockedLand( Entities[self.UnitKey], pos.X, pos.Y, self.Orientation, self.PlayerID )
        end
        Logic.SetEntityName( NewID, self.ScriptNameEntity .. "_" .. i )
        if self.HideFromAI then
            AICore.HideEntityFromAI( self.PlayerID, NewID, true )
        end
    end
end

function b_Reward_CreateSeveralEntities:GetCustomData( _Index )
    local Data = {}
    if _Index == 3 then
        for k, v in pairs( Entities ) do
            local name = {"^M_*","^XS_*","^X_*","^XT_*","^Z_*"}
            local found = false;
            for i=1,#name do
                if k:find(name[i]) then
                    found = true;
                    break;
                end
            end
            if not found then
                table.insert( Data, k );
            end
        end
        table.sort( Data )

    elseif _Index == 5 or _Index == 6 then
        table.insert( Data, "false" )
        table.insert( Data, "true" )
    else
        assert( false )
    end
    return Data

end

function b_Reward_CreateSeveralEntities:DEBUG(_Quest)
    if not Entities[self.UnitKey] then
        dbg(_Quest.Identifier .. " " .. self.Name .. ": got an invalid entity type!");
        return true;
    elseif not IsExisting(self.ScriptNameEntity) then
        dbg(_Quest.Identifier .. " " .. self.Name .. ": spawnpoint does not exist!");
        return true;
    elseif tonumber(self.PlayerID) == nil or self.PlayerID < 1 or self.PlayerID > 8 then
        dbg(_Quest.Identifier .. " " .. self.Name .. ": spawnpoint does not exist!");
        return true;
    elseif tonumber(self.Orientation) == nil then
        dbg(_Quest.Identifier .. " " .. self.Name .. ": orientation must be a number!");
        return true;
    elseif tonumber(self.Amount) == nil or self.Amount < 0 then
        dbg(_Quest.Identifier .. " " .. self.Name .. ": amount can not be negative!");
        return true;
    end
    return false;
end

Core:RegisterBehavior(b_Reward_CreateSeveralEntities);

-- -------------------------------------------------------------------------- --

---
-- Bewegt einen Siedler oder ein Battalion zum angegebenen Zielort.
--
-- @param _Settler     Einheit, die bewegt wird
-- @param _Destination Bewegungsziel
-- @return Table mit Behavior
-- @within Reward
--
function Reward_MoveSettler(...)
    return b_Reward_MoveSettler:new(...);
end

b_Reward_MoveSettler = {
    Name = "Reward_MoveSettler",
    Description = {
        en = "Reward: Moves a (NPC) settler to a destination. Must not be AI controlled, or it won't move",
        de = "Lohn: Bewegt einen (NPC) Siedler zu einem Zielort. Darf keinem KI Spieler gehören, ansonsten wird sich der Siedler nicht bewegen",
    },
    Parameter = {
        { ParameterType.ScriptName, en = "Settler", de = "Siedler" },
        { ParameterType.ScriptName, en = "Destination", de = "Ziel" },
    },
}

function b_Reward_MoveSettler:GetRewardTable()
    return { Reward.Custom,{self, self.CustomFunction} }
end

function b_Reward_MoveSettler:AddParameter(_Index, _Parameter)
    if (_Index == 0) then
        self.ScriptNameUnit = _Parameter
    elseif (_Index == 1) then
        self.ScriptNameDest = _Parameter
    end
end

function b_Reward_MoveSettler:CustomFunction(_Quest)
    if Logic.IsEntityDestroyed( self.ScriptNameUnit ) or Logic.IsEntityDestroyed( self.ScriptNameDest ) then
        return false
    end
    local DestID = GetID( self.ScriptNameDest )
    local DestX, DestY = Logic.GetEntityPosition( DestID )
    if Logic.IsBuilding( DestID ) == 1 then
        DestX, DestY = Logic.GetBuildingApproachPosition( DestID )
    end
    Logic.MoveSettler( GetID( self.ScriptNameUnit ), DestX, DestY )
end

function b_Reward_MoveSettler:DEBUG(_Quest)
    if not not IsExisting(self.ScriptNameUnit) then
        dbg(_Quest.Identifier .. " " .. self.Name .. ": mover entity does not exist!");
        return true;
    elseif not IsExisting(self.ScriptNameDest) then
        dbg(_Quest.Identifier .. " " .. self.Name .. ": destination does not exist!");
        return true;
    end
    return false;
end

Core:RegisterBehavior(b_Reward_MoveSettler);

-- -------------------------------------------------------------------------- --

---
-- Der Spieler gewinnt das Spiel.
--
-- @return Table mit Behavior
-- @within Reward
--
function Reward_Victory()
    return b_Reward_Victory:new()
end

b_Reward_Victory = {
    Name = "Reward_Victory",
    Description = {
        en = "Reward: The player wins the game.",
        de = "Lohn: Der Spieler gewinnt das Spiel.",
    },
}

function b_Reward_Victory:GetRewardTable(_Quest)
    return {Reward.Victory};
end

Core:RegisterBehavior(b_Reward_Victory);

-- -------------------------------------------------------------------------- --

---
-- Der Spieler verliert das Spiel.
--
-- @return Table mit Behavior
-- @within Reward
--
function Reward_Defeat()
    return b_Reward_Defeat:new()
end

b_Reward_Defeat = {
    Name = "Reward_Defeat",
    Description = {
        en = "Reward: The player loses the game.",
        de = "Lohn: Der Spieler verliert das Spiel.",
    },
}

function b_Reward_Defeat:GetRewardTable(_Quest)
    return { Reward.Custom, {self, self.CustomFunction} }
end

function b_Reward_Defeat:CustomFunction(_Quest)
    _Quest:TerminateEventsAndStuff()
    Logic.ExecuteInLuaLocalState("GUI_Window.MissionEndScreenSetVictoryReasonText(".. g_VictoryAndDefeatType.DefeatMissionFailed ..")")
    Defeated(_Quest.ReceivingPlayer)
end

Core:RegisterBehavior(b_Reward_Defeat);

-- -------------------------------------------------------------------------- --

---
-- Zeigt die Siegdekoration an dem Quest an.
--
-- Dies ist reine Optik! Der Spieler wird dadurch nicht das Spiel gewinnen.
--
-- @return Table mit Behavior
-- @within Reward
--
function Reward_FakeVictory()
    return b_Reward_FakeVictory:new();
end

b_Reward_FakeVictory = {
    Name = "Reward_FakeVictory",
    Description = {
        en = "Reward: Display a victory icon for a quest",
        de = "Lohn: Zeigt ein Siegesicon fuer diese Quest",
    },
}

function b_Reward_FakeVictory:GetRewardTable()
    return { Reward.FakeVictory }
end

Core:RegisterBehavior(b_Reward_FakeVictory);

-- -------------------------------------------------------------------------- --

---
-- Erzeugt eine Armee, die das angegebene Territorium angreift.
--
-- Die Armee wird versuchen Gebäude auf dem Territrium zu zerstören.
-- <ul>
-- <li>Außenposten: Die Armee versucht den Außenposten zu zerstören</li>
-- <li>Stadt: Die Armee versucht das Lagerhaus zu zerstören</li>
-- </ul>
--
-- @param _PlayerID   PlayerID der Angreifer
-- @param _SpawnPoint Skriptname des Entstehungspunkt
-- @param _Territory  Zielterritorium
-- @param _Sword      Anzahl Schwertkämpfer (Battalion)
-- @param _Bow        Anzahl Bogenschützen (Battalion)
-- @param _Cata       Anzahl Katapulte
-- @param _Towers     Anzahl Belagerungstürme
-- @param _Rams       Anzahl Rammen
-- @param _Ammo       Anzahl Munitionswagen
-- @param _Type       Typ der Soldaten
-- @param _Reuse      Freie Truppen wiederverwenden
-- @return Table mit Behavior
-- @within Reward
--
function Reward_AI_SpawnAndAttackTerritory(...)
    return b_Reward_AI_SpawnAndAttackTerritory:new(...);
end

b_Reward_AI_SpawnAndAttackTerritory = {
    Name = "Reward_AI_SpawnAndAttackTerritory",
    Description = {
        en = "Reward: Spawns AI troops and attacks a territory (Hint: Use for hidden quests as a surprise)",
        de = "Lohn: Erstellt KI Truppen und greift ein Territorium an (Tipp: Fuer eine versteckte Quest als Ueberraschung verwenden)",
    },
    Parameter = {
        { ParameterType.PlayerID, en = "AI Player", de = "KI Spieler" },
        { ParameterType.ScriptName, en = "Spawn point", de = "Erstellungsort" },
        { ParameterType.TerritoryName, en = "Territory", de = "Territorium" },
        { ParameterType.Number, en = "Sword", de = "Schwert" },
        { ParameterType.Number, en = "Bow", de = "Bogen" },
        { ParameterType.Number, en = "Catapults", de = "Katapulte" },
        { ParameterType.Number, en = "Siege towers", de = "Belagerungstuerme" },
        { ParameterType.Number, en = "Rams", de = "Rammen" },
        { ParameterType.Number, en = "Ammo carts", de = "Munitionswagen" },
        { ParameterType.Custom, en = "Soldier type", de = "Soldatentyp" },
        { ParameterType.Custom, en = "Reuse troops", de = "Verwende bestehende Truppen" },
    },
}

function b_Reward_AI_SpawnAndAttackTerritory:GetRewardTable()
    return { Reward.Custom,{self, self.CustomFunction} }
end

function b_Reward_AI_SpawnAndAttackTerritory:AddParameter(_Index, _Parameter)

    if (_Index == 0) then
        self.AIPlayerID = _Parameter * 1
    elseif (_Index == 1) then
        self.Spawnpoint = _Parameter
    elseif (_Index == 2) then
        self.TerritoryID = tonumber(_Parameter)
        if not self.TerritoryID then
            self.TerritoryID = GetTerritoryIDByName(_Parameter)
        end
    elseif (_Index == 3) then
        self.NumSword = _Parameter * 1
    elseif (_Index == 4) then
        self.NumBow = _Parameter * 1
    elseif (_Index == 5) then
        self.NumCatapults = _Parameter * 1
    elseif (_Index == 6) then
        self.NumSiegeTowers = _Parameter * 1
    elseif (_Index == 7) then
        self.NumRams = _Parameter * 1
    elseif (_Index == 8) then
        self.NumAmmoCarts = _Parameter * 1
    elseif (_Index == 9) then
        if _Parameter == "Normal" or _Parameter == false then
            self.TroopType = false
        elseif _Parameter == "RedPrince" or _Parameter == true then
            self.TroopType = true
        elseif _Parameter == "Bandit" or _Parameter == 2 then
            self.TroopType = 2
        elseif _Parameter == "Cultist" or _Parameter == 3 then
            self.TroopType = 3
        else
            assert(false)
        end
    elseif (_Index == 10) then
        self.ReuseTroops = AcceptAlternativeBoolean(_Parameter)
    end

end

function b_Reward_AI_SpawnAndAttackTerritory:GetCustomData( _Index )

    local Data = {}
    if _Index == 9 then
        table.insert( Data, "Normal" )
        table.insert( Data, "RedPrince" )
        table.insert( Data, "Bandit" )
        if g_GameExtraNo >= 1 then
            table.insert( Data, "Cultist" )
        end

    elseif _Index == 10 then
        table.insert( Data, "false" )
        table.insert( Data, "true" )

    else
        assert( false )
    end

    return Data

end

function b_Reward_AI_SpawnAndAttackTerritory:CustomFunction(_Quest)

    local TargetID = Logic.GetTerritoryAcquiringBuildingID( self.TerritoryID )
    if TargetID ~= 0 then
        AIScript_SpawnAndAttackCity( self.AIPlayerID, TargetID, self.Spawnpoint, self.NumSword, self.NumBow, self.NumCatapults, self.NumSiegeTowers, self.NumRams, self.NumAmmoCarts, self.TroopType, self.ReuseTroops)
    end

end

function b_Reward_AI_SpawnAndAttackTerritory:DEBUG(_Quest)
    if self.AIPlayerID < 2 then
        dbg(_Quest.Identifier .. ": Error in " .. self.Name .. ": Player " .. self.AIPlayerID .. " is wrong")
        return true
    elseif Logic.IsEntityDestroyed(self.Spawnpoint) then
        dbg(_Quest.Identifier .. " " .. self.Name .. ": Entity " .. self.SpawnPoint .. " is missing")
        return true
    elseif self.TerritoryID == 0 then
        dbg(_Quest.Identifier .. " " .. self.Name .. ": Territory unknown")
        return true
    elseif self.NumSword < 0 then
        dbg(_Quest.Identifier .. " " .. self.Name .. ": Number of Swords is negative")
        return true
    elseif self.NumBow < 0 then
        dbg(_Quest.Identifier .. " " .. self.Name .. ": Number of Bows is negative")
        return true
    elseif self.NumBow + self.NumSword < 1 then
        dbg(_Quest.Identifier .. " " .. self.Name .. ": No Soldiers?")
        return true
    elseif self.NumCatapults < 0 then
        dbg(_Quest.Identifier .. " " .. self.Name .. ": Catapults is negative")
        return true
    elseif self.NumSiegeTowers < 0 then
        dbg(_Quest.Identifier .. " " .. self.Name .. ": SiegeTowers is negative")
        return true
    elseif self.NumRams < 0 then
        dbg(_Quest.Identifier .. " " .. self.Name .. ": Rams is negative")
        return true
    elseif self.NumAmmoCarts < 0 then
        dbg(_Quest.Identifier .. " " .. self.Name .. ": AmmoCarts is negative")
        return true
    end
    return false;
end

Core:RegisterBehavior(b_Reward_AI_SpawnAndAttackTerritory);

-- -------------------------------------------------------------------------- --

---
-- Erzeugt eine Armee, die sich zum Zielpunkt bewegt und das Gebiet angreift.
--
-- Dabei werden die Soldaten alle erreichbaren Gebäude in Brand stecken. Ist
-- Das Zielgebiet eingemauert, können die Soldaten nicht angreifen und werden
-- sich zurückziehen.
--
-- @param _PlayerID   PlayerID des Angreifers
-- @param _SpawnPoint Skriptname des Entstehungspunktes
-- @param _Target     Skriptname des Ziels
-- @param _Radius     Aktionsradius um das Ziel
-- @param _Sword      Anzahl Schwertkämpfer (Battalione)
-- @param _Bow        Anzahl Bogenschützen (Battalione)
-- @param _Soldier    Typ der Soldaten
-- @param _Reuse      Freie Truppen wiederverwenden
-- @return Table mit Behavior
-- @within Reward
--
function Reward_AI_SpawnAndAttackArea(...)
    return b_Reward_AI_SpawnAndAttackArea:new(...);
end

b_Reward_AI_SpawnAndAttackArea = {
    Name = "Reward_AI_SpawnAndAttackArea",
    Description = {
        en = "Reward: Spawns AI troops and attacks everything within the specified area, except the players main buildings",
        de = "Lohn: Erstellt KI Truppen und greift ein angegebenes Gebiet an, aber nicht die Hauptgebauede eines Spielers",
    },
    Parameter = {
        { ParameterType.PlayerID, en = "AI Player", de = "KI Spieler" },
        { ParameterType.ScriptName, en = "Spawn point", de = "Erstellungsort" },
        { ParameterType.ScriptName, en = "Target", de = "Ziel" },
        { ParameterType.Number, en = "Radius", de = "Radius" },
        { ParameterType.Number, en = "Sword", de = "Schwert" },
        { ParameterType.Number, en = "Bow", de = "Bogen" },
        { ParameterType.Custom, en = "Soldier type", de = "Soldatentyp" },
        { ParameterType.Custom, en = "Reuse troops", de = "Verwende bestehende Truppen" },
    },
}

function b_Reward_AI_SpawnAndAttackArea:GetRewardTable()
    return { Reward.Custom,{self, self.CustomFunction} }
end

function b_Reward_AI_SpawnAndAttackArea:AddParameter(_Index, _Parameter)

    if (_Index == 0) then
        self.AIPlayerID = _Parameter * 1
    elseif (_Index == 1) then
        self.Spawnpoint = _Parameter
    elseif (_Index == 2) then
        self.TargetName = _Parameter
    elseif (_Index == 3) then
        self.Radius = _Parameter * 1
    elseif (_Index == 4) then
        self.NumSword = _Parameter * 1
    elseif (_Index == 5) then
        self.NumBow = _Parameter * 1
    elseif (_Index == 6) then
        if _Parameter == "Normal" or _Parameter == false then
            self.TroopType = false
        elseif _Parameter == "RedPrince" or _Parameter == true then
            self.TroopType = true
        elseif _Parameter == "Bandit" or _Parameter == 2 then
            self.TroopType = 2
        elseif _Parameter == "Cultist" or _Parameter == 3 then
            self.TroopType = 3
        else
            assert(false)
        end
    elseif (_Index == 7) then
        self.ReuseTroops = AcceptAlternativeBoolean(_Parameter)
    end
end

function b_Reward_AI_SpawnAndAttackArea:GetCustomData( _Index )
    local Data = {}
    if _Index == 6 then
        table.insert( Data, "Normal" )
        table.insert( Data, "RedPrince" )
        table.insert( Data, "Bandit" )
        if g_GameExtraNo >= 1 then
            table.insert( Data, "Cultist" )
        end
    elseif _Index == 7 then
        table.insert( Data, "false" )
        table.insert( Data, "true" )
    else
        assert( false )
    end
    return Data
end

function b_Reward_AI_SpawnAndAttackArea:CustomFunction(_Quest)
    if Logic.IsEntityAlive( self.TargetName ) and Logic.IsEntityAlive( self.Spawnpoint ) then
        local TargetID = GetID( self.TargetName )
        AIScript_SpawnAndRaidSettlement( self.AIPlayerID, TargetID, self.Spawnpoint, self.Radius, self.NumSword, self.NumBow, self.TroopType, self.ReuseTroops )
    end
end

function b_Reward_AI_SpawnAndAttackArea:DEBUG(_Quest)
    if self.AIPlayerID < 2 then
        dbg(_Quest.Identifier .. " " .. self.Name .. ": Player " .. self.AIPlayerID .. " is wrong")
        return true
    elseif Logic.IsEntityDestroyed(self.Spawnpoint) then
        dbg(_Quest.Identifier .. " " .. self.Name .. ": Entity " .. self.SpawnPoint .. " is missing")
        return true
    elseif Logic.IsEntityDestroyed(self.TargetName) then
        dbg(_Quest.Identifier .. " " .. self.Name .. ": Entity " .. self.TargetName .. " is missing")
        return true
    elseif self.Radius < 1 then
        dbg(_Quest.Identifier .. " " .. self.Name .. ": Radius is to small or negative")
        return true
    elseif self.NumSword < 0 then
        dbg(_Quest.Identifier .. " " .. self.Name .. ": Number of Swords is negative")
        return true
    elseif self.NumBow < 0 then
        dbg(_Quest.Identifier .. " " .. self.Name .. ": Number of Bows is negative")
        return true
    elseif self.NumBow + self.NumSword < 1 then
        dbg(_Quest.Identifier .. ": Error in " .. self.Name .. ": No Soldiers?")
        return true
    end
    return false;
end

Core:RegisterBehavior(b_Reward_AI_SpawnAndAttackArea);

-- -------------------------------------------------------------------------- --

---
-- Erstellt eine Armee, die das Zielgebiet verteidigt.
--
-- @param _PlayerID     PlayerID des Angreifers
-- @param _SpawnPoint   Skriptname des Entstehungspunktes
-- @param _Target       Skriptname des Ziels
-- @param _Radius       Bewachtes Gebiet
-- @param _Time         Dauer der Bewachung (-1 für unendlich)
-- @param _Sword        Anzahl Schwertkämpfer (Battalione)
-- @param _Bow          Anzahl Bogenschützen (Battalione)
-- @param _CaptureCarts Soldaten greifen Karren an
-- @param _Type         Typ der Soldaten
-- @param _Reuse        Freie Truppen wiederverwenden
-- @return Table mit Behavior
-- @within Reward
--
function Reward_AI_SpawnAndProtectArea(...)
    return b_Reward_AI_SpawnAndProtectArea:new(...);
end

b_Reward_AI_SpawnAndProtectArea = {
    Name = "Reward_AI_SpawnAndProtectArea",
    Description = {
        en = "Reward: Spawns AI troops and defends a specified area",
        de = "Lohn: Erstellt KI Truppen und verteidigt ein angegebenes Gebiet",
    },
    Parameter = {
        { ParameterType.PlayerID, en = "AI Player", de = "KI Spieler" },
        { ParameterType.ScriptName, en = "Spawn point", de = "Erstellungsort" },
        { ParameterType.ScriptName, en = "Target", de = "Ziel" },
        { ParameterType.Number, en = "Radius", de = "Radius" },
        { ParameterType.Number, en = "Time (-1 for infinite)", de = "Zeit (-1 fuer unendlich)" },
        { ParameterType.Number, en = "Sword", de = "Schwert" },
        { ParameterType.Number, en = "Bow", de = "Bogen" },
        { ParameterType.Custom, en = "Capture tradecarts", de = "Handelskarren angreifen" },
        { ParameterType.Custom, en = "Soldier type", de = "Soldatentyp" },
        { ParameterType.Custom, en = "Reuse troops", de = "Verwende bestehende Truppen" },
    },
}

function b_Reward_AI_SpawnAndProtectArea:GetRewardTable()
    return { Reward.Custom,{self, self.CustomFunction} }
end

function b_Reward_AI_SpawnAndProtectArea:AddParameter(_Index, _Parameter)

    if (_Index == 0) then
        self.AIPlayerID = _Parameter * 1
    elseif (_Index == 1) then
        self.Spawnpoint = _Parameter
    elseif (_Index == 2) then
        self.TargetName = _Parameter
    elseif (_Index == 3) then
        self.Radius = _Parameter * 1
    elseif (_Index == 4) then
        self.Time = _Parameter * 1
    elseif (_Index == 5) then
        self.NumSword = _Parameter * 1
    elseif (_Index == 6) then
        self.NumBow = _Parameter * 1
    elseif (_Index == 7) then
        self.CaptureTradeCarts = AcceptAlternativeBoolean(_Parameter)
    elseif (_Index == 8) then
        if _Parameter == "Normal" or _Parameter == true then
            self.TroopType = false
        elseif _Parameter == "RedPrince" or _Parameter == false then
            self.TroopType = true
        elseif _Parameter == "Bandit" or _Parameter == 2 then
            self.TroopType = 2
        elseif _Parameter == "Cultist" or _Parameter == 3 then
            self.TroopType = 3
        else
            assert(false)
        end
    elseif (_Index == 9) then
        self.ReuseTroops = AcceptAlternativeBoolean(_Parameter)
    end

end

function b_Reward_AI_SpawnAndProtectArea:GetCustomData( _Index )

    local Data = {}
    if _Index == 7 then
        table.insert( Data, "false" )
        table.insert( Data, "true" )
    elseif _Index == 8 then
        table.insert( Data, "Normal" )
        table.insert( Data, "RedPrince" )
        table.insert( Data, "Bandit" )
        if g_GameExtraNo >= 1 then
            table.insert( Data, "Cultist" )
        end

    elseif _Index == 9 then
        table.insert( Data, "false" )
        table.insert( Data, "true" )

    else
        assert( false )
    end

    return Data

end

function b_Reward_AI_SpawnAndProtectArea:CustomFunction(_Quest)

    if Logic.IsEntityAlive( self.TargetName ) and Logic.IsEntityAlive( self.Spawnpoint ) then
        local TargetID = GetID( self.TargetName )
        AIScript_SpawnAndProtectArea( self.AIPlayerID, TargetID, self.Spawnpoint, self.Radius, self.NumSword, self.NumBow, self.Time, self.TroopType, self.ReuseTroops, self.CaptureTradeCarts )
    end

end

function b_Reward_AI_SpawnAndProtectArea:DEBUG(_Quest)
    if self.AIPlayerID < 2 then
        dbg(_Quest.Identifier .. " " .. self.Name .. ": Player " .. self.AIPlayerID .. " is wrong")
        return true
    elseif Logic.IsEntityDestroyed(self.Spawnpoint) then
        dbg(_Quest.Identifier .. " " .. self.Name .. ": Entity " .. self.SpawnPoint .. " is missing")
        return true
    elseif Logic.IsEntityDestroyed(self.TargetName) then
        dbg(_Quest.Identifier .. " " .. self.Name .. ": Entity " .. self.TargetName .. " is missing")
        return true
    elseif self.Radius < 1 then
        dbg(_Quest.Identifier .. " " .. self.Name .. ": Radius is to small or negative")
        return true
    elseif self.Time < -1 then
        dbg(_Quest.Identifier .. " " .. self.Name .. ": Time is smaller than -1")
        return true
    elseif self.NumSword < 0 then
        dbg(_Quest.Identifier .. " " .. self.Name .. ": Number of Swords is negative")
        return true
    elseif self.NumBow < 0 then
        dbg(_Quest.Identifier .. " " .. self.Name .. ": Number of Bows is negative")
        return true
    elseif self.NumBow + self.NumSword < 1 then
        dbg(_Quest.Identifier .. " " .. self.Name .. ": No Soldiers?")
        return true
    end
    return false;
end

Core:RegisterBehavior(b_Reward_AI_SpawnAndProtectArea);

-- -------------------------------------------------------------------------- --

---
-- Ändert die Konfiguration eines KI-Spielers.
--
-- Optionen:
-- <ul>
-- <li>Courage/FEAR: Angstfaktor (0 bis ?)</li>
-- <li>Reconstruction/BARB: Wiederaufbau von Gebäuden (0 oder 1)</li>
-- <li>Build Order/BPMX: Buildorder ausführen (Nummer der Build Order)</li>
-- <li>Conquer Outposts/FCOP: Außenposten einnehmen (0 oder 1)</li>
-- <li>Mount Outposts/FMOP: Eigene Außenposten bemannen (0 oder 1)</li>
-- <li>max. Bowmen/FMBM: Maximale Anzahl an Bogenschützen (min. 1)</li>
-- <li>max. Swordmen/FMSM: Maximale Anzahl an Schwerkkämpfer (min. 1) </li>
-- <li>max. Rams/FMRA: Maximale Anzahl an Rammen (min. 1)</li>
-- <li>max. Catapults/FMCA: Maximale Anzahl an Katapulten (min. 1)</li>
-- <li>max. Ammunition Carts/FMAC: Maximale Anzahl an Minitionswagen (min. 1)</li>
-- <li>max. Siege Towers/FMST: Maximale Anzahl an Belagerungstürmen (min. 1)</li>
-- <li>max. Wall Catapults/FMBA: Maximale Anzahl an Mauerkatapulten (min. 1)</li>
-- </ul>
--
-- @param _PlayerID PlayerID des KI
-- @param _Fact     Konfigurationseintrag
-- @param _Value    Neuer Wert
-- @return Table mit Behavior
-- @within Reward
--
function Reward_AI_SetNumericalFact(...)
    return b_Reward_AI_SetNumericalFact:new(...);
end

b_Reward_AI_SetNumericalFact = {
    Name = "Reward_AI_SetNumericalFact",
    Description = {
        en = "Reward: Sets a numerical fact for the AI player",
        de = "Lohn: Setzt eine Verhaltensregel fuer den KI-Spieler. ",
    },
    Parameter = {
        { ParameterType.PlayerID, en = "AI Player",      de = "KI Spieler" },
        { ParameterType.Custom,   en = "Numerical Fact", de = "Verhaltensregel" },
        { ParameterType.Number,   en = "Value",          de = "Wert" },
    },
}

function b_Reward_AI_SetNumericalFact:GetRewardTable()
    return { Reward.Custom,{self, self.CustomFunction} }
end

function b_Reward_AI_SetNumericalFact:AddParameter(_Index, _Parameter)
    if (_Index == 0) then
        self.AIPlayerID = _Parameter * 1
    elseif (_Index == 1) then
        -- mapping of numerical facts
        local fact = {
            ["Courage"]               = "FEAR",
            ["Reconstruction"]        = "BARB",
            ["Build Order"]           = "BPMX",
            ["Conquer Outposts"]      = "FCOP",
            ["Mount Outposts"]        = "FMOP",
            ["max. Bowmen"]           = "FMBM",
            ["max. Swordmen"]         = "FMSM",
            ["max. Rams"]             = "FMRA",
            ["max. Catapults"]        = "FMCA",
            ["max. Ammunition Carts"] = "FMAC",
            ["max. Siege Towers"]     = "FMST",
            ["max. Wall Catapults"]   = "FMBA",
            ["FEAR"]                  = "FEAR", -- > 0
            ["BARB"]                  = "BARB", -- 1 or 0
            ["BPMX"]                  = "BPMX", -- >= 0
            ["FCOP"]                  = "FCOP", -- 1 or 0
            ["FMOP"]                  = "FMOP", -- 1 or 0
            ["FMBM"]                  = "FMBM", -- >= 0
            ["FMSM"]                  = "FMSM", -- >= 0
            ["FMRA"]                  = "FMRA", -- >= 0
            ["FMCA"]                  = "FMCA", -- >= 0
            ["FMAC"]                  = "FMAC", -- >= 0
            ["FMST"]                  = "FMST", -- >= 0
            ["FMBA"]                  = "FMBA", -- >= 0
        }
        self.NumericalFact = fact[_Parameter]
    elseif (_Index == 2) then
        self.Value = _Parameter * 1
    end
end

function b_Reward_AI_SetNumericalFact:CustomFunction(_Quest)
    AICore.SetNumericalFact( self.AIPlayerID, self.NumericalFact, self.Value )
end

function b_Reward_AI_SetNumericalFact:GetCustomData(_Index)
    if (_Index == 1) then
        return {
            "Courage",
            "Reconstruction",
            "Build Order",
            "Conquer Outposts",
            "Mount Outposts",
            "max. Bowmen",
            "max. Swordmen",
            "max. Rams",
            "max. Catapults",
            "max. Ammunition Carts",
            "max. Siege Towers",
            "max. Wall Catapults",
        };
    end
end

function b_Reward_AI_SetNumericalFact:DEBUG(_Quest)
    if Logic.GetStoreHouse(self.AIPlayerID) == 0 then
        dbg(_Quest.Identifier .. " " .. self.Name .. ": Player " .. self.AIPlayerID .. " is wrong or dead")
        return true
    elseif not self.NumericalFact then
        dbg(_Quest.Identifier .. " " .. self.Name .. ": invalid numerical fact choosen")
        return true
    else
        if self.NumericalFact == "BARB" or self.NumericalFact == "FCOP" or self.NumericalFact == "FMOP" then
            if self.Value ~= 0 and self.Value ~= 1 then
                dbg(_Quest.Identifier .. " " .. self.Name .. ": BARB, FCOP, FMOP: value must be 1 or 0")
                return true
            end
        elseif self.NumericalFact == "FEAR" then
            if self.Value <= 0 then
                dbg(_Quest.Identifier .. " " .. self.Name .. ": FEAR: value must greater than 0")
                return true
            end
        else
            if self.Value < 0 then
                dbg(_Quest.Identifier .. " " .. self.Name .. ": BPMX, FMBM, FMSM, FMRA, FMCA, FMAC, FMST, FMBA: value must greater than or equal 0")
                return true
            end
        end
    end
    return false
end

Core:RegisterBehavior(b_Reward_AI_SetNumericalFact);

-- -------------------------------------------------------------------------- --

---
-- Stellt den Aggressivitätswert des KI-Spielers nachträglich ein.
--
-- @param _PlayerID         PlayerID des KI-Spielers
-- @param _Aggressiveness   Aggressivitätswert (1 bis 3)
-- @return Table mit Behavior
-- @within Reward
--
function Reward_AI_Aggressiveness(...)
    return b_Reward_AI_Aggressiveness:new(...);
end

b_Reward_AI_Aggressiveness = {
    Name = "Reward_AI_Aggressiveness",
    Description = {
        en = "Reward: Sets the AI player's aggressiveness.",
        de = "Lohn: Setzt die Aggressivität des KI-Spielers fest.",
    },
    Parameter =
    {
        { ParameterType.PlayerID, en = "AI player", de = "KI-Spieler" },
        { ParameterType.Custom, en = "Aggressiveness (1-3)", de = "Aggressivität (1-3)" }
    }
};

function b_Reward_AI_Aggressiveness:GetRewardTable()
    return {Reward.Custom, {self, self.CustomFunction} };
end

function b_Reward_AI_Aggressiveness:AddParameter(_Index, _Parameter)
    if _Index == 0 then
        self.AIPlayer = _Parameter * 1;
    elseif _Index == 1 then
        self.Aggressiveness = tonumber(_Parameter);
    end
end

function b_Reward_AI_Aggressiveness:CustomFunction()
    local player = (PlayerAIs[self.AIPlayer]
        or AIPlayerTable[self.AIPlayer]
        or AIPlayer:new(self.AIPlayer, AIPlayerProfile_City));
    PlayerAIs[self.AIPlayer] = player;
    if self.Aggressiveness >= 2 then
        player.m_ProfileLoop = AIProfile_Skirmish;
        player.Skirmish = player.Skirmish or {};
        player.Skirmish.Claim_MinTime = SkirmishDefault.Claim_MinTime + (self.Aggressiveness - 2) * 390;
        player.Skirmish.Claim_MaxTime = player.Skirmish.Claim_MinTime * 2;
    else
        player.m_ProfileLoop = AIPlayerProfile_City;
    end
end

function b_Reward_AI_Aggressiveness:DEBUG(_Quest)
    if self.AIPlayer < 2 or Logic.GetStoreHouse(self.AIPlayer) == 0 then
        dbg(_Quest.Identifier .. ": Error in " .. self.Name .. ": Player " .. self.PlayerID .. " is wrong")
        return true
    end
end

function b_Reward_AI_Aggressiveness:GetCustomData(_Index)
    assert(_Index == 1, "Error in " .. self.Name .. ": GetCustomData: Index is invalid.");
    return { "1", "2", "3" };
end

Core:RegisterBehavior(b_Reward_AI_Aggressiveness)

-- -------------------------------------------------------------------------- --

---
-- Stellt den Feind des Skirmish-KI ein.
--
-- Der Skirmish-KI (maximale Aggressivität) kann nur einen Spieler als Feind
-- behandeln. Für gewöhnlich ist dies der menschliche Spieler.
--
-- @param _PlayerID      PlayerID des KI
-- @param _EnemyPlayerID PlayerID des Feindes
-- @return Table mit Behavior
-- @within Reward
--
function Reward_AI_SetEnemy(...)
    return b_Reward_AI_SetEnemy:new(...);
end

b_Reward_AI_SetEnemy = {
    Name = "Reward_AI_SetEnemy",
    Description = {
        en = "Reward:Sets the enemy of an AI player (the AI only handles one enemy properly).",
        de = "Lohn: Legt den Feind eines KI-Spielers fest (die KI behandelt nur einen Feind korrekt).",
    },
    Parameter =
    {
        { ParameterType.PlayerID, en = "AI player", de = "KI-Spieler" },
        { ParameterType.PlayerID, en = "Enemy", de = "Feind" }
    }
};

function b_Reward_AI_SetEnemy:GetRewardTable()

    return {Reward.Custom, {self, self.CustomFunction} };

end

function b_Reward_AI_SetEnemy:AddParameter(_Index, _Parameter)

    if _Index == 0 then
        self.AIPlayer = _Parameter * 1;
    elseif _Index == 1 then
        self.Enemy = _Parameter * 1;
    end

end

function b_Reward_AI_SetEnemy:CustomFunction()

    local player = PlayerAIs[self.AIPlayer];
    if player and player.Skirmish then
        player.Skirmish.Enemy = self.Enemy;
    end

end

function b_Reward_AI_SetEnemy:DEBUG(_Quest)

    if self.AIPlayer <= 1 or self.AIPlayer >= 8 or Logic.PlayerGetIsHumanFlag(self.AIPlayer) then
        dbg(_Quest.Identifier .. ": Error in " .. self.Name .. ": Player " .. self.AIPlayer .. " is wrong")
        return true
    end

end
Core:RegisterBehavior(b_Reward_AI_SetEnemy)

-- -------------------------------------------------------------------------- --

---
-- Ein Entity wird durch ein neues anderen Typs ersetzt.
--
-- Das neue Entity übernimmt Skriptname und Ausrichtung des alten Entity.
--
-- @param _Entity Skriptname oder ID des Entity
-- @param _Type   Neuer Typ des Entity
-- @param _Owner  Besitzer des Entity
-- @return Table mit Behavior
-- @within Reward
--
function Reward_ReplaceEntity(...)
    return b_Reward_ReplaceEntity:new(...);
end

b_Reward_ReplaceEntity = API.InstanceTable(b_Reprisal_ReplaceEntity);
b_Reward_ReplaceEntity.Name = "Reward_ReplaceEntity";
b_Reward_ReplaceEntity.Description.en = "Reward: Replaces an entity with a new one of a different type. The playerID can be changed too.";
b_Reward_ReplaceEntity.Description.de = "Lohn: Ersetzt eine Entity durch eine neue anderen Typs. Es kann auch die Spielerzugehörigkeit geändert werden.";
b_Reward_ReplaceEntity.GetReprisalTable = nil;

b_Reward_ReplaceEntity.GetRewardTable = function(self, _Quest)
    return { Reward.Custom,{self, self.CustomFunction} }
end

Core:RegisterBehavior(b_Reward_ReplaceEntity);

-- -------------------------------------------------------------------------- --

---
-- Setzt die Menge von Rohstoffen in einer Mine.
--
-- <b>Achtung:</b> Im Reich des Ostens darf die Mine nicht eingestürzt sein!
--
-- @param _ScriptName Skriptname der Mine
-- @param _Amount     Menge an Rohstoffen
-- @return Table mit Behavior
-- @within Reward
--
function Reward_SetResourceAmount(...)
    return b_Reward_SetResourceAmount:new(...);
end

b_Reward_SetResourceAmount = {
    Name = "Reward_SetResourceAmount",
    Description = {
        en = "Reward: Set the current and maximum amount of a resource doodad (the amount can also set to 0)",
        de = "Lohn: Setzt die aktuellen sowie maximalen Resourcen in einem Doodad (auch 0 ist möglich)",
    },
    Parameter = {
        { ParameterType.ScriptName, en = "Ressource", de = "Resource" },
        { ParameterType.Number, en = "Amount", de = "Menge" },
    },
}

function b_Reward_SetResourceAmount:GetRewardTable()
    return { Reward.Custom,{self, self.CustomFunction} }
end

function b_Reward_SetResourceAmount:AddParameter(_Index, _Parameter)

    if (_Index == 0) then
        self.ScriptName = _Parameter
    elseif (_Index == 1) then
        self.Amount = _Parameter * 1
    end

end

function b_Reward_SetResourceAmount:CustomFunction(_Quest)
    if Logic.IsEntityDestroyed( self.ScriptName ) then
        return false
    end
    local EntityID = GetID( self.ScriptName )
    if Logic.GetResourceDoodadGoodType( EntityID ) == 0 then
        return false
    end
    Logic.SetResourceDoodadGoodAmount( EntityID, self.Amount )
end

function b_Reward_SetResourceAmount:DEBUG(_Quest)
    if not IsExisting(self.ScriptName) then
        dbg(_Quest.Identifier .. " " .. self.Name .. ": resource entity does not exist!")
        return true
    elseif not type(self.Amount) == "number" or self.Amount < 0 then
        dbg(_Quest.Identifier .. " " .. self.Name .. ": resource amount can not be negative!")
        return true
    end
    return false;
end

Core:RegisterBehavior(b_Reward_SetResourceAmount);

-- -------------------------------------------------------------------------- --

---
-- Fügt dem Lagerhaus des Auftragnehmers eine Menge an Rohstoffen hinzu.
--
-- @param _Type   Rohstofftyp
-- @param _Amount Menge an Rohstoffen
-- @return Table mit Behavior
-- @within Reward
--
function Reward_Resources(...)
    return b_Reward_Resources:new(...);
end

b_Reward_Resources = {
    Name = "Reward_Resources",
    Description = {
        en = "Reward: The player receives a given amount of Goods in his store.",
        de = "Lohn: Legt der Partei die angegebenen Rohstoffe ins Lagerhaus.",
    },
    Parameter = {
        { ParameterType.RawGoods, en = "Type of good", de = "Resourcentyp" },
        { ParameterType.Number, en = "Amount of good", de = "Anzahl der Resource" },
    },
}

function b_Reward_Resources:AddParameter(_Index, _Parameter)
    if (_Index == 0) then
        self.GoodTypeName = _Parameter
    elseif (_Index == 1) then
        self.GoodAmount = _Parameter * 1
    end
end

function b_Reward_Resources:GetRewardTable()
    local GoodType = Logic.GetGoodTypeID(self.GoodTypeName)
    return { Reward.Resources, GoodType, self.GoodAmount }
end

Core:RegisterBehavior(b_Reward_Resources);

-- -------------------------------------------------------------------------- --

---
-- Entsendet einen Karren zum angegebenen Spieler.
--
-- Wenn der Spawnpoint ein Gebäude ist, wird der Wagen am Eingang erstellt.
-- Andernfalls kann der Spawnpoint gelöscht werden und der Wagen übernimmt
-- dann den Skriptnamen.
--
-- @param _ScriptName    Skriptname des Spawnpoint
-- @param _Owner         Empfänger der Lieferung
-- @param _Type          Typ des Wagens
-- @param _Good          Typ der Ware
-- @param _Amount        Menge an Waren
-- @param _OtherPlayer   Anderer Empfänger als Auftraggeber
-- @param _NoReservation Platzreservation auf dem Markt ignorieren (Sinnvoll?)
-- @param _Replace       Spawnpoint ersetzen
-- @return Table mit Behavior
-- @within Reward
--
function Reward_SendCart(...)
    return b_Reward_SendCart:new(...);
end

b_Reward_SendCart = {
    Name = "Reward_SendCart",
    Description = {
        en = "Reward: Sends a cart to a player. It spawns at a building or by replacing an entity. The cart can replace the entity if it's not a building.",
        de = "Lohn: Sendet einen Karren zu einem Spieler. Der Karren wird an einem Gebäude oder einer Entity erstellt. Er ersetzt die Entity, wenn diese kein Gebäude ist.",
    },
    Parameter = {
        { ParameterType.ScriptName, en = "Script entity", de = "Script Entity" },
        { ParameterType.PlayerID, en = "Owning player", de = "Besitzer" },
        { ParameterType.Custom, en = "Type name", de = "Typbezeichnung" },
        { ParameterType.Custom, en = "Good type", de = "Warentyp" },
        { ParameterType.Number, en = "Amount", de = "Anzahl" },
        { ParameterType.Custom, en = "Override target player", de = "Anderer Zielspieler" },
        { ParameterType.Custom, en = "Ignore reservations", de = "Ignoriere Reservierungen" },
        { ParameterType.Custom, en = "Replace entity", de = "Entity ersetzen" },
    },
}

function b_Reward_SendCart:GetRewardTable()
    return { Reward.Custom,{self, self.CustomFunction} }
end

function b_Reward_SendCart:AddParameter(_Index, _Parameter)
    if (_Index == 0) then
        self.ScriptNameEntity = _Parameter
    elseif (_Index == 1) then
        self.PlayerID = _Parameter * 1
    elseif (_Index == 2) then
        self.UnitKey = _Parameter
    elseif (_Index == 3) then
        self.GoodType = _Parameter
    elseif (_Index == 4) then
        self.GoodAmount = _Parameter * 1
    elseif (_Index == 5) then
        self.OverrideTargetPlayer = tonumber(_Parameter)
    elseif (_Index == 6) then
        self.IgnoreReservation = AcceptAlternativeBoolean(_Parameter)
    elseif (_Index == 7) then
        self.ReplaceEntity = AcceptAlternativeBoolean(_Parameter)
    end
end

function b_Reward_SendCart:CustomFunction(_Quest)

    if not IsExisting( self.ScriptNameEntity ) then
        return false;
    end

    local ID = SendCart(self.ScriptNameEntity,
                        self.PlayerID,
                        Goods[self.GoodType],
                        self.GoodAmount,
                        Entities[self.UnitKey],
                        self.IgnoreReservation    );

    if self.ReplaceEntity and Logic.IsBuilding(GetID(self.ScriptNameEntity)) == 0 then
        DestroyEntity(self.ScriptNameEntity);
        Logic.SetEntityName(ID, self.ScriptNameEntity);
    end
    if self.OverrideTargetPlayer then
        Logic.ResourceMerchant_OverrideTargetPlayerID(ID,self.OverrideTargetPlayer);
    end
end

function b_Reward_SendCart:GetCustomData( _Index )
    local Data = {}
    if _Index == 2 then
        Data = { "U_ResourceMerchant", "U_Medicus", "U_Marketer", "U_ThiefCart", "U_GoldCart", "U_Noblemen_Cart", "U_RegaliaCart" }
    elseif _Index == 3 then
        for k, v in pairs( Goods ) do
            if string.find( k, "^G_" ) then
                table.insert( Data, k )
            end
        end
        table.sort( Data )
    elseif _Index == 5 then
        table.insert( Data, "---" )
        for i = 1, 8 do
            table.insert( Data, i )
        end
    elseif _Index == 6 then
        table.insert( Data, "false" )
        table.insert( Data, "true" )
    elseif _Index == 7 then
        table.insert( Data, "false" )
        table.insert( Data, "true" )
    end
    return Data
end

function b_Reward_SendCart:DEBUG(_Quest)
    if not IsExisting(self.ScriptNameEntity) then
        dbg(_Quest.Identifier .. " " .. self.Name .. ": spawnpoint does not exist!");
        return true;
    elseif not tonumber(self.PlayerID) or self.PlayerID < 1 or self.PlayerID > 8 then
        dbg(_Quest.Identifier .. " " .. self.Name .. ": got a invalid playerID!");
        return true;
    elseif not Entities[self.UnitKey] then
        dbg(_Quest.Identifier .. " " .. self.Name .. ": entity type '"..self.UnitKey.."' is invalid!");
        return true;
    elseif not Goods[self.GoodType] then
        dbg(_Quest.Identifier .. " " .. self.Name .. ": good type '"..self.GoodType.."' is invalid!");
        return true;
    elseif not tonumber(self.GoodAmount) or self.GoodAmount < 1 then
        dbg(_Quest.Identifier .. " " .. self.Name .. ": good amount can not be below 1!");
        return true;
    elseif tonumber(self.OverrideTargetPlayer) and (self.OverrideTargetPlayer < 1 or self.OverrideTargetPlayer > 8) then
        dbg(_Quest.Identifier .. " " .. self.Name .. ": overwrite target player with invalid playerID!");
        return true;
    end
    return false;
end

Core:RegisterBehavior(b_Reward_SendCart);

-- -------------------------------------------------------------------------- --

---
-- Gibt dem Auftragnehmer eine Menge an Einheiten.
--
-- Die Einheiten erscheinen an der Burg. Hat der Spieler keine Burg, dann
-- erscheinen sie vorm Lagerhaus.
--
-- @param _Type   Typ der Einheit
-- @param _Amount Menge an Einheiten
-- @return Table mit Behavior
-- @within Reward
--
function Reward_Units(...)
    return b_Reward_Units:new(...)
end

b_Reward_Units = {
    Name = "Reward_Units",
    Description = {
        en = "Reward: Units",
        de = "Lohn: Einheiten",
    },
    Parameter = {
        { ParameterType.Entity, en = "Type name", de = "Typbezeichnung" },
        { ParameterType.Number, en = "Amount", de = "Anzahl" },
    },
}

function b_Reward_Units:AddParameter(_Index, _Parameter)
    if (_Index == 0) then
        self.EntityName = _Parameter
    elseif (_Index == 1) then
        self.Amount = _Parameter * 1
    end
end

function b_Reward_Units:GetRewardTable()
    return { Reward.Units, assert( Entities[self.EntityName] ), self.Amount }
end

Core:RegisterBehavior(b_Reward_Units);

-- -------------------------------------------------------------------------- --

---
-- Startet einen Quest neu.
--
-- @param _QuestName Name des Quest
-- @return Table mit Behavior
-- @within Reward
--
function Reward_QuestRestart(...)
    return b_Reward_QuestRestart(...)
end

b_Reward_QuestRestart = API.InstanceTable(b_Reprisal_QuestRestart);
b_Reward_QuestRestart.Name = "Reward_ReplaceEntity";
b_Reward_QuestRestart.Description.en = "Reward: Restarts a (completed) quest so it can be triggered and completed again.";
b_Reward_QuestRestart.Description.de = "Lohn: Startet eine (beendete) Quest neu, damit diese neu ausgelöst und beendet werden kann.";
b_Reward_QuestRestart.GetReprisalTable = nil;

b_Reward_QuestRestart.GetRewardTable = function(self, _Quest)
    return { Reward.Custom,{self, self.CustomFunction} }
end

Core:RegisterBehavior(b_Reward_QuestRestart);

-- -------------------------------------------------------------------------- --

---
-- Lässt einen Quest fehlschlagen.
--
-- @param _QuestName Name des Quest
-- @return Table mit Behavior
-- @within Reward
--
function Reward_QuestFailure(...)
    return b_Reward_QuestFailure(...)
end

b_Reward_QuestFailure = API.InstanceTable(b_Reprisal_ReplaceEntity);
b_Reward_QuestFailure.Name = "Reward_QuestFailure";
b_Reward_QuestFailure.Description.en = "Reward: Lets another active quest fail.";
b_Reward_QuestFailure.Description.de = "Lohn: Lässt eine andere aktive Quest fehlschlagen.";
b_Reward_QuestFailure.GetReprisalTable = nil;

b_Reward_QuestFailure.GetRewardTable = function(self, _Quest)
    return { Reward.Custom,{self, self.CustomFunction} }
end

Core:RegisterBehavior(b_Reward_QuestFailure);

-- -------------------------------------------------------------------------- --

---
-- Wertet einen Quest als erfolgreich.
--
-- @param _QuestName Name des Quest
-- @return Table mit Behavior
-- @within Reward
--
function Reward_QuestSuccess(...)
    return b_Reward_QuestSuccess(...)
end

b_Reward_QuestSuccess = API.InstanceTable(b_Reprisal_QuestSuccess);
b_Reward_QuestSuccess.Name = "Reward_QuestSuccess";
b_Reward_QuestSuccess.Description.en = "Reward: Completes another active quest successfully.";
b_Reward_QuestSuccess.Description.de = "Lohn: Beendet eine andere aktive Quest erfolgreich.";
b_Reward_QuestSuccess.GetReprisalTable = nil;

b_Reward_QuestSuccess.GetRewardTable = function(self, _Quest)
    return { Reward.Custom,{self, self.CustomFunction} }
end

Core:RegisterBehavior(b_Reward_QuestSuccess);

-- -------------------------------------------------------------------------- --

---
-- Triggert einen Quest.
--
-- @param _QuestName Name des Quest
-- @return Table mit Behavior
-- @within Reward
--
function Reward_QuestActivate(...)
    return b_Reward_QuestActivate(...)
end

b_Reward_QuestActivate = API.InstanceTable(b_Reprisal_QuestActivate);
b_Reward_QuestActivate.Name = "Reward_QuestActivate";
b_Reward_QuestActivate.Description.en = "Reward: Activates another quest that is not triggered yet.";
b_Reward_QuestActivate.Description.de = "Lohn: Aktiviert eine andere Quest die noch nicht ausgelöst wurde.";
b_Reward_QuestActivate.GetReprisalTable = nil;

b_Reward_QuestActivate.GetRewardTable = function(self, _Quest)
    return {Reward.Custom, {self, self.CustomFunction} }
end

Core:RegisterBehavior(b_Reward_QuestActivate)

-- -------------------------------------------------------------------------- --

---
-- Unterbricht einen Quest.
--
-- @param _QuestName Name des Quest
-- @return Table mit Behavior
-- @within Reward
--
function Reward_QuestInterrupt(...)
    return b_Reward_QuestInterrupt(...)
end

b_Reward_QuestInterrupt = API.InstanceTable(b_Reprisal_QuestInterrupt);
b_Reward_QuestInterrupt.Name = "Reward_QuestInterrupt";
b_Reward_QuestInterrupt.Description.en = "Reward: Interrupts another active quest without success or failure.";
b_Reward_QuestInterrupt.Description.de = "Lohn: Beendet eine andere aktive Quest ohne Erfolg oder Misserfolg.";
b_Reward_QuestInterrupt.GetReprisalTable = nil;

b_Reward_QuestInterrupt.GetRewardTable = function(self, _Quest)
    return { Reward.Custom,{self, self.CustomFunction} }
end

Core:RegisterBehavior(b_Reward_QuestInterrupt);

-- -------------------------------------------------------------------------- --

---
-- Unterbricht einen Quest, selbst wenn dieser noch nicht ausgelöst wurde.
--
-- @param _QuestName   Name des Quest
-- @param _EndetQuests Bereits beendete unterbrechen
-- @return Table mit Behavior
-- @within Reward
--
function Reward_QuestForceInterrupt(...)
    return b_Reward_QuestForceInterrupt(...)
end

b_Reward_QuestForceInterrupt = API.InstanceTable(b_Reprisal_QuestForceInterrupt);
b_Reward_QuestForceInterrupt.Name = "Reward_QuestForceInterrupt";
b_Reward_QuestForceInterrupt.Description.en = "Reward: Interrupts another quest (even when it isn't active yet) without success or failure.";
b_Reward_QuestForceInterrupt.Description.de = "Lohn: Beendet eine andere Quest, auch wenn diese noch nicht aktiv ist ohne Erfolg oder Misserfolg.";
b_Reward_QuestForceInterrupt.GetReprisalTable = nil;

b_Reward_QuestForceInterrupt.GetRewardTable = function(self, _Quest)
    return { Reward.Custom,{self, self.CustomFunction} }
end

Core:RegisterBehavior(b_Reward_QuestForceInterrupt);

-- -------------------------------------------------------------------------- --

---
-- Führt eine Funktion im Skript als Reward aus.
--
-- @param _FunctionName Name der Funktion
-- @return Table mit Behavior
-- @within Reward
--
function Reward_MapScriptFunction(...)
    return b_Reward_MapScriptFunction:new(...);
end

b_Reward_MapScriptFunction = API.InstanceTable(b_Reprisal_MapScriptFunction);
b_Reward_MapScriptFunction.Name = "Reprisal_MapScriptFunction";
b_Reward_MapScriptFunction.Description.en = "Reward: Calls a function within the global map script if the quest has failed.";
b_Reward_MapScriptFunction.Description.de = "Lohn: Ruft eine Funktion im globalen Kartenskript auf, wenn die Quest fehlschlägt.";
b_Reward_MapScriptFunction.GetReprisalTable = nil;

b_Reward_MapScriptFunction.GetRewardTable = function(self, _Quest)
    return {Reward.Custom, {self, self.CustomFunction}};
end

Core:RegisterBehavior(b_Reward_MapScriptFunction);

-- -------------------------------------------------------------------------- --

---
-- Ändert den Wert einer benutzerdefinierten Variable.
--
-- Benutzerdefinierte Variablen können ausschließlich Zahlen sein.
--
---- <p>Operatoren</p>
-- <ul>
-- <li>= - Variablenwert wird auf den Wert gesetzt</li>
-- <li>- - Variablenwert mit Wert Subtrahieren</li>
-- <li>+ - Variablenwert mit Wert addieren</li>
-- <li>* - Variablenwert mit Wert multiplizieren</li>
-- <li>/ - Variablenwert mit Wert dividieren</li>
-- <li>^ - Variablenwert mit Wert potenzieren</li>
-- </ul>
--
-- @param _Name     Name der Variable
-- @param _Operator Rechen- oder Zuweisungsoperator
-- @param _Value    Wert oder andere Custom Variable
-- @return Table mit Behavior
-- @within Reward
--
function Reward_CustomVariables(...)
    return b_Reward_CustomVariables:new(...);
end

b_Reward_CustomVariables = API.InstanceTable(b_Reprisal_CustomVariables);
b_Reward_CustomVariables.Name = "Reward_CustomVariables";
b_Reward_CustomVariables.Description.en = "Reward: Executes a mathematical operation with this variable. The other operand can be a number or another custom variable.";
b_Reward_CustomVariables.Description.de = "Lohn: Fuehrt eine mathematische Operation mit der Variable aus. Der andere Operand kann eine Zahl oder eine Custom-Varible sein.";
b_Reward_CustomVariables.GetReprisalTable = nil;

b_Reward_CustomVariables.GetRewardTable = function(self, _Quest)
    return { Reward.Custom, {self, self.CustomFunction} };
end

Core:RegisterBehavior(b_Reward_CustomVariables)

-- -------------------------------------------------------------------------- --

---
-- Erlaubt oder verbietet einem Spieler eine Technologie.
--
-- @param _PlayerID   ID des Spielers
-- @param _Lock       Sperren/Entsperren
-- @param _Technology Name der Technologie
-- @return Table mit Behavior
-- @within Reward
--
function Reward_Technology(...)
    return b_Reward_Technology:new(...);
end

b_Reward_Technology = API.InstanceTable(b_Reprisal_Technology);
b_Reward_Technology.Name = "Reward_Technology";
b_Reward_Technology.Description.en = "Reward: Locks or unlocks a technology for the given player.";
b_Reward_Technology.Description.de = "Lohn: Sperrt oder erlaubt eine Technolgie fuer den angegebenen Player.";
b_Reward_Technology.GetReprisalTable = nil;

b_Reward_Technology.GetRewardTable = function(self, _Quest)
    return { Reward.Custom, {self, self.CustomFunction} }
end

Core:RegisterBehavior(b_Reward_Technology);

---
-- Gibt dem Auftragnehmer eine Anzahl an Prestigepunkten.
--
-- @param _Amount Menge an Prestige
-- @return Table mit Behavior
-- @within Reward
--
function Reward_PrestigePoints(...)
    return b_Reward_PrestigePoints:mew(...);
end

b_Reward_PrestigePoints  = {
    Name = "Reward_PrestigePoints",
    Description = {
        en = "Reward: Prestige",
        de = "Lohn: Prestige",
    },
    Parameter = {
        { ParameterType.Number, en = "Points", de = "Punkte" },
    },
}

function b_Reward_PrestigePoints :AddParameter(_Index, _Parameter)
    if (_Index == 0) then
        self.Points = _Parameter
    end
end

function b_Reward_PrestigePoints :GetRewardTable()
    return { Reward.PrestigePoints, self.Points }
end

Core:RegisterBehavior(b_Reward_PrestigePoints);

-- -------------------------------------------------------------------------- --

---
-- Besetzt einen Außenposten mit Soldaten.
--
-- @param _ScriptName Skriptname des Außenposten
-- @param _Type       Soldatentyp
-- @return Table mit Behavior
-- @within Reward
--
function Reward_AI_MountOutpost(...)
    return b_Reward_AI_MountOutpost:new(...);
end

b_Reward_AI_MountOutpost = {
    Name = "Reward_AI_MountOutpost",
    Description = {
        en = "Reward: Places a troop of soldiers on a named outpost.",
        de = "Lohn: Platziert einen Trupp Soldaten auf einem Aussenposten der KI.",
    },
    Parameter = {
        { ParameterType.ScriptName, en = "Script name", de = "Skriptname" },
        { ParameterType.Custom,      en = "Soldiers type", de = "Soldatentyp" },
    },
}

function b_Reward_AI_MountOutpost:GetRewardTable()
    return { Reward.Custom,{self, self.CustomFunction} }
end

function b_Reward_AI_MountOutpost:AddParameter(_Index, _Parameter)
    if _Index == 0 then
        self.Scriptname = _Parameter
    else
        self.SoldiersType = _Parameter
    end
end

function b_Reward_AI_MountOutpost:CustomFunction(_Quest)
    local outpostID = assert(
        not Logic.IsEntityDestroyed(self.Scriptname) and GetID(self.Scriptname),
       _Quest.Identifier .. ": Error in " .. self.Name .. ": CustomFunction: Outpost is invalid"
    )
    local AIPlayerID = Logic.EntityGetPlayer(outpostID)
    local ax, ay = Logic.GetBuildingApproachPosition(outpostID)
    local TroopID = Logic.CreateBattalionOnUnblockedLand(Entities[self.SoldiersType], ax, ay, 0, AIPlayerID, 0)
    AICore.HideEntityFromAI(AIPlayerID, TroopID, true)
    Logic.CommandEntityToMountBuilding(TroopID, outpostID)
end

function b_Reward_AI_MountOutpost:GetCustomData(_Index)
    if _Index == 1 then
        local Data = {}
        for k,v in pairs(Entities) do
            if string.find(k, "U_MilitaryBandit") or string.find(k, "U_MilitarySword") or string.find(k, "U_MilitaryBow") then
                Data[#Data+1] = k
            end
        end
        return Data
    end
end

function b_Reward_AI_MountOutpost:DEBUG(_Quest)
    if Logic.IsEntityDestroyed(self.Scriptname) then
        dbg(_Quest.Identifier .. " " .. self.Name .. ": Outpost " .. self.Scriptname .. " is missing")
        return true
    end
end

Core:RegisterBehavior(b_Reward_AI_MountOutpost)

-- -------------------------------------------------------------------------- --

---
-- Startet einen Quest neu und lößt ihn sofort aus.
--
-- @param _QuestName Name des Quest
-- @return Table mit Behavior
-- @within Reward
--
function Reward_QuestRestartForceActive(...)
    return b_Reward_QuestRestartForceActive:new(...);
end

b_Reward_QuestRestartForceActive = {
    Name = "Reward_QuestRestartForceActive",
    Description = {
        en = "Reward: Restarts a (completed) quest and triggers it immediately.",
        de = "Lohn: Startet eine (beendete) Quest neu und triggert sie sofort.",
    },
    Parameter = {
        { ParameterType.QuestName, en = "Quest name", de = "Questname" },
    },
}

function b_Reward_QuestRestartForceActive:GetRewardTable()
    return { Reward.Custom,{self, self.CustomFunction} }
end

function b_Reward_QuestRestartForceActive:AddParameter(_Index, _Parameter)
    assert(_Index == 0, "Error in " .. self.Name .. ": AddParameter: Index is invalid.")
    self.QuestName = _Parameter
end

function b_Reward_QuestRestartForceActive:CustomFunction(_Quest)
    local QuestID, Quest = self:ResetQuest(_Quest);
    if QuestID then
        Quest:SetMsgKeyOverride()
        Quest:SetIconOverride()
        Quest:Trigger()
    end
end

b_Reward_QuestRestartForceActive.ResetQuest = b_Reward_QuestRestart.CustomFunction;
function b_Reward_QuestRestartForceActive:DEBUG(_Quest)
    if not Quests[GetQuestID(self.QuestName)] then
        dbg(_Quest.Identifier .. ": Error in " .. self.Name .. ": Quest: "..  self.QuestName .. " does not exist")
        return true
    end
end

Core:RegisterBehavior(b_Reward_QuestRestartForceActive)

-- -------------------------------------------------------------------------- --

---
-- Baut das angegebene Gabäude um eine Stufe aus.
--
-- <b>Achtung:</b> Ein Gebäude muss erst fertig ausgebaut sein, bevor ein
-- weiterer Ausbau begonnen werden kann!
--
-- @param _ScriptName Skriptname des Gebäudes
-- @return Table mit Behavior
-- @within Reward
--
function Reward_UpgradeBuilding(...)
    return b_Reward_UpgradeBuilding:new(...);
end

b_Reward_UpgradeBuilding = {
    Name = "Reward_UpgradeBuilding",
    Description = {
        en = "Reward: Upgrades a building",
        de = "Lohn: Baut ein Gebäude aus"
    },
    Parameter =    {
        { ParameterType.ScriptName, en = "Building", de = "Gebäude" }
    }
};

function b_Reward_UpgradeBuilding:GetRewardTable()

    return {Reward.Custom, {self, self.CustomFunction}};

end

function b_Reward_UpgradeBuilding:AddParameter(_Index, _Parameter)

    if _Index == 0 then
        self.Building = _Parameter;
    end

end

function b_Reward_UpgradeBuilding:CustomFunction(_Quest)

    local building = GetID(self.Building);
    if building ~= 0
    and Logic.IsBuilding(building) == 1
    and Logic.IsBuildingUpgradable(building, true)
    and Logic.IsBuildingUpgradable(building, false)
    then
        Logic.UpgradeBuilding(building);
    end

end

function b_Reward_UpgradeBuilding:DEBUG(_Quest)

    local building = GetID(self.Building);
    if not (building ~= 0
            and Logic.IsBuilding(building) == 1
            and Logic.IsBuildingUpgradable(building, true)
            and Logic.IsBuildingUpgradable(building, false) )
    then
        dbg(_Quest.Identifier .. " " .. self.Name .. ": Building is wrong")
        return true
    end

end

Core:RegisterBehavior(b_Reward_UpgradeBuilding)

-- -------------------------------------------------------------------------- --



-- -------------------------------------------------------------------------- --
-- Trigger                                                                    --
-- -------------------------------------------------------------------------- --

---
-- Starte den Quest, wenn ein anderer Spieler entdeckt wurde.
--
-- Ein Spieler ist dann entdeckt, wenn sein Heimatterritorium aufgedeckt wird.
--
-- @param _PlayerID Zu entdeckender Spieler
-- @return Table mit Behavior
-- @within Trigger
--
function Trigger_PlayerDiscovered(...)
    return b_Trigger_PlayerDiscovered:new(...);
end

b_Trigger_PlayerDiscovered = {
    Name = "Trigger_PlayerDiscovered",
    Description = {
        en = "Trigger: if a given player has been discovered",
        de = "Auslöser: wenn ein angegebener Spieler entdeckt wurde",
    },
    Parameter = {
        { ParameterType.PlayerID, en = "Player", de = "Spieler" },
    },
}

function b_Trigger_PlayerDiscovered:GetTriggerTable(_Quest)
    return {Triggers.PlayerDiscovered, self.PlayerID}
end

function b_Trigger_PlayerDiscovered:AddParameter(_Index, _Parameter)
    if (_Index == 0) then
        self.PlayerID = _Parameter * 1;
    end
end

Core:RegisterBehavior(b_Trigger_PlayerDiscovered);

-- -------------------------------------------------------------------------- --

---
-- Starte den Quest, wenn zwischen dem Empfänger und der angegebenen Partei
-- der geforderte Diplomatiestatus herrscht.
--
-- @param _PlayerID ID der Partei
-- @param _State    Diplomatie-Status
-- @return Table mit Behavior
-- @within Trigger
--
function Trigger_OnDiplomacy(...)
    return b_Trigger_OnDiplomacy:new(...);
end

b_Trigger_OnDiplomacy = {
    Name = "Trigger_OnDiplomacy",
    Description = {
        en = "Trigger: if diplomatic relations have been established with a player",
        de = "Auslöser: wenn ein angegebener Diplomatie-Status mit einem Spieler erreicht wurde.",
    },
    Parameter = {
        { ParameterType.PlayerID, en = "Player", de = "Spieler" },
        { ParameterType.DiplomacyState, en = "Relation", de = "Beziehung" },
    },
}

function b_Trigger_OnDiplomacy:GetTriggerTable(_Quest)
    return {Triggers.Diplomacy, self.PlayerID, assert( DiplomacyStates[self.DiplState] ) }
end

function b_Trigger_OnDiplomacy:AddParameter(_Index, _Parameter)
    if (_Index == 0) then
        self.PlayerID = _Parameter * 1
    elseif (_Index == 1) then
        self.DiplState = _Parameter
    end
end

Core:RegisterBehavior(b_Trigger_OnDiplomacy);

-- -------------------------------------------------------------------------- --

---
-- Starte den Quest, sobald ein Bedürfnis nicht erfüllt wird.
--
-- @param _PlayerID ID des Spielers
-- @param _Need     Bedürfnis
-- @param _Amount   Menge an skreikenden Siedlern
-- @return Table mit Behavior
-- @within Trigger
-- 
function Trigger_OnNeedUnsatisfied(...)
    return b_Trigger_OnNeedUnsatisfied:new(...);
end

b_Trigger_OnNeedUnsatisfied = {
    Name = "Trigger_OnNeedUnsatisfied",
    Description = {
        en = "Trigger: if a specified need is unsatisfied",
        de = "Auslöser: wenn ein bestimmtes Beduerfnis nicht befriedigt ist.",
    },
    Parameter = {
        { ParameterType.PlayerID, en = "Player", de = "Spieler" },
        { ParameterType.Need, en = "Need", de = "Beduerfnis" },
        { ParameterType.Number, en = "Workers on strike", de = "Streikende Arbeiter" },
    },
}

function b_Trigger_OnNeedUnsatisfied:GetTriggerTable()
    return { Triggers.Custom2,{self, self.CustomFunction} }
end

function b_Trigger_OnNeedUnsatisfied:AddParameter(_Index, _Parameter)
    if (_Index == 0) then
        self.PlayerID = _Parameter * 1
    elseif (_Index == 1) then
        self.Need = _Parameter
    elseif (_Index == 2) then
        self.WorkersOnStrike = _Parameter * 1
    end
end

function b_Trigger_OnNeedUnsatisfied:CustomFunction(_Quest)
    return Logic.GetNumberOfStrikingWorkersPerNeed( self.PlayerID, Needs[self.Need] ) >= self.WorkersOnStrike
end

function b_Trigger_OnNeedUnsatisfied:DEBUG(_Quest)
    if Logic.GetStoreHouse(self.PlayerID) == 0 then
        dbg(_Quest.Identifier .. " " .. self.Name .. ": " .. self.PlayerID .. " does not exist.")
        return true
    elseif not Needs[self.Need] then
        dbg(_Quest.Identifier .. " " .. self.Name .. ": " .. self.Need .. " does not exist.")
        return true
    elseif self.WorkersOnStrike < 0 then
        dbg(_Quest.Identifier .. " " .. self.Name .. ": WorkersOnStrike value negative")
        return true
    end
    return false;
end

Core:RegisterBehavior(b_Trigger_OnNeedUnsatisfied);

-- -------------------------------------------------------------------------- --

---
-- Startet den Quest, wenn die angegebene Mine erschöpft ist.
-- 
-- @param _ScriptName Skriptname der Mine
-- @return Table mit Behavior
-- @within Trigger
--
function Trigger_OnResourceDepleted(...)
    return b_Trigger_OnResourceDepleted:new(...);
end

b_Trigger_OnResourceDepleted = {
    Name = "Trigger_OnResourceDepleted",
    Description = {
        en = "Trigger: if a resource is (temporarily) depleted",
        de = "Auslöser: wenn eine Ressource (zeitweilig) verbraucht ist",
    },
    Parameter = {
        { ParameterType.ScriptName, en = "Script name", de = "Skriptname" },
    },
}

function b_Trigger_OnResourceDepleted:GetTriggerTable()
    return { Triggers.Custom2,{self, self.CustomFunction} }
end

function b_Trigger_OnResourceDepleted:AddParameter(_Index, _Parameter)
    if (_Index == 0) then
        self.ScriptName = _Parameter
    end
end

function b_Trigger_OnResourceDepleted:CustomFunction(_Quest)
    local ID = GetID(self.ScriptName)
    return not ID or ID == 0 or Logic.GetResourceDoodadGoodType(ID) == 0 or Logic.GetResourceDoodadGoodAmount(ID) == 0
end

Core:RegisterBehavior(b_Trigger_OnResourceDepleted);

-- -------------------------------------------------------------------------- --

---
-- Startet den Quest, sobald der angegebene Spieler eine Menge an Rohstoffen
-- im Lagerhaus hat.
--
-- @param  _PlayerID ID des Spielers
-- @param  _Type     Typ des Rohstoffes
-- @param _Amount    Menge an Rohstoffen
-- @return Table mit Behavior
-- @within Trigger
--
function Trigger_OnAmountOfGoods(...)
    return b_Trigger_OnAmountOfGoods:new(...);
end

b_Trigger_OnAmountOfGoods = {
    Name = "Trigger_OnAmountOfGoods",
    Description = {
        en = "Trigger: if the player has gathered a given amount of resources in his storehouse",
        de = "Auslöser: wenn der Spieler eine bestimmte Menge einer Ressource in seinem Lagerhaus hat",
    },
    Parameter = {
        { ParameterType.PlayerID, en = "Player", de = "Spieler" },
        { ParameterType.RawGoods, en = "Type of good", de = "Resourcentyp" },
        { ParameterType.Number, en = "Amount of good", de = "Anzahl der Resource" },
    },
}

function b_Trigger_OnAmountOfGoods:GetTriggerTable()
    return { Triggers.Custom2,{self, self.CustomFunction} }
end

function b_Trigger_OnAmountOfGoods:AddParameter(_Index, _Parameter)
    if (_Index == 0) then
        self.PlayerID = _Parameter * 1
    elseif (_Index == 1) then
        self.GoodTypeName = _Parameter
    elseif (_Index == 2) then
        self.GoodAmount = _Parameter * 1
    end
end

function b_Trigger_OnAmountOfGoods:CustomFunction(_Quest)
    local StoreHouseID = Logic.GetStoreHouse(self.PlayerID)
    if (StoreHouseID == 0) then
        return false
    end
    local GoodType = Logic.GetGoodTypeID(self.GoodTypeName)
    local GoodAmount = Logic.GetAmountOnOutStockByGoodType(StoreHouseID, GoodType)
    if (GoodAmount >= self.GoodAmount)then
        return true
    end
    return false
end

function b_Trigger_OnAmountOfGoods:DEBUG(_Quest)
    if Logic.GetStoreHouse(self.PlayerID) == 0 then
        dbg(_Quest.Identifier .. " " .. self.Name .. ": " .. self.PlayerID .. " does not exist.")
        return true
    elseif not Goods[self.GoodTypeName] then
        dbg(_Quest.Identifier .. " " .. self.Name .. ": Good type is wrong.")
        return true
    elseif self.GoodAmount < 0 then
        dbg(_Quest.Identifier .. " " .. self.Name .. ": Good amount is negative.")
        return true
    end
    return false;
end

Core:RegisterBehavior(b_Trigger_OnAmountOfGoods);

-- -------------------------------------------------------------------------- --

---
-- Startet den Quest, sobald ein anderer aktiv ist.
--
-- @param _QuestName Name des Quest
-- @param _Time      Wartezeit
-- return Table mit Behavior
-- @within Trigger
--
function Trigger_OnQuestActive(...)
    return b_Trigger_OnQuestActive(...);
end

b_Trigger_OnQuestActive = {
    Name = "Trigger_OnQuestActive",
    Description = {
        en = "Trigger: if a given quest has been activated. Waiting time optional",
        de = "Auslöser: wenn eine angegebene Quest aktiviert wurde. Optional mit Wartezeit",
    },
    Parameter = {
        { ParameterType.QuestName, en = "Quest name", de = "Questname" },
        { ParameterType.Number,     en = "Waiting time", de = "Wartezeit"},
    },
}

function b_Trigger_OnQuestActive:GetTriggerTable(_Quest)
    return { Triggers.Custom2,{self, self.CustomFunction} }
end

function b_Trigger_OnQuestActive:AddParameter(_Index, _Parameter)
    if (_Index == 0) then
        self.QuestName = _Parameter
    elseif (_Index == 1) then
        self.WaitTime = (_Parameter ~= nil and tonumber(_Parameter)) or 0
    end
end

function b_Trigger_OnQuestActive:CustomFunction(_Quest)
    local QuestID = GetQuestID(self.QuestName)
    if QuestID ~= nil then
        assert(type(QuestID) == "number");

        if (Quests[QuestID].State == QuestState.Active) then
            self.WasActivated = self.WasActivated or true;
        end
        if self.WasActivated then
            if self.WaitTime and self.WaitTime > 0 then
                self.WaitTimeTimer = self.WaitTimeTimer or Logic.GetTime();
                if Logic.GetTime() >= self.WaitTimeTimer + self.WaitTime then
                    return true;
                end
            else
                return true;
            end
        end
    end
    return false;
end

function b_Trigger_OnQuestActive:DEBUG(_Quest)
    if type(self.QuestName) ~= "string" then
        dbg("".._Quest.Identifier.." "..self.Name..": invalid quest name!");
        return true;
    elseif type(self.WaitTime) ~= "number" then
        dbg("".._Quest.Identifier.." "..self.Name..": waitTime must be a number!");
        return true;
    end
    return false;
end

function b_Trigger_OnQuestActive:Interrupt()
    -- does this realy matter after interrupt?
    -- self.WaitTimeTimer = nil;
    -- self.WasActivated = nil;
end

function b_Trigger_OnQuestActive:Reset()
    self.WaitTimeTimer = nil;
    self.WasActivated = nil;
end

Core:RegisterBehavior(b_Trigger_OnQuestActive);

-- -------------------------------------------------------------------------- --

---
-- Startet einen Quest, sobald ein anderer fehlschlägt.
--
-- @param _QuestName Name des Quest
-- @param _Time      Wartezeit
-- return Table mit Behavior
-- @within Trigger
--
function Trigger_OnQuestFailure(...)
    return b_Trigger_OnQuestFailure(...);
end

b_Trigger_OnQuestFailure = {
    Name = "Trigger_OnQuestFailure",
    Description = {
        en = "Trigger: if a given quest has failed. Waiting time optional",
        de = "Auslöser: wenn eine angegebene Quest fehlgeschlagen ist. Optional mit Wartezeit",
    },
    Parameter = {
        { ParameterType.QuestName,     en = "Quest name", de = "Questname" },
        { ParameterType.Number,     en = "Waiting time", de = "Wartezeit"},
    },
}

function b_Trigger_OnQuestFailure:GetTriggerTable(_Quest)
    return { Triggers.Custom2,{self, self.CustomFunction} }
end

function b_Trigger_OnQuestFailure:AddParameter(_Index, _Parameter)
    if (_Index == 0) then
        self.QuestName = _Parameter
    elseif (_Index == 1) then
        self.WaitTime = (_Parameter ~= nil and tonumber(_Parameter)) or 0
    end
end

function b_Trigger_OnQuestFailure:CustomFunction(_Quest)
    if (GetQuestID(self.QuestName) ~= nil) then
        local QuestID = GetQuestID(self.QuestName)
        if (Quests[QuestID].Result == QuestResult.Failure) then
            if self.WaitTime and self.WaitTime > 0 then
                self.WaitTimeTimer = self.WaitTimeTimer or Logic.GetTime();
                if Logic.GetTime() >= self.WaitTimeTimer + self.WaitTime then
                    return true;
                end
            else
                return true;
            end
        end
    end
    return false;
end

function b_Trigger_OnQuestFailure:DEBUG(_Quest)
    if type(self.QuestName) ~= "string" then
        dbg("".._Quest.Identifier.." "..self.Name..": invalid quest name!");
        return true;
    elseif type(self.WaitTime) ~= "number" then
        dbg("".._Quest.Identifier.." "..self.Name..": waitTime must be a number!");
        return true;
    end
    return false;
end

function b_Trigger_OnQuestFailure:Interrupt()
    self.WaitTimeTimer = nil;
end

function b_Trigger_OnQuestFailure:Reset()
    self.WaitTimeTimer = nil;
end

Core:RegisterBehavior(b_Trigger_OnQuestFailure);

-- -------------------------------------------------------------------------- --

---
-- Startet einen Quest, wenn ein anderer noch nicht ausgelöst wurde.
--
-- Der Trigger löst auch aus, wenn der Quest bereits beendet wurde, da er
-- dazu vorher ausgelöst wurden sein muss.
--
-- @param _QuestName Name des Quest
-- @param _Time      Wartezeit
-- return Table mit Behavior
-- @within Trigger
--
function Trigger_OnQuestNotTriggered(...)
    return b_Trigger_OnQuestNotTriggered(...);
end

b_Trigger_OnQuestNotTriggered = {
    Name = "Trigger_OnQuestNotTriggered",
    Description = {
        en = "Trigger: if a given quest is not yet active. Should be used in combination with other triggers.",
        de = "Auslöser: wenn eine angegebene Quest noch inaktiv ist. Sollte mit weiteren Triggern kombiniert werden.",
    },
    Parameter = {
        { ParameterType.QuestName,     en = "Quest name", de = "Questname" },
    },
}

function b_Trigger_OnQuestNotTriggered:GetTriggerTable(_Quest)
    return { Triggers.Custom2,{self, self.CustomFunction} }
end

function b_Trigger_OnQuestNotTriggered:AddParameter(_Index, _Parameter)
    if (_Index == 0) then
        self.QuestName = _Parameter
    end
end

function b_Trigger_OnQuestNotTriggered:CustomFunction(_Quest)
    if (GetQuestID(self.QuestName) ~= nil) then
        local QuestID = GetQuestID(self.QuestName)
        if (Quests[QuestID].State == QuestState.NotTriggered) then
            return true;
        end
    end
    return false;
end

function b_Trigger_OnQuestNotTriggered:DEBUG(_Quest)
    if type(self.QuestName) ~= "string" then
        dbg("".._Quest.Identifier.." "..self.Name..": invalid quest name!");
        return true;
    end
    return false;
end

Core:RegisterBehavior(b_Trigger_OnQuestNotTriggered);

-- -------------------------------------------------------------------------- --

---
-- Startet den Quest, sobald ein anderer unterbrochen wurde.
--
-- @param _QuestName Name des Quest
-- @param _Time      Wartezeit
-- return Table mit Behavior
-- @within Trigger
--
function Trigger_OnQuestInterrupted(...)
    return b_Trigger_OnQuestInterrupted(...);
end

b_Trigger_OnQuestInterrupted = {
    Name = "Trigger_OnQuestInterrupted",
    Description = {
        en = "Trigger: if a given quest has been interrupted. Should be used in combination with other triggers.",
        de = "Auslöser: wenn eine angegebene Quest abgebrochen wurde. Sollte mit weiteren Triggern kombiniert werden.",
    },
    Parameter = {
        { ParameterType.QuestName,     en = "Quest name", de = "Questname" },
        { ParameterType.Number,     en = "Waiting time", de = "Wartezeit"},
    },
}

function b_Trigger_OnQuestInterrupted:GetTriggerTable(_Quest)
    return { Triggers.Custom2,{self, self.CustomFunction} }
end

function b_Trigger_OnQuestInterrupted:AddParameter(_Index, _Parameter)
    if (_Index == 0) then
        self.QuestName = _Parameter
    elseif (_Index == 1) then
        self.WaitTime = (_Parameter ~= nil and tonumber(_Parameter)) or 0
    end
end

function b_Trigger_OnQuestInterrupted:CustomFunction(_Quest)
    if (GetQuestID(self.QuestName) ~= nil) then
        local QuestID = GetQuestID(self.QuestName)
        if (Quests[QuestID].State == QuestState.Over and Quests[QuestID].Result == QuestResult.Interrupted) then
            if self.WaitTime and self.WaitTime > 0 then
                self.WaitTimeTimer = self.WaitTimeTimer or Logic.GetTime();
                if Logic.GetTime() >= self.WaitTimeTimer + self.WaitTime then
                    return true;
                end
            else
                return true;
            end
        end
    end
    return false;
end

function b_Trigger_OnQuestInterrupted:DEBUG(_Quest)
    if type(self.QuestName) ~= "string" then
        dbg("".._Quest.Identifier.." "..self.Name..": invalid quest name!");
        return true;
    elseif type(self.WaitTime) ~= "number" then
        dbg("".._Quest.Identifier.." "..self.Name..": waitTime must be a number!");
        return true;
    end
    return false;
end

function b_Trigger_OnQuestInterrupted:Interrupt()
    self.WaitTimeTimer = nil;
end

function b_Trigger_OnQuestInterrupted:Reset()
    self.WaitTimeTimer = nil;
end

Core:RegisterBehavior(b_Trigger_OnQuestInterrupted);

-- -------------------------------------------------------------------------- --

---
-- Startet den Quest, sobald ein anderer bendet wurde.
--
-- Dabei ist das Resultat egal. Der Quest kann entweder erfolgreich beendet
-- wurden oder fehlgeschlagen sein.
--
-- @param _QuestName Name des Quest
-- @param _Time      Wartezeit
-- return Table mit Behavior
-- @within Trigger
--
function Trigger_OnQuestOver(...)
    return b_Trigger_OnQuestOver(...);
end

b_Trigger_OnQuestOver = {
    Name = "Trigger_OnQuestOver",
    Description = {
        en = "Trigger: if a given quest has been finished, regardless of its result. Waiting time optional",
        de = "Auslöser: wenn eine angegebene Quest beendet wurde, unabhängig von deren Ergebnis. Wartezeit optional",
    },
    Parameter = {
        { ParameterType.QuestName,     en = "Quest name", de = "Questname" },
        { ParameterType.Number,     en = "Waiting time", de = "Wartezeit"},
    },
}

function b_Trigger_OnQuestOver:GetTriggerTable(_Quest)
    return { Triggers.Custom2,{self, self.CustomFunction} }
end

function b_Trigger_OnQuestOver:AddParameter(_Index, _Parameter)
    if (_Index == 0) then
        self.QuestName = _Parameter
    elseif (_Index == 1) then
        self.WaitTime = (_Parameter ~= nil and tonumber(_Parameter)) or 0
    end
end

function b_Trigger_OnQuestOver:CustomFunction(_Quest)
    if (GetQuestID(self.QuestName) ~= nil) then
        local QuestID = GetQuestID(self.QuestName)
        if (Quests[QuestID].State == QuestState.Over and Quests[QuestID].Result ~= QuestResult.Interrupted) then
            if self.WaitTime and self.WaitTime > 0 then
                self.WaitTimeTimer = self.WaitTimeTimer or Logic.GetTime();
                if Logic.GetTime() >= self.WaitTimeTimer + self.WaitTime then
                    return true;
                end
            else
                return true;
            end
        end
    end
    return false;
end

function b_Trigger_OnQuestOver:DEBUG(_Quest)
    if type(self.QuestName) ~= "string" then
        dbg("".._Quest.Identifier.." "..self.Name..": invalid quest name!");
        return true;
    elseif type(self.WaitTime) ~= "number" then
        dbg("".._Quest.Identifier.." "..self.Name..": waitTime must be a number!");
        return true;
    end
    return false;
end

function b_Trigger_OnQuestOver:Interrupt()
    self.WaitTimeTimer = nil;
end

function b_Trigger_OnQuestOver:Reset()
    self.WaitTimeTimer = nil;
end

Core:RegisterBehavior(b_Trigger_OnQuestOver);

-- -------------------------------------------------------------------------- --

---
-- Startet den Quest, sobald ein anderer Quest erfolgreich abgeschlossen wurde.
--
-- @param _QuestName Name des Quest
-- @param _Time      Wartezeit
-- return Table mit Behavior
-- @within Trigger
--
function Trigger_OnQuestSuccess(...)
    return b_Trigger_OnQuestSuccess:new(...);
end

b_Trigger_OnQuestSuccess = {
    Name = "Trigger_OnQuestSuccess",
    Description = {
        en = "Trigger: if a given quest has been finished successfully. Waiting time optional",
        de = "Auslöser: wenn eine angegebene Quest erfolgreich abgeschlossen wurde. Wartezeit optional",
    },
    Parameter = {
        { ParameterType.QuestName,     en = "Quest name", de = "Questname" },
        { ParameterType.Number,     en = "Waiting time", de = "Wartezeit"},
    },
}

function b_Trigger_OnQuestSuccess:GetTriggerTable(_Quest)
    return { Triggers.Custom2,{self, self.CustomFunction} }
end

function b_Trigger_OnQuestSuccess:AddParameter(_Index, _Parameter)
    if (_Index == 0) then
        self.QuestName = _Parameter
    elseif (_Index == 1) then
        self.WaitTime = (_Parameter ~= nil and tonumber(_Parameter)) or 0
    end
end

function b_Trigger_OnQuestSuccess:CustomFunction()
    if (GetQuestID(self.QuestName) ~= nil) then
        local QuestID = GetQuestID(self.QuestName)
        if (Quests[QuestID].Result == QuestResult.Success) then
            if self.WaitTime and self.WaitTime > 0 then
                self.WaitTimeTimer = self.WaitTimeTimer or Logic.GetTime();
                if Logic.GetTime() >= self.WaitTimeTimer + self.WaitTime then
                    return true;
                end
            else
                return true;
            end
        end
    end
    return false;
end

function b_Trigger_OnQuestSuccess:DEBUG(_Quest)
    if type(self.QuestName) ~= "string" then
        dbg("".._Quest.Identifier.." "..self.Name..": invalid quest name!");
        return true;
    elseif type(self.WaitTime) ~= "number" then
        dbg("".._Quest.Identifier.." "..self.Name..": waittime must be a number!");
        return true;
    end
    return false;
end

function b_Trigger_OnQuestSuccess:Interrupt()
    self.WaitTimeTimer = nil;
end

function b_Trigger_OnQuestSuccess:Reset()
    self.WaitTimeTimer = nil;
end

Core:RegisterBehavior(b_Trigger_OnQuestSuccess);

-- -------------------------------------------------------------------------- --

---
-- Startet den Quest, wenn eine benutzerdefinierte Variable einen bestimmten
-- Wert angenommen hat.
--
-- Benutzerdefinierte Variablen müssen Zahlen sein.
--
-- @param _Name     Name der Variable
-- @param _Relation Vergleichsoperator
-- @param _Value    Wert oder Custom Variable
-- @return Table mit Behavior
-- @within Trigger
--
function Trigger_CustomVariables(...)
    return b_Trigger_CustomVariables:new(...);
end

b_Trigger_CustomVariables = {
    Name = "Trigger_CustomVariables",
    Description = {
        en = "Trigger: if the variable has a certain value.",
        de = "Auslöser: wenn die Variable einen bestimmen Wert eingenommen hat.",
    },
    Parameter = {
        { ParameterType.Default, en = "Name of Variable", de = "Variablennamen" },
        { ParameterType.Custom,  en = "Relation", de = "Relation" },
        { ParameterType.Default, en = "Value", de = "Wert" }
    }
};

function b_Trigger_CustomVariables:GetTriggerTable()
    return { Triggers.Custom2, {self, self.CustomFunction} };
end

function b_Trigger_CustomVariables:AddParameter(_Index, _Parameter)
    if _Index == 0 then
        self.VariableName = _Parameter
    elseif _Index == 1 then
        self.Relation = _Parameter
    elseif _Index == 2 then
        local value = tonumber(_Parameter);
        value = (value ~= nil and value) or _Parameter;
        self.Value = value
    end
end

function b_Trigger_CustomVariables:CustomFunction()
    if _G["QSB_CustomVariables_"..self.VariableName] ~= nil then
        if self.Relation == "==" then
            return _G["QSB_CustomVariables_"..self.VariableName] == ((type(self.Value) ~= "string" and self.Value) or _G["QSB_CustomVariables_"..self.Value]);
        elseif self.Relation ~= "~=" then
            return _G["QSB_CustomVariables_"..self.VariableName] ~= ((type(self.Value) ~= "string" and self.Value) or _G["QSB_CustomVariables_"..self.Value]);
        elseif self.Relation == ">" then
            return _G["QSB_CustomVariables_"..self.VariableName] > ((type(self.Value) ~= "string" and self.Value) or _G["QSB_CustomVariables_"..self.Value]);
        elseif self.Relation == ">=" then
            return _G["QSB_CustomVariables_"..self.VariableName] >= ((type(self.Value) ~= "string" and self.Value) or _G["QSB_CustomVariables_"..self.Value]);
        elseif self.Relation == "<=" then
            return _G["QSB_CustomVariables_"..self.VariableName] <= ((type(self.Value) ~= "string" and self.Value) or _G["QSB_CustomVariables_"..self.Value]);
        else
            return _G["QSB_CustomVariables_"..self.VariableName] < ((type(self.Value) ~= "string" and self.Value) or _G["QSB_CustomVariables_"..self.Value]);
        end
    end
    return false;
end

function b_Trigger_CustomVariables:GetCustomData( _Index )
    if _Index == 1 then
        return {"==", "~=", "<=", "<", ">", ">="};
    end
end

function b_Trigger_CustomVariables:DEBUG(_Quest)
    local relations = {"==", "~=", "<=", "<", ">", ">="}
    local results    = {true, false, nil}

    if not _G["QSB_CustomVariables_"..self.VariableName] then
        dbg(_Quest.Identifier.." "..self.Name..": variable '"..self.VariableName.."' do not exist!");
        return true;
    elseif not Inside(self.Relation,relations) then
        dbg(_Quest.Identifier.." "..self.Name..": '"..self.Relation.."' is an invalid relation!");
        return true;
    end
    return false;
end

Core:RegisterBehavior(b_Trigger_CustomVariables)

-- -------------------------------------------------------------------------- --

---
-- Startet den Quest sofort.
--
-- @return Table mit Behavior
-- @within Trigger
--
function Trigger_AlwaysActive()
    return b_Trigger_AlwaysActive:new()
end

b_Trigger_AlwaysActive = {
    Name = "Trigger_AlwaysActive",
    Description = {
        en = "Trigger: the map has been started.",
        de = "Auslöser: Start der Karte.",
    },
}

function b_Trigger_AlwaysActive:GetTriggerTable(_Quest)
    return {Triggers.Time, 0 }
end

Core:RegisterBehavior(b_Trigger_AlwaysActive);

-- -------------------------------------------------------------------------- --

---
-- Startet den Quest im angegebenen Monat.
--
-- @param _Month Monat
-- @return Table mit Behavior
-- @within Trigger
--
function Trigger_OnMonth(...)
    return b_Trigger_OnMonth:new(...);
end

b_Trigger_OnMonth = {
    Name = "Trigger_OnMonth",
    Description = {
        en = "Trigger: a specified month",
        de = "Auslöser: ein bestimmter Monat",
    },
    Parameter = {
        { ParameterType.Custom, en = "Month", de = "Monat" },
    },
}

function b_Trigger_OnMonth:GetTriggerTable()
    return { Triggers.Custom2,{self, self.CustomFunction} }
end

function b_Trigger_OnMonth:AddParameter(_Index, _Parameter)
    if (_Index == 0) then
        self.Month = _Parameter * 1
    end
end

function b_Trigger_OnMonth:CustomFunction(_Quest)
    return self.Month == Logic.GetCurrentMonth()
end

function b_Trigger_OnMonth:GetCustomData( _Index )
    local Data = {}
    if _Index == 0 then
        for i = 1, 12 do
            table.insert( Data, i )
        end
    else
        assert( false )
    end
    return Data
end

function b_Trigger_OnMonth:DEBUG(_Quest)
    if self.Month < 1 or self.Month > 12 then
        dbg(_Quest.Identifier .. " " .. self.Name .. ": Month has the wrong value")
        return true
    end
    return false;
end

Core:RegisterBehavior(b_Trigger_OnMonth);

-- -------------------------------------------------------------------------- --

---
-- Startet den Quest sobald der Monsunregen einsetzt.
--
-- <b>Achtung:</b> Dieses Behavior ist nur für Reich des Ostens verfügbar.
--
-- @return Table mit Behavior
-- @within Trigger
--
function Trigger_OnMonsoon()
    return b_Trigger_OnMonsoon:new();
end

b_Trigger_OnMonsoon = {
    Name = "Trigger_OnMonsoon",
    Description = {
        en = "Trigger: on monsoon.",
        de = "Auslöser: wenn der Monsun beginnt.",
    },
    RequiresExtraNo = 1,
}

function b_Trigger_OnMonsoon:GetTriggerTable()
    return { Triggers.Custom2,{self, self.CustomFunction} }
end

function b_Trigger_OnMonsoon:CustomFunction(_Quest)
    if Logic.GetWeatherDoesShallowWaterFlood(0) then
        return true
    end
end

Core:RegisterBehavior(b_Trigger_OnMonsoon);

-- -------------------------------------------------------------------------- --

---
-- Startet den Quest sobald der Timer abgelaufen ist.
--
-- Der Timer zählt immer vom Start der Map an.
--
-- @param _Time Zeit bis zum Start
-- @return Table mit Behavior
-- @within Trigger
--
function Trigger_Time(...)
    return b_Trigger_Time:new(...);
end

b_Trigger_Time = {
    Name = "Trigger_Time",
    Description = {
        en = "Trigger: a given amount of time since map start",
        de = "Auslöser: eine gewisse Anzahl Sekunden nach Spielbeginn",
    },
    Parameter = {
        { ParameterType.Number, en = "Time (sec.)", de = "Zeit (Sek.)" },
    },
}

function b_Trigger_Time:GetTriggerTable(_Quest)
    return {Triggers.Time, self.Time }
end

function b_Trigger_Time:AddParameter(_Index, _Parameter)
    if (_Index == 0) then
        self.Time = _Parameter * 1
    end
end

Core:RegisterBehavior(b_Trigger_Time);

-- -------------------------------------------------------------------------- --

---
-- Startet den Quest sobald das Wasser gefriert.
--
-- @return Table mit Behavior
-- @within Trigger
--
function Trigger_OnWaterFreezes()
    return b_Trigger_OnWaterFreezes:new();
end

b_Trigger_OnWaterFreezes = {
    Name = "Trigger_OnWaterFreezes",
    Description = {
        en = "Trigger: if the water starts freezing",
        de = "Auslöser: wenn die Gewässer gefrieren",
    },
}

function b_Trigger_OnWaterFreezes:GetTriggerTable()
    return { Triggers.Custom2,{self, self.CustomFunction} }
end

function b_Trigger_OnWaterFreezes:CustomFunction(_Quest)
    if Logic.GetWeatherDoesWaterFreeze(0) then
        return true
    end
end

Core:RegisterBehavior(b_Trigger_OnWaterFreezes);

-- -------------------------------------------------------------------------- --

---
-- Startet den Quest niemals.
--
-- Quests, für die dieser Trigger gesetzt ist, müssen durch einen anderen
-- Quest über Reward_QuestActive oder Reprisal_QuestActive gestartet werden.
--
-- @return Table mit Behavior
-- @within Trigger
--
function Trigger_NeverTriggered()
    return b_Trigger_NeverTriggered:new();
end

b_Trigger_NeverTriggered = {
    Name = "Trigger_NeverTriggered",
    Description = {
        en = "Never triggers a Quest. The quest may be set active by Reward_QuestActivate or Reward_QuestRestartForceActive",
        de = "Löst nie eine Quest aus. Die Quest kann von Reward_QuestActivate oder Reward_QuestRestartForceActive aktiviert werden.",
    },
}

function b_Trigger_NeverTriggered:GetTriggerTable()

    return {Triggers.Custom2, {self, function() end} }

end

Core:RegisterBehavior(b_Trigger_NeverTriggered)

-- -------------------------------------------------------------------------- --

---
-- Startet den Quest, sobald wenigstens einer von zwei Quests fehlschlägt.
--
-- @param _QuestName1 Name des ersten Quest
-- @param _QuestName2 Name des zweiten Quest
-- @return Table mit Behavior
-- @within Trigger
--
function Trigger_OnAtLeastOneQuestFailure(...)
    return b_Trigger_OnAtLeastOneQuestFailure:new(...);
end

b_Trigger_OnAtLeastOneQuestFailure = {
    Name = "Trigger_OnAtLeastOneQuestFailure",
    Description = {
        en = "Trigger: if one or both of the given quests have failed.",
        de = "Auslöser: wenn einer oder beide der angegebenen Aufträge fehlgeschlagen sind.",
    },
    Parameter = {
        { ParameterType.QuestName, en = "Quest Name 1", de = "Questname 1" },
        { ParameterType.QuestName, en = "Quest Name 2", de = "Questname 2" },
    },
}

function b_Trigger_OnAtLeastOneQuestFailure:GetTriggerTable(_Quest)
    return {Triggers.Custom2, {self, self.CustomFunction}};
end

function b_Trigger_OnAtLeastOneQuestFailure:AddParameter(_Index, _Parameter)
    self.QuestTable = {};

    if (_Index == 0) then
        self.Quest1 = _Parameter;
    elseif (_Index == 1) then
        self.Quest2 = _Parameter;
    end
end

function b_Trigger_OnAtLeastOneQuestFailure:CustomFunction(_Quest)
    local Quest1 = Quests[GetQuestID(self.Quest1)];
    local Quest2 = Quests[GetQuestID(self.Quest2)];
    if (Quest1.State == QuestState.Over and Quest1.Result == QuestResult.Failure)
    or (Quest2.State == QuestState.Over and Quest2.Result == QuestResult.Failure) then
        return true;
    end
    return false;
end

function b_Trigger_OnAtLeastOneQuestFailure:DEBUG(_Quest)
    if self.Quest1 == self.Quest2 then
        dbg(_Quest.Identifier..": "..self.Name..": Both quests are identical!");
        return true;
    elseif not IsValidQuest(self.Quest1) then
        dbg(_Quest.Identifier..": "..self.Name..": Quest '"..self.Quest1.."' does not exist!");
        return true;
    elseif not IsValidQuest(self.Quest2) then
        dbg(_Quest.Identifier..": "..self.Name..": Quest '"..self.Quest2.."' does not exist!");
        return true;
    end
    return false;
end

Core:RegisterBehavior(b_Trigger_OnAtLeastOneQuestFailure);

-- -------------------------------------------------------------------------- --

---
-- Startet den Quest, sobald wenigstens einer von zwei Quests erfolgreich ist.
--
-- @param _QuestName1 Name des ersten Quest
-- @param _QuestName2 Name des zweiten Quest
-- @return Table mit Behavior
-- @within Trigger
--
function Trigger_OnAtLeastOneQuestSuccess(...)
    return b_Trigger_OnAtLeastOneQuestSuccess:new(...);
end

b_Trigger_OnAtLeastOneQuestSuccess = {
    Name = "Trigger_OnAtLeastOneQuestSuccess",
    Description = {
        en = "Trigger: if one or both of the given quests are won.",
        de = "Auslöser: wenn einer oder beide der angegebenen Aufträge gewonnen wurden.",
    },
    Parameter = {
        { ParameterType.QuestName, en = "Quest Name 1", de = "Questname 1" },
        { ParameterType.QuestName, en = "Quest Name 2", de = "Questname 2" },
    },
}

function b_Trigger_OnAtLeastOneQuestSuccess:GetTriggerTable(_Quest)
    return {Triggers.Custom2, {self, self.CustomFunction}};
end

function b_Trigger_OnAtLeastOneQuestSuccess:AddParameter(_Index, _Parameter)
    self.QuestTable = {};

    if (_Index == 0) then
        self.Quest1 = _Parameter;
    elseif (_Index == 1) then
        self.Quest2 = _Parameter;
    end
end

function b_Trigger_OnAtLeastOneQuestSuccess:CustomFunction(_Quest)
    local Quest1 = Quests[GetQuestID(self.Quest1)];
    local Quest2 = Quests[GetQuestID(self.Quest2)];
    if (Quest1.State == QuestState.Over and Quest1.Result == QuestResult.Success)
    or (Quest2.State == QuestState.Over and Quest2.Result == QuestResult.Success) then
        return true;
    end
    return false;
end

function b_Trigger_OnAtLeastOneQuestSuccess:DEBUG(_Quest)
    if self.Quest1 == self.Quest2 then
        dbg(_Quest.Identifier..": "..self.Name..": Both quests are identical!");
        return true;
    elseif not IsValidQuest(self.Quest1) then
        dbg(_Quest.Identifier..": "..self.Name..": Quest '"..self.Quest1.."' does not exist!");
        return true;
    elseif not IsValidQuest(self.Quest2) then
        dbg(_Quest.Identifier..": "..self.Name..": Quest '"..self.Quest2.."' does not exist!");
        return true;
    end
    return false;
end

Core:RegisterBehavior(b_Trigger_OnAtLeastOneQuestSuccess);

-- -------------------------------------------------------------------------- --

---
-- Startet den Quest, sobald mindestens X von Y Quests erfolgreich sind.
--
-- @param _MinAmount   Mindestens zu erfüllen (max. 5)
-- @param _QuestAmount Anzahl geprüfter Quests (max. 5 und >= _MinAmount)
-- @param _Quest1      Name des 1. Quest
-- @param _Quest2      Name des 2. Quest
-- @param _Quest3      Name des 3. Quest
-- @param _Quest4      Name des 4. Quest
-- @param _Quest5      Name des 5. Quest
-- @return Table mit Behavior
-- @within Trigger
--
function Trigger_OnAtLeastXOfYQuestsSuccess(...)
    return b_Trigger_OnAtLeastXOfYQuestsSuccess:new(...);
end

b_Trigger_OnAtLeastXOfYQuestsSuccess = {
    Name = "Trigger_OnAtLeastXOfYQuestsSuccess",
    Description = {
        en = "Trigger: if at least X of Y given quests has been finished successfully.",
        de = "Auslöser: wenn X von Y angegebener Quests erfolgreich abgeschlossen wurden.",
    },
    Parameter = {
        { ParameterType.Custom, en = "Least Amount", de = "Mindest Anzahl" },
        { ParameterType.Custom, en = "Quest Amount", de = "Quest Anzahl" },
        { ParameterType.QuestName, en = "Quest name 1", de = "Questname 1" },
        { ParameterType.QuestName, en = "Quest name 2", de = "Questname 2" },
        { ParameterType.QuestName, en = "Quest name 3", de = "Questname 3" },
        { ParameterType.QuestName, en = "Quest name 4", de = "Questname 4" },
        { ParameterType.QuestName, en = "Quest name 5", de = "Questname 5" },
    },
}

function b_Trigger_OnAtLeastXOfYQuestsSuccess:GetTriggerTable()
    return { Triggers.Custom2,{self, self.CustomFunction} }
end

function b_Trigger_OnAtLeastXOfYQuestsSuccess:AddParameter(_Index, _Parameter)
    if (_Index == 0) then
        self.LeastAmount = tonumber(_Parameter)
    elseif (_Index == 1) then
        self.QuestAmount = tonumber(_Parameter)
    elseif (_Index == 2) then
        self.QuestName1 = _Parameter
    elseif (_Index == 3) then
        self.QuestName2 = _Parameter
    elseif (_Index == 4) then
        self.QuestName3 = _Parameter
    elseif (_Index == 5) then
        self.QuestName4 = _Parameter
    elseif (_Index == 6) then
        self.QuestName5 = _Parameter
    end
end

function b_Trigger_OnAtLeastXOfYQuestsSuccess:CustomFunction()
    local least = 0
    for i = 1, self.QuestAmount do
        local QuestID = GetQuestID(self["QuestName"..i]);
        if IsValidQuest(QuestID) then
			if (Quests[QuestID].Result == QuestResult.Success) then
				least = least + 1
				if least >= self.LeastAmount then
					return true
				end
			end
		end
    end
    return false
end

function b_Trigger_OnAtLeastXOfYQuestsSuccess:DEBUG(_Quest)
    local leastAmount = self.LeastAmount
    local questAmount = self.QuestAmount
    if leastAmount <= 0 or leastAmount >5 then
        dbg(_Quest.Identifier .. ": Error in " .. self.Name .. ": LeastAmount is wrong")
        return true
    elseif questAmount <= 0 or questAmount > 5 then
        dbg(_Quest.Identifier .. ": Error in " .. self.Name .. ": QuestAmount is wrong")
        return true
    elseif leastAmount > questAmount then
        dbg(_Quest.Identifier .. ": Error in " .. self.Name .. ": LeastAmount is greater than QuestAmount")
        return true
    end
    for i = 1, questAmount do
        if not IsValidQuest(self["QuestName"..i]) then
            dbg(_Quest.Identifier .. ": Error in " .. self.Name .. ": Quest ".. self["QuestName"..i] .. " not found")
            return true
        end
    end
    return false
end

function b_Trigger_OnAtLeastXOfYQuestsSuccess:GetCustomData(_Index)
    if (_Index == 0) or (_Index == 1) then
        return {"1", "2", "3", "4", "5"}
    end
end

Core:RegisterBehavior(b_Trigger_OnAtLeastXOfYQuestsSuccess)

-- -------------------------------------------------------------------------- --
-- Application-Space                                                          --
-- -------------------------------------------------------------------------- --

BundleClassicBehaviors = {
    Global = {},
    Local = {}
};

-- Global Script ---------------------------------------------------------------

---
-- Initialisiert das Bundle im globalen Skript.
-- @within Application-Space
-- @local
--
function BundleClassicBehaviors.Global:Install()

end

-- Local Script ----------------------------------------------------------------

---
-- Initialisiert das Bundle im lokalen Skript.
-- @within Application-Space
-- @local
--
function BundleClassicBehaviors.Local:Install()

end

Core:RegisterBundle("BundleClassicBehaviors");

-- -------------------------------------------------------------------------- --
-- ########################################################################## --
-- #  Symfonia BundleSymfoniaBehaviors                                      # --
-- ########################################################################## --
-- -------------------------------------------------------------------------- --

---
-- Dieses Bundle enthält einige weitere nützliche Standard-Behavior.
--
-- @module BundleSymfoniaBehaviors
-- @set sort=true
--

API = API or {};
QSB = QSB or {};

-- -------------------------------------------------------------------------- --
-- User-Space                                                                 --
-- -------------------------------------------------------------------------- --



-- -------------------------------------------------------------------------- --
-- Goals                                                                      --
-- -------------------------------------------------------------------------- --

---
-- Ein Entity muss sich zu einem Ziel bewegen und eine Distanz unterschreiten.
--
-- Optional kann das Ziel mit einem Marker markiert werden.
--
-- @param _ScriptName Skriptname des Entity
-- @param _Target     Skriptname des Ziels
-- @param _Distance   Entfernung
-- @param _UseMarker  Ziel markieren
-- @return Table mit Behavior
-- @within Goal
--
function Goal_MoveToPosition(...)
    return b_Goal_MoveToPosition:new(...);
end

b_Goal_MoveToPosition = {
    Name = "Goal_MoveToPosition",
    Description = {
        en = "Goal: A entity have to moved as close as the distance to another entity. The target can be marked with a static marker.",
        de = "Ziel: Eine Entity muss sich einer anderen bis auf eine bestimmte Distanz nähern. Die Lupe wird angezeigt, das Ziel kann markiert werden.",
    },
    Parameter = {
        { ParameterType.ScriptName, en = "Entity",      de = "Entity" },
        { ParameterType.ScriptName, en = "Target",      de = "Ziel" },
        { ParameterType.Number,     en = "Distance", de = "Entfernung" },
        { ParameterType.Custom,     en = "Marker",      de = "Ziel markieren" },
    },
}

function b_Goal_MoveToPosition:GetGoalTable(__quest_)
    return {Objective.Distance, self.Entity, self.Target, self.Distance, self.Marker}
end

function b_Goal_MoveToPosition:AddParameter(__index_, __parameter_)
    if (__index_ == 0) then
        self.Entity = __parameter_
    elseif (__index_ == 1) then
        self.Target = __parameter_
    elseif (__index_ == 2) then
        self.Distance = __parameter_ * 1
    elseif (__index_ == 3) then
        self.Marker = AcceptAlternativeBoolean(__parameter_)
    end
end

function b_Goal_MoveToPosition:GetCustomData( __index_ )
    local Data = {};
    if __index_ == 3 then
        Data = {"true", "false"}
    end
    return Data
end

Core:RegisterBehavior(b_Goal_MoveToPosition);

-- -------------------------------------------------------------------------- --

---
-- Der Spieler muss einen bestimmten Quest abschließen.
--
-- @param _QuestName Name des Quest
-- @return Table mit Behavior
-- @within Goal
--
function Goal_WinQuest(...)
    return b_Goal_WinQuest:new(...);
end

b_Goal_WinQuest = {
    Name = "Goal_WinQuest",
    Description = {
        en = "Goal: The player has to win a given quest",
        de = "Ziel: Der Spieler muss eine angegebene Quest erfolgreich abschliessen.",
    },
    Parameter = {
        { ParameterType.QuestName, en = "Quest Name",      de = "Questname" },
    },
}

function b_Goal_WinQuest:GetGoalTable(__quest_)
    return {Objective.Custom2, {self, self.CustomFunction}};
end

function b_Goal_WinQuest:AddParameter(__index_, __parameter_)
    if (__index_ == 0) then
        self.Quest = __parameter_;
    end
end

function b_Goal_WinQuest:CustomFunction(__quest_)
    local quest = Quests[GetQuestID(self.Quest)];
    if quest then
        if quest.Result == QuestResult.Failure then
            return false;
        end
        if quest.Result == QuestResult.Success then
            return true;
        end
    end
    return nil;
end

function b_Goal_WinQuest:DEBUG(__quest_)
    if Quests[GetQuestID(self.Quest)] == nil then
        dbg(__quest_.Identifier .. ": " .. self.Name .. ": Quest '"..self.Quest.."' does not exist!");
        return true;
    end
    return false;
end

Core:RegisterBehavior(b_Goal_WinQuest);

-- -------------------------------------------------------------------------- --

---
-- Der Spieler muss eine bestimmte Menge Gold mit Dieben stehlen.
--
-- Dabei ist es egal von welchem Spieler. Diebe können Gold nur aus
-- Stadtgebäude stehlen.
--
-- @param _Amount       Menge an Gold
-- @param _ShowProgress Fortschritt ausgeben
-- @return Table mit Behavior
-- @within Goal
--
function Goal_StealGold(...)
    return b_Goal_StealGold:new(...)
end

b_Goal_StealGold = {
    Name = "Goal_StealGold",
    Description = {
        en = "Goal: Steal an explicit amount of gold from a players or any players city buildings.",
        de = "Ziel: Diebe sollen eine bestimmte Menge Gold aus feindlichen Stadtgebäuden stehlen.",
    },
    Parameter = {
        { ParameterType.Number, en = "Amount on Gold", de = "Zu stehlende Menge" },
        { ParameterType.Custom, en = "Print progress", de = "Fortschritt ausgeben" },
    },
}

function b_Goal_StealGold:GetGoalTable(__quest_)
    return {Objective.Custom2, {self, self.CustomFunction}};
end

function b_Goal_StealGold:AddParameter(__index_, __parameter_)
    if (__index_ == 0) then
        self.Amount = __parameter_ * 1;
    elseif (__index_ == 1) then
        __parameter_ = __parameter_ or "true"
        self.Printout = AcceptAlternativeBoolean(__parameter_);
    end
    self.StohlenGold = 0;
end

function b_Goal_StealGold:GetCustomData(__index_)
    if __index_ == 1 then
        return { "true", "false" };
    end
end

function b_Goal_StealGold:SetDescriptionOverwrite(__quest_)
    local lang = (Network.GetDesiredLanguage() == "de" and "de") or "en";
    local amount = self.Amount-self.StohlenGold;
    amount = (amount > 0 and amount) or 0;
    local text = {
        de = "Gold stehlen {cr}{cr}Aus Stadtgebäuden zu stehlende Goldmenge: ",
        en = "Steal gold {cr}{cr}Amount on gold to steal from city buildings: ",
    };
    return "{center}" .. text[lang] .. amount
end

function b_Goal_StealGold:CustomFunction(__quest_)
    Core:ChangeCustomQuestCaptionText(__quest_.Identifier, self:SetDescriptionOverwrite(__quest_));

    if self.StohlenGold >= self.Amount then
        return true;
    end
    return nil;
end

function b_Goal_StealGold:GetIcon()
    return {5,13};
end

function b_Goal_StealGold:DEBUG(__quest_)
    if tonumber(self.Amount) == nil and self.Amount < 0 then
        dbg(__quest_.Identifier .. ": " .. self.Name .. ": amount can not be negative!");
        return true;
    end
    return false;
end

function b_Goal_StealGold:Reset()
    self.StohlenGold = 0;
end

Core:RegisterBehavior(b_Goal_StealGold)

-- -------------------------------------------------------------------------- --

---
-- Der Spieler muss ein bestimmtes Stadtgebäude bestehlen.
--
-- Eine Kirche wird immer Sabotiert. Ein Lagerhaus verhält sich ähnlich zu
-- einer Burg.
--
-- @param _ScriptName Skriptname des Gebäudes
-- @return Table mit Behavior
-- @within Goal
--
function Goal_StealBuilding(...)
    return b_Goal_StealBuilding:new(...)
end

b_Goal_StealBuilding = {
    Name = "Goal_StealBuilding",
    Description = {
        en = "Goal: The player has to steal from a building. Not a castle and not a village storehouse!",
        de = "Ziel: Der Spieler muss ein bestimmtes Gebäude bestehlen. Dies darf keine Burg und kein Dorflagerhaus sein!",
    },
    Parameter = {
        { ParameterType.ScriptName, en = "Building", de = "Gebäude" },
    },
}

function b_Goal_StealBuilding:GetGoalTable(__quest_)
    return {Objective.Custom2, {self, self.CustomFunction}};
end

function b_Goal_StealBuilding:AddParameter(__index_, __parameter_)
    if (__index_ == 0) then
        self.Building = __parameter_
    end
    self.RobberList = {};
end

function b_Goal_StealBuilding:GetCustomData(__index_)
    if __index_ == 1 then
        return { "true", "false" };
    end
end

function b_Goal_StealBuilding:SetDescriptionOverwrite(__quest_)
    local isCathedral = Logic.IsEntityInCategory(GetID(self.Building), EntityCategories.Cathedrals) == 1;
    local isWarehouse = Logic.GetEntityType(GetID(self.Building)) == Entities.B_StoreHouse;
    local lang = (Network.GetDesiredLanguage() == "de" and "de") or "en";
    local text;

    if isCathedral then
        text = {
            de = "Sabotage {cr}{cr} Sabotiert die mit Pfeil markierte Kirche.",
            en = "Sabotage {cr}{cr} Sabotage the Church of the opponent.",
        };
    elseif isWarehouse then
        text = {
            de = "Lagerhaus bestehlen {cr}{cr} Sendet einen Dieb in das markierte Lagerhaus.",
            en = "Steal from storehouse {cr}{cr} Steal from the marked storehouse.",
        };
    else
        text = {
            de = "Geb�ude bestehlen {cr}{cr} Bestehlt das durch einen Pfeil markierte Gebäude.",
            en = "Steal from building {cr}{cr} Steal from the building marked by an arrow.",
        };
    end
    return "{center}" .. text[lang];
end

function b_Goal_StealBuilding:CustomFunction(__quest_)
    if not IsExisting(self.Building) then
        if self.Marker then
            Logic.DestroyEffect(self.Marker);
        end
        return false;
    end

    if not self.Marker then
        local pos = GetPosition(self.Building);
        self.Marker = Logic.CreateEffect(EGL_Effects.E_Questmarker, pos.X, pos.Y, 0);
    end

    if self.SuccessfullyStohlen then
        Logic.DestroyEffect(self.Marker);
        return true;
    end
    return nil;
end

function b_Goal_StealBuilding:GetIcon()
    return {5,13};
end

function b_Goal_StealBuilding:DEBUG(__quest_)
    local eTypeName = Logic.GetEntityTypeName(Logic.GetEntityType(GetID(self.Building)));
    local IsHeadquarter = Logic.IsEntityInCategory(GetID(self.Building), EntityCategories.Headquarters) == 1;
    if Logic.IsBuilding(GetID(self.Building)) == 0 then
        dbg(__quest_.Identifier .. ": " .. self.Name .. ": target is not a building");
        return true;
    elseif not IsExisting(self.Building) then
        dbg(__quest_.Identifier .. ": " .. self.Name .. ": target is destroyed :(");
        return true;
    elseif string.find(eTypeName, "B_NPC_BanditsHQ") or string.find(eTypeName, "B_NPC_Cloister") or string.find(eTypeName, "B_NPC_StoreHouse") then
        dbg(__quest_.Identifier .. ": " .. self.Name .. ": village storehouses are not allowed!");
        return true;
    elseif IsHeadquarter then
        dbg(__quest_.Identifier .. ": " .. self.Name .. ": use Goal_StealInformation for headquarters!");
        return true;
    end
    return false;
end

function b_Goal_StealBuilding:Reset()
    self.SuccessfullyStohlen = false;
    self.RobberList = {};
    self.Marker = nil;
end

function b_Goal_StealBuilding:Interrupt(__quest_)
    Logic.DestroyEffect(self.Marker);
end

Core:RegisterBehavior(b_Goal_StealBuilding)

-- -------------------------------------------------------------------------- --

---
-- Der Spieler muss einen Dieb in ein Gebäude hineinschicken.
--
-- Der Quest ist erfolgreich, sobald der Dieb in das Gebäude eindringt. Es
-- muss sich um ein Gebäude handeln, das bestohlen werden kann (Burg, Lager,
-- Kirche, Stadtgebäude mit Einnahmen)!
--
-- Optional kann der Dieb nach Abschluss gelöscht werden. Diese Option macht
-- es einfacher ihn durch z.B. einen Abfahrenden U_ThiefCart zu ersetzen.
--
-- @param _ScriptName  Skriptname des Gebäudes
-- @param _DeleteThief Dieb nach Abschluss löschen
-- @return Table mit Behavior
-- @within Goal
--
function Goal_Infiltrate(...)
    return b_Goal_Infiltrate:new(...)
end

b_Goal_Infiltrate = {
    Name = "Goal_Infiltrate",
    IconOverwrite = {5,13},
    Description = {
        en = "Goal: Infiltrate a building with a thief. A thief must be able to steal from the target building.",
        de = "Ziel: Infiltriere ein Gebäude mit einem Dieb. Nur mit Gebaueden moeglich, die bestohlen werden koennen.",
    },
    Parameter = {
        { ParameterType.ScriptName, en = "Target Building", de = "Zielgebäude" },
        { ParameterType.Custom,     en = "Destroy Thief", de = "Dieb löschen" },
    },
}

function b_Goal_Infiltrate:GetGoalTable(__quest_)
    return {Objective.Custom2, {self, self.CustomFunction}};
end

function b_Goal_Infiltrate:AddParameter(__index_, __parameter_)
    if (__index_ == 0) then
        self.Building = __parameter_
    elseif (__index_ == 1) then
        __parameter_ = __parameter_ or "true"
        self.Delete = AcceptAlternativeBoolean(__parameter_)
    end
end

function b_Goal_Infiltrate:GetCustomData(__index_)
    if __index_ == 1 then
        return { "true", "false" };
    end
end

function b_Goal_Infiltrate:SetDescriptionOverwrite(__quest_)
    if not __quest_.QuestDescription then
        local lang = (Network.GetDesiredLanguage() == "de" and "de") or "en";
        local text = {
            de = "Gebäude infriltrieren {cr}{cr}Spioniere das markierte Gebäude mit einem Dieb aus!",
            en = "Infiltrate building {cr}{cr}Spy on the highlighted buildings with a thief!",
        };
        return text[lang];
    else
        return __quest_.QuestDescription;
    end
end

function b_Goal_Infiltrate:CustomFunction(__quest_)
    if not IsExisting(self.Building) then
        if self.Marker then
            Logic.DestroyEffect(self.Marker);
        end
        return false;
    end

    if not self.Marker then
        local pos = GetPosition(self.Building);
        self.Marker = Logic.CreateEffect(EGL_Effects.E_Questmarker, pos.X, pos.Y, 0);
    end

    if self.Infiltrated then
        Logic.DestroyEffect(self.Marker);
        return true;
    end
    return nil;
end

function b_Goal_Infiltrate:GetIcon()
    return self.IconOverwrite;
end

function b_Goal_Infiltrate:DEBUG(__quest_)
    if Logic.IsBuilding(GetID(self.Building)) == 0 then
        dbg(__quest_.Identifier .. ": " .. self.Name .. ": target is not a building");
        return true;
    elseif not IsExisting(self.Building) then
        dbg(__quest_.Identifier .. ": " .. self.Name .. ": target is destroyed :(");
        return true;
    end
    return false;
end

function b_Goal_Infiltrate:Reset()
    self.Infiltrated = false;
    self.Marker = nil;
end

function b_Goal_Infiltrate:Interrupt(__quest_)
    Logic.DestroyEffect(self.Marker);
end

Core:RegisterBehavior(b_Goal_Infiltrate);

-- -------------------------------------------------------------------------- --

---
-- Es muss eine Menge an Munition in der Kriegsmaschine erreicht werden.
-- 
-- <u>Relationen</u>
-- <ul>
-- <li>>= - Anzahl als Mindestmenge</li>
-- <li>< - Weniger als Anzahl</li>
-- </ul>
--
-- @param _ScriptName  Name des Kriegsgerät
-- @param _Relation    Mengenrelation
-- @param _Amount      Menge an Munition
-- @return Table mit Behavior
-- @within Goal
--
function Goal_AmmunitionAmount(...)
    return b_Goal_AmmunitionAmount:new(...);
end

b_Goal_AmmunitionAmount = {
    Name = "Goal_AmmunitionAmount",
    Description = {
        en = "Goal: Reach a smaller or bigger value than the given amount of ammunition in a war machine.",
        de = "Ziel: Ueber- oder unterschreite die angegebene Anzahl Munition in einem Kriegsgerät.",
    },
    Parameter = {
        { ParameterType.ScriptName, en = "Script name", de = "Skriptname" },
        { ParameterType.Custom, en = "Relation", de = "Relation" },
        { ParameterType.Number, en = "Amount", de = "Menge" },
    },
}

function b_Goal_AmmunitionAmount:GetGoalTable()
    return { Objective.Custom2, {self, self.CustomFunction} }
end

function b_Goal_AmmunitionAmount:AddParameter(_Index, _Parameter)
    if (_Index == 0) then
        self.Scriptname = _Parameter
    elseif (_Index == 1) then
        self.bRelSmallerThan = tostring(_Parameter) == "true" or _Parameter == "<"
    elseif (_Index == 2) then
        self.Amount = _Parameter * 1
    end
end

function b_Goal_AmmunitionAmount:CustomFunction()
    local EntityID = GetID(self.Scriptname);
    if not IsExisting(EntityID) then
        return false;
    end
    local HaveAmount = Logic.GetAmmunitionAmount(EntityID);
    if ( self.bRelSmallerThan and HaveAmount < self.Amount ) or ( not self.bRelSmallerThan and HaveAmount >= self.Amount ) then
        return true;
    end
    return nil;
end

function b_Goal_AmmunitionAmount:DEBUG(_Quest)
    if self.Amount < 0 then
        dbg(_Quest.Identifier .. ": Error in " .. self.Name .. ": Amount is negative");
        return true
    end
end

function b_Goal_AmmunitionAmount:GetCustomData( _Index )
    if _Index == 1 then
        return {"<", ">="};
    end
end

Core:RegisterBehavior(b_Goal_AmmunitionAmount)

-- -------------------------------------------------------------------------- --
-- Reprisals                                                                  --
-- -------------------------------------------------------------------------- --

---
-- Ändert die Position eines Siedlers oder eines Gebäudes.
--
-- Optional kann das Entity in einem bestimmten Abstand zum Ziel platziert
-- werden und das Ziel anschauen. Die Entfernung darf nicht kleiner sein
-- als 50!
--
-- @param _ScriptName Skriptname des Entity
-- @param _Target     Skriptname des Ziels
-- @param _LookAt     Gegenüberstellen
-- @param _Distance   Relative Entfernung (nur mit _LookAt)
-- @return Table mit Behavior
-- @within Reprisal
--
function Reprisal_SetPosition(...)
    return b_Reprisal_SetPosition:new(...);
end

b_Reprisal_SetPosition = {
    Name = "Reprisal_SetPosition",
    Description = {
        en = "Reprisal: Places an entity relative to the position of another. The entity can look the target.",
        de = "Vergeltung: Setzt eine Entity relativ zur Position einer anderen. Die Entity kann zum Ziel ausgerichtet werden.",
    },
    Parameter = {
        { ParameterType.ScriptName, en = "Entity",             de = "Entity", },
        { ParameterType.ScriptName, en = "Target position", de = "Zielposition", },
        { ParameterType.Custom,     en = "Face to face",     de = "Ziel ansehen", },
        { ParameterType.Number,     en = "Distance",         de = "Zielentfernung", },
    },
}

function b_Reprisal_SetPosition:GetReprisalTable(__quest_)
    return { Reprisal.Custom, { self, self.CustomFunction } }
end

function b_Reprisal_SetPosition:AddParameter( __index_, __parameter_ )
    if (__index_ == 0) then
        self.Entity = __parameter_;
    elseif (__index_ == 1) then
        self.Target = __parameter_;
    elseif (__index_ == 2) then
        self.FaceToFace = AcceptAlternativeBoolean(__parameter_)
    elseif (__index_ == 3) then
        self.Distance = (__parameter_ ~= nil and tonumber(__parameter_)) or 100;
    end
end

function b_Reprisal_SetPosition:CustomFunction(__quest_)
    if not IsExisting(self.Entity) or not IsExisting(self.Target) then
        return;
    end

    local entity = GetID(self.Entity);
    local target = GetID(self.Target);
    local x,y,z = Logic.EntityGetPos(target);
    if Logic.IsBuilding(target) == 1 then
        x,y = Logic.GetBuildingApproachPosition(target);
    end
    local ori = Logic.GetEntityOrientation(target)+90;

    if self.FaceToFace then
        x = x + self.Distance * math.cos( math.rad(ori) );
        y = y + self.Distance * math.sin( math.rad(ori) );
        Logic.DEBUG_SetSettlerPosition(entity, x, y);
        LookAt(self.Entity, self.Target);
    else
        if Logic.IsBuilding(target) == 1 then
            x,y = Logic.GetBuildingApproachPosition(target);
        end
        Logic.DEBUG_SetSettlerPosition(entity, x, y);
    end
end

function b_Reprisal_SetPosition:GetCustomData(__index_)
    if __index_ == 3 then
        return { "true", "false" }
    end
end

function b_Reprisal_SetPosition:DEBUG(__quest_)
    if self.FaceToFace then
        if tonumber(self.Distance) == nil or self.Distance < 50 then
            dbg(__quest_.Identifier.. " " ..self.Name.. ": Distance is nil or to short!");
            return true;
        end
    end
    if not IsExisting(self.Entity) or not IsExisting(self.Target) then
        dbg(__quest_.Identifier.. " " ..self.Name.. ": Mover entity or target entity does not exist!");
        return true;
    end
    return false;
end

Core:RegisterBehavior(b_Reprisal_SetPosition);

-- -------------------------------------------------------------------------- --

---
-- Ändert den Eigentümer des Entity oder des Battalions.
-- 
-- @param _ScriptName Skriptname des Entity
-- @param _NewOwner   PlayerID des Eigentümers
-- @return Table mit Behavior
-- @within Reprisal
--
function Reprisal_ChangePlayer(...)
    return b_Reprisal_ChangePlayer:new(...)
end

b_Reprisal_ChangePlayer = {
    Name = "Reprisal_ChangePlayer",
    Description = {
        en = "Reprisal: Changes the owner of the entity or a battalion.",
        de = "Vergeltung: Aendert den Besitzer einer Entity oder eines Battalions.",
    },
    Parameter = {
        { ParameterType.ScriptName, en = "Entity",     de = "Entity", },
        { ParameterType.Custom,     en = "Player",     de = "Spieler", },
    },
}

function b_Reprisal_ChangePlayer:GetReprisalTable(__quest_)
    return { Reprisal.Custom, { self, self.CustomFunction } }
end

function b_Reprisal_ChangePlayer:AddParameter( __index_, __parameter_ )
    if (__index_ == 0) then
        self.Entity = __parameter_;
    elseif (__index_ == 1) then
        self.Player = tostring(__parameter_);
    end
end

function b_Reprisal_ChangePlayer:CustomFunction(__quest_)
    if not IsExisting(self.Entity) then
        return;
    end
    local eID = GetID(self.Entity);
    if Logic.IsLeader(eID) == 1 then
        -- local SoldiersAmount = Logic.LeaderGetNumberOfSoldiers(eID);
        -- local SoldiersType = Logic.LeaderGetNumberOfSoldiers(eID);
        -- local Orientation = Logic.GetEntityOrientation(eID);
        -- local EntityName = Logic.GetEntityName(eID);
        -- local x,y,z = Logic.EntityGetPos(eID);
        -- local NewID = Logic.CreateBattalionOnUnblockedLand(SoldiersType, x, y, Orientation, self.Player, SoldiersAmount );
        -- Logic.SetEntityName(NewID, EntityName);
        -- DestroyEntity(eID);
        Logic.ChangeSettlerPlayerID(eID, self.Player);
    else
        Logic.ChangeEntityPlayerID(eID, self.Player);
    end
end

function b_Reprisal_ChangePlayer:GetCustomData(__index_)
    if __index_ == 1 then
        return {"0", "1", "2", "3", "4", "5", "6", "7", "8"}
    end
end

function b_Reprisal_ChangePlayer:DEBUG(__quest_)
    if not IsExisting(self.Entity) then
        dbg(__quest_.Identifier .. " " .. self.Name .. ": entity '"..  self.Entity .. "' does not exist!");
        return true;
    end
    return false;
end

Core:RegisterBehavior(b_Reprisal_ChangePlayer);

-- -------------------------------------------------------------------------- --

---
-- Ändert die Sichtbarkeit eines Entity.
-- 
-- @param _ScriptName Skriptname des Entity
-- @param _Visible    Sichtbarkeit an/aus
-- @return Table mit Behavior
-- @within Reprisal
--
function Reprisal_SetVisible(...)
    return b_Reprisal_SetVisible:new(...)
end

b_Reprisal_SetVisible = {
    Name = "Reprisal_SetVisible",
    Description = {
        en = "Reprisal: Changes the visibility of an entity. If the entity is a spawner the spawned entities will be affected.",
        de = "Strafe: Setzt die Sichtbarkeit einer Entity. Handelt es sich um einen Spawner werden auch die gespawnten Entities beeinflusst.",
    },
    Parameter = {
        { ParameterType.ScriptName, en = "Entity",     de = "Entity", },
        { ParameterType.Custom,     en = "Visible",     de = "Sichtbar", },
    },
}

function b_Reprisal_SetVisible:GetReprisalTable(__quest_)
    return { Reprisal.Custom, { self, self.CustomFunction } }
end

function b_Reprisal_SetVisible:AddParameter( __index_, __parameter_ )
    if (__index_ == 0) then
        self.Entity = __parameter_;
    elseif (__index_ == 1) then
        self.Visible = AcceptAlternativeBoolean(__parameter_)
    end
end

function b_Reprisal_SetVisible:CustomFunction(__quest_)
    if not IsExisting(self.Entity) then
        return;
    end

    local eID = GetID(self.Entity);
    local pID = Logic.EntityGetPlayer(eID);
    local eType = Logic.GetEntityType(eID);
    local tName = Logic.GetEntityTypeName(eType);

    if string.find(tName, "S_") or string.find(tName, "B_NPC_Bandits")
    or string.find(tName, "B_NPC_Barracks") then
        local spawned = {Logic.GetSpawnedEntities(eID)};
        for i=1, #spawned do
            if Logic.IsLeader(spawned[i]) == 1 then
                local soldiers = {Logic.GetSoldiersAttachedToLeader(spawned[i])};
                for j=2, #soldiers do
                    Logic.SetVisible(soldiers[j], self.Visible);
                end
            else
                Logic.SetVisible(spawned[i], self.Visible);
            end
        end
    else
        if Logic.IsLeader(eID) == 1 then
            local soldiers = {Logic.GetSoldiersAttachedToLeader(eID)};
            for j=2, #soldiers do
                Logic.SetVisible(soldiers[j], self.Visible);
            end
        else
            Logic.SetVisible(eID, self.Visible);
        end
    end
end

function b_Reprisal_SetVisible:GetCustomData(__index_)
    if __index_ == 1 then
        return { "true", "false" }
    end
end

function b_Reprisal_SetVisible:DEBUG(__quest_)
    if not IsExisting(self.Entity) then
        dbg(__quest_.Identifier .. " " .. self.Name .. ": entity '"..  self.Entity .. "' does not exist!");
        return true;
    end
    return false;
end

Core:RegisterBehavior(b_Reprisal_SetVisible);

-- -------------------------------------------------------------------------- --

---
-- Macht das Entity verwundbar oder unverwundbar.
--
-- @param _ScriptName Skriptname des Entity
-- @param _Vulnerable Verwundbarkeit an/aus
-- @return Table mit Behavior
-- @within Reprisal
--
function Reprisal_SetVulnerability(...)
    return b_Reprisal_SetVulnerability:new(...);
end

b_Reprisal_SetVulnerability = {
    Name = "Reprisal_SetVulnerability",
    Description = {
        en = "Reprisal: Changes the vulnerability of the entity. If the entity is a spawner the spawned entities will be affected.",
        de = "Vergeltung: Macht eine Entity verwundbar oder unverwundbar. Handelt es sich um einen Spawner, sind die gespawnten Entities betroffen",
    },
    Parameter = {
        { ParameterType.ScriptName, en = "Entity",              de = "Entity", },
        { ParameterType.Custom,     en = "Vulnerability",      de = "Verwundbar", },
    },
}

function b_Reprisal_SetVulnerability:GetReprisalTable(__quest_)
    return { Reprisal.Custom, { self, self.CustomFunction } }
end

function b_Reprisal_SetVulnerability:AddParameter( __index_, __parameter_ )
    if (__index_ == 0) then
        self.Entity = __parameter_;
    elseif (__index_ == 1) then
        self.Vulnerability = AcceptAlternativeBoolean(__parameter_)
    end
end

function b_Reprisal_SetVulnerability:CustomFunction(__quest_)
    if not IsExisting(self.Entity) then
        return;
    end
    local eID = GetID(self.Entity);
    local eType = Logic.GetEntityType(eID);
    local tName = Logic.GetEntityTypeName(eType);
    if self.Vulnerability then
        if string.find(tName, "S_") or string.find(tName, "B_NPC_Bandits")
        or string.find(tName, "B_NPC_Barracks") then
            local spawned = {Logic.GetSpawnedEntities(eID)};
            for i=1, #spawned do
                if Logic.IsLeader(spawned[i]) == 1 then
                    local Soldiers = {Logic.GetSoldiersAttachedToLeader(spawned[i])};
                    for j=2, #Soldiers do
                        MakeVulnerable(Soldiers[j]);
                    end
                end
                MakeVulnerable(spawned[i]);
            end
        else
            MakeVulnerable(self.Entity);
        end
    else
        if string.find(tName, "S_") or string.find(tName, "B_NPC_Bandits")
        or string.find(tName, "B_NPC_Barracks") then
            local spawned = {Logic.GetSpawnedEntities(eID)};
            for i=1, #spawned do
                if Logic.IsLeader(spawned[i]) == 1 then
                    local Soldiers = {Logic.GetSoldiersAttachedToLeader(spawned[i])};
                    for j=2, #Soldiers do
                        MakeInvulnerable(Soldiers[j]);
                    end
                end
                MakeInvulnerable(spawned[i]);
            end
        else
            MakeInvulnerable(self.Entity);
        end
    end
end

function b_Reprisal_SetVulnerability:GetCustomData(__index_)
    if __index_ == 1 then
        return { "true", "false" }
    end
end

function b_Reprisal_SetVulnerability:DEBUG(__quest_)
    if not IsExisting(self.Entity) then
        dbg(__quest_.Identifier .. " " .. self.Name .. ": entity '"..  self.Entity .. "' does not exist!");
        return true;
    end
    return false;
end

Core:RegisterBehavior(b_Reprisal_SetVulnerability);

-- -------------------------------------------------------------------------- --

---
-- Ändert das Model eines Entity.
--
-- In Verbindung mit Reward_SetVisible oder Reprisal_SetVisible können
-- Script Entites ein neues Model erhalten und sichtbar gemacht werden.
-- Das hat den Vorteil, das Script Entities nicht überbaut werden können.
--
-- @param _ScriptName Skriptname des Entity
-- @param _Model      Neues Model
-- @return Table mit Behavior
-- @within Reprisal
--
function Reprisal_SetModel(...)
    return b_Reprisal_SetModel:new(...);
end

b_Reprisal_SetModel = {
    Name = "Reprisal_SetModel",
    Description = {
        en = "Reward: Changes the model of the entity. Be careful, some models crash the game.",
        de = "Lohn: Aendert das Model einer Entity. Achtung: Einige Modelle fuehren zum Absturz.",
    },
    Parameter = {
        { ParameterType.ScriptName, en = "Entity",     de = "Entity", },
        { ParameterType.Custom,     en = "Model",     de = "Model", },
    },
}

function b_Reprisal_SetModel:GetRewardTable(__quest_)
    return { Reward.Custom, { self, self.CustomFunction } }
end

function b_Reprisal_SetModel:AddParameter( __index_, __parameter_ )
    if (__index_ == 0) then
        self.Entity = __parameter_;
    elseif (__index_ == 1) then
        self.Model = __parameter_;
    end
end

function b_Reprisal_SetModel:CustomFunction(__quest_)
    if not IsExisting(self.Entity) then
        return;
    end
    local eID = GetID(self.Entity);
    Logic.SetModel(eID, Models[self.Model]);
end

function b_Reprisal_SetModel:GetCustomData(__index_)
    if __index_ == 1 then
        local Data = {};
        for k,v in pairs(Models) do
            if  not string.find(k,"Animals_") and not string.find(k,"Banners_") and not string.find(k,"Goods_") and not string.find(k,"goods_")
            and not string.find(k,"Heads_") and not string.find(k,"MissionMap_") and not string.find(k,"R_Fish") and not string.find(k,"Units_")
            and not string.find(k,"XD_") and not string.find(k,"XS_") and not string.find(k,"XT_") and not string.find(k,"Z_") then
                table.insert(Data,k);
            end
        end
        return Data;
    end
end

function b_Reprisal_SetModel:DEBUG(__quest_)
    if not IsExisting(self.Entity) then
        dbg(__quest_.Identifier .. " " .. self.Name .. ": entity '"..  self.Entity .. "' does not exist!");
        return true;
    end
    return false;
end

Core:RegisterBehavior(b_Reprisal_SetModel);

-- -------------------------------------------------------------------------- --
-- Rewards                                                                    --
-- -------------------------------------------------------------------------- --

---
-- Ändert die Position eines Siedlers oder eines Gebäudes.
--
-- Optional kann das Entity in einem bestimmten Abstand zum Ziel platziert
-- werden und das Ziel anschauen. Die Entfernung darf nicht kleiner sein
-- als 50!
--
-- @param _ScriptName Skriptname des Entity
-- @param _Target     Skriptname des Ziels
-- @param _LookAt     Gegenüberstellen
-- @param _Distance   Relative Entfernung (nur mit _LookAt)
-- @return Table mit Behavior
-- @within Reward
--
function Reward_SetPosition(...)
    return b_Reward_SetPosition:new(...);
end

b_Reward_SetPosition = API.InstanceTable(b_Reprisal_SetPosition);
b_Reward_SetPosition.Name = "Reward_SetPosition";
b_Reward_SetPosition.Description.en = "Reward: Places an entity relative to the position of another. The entity can look the target.";
b_Reward_SetPosition.Description.de = "Lohn: Setzt eine Entity relativ zur Position einer anderen. Die Entity kann zum Ziel ausgerichtet werden.";
b_Reward_SetPosition.GetReprisalTable = nil;

b_Reward_SetPosition.GetRewardTable = function(self, __quest_)
    return { Reward.Custom, { self, self.CustomFunction } }
end

Core:RegisterBehavior(b_Reward_SetPosition);

-- -------------------------------------------------------------------------- --

---
-- Ändert den Eigentümer des Entity oder des Battalions.
-- 
-- @param _ScriptName Skriptname des Entity
-- @param _NewOwner   PlayerID des Eigentümers
-- @return Table mit Behavior
-- @within Reward
--
function Reprisal_ChangePlayer(...)
    return b_Reprisal_ChangePlayer:new(...)
end

b_Reward_ChangePlayer = API.InstanceTable(b_Reprisal_ChangePlayer);
b_Reward_ChangePlayer.Name = "Reward_ChangePlayer";
b_Reward_ChangePlayer.Description.en = "Reward: Changes the owner of the entity or a battalion.";
b_Reward_ChangePlayer.Description.de = "Lohn: Aendert den Besitzer einer Entity oder eines Battalions.";
b_Reward_ChangePlayer.GetReprisalTable = nil;

b_Reward_ChangePlayer.GetRewardTable = function(self, __quest_)
    return { Reward.Custom, { self, self.CustomFunction } }
end

Core:RegisterBehavior(b_Reward_ChangePlayer);

-- -------------------------------------------------------------------------- --

---
-- Bewegt einen Siedler relativ zu einem Zielpunkt.
--
-- Der Siedler wird sich zum Ziel ausrichten und in der angegeben Distanz
-- und dem angegebenen Winkel Position beziehen.
--
-- <b>Hinweis:</b> Funktioniert ähnlich wie MoveEntityToPositionToAnotherOne.
--
-- @param _ScriptName  Skriptname des Entity
-- @param _Destination Skriptname des Ziels
-- @param _Distance    Entfernung
-- @param _Angle       Winkel
-- @return Table mit Behavior
-- @within Reward
--
function Reward_MoveToPosition(...)
    return b_Reward_MoveToPosition:new(...);
end

b_Reward_MoveToPosition = {
    Name = "Reward_MoveToPosition",
    Description = {
        en = "Reward: Moves an entity relative to another entity. If angle is zero the entities will be standing directly face to face.",
        de = "Lohn: Bewegt eine Entity relativ zur Position einer anderen. Wenn Winkel 0 ist, stehen sich die Entities direkt gegen�ber.",
    },
    Parameter = {
        { ParameterType.ScriptName, en = "Settler", de = "Siedler" },
        { ParameterType.ScriptName, en = "Destination", de = "Ziel" },
        { ParameterType.Number,     en = "Distance", de = "Entfernung" },
        { ParameterType.Number,     en = "Angle", de = "Winkel" },
    },
}

function b_Reward_MoveToPosition:GetRewardTable(__quest_)
    return { Reward.Custom, {self, self.CustomFunction} }
end

function b_Reward_MoveToPosition:AddParameter(__index_, __parameter_)
    if (__index_ == 0) then
        self.Entity = __parameter_;
    elseif (__index_ == 1) then
        self.Target = __parameter_;
    elseif (__index_ == 2) then
        self.Distance = __parameter_ * 1;
    elseif (__index_ == 3) then
        self.Angle = __parameter_ * 1;
    end
end

function b_Reward_MoveToPosition:CustomFunction(__quest_)
    if not IsExisting(self.Entity) or not IsExisting(self.Target) then
        return;
    end
    self.Angle = self.Angle or 0;

    local entity = GetID(self.Entity);
    local target = GetID(self.Target);
    local orientation = Logic.GetEntityOrientation(target);
    local x,y,z = Logic.EntityGetPos(target);
    if Logic.IsBuilding(target) == 1 then
        x, y = Logic.GetBuildingApproachPosition(target);
        orientation = orientation -90;
    end
    x = x + self.Distance * math.cos( math.rad(orientation+self.Angle) );
    y = y + self.Distance * math.sin( math.rad(orientation+self.Angle) );
    Logic.MoveSettler(entity, x, y);
    StartSimpleJobEx( function(_entityID, _targetID)
        if Logic.IsEntityMoving(_entityID) == false then
            LookAt(_entityID, _targetID);
            return true;
        end
    end, entity, target);
end

function b_Reward_MoveToPosition:DEBUG(__quest_)
    if tonumber(self.Distance) == nil or self.Distance < 50 then
        dbg(__quest_.Identifier.. " " ..self.Name.. ": Reward_MoveToPosition: Distance is nil or to short!");
        return true;
    elseif not IsExisting(self.Entity) or not IsExisting(self.Target) then
        dbg(__quest_.Identifier.. " " ..self.Name.. ": Reward_MoveToPosition: Mover entity or target entity does not exist!");
        return true;
    end
    return false;
end

Core:RegisterBehavior(b_Reward_MoveToPosition);

-- -------------------------------------------------------------------------- --

---
-- Der Spieler gewinnt das Spiel mit einem animierten Siegesfest.
--
-- Es ist nicht möglich weiterzuspielen!
--
-- @return Table mit Behavior
-- @within Reprisal
--
function Reward_VictoryWithParty()
    return b_Reward_VictoryWithParty:new();
end

b_Reward_VictoryWithParty = {
    Name = "Reward_VictoryWithParty",
    Description = {
        en = "Reward: The player wins the game with an animated festival on the market.",
        de = "Lohn: Der Spieler gewinnt das Spiel mit einer animierten Siegesfeier.",
    },
    Parameter =    {}
};

function b_Reward_VictoryWithParty:GetRewardTable()
    return {Reward.Custom, {self, self.CustomFunction}};
end

function b_Reward_VictoryWithParty:AddParameter(__index_, __parameter_)
end

function b_Reward_VictoryWithParty:CustomFunction(__quest_)
    Victory(g_VictoryAndDefeatType.VictoryMissionComplete);
    local pID = __quest_.ReceivingPlayer;

    local market = Logic.GetMarketplace(pID);
    if IsExisting(market) then
        local pos = GetPosition(market)
        Logic.CreateEffect(EGL_Effects.FXFireworks01,pos.X,pos.Y,0);
        Logic.CreateEffect(EGL_Effects.FXFireworks02,pos.X,pos.Y,0);

        local PossibleSettlerTypes = {
            Entities.U_SmokeHouseWorker,
            Entities.U_Butcher,
            Entities.U_Carpenter,
            Entities.U_Tanner,
            Entities.U_Blacksmith,
            Entities.U_CandleMaker,
            Entities.U_Baker,
            Entities.U_DairyWorker,

            Entities.U_SpouseS01,
            Entities.U_SpouseS02,
            Entities.U_SpouseS02,
            Entities.U_SpouseS03,
            Entities.U_SpouseF01,
            Entities.U_SpouseF01,
            Entities.U_SpouseF02,
            Entities.U_SpouseF03,
        };
        VictoryGenerateFestivalAtPlayer(pID, PossibleSettlerTypes);

        Logic.ExecuteInLuaLocalState([[
            if IsExisting(]]..market..[[) then
                CameraAnimation.AllowAbort = false
                CameraAnimation.QueueAnimation( CameraAnimation.SetCameraToEntity, ]]..market..[[)
                CameraAnimation.QueueAnimation( CameraAnimation.StartCameraRotation,  5 )
                CameraAnimation.QueueAnimation( CameraAnimation.Stay ,  9999 )
            end
            XGUIEng.ShowWidget("/InGame/InGame/MissionEndScreen/ContinuePlaying", 0);
        ]]);
    end
end

function b_Reward_VictoryWithParty:DEBUG(__quest_)
    return false;
end

Core:RegisterBehavior(b_Reward_VictoryWithParty)

-- -------------------------------------------------------------------------- --

---
-- Ändert die Sichtbarkeit eines Entity.
-- 
-- @param _ScriptName Skriptname des Entity
-- @param _Visible    Sichtbarkeit an/aus
-- @return Table mit Behavior
-- @within Reprisal
--
function Reward_SetVisible(...)
    return b_Reward_SetVisible:new(...)
end

b_Reward_SetVisible = API.InstanceTable(b_Reprisal_SetVisible);
b_Reward_SetVisible.Name = "Reward_ChangePlayer";
b_Reward_SetVisible.Description.en = "Reward: Changes the visibility of an entity. If the entity is a spawner the spawned entities will be affected.";
b_Reward_SetVisible.Description.de = "Lohn: Setzt die Sichtbarkeit einer Entity. Handelt es sich um einen Spawner werden auch die gespawnten Entities beeinflusst.";
b_Reward_SetVisible.GetReprisalTable = nil;

b_Reward_SetVisible.GetRewardTable = function(self, __quest_)
    return { Reward.Custom, { self, self.CustomFunction } }
end

Core:RegisterBehavior(b_Reward_SetVisible);

-- -------------------------------------------------------------------------- --

---
-- Gibt oder entzieht einem KI-Spieler die Kontrolle über ein Entity.
--
-- @param _ScriptName Skriptname des Entity
-- @param _Controlled Durch KI kontrollieren an/aus
-- @return Table mit Behavior
-- @within Reward
--
function Reward_AI_SetEntityControlled(...)
    return b_Reward_AI_SetEntityControlled:new(...);
end

b_Reward_AI_SetEntityControlled = {
    Name = "Reward_AI_SetEntityControlled",
    Description = {
        en = "Reward: Bind or Unbind an entity or a battalion to/from an AI player. The AI player must be activated!",
        de = "Lohn: Die KI kontrolliert die Entity oder der KI die Kontrolle entziehen. Die KI muss aktiv sein!",
    },
    Parameter = {
        { ParameterType.ScriptName, en = "Entity",               de = "Entity", },
        { ParameterType.Custom,     en = "AI control entity", de = "KI kontrolliert Entity", },
    },
}

function b_Reward_AI_SetEntityControlled:GetRewardTable(__quest_)
    return { Reward.Custom, { self, self.CustomFunction } }
end

function b_Reward_AI_SetEntityControlled:AddParameter( __index_, __parameter_ )
    if (__index_ == 0) then
        self.Entity = __parameter_;
    elseif (__index_ == 1) then
        self.Hidden = AcceptAlternativeBoolean(__parameter_)
    end
end

function b_Reward_AI_SetEntityControlled:CustomFunction(__quest_)
    if not IsExisting(self.Entity) then
        return;
    end
    local eID = GetID(self.Entity);
    local pID = Logic.EntityGetPlayer(eID);
    local eType = Logic.GetEntityType(eID);
    local tName = Logic.GetEntityTypeName(eType);
    if string.find(tName, "S_") or string.find(tName, "B_NPC_Bandits")
    or string.find(tName, "B_NPC_Barracks") then
        local spawned = {Logic.GetSpawnedEntities(eID)};
        for i=1, #spawned do
            if Logic.IsLeader(spawned[i]) == 1 then
                AICore.HideEntityFromAI(pID, spawned[i], not self.Hidden);
            end
        end
    else
        AICore.HideEntityFromAI(pID, eID, not self.Hidden);
    end
end

function b_Reward_AI_SetEntityControlled:GetCustomData(__index_)
    if __index_ == 1 then
        return { "false", "true" }
    end
end

function b_Reward_AI_SetEntityControlled:DEBUG(__quest_)
    if not IsExisting(self.Entity) then
        dbg(__quest_.Identifier .. " " .. self.Name .. ": entity '"..  self.Entity .. "' does not exist!");
        return true;
    end
    return false;
end

Core:RegisterBehavior(b_Reward_AI_SetEntityControlled);

-- -------------------------------------------------------------------------- --

---
-- Macht das Entity verwundbar oder unverwundbar.
--
-- @param _ScriptName Skriptname des Entity
-- @param _Vulnerable Verwundbarkeit an/aus
-- @return Table mit Behavior
-- @within Reward
--
function Reward_SetVulnerability(...)
    return b_Reward_SetVulnerability:new(...);
end

b_Reward_SetVulnerability = API.InstanceTable(b_Reprisal_SetVulnerability);
b_Reward_SetVulnerability.Name = "Reward_SetVulnerability";
b_Reward_SetVulnerability.Description.en = "Reward: Changes the vulnerability of the entity. If the entity is a spawner the spawned entities will be affected.";
b_Reward_SetVulnerability.Description.de = "Lohn: Macht eine Entity verwundbar oder unverwundbar. Handelt es sich um einen Spawner, sind die gespawnten Entities betroffen.";
b_Reward_SetVulnerability.GetReprisalTable = nil;

b_Reward_SetVulnerability.GetRewardTable = function(self, __quest_)
    return { Reward.Custom, { self, self.CustomFunction } }
end

Core:RegisterBehavior(b_Reward_SetVulnerability);

-- -------------------------------------------------------------------------- --

---
-- Ändert das Model eines Entity.
--
-- In Verbindung mit Reward_SetVisible oder Reprisal_SetVisible können
-- Script Entites ein neues Model erhalten und sichtbar gemacht werden.
-- Das hat den Vorteil, das Script Entities nicht überbaut werden können.
--
-- @param _ScriptName Skriptname des Entity
-- @param _Model      Neues Model
-- @return Table mit Behavior
-- @within Reward
--
function Reward_SetModel(...)
    return b_Reward_SetModel:new(...);
end

b_Reward_SetModel = API.InstanceTable(b_Reprisal_SetModel);
b_Reward_SetModel.Name = "Reward_SetModel";
b_Reward_SetModel.Description.en = "Reward: Changes the model of the entity. Be careful, some models crash the game.";
b_Reward_SetModel.Description.de = "Lohn: Aendert das Model einer Entity. Achtung: Einige Modelle fuehren zum Absturz.";
b_Reward_SetModel.GetReprisalTable = nil;

b_Reward_SetModel.GetRewardTable = function(self, __quest_)
    return { Reward.Custom, { self, self.CustomFunction } }
end

Core:RegisterBehavior(b_Reward_SetModel);

-- -------------------------------------------------------------------------- --

---
-- Füllt die Munition in der Kriegsmaschine vollständig auf.
--
-- @param _ScriptName Skriptname des Entity
-- @return Table mit Behavior
-- @within Reward
--
function Reward_RefillAmmunition(...)
    return b_Reward_RefillAmmunition:new(...);
end

b_Reward_RefillAmmunition = {
    Name = "Reward_RefillAmmunition",
    Description = {
        en = "Reward: Refills completely the ammunition of the entity.",
        de = "Lohn: Fuellt die Munition der Entity vollständig auf.",
    },
    Parameter = {
        { ParameterType.ScriptName, en = "Script name", de = "Skriptname" },
    },
}

function b_Reward_RefillAmmunition:GetRewardTable()
    return { Reward.Custom, {self, self.CustomFunction} }
end

function b_Reward_RefillAmmunition:AddParameter(_Index, _Parameter)
    if (_Index == 0) then
        self.Scriptname = _Parameter
    end
end

function b_Reward_RefillAmmunition:CustomFunction()
    local EntityID = GetID(self.Scriptname);
    if not IsExisting(EntityID) then
        return;
    end

    local Ammunition = Logic.GetAmmunitionAmount(EntityID);
    while (Ammunition < 10)
    do
        Logic.RefillAmmunitions(EntityID);
        Ammunition = Logic.GetAmmunitionAmount(EntityID);
    end
end

function b_Reward_RefillAmmunition:DEBUG(_Quest)
    if not IsExisting(self.Scriptname) then
        dbg(_Quest.Identifier .. ": Error in " .. self.Name .. ": '"..self.Scriptname.."' is destroyed!");
        return true
    end
    return false;
end

Core:RegisterBehavior(b_Reward_RefillAmmunition)

-- -------------------------------------------------------------------------- --
-- Trigger                                                                    --
-- -------------------------------------------------------------------------- --

---
-- Startet den Quest, sobald mindestens X von Y Quests fehlgeschlagen sind.
--
-- @param _MinAmount Mindestens zu verlieren (max. 5)
-- @param _QuestAmount Anzahl geprüfter Quests (max. 5 und >= _MinAmount)
-- @param _Quest1      Name des 1. Quest
-- @param _Quest2      Name des 2. Quest
-- @param _Quest3      Name des 3. Quest
-- @param _Quest4      Name des 4. Quest
-- @param _Quest5      Name des 5. Quest
-- @return Table mit Behavior
-- @within Trigger
--
function Trigger_OnAtLeastXOfYQuestsFailed(...)
    return b_Trigger_OnAtLeastXOfYQuestsFailed:new(...);
end

b_Trigger_OnAtLeastXOfYQuestsFailed = {
    Name = "Trigger_OnAtLeastXOfYQuestsFailed",
    Description = {
        en = "Trigger: if at least X of Y given quests has been finished successfully.",
        de = "Ausloeser: wenn X von Y angegebener Quests fehlgeschlagen sind.",
    },
    Parameter = {
        { ParameterType.Custom, en = "Least Amount", de = "Mindest Anzahl" },
        { ParameterType.Custom, en = "Quest Amount", de = "Quest Anzahl" },
        { ParameterType.QuestName, en = "Quest name 1", de = "Questname 1" },
        { ParameterType.QuestName, en = "Quest name 2", de = "Questname 2" },
        { ParameterType.QuestName, en = "Quest name 3", de = "Questname 3" },
        { ParameterType.QuestName, en = "Quest name 4", de = "Questname 4" },
        { ParameterType.QuestName, en = "Quest name 5", de = "Questname 5" },
    },
}

function b_Trigger_OnAtLeastXOfYQuestsFailed:GetTriggerTable()
    return { Triggers.Custom2,{self, self.CustomFunction} }
end

function b_Trigger_OnAtLeastXOfYQuestsFailed:AddParameter(_Index, _Parameter)
    if (_Index == 0) then
        self.LeastAmount = tonumber(_Parameter)
    elseif (_Index == 1) then
        self.QuestAmount = tonumber(_Parameter)
    elseif (_Index == 2) then
        self.QuestName1 = _Parameter
    elseif (_Index == 3) then
        self.QuestName2 = _Parameter
    elseif (_Index == 4) then
        self.QuestName3 = _Parameter
    elseif (_Index == 5) then
        self.QuestName4 = _Parameter
    elseif (_Index == 6) then
        self.QuestName5 = _Parameter
    end
end

function b_Trigger_OnAtLeastXOfYQuestsFailed:CustomFunction()
    local least = 0
    for i = 1, self.QuestAmount do
		local QuestID = GetQuestID(self["QuestName"..i]);
        if IsValidQuest(QuestID) then
			if (Quests[QuestID].Result == QuestResult.Failure) then
				least = least + 1
				if least >= self.LeastAmount then
					return true
				end
			end
        end
    end
    return false
end

function b_Trigger_OnAtLeastXOfYQuestsFailed:DEBUG(_Quest)
    local leastAmount = self.LeastAmount
    local questAmount = self.QuestAmount
    if leastAmount <= 0 or leastAmount >5 then
        dbg(_Quest.Identifier .. ": Error in " .. self.Name .. ": LeastAmount is wrong")
        return true
    elseif questAmount <= 0 or questAmount > 5 then
        dbg(_Quest.Identifier .. ": Error in " .. self.Name .. ": QuestAmount is wrong")
        return true
    elseif leastAmount > questAmount then
        dbg(_Quest.Identifier .. ": Error in " .. self.Name .. ": LeastAmount is greater than QuestAmount")
        return true
    end
    for i = 1, questAmount do
        if not IsValidQuest(self["QuestName"..i]) then
            dbg(_Quest.Identifier .. ": Error in " .. self.Name .. ": Quest ".. self["QuestName"..i] .. " not found")
            return true
        end
    end
    return false
end

function b_Trigger_OnAtLeastXOfYQuestsFailed:GetCustomData(_Index)
    if (_Index == 0) or (_Index == 1) then
        return {"1", "2", "3", "4", "5"}
    end
end

Core:RegisterBehavior(b_Trigger_OnAtLeastXOfYQuestsFailed)

-- -------------------------------------------------------------------------- --

---
-- Startet den Quest, sobald die Munition in der Kriegsmaschine erschöpft ist.
--
-- @param _ScriptName Skriptname des Entity
-- @return Table mit Behavior
-- @within Trigger
--
function Trigger_AmmunitionDepleted(...)
    return b_Trigger_AmmunitionDepleted:new(...);
end

b_Trigger_AmmunitionDepleted = {
    Name = "Trigger_AmmunitionDepleted",
    Description = {
        en = "Trigger: if the ammunition of the entity is depleted.",
        de = "Ausloeser: wenn die Munition der Entity aufgebraucht ist.",
    },
    Parameter = {
        { ParameterType.Scriptname, en = "Script name", de = "Skriptname" },
    },
}

function b_Trigger_AmmunitionDepleted:GetTriggerTable()
    return { Triggers.Custom2,{self, self.CustomFunction} }
end

function b_Trigger_AmmunitionDepleted:AddParameter(_Index, _Parameter)
    if (_Index == 0) then
        self.Scriptname = _Parameter
    end
end

function b_Trigger_AmmunitionDepleted:CustomFunction()
    if not IsExisting(self.Scriptname) then
        return false;
    end

    local EntityID = GetID(self.Scriptname);
    if Logic.GetAmmunitionAmount(EntityID) > 0 then
        return false;
    end

    return true;
end

function b_Trigger_AmmunitionDepleted:DEBUG(_Quest)
    if not IsExisting(self.Scriptname) then
        dbg(_Quest.Identifier .. ": Error in " .. self.Name .. ": '"..self.Scriptname.."' is destroyed!");
        return true
    end
    return false
end

Core:RegisterBehavior(b_Trigger_AmmunitionDepleted)

-- -------------------------------------------------------------------------- --

---
-- Startet den Quest, wenn exakt einer von beiden Quests erfolgreich ist.
--
-- @param _QuestName1 Name des ersten Quest
-- @param _QuestName2 Name des zweiten Quest
-- @return Table mit Behavior
-- @within Trigger
--
function Trigger_OnExactOneQuestIsWon(...)
    return b_Trigger_OnExactOneQuestIsWon:new(...);
end

b_Trigger_OnExactOneQuestIsWon = {
    Name = "Trigger_OnExactOneQuestIsWon",
    Description = {
        en = "Trigger: if one of two given quests has been finished successfully, but NOT both.",
        de = "Ausloeser: wenn eine von zwei angegebenen Quests (aber NICHT beide) erfolgreich abgeschlossen wurde.",
    },
    Parameter = {
        { ParameterType.QuestName, en = "Quest Name 1", de = "Questname 1" },
        { ParameterType.QuestName, en = "Quest Name 2", de = "Questname 2" },
    },
}

function b_Trigger_OnExactOneQuestIsWon:GetTriggerTable(__quest_)
    return {Triggers.Custom2, {self, self.CustomFunction}};
end

function b_Trigger_OnExactOneQuestIsWon:AddParameter(__index_, __parameter_)
    self.QuestTable = {};

    if (__index_ == 0) then
        self.Quest1 = __parameter_;
    elseif (__index_ == 1) then
        self.Quest2 = __parameter_;
    end
end

function b_Trigger_OnExactOneQuestIsWon:CustomFunction(__quest_)
    local Quest1 = Quests[GetQuestID(self.Quest1)];
    local Quest2 = Quests[GetQuestID(self.Quest2)];
    if Quest2 and Quest1 then
        local Quest1Succeed = (Quest1.State == QuestState.Over and Quest1.Result == QuestResult.Success);
        local Quest2Succeed = (Quest2.State == QuestState.Over and Quest2.Result == QuestResult.Success);
        if (Quest1Succeed and not Quest2Succeed) or (not Quest1Succeed and Quest2Succeed) then
            return true;
        end
    end
    return false;
end

function b_Trigger_OnExactOneQuestIsWon:DEBUG(__quest_)
    if self.Quest1 == self.Quest2 then
        dbg(__quest_.Identifier..": "..self.Name..": Both quests are identical!");
        return true;
    elseif not IsValidQuest(self.Quest1) then
        dbg(__quest_.Identifier..": "..self.Name..": Quest '"..self.Quest1.."' does not exist!");
        return true;
    elseif not IsValidQuest(self.Quest2) then
        dbg(__quest_.Identifier..": "..self.Name..": Quest '"..self.Quest2.."' does not exist!");
        return true;
    end
    return false;
end

Core:RegisterBehavior(b_Trigger_OnExactOneQuestIsWon);

-- -------------------------------------------------------------------------- --

---
-- Startet den Quest, wenn exakt einer von beiden Quests erfolgreich ist.
--
-- @param _QuestName1 Name des ersten Quest
-- @param _QuestName2 Name des zweiten Quest
-- @return Table mit Behavior
-- @within Trigger
--
function Trigger_OnExactOneQuestIsLost(...)
    return b_Trigger_OnExactOneQuestIsLost:new(...);
end

b_Trigger_OnExactOneQuestIsLost = {
    Name = "Trigger_OnExactOneQuestIsLost",
    Description = {
        en = "Trigger: If one of two given quests has been lost, but NOT both.",
        de = "Ausloeser: Wenn einer von zwei angegebenen Quests (aber NICHT beide) fehlschlägt.",
    },
    Parameter = {
        { ParameterType.QuestName, en = "Quest Name 1", de = "Questname 1" },
        { ParameterType.QuestName, en = "Quest Name 2", de = "Questname 2" },
    },
}

function b_Trigger_OnExactOneQuestIsLost:GetTriggerTable(__quest_)
    return {Triggers.Custom2, {self, self.CustomFunction}};
end

function b_Trigger_OnExactOneQuestIsLost:AddParameter(__index_, __parameter_)
    self.QuestTable = {};

    if (__index_ == 0) then
        self.Quest1 = __parameter_;
    elseif (__index_ == 1) then
        self.Quest2 = __parameter_;
    end
end

function b_Trigger_OnExactOneQuestIsLost:CustomFunction(__quest_)
    local Quest1 = Quests[GetQuestID(self.Quest1)];
    local Quest2 = Quests[GetQuestID(self.Quest2)];
    if Quest2 and Quest1 then
        local Quest1Succeed = (Quest1.State == QuestState.Over and Quest1.Result == QuestResult.Failure);
        local Quest2Succeed = (Quest2.State == QuestState.Over and Quest2.Result == QuestResult.Failure);
        if (Quest1Succeed and not Quest2Succeed) or (not Quest1Succeed and Quest2Succeed) then
            return true;
        end
    end
    return false;
end

function b_Trigger_OnExactOneQuestIsLost:DEBUG(__quest_)
    if self.Quest1 == self.Quest2 then
        dbg(__quest_.Identifier..": "..self.Name..": Both quests are identical!");
        return true;
    elseif not IsValidQuest(self.Quest1) then
        dbg(__quest_.Identifier..": "..self.Name..": Quest '"..self.Quest1.."' does not exist!");
        return true;
    elseif not IsValidQuest(self.Quest2) then
        dbg(__quest_.Identifier..": "..self.Name..": Quest '"..self.Quest2.."' does not exist!");
        return true;
    end
    return false;
end

Core:RegisterBehavior(b_Trigger_OnExactOneQuestIsWon);

-- -------------------------------------------------------------------------- --
-- Application-Space                                                          --
-- -------------------------------------------------------------------------- --

BundleSymfoniaBehaviors = {
    Global = {},
    Local = {}
};

-- Global Script ---------------------------------------------------------------

---
-- Initialisiert das Bundle im globalen Skript.
-- @within Application-Space
-- @local
--
function BundleSymfoniaBehaviors.Global:Install()
    --~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    -- Theif observation
    --~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    GameCallback_OnThiefDeliverEarnings_Orig_QSB_SymfoniaBehaviors = GameCallback_OnThiefDeliverEarnings;
    GameCallback_OnThiefDeliverEarnings = function(_ThiefPlayerID, _ThiefID, _BuildingID, _GoodAmount)
        GameCallback_OnThiefDeliverEarnings_Orig_QSB_SymfoniaBehaviors(_ThiefPlayerID, _ThiefID, _BuildingID, _GoodAmount);

        for i=1, Quests[0] do
            if Quests[i] and Quests[i].State == QuestState.Active then
                for j=1, Quests[i].Objectives[0] do
                    if Quests[i].Objectives[j].Type == Objective.Custom2 then
                        if Quests[i].Objectives[j].Data[1].Name == "Goal_StealBuilding" then
                            local found;
                            for k=1, #Quests[i].Objectives[j].Data[1].RobberList do
                                local stohlen = Quests[i].Objectives[j].Data[1].RobberList[k];
                                if stohlen[1] == GetID(Quests[i].Objectives[j].Data[1].Building) and stohlen[2] == _ThiefID then
                                    found = true;
                                    break;
                                end
                            end
                            if found then
                                Quests[i].Objectives[j].Data[1].SuccessfullyStohlen = true;
                            end

                        elseif Quests[i].Objectives[j].Data[1].Name == "Goal_StealGold" then
                            Quests[i].Objectives[j].Data[1].StohlenGold = Quests[i].Objectives[j].Data[1].StohlenGold + _GoodAmount;
                            if Quests[i].Objectives[j].Data[1].Printout then
                                local lang = (Network.GetDesiredLanguage() == "de" and "de") or "en";
                                local msg  = {de = "Talern gestohlen",en = "gold stolen",};
                                local curr = Quests[i].Objectives[j].Data[1].StohlenGold;
                                local need = Quests[i].Objectives[j].Data[1].Amount;
                                API.Note(string.format("%d/%d %s", curr, need, msg[lang]));
                            end
                        end
                    end
                end
            end
        end
    end

    GameCallback_OnThiefStealBuilding_Orig_QSB_SymfoniaBehaviors = GameCallback_OnThiefStealBuilding;
    GameCallback_OnThiefStealBuilding = function(_ThiefID, _ThiefPlayerID, _BuildingID, _BuildingPlayerID)
        GameCallback_OnThiefStealBuilding_Orig_QSB_SymfoniaBehaviors(_ThiefID, _ThiefPlayerID, _BuildingID, _BuildingPlayerID);

        for i=1, Quests[0] do
            if Quests[i] and Quests[i].State == QuestState.Active then
                for j=1, Quests[i].Objectives[0] do
                    if Quests[i].Objectives[j].Type == Objective.Custom2 then
                        if Quests[i].Objectives[j].Data[1].Name == "Goal_Infiltrate" then
                            if  GetID(Quests[i].Objectives[j].Data[1].Building) == _BuildingID and Quests[i].ReceivingPlayer == _ThiefPlayerID then
                                Quests[i].Objectives[j].Data[1].Infiltrated = true;
                                if Quests[i].Objectives[j].Data[1].Delete then
                                    DestroyEntity(_ThiefID);
                                end
                            end

                        elseif Quests[i].Objectives[j].Data[1].Name == "Goal_StealBuilding" then
                            local found;
                            local isCathedral = Logic.IsEntityInCategory(_BuildingID, EntityCategories.Cathedrals) == 1;
                            local isWarehouse = Logic.GetEntityType(_BuildingID) == Entities.B_StoreHouse;
                            if isWarehouse or isCathedral then
                                Quests[i].Objectives[j].Data[1].SuccessfullyStohlen = true;
                            else
                                for k=1, #Quests[i].Objectives[j].Data[1].RobberList do
                                    local stohlen = Quests[i].Objectives[j].Data[1].RobberList[k];
                                    if stohlen[1] == _BuildingID and stohlen[2] == _ThiefID then
                                        found = true;
                                        break;
                                    end
                                end
                            end
                            if not found then
                                table.insert(Quests[i].Objectives[j].Data[1].RobberList, {_BuildingID, _ThiefID});
                            end
                        end
                    end
                end
            end
        end
    end

    --~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    -- Objectives
    --~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    QuestTemplate.IsObjectiveCompleted_Orig_QSB_SymfoniaBehaviors = QuestTemplate.IsObjectiveCompleted;
    QuestTemplate.IsObjectiveCompleted = function(self, objective)
        local objectiveType = objective.Type;
        local data = objective.Data;

        if objective.Completed ~= nil then
            return objective.Completed;
        end

        if objectiveType == Objective.Distance then

            -- Distance with parameter
            local IDdata2 = GetID(data[1]);
            local IDdata3 = GetID(data[2]);
            data[3] = data[3] or 2500;
            if not (Logic.IsEntityDestroyed(IDdata2) or Logic.IsEntityDestroyed(IDdata3)) then
                if Logic.GetDistanceBetweenEntities(IDdata2,IDdata3) <= data[3] then
                    DestroyQuestMarker(IDdata3);
                    objective.Completed = true;
                end
            else
                DestroyQuestMarker(IDdata3);
                objective.Completed = false;
            end
        else
            return self:IsObjectiveCompleted_Orig_QSB_SymfoniaBehaviors(objective);
        end
    end

    --~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    -- Questmarkers
    --~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    function QuestTemplate:RemoveQuestMarkers()
        for i=1, self.Objectives[0] do
            if self.Objectives[i].Type == Objective.Distance then
                if self.Objectives[i].Data[4] then
                    DestroyQuestMarker(self.Objectives[i].Data[2]);
                end
            end
        end
    end

    function QuestTemplate:ShowQuestMarkers()
        for i=1, self.Objectives[0] do
            if self.Objectives[i].Type == Objective.Distance then
                if self.Objectives[i].Data[4] then
                    ShowQuestMarker(self.Objectives[i].Data[2]);
                end
            end
        end
    end

    function ShowQuestMarker(_Entity)
        local eID = GetID(_Entity);
        local x,y = Logic.GetEntityPosition(eID);
        local Marker = EGL_Effects.E_Questmarker_low;
        if Logic.IsBuilding(eID) == 1 then
            Marker = EGL_Effects.E_Questmarker;
        end
        Questmarkers[eID] = Logic.CreateEffect(Marker, x,y,0);
    end

    function DestroyQuestMarker(_Entity)
        local eID = GetID(_Entity);
        if Questmarkers[eID] ~= nil then
            Logic.DestroyEffect(Questmarkers[eID]);
            Questmarkers[eID] = nil;
        end
    end
end

-- Local Script ----------------------------------------------------------------

---
-- Initialisiert das Bundle im lokalen Skript.
-- @within Application-Space
-- @local
--
function BundleSymfoniaBehaviors.Local:Install()

end

Core:RegisterBundle("BundleSymfoniaBehaviors");

-- -------------------------------------------------------------------------- --
-- ########################################################################## --
-- #  Symfonia BundleQuestGeneration                                        # --
-- ########################################################################## --
-- -------------------------------------------------------------------------- --

---
-- Mit diesem Bundle können Aufträge per Skript erstellt werden.
--
-- @module BundleQuestGeneration
-- @set sort=true
--

API = API or {};
QSB = QSB or {};

-- -------------------------------------------------------------------------- --
-- User-Space                                                                 --
-- -------------------------------------------------------------------------- --

---
-- Erstellt einen Quest, startet ihn jedoch noch nicht.
--
-- <b>Alias:</b> AddQuest
--
-- Ein Quest braucht immer wenigstens ein Goal und einen Trigger. Hat ein Quest
-- keinen Namen, erhält er automatisch einen mit fortlaufender Nummerierung.
--
-- Ein Quest besteht aus verschiedenen Parametern und Behavior, die nicht
-- alle zwingend gesetzt werden müssen. Behavior werden einfach nach den
-- Feldern nacheinander aufgerufen.
-- <p><u>Parameter:</u></p>
-- <ul>
-- <li>Name: Der eindeutige Name des Quests</li>
-- <li>Sender: PlayerID des Auftraggeber (Default 1)</li>
-- <li>Receiver: PlayerID des Auftragnehmer (Default 1)</li>
-- <li>Suggestion: Vorschlagnachricht des Quests</li>
-- <li>Success: Erfolgsnachricht des Quest</li>
-- <li>Failure: Fehlschlagnachricht des Quest</li>
-- <li>Description: Aufgabenbeschreibung (Nur bei Custom)</li>
-- <li>Time: Zeit bis zu, Fehlschlag</li>
-- <li>Loop: Funktion, die während der Laufzeit des Quests aufgerufen wird</li>
-- <li>Callback: Funktion, die nach Abschluss aufgerufen wird</li>
-- </ul>
--
-- @param _Data Questdefinition
-- @within User-Space
--
function API.AddQuest(_Data)
    if GUI then
        API.Log("Could not execute API.AddQuest in local script!");
        return;
    end
    return BundleQuestGeneration.Global:NewQuest(_Data);
end
AddQuest = API.AddQuest;

---
-- Startet alle mittels API.AddQuest initalisierten Quests.
--
-- @within User-Space
--
function API.StartQuests()
    if GUI then
        API.Brudge("API.StartQuests()");
        return;
    end
    return BundleQuestGeneration.Global:StartQuests();
end
StartQuests = API.StartQuests;

-- -------------------------------------------------------------------------- --
-- Application-Space                                                          --
-- -------------------------------------------------------------------------- --

BundleQuestGeneration = {
    Global = {
        Data = {
            GenerationList = {},
        }
    },
    Local = {
        Data = {}
    },
}

BundleQuestGeneration.Global.Data.QuestTemplate = {
    MSGKeyOverwrite = nil;
    IconOverwrite   = nil;
    Loop            = nil;
    Callback        = nil;
    SuggestionText  = nil;
    SuccessText     = nil;
    FailureText     = nil;
    Description     = nil;
    Identifier      = nil;
    OpenMessage     = true,
    CloseMessage    = true,
    Sender          = 1;
    Receiver        = 1;
    Time            = 0;
    Goals           = {};
    Reprisals       = {};
    Rewards         = {};
    Triggers        = {};
};

-- Global Script ---------------------------------------------------------------

---
-- Initalisiert das Bundle im globalen Skript.
--
-- @within Application-Space
-- @local
--
function BundleQuestGeneration.Global:Install()

end

---
-- Erzeugt einen Quest und trägt ihn in die GenerationList ein.
--
-- @param _Data Daten des Quest.
-- @within Application-Space
-- @local
--
function BundleQuestGeneration.Global:NewQuest(_Data)
    if not _Data.Name then
        QSB.AutomaticQuestNameCounter = (QSB.AutomaticQuestNameCounter or 0) +1;
        _Data.Name = string.format("AutoNamed_Quest_%d", QSB.AutomaticQuestNameCounter);
    end

    if not Core:CheckQuestName(_Data.Name) then
        dbg("Quest '"..tostring(_Data.Name).."': invalid questname! Contains forbidden characters!");
        return;
    end

    local QuestData = API.InstanceTable(self.Data.QuestTemplate);
    QuestData.Identifier      = _Data.Name;
    QuestData.MSGKeyOverwrite = nil;
    QuestData.IconOverwrite   = nil;
    QuestData.Loop            = _Data.Loop;
    QuestData.Callback        = _Data.Callback;
    QuestData.SuggestionText  = (type(_Data.Suggestion) == "table" and _Data.Suggestion[lang]) or _Data.Suggestion;
    QuestData.SuccessText     = (type(_Data.Success) == "table" and _Data.Success[lang]) or _Data.Success;
    QuestData.FailureText     = (type(_Data.Failure) == "table" and _Data.Failure[lang]) or _Data.Failure;
    QuestData.Description     = (type(_Data.Description) == "table" and _Data.Description[lang]) or _Data.Description;
    QuestData.OpenMessage     = _Data.Visible == true or _Data.Suggestion ~= nil;
    QuestData.CloseMessage    = _Data.EndMessage == true or (_Data.Failure ~= nil or _Data.Success ~= nil);
    QuestData.Sender          = (_Data.Sender ~= nil and _Data.Sender) or 1;
    QuestData.Receiver        = (_Data.Receiver ~= nil and _Data.Receiver) or 1;
    QuestData.Time            = (_Data.Time ~= nil and _Data.Time) or 0;

    if _Data.Arguments then
        QuestData.Arguments = API.InstanceTable(_Data.Arguments);
    end

    table.insert(self.Data.GenerationList, QuestData);
    local ID = #self.Data.GenerationList;
    self:AttachBehavior(ID, _Data);
    return ID;
end

---
-- Fügt dem Quest mit der ID in der GenerationList seine Behavior hinzu.
--
-- <b>Achtung: </b>Diese Funktion wird vom Code aufgerufen!
--
-- @param _ID   Id des Quests
-- @param _Data Quest Data
-- @within Application-Space
-- @local
--
function BundleQuestGeneration.Global:AttachBehavior(_ID, _Data)
    local lang = (Network.GetDesiredLanguage() == "de" and "de") or "en";
    for k,v in pairs(_Data) do
        if k ~= "Parameter" and type(v) == "table" and v.en and v.de then
            _Data[k] = v[lang];
        end
    end

    for k,v in pairs(_Data) do
        if tonumber(k) ~= nil then
            if type(v) ~= "table" then
                dbg(self.Data.GenerationList[_ID].Identifier..": Some behavior entries aren't behavior!");
            else
                if v.GetGoalTable then
                    table.insert(self.Data.GenerationList[_ID].Goals, v:GetGoalTable());

                    local Idx = #self.Data.GenerationList[_ID].Goals;
                    self.Data.GenerationList[_ID].Goals[Idx].Context            = v;
                    self.Data.GenerationList[_ID].Goals[Idx].FuncOverrideIcon   = self.Data.GenerationList[_ID].Goals[Idx].Context.GetIcon;
                    self.Data.GenerationList[_ID].Goals[Idx].FuncOverrideMsgKey = self.Data.GenerationList[_ID].Goals[Idx].Context.GetMsgKey;
                elseif v.GetReprisalTable then
                    table.insert(self.Data.GenerationList[_ID].Reprisals, v:GetReprisalTable());
                elseif v.GetRewardTable then
                    table.insert(self.Data.GenerationList[_ID].Rewards, v:GetRewardTable());
                elseif v.GetTriggerTable then
                    table.insert(self.Data.GenerationList[_ID].Triggers, v:GetTriggerTable());
                else
                    dbg(self.Data.GenerationList[_ID].Identifier..": Could not obtain behavior table!");
                end
            end
        end
    end
end

---
-- Startet alle Quests in der GenerationList.
--
-- @within Application-Space
-- @local
--
function BundleQuestGeneration.Global:StartQuests()
    if not self:ValidateQuests() then
        return;
    end

    while (#self.Data.GenerationList > 0)
    do
        local QuestData = table.remove(self.Data.GenerationList, 1);
        if self:DebugQuest(QuestData) then
            local QuestID, Quest = QuestTemplate:New(
                QuestData.Identifier,
                QuestData.Sender,
                QuestData.Receiver,
                QuestData.Goals,
                QuestData.Triggers,
                assert(tonumber(QuestData.Time)),
                QuestData.Rewards,
                QuestData.Reprisals,
                QuestData.Callback,
                QuestData.Loop,
                QuestData.OpenMessage,
                QuestData.CloseMessage,
                QuestData.Description,
                QuestData.SuggestionText,
                QuestData.SuccessText,
                QuestData.FailureText
            );

            if QuestData.MSGKeyOverwrite then
                Quest.MsgTableOverride = self.MSGKeyOverwrite;
            end
            if QuestData.IconOverwrite then
                Quest.IconOverride = self.IconOverwrite;
            end
            if QuestData.Arguments then
                Quest.Arguments = API.InstanceTable(QuestData.Arguments);
            end
        end
    end
end

---
-- Validiert alle Quests in der GenerationList. Verschiedene Standardfehler
-- werden geprüft.
--
-- @within Application-Space
-- @local
--
function BundleQuestGeneration.Global:ValidateQuests()
    for k, v in pairs(self.Data.GenerationList) do
        if #v.Goals == 0 then
            table.insert(self.Data.GenerationList[k].Goals, Goal_InstantSuccess());
        end
        if #v.Triggers == 0 then
            table.insert(self.Data.GenerationList[k].Triggers, Trigger_Time(0));
        end

        if #v.Goals == 0 and #v.Triggers == 0 then
            local text = string.format("Quest '" ..v.Identifier.. "' is missing a goal or a trigger!");
            return false;
        end

        local debugText = ""
        -- check if quest table is invalid
        if not v then
            debugText = debugText .. "quest table is invalid!"
        else
            -- check loop callback
            if v.Loop ~= nil and type(v.Loop) ~= "function" then
                debugText = debugText .. self.Identifier..": Loop must be a function!"
            end
            -- check callback
            if v.Callback ~= nil and type(v.Callback) ~= "function" then
                debugText = debugText .. self.Identifier..": Callback must be a function!"
            end
            -- check sender
            if (v.Sender == nil or (v.Sender < 1 or v.Sender > 8))then
                debugText = debugText .. v.Identifier..": Sender is nil or greater than 8 or lower than 1!"
            end
            -- check receiver
            if (v.Receiver == nil or (v.Receiver < 0 or v.Receiver > 8))then
                debugText = debugText .. self.Identifier..": Receiver is nil or greater than 8 or lower than 0!"
            end
            -- check time
            if (v.Time == nil or type(v.Time) ~= "number" or v.Time < 0)then
                debugText = debugText .. v.Identifier..": Time is nil or not a number or lower than 0!"
            end
            -- check visible
            if type(v.OpenMessage) ~= "boolean" then
                debugText = debugText .. v.Identifier..": Visible need to be a boolean!"
            end
            -- check end message
            if type(v.CloseMessage) ~= "boolean" then
                debugText = debugText .. v.Identifier..": EndMessage need to be a boolean!"
            end
            -- check description
            if (v.Description ~= nil and type(v.Description) ~= "string") then
                debugText = debugText .. v.Identifier..": Description is not a string!"
            end
            -- check proposal
            if (v.SuggestionText ~= nil and type(v.SuggestionText) ~= "string") then
                debugText = debugText .. v.Identifier..": Suggestion is not a string!"
            end
            -- check success
            if (v.SuccessText ~= nil and type(v.SuccessText) ~= "string") then
                debugText = debugText .. v.Identifier..": Success is not a string!"
            end
            -- check failure
            if (v.FailureText ~= nil and type(v.FailureText) ~= "string") then
                debugText = debugText .. v.Identifier..": Failure is not a string!"
            end
        end

        if debugText ~= "" then
            dbg(debugText);
            return false;
        end
    end
    return true;
end


---
-- Dummy-Funktion zur Validierung der Behavior eines Quests
--
-- Diese Funktion muss durch ein Debug Bundle überschrieben werden um Quests
-- in der Initalisiererliste zu testen.
--
-- @param _List Liste der Quests
-- @within Application-Space
-- @local
--
function BundleQuestGeneration.Global:DebugQuest(_List)
    return true;
end

-- Local Script ----------------------------------------------------------------

---
-- Initalisiert das Bundle im lokalen Skript.
--
-- @within Application-Space
-- @local
--
function BundleQuestGeneration.Local:Install()

end

Core:RegisterBundle("BundleQuestGeneration");

-- -------------------------------------------------------------------------- --
-- ########################################################################## --
-- #  Symfonia BundleQuestDebug                                             # --
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
-- Der Debug kann auf zwei verschiedene Arten Aktiviert werden:
-- <ol>
-- <li>Im Skript über API.ActivateDebugMode bz. ActivateDebugMode</li>
-- <li>Im Questassistenten über Reward_DEBUG</li>
-- </ol>
--
-- @module BundleQuestDebug
-- @set sort=true
--

API = API or {};
QSB = QSB or {};

BundleQuestDebug = {
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
-- <b>Alias:</b> ActivateDebugMode
--
-- @param _CheckAtStart   Prüfe Quests zur Erzeugunszeit
-- @param _CheckAtRun     Prüfe Quests zur Laufzeit
-- @param _TraceQuests    Aktiviert Questverfolgung
-- @param _DevelopingMode Aktiviert Cheats und Konsole
-- @within User-Space
--
function API.ActivateDebugMode(_CheckAtStart, _CheckAtRun, _TraceQuests, _DevelopingMode)
    if GUI then
        API.Bridge("API.DisbandTravelingSalesman(" ..tostring(_CheckAtStart).. ", " ..tostring(_CheckAtRun).. ", " ..tostring(_TraceQuests).. ", " ..tostring(_DevelopingMode).. ")");
        return;
    end
    BundleQuestDebug.Global:ActivateDebug(_CheckAtStart, _CheckAtRun, _TraceQuests, _DevelopingMode);
end
ActivateDebugMode = API.ActivateDebugMode;

-- -------------------------------------------------------------------------- --
-- Rewards                                                                    --
-- -------------------------------------------------------------------------- --

---
-- Aktiviert den Debug.
--
-- <b>Hinweis:</b> Die Option "Quest vor Start prüfen" funktioniert nur, wenn
-- der Debug im Skript gestartet wird, bevor CreateQuests() ausgeführt wird.
-- Zu dem Zeitpunkt, wenn ein Quest, der im Assistenten erstellt wurde,
-- ausgelöst wird, wurde CreateQuests bereits ausgeführt! Es ist daher nicht
-- mehr möglich die Quests vorab zu prüfen.
--
-- @see API.ActivateDebugMode
--
-- @param _CheckAtStart   Prüfe Quests zur Erzeugunszeit
-- @param _CheckAtRun     Prüfe Quests zur Laufzeit
-- @param _TraceQuests    Aktiviert Questverfolgung
-- @param _DevelopingMode Aktiviert Cheats und Konsole
-- @return Table mit Behavior
-- @within Rewards
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
        { ParameterType.Custom,     en = "Check quests beforehand", de = "Quest vor Start prüfen" },
        { ParameterType.Custom,     en = "Check quest while runtime", de = "Quests zur Laufzeit prüfen" },
        { ParameterType.Custom,     en = "Use quest trace", de = "Questverfolgung" },
        { ParameterType.Custom,     en = "Activate developing mode", de = "Testmodus aktivieren" },
    },
}

function b_Reward_DEBUG:GetRewardTable(__quest_)
    return { Reward.Custom, {self, self.CustomFunction} }
end

function b_Reward_DEBUG:AddParameter(_Index, _Parameter)
    if (_Index == 0) then
        self.CheckAtStart = AcceptAlternativeBoolean(_Parameter)
    elseif (_Index == 1) then
        self.CheckWhileRuntime = AcceptAlternativeBoolean(_Parameter)
    elseif (_Index == 2) then
        self.UseQuestTrace = AcceptAlternativeBoolean(_Parameter)
    elseif (_Index == 3) then
        self.DelepoingMode = AcceptAlternativeBoolean(_Parameter)
    end
end

function b_Reward_DEBUG:CustomFunction(__quest_)
    API.ActivateDebugMode(self.CheckAtStart, self.CheckWhileRuntime, self.UseQuestTrace, self.DelepoingMode);
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
-- @within BundleQuestDebug.Global
-- @local
--
function BundleQuestDebug.Global:Install()

    BundleQuestDebug.Global.Data.DebugCommands = {
        -- groupless commands
        {"clear",               BundleQuestDebug.Global.Clear,},
        {"diplomacy",           BundleQuestDebug.Global.Diplomacy,},
        {"restartmap",          BundleQuestDebug.Global.RestartMap,},
        {"shareview",           BundleQuestDebug.Global.ShareView,},
        {"setposition",         BundleQuestDebug.Global.SetPosition,},
        {"unfreeze",            BundleQuestDebug.Global.Unfreeze,},
        -- quest control
        {"win",                 BundleQuestDebug.Global.QuestSuccess,      true,},
        {"winall",              BundleQuestDebug.Global.QuestSuccess,      false,},
        {"fail",                BundleQuestDebug.Global.QuestFailure,      true,},
        {"failall",             BundleQuestDebug.Global.QuestFailure,      false,},
        {"stop",                BundleQuestDebug.Global.QuestInterrupt,    true,},
        {"stopall",             BundleQuestDebug.Global.QuestInterrupt,    false,},
        {"start",               BundleQuestDebug.Global.QuestTrigger,      true,},
        {"startall",            BundleQuestDebug.Global.QuestTrigger,      false,},
        {"restart",             BundleQuestDebug.Global.QuestReset,        true,},
        {"restartall",          BundleQuestDebug.Global.QuestReset,        false,},
        {"printequal",          BundleQuestDebug.Global.PrintQuests,       1,},
        {"printactive",         BundleQuestDebug.Global.PrintQuests,       2,},
        {"printdetail",         BundleQuestDebug.Global.PrintQuests,       3,},
        -- loading scripts into running game and execute them
        {"lload",               BundleQuestDebug.Global.LoadScript,        true},
        {"gload",               BundleQuestDebug.Global.LoadScript,        false},
        -- execute short lua commands
        {"lexec",               BundleQuestDebug.Global.ExecuteCommand,    true},
        {"gexec",               BundleQuestDebug.Global.ExecuteCommand,    false},
        -- garbage collector printouts
        {"collectgarbage",      BundleQuestDebug.Global.CollectGarbage,},
        {"dumpmemory",          BundleQuestDebug.Global.CountLuaLoad,},
    }

    for k,v in pairs(_G) do
        if type(v) == "table" and v.Name and k == "b_"..v.Name and v.CustomFunction and not v.CustomFunction2 then
            v.CustomFunction2 = v.CustomFunction;
            v.CustomFunction = function(self, __quest_)
                if BundleQuestDebug.Global.Data.CheckAtRun then
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

    if BundleQuestGeneration then
        BundleQuestGeneration.Global.DebugQuest = BundleQuestDebug.Global.DebugQuest;
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
-- @param _CheckAtStart   Prüfe Quests zur Erzeugunszeit
-- @param _CheckAtRun     Prüfe Quests zur Laufzeit
-- @param _TraceQuests    Aktiviert Questverfolgung
-- @param _DevelopingMode Aktiviert Cheats und Konsole
-- @within BundleQuestDebug.Global
-- @local
--
function BundleQuestDebug.Global:ActivateDebug(_CheckAtStart, _CheckAtRun, _TraceQuests, _DevelopingMode)
    if self.Data.DebugModeIsActive then
        return;
    end
    self.Data.DebugModeIsActive = true;

    self.Data.CheckAtStart    = _CheckAtStart == true;
    QSB.DEBUG_CheckAtStart    = _CheckAtStart == true;
    
    self.Data.CheckAtRun      = _CheckAtRun == true;
    QSB.DEBUG_CheckAtRun      = _CheckAtRun == true;
    
    self.Data.TraceQuests     = _TraceQuests == true;
    QSB.DEBUG_TraceQuests     = _TraceQuests == true;
    
    self.Data.DevelopingMode  = _DevelopingMode == true;
    QSB.DEBUG_DevelopingMode  = _DevelopingMode == true;

    self:ActivateQuestTrace();
    self:ActivateDevelopingMode();
end

---
-- Aktiviert die Questverfolgung. Jede Statusänderung wird am Bildschirm
-- angezeigt.
--
-- @within BundleQuestDebug.Global
-- @local
--
function BundleQuestDebug.Global:ActivateQuestTrace()
    if self.Data.TraceQuests then
        DEBUG_EnableQuestDebugKeys();
        DEBUG_QuestTrace(true);
    end
end

---
-- <p>Aktiviert die Questverfolgung. Jede Statusänderung wird am Bildschirm
-- angezeigt.</p>
-- <p>Der Debug stellt einige zusätzliche Tastenkombinationen bereit:</p>
-- <p>Die Konsole des Debug wird mit SHIFT + ^ geöffnet.</p>
-- <p>Die Konsole bietet folgende Kommandos:</p>
--
-- @within BundleQuestDebug.Global
-- @local
--
function BundleQuestDebug.Global:ActivateDevelopingMode()
    if self.Data.DevelopingMode then
        Logic.ExecuteInLuaLocalState("BundleQuestDebug.Local:ActivateDevelopingMode()");
    end
end

---
-- Ließt eingegebene Kommandos aus und führt entsprechende Funktionen aus.
--
-- @within BundleQuestDebug.Global
-- @local
--
function BundleQuestDebug.Global:Parser(_Input)
    local tokens = self:Tokenize(_Input);
    for k, v in pairs(self.Data.DebugCommands) do
        if v[1] == tokens[1] then
            for i=1, #tokens do
                local numb = tonumber(tokens[i])
                if numb then
                    tokens[i] = numb;
                end
            end
            v[2](BundleQuestDebug.Global, tokens, v[3]);
            return;
        end
    end
end

---
-- Zerlegt die Eingabe in einzelne Tokens und gibt diese zurück.
--
-- @return Table mit Tokens
-- @within BundleQuestDebug.Global
-- @local
--
function BundleQuestDebug.Global:Tokenize(_Input)
    local tokens = {};
    local rest = _Input;
    while (rest and rest:len() > 0)
    do
        local s, e = string.find(rest, " ");
        if e then
            tokens[#tokens+1] = rest:sub(1, e-1);
            rest = rest:sub(e+1, rest:len());
        else
            tokens[#tokens+1] = rest;
            rest = nil;
        end
    end
    return tokens;
end

---
-- Führt die Garbage Collection aus um nicht benötigten Speicher freizugeben.
--
-- Die Garbage Collection wird von Lua automatisch in Abständen ausgeführt.
-- Mit dieser Funktion kann man nachhelfen, sollten die Intervalle zu lang
-- sein und der Speicher vollgemüllt werden.
--
-- @within BundleQuestDebug.Global
-- @local
--
function BundleQuestDebug.Global:CollectGarbage()
    collectgarbage();
    Logic.ExecuteInLuaLocalState("BundleQuestDebug.Local:CollectGarbage()");
end

---
-- Gibt die Speicherauslastung von Lua zurück.
--
-- @within BundleQuestDebug.Global
-- @local
--
function BundleQuestDebug.Global:CountLuaLoad()
    Logic.ExecuteInLuaLocalState("BundleQuestDebug.Local:CountLuaLoad()");
    local LuaLoad = collectgarbage("count");
    API.StaticNote("Global Lua Size: " ..LuaLoad)
end

---
-- Zeigt alle Quests nach einem Filter an.
--
-- @within BundleQuestDebug.Global
-- @local
--
function BundleQuestDebug.Global:PrintQuests(_Arguments, _Flags)
    local questText         = ""
    local counter            = 0;

    local accept = function(_quest, _state)
        return _quest.State == _state;
    end

    if _Flags == 3 then
        self:PrintDetail(_Arguments);
        return;
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
end

---
-- Läd ein Lua-Skript in das Enviorment.
--
-- @within BundleQuestDebug.Global
-- @local
--
function BundleQuestDebug.Global:LoadScript(_Arguments, _Flags)
    if _Arguments[2] then
        if _Flags == true then
            Logic.ExecuteInLuaLocalState([[Script.Load("]].._Arguments[2]..[[")]]);
        elseif _Flags == false then
            Script.Load(__arguments_[2]);
        end
        if not self.Data.SurpassMessages then
            Logic.DEBUG_AddNote("load script ".._Arguments[2]);
        end
    end
end

---
-- Führt ein Lua-Kommando im Enviorment aus.
--
-- @within BundleQuestDebug.Global
-- @local
--
function BundleQuestDebug.Global:ExecuteCommand(_Arguments, _Flags)
    if _Arguments[2] then
        local args = "";
        for i=2,#_Arguments do
            args = args .. " " .. _Arguments[i];
        end

        if _Flags == true then
            _Arguments[2] = string.gsub(args,"'","\'");
            Logic.ExecuteInLuaLocalState([[]]..args..[[]]);
        elseif _Flags == false then
            Logic.ExecuteInLuaLocalState([[GUI.SendScriptCommand("]]..args..[[")]]);
        end
    end
end

---
-- Konsolenbefehl: Leert das Debug Window.
--
-- @within BundleQuestDebug.Global
-- @local
--
function BundleQuestDebug.Global:Clear()
    Logic.ExecuteInLuaLocalState("GUI.ClearNotes()");
end

---
-- Konsolenbefehl: Ändert die Diplomatie zwischen zwei Spielern.
--
-- @within BundleQuestDebug.Global
-- @local
--
function BundleQuestDebug.Global:Diplomacy(_Arguments)
    SetDiplomacyState(_Arguments[2], _Arguments[3], _Arguments[4]);
end

---
--  Konsolenbefehl: Startet die Map umgehend neu.
--
-- @within BundleQuestDebug.Global
-- @local
--
function BundleQuestDebug.Global:RestartMap()
    Logic.ExecuteInLuaLocalState("Framework.RestartMap()");
end

---
-- Konsolenbefehl: Aktiviert/deaktiviert die geteilte Sicht zweier Spieler.
--
-- @within BundleQuestDebug.Global
-- @local
--
function BundleQuestDebug.Global:ShareView(_Arguments)
    Logic.SetShareExplorationWithPlayerFlag(_Arguments[2], _Arguments[3], _Arguments[4]);
end

---
-- Konsolenbefehl: Setzt die Position eines Entity.
--
-- @within BundleQuestDebug.Global
-- @local
--
function BundleQuestDebug.Global:SetPosition(_Arguments)
    local entity = GetID(_Arguments[2]);
    local target = GetID(_Arguments[3]);
    local x,y,z  = Logic.EntityGetPos(target);
    if Logic.IsBuilding(target) == 1 then
        x,y = Logic.GetBuildingApproachPosition(target);
    end
    Logic.DEBUG_SetSettlerPosition(entity, x, y);
end

---
-- Beendet einen Quest, oder mehrere Quests mit ähnlichen Namen, erfolgreich.
--
-- @within BundleQuestDebug.Global
-- @local
--
function BundleQuestDebug.Global:QuestSuccess(_QuestName, _ExactName)
    local FoundQuests = FindQuestsByName(_QuestName[1], _ExactName);
    if #FoundQuests > 0 then
        return;
    end
    API.WinAllQuests(unpack(FoundQuests));
end

---
-- Lässt einen Quest, oder mehrere Quests mit ähnlichen Namen, fehlschlagen.
--
-- @within BundleQuestDebug.Global
-- @local
--
function BundleQuestDebug.Global:QuestFailure(_QuestName, _ExactName)
    local FoundQuests = FindQuestsByName(_QuestName[1], _ExactName);
    if #FoundQuests > 0 then
        return;
    end
    API.FailAllQuests(unpack(FoundQuests));
end

---
-- Stoppt einen Quest, oder mehrere Quests mit ähnlichen Namen.
--
-- @within BundleQuestDebug.Global
-- @local
--
function BundleQuestDebug.Global:QuestInterrupt(_QuestName, _ExactName)
    local FoundQuests = FindQuestsByName(_QuestName[1], _ExactName);
    if #FoundQuests > 0 then
        return;
    end
    API.StopAllQuests(unpack(FoundQuests));
end

---
-- Startet einen Quest, oder mehrere Quests mit ähnlichen Namen.
--
-- @within BundleQuestDebug.Global
-- @local
--
function BundleQuestDebug.Global:QuestTrigger(_QuestName, _ExactName)
    local FoundQuests = FindQuestsByName(_QuestName[1], _ExactName);
    if #FoundQuests > 0 then
        return;
    end
    API.StartAllQuests(unpack(FoundQuests));
end

---
-- Setzt den Quest / die Quests zurück, sodass er neu gestartet werden kann.
--
-- @within BundleQuestDebug.Global
-- @local
--
function BundleQuestDebug.Global:QuestReset(_QuestName, _ExactName)
    local FoundQuests = FindQuestsByName(_QuestName[1], _ExactName);
    if #FoundQuests > 0 then
        return;
    end
    API.RestartAllQuests(unpack(FoundQuests));
end

---
-- Überschreibt CreateQuests, sodass Assistentenquests über das Skript erzeugt 
-- werden um diese sinnvoll überprüfen zu können.
--
-- @within BundleQuestDebug.Global
-- @local
--
function BundleQuestDebug.Global:OverwriteCreateQuests()
    self.Data.CreateQuestOriginal = CreateQuests;
    CreateQuests = function()
        if not BundleQuestDebug.Global.Data.CheckAtStart then
            BundleQuestDebug.Global.Data.CreateQuestsOriginal();
            return;
        end

        local QuestNames = Logic.Quest_GetQuestNames()
        for i=1, #QuestNames, 1 do
            local QuestName = QuestNames[i]
            local QuestData = {Logic.Quest_GetQuestParamter(QuestName)};

            -- Behavior ermitteln
            local Behaviors = {};
            local Amount = Logic.Quest_GetQuestNumberOfBehaviors(QuestName);
            for j=0, Amount-1, 1 do
                local Name = Logic.Quest_GetQuestBehaviorName(QuestName, j);
                local Template = GetBehaviorTemplateByName(Name);
                assert(Template ~= nil);

                local Parameters = Logic.Quest_GetQuestBehaviorParameter(QuestName, j);
                API.DumpTable(Parameters);
                table.insert(Behaviors, Template:new(unpack(Parameters)));
            end

            API.AddQuest {
                Name        = QuestName,
                Sender      = QuestData[1],
                Receiver    = QuestData[2],
                Time        = QuestData[4],
                Description = QuestData[5],
                Suggestion  = QuestData[6],
                Failure     = QuestData[7],
                Success     = QuestData[8],

                unpack(Behaviors),
            }
        end

        API.StartQuests();
    end
end

---
-- Stellt den Debug nach dem Laden eines Spielstandes wieder her.
--
-- @param _Arguments Argumente der überschriebenen Funktion
-- @param _Original  Referenz auf Save-Funktion
-- @local
--
function BundleQuestDebug.Global.OnSaveGameLoad(_Arguments, _Original)
    BundleQuestDebug.Global:ActivateDevelopingMode();
    BundleQuestDebug.Global:ActivateQuestTrace();
end

---
-- Prüft die Quests in der Initalisierungsliste der Quests auf Korrektheit.
--
-- Es können nur Behavior der Typen Goal.Custom, Reprisal.Custom2,
-- Reward.Custom2 und Triggers.Custom überprüft werden. Die anderen Typen
-- können nicht debugt werden!
--
-- @param _List Liste der Quests
-- @local
--
function BundleQuestDebug.Global.DebugQuest(self, _Quest)
    if BundleQuestDebug.Global.Data.CheckAtStart then
        if _Quest.Goals then
            for i=1, #_Quest.Goals, 1 do
                if type(_Quest.Goals[i][2]) == "table" and type(_Quest.Goals[i][2][1]) == "table" then
                    if _Quest.Goals[i][2][1].DEBUG and _Quest.Goals[i][2][1]:DEBUG(_Quest) then
                        return false;
                    end
                end
            end
        end
        if _Quest.Reprisals then
            for i=1, #_Quest.Reprisals, 1 do
                if type(_Quest.Reprisals[i][2]) == "table" and type(_Quest.Reprisals[i][2][1]) == "table" then
                    if _Quest.Reprisals[i][2][1].DEBUG and _Quest.Reprisals[i][2][1]:DEBUG(_Quest) then
                        return false;
                    end
                end
            end
        end
        if _Quest.Rewards then
            for i=1, #_Quest.Rewards, 1 do
                if type(_Quest.Rewards[i][2]) == "table" and type(_Quest.Rewards[i][2][1]) == "table" then
                    if _Quest.Rewards[i][2][1].DEBUG and _Quest.Rewards[i][2][1]:DEBUG(_Quest) then
                        return false;
                    end
                end
            end
        end
        if _Quest.Triggers then
            for i=1, #_Quest.Triggers, 1 do
                if type(_Quest.Triggers[i][2]) == "table" and type(_Quest.Triggers[i][2][1]) == "table" then
                    if _Quest.Triggers[i][2][1].DEBUG and _Quest.Triggers[i][2][1]:DEBUG(_Quest) then
                        return false;
                    end
                end
            end
        end
    end
    return true;
end

-- Local Script ----------------------------------------------------------------

---
-- Initalisiert das Bundle im lokalen Skript.
--
-- @within BundleQuestDebug.Local
-- @local
--
function BundleQuestDebug.Local:Install()

end

---
-- Führt die Garbage Collection aus um nicht benötigten Speicher freizugeben.
--
-- Die Garbage Collection wird von Lua automatisch in Abständen ausgeführt.
-- Mit dieser Funktion kann man nachhelfen, sollten die Intervalle zu lang
-- sein und der Speicher vollgemüllt werden.
--
-- @within BundleQuestDebug.Local
-- @local
--
function BundleQuestDebug.Local:CollectGarbage()
    collectgarbage();
end

---
-- Gibt die Speicherauslastung von Lua zurück.
--
-- @within BundleQuestDebug.Local
-- @local
--
function BundleQuestDebug.Local:CountLuaLoad()
    local LuaLoad = collectgarbage("count");
    API.StaticNote("Local Lua Size: " ..LuaLoad)
end

---
-- Aktiviert die Questverfolgung. Jede Statusänderung wird am Bildschirm
-- angezeigt.
--
-- @see BundleQuestDebug.Global:ActivateDevelopingMode
-- @within BundleQuestDebug.Local
-- @local
--
function BundleQuestDebug.Local:ActivateDevelopingMode()
    KeyBindings_EnableDebugMode(1);
    KeyBindings_EnableDebugMode(2);
    KeyBindings_EnableDebugMode(3);
    XGUIEng.ShowWidget("/InGame/Root/Normal/AlignTopLeft/GameClock",1);

    GUI_Chat.Abort = function() end

    GUI_Chat.Confirm = function()
        Input.GameMode();
        XGUIEng.ShowWidget("/InGame/Root/Normal/ChatInput",0);
        BundleQuestDebug.Local.Data.ChatBoxInput = XGUIEng.GetText("/InGame/Root/Normal/ChatInput/ChatInput");
        g_Chat.JustClosed = 1;
        Game.GameTimeSetFactor( GUI.GetPlayerID(), 1 );
    end

    QSB_DEBUG_InputBoxJob = function()
        if not BundleQuestDebug.Local.Data.BoxShown then
            Input.ChatMode();
            Game.GameTimeSetFactor( GUI.GetPlayerID(), 0 );
            XGUIEng.ShowWidget("/InGame/Root/Normal/ChatInput", 1);
            XGUIEng.SetText("/InGame/Root/Normal/ChatInput/ChatInput", "");
            XGUIEng.SetFocus("/InGame/Root/Normal/ChatInput/ChatInput");
            BundleQuestDebug.Local.Data.BoxShown = true
        elseif BundleQuestDebug.Local.Data.ChatBoxInput then
            BundleQuestDebug.Local.Data.ChatBoxInput = string.gsub(BundleQuestDebug.Local.Data.ChatBoxInput,"'","\'");
            GUI.SendScriptCommand("BundleQuestDebug.Global:Parser('"..BundleQuestDebug.Local.Data.ChatBoxInput.."')");
            BundleQuestDebug.Local.Data.BoxShown = nil;
            return true;
        end
    end

    Input.KeyBindDown(
        Keys.ModifierShift + Keys.OemPipe,
        "StartSimpleJob('QSB_DEBUG_InputBoxJob')",
        2,
        true
    );
end

Core:RegisterBundle("BundleQuestDebug");

-- -------------------------------------------------------------------------- --
-- ########################################################################## --
-- #  Symfonia BundleNonPlayerCharacter                                     # --
-- ########################################################################## --
-- -------------------------------------------------------------------------- --

---
-- Implementiert ansprechbare Spielfiguren. Ein NPC wird angesprochen, indem
-- man mit einem selektierten Held über ihn zeigt. Der Mauszeiger wird zu einer
-- Hand. Klickt man dann links, wird sich der Held zum NPC bewegen. Sobald er
-- ihn errecht, wird eine Aktion ausgeführt.
--
-- Folgt ein NPC einem Helden, wird er stehen bleiben, wenn der Held zu weit
-- entfernt ist. Wenn ein Ziel angegeben ist, dann wird das Callback erst
-- ausgelöst, wenn man den NPC in der Nähe des Ziels anspricht. Ist kein
-- Ziel angegeben, wird das Callback niemals ausgelöst.
-- Optional kann eine Action angegeben werden, die anstelle des Callback
-- ausgeführt wird, wenn das Ziel nicht erreicht ist.
--
-- Führt ein NPC einen Helden, wird er stehen bleiben, wenn der Held zu weit
-- entfernt ist. Andernfalls bewegt sich der NPC zum Zielpunkt. Das Callback
-- wird nur ausgelöst, wenn sich der NPC in der Nähe des Ziels befindet. Es
-- kann eine Action angegeben werden, die anstelle des Callback ausgeführt
-- wird, wenn das Ziel nicht erreicht ist.
--
-- @module BundleNonPlayerCharacter
-- @set sort=true
--

API = API or {};
QSB = QSB or {};

-- -------------------------------------------------------------------------- --
-- User-Space                                                                 --
-- -------------------------------------------------------------------------- --

BundleNonPlayerCharacter = {
    Global = {
        NonPlayerCharacter = {
            Data = {},
        },
        NonPlayerCharacterObjects = {},
        LastNpcEntityID = 0,
        LastHeroEntityID = 0,
    },
    Local = {}
};

---
-- Erzeugt eine neue Instanz von NonPlayerCharacter für das Entity
-- mit dem angegebenen Skriptnamen.
--
-- <b>Alias:</b> NonPlayerCharacter:New
--
-- @param _ScriptName Skriptname des NPC
-- @return object
-- @within NonPlayerCharacter
--
-- @usage -- Einfachen NPC erzeugen:
-- local NPC = NonPlayerCharacter:New("npc")
--              :SetDialogPartner("hero")               -- Optional
--              :SetCallback(Briefing1)                 -- Optional
--              :Activate();
--
-- -- Folgenden NPC erzeugen:
-- local NPC = NonPlayerCharacter:New("npc")
--              :SetDialogPartner("hero")               -- Optional
--              :SetFollowTarget("hero")
--              :SetFollowDestination("destination")    -- Optional
--              :SetFollowAction(NotArrivedFunction)    -- Optional
--              :SetCallback(Briefing1)                 -- Optional
--              :Activate();
--
-- -- Führenden NPC erzeugen:
-- local NPC = NonPlayerCharacter:New("npc")
--              :SetDialogPartner("hero")               -- Optional
--              :SetGuideParams("destination", "hero")
--              :SetGuideAction(NotArrivedFunction)     -- Optional
--              :SetCallback(Briefing1)                 -- Optional
--              :Activate();
--
function BundleNonPlayerCharacter.Global.NonPlayerCharacter:New(_ScriptName)
    assert( self == BundleNonPlayerCharacter.Global.NonPlayerCharacter, 'Can not be used from instance!');
    assert(IsExisting(_ScriptName), 'entity "' .._ScriptName.. '" does not exist!');
    
    local npc = CopyTableRecursive(self);
    npc.Data.NpcName = _ScriptName;
    BundleNonPlayerCharacter.Global.NonPlayerCharacterObjects[_ScriptName] = npc;
    return npc;
end

---
-- Gibt die Inztanz des NPC mit dem angegebenen Skriptnamen zurück.
-- Handelt es sich um einen Soldaten, wird versucht die Instanz
-- über den Leader zu ermitteln.
--
-- <b>Alias:</b> NonPlayerCharacter:GetInstance
--
-- @param _ScriptName Skriptname des NPC
-- @return object
-- @within NonPlayerCharacter
-- @usage -- NPC ermitteln
-- local NPC = NonPlayerCharacter:GetInstance("horst");
-- -- Etwas mit dem NPC tun
-- NPC:SetDialogPartner("hilda");
--
function BundleNonPlayerCharacter.Global.NonPlayerCharacter:GetInstance(_ScriptName)
    assert( self == BundleNonPlayerCharacter.Global.NonPlayerCharacter, 'Can not be used from instance!');
    local EntityID = GetID(_ScriptName)
    local ScriptName = Logic.GetEntityName(EntityID);
    if Logic.IsEntityInCategory(EntityID, EntityCategories.Soldier) == 1 then
        local LeaderID = Logic.SoldierGetLeaderEntityID(EntityID);
        if IsExisting(LeaderID) then
            ScriptName = Logic.GetEntityName(LeaderID);
        end
    end
    return BundleNonPlayerCharacter.Global.NonPlayerCharacterObjects[ScriptName];
end

---
-- Gibt die Entity ID des letzten angesprochenen NPC zurück.
--
-- <b>Alias:</b> NonPlayerCharacter:GetNpcId
--
-- @return number
-- @within NonPlayerCharacter
--
function BundleNonPlayerCharacter.Global.NonPlayerCharacter:GetNpcId()
    assert( self == BundleNonPlayerCharacter.Global.NonPlayerCharacter, 'Can not be used from instance!');
    return BundleNonPlayerCharacter.Global.LastNpcEntityID;
end

---
-- Gibt die Entity ID des letzten Helden zurück, der einen NPC
-- angesprochen hat.
--
-- <b>Alias:</b> NonPlayerCharacter:GetHeroId
--
-- @return number
-- @within NonPlayerCharacter
--
function BundleNonPlayerCharacter.Global.NonPlayerCharacter:GetHeroId()
    assert( self == BundleNonPlayerCharacter.Global.NonPlayerCharacter, 'Can not be used from instance!');
    return BundleNonPlayerCharacter.Global.LastHeroEntityID;
end

---
-- Gibt die Entity ID des NPC zurück. Ist der NPC ein Leader, wird
-- der erste Soldat zurückgegeben, wenn es einen gibt.
--
-- <b>Alias:</b> NonPlayerCharacter:GetID
--
-- @return number
-- @within NonPlayerCharacter
--
function BundleNonPlayerCharacter.Global.NonPlayerCharacter:GetID()
    assert(self ~= BundleNonPlayerCharacter.Global.NonPlayerCharacter, 'Can not be used in static context!');
    local EntityID = GetID(self.Data.NpcName);
    if Logic.IsEntityInCategory(EntityID, EntityCategories.Leader) == 1 then
        local Soldiers = {Logic.GetSoldiersAttachedToLeader(EntityID)};
        if Soldiers[1] > 0 then
            return Soldiers[2];
        end
    end
    return EntityID
end

---
-- Löscht einen NPC.
--
-- <b>Alias:</b> NonPlayerCharacter:Dispose
--
-- @within NonPlayerCharacter
--
-- @usage -- NPC löschen
-- NPC:Dispose();
-- 
function BundleNonPlayerCharacter.Global.NonPlayerCharacter:Dispose()
    assert(self ~= BundleNonPlayerCharacter.Global.NonPlayerCharacter, 'Can not be used in static context!');
    self:Deactivate();
    BundleNonPlayerCharacter.Global.NonPlayerCharacterObjects[self.Data.NpcName] = nil;
end

---
-- Aktiviert einen inaktiven NPC, sodass er wieder angesprochen werden kann.
-- 
-- <p><b>Alias:</b> NonPlayerCharacter:Activate</p>
--
-- @return Instanz von NonPlayerCharacter
-- @within NonPlayerCharacter
-- @usage -- NPC aktivieren:
-- NPC:Activate();
--
function BundleNonPlayerCharacter.Global.NonPlayerCharacter:Activate()
    assert(self ~= BundleNonPlayerCharacter.Global.NonPlayerCharacter, 'Can not be used in static context!');
    if IsExisting(self.Data.NpcName) then
        Logic.SetOnScreenInformation(self:GetID(), 1);
    end
    return self;
end

---
-- Deaktiviert einen aktiven NPC, sodass er nicht angesprochen werden kann.
-- 
-- <p><b>Alias:</b> NonPlayerCharacter:Deactivate</p>
--
-- @return Instanz von NonPlayerCharacter
-- @within NonPlayerCharacter
-- @usage -- NPC deaktivieren:
-- NPC:Deactivate();
--
function BundleNonPlayerCharacter.Global.NonPlayerCharacter:Deactivate()
    assert(self ~= BundleNonPlayerCharacter.Global.NonPlayerCharacter, 'Can not be used in static context!');
    if IsExisting(self.Data.NpcName) then
        Logic.SetOnScreenInformation(self:GetID(), 0);
    end
    return self;
end

---
-- <p>Gibt true zurück, wenn der NPC aktiv ist.</p>
--
-- <p><b>Alias:</b> NonPlayerCharacter:IsActive</p>
--
-- @return boolean
-- @within NonPlayerCharacter
--
function BundleNonPlayerCharacter.Global.NonPlayerCharacter:IsActive()
    assert(self ~= BundleNonPlayerCharacter.Global.NonPlayerCharacter, 'Can not be used in static context!');
    return Logic.GetEntityScriptingValue(self:GetID(), 6) == 1;
end

---
-- Setzt den NPC zurück, sodass er erneut aktiviert werden kann.
--
-- <b>Alias:</b> NonPlayerCharacter:Reset
--
-- @return Instanz von NonPlayerCharacter
-- @within NonPlayerCharacter
--
function BundleNonPlayerCharacter.Global.NonPlayerCharacter:Reset()
    assert(self ~= BundleNonPlayerCharacter.Global.NonPlayerCharacter, 'Can not be used in static context!');
    if IsExisting(self.Data.NpcName) then
        Logic.SetOnScreenInformation(self:GetID(), 0);
        self.Data.TalkedTo = nil;
    end
    return self;
end

---
-- Gibt true zurück, wenn der NPC angesprochen wurde. Ist ein
-- spezieller Ansprechpartner definiert, wird nur dann true
-- zurückgegeben, wenn dieser Held mit dem NPC spricht.
--
-- <b>Alias:</b> NonPlayerCharacter:HasTalkedTo
--
-- @return boolean
-- @within NonPlayerCharacter
--
function BundleNonPlayerCharacter.Global.NonPlayerCharacter:HasTalkedTo()
    assert(self ~= BundleNonPlayerCharacter.Global.NonPlayerCharacter, 'Can not be used in static context!');
    if self.Data.HeroName then
        return self.Data.TalkedTo == GetID(self.Data.HeroName);
    end
    return self.Data.TalkedTo ~= nil;
end

---
-- Setzt den Ansprechpartner für diesen NPC.
--
-- <b>Alias:</b> NonPlayerCharacter:SetDialogPartner
--
-- @param _HeroName     Skriptname des Helden
-- @return Instanz von NonPlayerCharacter
-- @within NonPlayerCharacter
--
function BundleNonPlayerCharacter.Global.NonPlayerCharacter:SetDialogPartner(_HeroName)
    assert(self ~= BundleNonPlayerCharacter.Global.NonPlayerCharacter, 'Can not be used in static context!');
    self.Data.HeroName = _HeroName;
    return self;
end

---
-- Setzt das Callback für den Fall, dass ein falscher Held den
-- NPC anspricht.
--
-- <b>Alias:</b> NonPlayerCharacter:SetWrongPartnerCallback
--
-- @param _Callback     Callback
-- @return Instanz von NonPlayerCharacter
-- @within NonPlayerCharacter
--
function BundleNonPlayerCharacter.Global.NonPlayerCharacter:SetWrongPartnerCallback(_Callback)
    assert(self ~= BundleNonPlayerCharacter.Global.NonPlayerCharacter, 'Can not be used in static context!');
    self.Data.WrongHeroCallback = _Callback;
    return self;
end

---
-- Setzt das Ziel, zu dem der NPC vom Helden geführt werden
-- muss. Wenn ein Ziel erreicht wird, kann der NPC erst dann
-- angesprochen werden, wenn das Ziel erreicht ist.
--
-- <b>Alias:</b> NonPlayerCharacter:SetFollowDestination
--
-- @param _ScriptName     Skriptname des Ziel
-- @return Instanz von NonPlayerCharacter
-- @within NonPlayerCharacter
--
function BundleNonPlayerCharacter.Global.NonPlayerCharacter:SetFollowDestination(_ScriptName)
    assert(self ~= BundleNonPlayerCharacter.Global.NonPlayerCharacter, 'Can not be used in static context!');
    self.Data.FollowDestination = _ScriptName;
    return self;
end

---
-- Setzt den Helden, dem der NPC folgt. Ist Kein Ziel gesetzt,
-- folgt der NPC dem Helden unbegrenzt.
--
-- <b>Alias:</b> NonPlayerCharacter:SetFollowTarget
--
-- @param _ScriptName     Skriptname des Helden
-- @return Instanz von NonPlayerCharacter
-- @within NonPlayerCharacter
--
function BundleNonPlayerCharacter.Global.NonPlayerCharacter:SetFollowTarget(_ScriptName)
    assert(self ~= BundleNonPlayerCharacter.Global.NonPlayerCharacter, 'Can not be used in static context!');
    self.Data.FollowTarget = _ScriptName;
    return self;
end

---
-- Setzt die Funktion, die während ein NPC einem Helden folgt und
-- das Ziel noch nicht erreicht ist, anstelle des Callback beim
-- Ansprechen ausgeführt wird.
--
-- <b>Alias:</b> NonPlayerCharacter:SetFollowAction
--
-- @param _Function     Action
-- @return Instanz von NonPlayerCharacter
-- @within NonPlayerCharacter
--
function BundleNonPlayerCharacter.Global.NonPlayerCharacter:SetFollowAction(_Function)
    assert(self ~= BundleNonPlayerCharacter.Global.NonPlayerCharacter, 'Can not be used in static context!');
    self.Data.FollowAction = _Function;
    return self;
end
---
-- Setzt das Ziel zu dem der NPC läuft und den Helden, der dem
-- NPC folgen muss.
--
-- <b>Alias:</b> NonPlayerCharacter:SetGuideParams
--
-- @param _ScriptName     Skriptname des Ziel
-- @param _Target         Striptname des Helden
-- @return Instanz von NonPlayerCharacter
-- @within NonPlayerCharacter
--
function BundleNonPlayerCharacter.Global.NonPlayerCharacter:SetGuideParams(_ScriptName, _Target)
    assert(self ~= BundleNonPlayerCharacter.Global.NonPlayerCharacter, 'Can not be used in static context!');
    self.Data.GuideDestination = _ScriptName;
    self.Data.GuideTarget = _Target;
    return self;
end

---
-- Setzt die Funktion, die während ein NPC einen Helden führt und
-- das Ziel noch nicht erreicht ist, anstelle des Callback beim
-- Ansprechen ausgeführt wird.
--
-- <b>Alias:</b> NonPlayerCharacter:SetGuideAction
--
-- @param _Function     Action
-- @return Instanz von NonPlayerCharacter
-- @within NonPlayerCharacter
--
function BundleNonPlayerCharacter.Global.NonPlayerCharacter:SetGuideAction(_Function)
    assert(self ~= BundleNonPlayerCharacter.Global.NonPlayerCharacter, 'Can not be used in static context!');
    self.Data.GuideAction = _Function;
    return self;
end

---
-- Setzt das Callback des NPC, dass beim Ansprechen ausgeführt wird.
--
-- <b>Alias:</b> NonPlayerCharacter:SetCallback
--
-- @param _Callback     Callback
-- @return Instanz von NonPlayerCharacter
-- @within NonPlayerCharacter
--
function BundleNonPlayerCharacter.Global.NonPlayerCharacter:SetCallback(_Callback)
    assert(self ~= BundleNonPlayerCharacter.Global.NonPlayerCharacter, 'Can not be used in static context!');
    assert(type(_Callback) == "function", 'callback must be a function!');
    self.Data.Callback = _Callback;
    return self;
end

-- -------------------------------------------------------------------------- --
-- Behavior                                                                   --
-- -------------------------------------------------------------------------- --

---
-- Der Held muss einen Nichtspielercharakter ansprechen.
--
-- @param _NpcName  Skriptname des NPC
-- @param _HeroName Skriptname des Helden (optional)
-- @return Table mit Behavior
-- @within Behavior
--
function Goal_NPC(...)
    return b_Goal_NPC:new(...);
end

b_Goal_NPC = {
    Name             = "Goal_NPC",
    Description     = {
        en = "Goal: The hero has to talk to a non-player character.",
        de = "Ziel: Der Held muss einen Nichtspielercharakter ansprechen.",
    },
    Parameter = {
        { ParameterType.ScriptName, en = "NPC",  de = "NPC" },
        { ParameterType.ScriptName, en = "Hero", de = "Held" },
    },
}

function b_Goal_NPC:GetGoalTable(__quest_)
    return {Objective.Distance, -65565, self.Hero, self.NPC, self }
end

function b_Goal_NPC:AddParameter(__index_, __parameter_)
    if (__index_ == 0) then
        self.NPC = __parameter_
    elseif (__index_ == 1) then
        self.Hero = __parameter_
        if self.Hero == "-" then
            self.Hero = nil
        end
   end
end

function b_Goal_NPC:GetIcon()
    return {14,10}
end

Core:RegisterBehavior(b_Goal_NPC);

-- -------------------------------------------------------------------------- --

---
-- Startet den Quest, sobald der NPC angesprochen wurde.
--
-- @param _NpcName  Skriptname des NPC
-- @param _HeroName Skriptname des Helden (optional)
-- @return Table mit Behavior
-- @within Behavior
--
function Trigger_NPC(...)
    return b_Trigger_NPC:new(...);
end

b_Trigger_NPC = {
    Name = "Trigger_NPC",
    Description = {
        en = "Trigger: Starts the quest after the npc was spoken to.",
        de = "Ausloeser: Startet den Quest, sobald der NPC angesprochen wurde.",
    },
    Parameter = {
        { ParameterType.ScriptName, en = "NPC",  de = "NPC" },
        { ParameterType.ScriptName, en = "Hero", de = "Held" },
    },
}

function b_Trigger_NPC:GetTriggerTable()
    return { Triggers.Custom2,{self, self.CustomFunction} }
end

function b_Trigger_NPC:AddParameter(__index_, __parameter_)
    if (__index_ == 0) then
        self.NPC = __parameter_
    elseif (__index_ == 1) then
        self.Hero = __parameter_
        if self.Hero == "-" then
            self.Hero = nil
        end
    end
end

function b_Trigger_NPC:CustomFunction()
    if not IsExisting(self.NPC) then
        return;
    end
    if not self.NpcInstance then
        local NPC = NonPlayerCharacter:New(self.NPC);
        NPC:SetDialogPartner(self.Hero);
        self.NpcInstance = NPC;
    end
    local TalkedTo = self.NpcInstance:HasTalkedTo(self.Hero);
    if not TalkedTo then
        if not self.NpcInstance:IsActive() then
            self.NpcInstance:Activate();
        end
    end
    return TalkedTo;
end

function b_Trigger_NPC:Reset(__quest_)
    if self.NpcInstance then
        self.NpcInstance:Dispose();
    end
end

function b_Trigger_NPC:DEBUG(__quest_)
    return false;
end

Core:RegisterBehavior(b_Trigger_NPC);

-- -------------------------------------------------------------------------- --
-- Application-Space                                                          --
-- -------------------------------------------------------------------------- --

-- Global Script ---------------------------------------------------------------

---
-- Initialisiert das Bundle im globalen Skript.
-- @within Application-Space
-- @local
--
function BundleNonPlayerCharacter.Global:Install()
    NonPlayerCharacter = BundleNonPlayerCharacter.Global.NonPlayerCharacter;
    
    ---
    -- Führt die statische Steuerungsfunktion für alle NPC aus.
    --
    StartSimpleJobEx( function()
        for k, v in pairs(BundleNonPlayerCharacter.Global.NonPlayerCharacterObjects) do
            NonPlayerCharacter:Control(k);
        end
    end);
    
    -- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    
    GameCallback_OnNPCInteraction_Orig_QSB_NPC_Rewrite = GameCallback_OnNPCInteraction
    GameCallback_OnNPCInteraction = function(_EntityID, _PlayerID)
        GameCallback_OnNPCInteraction_Orig_QSB_NPC_Rewrite(_EntityID, _PlayerID)
        Quest_OnNPCInteraction(_EntityID, _PlayerID)
    end
    
    Quest_OnNPCInteraction = function(_EntityID, _PlayerID)
        local KnightIDs = {};
        Logic.GetKnights(_PlayerID, KnightIDs);
        -- Akteure ermitteln
        local ClosestKnightID = 0;
        local ClosestKnightDistance = Logic.WorldGetSize();
        for i= 1, #KnightIDs, 1 do
            local DistanceBetween = Logic.GetDistanceBetweenEntities(KnightIDs[i], _EntityID);
            if DistanceBetween < ClosestKnightDistance then
                ClosestKnightDistance = DistanceBetween;
                ClosestKnightID = KnightIDs[i];
            end
        end
        BundleNonPlayerCharacter.Global.LastHeroEntityID = ClosestKnightID;
        local NPC = NonPlayerCharacter:GetInstance(_EntityID);
        BundleNonPlayerCharacter.Global.LastNpcEntityID = NPC:GetID();
        
        if NPC then
            if NPC.Data.FollowTarget ~= nil then
                if NPC.Data.FollowDestination then
                    API.Note(Logic.GetDistanceBetweenEntities(_EntityID, GetID(NPC.Data.FollowDestination)))
                    if Logic.GetDistanceBetweenEntities(_EntityID, GetID(NPC.Data.FollowDestination)) > 2000 then
                        if NPC.Data.FollowAction then 
                            NPC.Data.FollowAction(self);
                        end
                        return
                    end
                else
                    if NPC.Data.FollowAction then
                        NPC.Data.FollowAction(self);
                    end
                    return
                end
            end

            if NPC.Data.GuideTarget ~= nil then
                local TargetID = GetID(NPC.Data.GuideDestination);
                if Logic.GetDistanceBetweenEntities(_EntityID, TargetID) > 2000 then
                    if NPC.Data.GuideAction then
                        NPC.Data.GuideAction(NPC);
                    end
                    return;
                end
                Logic.SetTaskList(_EntityID, TaskLists.TL_NPC_IDLE);
            end
            
            NPC:RotateActors();
            NPC.Data.TalkedTo = ClosestKnightID;
            if NPC:HasTalkedTo() then
                NPC:Deactivate();
                if NPC.Data.Callback then
                    NPC.Data.Callback(NPC);
                end
            else
                if NPC.Data.WrongHeroCallback then
                    NPC.Data.WrongHeroCallback(NPC);
                end
            end
        end
    end
    
    function QuestTemplate:RemoveQuestMarkers()
        for i=1, self.Objectives[0] do
            if self.Objectives[i].Type == Objective.Distance then
                if ((type(self.Objectives[i].Data[1]) == "number" and self.Objectives[i].Data[1] > 0) 
                or (type(self.Objectives[i].Data[1]) ~= "number")) and self.Objectives[i].Data[4] then
                    DestroyQuestMarker(self.Objectives[i].Data[2]);
                end
            end
        end
    end

    function QuestTemplate:ShowQuestMarkers()
        for i=1, self.Objectives[0] do
            if self.Objectives[i].Type == Objective.Distance then
                if ((type(self.Objectives[i].Data[1]) == "number" and self.Objectives[i].Data[1] > 0) 
                or (type(self.Objectives[i].Data[1]) ~= "number")) and self.Objectives[i].Data[4] then
                    ShowQuestMarker(self.Objectives[i].Data[2]);
                end
            end
        end
    end
    
    QuestTemplate.IsObjectiveCompleted_QSBU_NPC_Rewrite = QuestTemplate.IsObjectiveCompleted;
    QuestTemplate.IsObjectiveCompleted = function(self, objective)
        local objectiveType = objective.Type;
        local data = objective.Data;
        if objective.Completed ~= nil then
            return objective.Completed;
        end

        if objectiveType ~= Objective.Distance then
            return self:IsObjectiveCompleted_QSBU_NPC_Rewrite(objective);
        else
            if data[1] == -65565 then
                if not IsExisting(data[3]) then
                    return false;
                end
                if not data[4].NpcInstance then
                    local NPC = NonPlayerCharacter:New(data[3]);
                    NPC:SetDialogPartner(data[2]);
                    data[4].NpcInstance = NPC;
                end
                if data[4].NpcInstance:HasTalkedTo(data[2]) then
                    objective.Completed = true;
                end
                if not objective.Completed then
                    if not data[4].NpcInstance:IsActive() then
                        data[4].NpcInstance:Activate();
                    end
                end
            else
                return self:IsObjectiveCompleted_QSBU_NPC_Rewrite(objective);
            end
        end
    end
end

---
-- Rotiert alle nahen Helden zum NPC und den NPC zu dem Helden,
-- der ihn angesprochen hat.
--
-- @within NonPlayerCharacter
-- @local
--
function BundleNonPlayerCharacter.Global.NonPlayerCharacter:RotateActors()
    assert(self ~= BundleNonPlayerCharacter.Global.NonPlayerCharacter, 'Can not be used in static context!');
    
    local PlayerID = Logic.EntityGetPlayer(BundleNonPlayerCharacter.Global.LastHeroEntityID);
    local KnightIDs = {};
    Logic.GetKnights(PlayerID, KnightIDs);
    for i= 1, #KnightIDs, 1 do
        if Logic.GetDistanceBetweenEntities(KnightIDs[i], BundleNonPlayerCharacter.Global.LastNpcEntityID) < 3000 then
            local x,y,z = Logic.EntityGetPos(KnightIDs[i]);
            if Logic.IsEntityMoving(KnightIDs[i]) then
                Logic.MoveEntity(KnightIDs[i], x, y);
            end
            LookAt(KnightIDs[i], self.Data.NpcName);
        end
    end
    
    local Offset = 0;
    if Logic.IsEntityInCategory(self.Data.NpcName, EntityCategories.Hero) == 1 then
        LookAt(self.Data.NpcName, BundleNonPlayerCharacter.Global.LastHeroEntityID, 25);
    else
        LookAt(self.Data.NpcName, BundleNonPlayerCharacter.Global.LastHeroEntityID);
    end
    LookAt(BundleNonPlayerCharacter.Global.LastHeroEntityID, self.Data.NpcName, 25);
end

---
-- Steuert das Verhalten des NPC.
-- Soll ein NPC einem Helden folgen, wird er stehen bleiben, wenn
-- er dem Helden zu nahe, oder zu weit von ihm entfernt ist.
-- Soll ein NPC einen Helden führen, ...
--
-- @param _ScriptName   Skriptname des NPC
-- @within NonPlayerCharacter
-- @local
--
function BundleNonPlayerCharacter.Global.NonPlayerCharacter:Control(_ScriptName)
    assert(self == BundleNonPlayerCharacter.Global.NonPlayerCharacter, 'Can not be used from instance!');
    if not IsExisting(_ScriptName) then
        return;
    end
    
    local NPC = NonPlayerCharacter:GetInstance(_ScriptName);
    if not NPC then
        return;
    end
    if not NPC:IsActive() then
        return;
    end

    if NPC.Data.FollowTarget ~= nil then
        local NpcID  = NPC:GetID();
        local HeroID = GetID(NPC.Data.FollowTarget);
        local DistanceToHero = Logic.GetDistanceBetweenEntities(NpcID, HeroID);
        
        local MinDistance = 400;
        if Logic.IsEntityInCategory(NpcID, EntityCategories.Hero) == 1 then
            MinDistance = 800;
        end
        if DistanceToHero < MinDistance or DistanceToHero > 3500 then
            Logic.SetTaskList(NpcID, TaskLists.TL_NPC_IDLE);
            return;
        end
        if DistanceToHero >= MinDistance then
            local x, y, z = Logic.EntityGetPos(HeroID);
            Logic.MoveSettler(NpcID, x, y);
            return;
        end
    end

    if NPC.Data.GuideTarget ~= nil then
        local NpcID    = NPC:GetID();
        local HeroID   = GetID(NPC.Data.GuideTarget);
        local TargetID = GetID(NPC.Data.GuideDestination);
        
        local DistanceToHero   = Logic.GetDistanceBetweenEntities(NpcID, HeroID);
        local DistanceToTarget = Logic.GetDistanceBetweenEntities(NpcID, TargetID);

        if DistanceToTarget > 2000 then
            if DistanceToHero < 1500 and not Logic.IsEntityMoving(NpcID) then
                local x, y, z = Logic.EntityGetPos(TargetID);
                Logic.MoveSettler(NpcID, x, y);
            elseif DistanceToHero > 3000 and Logic.IsEntityMoving(NpcID) then
                local x, y, z = Logic.EntityGetPos(NpcID);
                Logic.MoveSettler(NpcID, x, y);
            end
        end
    end
end

-- Local Script ----------------------------------------------------------------

---
-- Initialisiert das Bundle im lokalen Skript.
-- @within Application-Space
-- @local
--
function BundleNonPlayerCharacter.Local:Install()
    g_CurrentDisplayedQuestID = 0;

    GUI_Interaction.DisplayQuestObjective_Orig_QSBU_NPC_Rewrite = GUI_Interaction.DisplayQuestObjective
    GUI_Interaction.DisplayQuestObjective = function(_QuestIndex, _MessageKey)
        local lang = Network.GetDesiredLanguage();
        if lang ~= "de" then lang = "en" end

        local QuestIndexTemp = tonumber(_QuestIndex);
        if QuestIndexTemp then
            _QuestIndex = QuestIndexTemp;
        end

        local Quest, QuestType = GUI_Interaction.GetPotentialSubQuestAndType(_QuestIndex);
        local QuestObjectivesPath = "/InGame/Root/Normal/AlignBottomLeft/Message/QuestObjectives";
        XGUIEng.ShowAllSubWidgets("/InGame/Root/Normal/AlignBottomLeft/Message/QuestObjectives", 0);
        local QuestObjectiveContainer;
        local QuestTypeCaption;

        local ParentQuest = Quests[_QuestIndex];
        local ParentQuestIdentifier;
        if ParentQuest ~= nil
        and type(ParentQuest) == "table" then
            ParentQuestIdentifier = ParentQuest.Identifier;
        end
        local HookTable = {};

        g_CurrentDisplayedQuestID = _QuestIndex;

        if QuestType == Objective.Distance then
            QuestObjectiveContainer = QuestObjectivesPath .. "/List";
            QuestTypeCaption = Wrapped_GetStringTableText(_QuestIndex, "UI_Texts/QuestInteraction");
            local ObjectList = {};

            if Quest.Objectives[1].Data[1] == -65565 then
                QuestObjectiveContainer = QuestObjectivesPath .. "/Distance";
                QuestTypeCaption = Wrapped_GetStringTableText(_QuestIndex, "UI_Texts/QuestMoveHere");
                SetIcon(QuestObjectiveContainer .. "/QuestTypeIcon",{7,10});

                local MoverEntityID = GetEntityId(Quest.Objectives[1].Data[2]);
                local MoverEntityType = Logic.GetEntityType(MoverEntityID);
                local MoverIcon = g_TexturePositions.Entities[MoverEntityType];
                if Quest.Objectives[1].Data[1] == -65567 or not MoverIcon then
                    MoverIcon = {16,12};
                end
                SetIcon(QuestObjectiveContainer .. "/IconMover", MoverIcon);

                local TargetEntityID = GetEntityId(Quest.Objectives[1].Data[3]);
                local TargetEntityType = Logic.GetEntityType(TargetEntityID);
                local TargetIcon = g_TexturePositions.Entities[TargetEntityType];
                if not TargetIcon then
                    TargetIcon = {14,10};
                end

                local IconWidget = QuestObjectiveContainer .. "/IconTarget";
                local ColorWidget = QuestObjectiveContainer .. "/TargetPlayerColor";

                SetIcon(IconWidget, TargetIcon);
                XGUIEng.SetMaterialColor(ColorWidget, 0, 255, 255, 255, 0);

                SetIcon(QuestObjectiveContainer .. "/QuestTypeIcon",{16,12});
                local caption = {de = "Gespräch beginnen", en = "Start conversation"};
                QuestTypeCaption = caption[lang];

                XGUIEng.SetText(QuestObjectiveContainer.."/Caption","{center}"..QuestTypeCaption);
                XGUIEng.ShowWidget(QuestObjectiveContainer, 1);
            else
                GUI_Interaction.DisplayQuestObjective_Orig_QSBU_NPC_Rewrite(_QuestIndex, _MessageKey);
            end
        else
            GUI_Interaction.DisplayQuestObjective_Orig_QSBU_NPC_Rewrite(_QuestIndex, _MessageKey);
        end
    end
    
    GUI_Interaction.GetEntitiesOrTerritoryListForQuest_Orig_QSBU_NPC_Rewrite = GUI_Interaction.GetEntitiesOrTerritoryListForQuest
    GUI_Interaction.GetEntitiesOrTerritoryListForQuest = function( _Quest, _QuestType )
        local EntityOrTerritoryList = {}
        local IsEntity = true

        if _QuestType == Objective.Distance then
            if _Quest.Objectives[1].Data[1] == -65565 then
                local Entity = GetEntityId(_Quest.Objectives[1].Data[3]);
                table.insert(EntityOrTerritoryList, Entity);
            else
                return GUI_Interaction.GetEntitiesOrTerritoryListForQuest_Orig_QSBU_NPC_Rewrite( _Quest, _QuestType );
            end

        else
            return GUI_Interaction.GetEntitiesOrTerritoryListForQuest_Orig_QSBU_NPC_Rewrite( _Quest, _QuestType );
        end
        return EntityOrTerritoryList, IsEntity
    end
end

Core:RegisterBundle("BundleNonPlayerCharacter");

-- -------------------------------------------------------------------------- --
-- ########################################################################## --
-- #  Symfonia BundleKnightTitleRequirements                                # --
-- ########################################################################## --
-- -------------------------------------------------------------------------- --

---
-- Erlaubt es dem Mapper die vorgegebenen Aufstiegsbedingungen idividuell
-- an die eigenen Vorstellungen anzupassen.
--
-- Mögliche Aufstiegsbedingungen:
-- <ul>
-- <li><b>Entitytyp besitzen</b><br/>
-- Der Spieler muss eine bestimmte Anzahl von Entities eines Typs besitzen.
-- </li>
-- <li><b>Entitykategorie besitzen</b><br/>
-- Der Spieler muss eine bestimmte Anzahl von Entities einer Kategorie besitzen.
-- </li>
-- <li><b>Gütertyp besitzen</b><br/>
-- Der Spieler muss Rohstoffe oder Güter eines Typs besitzen.
-- </li>
-- <li><b>Produkte erzeugen</b><br/>
-- Der Spieler muss Gebrauchsgegenstände für ein Bedürfnis bereitstellen.
-- </li>
-- <li><b>Güter konsumieren</b><br/>
-- Die Siedler müssen eine Menge einer bestimmten Waren konsumieren.
-- </li>
-- <li><b>Vielfältigkeit bereitstellen</b><br/>
-- Der Spieler muss einen Vielfältigkeits-Buff aktivieren.
-- </li>
-- <li><b>Stadtruf erreichen</b><br/>
-- Der Ruf der Stadt muss einen bestimmten Wert erreichen oder überschreiten.
-- <li><b>Anzahl an Dekorationen</b><br/>
-- Der Spieler muss mindestens die Anzahl der angegebenen Dekoration besitzen.
-- </li>
-- <li><b>Anzahl voll dekorierter Gebäude</b><br/>
-- Anzahl an Gebäuden, an die alle vier Dekorationen angebracht sein müssen.
-- </li>
-- <li><b>Spezialgebäude ausbauen</b><br/>
-- Ein Spezielgebäude muss ausgebaut werden.
-- </li>
-- <li><b>Anzahl Siedler</b><br/>
-- Der Spieler benötigt eine Gesamtzahl an Siedlern.
-- </li>
-- <li><b>Anzahl reiche Stadtgebäude</b><br/>
-- Eine Anzahl an Gebäuden muss durch Einnahmen Reichtum erlangen.
-- </li>
-- <li><b>Benutzerdefiniert</b><br/>
-- Eine benutzerdefinierte Funktion, die entweder als Schalter oder als Zähler 
-- fungieren kann und true oder false zurückgeben muss.
-- </li>
-- </ul>
--
-- @module BundleKnightTitleRequirements
-- @set sort=true
--

API = API or {};
QSB = QSB or {};

QSB.RequirementTooltipTypes = {};
QSB.ConsumedGoodsCounter = {};

-- -------------------------------------------------------------------------- --
-- User-Space                                                                 --
-- -------------------------------------------------------------------------- --



-- -------------------------------------------------------------------------- --
-- Application-Space                                                          --
-- -------------------------------------------------------------------------- --

BundleKnightTitleRequirements = {
    Global = {},
    Local = {
        Data = {},
    }
};

-- Global Script ---------------------------------------------------------------

---
-- Installiert das Bundle im globalen Skript.
-- @within BundleKnightTitleRequirements
-- @local
--
function BundleKnightTitleRequirements.Global:Install()
    self:OverwriteConsumedGoods();
    InitKnightTitleTables();
end

---
-- Zählt den Konsumzähler rauf, sobald eine Ware konsumiert wird.
--
-- @param _PlayerID ID des Spielers
-- @param _Good     Warentyp
-- @within BundleKnightTitleRequirements
-- @local
--
function BundleKnightTitleRequirements.Global:RegisterConsumedGoods(_PlayerID, _Good)
    QSB.ConsumedGoodsCounter[_PlayerID]        = QSB.ConsumedGoodsCounter[_PlayerID] or {};
    QSB.ConsumedGoodsCounter[_PlayerID][_Good] = QSB.ConsumedGoodsCounter[_PlayerID][_Good] or 0;
    QSB.ConsumedGoodsCounter[_PlayerID][_Good] = QSB.ConsumedGoodsCounter[_PlayerID][_Good] +1;
end

---
-- Überschreibt GameCallback_ConsumeGood, sodass konsumierte Waren gezählt
-- werden können.
-- @within BundleKnightTitleRequirements
-- @local
--
function BundleKnightTitleRequirements.Global:OverwriteConsumedGoods()
    GameCallback_ConsumeGood_Orig_QSB_Requirements = GameCallback_ConsumeGood
    GameCallback_ConsumeGood = function(_Consumer, _Good, _Building)
        GameCallback_ConsumeGood_Orig_QSB_Requirements(_Consumer, _Good, _Building)

        local PlayerID = Logic.EntityGetPlayer(_Consumer);
        BundleKnightTitleRequirements.Global:RegisterConsumedGoods(PlayerID, _Good);
        Logic.ExecuteInLuaLocalState([[
            BundleKnightTitleRequirements.Global:RegisterConsumedGoods(
                ]] ..PlayerID.. [[, ]] .._Good.. [[
            );
        ]]);
    end
end

-- Local Script ----------------------------------------------------------------

---
-- Installiert das Bundle im lokalen Skript.
-- @within BundleKnightTitleRequirements
-- @local
--
function BundleKnightTitleRequirements.Local:Install()    
    self:OverwriteTooltips();
    self:InitTexturePositions();
    self:OverwriteUpdateRequirements();
    self:OverwritePromotionCelebration();
    InitKnightTitleTables();
end

---
-- Zählt den Konsumzähler rauf, sobald eine Ware konsumiert wird.
--
-- @param _PlayerID ID des Spielers
-- @param _Good     Warentyp
-- @within BundleKnightTitleRequirements
-- @local
--
function BundleKnightTitleRequirements.Local:RegisterConsumedGoods(_PlayerID, _Good)
    QSB.ConsumedGoodsCounter[_PlayerID]        = QSB.ConsumedGoodsCounter[_PlayerID] or {};
    QSB.ConsumedGoodsCounter[_PlayerID][_Good] = QSB.ConsumedGoodsCounter[_PlayerID][_Good] or 0;
    QSB.ConsumedGoodsCounter[_PlayerID][_Good] = QSB.ConsumedGoodsCounter[_PlayerID][_Good] +1;
end

---
-- Fügt einige weitere Einträge zu den Texturpositionen hinzu.
-- @within BundleKnightTitleRequirements
-- @local
--
function BundleKnightTitleRequirements.Local:InitTexturePositions()
    g_TexturePositions.EntityCategories[EntityCategories.GC_Food_Supplier]          = { 1, 1};
    g_TexturePositions.EntityCategories[EntityCategories.GC_Clothes_Supplier]       = { 1, 2};
    g_TexturePositions.EntityCategories[EntityCategories.GC_Hygiene_Supplier]       = {16, 1};
    g_TexturePositions.EntityCategories[EntityCategories.GC_Entertainment_Supplier] = { 1, 4};
    g_TexturePositions.EntityCategories[EntityCategories.GC_Luxury_Supplier]        = {16, 3};
    g_TexturePositions.EntityCategories[EntityCategories.GC_Weapon_Supplier]        = { 1, 7};
    g_TexturePositions.EntityCategories[EntityCategories.GC_Medicine_Supplier]      = { 2,10};
    g_TexturePositions.EntityCategories[EntityCategories.Outpost]                   = {12, 3};
    g_TexturePositions.EntityCategories[EntityCategories.Spouse]                    = { 5,15};
    g_TexturePositions.EntityCategories[EntityCategories.CattlePasture]             = { 3,16};
    g_TexturePositions.EntityCategories[EntityCategories.SheepPasture]              = { 4, 1};
    g_TexturePositions.EntityCategories[EntityCategories.Soldier]                   = { 7,12};
    g_TexturePositions.EntityCategories[EntityCategories.GrainField]                = {14, 2};
    g_TexturePositions.EntityCategories[EntityCategories.OuterRimBuilding]          = { 3, 4};
    g_TexturePositions.EntityCategories[EntityCategories.CityBuilding]              = { 8, 1};
    g_TexturePositions.EntityCategories[EntityCategories.Range]                     = { 9, 8};
    g_TexturePositions.EntityCategories[EntityCategories.Melee]                     = { 9, 7};
    g_TexturePositions.EntityCategories[EntityCategories.SiegeEngine]               = { 2,15};
    
    g_TexturePositions.Entities[Entities.B_Outpost]                                 = {12, 3};
    g_TexturePositions.Entities[Entities.B_Outpost_AS]                              = {12, 3};
    g_TexturePositions.Entities[Entities.B_Outpost_ME]                              = {12, 3};
    g_TexturePositions.Entities[Entities.B_Outpost_NA]                              = {12, 3};
    g_TexturePositions.Entities[Entities.B_Outpost_NE]                              = {12, 3};
    g_TexturePositions.Entities[Entities.B_Outpost_SE]                              = {12, 3};
    g_TexturePositions.Entities[Entities.B_Cathedral_Big]                           = { 3,12};
    g_TexturePositions.Entities[Entities.U_MilitaryBallista]                        = {10, 5};
    g_TexturePositions.Entities[Entities.U_Trebuchet]                               = { 9, 1};
    g_TexturePositions.Entities[Entities.U_SiegeEngineCart]                         = { 9, 4};

    g_TexturePositions.Needs[Needs.Medicine]                                        = { 2,10};

    g_TexturePositions.Technologies[Technologies.R_Castle_Upgrade_1]                = { 4, 7};
    g_TexturePositions.Technologies[Technologies.R_Castle_Upgrade_2]                = { 4, 7};
    g_TexturePositions.Technologies[Technologies.R_Castle_Upgrade_3]                = { 4, 7};
    g_TexturePositions.Technologies[Technologies.R_Cathedral_Upgrade_1]             = { 4, 5};
    g_TexturePositions.Technologies[Technologies.R_Cathedral_Upgrade_2]             = { 4, 5};
    g_TexturePositions.Technologies[Technologies.R_Cathedral_Upgrade_3]             = { 4, 5};
    g_TexturePositions.Technologies[Technologies.R_Storehouse_Upgrade_1]            = { 4, 6};
    g_TexturePositions.Technologies[Technologies.R_Storehouse_Upgrade_2]            = { 4, 6};
    g_TexturePositions.Technologies[Technologies.R_Storehouse_Upgrade_3]            = { 4, 6};

    g_TexturePositions.Buffs = g_TexturePositions.Buffs or {};

    g_TexturePositions.Buffs[Buffs.Buff_ClothesDiversity]                           = { 1, 2};
    g_TexturePositions.Buffs[Buffs.Buff_EntertainmentDiversity]                     = { 1, 4};
    g_TexturePositions.Buffs[Buffs.Buff_FoodDiversity]                              = { 1, 1};
    g_TexturePositions.Buffs[Buffs.Buff_HygieneDiversity]                           = { 1, 3};
    g_TexturePositions.Buffs[Buffs.Buff_Colour]                                     = { 5,11};
    g_TexturePositions.Buffs[Buffs.Buff_Entertainers]                               = { 5,12};
    g_TexturePositions.Buffs[Buffs.Buff_ExtraPayment]                               = { 1, 8};
    g_TexturePositions.Buffs[Buffs.Buff_Sermon]                                     = { 4,14};
    g_TexturePositions.Buffs[Buffs.Buff_Spice]                                      = { 5,10};
    g_TexturePositions.Buffs[Buffs.Buff_NoTaxes]                                    = { 1, 6};
    if Framework.GetGameExtraNo() ~= 0 then
        g_TexturePositions.Buffs[Buffs.Buff_Gems]                                   = { 1, 1, 1};
        g_TexturePositions.Buffs[Buffs.Buff_MusicalInstrument]                      = { 1, 3, 1};
        g_TexturePositions.Buffs[Buffs.Buff_Olibanum]                               = { 1, 2, 1};
    end

    g_TexturePositions.GoodCategories = g_TexturePositions.GoodCategories or {};

    g_TexturePositions.GoodCategories[GoodCategories.GC_Ammunition]                 = {10, 6};
    g_TexturePositions.GoodCategories[GoodCategories.GC_Animal]                     = { 4,16};
    g_TexturePositions.GoodCategories[GoodCategories.GC_Clothes]                    = { 1, 2};
    g_TexturePositions.GoodCategories[GoodCategories.GC_Document]                   = { 5, 6};
    g_TexturePositions.GoodCategories[GoodCategories.GC_Entertainment]              = { 1, 4};
    g_TexturePositions.GoodCategories[GoodCategories.GC_Food]                       = { 1, 1};
    g_TexturePositions.GoodCategories[GoodCategories.GC_Gold]                       = { 1, 8};
    g_TexturePositions.GoodCategories[GoodCategories.GC_Hygiene]                    = {16, 1};
    g_TexturePositions.GoodCategories[GoodCategories.GC_Luxury]                     = {16, 3};
    g_TexturePositions.GoodCategories[GoodCategories.GC_Medicine]                   = { 2,10};
    g_TexturePositions.GoodCategories[GoodCategories.GC_None]                       = {15,16};
    g_TexturePositions.GoodCategories[GoodCategories.GC_RawFood]                    = { 3, 4};
    g_TexturePositions.GoodCategories[GoodCategories.GC_RawMedicine]                = { 2, 2};
    g_TexturePositions.GoodCategories[GoodCategories.GC_Research]                   = { 5, 6};
    g_TexturePositions.GoodCategories[GoodCategories.GC_Resource]                   = { 3, 4};
    g_TexturePositions.GoodCategories[GoodCategories.GC_Tools]                      = { 4,12};
    g_TexturePositions.GoodCategories[GoodCategories.GC_Water]                      = { 1,16};
    g_TexturePositions.GoodCategories[GoodCategories.GC_Weapon]                     = { 8, 5};
end

---
-- Überschreibt die Aktualisierungsfunktion der Aufstiegsbedingungen.
-- @within BundleKnightTitleRequirements
-- @local
--
function BundleKnightTitleRequirements.Local:OverwriteUpdateRequirements()
    GUI_Knight.UpdateRequirements = function()
        local WidgetPos = BundleKnightTitleRequirements.Local.Data.RequirementWidgets;
        local RequirementsIndex = 1;

        local PlayerID = GUI.GetPlayerID();
        local CurrentTitle = Logic.GetKnightTitle(PlayerID);
        local NextTitle = CurrentTitle + 1;

        --Headline
        local KnightID = Logic.GetKnightID(PlayerID);
        local KnightType = Logic.GetEntityType(KnightID);
        XGUIEng.SetText("/InGame/Root/Normal/AlignBottomRight/KnightTitleMenu/NextKnightTitle", "{center}" .. GUI_Knight.GetTitleNameByTitleID(KnightType, NextTitle));
        XGUIEng.SetText("/InGame/Root/Normal/AlignBottomRight/KnightTitleMenu/NextKnightTitleWhite", "{center}" .. GUI_Knight.GetTitleNameByTitleID(KnightType, NextTitle));

        -- show Settlers
        if KnightTitleRequirements[NextTitle].Settlers ~= nil then
            SetIcon(WidgetPos[RequirementsIndex] .. "/Icon", {5,16})
            local IsFulfilled, CurrentAmount, NeededAmount = DoesNeededNumberOfSettlersForKnightTitleExist(PlayerID, NextTitle)
            XGUIEng.SetText(WidgetPos[RequirementsIndex] .. "/Amount", "{center}" .. CurrentAmount .. "/" .. NeededAmount)
            if IsFulfilled then
                XGUIEng.ShowWidget(WidgetPos[RequirementsIndex] .. "/Done", 1)
            else
                XGUIEng.ShowWidget(WidgetPos[RequirementsIndex] .. "/Done", 0)
            end
            XGUIEng.ShowWidget(WidgetPos[RequirementsIndex], 1)

            QSB.RequirementTooltipTypes[RequirementsIndex] = "Settlers";
            RequirementsIndex = RequirementsIndex +1;
        end

        -- show rich buildings
        if KnightTitleRequirements[NextTitle].RichBuildings ~= nil then
            SetIcon(WidgetPos[RequirementsIndex] .. "/Icon", {8,4});
            local IsFulfilled, CurrentAmount, NeededAmount = DoNeededNumberOfRichBuildingsForKnightTitleExist(PlayerID, NextTitle);
            if NeededAmount == -1 then
                NeededAmount = Logic.GetNumberOfPlayerEntitiesInCategory(PlayerID, EntityCategories.CityBuilding);
            end
            XGUIEng.SetText(WidgetPos[RequirementsIndex] .. "/Amount", "{center}" .. CurrentAmount .. "/" .. NeededAmount);
            if IsFulfilled then
                XGUIEng.ShowWidget(WidgetPos[RequirementsIndex] .. "/Done", 1);
            else
                XGUIEng.ShowWidget(WidgetPos[RequirementsIndex] .. "/Done", 0);
            end
            XGUIEng.ShowWidget(WidgetPos[RequirementsIndex], 1);

            QSB.RequirementTooltipTypes[RequirementsIndex] = "RichBuildings";
            RequirementsIndex = RequirementsIndex +1;
        end

        -- Castle
        if KnightTitleRequirements[NextTitle].Headquarters ~= nil then
            SetIcon(WidgetPos[RequirementsIndex] .. "/Icon", {4,7});
            local IsFulfilled, CurrentAmount, NeededAmount = DoNeededSpecialBuildingUpgradeForKnightTitleExist(PlayerID, NextTitle, EntityCategories.Headquarters);
            XGUIEng.SetText(WidgetPos[RequirementsIndex] .. "/Amount", "{center}" .. CurrentAmount + 1 .. "/" .. NeededAmount + 1);
            if IsFulfilled then
                XGUIEng.ShowWidget(WidgetPos[RequirementsIndex] .. "/Done", 1);
            else
                XGUIEng.ShowWidget(WidgetPos[RequirementsIndex] .. "/Done", 0);
            end
            XGUIEng.ShowWidget(WidgetPos[RequirementsIndex], 1);

            QSB.RequirementTooltipTypes[RequirementsIndex] = "Headquarters";
            RequirementsIndex = RequirementsIndex +1;
        end

        -- Storehouse
        if KnightTitleRequirements[NextTitle].Storehouse ~= nil then
            SetIcon(WidgetPos[RequirementsIndex] .. "/Icon", {4,6});
            local IsFulfilled, CurrentAmount, NeededAmount = DoNeededSpecialBuildingUpgradeForKnightTitleExist(PlayerID, NextTitle, EntityCategories.Storehouse);
            XGUIEng.SetText(WidgetPos[RequirementsIndex] .. "/Amount", "{center}" .. CurrentAmount + 1 .. "/" .. NeededAmount + 1);
            if IsFulfilled then
                XGUIEng.ShowWidget(WidgetPos[RequirementsIndex] .. "/Done", 1);
            else
                XGUIEng.ShowWidget(WidgetPos[RequirementsIndex] .. "/Done", 0);
            end
            XGUIEng.ShowWidget(WidgetPos[RequirementsIndex], 1);

            QSB.RequirementTooltipTypes[RequirementsIndex] = "Storehouse";
            RequirementsIndex = RequirementsIndex +1;
        end

        -- Cathedral
        if KnightTitleRequirements[NextTitle].Cathedrals ~= nil then
            SetIcon(WidgetPos[RequirementsIndex] .. "/Icon", {4,5});
            local IsFulfilled, CurrentAmount, NeededAmount = DoNeededSpecialBuildingUpgradeForKnightTitleExist(PlayerID, NextTitle, EntityCategories.Cathedrals);
            XGUIEng.SetText(WidgetPos[RequirementsIndex] .. "/Amount", "{center}" .. CurrentAmount + 1 .. "/" .. NeededAmount + 1);
            if IsFulfilled then
                XGUIEng.ShowWidget(WidgetPos[RequirementsIndex] .. "/Done", 1);
            else
                XGUIEng.ShowWidget(WidgetPos[RequirementsIndex] .. "/Done", 0);
            end
            XGUIEng.ShowWidget(WidgetPos[RequirementsIndex], 1);

            QSB.RequirementTooltipTypes[RequirementsIndex] = "Cathedrals";
            RequirementsIndex = RequirementsIndex +1;
        end

        -- Neue Bedingungen --------------------------------------------

        -- Volldekorierte Gebäude
        if KnightTitleRequirements[NextTitle].FullDecoratedBuildings ~= nil then
            local IsFulfilled, CurrentAmount, NeededAmount = DoNeededNumberOfFullDecoratedBuildingsForKnightTitleExist(PlayerID, NextTitle);
            local EntityCategory = KnightTitleRequirements[NextTitle].FullDecoratedBuildings;
            SetIcon(WidgetPos[RequirementsIndex].."/Icon"  , g_TexturePositions.Needs[Needs.Wealth]);

            XGUIEng.SetText(WidgetPos[RequirementsIndex] .. "/Amount", "{center}" .. CurrentAmount .. "/" .. NeededAmount);
            if IsFulfilled then
                XGUIEng.ShowWidget(WidgetPos[RequirementsIndex] .. "/Done", 1);
            else
                XGUIEng.ShowWidget(WidgetPos[RequirementsIndex] .. "/Done", 0);
            end
            XGUIEng.ShowWidget(WidgetPos[RequirementsIndex] , 1);

            QSB.RequirementTooltipTypes[RequirementsIndex] = "FullDecoratedBuildings";
            RequirementsIndex = RequirementsIndex +1;
        end

        -- Stadtruf
        if KnightTitleRequirements[NextTitle].Reputation ~= nil then
            SetIcon(WidgetPos[RequirementsIndex] .. "/Icon", {5,14});
            local IsFulfilled, CurrentAmount, NeededAmount = DoesNeededCityReputationForKnightTitleExist(PlayerID, NextTitle);
            XGUIEng.SetText(WidgetPos[RequirementsIndex] .. "/Amount", "{center}" .. CurrentAmount .. "/" .. NeededAmount);
            if IsFulfilled then
                XGUIEng.ShowWidget(WidgetPos[RequirementsIndex] .. "/Done", 1);
            else
                XGUIEng.ShowWidget(WidgetPos[RequirementsIndex] .. "/Done", 0);
            end
            XGUIEng.ShowWidget(WidgetPos[RequirementsIndex], 1);

            QSB.RequirementTooltipTypes[RequirementsIndex] = "Reputation";
            RequirementsIndex = RequirementsIndex +1;
        end

        -- Güter sammeln
        if KnightTitleRequirements[NextTitle].Goods ~= nil then
            for i=1, #KnightTitleRequirements[NextTitle].Goods do
                local GoodType = KnightTitleRequirements[NextTitle].Goods[i][1];
                SetIcon(WidgetPos[RequirementsIndex] .. "/Icon", g_TexturePositions.Goods[GoodType]);
                local IsFulfilled, CurrentAmount, NeededAmount = DoesNeededNumberOfGoodTypesForKnightTitleExist(PlayerID, NextTitle, i);
                XGUIEng.SetText(WidgetPos[RequirementsIndex] .. "/Amount", "{center}" .. CurrentAmount .. "/" .. NeededAmount);
                if IsFulfilled then
                    XGUIEng.ShowWidget(WidgetPos[RequirementsIndex] .. "/Done", 1);
                else
                    XGUIEng.ShowWidget(WidgetPos[RequirementsIndex] .. "/Done", 0);
                end
                XGUIEng.ShowWidget(WidgetPos[RequirementsIndex], 1);

                QSB.RequirementTooltipTypes[RequirementsIndex] = "Goods" .. i;
                RequirementsIndex = RequirementsIndex +1;
            end
        end

        -- Kategorien
        if KnightTitleRequirements[NextTitle].Category ~= nil then
            for i=1, #KnightTitleRequirements[NextTitle].Category do
                local Category = KnightTitleRequirements[NextTitle].Category[i][1];
                SetIcon(WidgetPos[RequirementsIndex] .. "/Icon", g_TexturePositions.EntityCategories[Category]);
                local IsFulfilled, CurrentAmount, NeededAmount = DoesNeededNumberOfEntitiesInCategoryForKnightTitleExist(PlayerID, NextTitle, i);
                XGUIEng.SetText(WidgetPos[RequirementsIndex] .. "/Amount", "{center}" .. CurrentAmount .. "/" .. NeededAmount);
                if IsFulfilled then
                    XGUIEng.ShowWidget(WidgetPos[RequirementsIndex] .. "/Done", 1);
                else
                    XGUIEng.ShowWidget(WidgetPos[RequirementsIndex] .. "/Done", 0);
                end
                XGUIEng.ShowWidget(WidgetPos[RequirementsIndex], 1);

                local EntitiesInCategory = {Logic.GetEntityTypesInCategory(Category)};
                if Logic.IsEntityTypeInCategory(EntitiesInCategory[1], EntityCategories.GC_Weapon_Supplier) == 1 then
                    QSB.RequirementTooltipTypes[RequirementsIndex] = "Weapons" .. i;
                elseif Logic.IsEntityTypeInCategory(EntitiesInCategory[1], EntityCategories.SiegeEngine) == 1 then
                    QSB.RequirementTooltipTypes[RequirementsIndex] = "HeavyWeapons" .. i;
                elseif Logic.IsEntityTypeInCategory(EntitiesInCategory[1], EntityCategories.Spouse) == 1 then
                    QSB.RequirementTooltipTypes[RequirementsIndex] = "Spouse" .. i;
                elseif Logic.IsEntityTypeInCategory(EntitiesInCategory[1], EntityCategories.Worker) == 1 then
                    QSB.RequirementTooltipTypes[RequirementsIndex] = "Worker" .. i;
                elseif Logic.IsEntityTypeInCategory(EntitiesInCategory[1], EntityCategories.Soldier) == 1 then
                    QSB.RequirementTooltipTypes[RequirementsIndex] = "Soldiers" .. i;
                elseif Logic.IsEntityTypeInCategory(EntitiesInCategory[1], EntityCategories.Outpost) == 1 then
                    QSB.RequirementTooltipTypes[RequirementsIndex] = "Outposts" .. i;
                elseif Logic.IsEntityTypeInCategory(EntitiesInCategory[1], EntityCategories.CattlePasture) == 1 then
                    QSB.RequirementTooltipTypes[RequirementsIndex] = "Cattle" .. i;
                elseif Logic.IsEntityTypeInCategory(EntitiesInCategory[1], EntityCategories.SheepPasture) == 1 then
                    QSB.RequirementTooltipTypes[RequirementsIndex] = "Sheep" .. i;
                elseif Logic.IsEntityTypeInCategory(EntitiesInCategory[1], EntityCategories.CityBuilding) == 1 then
                    QSB.RequirementTooltipTypes[RequirementsIndex] = "CityBuilding" .. i;
                elseif Logic.IsEntityTypeInCategory(EntitiesInCategory[1], EntityCategories.OuterRimBuilding) == 1 then
                    QSB.RequirementTooltipTypes[RequirementsIndex] = "OuterRimBuilding" .. i;
                elseif Logic.IsEntityTypeInCategory(EntitiesInCategory[1], EntityCategories.AttackableBuilding) == 1 then
                    QSB.RequirementTooltipTypes[RequirementsIndex] = "Buildings" .. i;
                else
                    QSB.RequirementTooltipTypes[RequirementsIndex] = "EntityCategoryDefault" .. i;
                end
                RequirementsIndex = RequirementsIndex +1;
            end
        end

        -- Entities
        if KnightTitleRequirements[NextTitle].Entities ~= nil then
            for i=1, #KnightTitleRequirements[NextTitle].Entities do
                local EntityType = KnightTitleRequirements[NextTitle].Entities[i][1];
                SetIcon(WidgetPos[RequirementsIndex] .. "/Icon", g_TexturePositions.Entities[EntityType]);
                local IsFulfilled, CurrentAmount, NeededAmount = DoesNeededNumberOfEntitiesOfTypeForKnightTitleExist(PlayerID, NextTitle, i);
                XGUIEng.SetText(WidgetPos[RequirementsIndex] .. "/Amount", "{center}" .. CurrentAmount .. "/" .. NeededAmount);
                if IsFulfilled then
                    XGUIEng.ShowWidget(WidgetPos[RequirementsIndex] .. "/Done", 1);
                else
                    XGUIEng.ShowWidget(WidgetPos[RequirementsIndex] .. "/Done", 0);
                end
                XGUIEng.ShowWidget(WidgetPos[RequirementsIndex], 1);

                QSB.RequirementTooltipTypes[RequirementsIndex] = "Entities" .. i;
                RequirementsIndex = RequirementsIndex +1;
            end
        end

        -- Güter konsumieren
        if KnightTitleRequirements[NextTitle].Consume ~= nil then
            for i=1, #KnightTitleRequirements[NextTitle].Consume do
                local GoodType = KnightTitleRequirements[NextTitle].Consume[i][1];
                SetIcon(WidgetPos[RequirementsIndex] .. "/Icon", g_TexturePositions.Goods[GoodType]);
                local IsFulfilled, CurrentAmount, NeededAmount = DoNeededNumberOfConsumedGoodsForKnightTitleExist(PlayerID, NextTitle, i);
                XGUIEng.SetText(WidgetPos[RequirementsIndex] .. "/Amount", "{center}" .. CurrentAmount .. "/" .. NeededAmount);
                if IsFulfilled then
                    XGUIEng.ShowWidget(WidgetPos[RequirementsIndex] .. "/Done", 1);
                else
                    XGUIEng.ShowWidget(WidgetPos[RequirementsIndex] .. "/Done", 0);
                end
                XGUIEng.ShowWidget(WidgetPos[RequirementsIndex], 1);

                QSB.RequirementTooltipTypes[RequirementsIndex] = "Consume" .. i;
                RequirementsIndex = RequirementsIndex +1;
            end
        end

        -- Güter aus Gruppe produzieren
        if KnightTitleRequirements[NextTitle].Products ~= nil then
            for i=1, #KnightTitleRequirements[NextTitle].Products do
                local Product = KnightTitleRequirements[NextTitle].Products[i][1];
                SetIcon(WidgetPos[RequirementsIndex] .. "/Icon", g_TexturePositions.GoodCategories[Product]);
                local IsFulfilled, CurrentAmount, NeededAmount = DoNumberOfProductsInCategoryExist(PlayerID, NextTitle, i);
                XGUIEng.SetText(WidgetPos[RequirementsIndex] .. "/Amount", "{center}" .. CurrentAmount .. "/" .. NeededAmount);
                if IsFulfilled then
                    XGUIEng.ShowWidget(WidgetPos[RequirementsIndex] .. "/Done", 1);
                else
                    XGUIEng.ShowWidget(WidgetPos[RequirementsIndex] .. "/Done", 0);
                end
                XGUIEng.ShowWidget(WidgetPos[RequirementsIndex], 1);

                QSB.RequirementTooltipTypes[RequirementsIndex] = "Products" .. i;
                RequirementsIndex = RequirementsIndex +1;
            end
        end

        -- Bonus aktivieren
        if KnightTitleRequirements[NextTitle].Buff ~= nil then
            for i=1, #KnightTitleRequirements[NextTitle].Buff do
                local Buff = KnightTitleRequirements[NextTitle].Buff[i];
                SetIcon(WidgetPos[RequirementsIndex] .. "/Icon", g_TexturePositions.Buffs[Buff]);
                local IsFulfilled = DoNeededDiversityBuffForKnightTitleExist(PlayerID, NextTitle, i);
                XGUIEng.SetText(WidgetPos[RequirementsIndex] .. "/Amount", "");
                if IsFulfilled then
                    XGUIEng.ShowWidget(WidgetPos[RequirementsIndex] .. "/Done", 1);
                else
                    XGUIEng.ShowWidget(WidgetPos[RequirementsIndex] .. "/Done", 0);
                end
                XGUIEng.ShowWidget(WidgetPos[RequirementsIndex], 1);

                QSB.RequirementTooltipTypes[RequirementsIndex] = "Buff" .. i;
                RequirementsIndex = RequirementsIndex +1;
            end
        end

        -- Selbstdefinierte Bedingung
        if KnightTitleRequirements[NextTitle].Custom ~= nil then
            for i=1, #KnightTitleRequirements[NextTitle].Custom do
                local Icon = KnightTitleRequirements[NextTitle].Custom[i][2];
                BundleKnightTitleRequirements.Local:RequirementIcon(WidgetPos[RequirementsIndex] .. "/Icon", Icon);
                local IsFulfilled, CurrentAmount, NeededAmount = DoCustomFunctionForKnightTitleSucceed(PlayerID, NextTitle, i);
                if CurrentAmount and NeededAmount then
                    XGUIEng.SetText(WidgetPos[RequirementsIndex] .. "/Amount", "{center}" .. CurrentAmount .. "/" .. NeededAmount);
                else
                    XGUIEng.SetText(WidgetPos[RequirementsIndex] .. "/Amount", "");
                end
                if IsFulfilled then
                    XGUIEng.ShowWidget(WidgetPos[RequirementsIndex] .. "/Done", 1);
                else
                    XGUIEng.ShowWidget(WidgetPos[RequirementsIndex] .. "/Done", 0);
                end
                XGUIEng.ShowWidget(WidgetPos[RequirementsIndex], 1);

                QSB.RequirementTooltipTypes[RequirementsIndex] = "Custom" .. i;
                RequirementsIndex = RequirementsIndex +1;
            end
        end

        -- Dekorationselemente
        if KnightTitleRequirements[NextTitle].DecoratedBuildings ~= nil then
            for i=1, #KnightTitleRequirements[NextTitle].DecoratedBuildings do
                local GoodType = KnightTitleRequirements[NextTitle].DecoratedBuildings[i][1];
                SetIcon(WidgetPos[RequirementsIndex].."/Icon", g_TexturePositions.Goods[GoodType]);
                local IsFulfilled, CurrentAmount, NeededAmount = DoNeededNumberOfDecoratedBuildingsForKnightTitleExist(PlayerID, NextTitle, i);
                XGUIEng.SetText(WidgetPos[RequirementsIndex] .. "/Amount", "{center}" .. CurrentAmount .. "/" .. NeededAmount);
                if IsFulfilled then
                    XGUIEng.ShowWidget(WidgetPos[RequirementsIndex] .. "/Done", 1);
                else
                    XGUIEng.ShowWidget(WidgetPos[RequirementsIndex] .. "/Done", 0);
                end
                XGUIEng.ShowWidget(WidgetPos[RequirementsIndex], 1);

                QSB.RequirementTooltipTypes[RequirementsIndex] = "DecoratedBuildings" ..i;
                RequirementsIndex = RequirementsIndex +1;
            end
        end

        -- Übrige ausblenden
        for i=RequirementsIndex, 6 do
            XGUIEng.ShowWidget(WidgetPos[i], 0);
        end
    end
end

---
-- Überschreibt die Beförderung des Primary Knight.
-- @within BundleKnightTitleRequirements
-- @local
--
function BundleKnightTitleRequirements.Local:OverwritePromotionCelebration()
    StartKnightsPromotionCelebration = function( _PlayerID , _OldTitle, _FirstTime)
        if _PlayerID ~= GUI.GetPlayerID() or Logic.GetTime() < 5 then
            return;
        end

        local MarketplaceID = Logic.GetMarketplace(_PlayerID);

        if _FirstTime == 1 then
            local KnightID = Logic.GetKnightID(_PlayerID);
            local Random

            repeat
                Random = 1 + XGUIEng.GetRandom(3)
            until Random ~= g_LastGotPromotionMessageRandom

            g_LastGotPromotionMessageRandom = Random;
            local TextKey = "Title_GotPromotion" .. Random;
            LocalScriptCallback_QueueVoiceMessage(_PlayerID, TextKey, false, _PlayerID);
            GUI.StartFestival(_PlayerID, 1);
        end

        -- reset local
        local Consume = QSB.ConsumedGoodsCounter[_PlayerID];
        QSB.ConsumedGoodsCounter[_PlayerID] = Consume or {};
        for k,v in pairs(QSB.ConsumedGoodsCounter[_PlayerID]) do
            QSB.ConsumedGoodsCounter[_PlayerID][k] = 0;
        end

        -- reset global
        GUI.SendScriptCommand([[
            local Consume = QSB.ConsumedGoodsCounter[]].._PlayerID..[[];
            QSB.ConsumedGoodsCounter[]].._PlayerID..[[] = Consume or {};
            for k,v in pairs(QSB.ConsumedGoodsCounter[]].._PlayerID..[[]) do
                QSB.ConsumedGoodsCounter[]].._PlayerID..[[][k] = 0;
            end
        ]]);

        XGUIEng.ShowWidget("/InGame/Root/Normal/AlignBottomRight/KnightTitleMenu", 0);
        XGUIEng.ShowWidget("/InGame/Root/Normal/AlignTopCenter/KnightTitleMenuBig", 0);
        g_WantsPromotionMessageInterval = 30;
        g_TimeOfPromotionPossible = nil;
    end
end

---
-- Überschreibt die Tooltips im Aufstiegsmenü.
-- @within BundleKnightTitleRequirements
-- @local
--
function BundleKnightTitleRequirements.Local:OverwriteTooltips()
    GUI_Tooltip.SetNameAndDescription_Orig_QSB_Requirements = GUI_Tooltip.SetNameAndDescription;
    GUI_Tooltip.SetNameAndDescription = function(_TooltipNameWidget, _TooltipDescriptionWidget, _OptionalTextKeyName, _OptionalDisabledTextKeyName, _OptionalMissionTextFileBoolean)
        local CurrentWidgetID = XGUIEng.GetCurrentWidgetID();
        local Selected = GUI.GetSelectedEntity();
        local PlayerID = GUI.GetPlayerID();
    
        for k,v in pairs(BundleKnightTitleRequirements.Local.Data.RequirementWidgets) do
            if v .. "/Icon" == XGUIEng.GetWidgetPathByID(CurrentWidgetID) then
                local key = QSB.RequirementTooltipTypes[k];
                local num = tonumber(string.sub(key, string.len(key)));
                if num ~= nil then
                    key = string.sub(key, 1, string.len(key)-1);
                end
                BundleKnightTitleRequirements.Local:RequirementTooltipWrapped(key, num);
                return;
            end
        end
        GUI_Tooltip.SetNameAndDescription_Orig_QSB_Requirements(_TooltipNameWidget, _TooltipDescriptionWidget, _OptionalTextKeyName, _OptionalDisabledTextKeyName, _OptionalMissionTextFileBoolean);
    end
    
    GUI_Knight.RequiredGoodTooltip = function()
        local key = QSB.RequirementTooltipTypes[2];
        local num = tonumber(string.sub(key, string.len(key)));
        if num ~= nil then
            key = string.sub(key, 1, string.len(key)-1);
        end
        BundleKnightTitleRequirements.Local:RequirementTooltipWrapped(key, num);
    end
    
    if Framework.GetGameExtraNo() ~= 0 then
        BundleKnightTitleRequirements.Local.Data.BuffTypeNames[Buffs.Buff_Gems] = {
            de = "Edelsteine beschaffen", en = "Obtain gems"
        }
        BundleKnightTitleRequirements.Local.Data.BuffTypeNames[Buffs.Buff_Olibanum] = {
            de = "Weihrauch beschaffen", en = "Obtain olibanum"
        }
        BundleKnightTitleRequirements.Local.Data.BuffTypeNames[Buffs.Buff_MusicalInstrument] = {
            de = "Muskinstrumente beschaffen", en = "Obtain instruments"
        }
    end
end

---
-- Ändert die Textur eines Icons in den Aufstiegsbedingungen.
--
-- Icons für Aufstiegsbedingungen können sein:
-- <ul>
-- <li>Koordinaten auf der Spielinternen Icon Matrix</li>
-- <li>Koordinaten auf einer externen Icon Matrix (Name .. "big.png")</li>
-- <li>Pfad zu einelnem Icon (200x200 Pixel)</li>
-- </ul>
--
-- @param _Widget Icon Widget
-- @param _Icon   Icon Textur
-- @within BundleKnightTitleRequirements
-- @local
--
function BundleKnightTitleRequirements.Local:RequirementIcon(_Widget, _Icon)
    if type(_Icon) == "table" then
        if type(_Icon[3]) == "string" then
            local u0, u1, v0, v1;
            u0 = (_Coordinates[1] - 1) * 64;
            v0 = (_Coordinates[2] - 1) * 64;
            u1 = (_Coordinates[1]) * 64;
            v1 = (_Coordinates[2]) * 64;
            XGUIEng.SetMaterialAlpha(_Widget, 1, 255);
            XGUIEng.SetMaterialTexture(_Widget, 1, _Icon[3].. "big.png");
            XGUIEng.SetMaterialUV(_Widget, 1, u0, v0, u1, v1);
        else
            SetIcon(_Widget, _Icon);
        end
    else
        local screenSize = {GUI.GetScreenSize()};
        local Scale = 330;
        if screenSize[2] >= 800 then
            Scale = 260;
        end
        if screenSize[2] >= 1000 then
            Scale = 210;
        end
        XGUIEng.SetMaterialAlpha(_Widget, 1, 255);
        XGUIEng.SetMaterialTexture(_Widget, 1, _file);
        XGUIEng.SetMaterialUV(_Widget, 1, 0, 0, Scale, Scale);
    end
end

---
-- Setzt einen für den Tooltip des aktuellen Widget einen neuen Text.
--
-- @param _Title Titel des Tooltip
-- @param _Text  Text des Tooltip
-- @within BundleKnightTitleRequirements
-- @local
--
function BundleKnightTitleRequirements.Local:RequirementTooltip(_Title, _Text)
    local TooltipContainerPath = "/InGame/Root/Normal/TooltipNormal";
    local TooltipContainer = XGUIEng.GetWidgetID(TooltipContainerPath);
    local TooltipNameWidget = XGUIEng.GetWidgetID(TooltipContainerPath .. "/FadeIn/Name");
    local TooltipDescriptionWidget = XGUIEng.GetWidgetID(TooltipContainerPath .. "/FadeIn/Text");
    local TooltipBGWidget = XGUIEng.GetWidgetID(TooltipContainerPath .. "/FadeIn/BG");
    local TooltipFadeInContainer = XGUIEng.GetWidgetID(TooltipContainerPath .. "/FadeIn");
    local PositionWidget = XGUIEng.GetCurrentWidgetID();
    GUI_Tooltip.ResizeBG(TooltipBGWidget, TooltipDescriptionWidget);
    local TooltipContainerSizeWidgets = {TooltipBGWidget};
    GUI_Tooltip.SetPosition(TooltipContainer, TooltipContainerSizeWidgets, PositionWidget);
    GUI_Tooltip.FadeInTooltip(TooltipFadeInContainer);

    XGUIEng.SetText(TooltipNameWidget, "{center}" .. _Title);
    XGUIEng.SetText(TooltipDescriptionWidget, _Text);
    local Height = XGUIEng.GetTextHeight(TooltipDescriptionWidget, true);
    local W, H = XGUIEng.GetWidgetSize(TooltipDescriptionWidget);
    XGUIEng.SetWidgetSize(TooltipDescriptionWidget, W, Height);
end

---
-- Ermittelt die veränderten Texte für den Tooltip hinter dem angegebenen Key.
--
-- @param _key Index in Description
-- @param _i   Buttonindex
-- @within BundleKnightTitleRequirements
-- @local
--
function BundleKnightTitleRequirements.Local:RequirementTooltipWrapped(_key, _i)
    local lang = (Network.GetDesiredLanguage() == "de" and "de") or "en";
    local PlayerID = GUI.GetPlayerID();
    local KnightTitle = Logic.GetKnightTitle(PlayerID);
    local Title = ""
    local Text = "";

    if _key == "Consume" or _key == "Goods" or _key == "DecoratedBuildings" then
        local GoodType     = KnightTitleRequirements[KnightTitle+1][_key][_i][1];
        local GoodTypeName = Logic.GetGoodTypeName(GoodType);
        local GoodName     = XGUIEng.GetStringTableText("UI_ObjectNames/" .. GoodTypeName);

        if GoodName == nil then
            GoodName = "Goods." .. GoodTypeName;
        end
        Title = GoodName;
        Text  = BundleKnightTitleRequirements.Local.Data.Description[_key].Text;

    elseif _key == "Products" then
        local GoodCategoryNames = BundleKnightTitleRequirements.Local.Data.GoodCategoryNames;
        local Category = KnightTitleRequirements[KnightTitle+1][_key][_i][1];
        local CategoryName = GoodCategoryNames[Category][lang];

        if CategoryName == nil then
            CategoryName = "ERROR: Name missng!";
        end
        Title = CategoryName;
        Text  = BundleKnightTitleRequirements.Local.Data.Description[_key].Text;

    elseif _key == "Entities" then
        local EntityType     = KnightTitleRequirements[KnightTitle+1][_key][_i][1];
        local EntityTypeName = Logic.GetEntityTypeName(EntityType);
        local EntityName = XGUIEng.GetStringTableText("Names/" .. EntityTypeName);

        if EntityName == nil then
            EntityName = "Entities." .. EntityTypeName;
        end

        Title = EntityName;
        Text  = BundleKnightTitleRequirements.Local.Data.Description[_key].Text;

    elseif _key == "Custom" then
        local Custom = KnightTitleRequirements[KnightTitle+1].Custom[_i];
        Title = Custom[3];
        Text  = Custom[4];
        
    elseif _key == "Buff" then
        local BuffTypeNames = BundleKnightTitleRequirements.Local.Data.BuffTypeNames;
        local BuffType = KnightTitleRequirements[KnightTitle+1][_key][_i];
        local BuffTitle = BuffTypeNames[BuffType][lang];
        
        if BuffTitle == nil then
            BuffTitle = "ERROR: Name missng!";
        end
        Title = BuffTitle;
        Text  = BundleKnightTitleRequirements.Local.Data.Description[_key].Text;

    else
        Title = BundleKnightTitleRequirements.Local.Data.Description[_key].Title;
        Text  = BundleKnightTitleRequirements.Local.Data.Description[_key].Text;
    end
    
    Title = (type(Title) == "table" and Title[lang]) or Title;
    Text  = (type(Text) == "table" and Text[lang]) or Text;
    self:RequirementTooltip(Title, Text);
end

BundleKnightTitleRequirements.Local.Data.RequirementWidgets = {
    [1] = "/InGame/Root/Normal/AlignBottomRight/KnightTitleMenu/Requirements/Settlers",
    [2] = "/InGame/Root/Normal/AlignBottomRight/KnightTitleMenu/Requirements/Goods",
    [3] = "/InGame/Root/Normal/AlignBottomRight/KnightTitleMenu/Requirements/RichBuildings",
    [4] = "/InGame/Root/Normal/AlignBottomRight/KnightTitleMenu/Requirements/Castle",
    [5] = "/InGame/Root/Normal/AlignBottomRight/KnightTitleMenu/Requirements/Storehouse",
    [6] = "/InGame/Root/Normal/AlignBottomRight/KnightTitleMenu/Requirements/Cathedral",
};

BundleKnightTitleRequirements.Local.Data.GoodCategoryNames = {
    [GoodCategories.GC_Ammunition]      = {de = "Munition", en = "Ammunition"},
    [GoodCategories.GC_Animal]          = {de = "Nutztiere", en = "Livestock"},
    [GoodCategories.GC_Clothes]         = {de = "Kleidung", en = "Clothes"},
    [GoodCategories.GC_Document]        = {de = "Dokumente", en = "Documents"},
    [GoodCategories.GC_Entertainment]   = {de = "Unterhaltung", en = "Entertainment"},
    [GoodCategories.GC_Food]            = {de = "Nahrungsmittel", en = "Food"},
    [GoodCategories.GC_Gold]            = {de = "Gold", en = "Gold"},
    [GoodCategories.GC_Hygiene]         = {de = "Hygieneartikel", en = "Hygiene"},
    [GoodCategories.GC_Luxury]          = {de = "Dekoration", en = "Decoration"},
    [GoodCategories.GC_Medicine]        = {de = "Medizin", en = "Medicine"},
    [GoodCategories.GC_None]            = {de = "Nichts", en = "None"},
    [GoodCategories.GC_RawFood]         = {de = "Nahrungsmittel", en = "Food"},
    [GoodCategories.GC_RawMedicine]     = {de = "Medizin", en = "Medicine"},
    [GoodCategories.GC_Research]        = {de = "Forschung", en = "Research"},
    [GoodCategories.GC_Resource]        = {de = "Rohstoffe", en = "Resource"},
    [GoodCategories.GC_Tools]           = {de = "Werkzeug", en = "Tools"},
    [GoodCategories.GC_Water]           = {de = "Wasser", en = "Water"},
    [GoodCategories.GC_Weapon]          = {de = "Waffen", en = "Weapon"},
};

BundleKnightTitleRequirements.Local.Data.BuffTypeNames = {
    [Buffs.Buff_ClothesDiversity]        = {de = "Abwechslungsreiche Kleidung", en = "Clothes diversity"},
    [Buffs.Buff_Colour]                  = {de = "Farben beschaffen", en = "Obtain color"},
    -- Funktioniert nicht, belegt MP
    [Buffs.Buff_Entertainers]            = {de = "Gaukler anheuern", en = "Hire entertainer"},
    [Buffs.Buff_EntertainmentDiversity]  = {de = "Abwechslungsreiche Unterhaltung", en = "Entertainment diversity"},
    [Buffs.Buff_ExtraPayment]            = {de = "Sonderzahlung", en = "Extra payment"},
    -- Funktioniert nicht, belegt MP
    [Buffs.Buff_Festival]                = {de = "Fest veranstalten", en = "Hold Festival"},
    [Buffs.Buff_FoodDiversity]           = {de = "Abwechslungsreiche Nahrung", en = "Food diversity"},
    [Buffs.Buff_HygieneDiversity]        = {de = "Abwechslungsreiche Hygiene", en = "Hygiene diversity"},
    [Buffs.Buff_NoTaxes]                 = {de = "Steuerbefreiung", en = "No taxes"},
    [Buffs.Buff_Sermon]                  = {de = "Pregigt abhalten", en = "Hold sermon"},
    [Buffs.Buff_Spice]                   = {de = "Salz beschaffen", en = "Obtain salt"},
};

BundleKnightTitleRequirements.Local.Data.Description = {
    Settlers = {
        Title = {
            de = "Benötigte Siedler",
            en = "Needed settlers",
        },
        Text = {
            de = "- Benötigte Menge an Siedlern",
            en = "- Needed number of settlers",
        },
    },
    
    RichBuildings = {
        Title = {
            de = "Reiche Stadtgebäude",
            en = "Rich city buildings",
        },
        Text = {
            de = "- Menge an reichen Stadtgebäuden",
            en = "- Needed amount of rich city buildings",
        },
    },
    
    Goods = {
        Title = {
            de = "Waren lagern",
            en = "Store Goods",
        },
        Text = {
            de = "- Benötigte Menge",
            en = "- Needed amount",
        },
    },
    
    FullDecoratedBuildings = {
        Title = {
            de = "Dekorierte Stadtgebäude",
            en = "Decorated City buildings",
        },
        Text = {
            de = "- Menge an voll dekorierten Gebäuden",
            en = "- Amount of full decoraded city buildings",
        },
    },
    
    DecoratedBuildings = {
        Title = {
            de = "Dekoration",
            en = "Decoration",
        },
        Text = {
            de = "- Menge an Dekorationsgütern in der Siedlung",
            en = "- Amount of decoration goods in settlement",
        },
    },
    
    Headquarters = {
        Title = {
            de = "Burgstufe",
            en = "Castle level",
        },
        Text = {
            de = "- Benötigte Ausbauten der Burg",
            en = "- Needed castle upgrades",
        },
    },
    
    Storehouse = {
        Title = {
            de = "Lagerhausstufe",
            en = "Storehouse level",
        },
        Text = {
            de = "- Benötigte Ausbauten des Lagerhauses",
            en = "- Needed storehouse upgrades",
        },
    },
    
    Cathedrals = {
        Title = {
            de = "Kirchenstufe",
            en = "Cathedral level",
        },
        Text = {
            de = "- Benötigte Ausbauten der Kirche",
            en = "- Needed cathedral upgrades",
        },
    },

    Reputation = {
        Title = {
            de = "Ruf der Stadt",
            en = "City reputation",
        },
        Text = {
            de = "- Benötigter Ruf der Stadt",
            en = "- Needed city reputation",
        },
    },

    EntityCategoryDefault = {
        Title = {
            de = "",
            en = "",
        },
        Text = {
            de = "- Benötigte Anzahl",
            en = "- Needed amount",
        },
    },
    
    Cattle = {
        Title = {
            de = "Kühe",
            en = "Cattle",
        },
        Text = {
            de = "- Benötigte Menge an Kühen",
            en = "- Needed amount of cattle",
        },
    },
    
    Sheep = {
        Title = {
            de = "Schafe",
            en = "Sheeps",
        },
        Text = {
            de = "- Benötigte Menge an Schafen",
            en = "- Needed amount of sheeps",
        },
    },
    
    Outposts = {
        Title = {
            de = "Territorien",
            en = "Territories",
        },
        Text = {
            de = "- Zu erobernde Territorien",
            en = "- Territories to claim",
        },
    },
    
    CityBuilding = {
        Title = {
            de = "Stadtgebäude",
            en = "City buildings",
        },
        Text = {
            de = "- Menge benötigter Stadtgebäude",
            en = "- Needed amount of city buildings",
        },
    },
    
    OuterRimBuilding = {
        Title = {
            de = "Rohstoffgebäude",
            en = "Gatherer",
        },
        Text = {
            de = "- Menge benötigter Rohstoffgebäude",
            en = "- Needed amount of gatherer",
        },
    },
    
    Consume = {
        Title = {
            de = "",
            en = "",
        },
        Text = {
            de = "- Durch Siedler zu konsumierende Menge",
            en = "- Amount to be consumed by the settlers",
        },
    },
    
    Products = {
        Title = {
            de = "",
            en = "",
        },
        Text = {
            de = "- Benötigte Menge",
            en = "- Needed amount",
        },
    },
    
    Buff = {
        Title = {
            de = "Bonus aktivieren",
            en = "Activate Buff",
        },
        Text = {
            de = "- Aktiviere diesen Bonus auf den Ruf der Stadt",
            en = "- Raise the city reputatition with this buff",
        },
    },
    
    Soldiers = {
        Title = {
            de = "Soldaten",
            en = "Soldiers",
        },
        Text = {
            de = "- Menge an Streitkräften unterhalten",
            en = "- Soldiers you need under your command",
        },
    },
    
    Worker = {
        Title = {
            de = "Arbeiter",
            en = "Workers",
        },
        Text = {
            de = "- Menge an arbeitender Bevölkerung",
            en = "- Workers you need under your reign",
        },
    },
    
    Entities = {
        Title = {
            de = "",
            en = "",
        },
        Text = {
            de = "- Benötigte Menge",
            en = "- Needed Amount",
        },
    },
    
    Buildings = {
        Title = {
            de = "Gebäude",
            en = "Buildings",
        },
        Text = {
            de = "- Gesamtmenge an Gebäuden",
            en = "- Amount of buildings",
        },
    },
    
    Weapons = {
        Title = {
            de = "Waffen",
            en = "Weapons",
        },
        Text = {
            de = "- Benötigte Menge an Waffen",
            en = "- Needed amount of weapons",
        },
    },
    
    HeavyWeapons = {
        Title = {
            de = "Belagerungsgeräte",
            en = "Siege Engines",
        },
        Text = {
            de = "- Benötigte Menge an Belagerungsgeräten",
            en = "- Needed amount of siege engine",
        },
    },
    
    Spouse = {
        Title = {
            de = "Ehefrauen",
            en = "Spouses",
        },
        Text = {
            de = "- Benötigte Anzahl Ehefrauen in der Stadt",
            en = "- Needed amount of spouses in your city",
        },
    },
};

Core:RegisterBundle("BundleKnightTitleRequirements");

-- -------------------------------------------------------------------------- --
-- Spielfunktionen                                                            --
-- -------------------------------------------------------------------------- --

---
-- Prüft, ob genug Entities in einer bestimmten Kategorie existieren.
--
-- @param _PlayerID    ID des Spielers
-- @param _KnightTitle Nächster Titel
-- @param _i           Button Index
-- @within BB-Funktionen
-- @local
--
DoesNeededNumberOfEntitiesInCategoryForKnightTitleExist = function(_PlayerID, _KnightTitle, _i)
    if KnightTitleRequirements[_KnightTitle].Category == nil then
        return;
    end
    if _i then
        local EntityCategory = KnightTitleRequirements[_KnightTitle].Category[_i][1];
        local NeededAmount = KnightTitleRequirements[_KnightTitle].Category[_i][2];

        local ReachedAmount = 0;
        if EntityCategory == EntityCategories.Spouse then
            ReachedAmount = Logic.GetNumberOfSpouses(_PlayerID);
        else
            local Buildings = {Logic.GetPlayerEntitiesInCategory(_PlayerID, EntityCategory)};
            for i=1, #Buildings do
                if Logic.IsBuilding(Buildings[i]) == 1 then
                    if Logic.IsConstructionComplete(Buildings[i]) == 1 then
                        ReachedAmount = ReachedAmount +1;
                    end
                else
                    ReachedAmount = ReachedAmount +1;
                end
            end
        end

        if ReachedAmount >= NeededAmount then
            return true, ReachedAmount, NeededAmount;
        end
        return false, ReachedAmount, NeededAmount;
    else
        local bool, reach, need;
        for i=1,#KnightTitleRequirements[_KnightTitle].Category do
            bool, reach, need = DoesNeededNumberOfEntitiesInCategoryForKnightTitleExist(_PlayerID, _KnightTitle, i);
            if bool == false then
                return bool, reach, need
            end
        end
        return bool;
    end
end

---
-- Prüft, ob genug Entities eines bestimmten Typs existieren.
--
-- @param _PlayerID    ID des Spielers
-- @param _KnightTitle Nächster Titel
-- @param _i           Button Index
-- @within BB-Funktionen
-- @local
--
DoesNeededNumberOfEntitiesOfTypeForKnightTitleExist = function(_PlayerID, _KnightTitle, _i)
    if KnightTitleRequirements[_KnightTitle].Entities == nil then
        return;
    end
    if _i then
        local EntityType = KnightTitleRequirements[_KnightTitle].Entities[_i][1];
        local NeededAmount = KnightTitleRequirements[_KnightTitle].Entities[_i][2];
        local Buildings = GetPlayerEntities(_PlayerID, EntityType);

        local ReachedAmount = 0;
        for i=1, #Buildings do
            if Logic.IsBuilding(Buildings[i]) == 1 then
                if Logic.IsConstructionComplete(Buildings[i]) == 1 then
                    ReachedAmount = ReachedAmount +1;
                end
            else
                ReachedAmount = ReachedAmount +1;
            end
        end

        if ReachedAmount >= NeededAmount then
            return true, ReachedAmount, NeededAmount;
        end
        return false, ReachedAmount, NeededAmount;
    else
        local bool, reach, need;
        for i=1,#KnightTitleRequirements[_KnightTitle].Entities do
            bool, reach, need = DoesNeededNumberOfEntitiesOfTypeForKnightTitleExist(_PlayerID, _KnightTitle, i);
            if bool == false then
                return bool, reach, need
            end
        end
        return bool;
    end
end

---
-- Prüft, ob es genug Einheiten eines Warentyps gibt.
--
-- @param _PlayerID    ID des Spielers
-- @param _KnightTitle Nächster Titel
-- @param _i           Button Index
-- @within BB-Funktionen
-- @local
--
DoesNeededNumberOfGoodTypesForKnightTitleExist = function(_PlayerID, _KnightTitle, _i)
    if KnightTitleRequirements[_KnightTitle].Goods == nil then
        return;
    end
    if _i then
        local GoodType = KnightTitleRequirements[_KnightTitle].Goods[_i][1];
        local NeededAmount = KnightTitleRequirements[_KnightTitle].Goods[_i][2];
        local ReachedAmount = GetPlayerGoodsInSettlement(GoodType, _PlayerID, true);

        if ReachedAmount >= NeededAmount then
            return true, ReachedAmount, NeededAmount;
        end
        return false, ReachedAmount, NeededAmount;
    else
        local bool, reach, need;
        for i=1,#KnightTitleRequirements[_KnightTitle].Goods do
            bool, reach, need = DoesNeededNumberOfGoodTypesForKnightTitleExist(_PlayerID, _KnightTitle, i);
            if bool == false then
                return bool, reach, need
            end
        end
        return bool;
    end
end

---
-- Prüft, ob die Siedler genug Einheiten einer Ware konsumiert haben.
--
-- @param _PlayerID    ID des Spielers
-- @param _KnightTitle Nächster Titel
-- @param _i           Button Index
-- @within BB-Funktionen
-- @local
--
DoNeededNumberOfConsumedGoodsForKnightTitleExist = function( _PlayerID, _KnightTitle, _i)
    if KnightTitleRequirements[_KnightTitle].Consume == nil then
        return;
    end
    if _i then
        QSB.ConsumedGoodsCounter[_PlayerID] = QSB.ConsumedGoodsCounter[_PlayerID] or {};

        local GoodType = KnightTitleRequirements[_KnightTitle].Consume[_i][1];
        local GoodAmount = QSB.ConsumedGoodsCounter[_PlayerID][GoodType] or 0;
        local NeededGoodAmount = KnightTitleRequirements[_KnightTitle].Consume[_i][2];
        if GoodAmount >= NeededGoodAmount then
            return true, GoodAmount, NeededGoodAmount;
        else
            return false, GoodAmount, NeededGoodAmount;
        end
    else
        local bool, reach, need;
        for i=1,#KnightTitleRequirements[_KnightTitle].Consume do
            bool, reach, need = DoNeededNumberOfConsumedGoodsForKnightTitleExist(_PlayerID, _KnightTitle, i);
            if bool == false then
                return false, reach, need
            end
        end
        return true, reach, need;
    end
end

---
-- Prüft, ob genug Waren der Kategorie hergestellt wurde.
--
-- @param _PlayerID    ID des Spielers
-- @param _KnightTitle Nächster Titel
-- @param _i           Button Index
-- @within BB-Funktionen
-- @local
--
DoNumberOfProductsInCategoryExist = function(_PlayerID, _KnightTitle, _i)
    if KnightTitleRequirements[_KnightTitle].Products == nil then
        return;
    end
    if _i then
        local GoodAmount = 0;
        local NeedAmount = KnightTitleRequirements[_KnightTitle].Products[_i][2];
        local GoodCategory = KnightTitleRequirements[_KnightTitle].Products[_i][1];
        local GoodsInCategory = {Logic.GetGoodTypesInGoodCategory(GoodCategory)};

        for i=1, #GoodsInCategory do
            GoodAmount = GoodAmount + GetPlayerGoodsInSettlement(GoodsInCategory[i], _PlayerID, true);
        end
        return (GoodAmount >= NeedAmount), GoodAmount, NeedAmount;
    else
        local bool, reach, need;
        for i=1,#KnightTitleRequirements[_KnightTitle].Products do
            bool, reach, need = DoNumberOfProductsInCategoryExist(_PlayerID, _KnightTitle, i);
            if bool == false then
                return bool, reach, need
            end
        end
        return bool;
    end
end

---
-- Prüft, ob ein bestimmter Buff für den Spieler aktiv ist.
--
-- @param _PlayerID    ID des Spielers
-- @param _KnightTitle Nächster Titel
-- @param _i           Button Index
-- @within BB-Funktionen
-- @local
--
DoNeededDiversityBuffForKnightTitleExist = function(_PlayerID, _KnightTitle, _i)
    if KnightTitleRequirements[_KnightTitle].Buff == nil then
        return;
    end
    if _i then
        local buff = KnightTitleRequirements[_KnightTitle].Buff[_i];
        if Logic.GetBuff(_PlayerID,buff) and Logic.GetBuff(_PlayerID,buff) ~= 0 then
            return true;
        end
        return false;
    else
        local bool, reach, need;
        for i=1,#KnightTitleRequirements[_KnightTitle].Buff do
            bool, reach, need = DoNeededDiversityBuffForKnightTitleExist(_PlayerID, _KnightTitle, i);
            if bool == false then
                return bool, reach, need
            end
        end
        return bool;
    end
end

---
-- Prüft, ob die Custom Function true vermeldet.
--
-- @param _PlayerID    ID des Spielers
-- @param _KnightTitle Nächster Titel
-- @param _i           Button Index
-- @within BB-Funktionen
-- @local
--
DoCustomFunctionForKnightTitleSucceed = function(_PlayerID, _KnightTitle, _i)
    if KnightTitleRequirements[_KnightTitle].Custom == nil then
        return;
    end
    if _i then
        return KnightTitleRequirements[_KnightTitle].Custom[_i][1]();
    else
        local bool, reach, need;
        for i=1,#KnightTitleRequirements[_KnightTitle].Custom do
            bool, reach, need = DoCustomFunctionForKnightTitleSucceed(_PlayerID, _KnightTitle, i);
            if bool == false then
                return bool, reach, need
            end
        end
        return bool;
    end
end

---
-- Prüft, ob genug Dekoration eines Typs angebracht wurde.
--
-- @param _PlayerID    ID des Spielers
-- @param _KnightTitle Nächster Titel
-- @param _i           Button Index
-- @within BB-Funktionen
-- @local
--
DoNeededNumberOfDecoratedBuildingsForKnightTitleExist = function( _PlayerID, _KnightTitle, _i)
    if KnightTitleRequirements[_KnightTitle].DecoratedBuildings == nil then
        return
    end

    if _i then
        local CityBuildings = {Logic.GetPlayerEntitiesInCategory(_PlayerID, EntityCategories.CityBuilding)}
        local DecorationGoodType = KnightTitleRequirements[_KnightTitle].DecoratedBuildings[_i][1]
        local NeededBuildingsWithDecoration = KnightTitleRequirements[_KnightTitle].DecoratedBuildings[_i][2]
        local BuildingsWithDecoration = 0

        for i=1, #CityBuildings do
            local BuildingID = CityBuildings[i]
            local GoodState = Logic.GetBuildingWealthGoodState(BuildingID, DecorationGoodType)
            if GoodState > 0 then
                BuildingsWithDecoration = BuildingsWithDecoration + 1
            end
        end

        if BuildingsWithDecoration >= NeededBuildingsWithDecoration then
            return true, BuildingsWithDecoration, NeededBuildingsWithDecoration
        else
            return false, BuildingsWithDecoration, NeededBuildingsWithDecoration
        end
    else
        local bool, reach, need;
        for i=1,#KnightTitleRequirements[_KnightTitle].DecoratedBuildings do
            bool, reach, need = DoNeededNumberOfDecoratedBuildingsForKnightTitleExist(_PlayerID, _KnightTitle, i);
            if bool == false then
                return bool, reach, need
            end
        end
        return bool;
    end
end

---
-- Prüft, ob die Spezialgebäude weit genug ausgebaut sind.
--
-- @param _PlayerID       ID des Spielers
-- @param _KnightTitle    Nächster Titel
-- @param _EntityCategory Entity Category
-- @within BB-Funktionen
-- @local
--
DoNeededSpecialBuildingUpgradeForKnightTitleExist = function( _PlayerID, _KnightTitle, _EntityCategory)
    local SpecialBuilding
    local SpecialBuildingName
    if _EntityCategory == EntityCategories.Headquarters then
        SpecialBuilding = Logic.GetHeadquarters(_PlayerID)
        SpecialBuildingName = "Headquarters"
    elseif _EntityCategory == EntityCategories.Storehouse then
        SpecialBuilding = Logic.GetStoreHouse(_PlayerID)
        SpecialBuildingName = "Storehouse"
    elseif _EntityCategory == EntityCategories.Cathedrals then
        SpecialBuilding = Logic.GetCathedral(_PlayerID)
        SpecialBuildingName = "Cathedrals"
    else
        return
    end
    if KnightTitleRequirements[_KnightTitle][SpecialBuildingName] == nil then
        return
    end
    local NeededUpgradeLevel = KnightTitleRequirements[_KnightTitle][SpecialBuildingName]
    if SpecialBuilding ~= nil then
        local SpecialBuildingUpgradeLevel = Logic.GetUpgradeLevel(SpecialBuilding)
        if SpecialBuildingUpgradeLevel >= NeededUpgradeLevel then
            return true, SpecialBuildingUpgradeLevel, NeededUpgradeLevel
        else
            return false, SpecialBuildingUpgradeLevel, NeededUpgradeLevel
        end
    else
        return false, 0, NeededUpgradeLevel
    end
end

---
-- Prüft, ob der Ruf der Stadt hoch genug ist.
--
-- @param _PlayerID    ID des Spielers
-- @param _KnightTitle Nächster Titel
-- @within BB-Funktionen
-- @local
--
DoesNeededCityReputationForKnightTitleExist = function(_PlayerID, _KnightTitle)
    if KnightTitleRequirements[_KnightTitle].Reputation == nil then
        return;
    end
    local NeededAmount = KnightTitleRequirements[_KnightTitle].Reputation;
    if not NeededAmount then
        return;
    end
    local ReachedAmount = math.floor((Logic.GetCityReputation(_PlayerID) * 100) + 0.5);
    if ReachedAmount >= NeededAmount then
        return true, ReachedAmount, NeededAmount;
    end
    return false, ReachedAmount, NeededAmount;
end

---
-- Prüft, ob genug Gebäude vollständig dekoriert sind.
--
-- @param _PlayerID    ID des Spielers
-- @param _KnightTitle Nächster Titel
-- @within BB-Funktionen
-- @local
--
DoNeededNumberOfFullDecoratedBuildingsForKnightTitleExist = function( _PlayerID, _KnightTitle)
    if KnightTitleRequirements[_KnightTitle].FullDecoratedBuildings == nil then
        return
    end
    local CityBuildings = {Logic.GetPlayerEntitiesInCategory(_PlayerID, EntityCategories.CityBuilding)}
    local NeededBuildingsWithDecoration = KnightTitleRequirements[_KnightTitle].FullDecoratedBuildings
    local BuildingsWithDecoration = 0

    for i=1, #CityBuildings do
        local BuildingID = CityBuildings[i]
        local AmountOfWealthGoodsAtBuilding = 0

        if Logic.GetBuildingWealthGoodState(BuildingID, Goods.G_Banner ) > 0 then
            AmountOfWealthGoodsAtBuilding = AmountOfWealthGoodsAtBuilding  + 1
        end
        if Logic.GetBuildingWealthGoodState(BuildingID, Goods.G_Sign  ) > 0 then
            AmountOfWealthGoodsAtBuilding = AmountOfWealthGoodsAtBuilding  + 1
        end
        if Logic.GetBuildingWealthGoodState(BuildingID, Goods.G_Candle) > 0 then
            AmountOfWealthGoodsAtBuilding = AmountOfWealthGoodsAtBuilding  + 1
        end
        if Logic.GetBuildingWealthGoodState(BuildingID, Goods.G_Ornament  ) > 0 then
            AmountOfWealthGoodsAtBuilding = AmountOfWealthGoodsAtBuilding  + 1
        end
        if AmountOfWealthGoodsAtBuilding >= 4 then
            BuildingsWithDecoration = BuildingsWithDecoration + 1
        end
    end

    if BuildingsWithDecoration >= NeededBuildingsWithDecoration then
        return true, BuildingsWithDecoration, NeededBuildingsWithDecoration
    else
        return false, BuildingsWithDecoration, NeededBuildingsWithDecoration
    end
end

---
-- Prüft, ob der Spieler befördert werden kann.
--
-- @param _PlayerID    ID des Spielers
-- @param _KnightTitle Nächster Titel
-- @within BB-Funktionen
-- @local
--
CanKnightBePromoted = function(_PlayerID, _KnightTitle)
    if _KnightTitle == nil then
        _KnightTitle = Logic.GetKnightTitle(_PlayerID) + 1;
    end

    if Logic.CanStartFestival(_PlayerID, 1) == true then
        if  KnightTitleRequirements[_KnightTitle] ~= nil
        and DoesNeededNumberOfSettlersForKnightTitleExist(_PlayerID, _KnightTitle) ~= false
        and DoNeededNumberOfGoodsForKnightTitleExist( _PlayerID, _KnightTitle)  ~= false
        and DoNeededSpecialBuildingUpgradeForKnightTitleExist( _PlayerID, _KnightTitle, EntityCategories.Headquarters) ~= false
        and DoNeededSpecialBuildingUpgradeForKnightTitleExist( _PlayerID, _KnightTitle, EntityCategories.Storehouse) ~= false
        and DoNeededSpecialBuildingUpgradeForKnightTitleExist( _PlayerID, _KnightTitle, EntityCategories.Cathedrals)  ~= false
        and DoNeededNumberOfRichBuildingsForKnightTitleExist( _PlayerID, _KnightTitle)  ~= false
        and DoNeededNumberOfFullDecoratedBuildingsForKnightTitleExist( _PlayerID, _KnightTitle) ~= false
        and DoNeededNumberOfDecoratedBuildingsForKnightTitleExist( _PlayerID, _KnightTitle) ~= false
        and DoesNeededCityReputationForKnightTitleExist( _PlayerID, _KnightTitle) ~= false
        and DoesNeededNumberOfEntitiesInCategoryForKnightTitleExist( _PlayerID, _KnightTitle) ~= false
        and DoesNeededNumberOfEntitiesOfTypeForKnightTitleExist( _PlayerID, _KnightTitle) ~= false
        and DoesNeededNumberOfGoodTypesForKnightTitleExist( _PlayerID, _KnightTitle) ~= false
        and DoNeededDiversityBuffForKnightTitleExist( _PlayerID, _KnightTitle) ~= false
        and DoCustomFunctionForKnightTitleSucceed( _PlayerID, _KnightTitle) ~= false
        and DoNeededNumberOfConsumedGoodsForKnightTitleExist( _PlayerID, _KnightTitle) ~= false
        and DoNumberOfProductsInCategoryExist( _PlayerID, _KnightTitle) ~= false then
            return true;
        end
    end
    return false;
end

---
-- Der Spieler gewinnt das Spiel
-- @within BB-Funktionen
-- @local
--
VictroryBecauseOfTitle = function()
    QuestTemplate:TerminateEventsAndStuff();
    Victory(g_VictoryAndDefeatType.VictoryMissionComplete);
end

-- -------------------------------------------------------------------------- --
-- Aufstiegsbedingungen                                                       --
-- -------------------------------------------------------------------------- --

---
-- Definiert andere Aufstiegsbedingungen für den Spieler.
--
-- Diese Funktion muss entweder in der QSB modifiziert oder sowohl im globalen
-- als auch im lokalen Skript überschrieben werden. Bei Modifikationen muss
-- das Schema für Aufstiegsbedingungen und Rechtevergabe immer beibehalten
-- werden.
--
-- TODO: Fehlererennung muss noch implementiert werden!
--
-- @within BB-Funktionen
--
InitKnightTitleTables = function()
    KnightTitles = {}
    KnightTitles.Knight     = 0
    KnightTitles.Mayor      = 1
    KnightTitles.Baron      = 2
    KnightTitles.Earl       = 3
    KnightTitles.Marquees   = 4
    KnightTitles.Duke       = 5
    KnightTitles.Archduke   = 6



    -- ---------------------------------------------------------------------- --
    -- Rechte und Pflichten                                                   --
    -- ---------------------------------------------------------------------- --

    NeedsAndRightsByKnightTitle ={}

    -- Ritter ------------------------------------------------------------------

    NeedsAndRightsByKnightTitle[KnightTitles.Knight] = {
        ActivateNeedForPlayer,
        {
            Needs.Nutrition,                                    -- Bedürfnis: Nahrung
            Needs.Medicine,                                     -- Bedürfnis: Medizin
        },
        ActivateRightForPlayer,
        {
            Technologies.R_Gathering,                           -- Recht: Rohstoffsammler
            Technologies.R_Woodcutter,                          -- Recht: Holzfäller
            Technologies.R_StoneQuarry,                         -- Recht: Steinbruch
            Technologies.R_HuntersHut,                          -- Recht: Jägerhütte
            Technologies.R_FishingHut,                          -- Recht: Fischerhütte
            Technologies.R_CattleFarm,                          -- Recht: Kuhfarm
            Technologies.R_GrainFarm,                           -- Recht: Getreidefarm
            Technologies.R_SheepFarm,                           -- Recht: Schaffarm
            Technologies.R_IronMine,                            -- Recht: Eisenmine
            Technologies.R_Beekeeper,                           -- Recht: Imkerei
            Technologies.R_HerbGatherer,                        -- Recht: Kräutersammler
            Technologies.R_Nutrition,                           -- Recht: Nahrung
            Technologies.R_Bakery,                              -- Recht: Bäckerei
            Technologies.R_Dairy,                               -- Recht: Käserei
            Technologies.R_Butcher,                             -- Recht: Metzger
            Technologies.R_SmokeHouse,                          -- Recht: Räucherhaus
            Technologies.R_Clothes,                             -- Recht: Kleidung
            Technologies.R_Tanner,                              -- Recht: Ledergerber
            Technologies.R_Weaver,                              -- Recht: Weber
            Technologies.R_Construction,                        -- Recht: Konstruktion
            Technologies.R_Wall,                                -- Recht: Mauer
            Technologies.R_Pallisade,                           -- Recht: Palisade
            Technologies.R_Trail,                               -- Recht: Pfad
            Technologies.R_KnockDown,                           -- Recht: Abriss
            Technologies.R_Sermon,                              -- Recht: Predigt
            Technologies.R_SpecialEdition,                      -- Recht: Special Edition
            Technologies.R_SpecialEdition_Pavilion,             -- Recht: Pavilion AeK SE
        }
    }

    -- Landvogt ----------------------------------------------------------------

    NeedsAndRightsByKnightTitle[KnightTitles.Mayor] = {
        ActivateNeedForPlayer,
        {
            Needs.Clothes,                                      -- Bedürfnis: KLeidung
        },
        ActivateRightForPlayer, {
            Technologies.R_Hygiene,                             -- Recht: Hygiene
            Technologies.R_Soapmaker,                           -- Recht: Seifenmacher
            Technologies.R_BroomMaker,                          -- Recht: Besenmacher
            Technologies.R_Military,                            -- Recht: Militär
            Technologies.R_SwordSmith,                          -- Recht: Schwertschmied
            Technologies.R_Barracks,                            -- Recht: Schwertkämpferkaserne
            Technologies.R_Thieves,                             -- Recht: Diebe
            Technologies.R_SpecialEdition_StatueFamily,         -- Recht: Familienstatue Aek SE
        },
        StartKnightsPromotionCelebration                        -- Beförderungsfest aktivieren
    }

    -- Baron -------------------------------------------------------------------

    NeedsAndRightsByKnightTitle[KnightTitles.Baron] = {
        ActivateNeedForPlayer,
        {
            Needs.Hygiene,                                      -- Bedürfnis: Hygiene
        },
        ActivateRightForPlayer, {
            Technologies.R_Medicine,                            -- Recht: Medizin
            Technologies.R_BowMaker,                            -- Recht: Bogenmacher
            Technologies.R_BarracksArchers,                     -- Recht: Bogenschützenkaserne
            Technologies.R_Entertainment,                       -- Recht: Unterhaltung
            Technologies.R_Tavern,                              -- Recht: Taverne
            Technologies.R_Festival,                            -- Recht: Fest
            Technologies.R_Street,                              -- Recht: Straße
            Technologies.R_SpecialEdition_Column,               -- Recht: Säule AeK SE
        },
        StartKnightsPromotionCelebration                        -- Beförderungsfest aktivieren
    }

    -- Graf --------------------------------------------------------------------

    NeedsAndRightsByKnightTitle[KnightTitles.Earl] = {
        ActivateNeedForPlayer,
        {
            Needs.Entertainment,                                -- Bedürfnis: Unterhaltung
            Needs.Prosperity,                                   -- Bedürfnis: Reichtum
        },
        ActivateRightForPlayer, {
            Technologies.R_SiegeEngineWorkshop,                 -- Recht: Belagerungswaffenschmied
            Technologies.R_BatteringRam,                        -- Recht: Ramme
            Technologies.R_Baths,                               -- Recht: Badehaus
            Technologies.R_AmmunitionCart,                      -- Recht: Munitionswagen
            Technologies.R_Prosperity,                          -- Recht: Reichtum
            Technologies.R_Taxes,                               -- Recht: Steuern einstellen
            Technologies.R_Ballista,                            -- Recht: Mauerkatapult
            Technologies.R_SpecialEdition_StatueSettler,        -- Recht: Siedlerstatue AeK SE
        },
        StartKnightsPromotionCelebration                        -- Beförderungsfest aktivieren
    }

    -- Marquees ----------------------------------------------------------------

    NeedsAndRightsByKnightTitle[KnightTitles.Marquees] = {
        ActivateNeedForPlayer,
        {
            Needs.Wealth,                                       -- Bedürfnis: Verschönerung
        },
        ActivateRightForPlayer, {
            Technologies.R_Theater,                             -- Recht: Theater
            Technologies.R_Wealth,                              -- Recht: Schmuckgebäude
            Technologies.R_BannerMaker,                         -- Recht: Bannermacher
            Technologies.R_SiegeTower,                          -- Recht: Belagerungsturm
            Technologies.R_SpecialEdition_StatueProduction,     -- Recht: Produktionsstatue AeK SE
        },
        StartKnightsPromotionCelebration                        -- Beförderungsfest aktivieren
    }

    -- Herzog ------------------------------------------------------------------

    NeedsAndRightsByKnightTitle[KnightTitles.Duke] = {
        ActivateNeedForPlayer, nil,
        ActivateRightForPlayer, {
            Technologies.R_Catapult,                            -- Recht: Katapult
            Technologies.R_Carpenter,                           -- Recht: Tischler
            Technologies.R_CandleMaker,                         -- Recht: Kerzenmacher
            Technologies.R_Blacksmith,                          -- Recht: Schmied
            Technologies.R_SpecialEdition_StatueDario,          -- Recht: Dariostatue AeK SE
        },
        StartKnightsPromotionCelebration                        -- Beförderungsfest aktivieren
    }

    -- Erzherzog ---------------------------------------------------------------

    NeedsAndRightsByKnightTitle[KnightTitles.Archduke] = {
        ActivateNeedForPlayer,nil,
        ActivateRightForPlayer, {
            Technologies.R_Victory                              -- Sieg
        },
        -- VictroryBecauseOfTitle,                              -- Sieg wegen Titel
        StartKnightsPromotionCelebration                        -- Beförderungsfest aktivieren
    }



    -- Reich des Ostens --------------------------------------------------------

    if g_GameExtraNo >= 1 then
        local TechnologiesTableIndex = 4;
        table.insert(NeedsAndRightsByKnightTitle[KnightTitles.Mayor][TechnologiesTableIndex],Technologies.R_Cistern);
        table.insert(NeedsAndRightsByKnightTitle[KnightTitles.Mayor][TechnologiesTableIndex],Technologies.R_Beautification_Brazier);
        table.insert(NeedsAndRightsByKnightTitle[KnightTitles.Mayor][TechnologiesTableIndex],Technologies.R_Beautification_Shrine);
        table.insert(NeedsAndRightsByKnightTitle[KnightTitles.Baron][TechnologiesTableIndex],Technologies.R_Beautification_Pillar);
        table.insert(NeedsAndRightsByKnightTitle[KnightTitles.Earl][TechnologiesTableIndex],Technologies.R_Beautification_StoneBench);
        table.insert(NeedsAndRightsByKnightTitle[KnightTitles.Earl][TechnologiesTableIndex],Technologies.R_Beautification_Vase);
        table.insert(NeedsAndRightsByKnightTitle[KnightTitles.Marquees][TechnologiesTableIndex],Technologies.R_Beautification_Sundial);
        table.insert(NeedsAndRightsByKnightTitle[KnightTitles.Archduke][TechnologiesTableIndex],Technologies.R_Beautification_TriumphalArch);
        table.insert(NeedsAndRightsByKnightTitle[KnightTitles.Duke][TechnologiesTableIndex],Technologies.R_Beautification_VictoryColumn);
    end



    -- ---------------------------------------------------------------------- --
    -- Bedingungen                                                            --
    -- ---------------------------------------------------------------------- --

    KnightTitleRequirements = {}

    -- Ritter ------------------------------------------------------------------

    KnightTitleRequirements[KnightTitles.Mayor] = {}
    KnightTitleRequirements[KnightTitles.Mayor].Headquarters = 1
    KnightTitleRequirements[KnightTitles.Mayor].Settlers = 10
    KnightTitleRequirements[KnightTitles.Mayor].Products = {
        {GoodCategories.GC_Clothes, 6},
    }

    -- Baron -------------------------------------------------------------------

    KnightTitleRequirements[KnightTitles.Baron] = {}
    KnightTitleRequirements[KnightTitles.Baron].Settlers = 30
    KnightTitleRequirements[KnightTitles.Baron].Headquarters = 1
    KnightTitleRequirements[KnightTitles.Baron].Storehouse = 1
    KnightTitleRequirements[KnightTitles.Baron].Cathedrals = 1
    KnightTitleRequirements[KnightTitles.Baron].Products = {
        {GoodCategories.GC_Hygiene, 12},
    }

    -- Graf --------------------------------------------------------------------

    KnightTitleRequirements[KnightTitles.Earl] = {}
    KnightTitleRequirements[KnightTitles.Earl].Settlers = 50
    KnightTitleRequirements[KnightTitles.Earl].Headquarters = 2
    KnightTitleRequirements[KnightTitles.Earl].Products = {
        {GoodCategories.GC_Entertainment, 18},
    }

    -- Marquess ----------------------------------------------------------------

    KnightTitleRequirements[KnightTitles.Marquees] = {}
    KnightTitleRequirements[KnightTitles.Marquees].Settlers = 70
    KnightTitleRequirements[KnightTitles.Marquees].Headquarters = 2
    KnightTitleRequirements[KnightTitles.Marquees].Storehouse = 2
    KnightTitleRequirements[KnightTitles.Marquees].Cathedrals = 2
    KnightTitleRequirements[KnightTitles.Marquees].RichBuildings = 20

    -- Herzog ------------------------------------------------------------------

    KnightTitleRequirements[KnightTitles.Duke] = {}
    KnightTitleRequirements[KnightTitles.Duke].Settlers = 90
    KnightTitleRequirements[KnightTitles.Duke].Storehouse = 2
    KnightTitleRequirements[KnightTitles.Duke].Cathedrals = 2
    KnightTitleRequirements[KnightTitles.Duke].Headquarters = 3
    KnightTitleRequirements[KnightTitles.Duke].DecoratedBuildings = {
        {Goods.G_Banner, 9 },
    }

    -- Erzherzog ---------------------------------------------------------------

    KnightTitleRequirements[KnightTitles.Archduke] = {}
    KnightTitleRequirements[KnightTitles.Archduke].Settlers = 150
    KnightTitleRequirements[KnightTitles.Archduke].Storehouse = 3
    KnightTitleRequirements[KnightTitles.Archduke].Cathedrals = 3
    KnightTitleRequirements[KnightTitles.Archduke].Headquarters = 3
    KnightTitleRequirements[KnightTitles.Archduke].RichBuildings = 30
    KnightTitleRequirements[KnightTitles.Archduke].FullDecoratedBuildings = 30

    -- Einstellungen Aktivieren
    CreateTechnologyKnightTitleTable()
end

-- -------------------------------------------------------------------------- --
-- ########################################################################## --
-- #  Symfonia BundleInterfaceApperance                                     # --
-- ########################################################################## --
-- -------------------------------------------------------------------------- --

---
-- Dieses Bundle bietet dem Nutzer Funktionen zur Manipulation der Oberfläche 
-- des Spiels. Es gibt Funktionen zum Ausblenden einiger Buttons und Menüs und 
-- die Möglichkeit eigene Texte in Tooltips und eigene Grafiken für Widgets
-- zu setzen.
--
-- @module BundleInterfaceApperance
-- @set sort=true
--

API = API or {};
QSB = QSB or {};

QSB.PlayerNames = {};

-- -------------------------------------------------------------------------- --
-- User-Space                                                                 --
-- -------------------------------------------------------------------------- --

---
-- Graut die Minimap aus oder macht sie wieder verwendbar.
--
-- <b>Hinweis:</b> Diese Änderung persistiert auch nach dem Laden eines 
-- Spielstandes und muss explizit mit dieser Funktion zurückgenommen werden!
--
-- @param _Flag Widget versteckt
-- @within User-Space
--
function API.HideMinimap(_Flag)
    if not GUI then
        Logic.ExecuteInLuaLocalState("API.HideMinimap(" ..tostring(_Flag).. ")");
        return;
    end

    BundleInterfaceApperance.Local:HideInterfaceButton(
        "/InGame/Root/Normal/AlignBottomRight/MapFrame/Minimap/MinimapOverlay",
        _Flag
    );
    BundleInterfaceApperance.Local:HideInterfaceButton(
        "/InGame/Root/Normal/AlignBottomRight/MapFrame/Minimap/MinimapTerrain",
        _Flag
    );
end

---
-- Versteckt den Umschaltknopf der Minimap oder blendet ihn ein.
--
-- <b>Hinweis:</b> Diese Änderung persistiert auch nach dem Laden eines 
-- Spielstandes und muss explizit mit dieser Funktion zurückgenommen werden!
--
-- @param _Flag Widget versteckt
-- @within User-Space
--
function API.HideToggleMinimap(_Flag)
    if not GUI then
        Logic.ExecuteInLuaLocalState("API.HideToggleMinimap(" ..tostring(_Flag).. ")");
        return;
    end

    BundleInterfaceApperance.Local:HideInterfaceButton(
        "/InGame/Root/Normal/AlignBottomRight/MapFrame/MinimapButton",
        _Flag
    );
end

---
-- Versteckt den Button des Diplomatiemenü oder blendet ihn ein.
--
-- <b>Hinweis:</b> Diese Änderung persistiert auch nach dem Laden eines 
-- Spielstandes und muss explizit mit dieser Funktion zurückgenommen werden!
--
-- @param _Flag Widget versteckt
-- @within User-Space
--
function API.HideDiplomacyMenu(_Flag)
    if not GUI then
        Logic.ExecuteInLuaLocalState("API.HideDiplomacyMenu(" ..tostring(_Flag).. ")");
        return;
    end

    BundleInterfaceApperance.Local:HideInterfaceButton(
        "/InGame/Root/Normal/AlignBottomRight/MapFrame/DiplomacyMenuButton",
        _Flag
    );
end

---
-- Versteckt den Button des Produktionsmenü oder blendet ihn ein.
--
-- <b>Hinweis:</b> Diese Änderung persistiert auch nach dem Laden eines 
-- Spielstandes und muss explizit mit dieser Funktion zurückgenommen werden!
--
-- @param _Flag Widget versteckt
-- @within User-Space
--
function API.HideProductionMenu(_Flag)
    if not GUI then
        Logic.ExecuteInLuaLocalState("API.HideProductionMenu(" ..tostring(_Flag).. ")");
        return;
    end

    BundleInterfaceApperance.Local:HideInterfaceButton(
        "/InGame/Root/Normal/AlignBottomRight/MapFrame/ProductionMenuButton",
        _Flag
    );
end

---
-- Versteckt den Button des Wettermenüs oder blendet ihn ein.
--
-- <b>Hinweis:</b> Diese Änderung persistiert auch nach dem Laden eines 
-- Spielstandes und muss explizit mit dieser Funktion zurückgenommen werden!
--
-- @param _Flag Widget versteckt
-- @within User-Space
--
function API.HideWeatherMenu(_Flag)
    if not GUI then
        Logic.ExecuteInLuaLocalState("API.HideWeatherMenu(" ..tostring(_Flag).. ")");
        return;
    end

    BundleInterfaceApperance.Local:HideInterfaceButton(
        "/InGame/Root/Normal/AlignBottomRight/MapFrame/WeatherMenuButton",
        _Flag
    );
end

---
-- Versteckt den Button zum Territorienkauf oder blendet ihn ein.
--
-- <b>Hinweis:</b> Diese Änderung persistiert auch nach dem Laden eines 
-- Spielstandes und muss explizit mit dieser Funktion zurückgenommen werden!
--
-- @param _Flag Widget versteckt
-- @within User-Space
--
function API.HideBuyTerritory(_Flag)
    if not GUI then
        Logic.ExecuteInLuaLocalState("API.HideBuyTerritory(" ..tostring(_Flag).. ")");
        return;
    end

    BundleInterfaceApperance.Local:HideInterfaceButton(
        "/InGame/Root/Normal/AlignBottomRight/DialogButtons/Knight/ClaimTerritory",
        _Flag
    );
end

---
-- Versteckt den Button der Heldenfähigkeit oder blendet ihn ein.
--
-- <b>Hinweis:</b> Diese Änderung persistiert auch nach dem Laden eines 
-- Spielstandes und muss explizit mit dieser Funktion zurückgenommen werden!
--
-- @param _Flag Widget versteckt
-- @within User-Space
--
function API.HideKnightAbility(_Flag)
    if not GUI then
        Logic.ExecuteInLuaLocalState("API.HideKnightAbility(" ..tostring(_Flag).. ")");
        return;
    end

    BundleInterfaceApperance.Local:HideInterfaceButton(
        "/InGame/Root/Normal/AlignBottomRight/DialogButtons/Knight/StartAbilityProgress",
        _Flag
    );
    BundleInterfaceApperance.Local:HideInterfaceButton(
        "/InGame/Root/Normal/AlignBottomRight/DialogButtons/Knight/StartAbility",
        _Flag
    );
end

---
-- Versteckt den Button zur Heldenselektion oder blendet ihn ein.
--
-- <b>Hinweis:</b> Diese Änderung persistiert auch nach dem Laden eines 
-- Spielstandes und muss explizit mit dieser Funktion zurückgenommen werden!
--
-- @param _Flag Widget versteckt
-- @within User-Space
--
function API.HideKnightButton(_Flag)
    if not GUI then
        Logic.ExecuteInLuaLocalState("API.HideKnightButton(" ..tostring(_Flag).. ")");
        return;
    end
    
    local KnightID = Logic.GetKnightID(GUI.GetPlayerID());
    if _Flag == true then 
        GUI.SendScriptCommand("Logic.SetEntitySelectableFlag("..KnightID..", 0)");
        GUI.DeselectEntity(KnightID);
    else 
        GUI.SendScriptCommand("Logic.SetEntitySelectableFlag("..KnightID..", 1)");
    end
    
    BundleInterfaceApperance.Local:HideInterfaceButton(
        "/InGame/Root/Normal/AlignBottomRight/MapFrame/KnightButtonProgress",
        _Flag
    );
    BundleInterfaceApperance.Local:HideInterfaceButton(
        "/InGame/Root/Normal/AlignBottomRight/MapFrame/KnightButton",
        _Flag
    );
end

---
-- Versteckt den Button zur Selektion des Militärs oder blendet ihn ein.
--
-- <b>Hinweis:</b> Diese Änderung persistiert auch nach dem Laden eines 
-- Spielstandes und muss explizit mit dieser Funktion zurückgenommen werden!
--
-- @param _Flag Widget versteckt
-- @within User-Space
--
function API.HideSelectionButton(_Flag)
    if not GUI then
        Logic.ExecuteInLuaLocalState("API.HideSelectionButton(" ..tostring(_Flag).. ")");
        return;
    end
    API.HideKnightButton(_Flag);
    GUI.ClearSelection();
    
    BundleInterfaceApperance.Local:HideInterfaceButton(
        "/InGame/Root/Normal/AlignBottomRight/MapFrame/BattalionButton",
        _Flag
    );
end

---
-- Versteckt das Baumenü oder blendet es ein.
--
-- <b>Hinweis:</b> Diese Änderung persistiert auch nach dem Laden eines 
-- Spielstandes und muss explizit mit dieser Funktion zurückgenommen werden!
--
-- @param _Flag Widget versteckt
-- @within User-Space
--
function API.HideBuildMenu(_Flag)
    if not GUI then
        Logic.ExecuteInLuaLocalState("API.HideBuildMenu(" ..tostring(_Flag).. ")");
        return;
    end
    
    BundleInterfaceApperance.Local:HideInterfaceButton(
        "/InGame/Root/Normal/AlignBottomRight/BuildMenu",
        _Flag
    );
end

---
-- Setzt eine Grafik als Bild für einen Icon oder einen Button.
--
-- Die Größe des Bildes ist auf 200x200 Pixel festgelegt. Es kann an jedem
-- beliebigen Ort im interen Verzeichnis oder auf der Festplatte liegen. Es
-- muss jedoch immer der korrekte Pfad angegeben werden.
--
-- <b>Hinweis:</b> Es kann vorkommen, dass das Bild nicht genau da ist, wo es
-- sein soll, sondern seine Position, je nach Auflösung, um ein paar Pixel 
-- unterschiedlich ist.
-- 
-- @param _widget Widgetpfad oder ID
-- @param _file   Pfad zur Datei
-- @within User-Space
--
function API.SetTexture(_widget, _file)
    if not GUI then
        return;
    end
    BundleInterfaceApperance.Local:SetTexture(_widget, _file)
end
UserSetTexture = API.SetTexture;

---
-- Setzt einen Icon aus einer benutzerdefinierten Icon Matrix.
--
-- Dabei müssen die Quellen nach gui_768, gui_920 und gui_1080 in der
-- entsprechenden Größe gepackt werden. Die Ordner liegen in graphics/textures.
-- Jede Map muss einen eigenen eindeutigen Namen für jede Grafik verwenden.
--
-- <u>Größen:</u>
-- Die gesamtgrßee ergibt sich aus der Anzahl der Buttons und der Pixelbreite
-- für die jeweilige Grö0e. z.B. 64 Buttons -> Größe * 8 x Größe * 8
-- <ul>
-- <li>768: 41x41</li>
-- <li>960: 52x52</li>
-- <li>1200: 64x64</li>
-- </ul>
--
-- <u>Namenskonvention:</u>
-- Die Namenskonvention wird durch das Spiel vorgegeben. Je nach größe sind 
-- die Namen der Matrizen erweitert mit .png, big.png und verybig.png. Du
-- gibst also niemals die Dateiendung mit an!
-- <ul>
-- <li>Für normale Icons: _Name .. .png</li>
-- <li>Für große Icons: _Name .. big.png</li>
-- <li>Für riesige Icons: _Name .. verybig.png</li>
-- </ul>
-- 
-- @param _WidgetID    Widgetpfad oder ID
-- @param _Coordinates Koordinaten
-- @param _Size        Größe des Icon
-- @param _Name        Name der Icon Matrix
-- @within User-Space
--
function API.SetIcon(_WidgetID, _Coordinates, _Size, _Name)
    if not GUI then
        return;
    end
    BundleInterfaceApperance.Local:SetIcon(_WidgetID, _Coordinates, _Size, _Name)
end
UserSetIcon = API.SetIcon;

---
-- Ändert den aktuellen Tooltip mit der Beschreibung.
--
-- <b>Alias:</b> UserSetTextNormal
--
-- Die Funtion ermittelt das aktuelle GUI Widget und ändert den Text des 
-- Tooltip. Dazu muss die Funktion innerhalb der Mouseover-Funktion eines 
-- Buttons oder Widgets mit Tooltip aufgerufen werden.
--
-- Die Funktion kann auch mit deutsch/english lokalisierten Tabellen als 
-- Text gefüttert werden. In diesem Fall wird der deutsche Text genommen,
-- wenn es sich um eine deutsche Spielversion handelt. Andernfalls wird
-- immer der englische Text verwendet.
-- 
-- @param _title        Titel des Tooltip
-- @param _text         Text des Tooltip
-- @param _disabledText Textzusatz wenn inaktiv
-- @within User-Space
--
function API.SetTooltipNormal(_title, _text, _disabledText)
    if not GUI then 
        return;
    end
    BundleInterfaceApperance.Local:TextNormal(_title, _text, _disabledText);
end
UserSetTextNormal = API.SetTooltipNormal;

---
-- Ändert den aktuellen Tooltip mit der Beschreibung und den Kosten.
--
-- <b>Alias:</b> UserSetTextBuy
--
-- @see API.SetTooltipNormal
-- 
-- @param _title        Titel des Tooltip
-- @param _text         Text des Tooltip
-- @param _disabledText Textzusatz wenn inaktiv
-- @param _costs        Kostentabelle
-- @param _inSettlement Kosten in Siedlung suchen
-- @within User-Space
--
function API.SetTooltipCosts(_title,_text,_disabledText,_costs,_inSettlement)
    if not GUI then
        return;
    end
    BundleInterfaceApperance.Local:TextCosts(_title,_text,_disabledText,_costs,_inSettlement);
end
UserSetTextBuy = API.SetTooltipCosts;

---
-- Gibt den Namen des Territoriums zurück.
--
-- <b>Alias:</b> GetTerritoryName
--
-- @return _TerritoryID ID des Territoriums
-- @return Name des Territorium
-- @within User-Space
--
function API.GetTerritoryName(_TerritoryID)
    local Name = Logic.GetTerritoryName(_TerritoryID);
    local MapType = Framework.GetCurrentMapTypeAndCampaignName();
    if MapType == 1 or MapType == 3 then
        return Name;
    end

    local MapName = Framework.GetCurrentMapName();
    local StringTable = "Map_" .. MapName;
    local TerritoryName = string.gsub(Name, " ","");
    TerritoryName = XGUIEng.GetStringTableText(StringTable .. "/Territory_" .. TerritoryName);
    if TerritoryName == "" then
        TerritoryName = Name .. "(key?)";
    end
    return TerritoryName;
end
GetTerritoryName = API.GetTerritoryName;

---
-- Gibt den Namen des Spielers zurück.
--
-- <b>Alias:</b> GetPlayerName
--
-- @return _PlayerID ID des Spielers
-- @return Name des Territorium
-- @within User-Space
--
function API.GetPlayerName(_PlayerID)
    local PlayerName = Logic.GetPlayerName(_PlayerID);
    local name = QSB.PlayerNames[_PlayerID];
    if name ~= nil and name ~= "" then
        PlayerName = name;
    end

    local MapType = Framework.GetCurrentMapTypeAndCampaignName();
    local MutliplayerMode = Framework.GetMultiplayerMapMode(Framework.GetCurrentMapName(), MapType);

    if MutliplayerMode > 0 then
        return PlayerName;
    end
    if MapType == 1 or MapType == 3 then
        local PlayerNameTmp, PlayerHeadTmp, PlayerAITmp = Framework.GetPlayerInfo(_PlayerID);
        if PlayerName ~= "" then
            return PlayerName;
        end
        return PlayerNameTmp;
    end
end
GetPlayerName_OrigName = GetPlayerName;
GetPlayerName = API.GetPlayerName;

---
-- Gibt dem Spieler einen neuen Namen.
--
-- <b>Alias:</b> SetPlayerName
--
-- @return _playerID ID des Spielers
-- @return _name     Name des Spielers
-- @return Name des Territorium
-- @within User-Space
--
function API.SetPlayerName(_playerID,_name)
    assert(type(_playerID) == "number");
    assert(type(_name) == "string");
    if not GUI then
        Logic.ExecuteInLuaLocalState("SetPlayerName(".._playerID..",'".._name.."')");
    else
        GUI_MissionStatistic.PlayerNames[_playerID] = _name;
        GUI.SendScriptCommand("QSB.PlayerNames[".._playerID.."] = '".._name.."'");
    end
    QSB.PlayerNames[_playerID] = _name;
end
SetPlayerName = API.SetPlayerName;

---
-- Setzt zu Spielbeginn eine andere Spielerfarbe.
--
-- @return _PlayerID ID des Spielers
-- @return _Color    Spielerfarbe
-- @return _Logo     Logo (optional)
-- @return _Pattern  Pattern (optional)
-- @return Name des Territorium
-- @within User-Space
--
function API.SetPlayerColor(_PlayerID, _Color, _Logo, _Pattern)
    if GUI then
        return;
    end
    local Type    = type(_Color);
    local Col     = (type(_Color) == "string" and g_ColorIndex[_Color]) or _Color;
    local Logo    = _Logo or -1;
    local Pattern = _Pattern or -1;
    
    g_ColorIndex["ExtraColor1"] = 16;
    g_ColorIndex["ExtraColor2"] = 17;
    
    StartSimpleJobEx( function(Col, _PlayerID, _Logo, _Pattern)
        Logic.PlayerSetPlayerColor(_PlayerID, Col, _Logo, _Pattern);
        return true;
    end, Col, _PlayerID, Logo, Pattern);
end

-- -------------------------------------------------------------------------- --
-- Application-Space                                                          --
-- -------------------------------------------------------------------------- --

BundleInterfaceApperance = {
    Global = {},
    Local = {
        HiddenWidgets = {},
    }
};

-- Global Script ---------------------------------------------------------------

---
-- Initialisiert das Bundle im globalen Skript.
-- @within Application-Space
-- @local
--
function BundleInterfaceApperance.Global:Install()
    API.AddSaveGameAction(BundleInterfaceApperance.Global.RestoreAfterLoad);
end

---
-- Stellt alle versteckten Buttons nach dem Laden eines Spielstandes wieder her.
-- @within Application-Space
-- @local
--
function BundleInterfaceApperance.Global.RestoreAfterLoad()
    Logic.ExecuteInLuaLocalState([[
        BundleInterfaceApperance.Local:RestoreAfterLoad();
    ]]);
end

-- Local Script ----------------------------------------------------------------

---
-- Initialisiert das Bundle im lokalen Skript.
-- @within Application-Space
-- @local
--
function BundleInterfaceApperance.Local:Install()
    StartMissionGoodOrEntityCounter = function(_Icon, _AmountToReach)
        if type(_Icon) == "string" then
            BundleInterfaceApperance.Local:SetTexture("/InGame/Root/Normal/MissionGoodOrEntityCounter/Icon", _Icon);
        else
            if type(_Icon[3]) == "string" then
                BundleInterfaceApperance.Local:SetIcon("/InGame/Root/Normal/MissionGoodOrEntityCounter/Icon", _Icon, 64, _Icon[3]);
            else
                SetIcon("/InGame/Root/Normal/MissionGoodOrEntityCounter/Icon", _Icon);
            end
        end

        g_MissionGoodOrEntityCounterAmountToReach = _AmountToReach;
        g_MissionGoodOrEntityCounterIcon = _Icon;

        XGUIEng.ShowWidget("/InGame/Root/Normal/MissionGoodOrEntityCounter", 1);
    end
    
    GUI_Knight.ClaimTerritoryUpdate_Orig_QSB_InterfaceApperance = GUI_Knight.ClaimTerritoryUpdate;
    GUI_Knight.ClaimTerritoryUpdate = function()
        local Key = "/InGame/Root/Normal/AlignBottomRight/DialogButtons/Knight/ClaimTerritory";
        if BundleInterfaceApperance.Local.Data.HiddenWidgets[Key] == true
        then
            BundleInterfaceApperance.Local:HideInterfaceButton(Key, true);
        end
        GUI_Knight.ClaimTerritoryUpdate_Orig_QSB_InterfaceApperance();
    end
end

---
-- Versteht ein Widget oder blendet es ein.
--
-- @param _Widget Widgetpfad oder ID
-- @param _Hide   Hidden Flag
-- @within Application-Space
-- @local
--
function BundleInterfaceApperance.Local:HideInterfaceButton(_Widget, _Hide)
    self.Data.HiddenWidgets[_Widget] = _Hide == true;
    XGUIEng.ShowWidget(_Widget, (_Hide == true and 0) or 1);
end

---
-- Stellt alle versteckten Buttons nach dem Laden eines Spielstandes wieder her.
-- @within Application-Space
-- @local
--
function BundleInterfaceApperance.Local:RestoreAfterLoad()
    for k, v in pairs(self.Data.HiddenWidgets) do
        if v then 
            XGUIEng.ShowWidget(k, 0);
        end
    end
end

---
-- Setzt einen Icon aus einer benutzerdefinerten Datei.
--
-- @param _widget Widgetpfad oder ID
-- @param _file   Pfad zur Datei
-- @within Application-Space
-- @local
--
function BundleInterfaceApperance.Local:SetTexture(_widget, _file)
    assert((type(_widget) == "string" or type(_widget) == "number"));
    local wID = (type(_widget) == "string" and XGUIEng.GetWidgetID(_widget)) or _widget;
    local screenSize = {GUI.GetScreenSize()};

    local state = 1;
    if XGUIEng.IsButton(wID) == 1 then
        state = 7;
    end
    
    local Scale = 330;
    if screenSize[2] >= 800 then
        Scale = 260;
    end
    if screenSize[2] >= 1000 then
        Scale = 210;
    end
    XGUIEng.SetMaterialAlpha(wID, state, 255);
    XGUIEng.SetMaterialTexture(wID, state, _file);
    XGUIEng.SetMaterialUV(wID, state, 0, 0, Scale, Scale);
end

---
-- Setzt einen Icon aus einer benutzerdefinierten Matrix.
--
-- @param _WidgetID    Widgetpfad oder ID
-- @param _Coordinates Koordinaten
-- @param _Size        Größe des Icon
-- @param _Name        Name der Icon Matrix
-- @within Application-Space
-- @local
--
function BundleInterfaceApperance.Local:SetIcon(_WidgetID, _Coordinates, _Size, _Name)
    if _Name == nil then
        _Name = "usericons";
    end
    if _Size == nil then
        _Size = 64;
    end
    
    if _Size == 44 then
        _Name = _Name .. ".png"
    end
    if _Size == 64 then
        _Name = _Name .. "big.png"
    end
    if _Size == 128 then
        _Name = _Name .. "verybig.png"
    end
    
    local u0, u1, v0, v1;
    u0 = (_Coordinates[1] - 1) * _Size;
    v0 = (_Coordinates[2] - 1) * _Size;
    u1 = (_Coordinates[1]) * _Size;
    v1 = (_Coordinates[2]) * _Size;
    
    State = 1;
    if XGUIEng.IsButton(_WidgetID) == 1 then
        State = 7;
    end
    XGUIEng.SetMaterialAlpha(_WidgetID, State, 255);
    XGUIEng.SetMaterialTexture(_WidgetID, State, _Name);
    XGUIEng.SetMaterialUV(_WidgetID, State, u0, v0, u1, v1);
end

---
-- Setzt einen Beschreibungstooltip.
--
-- @param _title        Titel des Tooltip
-- @param _text         Text des Tooltip
-- @param _disabledText Textzusatz wenn inaktiv
-- @within Application-Space
-- @local
--
function BundleInterfaceApperance.Local:TextNormal(_title, _text, _disabledText)
    local lang = Network.GetDesiredLanguage()
    if lang ~= "de" then lang = "en" end

    if type(_title) == "table" then
        _title = _title[lang];
    end
    if type(_text) == "table" then
        _text = _text[lang];
    end
    _text = _text or "";
    if type(_disabledText) == "table" then
        _disabledText = _disabledText[lang];
    end

    local TooltipContainerPath = "/InGame/Root/Normal/TooltipNormal"
    local TooltipContainer = XGUIEng.GetWidgetID(TooltipContainerPath)
    local TooltipNameWidget = XGUIEng.GetWidgetID(TooltipContainerPath .. "/FadeIn/Name")
    local TooltipDescriptionWidget = XGUIEng.GetWidgetID(TooltipContainerPath .. "/FadeIn/Text")
    local TooltipBGWidget = XGUIEng.GetWidgetID(TooltipContainerPath .. "/FadeIn/BG")
    local TooltipFadeInContainer = XGUIEng.GetWidgetID(TooltipContainerPath .. "/FadeIn")
    local PositionWidget = XGUIEng.GetCurrentWidgetID()
    GUI_Tooltip.ResizeBG(TooltipBGWidget, TooltipDescriptionWidget)
    local TooltipContainerSizeWidgets = {TooltipBGWidget}
    GUI_Tooltip.SetPosition(TooltipContainer, TooltipContainerSizeWidgets, PositionWidget)
    GUI_Tooltip.FadeInTooltip(TooltipFadeInContainer)

    _disabledText = _disabledText or "";
    local disabled = "";
    if XGUIEng.IsButtonDisabled(PositionWidget) == 1 and _disabledText ~= "" and _text ~= "" then
        disabled = disabled .. "{cr}{@color:255,32,32,255}" .. _disabledText
    end

    XGUIEng.SetText(TooltipNameWidget, "{center}" .. _title)
    XGUIEng.SetText(TooltipDescriptionWidget, _text .. disabled)
    local Height = XGUIEng.GetTextHeight(TooltipDescriptionWidget, true)
    local W, H = XGUIEng.GetWidgetSize(TooltipDescriptionWidget)
    XGUIEng.SetWidgetSize(TooltipDescriptionWidget, W, Height)
end

---
-- Setzt den Kostentooltip.
--
-- @param _title        Titel des Tooltip
-- @param _text         Text des Tooltip
-- @param _disabledText Textzusatz wenn inaktiv
-- @param _costs        Kostentabelle
-- @param _inSettlement Kosten in Siedlung suchen
-- @within Application-Space
-- @local
--
function BundleInterfaceApperance.Local:TextCosts(_title,_text,_disabledText,_costs,_inSettlement)
    local lang = Network.GetDesiredLanguage()
    if lang ~= "de" then lang = "en" end
    _costs = _costs or {};

    if type(_title) == "table" then
        _title = _title[lang];
    end
    if type(_text) == "table" then
        _text = _text[lang];
    end
    _text = _text or "";
    if type(_disabledText) == "table" then
        _disabledText = _disabledText[lang];
    end

    local TooltipContainerPath = "/InGame/Root/Normal/TooltipBuy"
    local TooltipContainer = XGUIEng.GetWidgetID(TooltipContainerPath)
    local TooltipNameWidget = XGUIEng.GetWidgetID(TooltipContainerPath .. "/FadeIn/Name")
    local TooltipDescriptionWidget = XGUIEng.GetWidgetID(TooltipContainerPath .. "/FadeIn/Text")
    local TooltipBGWidget = XGUIEng.GetWidgetID(TooltipContainerPath .. "/FadeIn/BG")
    local TooltipFadeInContainer = XGUIEng.GetWidgetID(TooltipContainerPath .. "/FadeIn")
    local TooltipCostsContainer = XGUIEng.GetWidgetID(TooltipContainerPath .. "/Costs")
    local PositionWidget = XGUIEng.GetCurrentWidgetID()
    GUI_Tooltip.ResizeBG(TooltipBGWidget, TooltipDescriptionWidget)
    GUI_Tooltip.SetCosts(TooltipCostsContainer, _costs, _inSettlement)
    local TooltipContainerSizeWidgets = {TooltipContainer, TooltipCostsContainer, TooltipBGWidget}
    GUI_Tooltip.SetPosition(TooltipContainer, TooltipContainerSizeWidgets, PositionWidget, nil, true)
    GUI_Tooltip.OrderTooltip(TooltipContainerSizeWidgets, TooltipFadeInContainer, TooltipCostsContainer, PositionWidget, TooltipBGWidget)
    GUI_Tooltip.FadeInTooltip(TooltipFadeInContainer)

    _disabledText = _disabledText or "";
    local disabled = ""
    if XGUIEng.IsButtonDisabled(PositionWidget) == 1 and _disabledText ~= "" and _text ~= "" then
        disabled = disabled .. "{cr}{@color:255,32,32,255}" .. _disabledText
    end

    XGUIEng.SetText(TooltipNameWidget, "{center}" .. _title)
    XGUIEng.SetText(TooltipDescriptionWidget, _text .. disabled)
    local Height = XGUIEng.GetTextHeight(TooltipDescriptionWidget, true)
    local W, H = XGUIEng.GetWidgetSize(TooltipDescriptionWidget)
    XGUIEng.SetWidgetSize(TooltipDescriptionWidget, W, Height)
end

-- -------------------------------------------------------------------------- --

Core:RegisterBundle("BundleInterfaceApperance");

-- -------------------------------------------------------------------------- --
-- ########################################################################## --
-- #  Symfonia BundleTradingFunctions                                       # --
-- ########################################################################## --
-- -------------------------------------------------------------------------- --

---
-- Dieses Bundle bietet einige (experientelle) Funktionen zum untersuchen und
-- zur Manipulation von Handelsangeboten. Die bekannten Funktionen, wie z.B.
-- AddOffer, werden erweitert, sodass sie Angebote für einen Spieler mit einer
-- anderen ID als 1 erstellen können.
-- Zudem wird ein fliegender Händler angeboten, der periodisch den Hafen mit
-- einem Schiff anfährt. Dabei kann der Fahrtweg frei mit Wegpunkten bestimmt
-- werden. Es können auch mehrere Spieler zu Händlern gemacht werden.
--
-- @module BundleTradingFunctions
-- @set sort=true
--

API = API or {};
QSB = QSB or {};

QSB.TravelingSalesman = {
	Harbors = {}
};

QSB.TraderTypes = {
    GoodTrader        = 1,
    MercenaryTrader   = 2,
    EntertainerTrader = 3,
    Unknown           = 4,
};

-- -------------------------------------------------------------------------- --
-- User-Space                                                                 --
-- -------------------------------------------------------------------------- --

---
-- Gibt die Handelsinformationen des Spielers aus. In dem Objekt stehen
-- ID des Spielers, ID des Lagerhaus, Menge an Angeboten insgesamt und
-- alle Angebote der Händlertypen.
--
-- @param _PlayerID Player ID
-- @return Angebotsinformationen
-- @within User-Space
--
-- @usage BundleTradingFunctions.Global:GetOfferInformation(2);
--
-- -- Ausgabe:
-- -- Info = {
-- --      Player = 2,
-- --      Storehouse = 26796.
-- --      OfferCount = 2,
-- --      {
-- --          {TraderID = 0, OfferID = 0, GoodType = Goods.G_Gems,
-- --           OfferGoodAmount = 9, OfferAmount = 2},
-- --          {TraderID = 0, OfferID = 1, GoodType = Goods.G_Milk,
-- --           OfferGoodAmount = 9, OfferAmount = 4},
-- --      },
-- -- }
--
function API.GetOfferInformation(_PlayerID)
    if GUI then
        API.Log("Can not execute API.GetOfferInformation in local script!");
        return;
    end
    return BundleTradingFunctions.Global:GetOfferInformation(_PlayerID);
end

---
-- Gibt die Menge an Angeboten im Lagerhaus des Spielers zurück. Wenn
-- der Spieler kein Lagerhaus hat, wird 0 zurückgegeben.
--
-- @param _PlayerID ID des Spielers
-- @return number
-- @within User-Space
--
function API.GetOfferCount(_PlayerID)
    if GUI then
        API.Log("Can not execute API.GetOfferCount in local script!");
        return;
    end
    return BundleTradingFunctions.Global:GetOfferCount(_PlayerID);
end

---
-- Gibt Offer ID und Trader ID und ID des Lagerhaus des Angebots für 
-- den Spieler zurück. Es wird immer das erste Angebot zurückgegeben.
--
-- @param _PlayerID Player ID
-- @param _GoodType Warentyp oder Entitytyp
-- @return numer, number, number
-- @within User-Space
--
function API.GetOfferAndTrader(_PlayerID, _GoodorEntityType)
    if GUI then
        API.Log("Can not execute API.GetOfferAndTrader in local script!");
        return;
    end
    return BundleTradingFunctions.Global:GetOfferAndTrader(_PlayerID, _GoodorEntityType);
end

---
-- Gibt den Typ des Händlers mit der ID im Gebäude zurück.
--
-- @param _BuildingID Building ID
-- @param _TraderID   Trader ID
-- @return number
-- @within User-Space
--
function API.GetTraderType(_BuildingID, _TraderID)
    if GUI then
        API.Log("Can not execute API.GetTraderType in local script!");
        return;
    end
    return BundleTradingFunctions.Global:GetTraderType(_BuildingID, _TraderID);
end

---
-- Gibt den Händler des Typs in dem Gebäude zurück.
--
-- @param _BuildingID Entity ID des Handelsgebäudes
-- @param _TraderType Typ des Händlers
-- @return number
-- @within User-Space
--
function API.GetTrader(_BuildingID, _TraderType)
    if GUI then
        API.Log("Can not execute API.GetTrader in local script!");
        return;
    end
    return BundleTradingFunctions.Global:GetTrader(_BuildingID, _TraderType);
end

---
-- Entfernt das Angebot mit dem Index für den Händler im Handelsgebäude
-- des Spielers.
--
-- @param _PlayerID        Entity ID des Handelsgebäudes
-- @param _TraderType      Typ des Händlers
-- @param _OfferIndex      Index des Angebots
-- @within User-Space
--
function API.RemoveOfferByIndex(_PlayerID, _TraderType, _OfferIndex)
    if GUI then
        API.Bridge("API.RemoveOfferByIndex(" .._PlayerID.. ", " .._TraderType.. ", " .._OfferIndex.. ")");
        return;
    end
    return BundleTradingFunctions.Global:RemoveOfferByIndex(_PlayerID, _TraderType, _OfferIndex);
end

---
-- Entfernt das Angebot vom Lagerhaus des Spielers, wenn es vorhanden
-- ist. Es wird immer nur das erste Angebot des Typs entfernt.
--
-- @param _PlayerID            Player ID
-- @param _GoodorEntityType    Warentyp oder Entitytyp
-- @within User-Space
--
function API.RemoveOffer(_PlayerID, _GoodOrEntityType)
    if GUI then
        API.Bridge("API.RemoveOffer(" .._PlayerID.. ", " .._GoodOrEntityType.. ")");
        return;
    end
    return BundleTradingFunctions.Global:RemoveOffer(_PlayerID, _GoodOrEntityType);
end

---
-- Ändert die maximale Menge des Angebots im Händelrgebäude.
-- TODO Test this Shit!
--
-- @param _Merchant	Händlergebäude
-- @param _TraderID	ID des Händlers im Gebäude
-- @param _OfferID		ID des Angebots
-- @param _NewAmount	Neue Menge an Angeboten
-- @within User-Space
--
function API.ModifyTraderOffer(_Merchant, _TraderID, _OfferID, _NewAmount)
    if GUI then
        API.Bridge("API.ModifyTraderOffer(" .._Merchant.. ", " .._TraderID.. ", " .._OfferID.. ", " .._NewAmount.. ")");
        return;
    end
    return BundleTradingFunctions.Global:ModifyTraderOffer(_Merchant, _TraderID, _OfferID, _NewAmount);
end

---
-- Erstellt einen fliegenden Händler mit zufälligen Angeboten. Soll
-- immer das selbe angeboten werden, muss nur ein Angebotsblock
-- definiert werden.
-- Es kann mehrere fliegende Händler auf der Map geben.
--
-- @param _Offers	 Liste an Angeboten
-- @param _Stay		 Wartezeit
-- @param _Waypoints Wegpunktliste Anfahrt
-- @param _Reversed	 Wegpunktliste Abfahrt
-- @param _PlayerID	 Spieler-ID des Händlers
-- @within User-Space
--
function API.ActivateTravelingSalesman(_Offers, _Stay, _Waypoints, _Reversed, _PlayerID)
    if GUI then
        API.Log("Can not execute API.ActivateTravelingSalesman in local script!");
        return;
    end
    return BundleTradingFunctions.Global:TravelingSalesman_Create(_Offers, _Stay, _Waypoints, _Reversed, _PlayerID);
end

---
-- Zerstört den fliegenden Händler. Der Spieler wird dabei natürlich
-- nicht zerstört.
--
-- @param _PlayerID	Spieler-ID des Händlers
-- @within User-Space
--
function API.DisbandTravelingSalesman(_PlayerID)
    if GUI then
        API.Bridge("API.DisbandTravelingSalesman(" .._PlayerID.. ")");
        return;
    end
    return BundleTradingFunctions.Global:TravelingSalesman_Disband(_PlayerID);
end

-- -------------------------------------------------------------------------- --
-- Application-Space                                                          --
-- -------------------------------------------------------------------------- --

BundleTradingFunctions = {
    Global = {
        Data = {}
    },
    Local = {
        Data = {}
    },
}

-- Global Script ---------------------------------------------------------------

---
-- Initialisiert das Bundle im globalen Skript.
-- @within Application-Space
-- @local
--
function BundleTradingFunctions.Global:Install()
    self.OverwriteOfferFunctions();
    self.OverwriteBasePricesAndRefreshRates();
    
    TravelingSalesman_Control = BundleTradingFunctions.Global.TravelingSalesman_Control;
end

---
--
--
-- @within Application-Space
-- @local
--
function BundleTradingFunctions.Global:OverwriteOfferFunctions()
    ---
    -- Erzeugt ein Handelsangebot für Waren und gibt die ID zurück.
    --
    -- @param _Merchant					Handelsgebäude
    -- @param _NumberOfOffers			Anzahl an Angeboten
    -- @param _GoodType                 Warentyp
    -- @param _RefreshRate              Erneuerungsrate
    -- @param _optionalPlayersPlayerID	Optionale Spieler-ID
    -- @return Offer ID	
    -- @within BB-Funktionen			
    --
    AddOffer = function(_Merchant, _NumberOfOffers, _GoodType, _RefreshRate, _optionalPlayersPlayerID)
        local MerchantID = GetID(_Merchant)
        if type(_GoodType) == "string" 
        then
            _GoodType = Goods[_GoodType]
        else
            _GoodType = _GoodType
        end
        local PlayerID = Logic.EntityGetPlayer(MerchantID)
        AddGoodToTradeBlackList(PlayerID, _GoodType)
        local MarketerType = Entities.U_Marketer
        if _GoodType == Goods.G_Medicine 
        then
            MarketerType = Entities.U_Medicus
        end
        if _RefreshRate == nil 
        then
            _RefreshRate = MerchantSystem.RefreshRates[_GoodType]
            if _RefreshRate == nil 
            then 
                _RefreshRate = 0 
            end
        end
        if _optionalPlayersPlayerID == nil 
        then
            _optionalPlayersPlayerID = 1
        end
        local offerAmount = 9;
        return Logic.AddGoodTraderOffer(MerchantID,_NumberOfOffers,Goods.G_Gold,0,_GoodType,offerAmount,_optionalPlayersPlayerID,_RefreshRate,MarketerType,Entities.U_ResourceMerchant)
    end

    ---
    -- Erzeugt ein Handelsangebot für Söldner und gibt die ID zurück.
    --
    -- @param _Merchant					Handelsgebäude
    -- @param _Amount					Anzahl an Angeboten
    -- @param _Type						Soldatentyp
    -- @param _RefreshRate				Erneuerungsrate
    -- @param _optionalPlayersPlayerID	Optionale Spieler-ID
    -- @return Offer ID
    -- @within BB-Funktionen	
    --
    AddMercenaryOffer = function( _Mercenary, _Amount, _Type, _RefreshRate, _optionalPlayersPlayerID)
        local MercenaryID = GetID(_Mercenary)
        if _Type == nil 
        then
            _Type = Entities.U_MilitaryBandit_Melee_ME
        end
        if _RefreshRate == nil 
        then
            _RefreshRate = MerchantSystem.RefreshRates[_Type]
            if _RefreshRate == nil 
            then
                _RefreshRate = 0
            end
        end
        local amount = 3;
        local typeName = Logic.GetEntityTypeName(_Type);
        if string.find(typeName,"MilitaryBow") or string.find(typeName,"MilitarySword") 
        then
            amount = 6;
        elseif string.find(typeName,"Cart") 
        then
            amount = 0;
        end
        if _optionalPlayersPlayerID == nil 
        then
            _optionalPlayersPlayerID = 1
        end
        return Logic.AddMercenaryTraderOffer(MercenaryID, _Amount, Goods.G_Gold, 3, _Type ,amount,_optionalPlayersPlayerID,_RefreshRate)
    end

    ---
    -- Erzeugt ein Handelsangebot für Entertainer und gibt die 
    -- ID zurück.
    --
    -- @param _Merchant					Handelsgebäude
    -- @param _EntertainerType			Typ des Entertainer
    -- @param _optionalPlayersPlayerID	Optionale Spieler-ID
    -- @return Offer ID
    -- @within BB-Funktionen	
    --
    AddEntertainerOffer = function(_Merchant, _EntertainerType, _optionalPlayersPlayerID)
        local MerchantID = GetID(_Merchant)
        local NumberOfOffers = 1
        if _EntertainerType == nil 
        then
            _EntertainerType = Entities.U_Entertainer_NA_FireEater
        end
        if _optionalPlayersPlayerID == nil 
        then
            _optionalPlayersPlayerID = 1
        end
        return Logic.AddEntertainerTraderOffer(MerchantID,NumberOfOffers,Goods.G_Gold,0,_EntertainerType, _optionalPlayersPlayerID,0)
    end
end

---
-- Fügt fehlende Einträge für Militäreinheiten bei den Basispreisen
-- und Erneuerungsraten hinzu, damit diese gehandelt werden können.
-- @within Application-Space
-- @local
--
function BundleTradingFunctions.Global:OverwriteBasePricesAndRefreshRates()
    MerchantSystem.BasePrices[Entities.U_CatapultCart] = MerchantSystem.BasePrices[Entities.U_CatapultCart] or 1000;
    MerchantSystem.BasePrices[Entities.U_BatteringRamCart] = MerchantSystem.BasePrices[Entities.U_BatteringRamCart] or 450;
    MerchantSystem.BasePrices[Entities.U_SiegeTowerCart] = MerchantSystem.BasePrices[Entities.U_SiegeTowerCart] or 600;
    MerchantSystem.BasePrices[Entities.U_AmmunitionCart] = MerchantSystem.BasePrices[Entities.U_AmmunitionCart] or 180;
    MerchantSystem.BasePrices[Entities.U_MilitarySword_RedPrince] = MerchantSystem.BasePrices[Entities.U_MilitarySword_RedPrince] or 150;
    MerchantSystem.BasePrices[Entities.U_MilitarySword_Khana] = MerchantSystem.BasePrices[Entities.U_MilitarySword_Khana] or 150;
    MerchantSystem.BasePrices[Entities.U_MilitarySword] = MerchantSystem.BasePrices[Entities.U_MilitarySword] or 150;
    MerchantSystem.BasePrices[Entities.U_MilitaryBow_RedPrince] = MerchantSystem.BasePrices[Entities.U_MilitaryBow_RedPrince] or 220;
    MerchantSystem.BasePrices[Entities.U_MilitaryBow] = MerchantSystem.BasePrices[Entities.U_MilitaryBow] or 220;

    MerchantSystem.RefreshRates[Entities.U_CatapultCart] = MerchantSystem.RefreshRates[Entities.U_CatapultCart] or 270;
    MerchantSystem.RefreshRates[Entities.U_BatteringRamCart] = MerchantSystem.RefreshRates[Entities.U_BatteringRamCart] or 190;
    MerchantSystem.RefreshRates[Entities.U_SiegeTowerCart] = MerchantSystem.RefreshRates[Entities.U_SiegeTowerCart] or 220;
    MerchantSystem.RefreshRates[Entities.U_AmmunitionCart] = MerchantSystem.RefreshRates[Entities.U_AmmunitionCart] or 150;
    MerchantSystem.RefreshRates[Entities.U_MilitaryBow_RedPrince] = MerchantSystem.RefreshRates[Entities.U_MilitarySword_RedPrince] or 150;
    MerchantSystem.RefreshRates[Entities.U_MilitaryBow_Khana] = MerchantSystem.RefreshRates[Entities.U_MilitarySword_Khana] or 150;
    MerchantSystem.RefreshRates[Entities.U_MilitarySword] = MerchantSystem.RefreshRates[Entities.U_MilitarySword] or 150;
    MerchantSystem.RefreshRates[Entities.U_MilitaryBow_RedPrince] = MerchantSystem.RefreshRates[Entities.U_MilitaryBow_RedPrince] or 150;
    MerchantSystem.RefreshRates[Entities.U_MilitaryBow] = MerchantSystem.RefreshRates[Entities.U_MilitaryBow] or 150;
    
    if g_GameExtraNo >= 1 then
        MerchantSystem.BasePrices[Entities.U_MilitaryBow_Khana] = MerchantSystem.BasePrices[Entities.U_MilitaryBow_Khana] or 220;
        MerchantSystem.RefreshRates[Entities.U_MilitaryBow_Khana] = MerchantSystem.RefreshRates[Entities.U_MilitaryBow_Khana] or 150;
    end
end

---
-- Gibt die Handelsinformationen des Spielers aus. In dem Objekt stehen
-- ID des Spielers, ID des Lagerhaus, Menge an Angeboten insgesamt und
-- alle Angebote der Händlertypen.
--
-- @param _PlayerID Player ID
-- @return Angebotsinformationen
-- @within Application-Space
-- @local
--
-- @usage BundleTradingFunctions.Global:GetOfferInformation(2);
--
-- -- Ausgabe:
-- -- Info = {
-- --      Player = 2,
-- --      Storehouse = 26796.
-- --      OfferCount = 2,
-- --      {
-- --          {TraderID = 0, OfferID = 0, GoodType = Goods.G_Gems,
-- --           OfferGoodAmount = 9, OfferAmount = 2},
-- --          {TraderID = 0, OfferID = 1, GoodType = Goods.G_Milk,
-- --           OfferGoodAmount = 9, OfferAmount = 4},
-- --      },
-- -- }
--
function BundleTradingFunctions.Global:GetOfferInformation(_PlayerID)
    local BuildingID = Logic.GetStoreHouse(_PlayerID);
    if not IsExisting(BuildingID)
    then
        return;
    end

    -- Initialisieren
    local OfferInformation = {
        Player      = _PlayerID,
        Storehouse  = BuildingID,
        OfferCount  = 0,
    };

    -- Angebote aller Händler im Gebäude durchgehen
    local AmountOfOffers = 0;
    local TradersCount = Logic.GetNumberOfMerchants(BuildingID);
    for i= 0, TradersCount-1, 1
    do

        local TraderTypeOffers = {};
        local Offers = {Logic.GetMerchantOfferIDs(BuildingID, i, _PlayerID)};
        for j = 1, #Offers
        do
            AmountOfOffers = AmountOfOffers +1;

            local GoodType, OfferGoodAmount, OfferAmount, AmountPrices;
            local TraderType = Module_TradingTools.Global.GetTraderType(i);
            if TraderType == QSB.TraderTypes.GoodTrader then
                GoodType, OfferGoodAmount, OfferAmount, AmountPrices = Logic.GetGoodTraderOffer(BuildingID, Offers[j], _PlayerID);
            elseif TraderType == QSB.TraderTypes.MercenaryTrader then
                GoodType, OfferGoodAmount, OfferAmount, AmountPrices = Logic.GetMercenaryOffer(BuildingID, Offers[j], _PlayerID);
            else
                GoodType, OfferGoodAmount, OfferAmount, AmountPrices = Logic.GetEntertainerTraderOffer(BuildingID, Offers[j], _PlayerID);
            end

            table.insert(TraderTypeOffers, {
                TraderID        = i,
                OfferID         = Offers[j],
                GoodType        = GoodType,
                OfferGoodAmount = OfferGoodAmount,
                OfferAmount     = OfferAmount,
            });
        end
        table.insert(OfferInformation, TraderTypeOffers);
    end

    -- Menge speichern
    OfferInformation.OfferCount = AmountOfOffers;
    return OfferInformation;
end

---
-- Gibt die Menge an Angeboten im Lagerhaus des Spielers zurück. Wenn
-- der Spieler kein Lagerhaus hat, wird 0 zurückgegeben.
--
-- @param _PlayerID ID des Spielers
-- @return number
-- @within Application-Space
-- @local
--
function BundleTradingFunctions.Global:GetOfferCount(_PlayerID)
    local Offers = self:GetOfferInformation(_PlayerID);
    return Offers.OfferCount;
end

---
-- Gibt Offer ID und Trader ID und ID des Lagerhaus des Angebots für 
-- den Spieler zurück. Es wird immer das erste Angebot zurückgegeben.
--
-- @param _PlayerID Player ID
-- @param _GoodType Warentyp oder Entitytyp
-- @return numer, number, number
-- @within Application-Space
-- @local
--
function BundleTradingFunctions.Global:GetOfferAndTrader(_PlayerID, _GoodorEntityType)
    local Info = self:GetOfferInformation(_PlayerID);
    for i=1, #Info, 1 do
        for j=1, #Info, 1 do
          if Info[i][j].GoodType == _GoodorEntityType then
              return Info[i][j].OfferID, Info[i][j].TraderID, Info.Storehouse;
          end
        end
    end
end

---
-- Gibt den Typ des Händlers mit der ID im Gebäude zurück.
--
-- @param _BuildingID Building ID
-- @param _TraderID   Trader ID
-- @return number
-- @within Application-Space
-- @local
--
function BundleTradingFunctions.Global:GetTraderType(_BuildingID, _TraderID)
    if Logic.IsGoodTrader(BuildingID, _TraderID) == true
    then
        return QSB.TraderTypes.GoodTrader;
    elseif Logic.IsMercenaryTrader(BuildingID, _TraderID) == true
    then
        return QSB.TraderTypes.MercenaryTrader;
    elseif Logic.IsMercenaryTrader(BuildingID, _TraderID) == true
    then
        return QSB.TraderTypes.EntertainerTrader;
    else
        return QSB.TraderTypes.Unknown;
    end
end

---
-- Gibt den Händler des Typs in dem Gebäude zurück.
--
-- @param _BuildingID Entity ID des Handelsgebäudes
-- @param _TraderType Typ des Händlers
-- @return number
-- @within Application-Space
-- @local
--
function BundleTradingFunctions.Global:GetTrader(_BuildingID, _TraderType)
    local TraderID;
    local TradersCount = Logic.GetNumberOfMerchants(BuildingID);
    for i= 0, TradersCount-1, 1
    do
        if self:GetTraderType(BuildingID) == _TraderType
        then
            TraderID = i;
            break;
        end
    end
    return TraderID;
end

---
-- Entfernt das Angebot mit dem Index für den Händler im Handelsgebäude
-- des Spielers.
--
-- @param _PlayerID        Entity ID des Handelsgebäudes
-- @param _TraderType      Typ des Händlers
-- @param _OfferIndex      Index des Angebots
-- @within Application-Space
-- @local
--
function BundleTradingFunctions.Global:RemoveOfferByIndex(_PlayerID, _TraderType, _OfferIndex)
    local BuildingID = Logic.GetStoreHouse(_PlayerID);
    if not IsExisting(BuildingID)
    then
        return;
    end

    _OfferIndex = _OfferIndex or 0;
    local TraderID = self:GetTrader(_PlayerID, _TraderType);
    if TraderID ~= nil
    then
        Logic.RemoveOffer(BuildingID, TraderID, _OfferIndex);
    end
end

---
-- Entfernt das Angebot vom Lagerhaus des Spielers, wenn es vorhanden
-- ist. Es wird immer nur das erste Angebot des Typs entfernt.
--
-- @param _PlayerID            Player ID
-- @param _GoodorEntityType    Warentyp oder Entitytyp
-- @within Application-Space
-- @local
--
function BundleTradingFunctions.Global:RemoveOffer(_PlayerID, _GoodOrEntityType)
    local OfferID, TraderID, Storehouse = self:GetOfferAndTrader(_PlayerID, _GoodOrEntityType);
    if OfferID and TraderID and Storehouse
    then
        Logic.RemoveOffer(Storehouse, TraderID, OfferID);
    end
end

---
-- Ändert die maximale Menge des Angebots im Händelrgebäude.
-- TODO Test this Shit!
--
-- @param _Merchant	Händlergebäude
-- @param _TraderID	ID des Händlers im Gebäude
-- @param _OfferID		ID des Angebots
-- @param _NewAmount	Neue Menge an Angeboten
-- @within Application-Space
-- @local
--
function BundleTradingFunctions.Global:ModifyTraderOffer(_Merchant, _TraderID, _OfferID, _NewAmount)
    local BuildingID = GetID(_Merchant)
    if not IsExisting(BuildingID) then
        return;
    end
    Logic.ModifyTraderOffer(BuildingID, _TraderID, _OfferID, _NewAmount);
end

---
-- Gibt den ersten menschlichen Spieler zurück. Ist das globale
-- Gegenstück zu GUI.GetPlayerID().
--
-- @return number
-- @within Application-Space
-- @local
--
function BundleTradingFunctions.Global:TravelingSalesman_GetHumanPlayer()
    local pID = 1;
    for i=1,8 do
        if Logic.PlayerGetIsHumanFlag(1) == true then
            pID = i;
            break;
        end
    end
    return pID;
end

---
-- Erstellt einen fliegenden Händler mit zufälligen Angeboten. Soll
-- immer das selbe angeboten werden, muss nur ein Angebotsblock
-- definiert werden.
-- Es kann mehrere fliegende Händler auf der Map geben.
--
-- @param offers	Liste an Angeboten
-- @param stay		Wartezeit
-- @param waypoints	Wegpunktliste Anfahrt
-- @param reversed	Wegpunktliste Abfahrt
-- @param playerID	Spieler-ID des Händlers
-- @within Application-Space
-- @local
--
function BundleTradingFunctions.Global:TravelingSalesman_Create(offers, stay, waypoints, reversed, playerID)
    assert(type(playerID) == "number");
    assert(type(offers) == "table");
    stay = stay or {{3,5},{8,10}};
    assert(type(stay) == "table");
    assert(type(waypoints) == "table");

    if not reversed then
        reversed = {};
        for i=#waypoints, 1, -1 do
            reversed[#waypoints+1 - i] = waypoints[i];
        end
    end

    if not QSB.TravelingSalesman.Harbors[playerID] then
        QSB.TravelingSalesman.Harbors[playerID] = {};

        QSB.TravelingSalesman.Harbors[playerID].Waypoints = waypoints;
        QSB.TravelingSalesman.Harbors[playerID].Reversed = reversed;
        QSB.TravelingSalesman.Harbors[playerID].SpawnPos = waypoints[1];
        QSB.TravelingSalesman.Harbors[playerID].Destination = reversed[1];
        QSB.TravelingSalesman.Harbors[playerID].Appearance = stay;
        QSB.TravelingSalesman.Harbors[playerID].Status = 0;
        QSB.TravelingSalesman.Harbors[playerID].Offer = offers;
        QSB.TravelingSalesman.Harbors[playerID].LastOffer = 0;
    end
    math.randomseed(Logic.GetTimeMs());

    if not QSB.TravelingSalesman.JobID then
        QSB.TravelingSalesman.JobID = StartSimpleJob("TravelingSalesman_Control");
    end
end

---
-- Zerstört den fliegenden Händler. Der Spieler wird dabei natürlich
-- nicht zerstört.
--
-- @param playerID	Spieler-ID des Händlers
-- @within Application-Space
-- @local
--
function BundleTradingFunctions.Global:TravelingSalesman_Disband(playerID)
    assert(type(playerID) == "number");
    QSB.TravelingSalesman.Harbors[playerID] = nil;
    Logic.RemoveAllOffers(Logic.GetStoreHouse(playerID));
    DestroyEntity("TravelingSalesmanShip_Player"..playerID);
end

---
-- Setzt die Angebote des Fliegenden Händlers.
--
-- @paramplayerID	Spieler-ID des Händlers
-- @within Application-Space
-- @local
--
function BundleTradingFunctions.Global:TravelingSalesman_AddOffer(playerID)
    MerchantSystem.TradeBlackList[playerID] = {};
    MerchantSystem.TradeBlackList[playerID][0] = #MerchantSystem.TradeBlackList[3];

    local traderId = Logic.GetStoreHouse(playerID);
    local rand = 1;
    if #QSB.TravelingSalesman.Harbors[playerID].Offer > 1 then
        repeat
            rand = math.random(1,#QSB.TravelingSalesman.Harbors[playerID].Offer);
        until (rand ~= QSB.TravelingSalesman.Harbors[playerID].LastOffer);
    end
    QSB.TravelingSalesman.Harbors[playerID].LastOffer = rand;
    local offer = QSB.TravelingSalesman.Harbors[playerID].Offer[rand];
    Logic.RemoveAllOffers(traderId);

    if #offer > 0 then
        for i=1,#offer,1 do
            local offerType = offer[i][1];
            local isGoodType = false
            for k,v in pairs(Goods)do
                if k == offerType then
                    isGoodType = true
                end
            end

            if isGoodType then
                local amount = offer[i][2];
                AddOffer(traderId,amount,Goods[offerType],9999);
            else
                if Logic.IsEntityTypeInCategory(Entities[offerType],EntityCategories.Military)== 0 then
                    AddEntertainerOffer(traderId,Entities[offerType]);
                else
                    local amount = offer[i][2];
                    AddMercenaryOffer(traderId,amount,Entities[offerType],9999);
                end
            end
        end
    end

    SetDiplomacyState(self:TravelingSalesman_GetHumanPlayer(),playerID,DiplomacyStates.TradeContact);
    ActivateMerchantPermanentlyForPlayer(Logic.GetStoreHouse(playerID),self:TravelingSalesman_GetHumanPlayer());

    local doIt = (IsBriefingActive and not IsBriefingActive()) or true
    if doIt then
        local Text = { de = "Ein Schiff hat angelegt. Es bringt Güter von weit her.",
                       en = "A ship is at the pier. It deliver goods from far away."};
        local lang = (Network.GetDesiredLanguage() == "de" and "de") or "en";

        QuestTemplate:New(
            "TravelingSalesman_Info_P"..playerID,
            _Quest.SendingPlayer,
            self:TravelingSalesman_GetHumanPlayer(),
            {{ Objective.Dummy,}},
            {{ Triggers.Time, 0 }},
            0,
            nil, nil, nil, nil, nil, true,
            nil, nil,
            Text[lang],
            nil
        );
    end
end

---
-- Steuert alle fliegenden Händler auf der Map.
-- @within Application-Space
-- @local
--
function BundleTradingFunctions.Global.TravelingSalesman_Control()
    for k,v in pairs(QSB.TravelingSalesman.Harbors) do
        if QSB.TravelingSalesman.Harbors[k] ~= nil then
            if v.Status == 0 then
                local month = Logic.GetCurrentMonth();
                local start = false;
                for i=1, #v.Appearance,1 do
                    if month == v.Appearance[i][1] then
                        start = true;
                    end
                end
                if start then
                    local orientation = Logic.GetEntityOrientation(GetID(v.SpawnPos))
                    local ID = CreateEntity(0,Entities.D_X_TradeShip,GetPosition(v.SpawnPos),"TravelingSalesmanShip_Player"..k,orientation);
                    Path:new(ID,v.Waypoints, nil, nil, nil, nil, true, nil, nil, 300);
                    v.Status = 1;
                end
            elseif v.Status == 1 then
                if IsNear("TravelingSalesmanShip_Player"..k,v.Destination,400) then
                    BundleTradingFunctions.Global:TravelingSalesman_AddOffer(k)
                    v.Status = 2;
                end
            elseif v.Status == 2 then
                local month = Logic.GetCurrentMonth();
                local stop = false;
                for i=1, #v.Appearance,1 do
                    if month == v.Appearance[i][2] then
                        stop = true;
                    end
                end
                if stop then
                    SetDiplomacyState(BundleTradingFunctions.Global:TravelingSalesman_GetHumanPlayer(),k,DiplomacyStates.EstablishedContact);
                    Path:new(GetID("TravelingSalesmanShip_Player"..k),v.Reversed, nil, nil, nil, nil, true, nil, nil, 300);
                    Logic.RemoveAllOffers(Logic.GetStoreHouse(k));
                    v.Status = 3;
                end
            elseif v.Status == 3 then
                if IsNear("TravelingSalesmanShip_Player"..k,v.SpawnPos,400) then
                    DestroyEntity("TravelingSalesmanShip_Player"..k);
                    v.Status = 0;
                end
            end
        end
    end
end

-- Local Script ----------------------------------------------------------------

---
-- Initialisiert das Bundle im lokalen Skript.
-- @within Application-Space
-- @local
--
function BundleTradingFunctions.Local:Install()

end

-- -------------------------------------------------------------------------- --

Core:RegisterBundle("BundleTradingFunctions");

-- -------------------------------------------------------------------------- --
-- ########################################################################## --
-- #  Symfonia BundleMusicTools                                             # --
-- ########################################################################## --
-- -------------------------------------------------------------------------- --

---
-- Dieses Bundle bietet die Möglichkeit Musikstücke oder ganze Playlists als
-- Stimme abzuspielen.
--
-- @module BundleMusicTools
-- @set sort=true
--

API = API or {};
QSB = QSB or {};

-- -------------------------------------------------------------------------- --
-- User-Space                                                                 --
-- -------------------------------------------------------------------------- --

---
-- Startet ein Musikstück als Stimme.
--
-- <b>Alias:</b> StartMusic
--
-- Es wird nicht als Musik behandelt, sondern als Sprache! Die Lautstäkre 
-- sämtlicher Sprache wird beeinflusst, weshalb immer nur 1 Song gleichzeitig
-- gespielt werden kann! Alle als Sprache abgespielten Sounds werden die
-- gleiche Lautstärke haben, wie die Musik.
--
-- _Description hat folgendes Format:
-- <ul>
-- <li>File     - Path + Dateiname</li>
-- <li>Volume   - Lautstärke</li>
-- <li>length   - abgespielte Länge in Sekunden (nicht zwingend |Musikstück|)</li>
-- <li>Fadeout  - Ausblendzeit in Zehntels. (>= 5 oder 0 für sofort)</li>
-- <li>MuteAtmo - Hintergrundgeräusche aus</li>
-- <li>MuteUI   - GUI-Sounds aus</li>
-- </ul>
--
-- @param _Description 
-- @within User-Space
--
function API.StartMusic(_Description)
    if GUI then
        API.Log("Could not execute API.StartMusic in local script!");
        return;
    end
    BundleMusicTools.Global:StartSong(_Description);
end
StartMusic = API.StartMusic;

---
-- Vereinfachter einzeiliger Aufruf für StartSong.
--
-- <b>Alias:</b> StartMusicSimple
--
-- @param _File    Pfad zur Datei
-- @param _Volume  Lautstärke
-- @param _Length  Abspieldower (<= Dauer Musikstück)
-- @param _FadeOut Ausblenden in Sekunden
-- @within User-Space
--
function API.StartMusicSimple(_File, _Volume, _Length, _FadeOut)
    if GUI then
        API.Bridge("API.StartMusicSimple('" .._File.. "', " .._Volume.. ", " .._Length.. ", " .._FadeOut.. ")");
        return;
    end
    local Data = {
        File     = _File,
        Volume   = _Volume,
        Length   = _Length,
        Fadeout  = _FadeOut * 10,
        MuteAtmo = true;
        MuteUI   = true,
    };
    BundleMusicTools.Global:StartSong(Data);
end
StartMusicSimple = API.StartMusicSimple;

---
-- Spielt eine Playlist ab.
--
-- <b>Alias:</b> StartPlaylist
--
-- Eine im Skript definierte Playlist, nicht
-- eine XML! Die Playlist kann einmal abgearbeitet oder auf Wiederholung
-- gestellt werden. Alle Einträge haben das Format von StartSong!
-- Zusätzlich kann der Wahrheitswert Repeat gesetzt werden, damit
-- sich die Playlist endlos wiederholt.
--
-- @param _Playlist 
-- @within User-Space
--
function API.StartPlaylist(_Playlist)
    if GUI then
        API.Log("Could not execute API.StartPlaylist in local script!");
        return;
    end
    BundleMusicTools.Global:StartPlaylist(_Playlist);
end
StartPlaylist = API.StartPlaylist;

---
-- Stoppt gerade gespielte Musik und startet die Playlist mit dem
-- angegebenen Titel. Es muss eine Playlist existieren! Nachdem der
-- Titel abgespielt ist, wird die Playlist normal weiter gespielt.
--
-- <b>Alias:</b> StartPlaylistTitle
--
-- @param _Title 
-- @within User-Space
--
function API.StartPlaylistTitle(_Title)
    if GUI then
        API.Log("Could not execute API.StartPlaylistTitle in local script!");
        return;
    end
    BundleMusicTools.Global:StartPlaylistTitle(_Title);
end
StartPlaylistTitle = API.StartPlaylistTitle;

---
-- Stopt Musik und stellt die alte Soundkonfiguration wieder her.
--
-- <b>Alias:</b> StopSong
--
-- @within User-Space
--
function API.StopSong()
    if GUI then
        API.Bridge("API.StopSong()");
        return;
    end
    BundleMusicTools.Global:StopSong();
end
StopSong = API.StopSong;

---
-- Stopt den gerade laufenden Song und leert sowohl die Songdaten
-- als auch die Playlist.
--
-- <b>Alias:</b> AbortSongOrPlaylist
--
-- @within User-Space
--
function API.AbortMusic()
    if GUI then
        API.Bridge("API.AbortMusic()");
        return;
    end
    BundleMusicTools.Global:AbortMusic();
end
AbortSongOrPlaylist = API.AbortMusic;

-- -------------------------------------------------------------------------- --
-- Application-Space                                                          --
-- -------------------------------------------------------------------------- --

BundleMusicTools = {
    Global = {
        Data = {
            StartSongData = {},
            StartSongPlaylist = {},
            StartSongQueue = {},
        }
    },
    Local = {
        Data = {}
    },
}

-- Global Script ---------------------------------------------------------------

---
-- Initalisiert das Bundle im globalen Skript.
--
-- @within Application-Space
-- @local
--
function BundleMusicTools.Global:Install()

end

---
-- Startet ein Musikstück als Stimme.
--
-- @param _Description Beschreibung des Musikstücks
-- @within Application-Space
-- @local
--
function BundleMusicTools.Global:StartSong(_Description)
    if self.Data.StartSongData.Running then
        table.insert(self.Data.StartSongQueue, _Description);
    else
        assert(type(_Description.File) == "string");
        assert(type(_Description.Volume) == "number");
        assert(type(_Description.Length) == "number");
        _Description.Length = _Description.Length * 10;
        assert(type(_Description.Fadeout) == "number");
        _Description.MuteAtmo = _Description.MuteAtmo == true;
        _Description.MuteUI = _Description.MuteUI == true;
        _Description.CurrentVolume = _Description.Volume;
        _Description.Time = 0;

        self.Data.StartSongData = _Description;
        self.Data.StartSongData.Running = true;

        Logic.ExecuteInLuaLocalState([[
            BundleMusicTools.Local:BackupSound(
                ]].. _Description.Volume ..[[,
                "]].. _Description.File ..[[",
                ]].. tostring(_Description.MuteAtmo) ..[[,
                ]].. tostring(_Description.MuteUI) ..[[
            )
        ]])

        if not self.Data.StartSongJob then
            self.Data.StartSongJob = StartSimpleHiResJob("StartSongControl");
        end
    end
end

---
-- Spielt eine Playlist ab.
--
-- @within Application-Space
-- @local
--
function BundleMusicTools.Global:StartPlaylist(_Playlist)
    for i=1, #_Playlist, 1 do
        table.insert(self.Data.StartSongPlaylist, _Playlist[i]);
        self:StartSong(_Playlist[i]);
    end
    self.Data.StartSongPlaylist.Repeat = _Playlist.Repeat == true;
end

---
-- Stoppt gerade gespielte Musik und startet die Playlist mit dem
-- angegebenen Titel. Es muss eine Playlist existieren! Nachdem der
-- Titel abgespielt ist, wird die Playlist normal weiter gespielt.
--
-- @within Application-Space
-- @local
--
function BundleMusicTools.Global:StartPlaylistTitle(_Title)
    local playlist = self.Data.StartSongPlaylist;
    local length = #length;
    if (length >= _Title) then
        self.Data.StartSongData.Running = false;
        self.Data.StartSongQueue = {};
        self.Data.StartSongData = {};
        self:StopSong();
        EndJob(self.Data.StartSongJob);
        self.Data.StartSongJob = nil;
        for i=_Title, length, 1 do
            self:StartSong(playlist);
        end
    end
end

---
-- Stopt Musik und stellt die alte Soundkonfiguration wieder her.
--
-- @within Application-Space
-- @local
--
function BundleMusicTools.Global:StopSong()
    local Queue = #self.Data.StartSongQueue;
    local Data = self.Data.StartSongData;
    Logic.ExecuteInLuaLocalState([[
        BundleMusicTools.Local:ResetSound(
            "]].. ((Data.File ~= nil and Data.File) or "") ..[[",
            ]].. Queue ..[[
        )
    ]]);
end

---
-- Stopt den gerade laufenden Song und leert sowohl die Songdaten
-- als auch die Playlist.
--
-- @within Application-Space
-- @local
--
function BundleMusicTools.Global:AbortMusic()
    self.Data.StartSongPlaylist = {};
    self.Data.StartSongQueue = {};
    self:StopSong();
    self.Data.StartSongData = {};
    EndJob(self.Data.StartSongJob);
    self.Data.StartSongJob = nil;
end

---
-- Kontrolliert den Song / die Playlist. Wenn ein Song durch ist, wird
-- der nächste Song in der Warteschlange gestartet, sofern vorhanden.
-- Ist die Warteschlange leer, endet der Job. Existiert eine Playlist,
-- für die Repeat = true ist, dann wird die Playlist neu gestartet.
--
-- @within Application-Space
-- @local
--
function BundleMusicTools.Global.StartSongControl()
    if not self.Data.StartSongData.Running then
        self.Data.StartSongData = {};
        self.Data.StartSongJob = nil;
        if #self.Data.StartSongQueue > 0 then
            local Description = table.remove(self.Data.StartSongQueue, 1);
            self:StartSong(Description);
        else
            if self.Data.StartSongPlaylist.Repeat then
                self:StartPlaylist(self.Data.StartSongPlaylist);
            end
        end
        return true;
    end

    local Data = self.Data.StartSongData;
    -- Zeit z�hlen
    self.Data.StartSongData.Time = Data.Time +1;

    if Data.Fadeout < 5 then
        if Data.Time >= Data.Length then
            self.Data.StartSongData.Running = false;
            self:StopSong();
        end
    else
        local FadeoutTime = Data.Length - Data.Fadeout+1;
        if Data.Time >= FadeoutTime then
            if Data.Time >= Data.Length then
                self.Data.StartSongData.Running = false;
                self:StopSong();
            else
                local VolumeStep = Data.Volume / Data.Fadeout;
                self.Data.StartSongData.CurrentVolume = Data.CurrentVolume - VolumeStep;
                Logic.ExecuteInLuaLocalState([[
                    Sound.SetSpeechVolume(]]..Data.CurrentVolume..[[)
                ]]);
            end
        end
    end
end
StartSongControl = BundleMusicTools.Global.StartSongControl;

-- Local Script ----------------------------------------------------------------

---
-- Initalisiert das Bundle im lokalen Skript.
--
-- @within Application-Space
-- @local
--
function BundleMusicTools.Local:Install()

end

---
-- Speichert die Soundeinstellungen.
--
-- @param _Volume   Lautstärke
-- @param _Song     Pfad zum Titel
-- @param _MuteAtmo Atmosphäre stumm schalten
-- @param _MuteUI   UI stumm schalten
-- @within Application-Space
-- @local
--
function BundleMusicTools.Local:BackupSound(_Volume, _Song, _MuteAtmo, _MuteUI)
    if self.Data.SoundBackup.FXSP == nil then
        self.Data.SoundBackup.FXSP = Sound.GetFXSoundpointVolume();
        self.Data.SoundBackup.FXAtmo = Sound.GetFXAtmoVolume();
        self.Data.SoundBackup.FXVol = Sound.GetFXVolume();
        self.Data.SoundBackup.Sound = Sound.GetGlobalVolume();
        self.Data.SoundBackup.Music = Sound.GetMusicVolume();
        self.Data.SoundBackup.Voice = Sound.GetSpeechVolume();
        self.Data.SoundBackup.UI = Sound.Get2DFXVolume();
    end

    Sound.SetFXVolume(100);
    Sound.SetSpeechVolume(_Volume);
    if _MuteAtmo == true then
        Sound.SetFXSoundpointVolume(0);
        Sound.SetFXAtmoVolume(0);
    end
    if _MuteUI == true then
        Sound.Set2DFXVolume(0);
        Sound.SetFXVolume(0);
    end
    Sound.SetMusicVolume(0);
    Sound.PlayVoice("ImportantStuff", _Song);
end

---
-- Stellt die Soundeinstellungen wieder her.
--
-- @param _File        Pfad zur Datei
-- @param _QueueLength Länge der Warteschlange
-- @within Application-Space
-- @local
--
function BundleMusicTools.Local:ResetSound(_File, _QueueLength)
    if _File ~= nil then
        Sound.StopVoice("ImportantStuff", _File)
    end
    if _QueueLength <= 0 then
        if self.Data.SoundBackup.FXSP ~= nil then
            Sound.SetFXSoundpointVolume(self.Data.SoundBackup.FXSP)
            Sound.SetFXAtmoVolume(self.Data.SoundBackup.FXAtmo)
            Sound.SetFXVolume(self.Data.SoundBackup.FXVol)
            Sound.SetGlobalVolume(self.Data.SoundBackup.Sound)
            Sound.SetMusicVolume(self.Data.SoundBackup.Music)
            Sound.SetSpeechVolume(self.Data.SoundBackup.Voice)
            Sound.Set2DFXVolume(self.Data.SoundBackup.UI)
            self.Data.SoundBackup = {}
        end
    end
end

-- -------------------------------------------------------------------------- --

Core:RegisterBundle("BundleMusicTools");

-- -------------------------------------------------------------------------- --
-- ########################################################################## --
-- #  Symfonia BundleEntityScriptingValues                                  # --
-- ########################################################################## --
-- -------------------------------------------------------------------------- --

---
-- Dieses Bundle ermöglicht die Manipulation einer Entität direkt im 
-- Arbeitsspeicher.
--
-- @module BundleEntityScriptingValues
-- @set sort=true
--

API = API or {};
QSB = QSB or {};

-- -------------------------------------------------------------------------- --
-- User-Space                                                                 --
-- -------------------------------------------------------------------------- --

---
-- Gibt den Größenfaktor des Entity zurück.
--
-- @param _Entity Entity
-- @return Größenfaktor
-- @within User-Space
--
function API.GetScale(_Entity)
    if not IsExisting(_Entity) then
        local Subject = (type(_Entity) == "string" and "'" .._Entity.. "'") or _Entity;
        API.Dbg("API.GetScale: Target " ..Subject.. " is invalid!");
        return -1;
    end
    return BundleEntityScriptingValues:GetEntitySize(_Entity);
end

---
-- Gibt den Besitzer des Entity zurück.
--
-- @param _Entity Entity
-- @return Besitzer
-- @within User-Space
--
function API.GetPlayer(_Entity)
    if not IsExisting(_Entity) then
        local Subject = (type(_Entity) == "string" and "'" .._Entity.. "'") or _Entity;
        API.Dbg("API.GetPlayer: Target " ..Subject.. " is invalid!");
        return -1;
    end
    return BundleEntityScriptingValues:GetPlayerID(_entity);
end

---
-- Gibt die Position zurück, zu der sich das Entity bewegt.
--
-- @param _Entity Entity
-- @return Positionstabelle
-- @within User-Space
--
function API.GetMovingTarget(_Entity)
    if not IsExisting(_Entity) then
        local Subject = (type(_Entity) == "string" and "'" .._Entity.. "'") or _Entity;
        API.Dbg("API.GetMovingTarget: Target " ..Subject.. " is invalid!");
        return nil;
    end
    return BundleEntityScriptingValues:GetMovingTargetPosition(_Entity);
end

---
-- Gibt zurück, ob das NPC-Flag bei dem Siedler gesetzt ist.
--
-- @param _Entity Entity
-- @return Ist NPC
-- @within User-Space
--
function API.IsNPC(_Entity)
    if not IsExisting(_Entity) then
        local Subject = (type(_Entity) == "string" and "'" .._Entity.. "'") or _Entity;
        API.Dbg("API.IsNPC: Target " ..Subject.. " is invalid!");
        return false;
    end
    return BundleEntityScriptingValues:IsOnScreenInformationActive(_Entity);
end

---
-- Gibt zurück, ob das Entity sichtbar ist.
--
-- @param _Entity Entity
-- @return Ist sichtbar
-- @within User-Space
--
function API.IsVisible(_Entity)
    if not IsExisting(_Entity) then
        local Subject = (type(_Entity) == "string" and "'" .._Entity.. "'") or _Entity;
        API.Dbg("API.IsVisible: Target " ..Subject.. " is invalid!");
        return false;
    end
    return BundleEntityScriptingValues:IsEntityVisible(_Entity);
end

---
-- Setzt den Größenfaktor des Entity.
--
-- Bei einem Siedler wird ebenfalls versucht die Bewegungsgeschwindigkeit an
-- die Größe anzupassen, was aber nicht bei allen Siedlern möglich ist.
--
-- @param _Entity Entity
-- @param _Scale  Größenfaktor
-- @within User-Space
--
function API.SetScale(_Entity, _Scale)
    if GUI or not IsExisting(_Entity) then
        local Subject = (type(_Entity) == "string" and "'" .._Entity.. "'") or _Entity;
        API.Dbg("API.SetScale: Target " ..Subject.. " is invalid!");
        return;
    end
    if type(_Scale) ~= "number" then
        API.Dbg("API.SetScale: Scale must be a number!");
        return;
    end
    return BundleEntityScriptingValues.Global:SetEntitySize(_Entity, _Scale);
end

---
-- Ändert den Besitzer des Entity.
--
-- Mit dieser Funktion werden die Sicherungen des Spiels umgangen! Es ist
-- möglich ein Raubtier einem Spieler zuzuweisen.
--
-- @param _Entity   Entity
-- @param _PlayerID Besitzer
-- @within User-Space
--
function API.SetPlayer(_Entity, _PlayerID)
    if GUI or not IsExisting(_Entity) then
        local Subject = (type(_Entity) == "string" and "'" .._Entity.. "'") or _Entity;
        API.Dbg("API.SetPlayer: Target " ..Subject.. " is invalid!");
        return;
    end
    if type(_PlayerID) ~= "number" or _PlayerID <= 0 or _PlayerID > 8 then
        API.Dbg("API.SetPlayer: Player-ID must between 0 and 8!");
        return;
    end
    return BundleEntityScriptingValues.Global:SetPlayerID(_Entity, math.floor(_PlayerID));
end

-- -------------------------------------------------------------------------- --
-- Application-Space                                                          --
-- -------------------------------------------------------------------------- --

BundleEntityScriptingValues = {
    Global = {
        Data = {}
    },
    Local = {
        Data = {}
    },
}

-- Global Script ---------------------------------------------------------------

---
-- Initalisiert das Bundle im globalen Skript.
--
-- @within Application-Space
-- @local
--
function BundleEntityScriptingValues.Global:Install()

end

---
-- Ändert die Größe des Entity.
--
-- @param _entity Entity
-- @param _size   Größenfaktor
-- @within Application-Space
-- @local
--
function BundleEntityScriptingValues.Global:SetEntitySize(_entity, _size)
    local EntityID = GetID(_entity);
    Logic.SetEntityScriptingValue(EntityID, -45, BundleEntityScriptingValues:Float2Int(_size));
    if Logic.IsSettler(EntityID) == 1 then
        Logic.SetSpeedFactor(EntityID, _size);
    end
end

---
-- Ändert den Besitzer des Entity.
--
-- @param _entity   Entity
-- @param _PlayerID Neuer Besitzer
-- @within Application-Space
-- @local
-- 
function BundleEntityScriptingValues.Global:SetPlayerID(_entity, _PlayerID)
    local EntityID = GetID(_entity);
    Logic.SetEntityScriptingValue(EntityID, -71, _PlayerID);
end

-- Local Script ----------------------------------------------------------------

---
-- Initalisiert das Bundle im lokalen Skript.
--
-- @within Application-Space
-- @local
--
function BundleEntityScriptingValues.Local:Install()

end

-- Shared ----------------------------------------------------------------------

---
-- Gibt die relative Größe des Entity zurück.
--
-- @param _entity Entity
-- @return Größenfaktor
-- @within BundleEntityScriptingValues
-- @local
--
function BundleEntityScriptingValues:GetEntitySize(_entity)
    local EntityID = GetID(_entity);
    local size = Logic.GetEntityScriptingValue(EntityID, -45);
    return self.Int2Float(size);
end

---
-- Gibt den Besitzer des Entity zurück.
-- @internal
--
-- @param _entity Entity
-- @return PlayerID
-- @within BundleEntityScriptingValues
-- @local
--
function BundleEntityScriptingValues:GetPlayerID(_entity)
    local EntityID = GetID(_entity);
    return Logic.GetEntityScriptingValue(EntityID, -71);
end

---
-- Gibt zurück, ob das Entity sichtbar ist.
--
-- @param _entity Entity
-- @return Entity ist sichtbar
-- @within BundleEntityScriptingValues
-- @local
--
function BundleEntityScriptingValues:IsEntityVisible(_entity)
    local EntityID = GetID(_entity);
    return Logic.GetEntityScriptingValue(EntityID, -50) == 801280;
end

---
-- Gibt zurück, ob eine NPC-Interaktion mit dem Siedler möglich ist.
--
-- @param _entity Entity
-- @return NPC ist aktiv
-- @within BundleEntityScriptingValues
-- @local
--
function BundleEntityScriptingValues:IsOnScreenInformationActive(_entity)
    local EntityID = GetID(_entity);
    if Logic.IsSettler(EntityID) == 0 then
        return false;
    end
    return Logic.GetEntityScriptingValue(EntityID, 6) == 1;
end

---
-- Gibt das Bewegungsziel des Entity zurück.
--
-- @param _entity Entity
-- @return Position Table
-- @within BundleEntityScriptingValues
-- @local
--
function BundleEntityScriptingValues:GetMovingTargetPosition(_entity)
    local pos = {};
    pos.X = self:GetValueAsFloat(_entity, 19);
    pos.Y = self:GetValueAsFloat(_entity, 20);
    return pos;
end

---
-- Gibt die Scripting Value des Entity als Ganzzahl zurück.
--
-- @param _entity Zu untersuchendes Entity
-- @param _index  Index im RAM
-- @return Integer
-- @within BundleEntityScriptingValues
-- @local
--
function BundleEntityScriptingValues:GetValueAsInteger(_entity, _index)
    local value = Logic.GetEntityScriptingValue(GetID(_entity),_index);
    return value;
end

---
-- Gibt die Scripting Value des Entity als Dezimalzahl zurück.
--
-- @param _entity Zu untersuchendes Entity
-- @param _index  Index im RAM
-- @return Float
-- @within BundleEntityScriptingValues
-- @local
--
function BundleEntityScriptingValues:GetValueAsFloat(_entity, _index)
    local value = Logic.GetEntityScriptingValue(GetID(_entity),_index);
    return SV.Int2Float(value);
end

---
-- Bestimmt das Modul b der Zahl a.
--
-- @param a	Zahl
-- @param b	Modul
-- @return qmod der Zahl
-- @within BundleEntityScriptingValues
-- @local
--
function BundleEntityScriptingValues:qmod(a, b)
    return a - math.floor(a/b)*b
end

---
-- Konvertiert eine Ganzzahl in eine Dezimalzahl.
--
-- @param num Integer
-- @return Integer als Float
-- @within BundleEntityScriptingValues
-- @local
--
function BundleEntityScriptingValues:Int2Float(num)
    if(num == 0) then return 0 end
    local sign = 1
    if(num < 0) then num = 2147483648 + num; sign = -1 end
    local frac = self:qmod(num, 8388608)
    local headPart = (num-frac)/8388608
    local expNoSign = self:qmod(headPart, 256)
    local exp = expNoSign-127
    local fraction = 1
    local fp = 0.5
    local check = 4194304
    for i = 23, 0, -1 do
        if(frac - check) > 0 then fraction = fraction + fp; frac = frac - check end
        check = check / 2; fp = fp / 2
    end
    return fraction * math.pow(2, exp) * sign
end

---
-- Gibt den Integer als Bits zurück
--
-- @param num Bits
-- @return Table mit Bits
-- @within BundleEntityScriptingValues
-- @local
--
function BundleEntityScriptingValues:bitsInt(num)
    local t={}
    while num>0 do
        rest=self:qmod(num, 2) table.insert(t,1,rest) num=(num-rest)/2
    end
    table.remove(t, 1)
    return t
end

---
-- Stellt eine Zahl als eine folge von Bits in einer Table dar.
--
-- @param num Integer
-- @param t	  Table
-- @return Table mit Bits
-- @within BundleEntityScriptingValues
-- @local
--
function BundleEntityScriptingValues:bitsFrac(num, t)
    for i = 1, 48 do
        num = num * 2
        if(num >= 1) then table.insert(t, 1); num = num - 1 else table.insert(t, 0) end
        if(num == 0) then return t end
    end
    return t
end

---
-- Konvertiert eine Dezimalzahl in eine Ganzzahl.
--
-- @param fval Float
-- @return Float als Integer
-- @within BundleEntityScriptingValues
-- @local
--
function BundleEntityScriptingValues:Float2Int(fval)
    if(fval == 0) then return 0 end
    local signed = false
    if(fval < 0) then signed = true; fval = fval * -1 end
    local outval = 0;
    local bits
    local exp = 0
    if fval >= 1 then
        local intPart = math.floor(fval); local fracPart = fval - intPart;
        bits = self:bitsInt(intPart); exp = table.getn(bits); self:bitsFrac(fracPart, bits)
    else
        bits = {}; self:bitsFrac(fval, bits)
        while(bits[1] == 0) do exp = exp - 1; table.remove(bits, 1) end
        exp = exp - 1
        table.remove(bits, 1)
    end
    local bitVal = 4194304; local start = 1
    for bpos = start, 23 do
        local bit = bits[bpos]
        if(not bit) then break; end
        if(bit == 1) then outval = outval + bitVal end
        bitVal = bitVal / 2
    end
    outval = outval + (exp+127)*8388608
    if(signed) then outval = outval - 2147483648 end
    return outval;
end

-- -------------------------------------------------------------------------- --

Core:RegisterBundle("BundleEntityScriptingValues");

-- -------------------------------------------------------------------------- --
-- ########################################################################## --
-- #  Symfonia BundleConstructionControl                                    # --
-- ########################################################################## --
-- -------------------------------------------------------------------------- --

---
-- Erlaubt es Gebiete oder Territorien auf der Map zu definieren, auf der ein
-- Gebäude oder ein Typ nicht gebaut bzw. nicht abgerissen werden darf.
--
-- @module BundleConstructionControl
-- @set sort=true
--

API = API or {};
QSB = QSB or {};

-- -------------------------------------------------------------------------- --
-- User-Space                                                                 --
-- -------------------------------------------------------------------------- --

---
-- Fügt ein Entity hinzu, dass nicht abgerissen werden darf.
--
-- @param _entry Nicht abreißbares Entity
-- @within User-Space
--
function API.AddEntity(_entity)
    if not GUI then
        Logic.ExecuteInLuaLocalState([[
            API.AddEntity("]].._entity..[[")
        ]]);
    else
        if not Inside(_enitry, BundleConstructionControl.Local.Data.Entities) then
            table.insert(BundleConstructionControl.Local.Data.Entities, _entity);
        end
    end
end

---
-- Fügt einen Entitytyp hinzu, der nicht abgerissen werden darf.
--
-- @param _entry Nicht abreißbarer Typ
-- @within User-Space
--
function API.AddEntityType(_entity)
    if not GUI then
        Logic.ExecuteInLuaLocalState([[
            API.AddEntityType(]].._entity..[[)
        ]]);
    else
        if not Inside(_enitry, BundleConstructionControl.Local.Data.EntityTypes) then
            table.insert(BundleConstructionControl.Local.Data.EntityTypes, _entity);
        end
    end
end

---
-- Fügt eine Kategorie hinzu, die nicht abgerissen werden darf.
--
-- @param _entry Nicht abreißbare Kategorie
-- @within User-Space
--
function API.AddCategory(_entity)
    if not GUI then
        Logic.ExecuteInLuaLocalState([[
            API.AddCategory(]].._entity..[[)
        ]]);
    else
        if not Inside(_enitry, BundleConstructionControl.Local.Data.EntityCategories) then
            table.insert(BundleConstructionControl.Local.Data.EntityCategories, _entity);
        end
    end
end

---
-- Fügt ein Territory hinzu, auf dem nichts abgerissen werden kann.
--
-- @param _entry Geschütztes Territorium
-- @within User-Space
--
function API.AddTerritory(_entity)
    if not GUI then
        Logic.ExecuteInLuaLocalState([[
            API.AddTerritory(]].._entity..[[)
        ]]);
    else
        if not Inside(_enitry, BundleConstructionControl.Local.Data.OnTerritory) then
            table.insert(BundleConstructionControl.Local.Data.OnTerritory, _entity);
        end
    end
end

---
-- Entfernt ein Entity, dass nicht abgerissen werden darf.
--
-- @param _entry Nicht abreißbares Entity
-- @within User-Space
--
function API.RemoveEntity(_entry)
    if not GUI then
        Logic.ExecuteInLuaLocalState([[
            API.RemoveEntity("]].._entry..[[")
        ]]);
    else
        for i=1,#BundleConstructionControl.Local.Data.Entities do
            if BundleConstructionControl.Local.Data.Entities[i] == _entry then
                table.remove(BundleConstructionControl.Local.Data.Entities, i);
                return;
            end
        end
    end
end

---
-- Entfernt einen Entitytyp, der nicht abgerissen werden darf.
--
-- @param _entry Nicht abreißbarer Typ
-- @within User-Space
--
function API.RemoveEntityType(_entry)
    if not GUI then
        Logic.ExecuteInLuaLocalState([[
            API.RemoveEntityType(]].._entry..[[)
        ]]);
    else
        for i=1,#BundleConstructionControl.Local.Data.EntityTypes do
            if BundleConstructionControl.Local.Data.EntityTypes[i] == _entry then
                table.remove(BundleConstructionControl.Local.Data.EntityTypes, i);
                return;
            end
        end
    end
end

---
-- Entfernt eine Kategorie, die nicht abgerissen werden darf.
--
-- @param _entry Nicht abreißbare Kategorie
-- @within User-Space
--
function API.RemoveCategory(_entry)
    if not GUI then
        Logic.ExecuteInLuaLocalState([[
            API.RemoveCategory(]].._entry..[[)
        ]]);
    else
        for i=1,#BundleConstructionControl.Local.Data.EntityCategories do
            if BundleConstructionControl.Local.Data.EntityCategories[i] == _entry then
                table.remove(BundleConstructionControl.Local.Data.EntityCategories, i);
                return;
            end
        end
    end
end

---
-- Entfernt ein Territory, auf dem nichts abgerissen werden kann.
--
-- @param _entry Geschütztes Territorium
-- @within User-Space
--
function API.RemoveTerritory(_entry)
    if not GUI then
        Logic.ExecuteInLuaLocalState([[
            API.RemoveTerritory(]].._entry..[[)
        ]]);
    else
        for i=1,#BundleConstructionControl.Local.Data.OnTerritory do
            if BundleConstructionControl.Local.Data.OnTerritory[i] == _entry then
                table.remove(BundleConstructionControl.Local.Data.OnTerritory, i);
                return;
            end
        end
    end
end

---
-- Untersagt den Bau des Typs im Territorium.
--
-- @param _type      Entitytyp
-- @param _territory Territorium
-- @within User-Space
--
function API.BanTypeAtTerritory(_type, _territory)
    if GUI then
        local Territory = (type(_center) == "string" and "'" .._territory.. "'") or _territory;
        GUI.SendScriptCommand("API.BanTypeAtTerritory(" .._type.. ", " ..Territory.. ")");
        return;
    end
    if type(_territory) == "string" then
        _territory = GetTerritoryIDByName(_territory);
    end

    BundleConstructionControl.Global.Data.TerritoryBlockEntities[_type] = BundleConstructionControl.Global.Data.TerritoryBlockEntities[_type] or {};
    if not Inside(_territory, BundleConstructionControl.Global.Data.TerritoryBlockEntities[_type]) then
        table.insert(BundleConstructionControl.Global.Data.TerritoryBlockEntities[_type], _territory);
    end
end

---
-- Untersagt den Bau der Kategorie im Territorium.
--
-- @param _eCat      Entitykategorie
-- @param _territory Territorium
-- @within User-Space
--
function API.BanCategoryAtTerritory(_eCat, _territory)
    if GUI then
        local Territory = (type(_center) == "string" and "'" .._territory.. "'") or _territory;
        GUI.SendScriptCommand("API.BanTypeAtTerritory(" .._eCat.. ", " ..Territory.. ")");
        return;
    end
    if type(_territory) == "string" then
        _territory = GetTerritoryIDByName(_territory);
    end

    BundleConstructionControl.Global.Data.TerritoryBlockCategories[_eCat] = BundleConstructionControl.Global.Data.TerritoryBlockCategories[_eCat] or {};
    if not Inside(_territory, BundleConstructionControl.Global.Data.TerritoryBlockCategories[_eCat]) then
        table.insert(BundleConstructionControl.Global.Data.TerritoryBlockCategories[_eCat], _territory);
    end
end

---
-- Untersagt den Bau des Typs im Gebiet.
--
-- @param _type   Entitytyp
-- @param _center Gebietszentrum
-- @param _area   Gebietsgröße
-- @within User-Space
--
function API.BanTypeInArea(_type, _center, _area)
    if GUI then
        local Center = (type(_center) == "string" and "'" .._center.. "'") or _center;
        GUI.SendScriptCommand("API.BanTypeInArea(" .._type.. ", " ..Center.. ", " .._area.. ")");
        return;
    end

    BundleConstructionControl.Global.Data.AreaBlockEntities[_center] = BundleConstructionControl.Global.Data.AreaBlockEntities[_center] or {};
    if not Inside(_type, BundleConstructionControl.Global.Data.AreaBlockEntities[_center], true) then
        table.insert(BundleConstructionControl.Global.Data.AreaBlockEntities[_center], {_type, _area});
    end
end

---
-- Untersagt den Bau der Kategorie im Gebiet.
--
-- @param _eCat   Entitykategorie
-- @param _center Gebietszentrum
-- @param _area   Gebietsgröße
-- @within User-Space
--
function API.BanCategoryInArea(_eCat, _center, _area)
    if GUI then
        local Center = (type(_center) == "string" and "'" .._center.. "'") or _center;
        GUI.SendScriptCommand("API.BanCategoryInArea(" .._eCat.. ", " ..Center.. ", " .._area.. ")");
        return;
    end

    BundleConstructionControl.Global.Data.AreaBlockCategories[_center] = BundleConstructionControl.Global.Data.AreaBlockCategories[_center] or {};
    if not Inside(_eCat, BundleConstructionControl.Global.Data.AreaBlockCategories[_center], true) then
        table.insert(BundleConstructionControl.Global.Data.AreaBlockCategories[_center], {_eCat, _area});
    end
end

---
-- Gibt einen Typ zum Bau im Territorium wieder frei.
--
-- @param _type      Entitytyp
-- @param _territory Territorium
-- @within User-Space
--
function API.UnBanTypeAtTerritory(_type, _territory)
    if GUI then
        local Territory = (type(_center) == "string" and "'" .._territory.. "'") or _territory;
        GUI.SendScriptCommand("API.UnBanTypeAtTerritory(" .._type.. ", " ..Territory.. ")");
        return;
    end
    if type(_territory) == "string" then
        _territory = GetTerritoryIDByName(_territory);
    end
    
    if not BundleConstructionControl.Global.Data.TerritoryBlockEntities[_type] then
        return;
    end
    for i=1, BundleConstructionControl.Global.Data.TerritoryBlockEntities[_type], 1 do
        if BundleConstructionControl.Global.Data.TerritoryBlockEntities[_type][i] == _type then
            table.remove(BundleConstructionControl.Global.Data.TerritoryBlockEntities[_type], i);
            break;
        end
    end
end

---
-- Gibt eine Kategorie zum Bau im Territorium wieder frei.
--
-- @param _ecat      Entitykategorie
-- @param _territory Territorium
-- @within User-Space
--
function API.UnBanCategoryAtTerritory(_eCat, _territory)
    if GUI then
        local Territory = (type(_center) == "string" and "'" .._territory.. "'") or _territory;
        GUI.SendScriptCommand("API.UnBanTypeAtTerritory(" .._eCat.. ", " ..Territory.. ")");
        return;
    end
    if type(_territory) == "string" then
        _territory = GetTerritoryIDByName(_territory);
    end

    if not BundleConstructionControl.Global.Data.TerritoryBlockCategories[_eCat] then
        return;
    end
    for i=1, BundleConstructionControl.Global.Data.TerritoryBlockCategories[_eCat], 1 do
        if BundleConstructionControl.Global.Data.TerritoryBlockCategories[_eCat][i] == _type then
            table.remove(BundleConstructionControl.Global.Data.TerritoryBlockCategories[_eCat], i);
            break;
        end
    end
end

---
-- Gibt einen Typ zum Bau im Gebiet wieder frei.
--
-- @param _type   Entitytyp
-- @param _center Gebiet
-- @within User-Space
--
function API.UnBanTypeInArea (_type, _center)
    if GUI then
        local Center = (type(_center) == "string" and "'" .._center.. "'") or _center;
        GUI.SendScriptCommand("API.UnBanTypeInArea(" .._eCat.. ", " ..Center.. ")");
        return;
    end

    if not BundleConstructionControl.Global.Data.AreaBlockEntities[_center] then
        return;
    end
    for i=1, BundleConstructionControl.Global.Data.AreaBlockEntities[_center], 1 do
        if BundleConstructionControl.Global.Data.AreaBlockEntities[_center][i][1] == _type then
            table.remove(BundleConstructionControl.Global.Data.AreaBlockEntities[_center], i);
            break;
        end
    end
end

---
-- Gibt eine Kategorie zum Bau im Gebiet wieder frei.
--
-- @param _eCat   Entitykategorie
-- @param _center Gebiet
-- @within User-Space
--
function API.UnBanCategoryInArea(_eCat, _center)
    if GUI then
        local Center = (type(_center) == "string" and "'" .._center.. "'") or _center;
        GUI.SendScriptCommand("API.UnBanCategoryInArea(" .._type.. ", " ..Center.. ")");
        return;
    end

    if not BundleConstructionControl.Global.Data.AreaBlockCategories[_center] then
        return;
    end
    for i=1, BundleConstructionControl.Global.Data.AreaBlockCategories[_center], 1 do
        if BundleConstructionControl.Global.Data.AreaBlockCategories[_center][i][1] == _eCat then
            table.remove(BundleConstructionControl.Global.Data.AreaBlockCategories[_center], i);
            break;
        end
    end
end

-- -------------------------------------------------------------------------- --
-- Application-Space                                                          --
-- -------------------------------------------------------------------------- --

BundleConstructionControl = {
    Global = {
        Data = {
            TerritoryBlockCategories = {},
            TerritoryBlockEntities = {},
            AreaBlockCategories = {},
            AreaBlockEntities = {},
        }
    },
    Local = {
        Data = {
            Entities = {},
            EntityTypes = {},
            EntityCategories = {},
            OnTerritory = {},
        }
    },
}

-- Global Script ---------------------------------------------------------------

---
-- Initalisiert das Bundle im globalen Skript.
--
-- @within Application-Space
-- @local
--
function BundleConstructionControl.Global:Install()
    Core:AppendFunction(
        "GameCallback_CanPlayerPlaceBuilding",
        BundleConstructionControl.Global.CanPlayerPlaceBuilding
    );
end

---
-- Verhindert den Bau von Entities in Gebieten und Territorien.
--
-- @param _Arg      Argumente Originalfunktion
-- @param _Original Referenz Originalfunktion
-- @within Application-Space
-- @local
--
function BundleConstructionControl.Global.CanPlayerPlaceBuilding(_Arg, _Original)
    local PlayerID = _Arg[1];
    local Type     = _Arg[1];
    local x        = _Arg[1];
    local y        = _Arg[1];
    
    -- Auf Territorium ---------------------------------------------

    -- Prüfe Kategorien
    for k,v in pairs(BundleConstructionControl.Global.Data.TerritoryBlockCategories) do
        if v then
            for key, val in pairs(v) do
                if val and Logic.GetTerritoryAtPosition(x, y) == val then
                    if Logic.IsEntityTypeInCategory(Type, k) == 1 then
                        return false;
                    end
                end
            end
        end
    end

    -- Prüfe Typen
    for k,v in pairs(BundleConstructionControl.Global.Data.TerritoryBlockEntities) do
        if v then
            for key,val in pairs(v) do
                GUI_Note(tostring(Logic.GetTerritoryAtPosition(x, y) == val));
                if val and Logic.GetTerritoryAtPosition(x, y) == val then
                    if Type == k then
                        return false;
                    end
                end
            end
        end
    end
    
    -- In einem Gebiet ---------------------------------------------

    -- Prüfe Kategorien
    for k, v in pairs(BundleConstructionControl.Global.Data.AreaBlockCategories) do
        if v then
            for key, val in pairs(v) do
                if Logic.IsEntityTypeInCategory(Type, val[1]) == 1 then
                    if GetDistance(k, {X= x, Y= y}) < val[2] then
                        return false;
                    end
                end
            end
        end
    end

    -- Prüfe Typen
    for k, v in pairs(BundleConstructionControl.Global.Data.AreaBlockEntities) do
        if v then
            for key, val in pairs(v) do
                if Type == val[1] then
                    if GetDistance(k, {X= x, Y= y}) < val[2] then
                        return false;
                    end
                end
            end
        end
    end
end

-- Local Script ----------------------------------------------------------------

---
-- Initalisiert das Bundle im lokalen Skript.
--
-- @within Application-Space
-- @local
--
function BundleConstructionControl.Local:Install()
    Core:AppendFunction(
        "GameCallback_GUI_DeleteEntityStateBuilding",
        BundleConstructionControl.Local.DeleteEntityStateBuilding
    );
end

---
-- Verhindert den Abriss von Entities.
--
-- @param _Arg      Argumente Originalfunktion
-- @param _Original Referenz Originalfunktion
-- @within Application-Space
-- @local
--
function BundleConstructionControl.Local.DeleteEntityStateBuilding(_Arg, _Original)
    local eType = Logic.GetEntityType(_Arg[1]);
    local eName = Logic.GetEntityName(_Arg[1]);
    local tID   = GetTerritoryUnderEntity(_Arg[1]);
    
    if Logic.IsConstructionComplete(_BuildingID) == 1 and Module_tHEA.GameControl.Protection then
        -- Prüfe auf Namen
        if Inside(eName, BundleConstructionControl.Local.Data.Entities) then
            Message(Module_tHEA_Protection.Description.NoKnockdown[Module_tHEA_Protection.lang]);
            GUI.CancelBuildingKnockDown(_BuildingID);
            return;
        end

        -- Prüfe auf Typen
        if Inside(eType, BundleConstructionControl.Local.Data.EntityTypes) then
            Message(Module_tHEA_Protection.Description.NoKnockdown[Module_tHEA_Protection.lang]);
            GUI.CancelBuildingKnockDown(_BuildingID);
            return;
        end

        -- Prüfe auf Territorien
        if Inside(tID, BundleConstructionControl.Local.Data.OnTerritory) then
            Message(Module_tHEA_Protection.Description.NoKnockdown[Module_tHEA_Protection.lang]);
            GUI.CancelBuildingKnockDown(_BuildingID);
            return;
        end

        -- Prüfe auf Category
        for k,v in pairs(BundleConstructionControl.Local.Data.EntityCategories) do
            if Logic.IsEntityInCategory(_BuildingID, v) == 1 then
                Message(Module_tHEA_Protection.Description.NoKnockdown[Module_tHEA_Protection.lang]);
                GUI.CancelBuildingKnockDown(_BuildingID);
                return;
            end
        end
    end
end

-- -------------------------------------------------------------------------- --

Core:RegisterBundle("BundleConstructionControl");

-- -------------------------------------------------------------------------- --
-- ########################################################################## --
-- #  Symfonia BundleEntitySelection                                        # --
-- ########################################################################## --
-- -------------------------------------------------------------------------- --

---
-- Dieses Bundle implementiert verschiedene Selektionsmodi. Es gibt keine
-- öffentlichen Funktionen. Das Bundle arbeitet autonom ohne zutun.
--
-- @module BundleEntitySelection
-- @set sort=true
--

API = API or {};
QSB = QSB or {};

-- -------------------------------------------------------------------------- --
-- User-Space                                                                 --
-- -------------------------------------------------------------------------- --



-- -------------------------------------------------------------------------- --
-- Application-Space                                                          --
-- -------------------------------------------------------------------------- --

BundleEntitySelection = {
    Global = {},
    Local = {
        Data = {
            Tooltips = {
                KnightButton = {
                    Title = {
                        de = "Ritter selektieren",
                        en = "Select Knight",
                    },
                    Text = {
                        de = "- Klick selektiert den Ritter {cr}- Doppelklick springt zum Ritter{cr}- STRG halten selektiert alle Ritter",
                        en = "- Click selects the knight {cr}- Double click jumps to knight{cr}- Press CTRL to select all knights",
                    },
                },
                BattalionButton = {
                    Title = {
                        de = "Militär selektieren",
                        en = "Select Units",
                    },
                    Text = {
                        de = "- Selektiert alle Militäreinheiten {cr}- SHIFT halten um auch Munitionswagen und Trebuchets auszuwählen",
                        en = "- Selects all military units {cr}- Press SHIFT to additionally select ammunition carts and trebuchets",
                    },
                },
            },
        },
    },
    
};

-- Global Script ---------------------------------------------------------------

---
-- Initialisiert das Bundle im globalen Skript.
-- @within Application-Space
-- @local
--
function BundleEntitySelection.Global:Install()

end

-- Local Script ----------------------------------------------------------------

---
-- Initialisiert das Bundle im lokalen Skript.
-- @within Application-Space
-- @local
--
function BundleEntitySelection.Local:Install()
    self:OverwriteSelectAllUnits();
    self:OverwriteSelectKnight();
    self:OverwriteNamesAndDescription();
end

---
-- Hängt eine Funktion an die GUI_Tooltip.SetNameAndDescription an, sodass
-- Tooltips überschrieben werden können.
--
-- @within Application-Space
-- @local
--
function BundleEntitySelection.Local:OverwriteNamesAndDescription()
    GUI_Tooltip.SetNameAndDescription_Orig_QSB_EntitySelection = GUI_Tooltip.SetNameAndDescription;
    GUI_Tooltip.SetNameAndDescription = function(_TooltipNameWidget, _TooltipDescriptionWidget, _OptionalTextKeyName, _OptionalDisabledTextKeyName, _OptionalMissionTextFileBoolean)
        local CurrentWidgetID = XGUIEng.GetCurrentWidgetID()
        local lang = (Network.GetDesiredLanguage() == "de" and "de") or "en"
        
        if XGUIEng.GetWidgetID("/InGame/Root/Normal/AlignBottomRight/MapFrame/KnightButton") == CurrentWidgetID then
            BundleEntitySelection.Local:SetTooltip(
                BundleEntitySelection.Local.Data.Tooltips.KnightButton.Title[lang], 
                BundleEntitySelection.Local.Data.Tooltips.KnightButton.Text[lang]
            )
            return;
        end
        
        if XGUIEng.GetWidgetID("/InGame/Root/Normal/AlignBottomRight/MapFrame/BattalionButton") == CurrentWidgetID then
            BundleEntitySelection.Local:SetTooltip(
                BundleEntitySelection.Local.Data.Tooltips.BattalionButton.Title[lang],
                BundleEntitySelection.Local.Data.Tooltips.BattalionButton.Text[lang]
            )
            return;
        end
        GUI_Tooltip.SetNameAndDescription_Orig_QSB_EntitySelection(_TooltipNameWidget, _TooltipDescriptionWidget, _OptionalTextKeyName, _OptionalDisabledTextKeyName, _OptionalMissionTextFileBoolean);
    end
end

---
-- Schreibt einen anderen Text in einen normalen Tooltip.
--
-- @param _TitleText Titel des Tooltip
-- @param _DescText  Text des Tooltip
-- @within Application-Space
-- @local
--
function BundleEntitySelection.Local:SetTooltip(_TitleText, _DescText)
    local TooltipContainerPath = "/InGame/Root/Normal/TooltipNormal"
    local TooltipContainer = XGUIEng.GetWidgetID(TooltipContainerPath)
    local TooltipNameWidget = XGUIEng.GetWidgetID(TooltipContainerPath .. "/FadeIn/Name")
    local TooltipDescriptionWidget = XGUIEng.GetWidgetID(TooltipContainerPath .. "/FadeIn/Text")
    
    XGUIEng.SetText(TooltipNameWidget, "{center}" .. _TitleText)
    XGUIEng.SetText(TooltipDescriptionWidget, _DescText)
    
    local Height = XGUIEng.GetTextHeight(TooltipDescriptionWidget, true)
    local W, H = XGUIEng.GetWidgetSize(TooltipDescriptionWidget)
    
    XGUIEng.SetWidgetSize(TooltipDescriptionWidget, W, Height)
end

---
-- Überschreibt den SelectKnight-Button. Durch drücken von CTLR können alle
-- Helden selektiert werden, die der Spieler kontrolliert.
--
-- @within Application-Space
-- @local
--
function BundleEntitySelection.Local:OverwriteSelectKnight()
    GUI_Knight.JumpToButtonClicked = function()
        local PlayerID = GUI.GetPlayerID();
        local KnightID = Logic.GetKnightID(PlayerID);
        if KnightID > 0 then
            g_MultiSelection.EntityList = {};
            g_MultiSelection.Highlighted = {};
            GUI.ClearSelection();
            
            if XGUIEng.IsModifierPressed(Keys.ModifierControl) then
                local knights = {}
                Logic.GetKnights(PlayerID, knights);
                for i=1,#knights do
                    GUI.SelectEntity(knights[i]);
                end
            else
                GUI.SelectEntity(Logic.GetKnightID(PlayerID));
                
                if ((Framework.GetTimeMs() - g_Selection.LastClickTime ) < g_Selection.MaxDoubleClickTime) then
                    local pos = GetPosition(KnightID);
                    Camera.RTS_SetLookAtPosition(pos.X, pos.Y);
                else
                    Sound.FXPlay2DSound("ui\\mini_knight");
                end
                
                g_Selection.LastClickTime = Framework.GetTimeMs();
            end
            GUI_MultiSelection.CreateMultiSelection(g_SelectionChangedSource.User);
        else
            GUI.AddNote("Debug: You do not have a knight");
        end
    end
end

---
-- Überschreibt die Militärselektion, sodass der Spieler mit SHIFT zusätzlich
-- die Munitionswagen und Trebuchets selektieren kann.
-- @within Application-Space
-- @local
--
function BundleEntitySelection.Local:OverwriteSelectAllUnits()
    GUI_MultiSelection.SelectAllPlayerUnitsClicked = function()
        if XGUIEng.IsModifierPressed(Keys.ModifierShift) then
            BundleEntitySelection.Local:ExtendedLeaderSortOrder();
        else
            BundleEntitySelection.Local:NormalLeaderSortOrder();
        end
        
        Sound.FXPlay2DSound("ui\\menu_click");
        GUI.ClearSelection();
        
        local PlayerID = GUI.GetPlayerID()   
        for i = 1, #LeaderSortOrder do
            local EntitiesOfThisType = GetPlayerEntities(PlayerID, LeaderSortOrder[i])      
            for j = 1, #EntitiesOfThisType do
                GUI.SelectEntity(EntitiesOfThisType[j])
            end
        end
        
        local Knights = {}
        Logic.GetKnights(PlayerID, Knights)
        for k = 1, #Knights do
            GUI.SelectEntity(Knights[k])
        end
        GUI_MultiSelection.CreateMultiSelection(g_SelectionChangedSource.User);
    end
end

---
-- Erzeugt die normale Sortierung ohne Munitionswagen und Trebuchets.
-- @within Application-Space
-- @local
--
function BundleEntitySelection.Local:NormalLeaderSortOrder()
    g_MultiSelection = {};
    g_MultiSelection.EntityList = {};
    g_MultiSelection.Highlighted = {};

    LeaderSortOrder     = {};
    LeaderSortOrder[1]  = Entities.U_MilitarySword;
    LeaderSortOrder[2]  = Entities.U_MilitaryBow;
    LeaderSortOrder[3]  = Entities.U_MilitarySword_RedPrince;
    LeaderSortOrder[4]  = Entities.U_MilitaryBow_RedPrince;
    LeaderSortOrder[5]  = Entities.U_MilitaryBandit_Melee_ME;
    LeaderSortOrder[6]  = Entities.U_MilitaryBandit_Melee_NA;
    LeaderSortOrder[7]  = Entities.U_MilitaryBandit_Melee_NE;
    LeaderSortOrder[8]  = Entities.U_MilitaryBandit_Melee_SE;
    LeaderSortOrder[9]  = Entities.U_MilitaryBandit_Ranged_ME;
    LeaderSortOrder[10] = Entities.U_MilitaryBandit_Ranged_NA;
    LeaderSortOrder[11] = Entities.U_MilitaryBandit_Ranged_NE;
    LeaderSortOrder[12] = Entities.U_MilitaryBandit_Ranged_SE;
    LeaderSortOrder[13] = Entities.U_MilitaryCatapult;
    LeaderSortOrder[14] = Entities.U_MilitarySiegeTower;
    LeaderSortOrder[15] = Entities.U_MilitaryBatteringRam;
    LeaderSortOrder[16] = Entities.U_CatapultCart;
    LeaderSortOrder[17] = Entities.U_SiegeTowerCart;
    LeaderSortOrder[18] = Entities.U_BatteringRamCart;
    LeaderSortOrder[19] = Entities.U_Thief;

    -- Asien wird nur in der Erweiterung gebraucht.
    if g_GameExtraNo >= 1 then
        table.insert(LeaderSortOrder,  4, Entities.U_MilitarySword_Khana);
        table.insert(LeaderSortOrder,  6, Entities.U_MilitaryBow_Khana);
        table.insert(LeaderSortOrder,  7, Entities.U_MilitaryBandit_Melee_AS);
        table.insert(LeaderSortOrder, 12, Entities.U_MilitaryBandit_Ranged_AS);
    end
end

---
-- Erzeugt die erweiterte Selektion mit Munitionswagen und Trebuchets.
-- @within Application-Space
-- @local
--
function BundleEntitySelection.Local:ExtendedLeaderSortOrder()
    g_MultiSelection = {};
    g_MultiSelection.EntityList = {};
    g_MultiSelection.Highlighted = {};

    LeaderSortOrder     = {};
    LeaderSortOrder[1]  = Entities.U_MilitarySword;
    LeaderSortOrder[2]  = Entities.U_MilitaryBow;
    LeaderSortOrder[3]  = Entities.U_MilitarySword_RedPrince;
    LeaderSortOrder[4]  = Entities.U_MilitaryBow_RedPrince;
    LeaderSortOrder[5]  = Entities.U_MilitaryBandit_Melee_ME;
    LeaderSortOrder[6]  = Entities.U_MilitaryBandit_Melee_NA;
    LeaderSortOrder[7]  = Entities.U_MilitaryBandit_Melee_NE;
    LeaderSortOrder[8]  = Entities.U_MilitaryBandit_Melee_SE;
    LeaderSortOrder[9]  = Entities.U_MilitaryBandit_Ranged_ME;
    LeaderSortOrder[10] = Entities.U_MilitaryBandit_Ranged_NA;
    LeaderSortOrder[11] = Entities.U_MilitaryBandit_Ranged_NE;
    LeaderSortOrder[12] = Entities.U_MilitaryBandit_Ranged_SE;
    LeaderSortOrder[13] = Entities.U_MilitaryCatapult;
    LeaderSortOrder[14] = Entities.U_Trebuchet;
    LeaderSortOrder[15] = Entities.U_MilitarySiegeTower;
    LeaderSortOrder[16] = Entities.U_MilitaryBatteringRam;
    LeaderSortOrder[17] = Entities.U_CatapultCart;
    LeaderSortOrder[18] = Entities.U_SiegeTowerCart;
    LeaderSortOrder[19] = Entities.U_BatteringRamCart;
    LeaderSortOrder[20] = Entities.U_AmmunitionCart;
    LeaderSortOrder[21] = Entities.U_Thief;

    -- Asien wird nur in der Erweiterung gebraucht.
    if g_GameExtraNo >= 1 then
        table.insert(LeaderSortOrder,  4, Entities.U_MilitarySword_Khana);
        table.insert(LeaderSortOrder,  6, Entities.U_MilitaryBow_Khana);
        table.insert(LeaderSortOrder,  7, Entities.U_MilitaryBandit_Melee_AS);
        table.insert(LeaderSortOrder, 12, Entities.U_MilitaryBandit_Ranged_AS);
    end
end

-- -------------------------------------------------------------------------- --

Core:RegisterBundle("BundleEntitySelection");

-- -------------------------------------------------------------------------- --
-- ########################################################################## --
-- #  Symfonia BundleSaveGameTools                                          # --
-- ########################################################################## --
-- -------------------------------------------------------------------------- --

---
-- Dieses Bundle bietet Funktionen an, mit denen Spielstände. außerhalb des
-- üblichen Ordners gespeichert und geladen werden können.
--
-- @module BundleSaveGameTools
-- @set sort=true
--

API = API or {};
QSB = QSB or {};

-- -------------------------------------------------------------------------- --
-- User-Space                                                                 --
-- -------------------------------------------------------------------------- --

---
-- Speichert das Spiel mit automatisch fortlaufender Nummer im Namen
-- des Spielstandes. Wenn nicht gespeichert werden kann, wird bis
-- zum nδchsten mφglichen Zeitpunkt gewartet.
--
-- @param _Name	Name des Spielstandes
-- @within User-Space
--
function API.AutoSaveGame(_name)
    assert(_name);
    if not GUI then
        API.Bridge('API.AutoSaveGame("'.._name..'")');
        return;
    end
    BundleSaveGameTools.Local:AutoSaveGame(_name);
end

---
-- Speichert den Spielstand in das angegebene Verzeichnis. Es kφnnen
-- keine Verzeichnise erzeugt werden. Der Pfad beginnt relativ vom
-- Spielstandverzeichnis.
--
-- @param _path	Pfad zum Ziel
-- @param _name	Name des Spielstandes
-- @within User-Space
--
function API.SaveGameToFolder(_path, _name)
    assert(_path);
    assert(_name);
    if not GUI then
        API.Bridge('API.SaveGameToFolder("'.._path..'", "'.._name..'")');
        return;
    end
    BundleSaveGameTools.Local:SaveGameToFolder(_path, _name);
end

---
-- Lδd einen Spielstand aus dem angegebenen Verzeichnis. Der Pfad 
-- beginnt relativ vom Spielstandverzeichnis. Optional kann der
-- Ladebildschirm gehalten werden, bis der Spieler das Spiel per
-- Button startet.
--
-- @param _path		  Pfad zum Ziel
-- @param _name		  Name des Spielstandes
-- @param _needButton Startbutton anzeigen (0 oder 1)
-- @within User-Space
--
function API.LoadGameFromFolder(_path, _name, _needButton)
    assert(_path);
    assert(_name);
    assert(_needButton);
    if not GUI then
        API.Bridge('API.LoadGameFromFolder("'.._path..'", "'.._name..'", "'.._needButton..'")');
        return;
    end
    BundleSaveGameTools.Local:LoadGameFromFolder(_path, _name, _needButton);
end

---
-- Startet eine Map aus dem angegebenen Verzeichnis. Die Verzeichnisse
-- werden durch IDs unterschieden.
-- <ul>
-- <li>Kampagne: -1</li>
-- <li>Development:	1</li>
-- <li>Singleplayer: 0</li>
-- <li>Multiplayer:	2</li>
-- <li>Usermap: 3</li>
-- </ul>
--
-- @param _map			Name der Map
-- @param _knight		Index des Helden
-- @param _folder		Mapordner
-- @param _needButton	Startbutton nutzen
-- @within User-Space
--
function API.StartMap(_map, _knight, _folder, _needButton)
    assert(_map);
    assert(_knight);
    assert(_folder);
    assert(_needButton);
    if not GUI then
        API.Bridge('API.StartMap("'.._map..'", "'.._knight..'", "'.._needButton..'", "'.._needButton..'")');
        return;
    end
    BundleSaveGameTools.Local:LoadGameFromFolder(_map, _knight, _folder, _needButton);
end

-- -------------------------------------------------------------------------- --
-- Application-Space                                                          --
-- -------------------------------------------------------------------------- --

BundleSaveGameTools = {
    Global = {
        Data = {}
    },
    Local = {
        Data = {
            AutoSaveCounter = 0,
        }
    },
}

-- Global Script ---------------------------------------------------------------

---
-- Initalisiert das Bundle im globalen Skript.
--
-- @within Application-Space
-- @local
--
function BundleSaveGameTools.Global:Install()

end



-- Local Script ----------------------------------------------------------------

---
-- Initalisiert das Bundle im lokalen Skript.
--
-- @within Application-Space
-- @local
--
function BundleSaveGameTools.Local:Install()

end

---
-- Speichert das Spiel mit automatisch fortlaufender Nummer im Namen
-- des Spielstandes. Wenn nicht gespeichert werden kann, wird bis
-- zum nδchsten mφglichen Zeitpunkt gewartet.
--
-- @param _Name	Name des Spielstandes
-- @within Application-Space
-- @local
--
function BundleSaveGameTools.Local:AutoSaveGame(_name)
    _name = _name or Framework.GetCurrentMapName();

    local counter = BundleSaveGameTools.Local.Data.AutoSaveCounter +1;
    BundleSaveGameTools.Local.Data.AutoSaveCounter = counter;
    local lang = Network.GetDesiredLanguage();
    if lang ~= "de" then lang = "en" end
    local text = (lang == "de" and "Spiel wird gespeichert...") or
                  "Saving game...";

    if (not IsBriefingActive or not IsBriefingActive()) and XGUIEng.IsWidgetShownEx("/LoadScreen/LoadScreen") == 0 then
        OpenDialog(text, XGUIEng.GetStringTableText("UI_Texts/MainMenuSaveGame_center"));
        XGUIEng.ShowWidget("/InGame/Dialog/Ok", 0);
        Framework.SaveGame("Autosave "..counter.." --- ".._name, "--");
    else
        StartSimpleJobEx( function()
            if (not IsBriefingActive or not IsBriefingActive()) and XGUIEng.IsWidgetShownEx("/LoadScreen/LoadScreen") == 0 then
                OpenDialog(text, XGUIEng.GetStringTableText("UI_Texts/MainMenuSaveGame_center"));
                XGUIEng.ShowWidget("/InGame/Dialog/Ok", 0);
                Framework.SaveGame("Autosave - "..counter.." --- ".._name, "--");
                return true;
            end
        end);
    end
end

---
-- Speichert den Spielstand in das angegebene Verzeichnis. Es kφnnen
-- keine Verzeichnise erzeugt werden. Der Pfad beginnt relativ vom
-- Spielstandverzeichnis.
--
-- @param _path	Pfad zum Ziel
-- @param _name	Name des Spielstandes
-- @within Application-Space
-- @local
--
function BundleSaveGameTools.Local:SaveGameToFolder(_path, _name)
    _name = _name or Framework.GetCurrentMapName();
    Framework.SaveGame(_path .. "/" .. _name, "--");
end

---
-- Läd einen Spielstand aus dem angegebenen Verzeichnis. Der Pfad 
-- beginnt relativ vom Spielstandverzeichnis. Optional kann der
-- Ladebildschirm gehalten werden, bis der Spieler das Spiel per
-- Button startet.
--
-- @param _path		  Pfad zum Ziel
-- @param _name		  Name des Spielstandes
-- @param _needButton Startbutton anzeigen (0 oder 1)
-- @within Application-Space
-- @local
--
function BundleSaveGameTools.Local:LoadGameFromFolder(_path, _name, _needButton)
    _needButton = _needButton or 0;
    assert( type(_name) == "string" );
    local SaveName = _path .. "/" .. _name .. GetSaveGameExtension();
    local Name, Type, Campaign = Framework.GetSaveGameMapNameAndTypeAndCampaign(SaveName);
    InitLoadScreen(false, Type, Name, Campaign, 0);
    Framework.ResetProgressBar();
    Framework.SetLoadScreenNeedButton(_needButton);
    Framework.LoadGame(SaveName);
end

---
-- Startet eine Map aus dem angegebenen Verzeichnis. Die Verzeichnisse
-- werden durch IDs unterschieden.
-- <ul>
-- <li>Kampagne: -1</li>
-- <li>Development:	1</li>
-- <li>Singleplayer: 0</li>
-- <li>Multiplayer:	2</li>
-- <li>Usermap: 3</li>
-- </ul>
--
-- @param _map			Name der Map
-- @param _knight		Index des Helden
-- @param _folder		Mapordner
-- @param _needButton	Startbutton nutzen
-- @within Application-Space
-- @local
--
function BundleSaveGameTools.Local:LoadGameFromFolder(_map, _knight, _folder, _needButton)
    _needButton = _needButton or 1;
    _knight = _knight or 0;
    _folder = _folder or 3;
    local name, desc, size, mode = Framework.GetMapNameAndDescription(_map, _folder);
    if name ~= nil and name ~= "" then
        XGUIEng.ShowAllSubWidgets("/InGame",0);
        Framework.SetLoadScreenNeedButton(_needButton);
        InitLoadScreen(false, _folder, _map, 0, _knight);
        Framework.ResetProgressBar();
        Framework.StartMap(_map, _folder, _knight);
    else
        GUI.AddNote("ERROR: invalid mapfile!");
    end
end

-- -------------------------------------------------------------------------- --

Core:RegisterBundle("BundleSaveGameTools");

-- -------------------------------------------------------------------------- --
-- ########################################################################## --
-- #  Symfonia BundleEntityHelperFunctions                                  # --
-- ########################################################################## --
-- -------------------------------------------------------------------------- --

---
-- Dieses Bundle enthält häufig gebrauchte Funktionen im Kontext zu Entities.
--
-- @module BundleEntityHelperFunctions
-- @set sort=true
--

API = API or {};
QSB = QSB or {};

-- -------------------------------------------------------------------------- --
-- User-Space                                                                 --
-- -------------------------------------------------------------------------- --

---
-- Ermittelt alle Entities in den Kategorien auf den Territorien für die
-- Liste von Parteien und gibt sie als Liste zurück.
--
-- <b>Alias:</b> GetEntitiesOfCategoriesInTerritories
-- 
-- @param _player       PlayerID [0-8] oder Table mit PlayerIDs
-- @param _category     Kategorien oder Table mit Kategorien
-- @param _territory    Zielterritorium oder Table mit Territorien
-- @return table: Liste mit Entities
-- @within User-Space
--
function API.GetEntitiesOfCategoriesInTerritories(_player, _category, _territory)
    return BundleEntityHelperFunctions:GetEntitiesOfCategoriesInTerritories(_player, _category, _territory);
end
GetEntitiesOfCategoriesInTerritories = API.GetEntitiesOfCategoriesInTerritories;

---
-- Gibt alle Entities zurück, deren Name mit dem Prefix beginnt. 
--
-- <b>Alias:</b> GetEntitiesNamedWith
-- 
-- @param _Prefix Präfix des Skriptnamen
-- @return table: Liste mit Entities
-- @within User-Space
--
function API.GetEntitiesByPrefix(_Prefix)
    return BundleEntityHelperFunctions:GetEntitiesByPrefix(_Prefix);
end
GetEntitiesNamedWith = API.GetEntitiesByPrefix;

-- Setzt die Menge an Rohstoffen und die durchschnittliche Auffüllmenge
-- in einer Mine. 
--
-- <b>Alias:</b> SetResourceAmount
--
-- @param _Entity       Skriptname, EntityID der Mine
-- @param _StartAmount  Menge an Rohstoffen
-- @param _RefillAmount Minimale Nachfüllmenge (> 0)
-- @within User Spase
--
function API.SetResourceAmount(_Entity, _StartAmount, _RefillAmount)
    if GUI then
        local Subject = (type(_Entity) ~= "string" and _Entity) or "'" .._Entity.. "'";
        API.Bridge("API.SetResourceAmount(" ..Subject..", " .._StartAmount.. ", " .._RefillAmount.. ")")
        return;
    end
    if not IsExisting(_Entity) then
        local Subject = (type(_Entity) ~= "string" and _Entity) or "'" .._Entity.. "'";
        API.Dbg("API.SetResourceAmount: Entity " ..Subject.. " does not exist!");
        return;
    end
    return BundleEntityHelperFunctions.Global:SetResourceAmount(_Entity, _StartAmount, _RefillAmount);
end
SetResourceAmount = API.SetResourceAmount;

---
-- Errechnet eine Position relativ im angegebenen Winkel und Position zur
-- Basisposition. Die Basis kann ein Entity oder eine Positionstabelle sein. 
--
-- <b>Alias:</b> GetRelativePos
-- 
-- @param _target          Basisposition
-- @param _distance        Entfernung
-- @param _angle           Winkel
-- @param _buildingRealPos Gebäudemitte statt Gebäudeeingang
-- @return table: Position
-- @within User-Space
--
function API.GetRelativePos(_target, _distance, _angle, _buildingRealPos)
    if not API.ValidatePosition(_target) then
        if not IsExisting(_target) then
            API.Dbg("API.GetRelativePos: Target is invalid!");
            return;
        end
    end
    return BundleEntityHelperFunctions:GetRelativePos(_target, _distance, _angle, _buildingRealPos);
end
GetRelativePos = API.GetRelativePos;

-- Setzt ein Entity oder ein Battalion an eine neue Position.
--
-- <b>Alias:</b> SetPosition
--
-- @param _Entity   Entity zum versetzen
-- @param _Position Neue Position
-- @within User-Space
--
function API.SetPosition(_Entity, _Position)
    if GUI then
        local Subject = (type(_Entity) ~= "string" and _Entity) or "'" .._Entity.. "'";
        local Position = _Position;
        if type(Position) == "table" then
            Position = "{X= " ..tostring(Position.X).. ", Y= " ..tostring(Position.Y).. "}";
        end
        API.Bridge("API.SetPosition(" ..Subject.. ", " ..Position.. ")")
        return;
    end
    if not IsExisting(_Entity) then
        local Subject = (type(_Entity) ~= "string" and _Entity) or "'" .._Entity.. "'";
        API.Dbg("API.SetPosition: Entity " ..Subject.. " does not exist!");
        return;
    end
    local Position = API.LocateEntity(_Position)
    if not API.ValidatePosition(Position) then
        API.Dbg("API.SetPosition: Position is invalid!");
        return;
    end
    return BundleEntityHelperFunctions.Global:SetPosition(_Entity, Position);
end
SetPosition = API.SetPosition;

---
-- Das Entity wird zum ziel bewegt und kann relativ um das Ziel in einem
-- Winkel bewegt werden. Das Entity wird das Ziel anschießend anschauen.
-- Die Funktion kann auch Schiffe bewegen, indem der letzte Parameter
-- true gesetzt wird.
--
-- <b>Alias:</b> MoveEx
--
-- @param _Entity       Zu bewegendes Entity
-- @param _Position     Ziel
-- @param _Distance     Entfernung zum Ziel
-- @param _Angle        Winkel
-- @param _moveAsEntity Blocking ignorieren
-- @within User-Space
--
function API.MoveToPosition(_Entity, _Position, _Distance, _Angle, _moveAsEntity)
    if GUI then
        API.Bridge("API.MoveToPosition(" ..GetID(_Entity).. ", " ..GetID(_Position).. ", " .._Distance.. ", " .._Angle.. ", " ..tostring(_moveAsEntity).. ")")
        return;
    end
    if not IsExisting(_Entity) then
        local Subject = (type(_Entity) ~= "string" and _Entity) or "'" .._Entity.. "'";
        API.Dbg("API.MoveToPosition: Entity " ..Subject.. " does not exist!");
        return;
    end
    if not IsExisting(_Position) then
        local Subject = (type(_Position) ~= "string" and _Position) or "'" .._Position.. "'";
        API.Dbg("API.MoveToPosition: Entity " ..Subject.. " does not exist!");
        return;
    end
    return BundleEntityHelperFunctions.Global:MoveToPosition(_Entity, _Position, _Distance, _Angle, _moveAsEntity)
end
MoveEx = API.MoveToPosition;

---
-- Platziert das Entity wird zum ziel gesetzt und das relativ zum Winkel um 
-- das Ziel.
--
-- <b>Alias:</b> SetPositionEx
--
-- @param _Entity       Zu bewegendes Entity
-- @param _Position     Ziel
-- @param _Distance     Entfernung zum Ziel
-- @param _Angle        Winkel
-- @within User-Space
--
function API.PlaceToPosition(_Entity, _Position, _Distance, _Angle)
    if GUI then
        API.Bridge("API.PlaceToPosition(" ..GetID(_Entity).. ", " ..GetID(_Position).. ", " .._Distance.. ", " .._Angle.. ")")
        return;
    end
    if not IsExisting(_Entity) then
        local Subject = (type(_Entity) ~= "string" and _Entity) or "'" .._Entity.. "'";
        API.Dbg("API.PlaceToPosition: Entity " ..Subject.. " does not exist!");
        return;
    end
    if not IsExisting(_Position) then
        local Subject = (type(_Position) ~= "string" and _Position) or "'" .._Position.. "'";
        API.Dbg("API.PlaceToPosition: Entity " ..Subject.. " does not exist!");
        return;
    end
    local Position = API.GetRelativePos(_Position, _Distance, _Angle, true);
    API.SetPosition(_Entity, Position);
end
SetPositionEx = API.PlaceToPosition;

---
-- Gibt dem Entity einen eindeutigen Skriptnamen und gibt ihn zurück.
-- Hat das Entity einen Namen, bleibt dieser unverändert und wird
-- zurückgegeben.
--
-- <b>Alias:</b> GiveEntityName
--
-- @param _EntityID Entity ID
-- @return string: Vergebener Name
-- @within User-Space
--
function API.GiveEntityName(_EntityID)
    if IsExisting(_name) then
        API.Dbg("API.GiveEntityName: Entity does not exist!");
        return;
    end
    if GUI then
        API.Bridge("API.GiveEntityName(" ..GetID(_EntityID).. ")")
        return;
    end
    return BundleEntityHelperFunctions.Global:GiveEntityName(_EntityID);
end
GiveEntityName = API.GiveEntityName;

---
-- Gibt den Skriptnamen des Entity zurück.
--
-- <b>Alias:</b> GetEntityName
--
-- @param _entity Gesuchtes Entity
-- @return string: Skriptname
-- @within User-Space
--
function API.GetEntityName(_entity)
    if not IsExisting(_entity) then
        local Subject = (type(_entity) ~= "string" and _entity) or "'" .._entity.. "'";
        API.Warn("API.GetEntityName: Entity " ..Subject.. " does not exist!");
        return nil;
    end
    return Logic.GetEntityName(GetID(_entity));
end
GetEntityName = API.GetEntityName;

---
-- Setzt den Skriptnamen des Entity.
--
-- <b>Alias:</b> SetEntityName
--
-- @param _entity Entity
-- @param _name   Skriptname
-- @return string: Skriptname
-- @within User-Space
--
function API.SetEntityName(_entity, _name)
    if GUI then
        API.Bridge("API.SetEntityName(" ..GetID(_EntityID).. ", '" .._name.. "')")
        return;
    end
    if IsExisting(_name) then
        API.Dbg("API.SetEntityName: Entity '" .._name.. "' already exists!");
        return;
    end
    return Logic.SetEntityName(GetID(_entity), _name);
end
SetEntityName = API.SetEntityName;

---
-- Setzt die Orientierung des Entity.
--
-- <b>Alias:</b> SetOrientation
--
-- @param _entity Gesuchtes Entity
-- @param _ori    Ausrichtung in Grad
-- @within User-Space
--
function API.SetOrientation(_entity, _ori)
    if GUI then
        API.Bridge("API.SetOrientation(" ..GetID(_entity).. ", " .._ori.. ")")
        return;
    end
    if not IsExisting(_entity) then
        local Subject = (type(_entity) ~= "string" and _entity) or "'" .._entity.. "'";
        API.Dbg("API.SetOrientation: Entity " ..Subject.. " does not exist!");
        return;
    end
    return Logic.SetOrientation(GetID(_entity), _ori);
end
SetOrientation = API.SetOrientation;

---
-- Gibt die Orientierung des Entity zurück.
--
-- <b>Alias:</b> GetOrientation
--
-- @param _entity Gesuchtes Entity
-- @return number: Orientierung in Grad
-- @within User-Space
--
function API.GetOrientation(_entity)
    if not IsExisting(_entity) then
        local Subject = (type(_entity) ~= "string" and _entity) or "'" .._entity.. "'";
        API.Warn("API.GetOrientation: Entity " ..Subject.. " does not exist!");
        return 0;
    end
    return Logic.GetEntityOrientation(GetID(_entity));
end
GetOrientation = API.GetOrientation;

---
-- Das Entity greift ein anderes Entity an, sofern möglich.
--
-- <b>Alias:</b> Attack
--
-- @param_Entity  Angreifendes Entity
-- @param _Target Angegriffenes Entity
-- @within User-Space
--
function API.EntityAttack(_Entity, _Target)
    if GUI then
        API.Bridge("API.EntityAttack(" ..GetID(_Entity).. ", " ..GetID(_Target).. ")")
        return;
    end
    if not IsExisting(_Entity) then
        local Subject = (type(_Entity) == "string" and "'" .._Entity.. "'") or _Entity;
        API.Dbg("API.EntityAttack: Entity " ..Subject.. " does not exist!");
        return;
    end
    if not IsExisting(_Target) then
        local Subject = (type(_Target) == "string" and "'" .._Target.. "'") or _Target;
        API.Dbg("API.EntityAttack: Target " ..Subject.. " does not exist!");
        return;
    end
    return BundleEntityHelperFunctions.Global:Attack(_Entity, _Target);
end
Attack = API.EntityAttack;

---
-- Ein Entity oder ein Battalion wird zu einer Position laufen und
-- alle gültigen Ziele auf dem Weg angreifen.
--
-- <b>Alias:</b> AttackMove
--
-- @param _Entity   Angreifendes Entity
-- @param _Position Skriptname, EntityID oder Positionstable
-- @within Application Space
-- @local
--
function API.EntityAttackMove(_Entity, _Position)
    if GUI then
        API.Dbg("API.EntityAttackMove: Cannot be used from local script!");
        return;
    end
    if not IsExisting(_Entity) then
        local Subject = (type(_Entity) == "string" and "'" .._Entity.. "'") or _Entity;
        API.Dbg("API.EntityAttackMove: Entity " ..Subject.. " does not exist!");
        return;
    end
    local Position = API.LocateEntity(_Position)
    if not API.ValidatePosition(Position) then
        API.Dbg("API.EntityAttackMove: Position is invalid!");
        return;
    end
    return BundleEntityHelperFunctions.Global:AttackMove(_Entity, Position);
end
AttackMove = API.EntityAttackMove;

---
-- Bewegt das Entity zur Zielposition.
--
-- <b>Alias:</b> Move
--
-- @param _Entity   Bewegendes Entity
-- @param _Position Skriptname, EntityID oder Positionstable
-- @within Application Space
-- @local
--
function API.EntityMove(_Entity, _Position)
    if GUI then
        API.Dbg("API.EntityMove: Cannot be used from local script!");
        return;
    end
    if not IsExisting(_Entity) then
        local Subject = (type(_Entity) == "string" and "'" .._Entity.. "'") or _Entity;
        API.Dbg("API.EntityMove: Entity " ..Subject.. " does not exist!");
        return;
    end
    local Position = API.LocateEntity(_Position)
    if not API.ValidatePosition(Position) then
        API.Dbg("API.EntityMove: Position is invalid!");
        return;
    end
    return BundleEntityHelperFunctions.Global:Move(_Entity, Position);
end
Move = API.EntityMove;


---
-- Gibt die Battalion-ID (Entity-ID des Leaders) eines Soldaten zurück.
--
-- <b>Alias:</b> GetLeaderBySoldier
--
-- @param _soldier Soldier
-- @return number: ID des Battalion
-- @within User-Space
--
function API.GetLeaderBySoldier(_soldier)
    if not IsExisting(_soldier) then
        local Subject = (type(_soldier) == "string" and "'" .._soldier.. "'") or _Entity;
        API.Dbg("API.GetLeaderBySoldier: Entity " ..Subject.. " does not exist!");
        return;
    end
    return Logic.SoldierGetLeaderEntityID(GetID(_soldier))
end
GetLeaderBySoldier = API.GetLeaderBySoldier;

---
-- Ermittelt den Helden eines Spielers, ders dem Basis-Entity am nächsten ist.
--
-- <b>Alias:</b> GetClosestKnight
-- 
-- @param _eID      Basis-Entity
-- @param _playerID Besitzer der Helden
-- @return number: Nächstes Entity
-- @within User-Space
--
function API.GetNearestKnight(_eID,_playerID)
    local Knights = {};
    Logic.GetKnights(_playerID, Knights);
    return API.GetNearestEntity(_eID, Knights);
end
GetClosestKnight = API.GetNearestKnight;

---
-- Ermittelt aus einer liste von Entity-IDs das Entity, dass dem Basis-Entity
-- am nächsten ist.
--
-- <b>Alias:</b> GetClosestEntity
-- 
-- @param _eID      Basis-Entity
-- @param _entities Liste von Entities
-- @return number: Nächstes Entity
-- @within User-Space
--
function API.GetNearestEntity(_eID, _entities)
    if not IsExisting(_eID) then
        API.Dbg("API.GetNearestEntity: Base entity does not exist!");
        return;
    end
    if #_entities == 0 then
        API.Dbg("API.GetNearestEntity: The target list is empty!");
        return;
    end
    for i= 1, #_entities, 1 do
        if not IsExisting(_entities[i]) then
            API.Dbg("API.GetNearestEntity: At least one target entity is dead!");
            return;
        end
    end
    return BundleEntityHelperFunctions:GetNearestEntity(_eID,_entities);
end
GetClosestEntity = API.GetNearestEntity;

-- -------------------------------------------------------------------------- --
-- Application-Space                                                          --
-- -------------------------------------------------------------------------- --

BundleEntityHelperFunctions = {
    Global = {
        Data = {
            RefillAmounts = {},
        }
    },
    Local = {
        Data = {}
    },
}

-- Global Script ---------------------------------------------------------------

---
-- Initalisiert das Bundle im globalen Skript.
--
-- @within Application-Space
-- @local
--
function BundleEntityHelperFunctions.Global:Install()
    BundleEntityHelperFunctions.Global:OverwriteGeologistRefill();
end

---
-- Überschreibt das Auffüll-Callback, wenn es vorhanden ist, um Auffüllmengen
-- auch während des Spiels setzen zu können.
--
-- @within Application-Space
-- @local
--
function BundleEntityHelperFunctions.Global:OverwriteGeologistRefill()
    if Framework.GetGameExtraNo() >= 1 then
        GameCallback_OnGeologistRefill_Orig_QSBPlusComforts1 = GameCallback_OnGeologistRefill
        GameCallback_OnGeologistRefill = function( _PlayerID, _TargetID, _GeologistID )
            GameCallback_OnGeologistRefill_Orig_QSBPlusComforts1( _PlayerID, _TargetID, _GeologistID )
            if BundleEntityHelperFunctions.Global.Data.RefillAmounts[_TargetID] then
                local RefillAmount = BundleEntityHelperFunctions.Global.Data.RefillAmounts[_TargetID];
                local RefillRandom = RefillAmount + math.random(1, math.floor((RefillAmount * 0.2) + 0.5));
                Logic.SetResourceDoodadGoodAmount(_TargetID, RefillRandom);
            end
        end
    end
end

-- Setzt die Menge an Rohstoffen und die durchschnittliche Auffüllmenge
-- in einer Mine.
--
-- @param _Entity       Skriptname, EntityID der Mine
-- @param _StartAmount  Menge an Rohstoffen
-- @param _RefillAmount Minimale Nachfüllmenge (> 0)
-- @return boolean: Operation erfolgreich
-- @within Application-Space
-- @local
--
function BundleEntityHelperFunctions.Global:SetResourceAmount(_Entity, _StartAmount, _RefillAmount)
    assert(type(_StartAmount) == "number");
    assert(type(_RefillAmount) == "number");
    
    local EntityID = GetID(_Entity);
    if not IsExisting(EntityID) or Logic.GetResourceDoodadGoodType(EntityID) == 0 then
        API.Dbg("SetResourceAmount: Resource entity is invalid!");
        return false;
    end
    if Logic.GetResourceDoodadGoodAmount(EntityID) == 0 then
        EntityID = ReplaceEntity(EntityID, Logic.GetEntityType(EntityID));
    end
    Logic.SetResourceDoodadGoodAmount(EntityID, _StartAmount);
    if _RefillAmount then
        self.Data.RefillAmounts[EntityID] = _RefillAmount;
    end
    return true;
end

-- Setzt ein Entity oder ein Battalion an eine neue Position.
--
-- @param _Entity   Entity zum versetzen
-- @param _Position Neue Position
-- @within Application-Space
-- @local
--
function BundleEntityHelperFunctions.Global:SetPosition(_Entity,_Position)
    if not IsExisting(_Entity)then
        return
    end
    local EntityID = GetEntityId(_Entity);
    Logic.DEBUG_SetSettlerPosition(EntityID, _Position.X, _Position.Y);
    if Logic.IsLeader(EntityID) == 1 then
        local soldiers = {Logic.GetSoldiersAttachedToLeader(EntityID)};
        if soldiers[1] > 0 then
            for i=1,#soldiers do
                Logic.DEBUG_SetSettlerPosition(soldiers[i], _Position.X, _Position.Y);
            end
        end
    end
end

---
-- Das Entity wird zum ziel bewegt und kann relativ um das Ziel in einem
-- Winkel bewegt werden. Das Entity wird das Ziel anschießend anschauen.
-- Die Funktion kann auch Schiffe bewegen, indem der letzte Parameter
-- true gesetzt wird.
--
-- @param _Entity       Zu bewegendes Entity
-- @param _Position     Ziel
-- @param _Distance     Entfernung zum Ziel
-- @param _Angle        Winkel
-- @param _moveAsEntity Blocking ignorieren
-- @within Application-Space
-- @local
--
function BundleEntityHelperFunctions.Global:MoveToPosition(_Entity, _Position, _Distance, _Angle, _moveAsEntity)
    if not IsExisting(_Entity)then
        return
    end
    if not _Distance then
        _Distance = 0;
    end
    local eID = GetID(_Entity);
    local tID = GetID(_Position);
    local pos = GetRelativePos(_Position, _Distance);
    if type(_Angle) == "number" then
        pos = BundleEntityHelperFunctions:GetRelativePos(_Position, _Distance, _Angle);
    end

    if _moveAsEntity then
        Logic.MoveEntity(eID, pos.X, pos.Y);
    else
        Logic.MoveSettler(eID, pos.X, pos.Y);
    end
    
    StartSimpleJobEx( function(_EntityID, _TargetID)
        if not Logic.IsEntityMoving(_EntityID) then
            LookAt(_EntityID, _TargetID);
            return true;
        end
    end, eID, tID);
end

---
-- Gibt dem Entity einen eindeutigen Skriptnamen und gibt ihn zurück.
-- Hat das Entity einen Namen, bleibt dieser unverändert und wird
-- zurückgegeben.
--
-- @param _EntityID Entity ID
-- @return string: Vergebener Name
-- @within Application Space
-- @local
--
function BundleEntityHelperFunctions.Global:GiveEntityName(_EntityID)
    if type(_EntityID) == "string" then
        return _EntityID;
    else
        assert(type(_EntityID) == "number");
        local name = Logic.GetEntityName(_EntityID);
        if (type(name) ~= "string" or name == "" ) then
            QSB.GiveEntityNameCounter = (QSB.GiveEntityNameCounter or 0)+ 1;
            name = "GiveEntityName_Entity_"..QSB.GiveEntityNameCounter;
            Logic.SetEntityName(_EntityID, name);
        end
        return name;
    end
end

---
-- Das Entity greift ein anderes Entity an, sofern möglich.
--
-- @param_Entity  Angreifendes Entity
-- @param _Target Angegriffenes Entity
-- @within Application Space
-- @local
--
function BundleEntityHelperFunctions.Global:Attack(_Entity, _Target)
    local EntityID = GetID(_Entity);
    local TargetID = GetID(_Target);
    Logic.GroupAttack(EntityID, TargetID);
end

---
-- Ein Entity oder ein Battalion wird zu einer Position laufen und
-- alle gültigen Ziele auf dem Weg angreifen.
--
-- @param _Entity   Angreifendes Entity
-- @param _Position Positionstable
-- @within Application Space
-- @local
--
function BundleEntityHelperFunctions.Global:AttackMove(_Entity, _Position)
    local EntityID = GetID(_Entity);
    Logic.GroupAttackMove(EntityID, _Position.X, _Position.Y);
end

---
-- Bewegt das Entity zur Zielposition.
--
-- @param _Entity   Bewegendes Entity
-- @param _Position Positionstable
-- @within Application Space
-- @local
--
function BundleEntityHelperFunctions.Global:Move(_Entity, _Position)
    local EntityID = GetID(_Entity);
    Logic.MoveSettler(EntityID, _Position.X, _Position.Y);
end

-- Local Script ----------------------------------------------------------------

---
-- Initalisiert das Bundle im lokalen Skript.
--
-- @within Application-Space
-- @local
--
function BundleEntityHelperFunctions.Local:Install()

end



-- Shared ----------------------------------------------------------------------

---
-- Ermittelt alle Entities in den Kategorien auf den Territorien für die
-- Liste von Parteien und gibt sie als Liste zurück.
-- 
-- @param _player       PlayerID [0-8] oder Table mit PlayerIDs
-- @param _category     Kategorien oder Table mit Kategorien
-- @param _territory    Zielterritorium oder Table mit Territorien
-- @return table: Liste mit Entities
-- @within Application-Space
-- @local
--
function BundleEntityHelperFunctions:GetEntitiesOfCategoriesInTerritories(_player, _category, _territory)
    -- Tables erzwingen
    local p = (type(_player) == "table" and _player) or {_player};
    local c = (type(_category) == "table" and _category) or {_category};
    local t = (type(_territory) == "table" and _territory) or {_territory};

    local PlayerEntities = {};
    for i=1, #p, 1 do
        for j=1, #c, 1 do
            for k=1, #t, 1 do
                local Units = API.GetEntitiesOfCategoryInTerritory(p[i], c[j], t[k]);
                PlayerEntities = Array_Append(PlayerEntities, Units);
            end
        end
    end
    return PlayerEntities;
end

---
-- Gibt alle Entities zurück, deren Name mit dem Prefix beginnt. 
-- 
-- @param _Prefix Präfix des Skriptnamen
-- @return table: Liste mit Entities
-- @within Application-Space
-- @local
--
function BundleEntityHelperFunctions:GetEntitiesByPrefix(_Prefix)
    local list = {};
    local i = 1;
    local bFound = true;
    while bFound do
        local entity = GetID(_Prefix ..i);
        if entity ~= 0 then
            table.insert(list, entity);
        else
            bFound = false;
        end
        i = i + 1;
    end
    return list;
end

---
-- Errechnet eine Position relativ im angegebenen Winkel und Position zur
-- Basisposition. Die Basis kann ein Entity oder eine Positionstabelle sein. 
-- 
-- @param _target          Basisposition
-- @param _distance        Entfernung
-- @param _angle           Winkel
-- @param _buildingRealPos Gebäudemitte statt Gebäudeeingang
-- @return table: Position
-- @within Application-Space
-- @local
--
function BundleEntityHelperFunctions:GetRelativePos(_target,_distance,_angle,_buildingRealPos)
    if not type(_target) == "table" and not IsExisting(_target)then
        return
    end
    if _angle == nil then
        _angle = 0;
    end

    local pos1;
    if type(_target) == "table" then
        local pos = _target;
        local ori = 0+_angle;
        pos1 = { X= pos.X+_distance * math.cos(math.rad(ori)),
                 Y= pos.Y+_distance * math.sin(math.rad(ori))};
    else
        local eID = GetID(_target);
        local pos = GetPosition(eID);
        local ori = Logic.GetEntityOrientation(eID)+_angle;
        if Logic.IsBuilding(eID) == 1 and not _buildingRealPos then
            x, y = Logic.GetBuildingApproachPosition(eID);
            pos = {X= x, Y= y};
            ori = ori -90;
        end
        pos1 = { X= pos.X+_distance * math.cos(math.rad(ori)),
                 Y= pos.Y+_distance * math.sin(math.rad(ori))};
    end
    return pos1;
end

---
-- Ermittelt aus einer liste von Entity-IDs das Entity, dass dem Basis-Entity
-- am nächsten ist.
-- 
-- @param _eID      Basis-Entity
-- @param _entities Liste von Entities
-- @return number: Nächstes Entity
-- @within Application-Space
-- @local
--
function BundleEntityHelperFunctions:GetNearestEntity(_eID,_entities)
    local bestDistance = Logic.WorldGetSize();
    local best = nil;
    for i=1,#_entities do
        local distanceBetween = Logic.GetDistanceBetweenEntities(_entities[i], _eID);
        if distanceBetween < bestDistance and _entities[i] ~= _eID then
            bestDistance = distanceBetween;
            best = _entities[i];
        end
    end
    return best;
end

-- -------------------------------------------------------------------------- --

Core:RegisterBundle("BundleEntityHelperFunctions");

-- -------------------------------------------------------------------------- --
-- ########################################################################## --
-- #  Symfonia BundleGameHelperFunctions                                    # --
-- ########################################################################## --
-- -------------------------------------------------------------------------- --

---
-- 
--
-- @module BundleGameHelperFunctions
-- @set sort=true
--

API = API or {};
QSB = QSB or {};

-- -------------------------------------------------------------------------- --
-- User-Space                                                                 --
-- -------------------------------------------------------------------------- --

---
-- Entfernt ein Territorium für den angegebenen Spieler aus der Liste
-- der entdeckten Territorien.
--
-- <b>Alias:</b> UndiscoverTerritory
--
-- @param _PlayerID    Spieler-ID
-- @param _TerritoryID Territorium-ID
-- @within User-Space
--
function API.UndiscoverTerritory(_PlayerID, _TerritoryID)
    if GUI then
        API.Bridge("API.UndiscoverTerritory(" .._PlayerID.. ", ".._TerritoryID.. ")")
        return;
    end
    return BundleGameHelperFunctions.Global:UndiscoverTerritory(_PlayerID, _TerritoryID);
end
UndiscoverTerritory = API.UndiscoverTerritory;

---
-- Entfernt alle Territorien einer Partei aus der Liste der entdeckten
-- Territorien. Als Nebeneffekt gild die Partei als unentdeckt.
--
-- <b>Alias:</b> UndiscoverTerritories
--
-- @param _PlayerID       Spieler-ID
-- @param _TargetPlayerID Zielpartei
-- @within User-Space
--
function API.UndiscoverTerritories(_PlayerID, _TargetPlayerID)
    if GUI then
        API.Bridge("API.UndiscoverTerritories(" .._PlayerID.. ", ".._TargetPlayerID.. ")")
        return;
    end
    return BundleGameHelperFunctions.Global:UndiscoverTerritories(_PlayerID, _TargetPlayerID);
end
UndiscoverTerritories = API.UndiscoverTerritories;

---
-- Setzt den Befriedigungsstatus eines Bedürfnisses für alle Gebäude
-- des angegebenen Spielers. Der Befriedigungsstatus ist eine Zahl
-- zwischen 0.0 und 1.0.
--
-- <b>Alias:</b> SetNeedSatisfactionLevel
--
-- @param _Need     Bedürfnis
-- @param _State    Erfüllung des Bedürfnisses
-- @param _PlayerID Partei oder nil für alle
-- @within User-Space
--
function API.SetNeedSatisfaction(_Need, _State, _PlayerID)
    if GUI then
        API.Bridge("API.SetNeedSatisfaction(" .._Need.. ", " .._State.. ", " .._PlayerID.. ")")
        return;
    end
    return BundleGameHelperFunctions.Global:SetNeedSatisfactionLevel(_Need, _State, _PlayerID);
end
SetNeedSatisfactionLevel = API.SetNeedSatisfaction;

---
-- Entsperrt einen gesperrten Titel für den Spieler, sofern dieser
-- Titel gesperrt wurde.
--
-- <b>Alias:</b> UnlockTitleForPlayer
--
-- @param _PlayerID    Zielpartei
-- @param _KnightTitle Titel zum Entsperren
-- @within User-Space
--
function API.UnlockTitleForPlayer(_PlayerID, _KnightTitle)
    if GUI then
        API.Bridge("API.UnlockTitleForPlayer(" .._PlayerID.. ", " .._KnightTitle.. ")")
        return;
    end
    return BundleGameHelperFunctions.Global:UnlockTitleForPlayer(_PlayerID, _KnightTitle);
end
UnlockTitleForPlayer = API.UnlockTitleForPlayer;

---
-- Fokusiert die Kamera auf dem Primärritter des Spielers.
--
-- <b>Alias:</b> SetCameraToPlayerKnight
--
-- @param _Player     Partei
-- @param _Rotation   Kamerawinkel
-- @param _ZoomFactor Zoomfaktor
-- @within User-Space
--
function API.FocusCameraOnKnight(_Player, _Rotation, _ZoomFactor)
    if not GUI then
        API.Bridge("API.SetCameraToPlayerKnight(" .._Player.. ", " .._Rotation.. ", " .._ZoomFactor.. ")")
        return;
    end
    return BundleGameHelperFunctions.Local:SetCameraToPlayerKnight(_Player, _Rotation, _ZoomFactor);
end
SetCameraToPlayerKnight = API.FocusCameraOnKnight;

---
-- Fokusiert die Kamera auf dem Entity.
--
-- <b>Alias:</b> SetCameraToEntity
--
-- @param _Entity     Entity
-- @param _Rotation   Kamerawinkel
-- @param _ZoomFactor Zoomfaktor
-- @within User-Space
--
function API.FocusCameraOnEntity(_Entity, _Rotation, _ZoomFactor)
    if not GUI then
        API.Bridge("API.FocusCameraOnEntity(" .._Entity.. ", " .._Rotation.. ", " .._ZoomFactor.. ")")
        return;
    end
    if not IsExisting(_Entity) then
        local Subject = (type(_Entity) == "string" and _Entity) or "'" .._Entity.. "'";
        API.Dbg("API.FocusCameraOnEntity: Entity " ..Subject.. " does not exist!");
        return;
    end
    return BundleGameHelperFunctions.Local:SetCameraToEntity(_Entity, _Rotation, _ZoomFactor);
end
SetCameraToEntity = API.FocusCameraOnEntity;

-- -------------------------------------------------------------------------- --
-- Application-Space                                                          --
-- -------------------------------------------------------------------------- --

BundleGameHelperFunctions = {
    Global = {
        Data = {}
    },
    Local = {
        Data = {}
    },
}

-- Global Script ---------------------------------------------------------------

---
-- Initalisiert das Bundle im globalen Skript.
--
-- @within Application-Space
-- @local
--
function BundleGameHelperFunctions.Global:Install()
    
end

---
-- Entfernt ein Territorium für den angegebenen Spieler aus der Liste
-- der entdeckten Territorien.
--
-- @param _PlayerID    Spieler-ID
-- @param _TerritoryID Territorium-ID
-- @within Application-Space
-- @local
--
function BundleGameHelperFunctions.Global:UndiscoverTerritory(_PlayerID, _TerritoryID)
    if DiscoveredTerritories[_PlayerID] == nil then
        DiscoveredTerritories[_PlayerID] = {};
    end
    for i=1, #DiscoveredTerritories[_PlayerID], 1 do
        if DiscoveredTerritories[_PlayerID][i] == _TerritoryID then
            table.remove(DiscoveredTerritories[_PlayerID], i);
            break;
        end
    end
end

---
-- Entfernt alle Territorien einer Partei aus der Liste der entdeckten
-- Territorien. Als Nebeneffekt gild die Partei als unentdeckt-
--
-- @param _PlayerID       Spieler-ID
-- @param _TargetPlayerID Zielpartei
-- @within Application-Space
-- @local
--
function BundleGameHelperFunctions.Global:UndiscoverTerritories(_PlayerID, _TargetPlayerID)
    if DiscoveredTerritories[_PlayerID] == nil then
        DiscoveredTerritories[_PlayerID] = {};
    end
    local Discovered = {};
    for k, v in pairs(DiscoveredTerritories[_PlayerID]) do
        local OwnerPlayerID = Logic.GetTerritoryPlayerID(v);
        if OwnerPlayerID ~= _TargetPlayerID then
            table.insert(Discovered, v);
            break;
        end
    end
    DiscoveredTerritories[_PlayerID][i] = Discovered;
end

---
-- Setzt den Befriedigungsstatus eines Bedürfnisses für alle Gebäude
-- des angegebenen Spielers. Der Befriedigungsstatus ist eine Zahl
-- zwischen 0.0 und 1.0.
--
-- @param _Need     Bedürfnis
-- @param _State    Erfüllung des Bedürfnisses
-- @param _PlayerID Partei oder nil für alle
-- @within Application-Space
-- @local
--
function BundleGameHelperFunctions.Global:SetNeedSatisfactionLevel(_Need, _State, _PlayerID)
    if not _PlayerID then
        for i=1, 8, 1 do
            Module_Comforts.Global.SetNeedSatisfactionLevel(_Need, _State, i);
        end
    else
        local City = {Logic.GetPlayerEntitiesInCategory(_PlayerID, EntityCategories.CityBuilding)};
        if _Need == Needs.Nutrition or _Need == Needs.Medicine then
            local Rim = {Logic.GetPlayerEntitiesInCategory(_PlayerID, EntityCategories.OuterRimBuilding)};
            City = Array_Append(City, Rim);
        end
        for j=1, #City, 1 do
            if Logic.IsNeedActive(City[j], _Need) then
                Logic.SetNeedState(City[j], _Need, _State);
            end
        end
    end
end

---
-- Entsperrt einen gesperrten Titel für den Spieler, sofern dieser
-- Titel gesperrt wurde.
--
-- @param _PlayerID    Zielpartei
-- @param _KnightTitle Titel zum Entsperren
-- @within Application-Space
-- @local
--
function BundleGameHelperFunctions.Global:UnlockTitleForPlayer(_PlayerID, _KnightTitle)
    if LockedKnightTitles[_PlayerID] == _KnightTitle
    then
        LockedKnightTitles[_PlayerID] = nil;
        for KnightTitle= _KnightTitle, #NeedsAndRightsByKnightTitle
        do
            local TechnologyTable = NeedsAndRightsByKnightTitle[KnightTitle][4];
            if TechnologyTable ~= nil
            then
                for i=1, #TechnologyTable
                do
                    local TechnologyType = TechnologyTable[i];
                    Logic.TechnologySetState(_PlayerID, TechnologyType, TechnologyStates.Unlocked);
                end
            end
        end
    end
end

-- Local Script ----------------------------------------------------------------

---
-- Initalisiert das Bundle im lokalen Skript.
--
-- @within Application-Space
-- @local
--
function BundleGameHelperFunctions.Local:Install()

end

---
-- Fokusiert die Kamera auf dem Primärritter des Spielers.
--
-- @param _Player     Partei
-- @param _Rotation   Kamerawinkel
-- @param _ZoomFactor Zoomfaktor
-- @within Application-Space
-- @local
--
function BundleGameHelperFunctions.Local:SetCameraToPlayerKnight(_Player, _Rotation, _ZoomFactor)
    BundleGameHelperFunctions.Local:SetCameraToEntity(Logic.GetKnightID(_Player), _Rotation, _ZoomFactor);
end

---
-- Fokusiert die Kamera auf dem Entity.
--
-- @param _Entity     Entity
-- @param _Rotation   Kamerawinkel
-- @param _ZoomFactor Zoomfaktor
-- @within Application-Space
-- @local
--
function BundleGameHelperFunctions.Local:SetCameraToEntity(_Entity, _Rotation, _ZoomFactor)
    local pos = GetPosition(_Entity);
    local rotation = (_Rotation or -45);
    local zoomFactor = (_ZoomFactor or 0.5);
    Camera.RTS_SetLookAtPosition(pos.X, pos.Y);
    Camera.RTS_SetRotationAngle(rotation);
    Camera.RTS_SetZoomFactor(zoomFactor);
end

-- -------------------------------------------------------------------------- --

Core:RegisterBundle("BundleGameHelperFunctions");

-- -------------------------------------------------------------------------- --
-- ########################################################################## --
-- #  Symfonia BundleDialogWindows                                          # --
-- ########################################################################## --
-- -------------------------------------------------------------------------- --

---
-- Mit diesem Bundle kommen einige Funktionen für das lokale Skript hinzu, die
-- es ermöglichen verschiedene Dialoge oder ein Textfenster anzuzeigen.
--
-- @module BundleDialogWindows
-- @set sort=true
--

API = API or {};
QSB = QSB or {};

-- -------------------------------------------------------------------------- --
-- User-Space                                                                 --
-- -------------------------------------------------------------------------- --

---
-- Öffnet einen Info-Dialog. Sollte bereits ein Dialog zu sehen sein, wird
-- der Dialog der Dialogwarteschlange hinzugefügt.
--
-- @param _Title  Titel des Dialog
-- @param _Text   Text des Dialog
-- @param _Action Callback-Funktion
-- @within User-Space
--
function API.OpenDialog(_Title, _Text, _Action)
    if not GUI then
        API.Dbg("API.OpenDialog: Can only be used in the local script!");
        return;
    end
    
    local lang = (Network.GetDesiredLanguage() == "de" and "de") or "en";
    if type(_Title) == "table" then
       _Title = _Title[lang];
    end
    if type(_Text) == "table" then
       _Text = _Text[lang];
    end
    return BundleDialogWindows.Local:OpenDialog(_Title, _Text, _Action);
end

---
-- Öffnet einen Ja-Nein-Dialog. Sollte bereits ein Dialog zu sehen sein, wird
-- der Dialog der Dialogwarteschlange hinzugefügt.
--
-- @param _Title    Titel des Dialog
-- @param _Text     Text des Dialog
-- @param _Action   Callback-Funktion
-- @param _OkCancel Okay/Abbrechen statt Ja/Nein
-- @within User-Space
--
function API.OpenRequesterDialog(_Title, _Text, _Action, _OkCancel)
    if not GUI then
        API.Dbg("API.OpenRequesterDialog: Can only be used in the local script!");
        return;
    end
    
    local lang = (Network.GetDesiredLanguage() == "de" and "de") or "en";
    if type(_Title) == "table" then
       _Title = _Title[lang];
    end
    if type(_Text) == "table" then
       _Text = _Text[lang];
    end
    return BundleDialogWindows.Local:OpenRequesterDialog(_Title, _Text, _Action, _OkCancel);
end

---
-- Öffnet einen Auswahldialog. Sollte bereits ein Dialog zu sehen sein, wird
-- der Dialog der Dialogwarteschlange hinzugefügt.
--
-- @param _Title  Titel des Dialog
-- @param _Text   Text des Dialog
-- @param _Action Callback-Funktion
-- @param _List   Liste der Optionen
-- @within User-Space
--
function API.OpenSelectionDialog(_Title, _Text, _Action, _List)
    if not GUI then
        API.Dbg("API.OpenSelectionDialog: Can only be used in the local script!");
        return;
    end
    
    if type(_Text) == "table" then
        _Text.de = _Text.de .. "{cr}";
        _Text.en = _Text.en .. "{cr}";
    else
        _Text = _Text .. "{cr}";
    end
    return BundleDialogWindows.Local:OpenSelectionDialog(_Title, _Text, _Action, _List);
end

-- -------------------------------------------------------------------------- --
-- Application-Space                                                          --
-- -------------------------------------------------------------------------- --

BundleDialogWindows = {
    Global = {
        Data = {}
    },
    Local = {
        Data = {
            Requester = {
                ActionFunction = nil,
                ActionRequester = nil,
                Next = nil,
                Queue = {},
            },
        },
        TextWindow = {
            Data = {
                Shown       = false,
                Caption     = "",
                Text        = "",
                ButtonText  = "",
                Picture     = nil,
                Action      = nil,
                Callback    = function() end,
            },
        },
    },
}

-- Global Script ---------------------------------------------------------------

---
-- Initalisiert das Bundle im globalen Skript.
--
-- @within Application-Space
-- @local
--
function BundleDialogWindows.Global:Install()
    TextWindow = BundleDialogWindows.Local.TextWindow;
end



-- Local Script ----------------------------------------------------------------

---
-- Initalisiert das Bundle im lokalen Skript.
--
-- @within Application-Space
-- @local
--
function BundleDialogWindows.Local:Install()
    self:DialogOverwriteOriginal();
end

---
-- Führt das Callback eines Info-Fensters oder eines Selektionsfensters aus.
--
-- @within Application-Space
-- @local
--
function BundleDialogWindows.Local:Callback()
    if self.Data.Requester.ActionFunction then
        self.Data.Requester.ActionFunction(CustomGame.Knight + 1);
    end
    self:OnDialogClosed();
end

---
-- Führt das Callback eines Ja-Nein-Dialogs aus.
--
-- @param _yes Gegebene Antwort
-- @within Application-Space
-- @local
--
function BundleDialogWindows.Local:CallbackRequester(_yes)
    if self.Data.Requester.ActionRequester then
        self.Data.Requester.ActionRequester(_yes);
    end
    self:OnDialogClosed();
end

---
-- Läd den nächsten Dialog aus der Warteschlange und stellt die Speicher-Hotkeys
-- wieder her.
--
-- @within Application-Space
-- @local
--
function BundleDialogWindows.Local:OnDialogClosed()
    self:DialogQueueStartNext();
    self:RestoreSaveGame();
end

---
-- Startet den nächsten Dialog in der Warteschlange, sofern möglich.
--
-- @within Application-Space
-- @local
--
function BundleDialogWindows.Local:DialogQueueStartNext()
    self.Data.Requester.Next = table.remove(self.Data.Requester.Queue, 1);

    DialogQueueStartNext_HiResControl = function()
        local Entry = self.Data.Requester.Next;
        if Entry then
            local Methode = Entry[1];
            self.Data[Methode]( unpack(Entry[2]) );
            self.Data.Requester.Next = nil;
        end
        return true;
    end
    StartSimpleHiResJob("DialogQueueStartNext_HiResControl");
end

---
-- Fügt der Dialogwarteschlange einen neuen Dialog hinten an.
--
-- @param _Methode Dialogfunktion als String
-- @param _Args    Argumente als Table
-- @within Application-Space
-- @local
--
function BundleDialogWindows.Local:DialogQueuePush(_Methode, _Args)
    local Entry = {_Methode, _Args};
    table.insert(self.Data.Requester.Queue, Entry);
end

---
-- Öffnet einen Info-Dialog. Sollte bereits ein Dialog zu sehen sein, wird
-- der Dialog der Dialogwarteschlange hinzugefügt.
--
-- @param _Title  Titel des Dialog
-- @param _Text   Text des Dialog
-- @param _Action Callback-Funktion
-- @within Application-Space
-- @local
--
function BundleDialogWindows.Local:OpenDialog(_Title, _Text, _Action)
    if XGUIEng.IsWidgetShown(RequesterDialog) == 0 then
        assert(type(_Title) == "string");
        assert(type(_Text) == "string");
        
        _Title = "{center}" .. _Title;
        if string.len(_Text) < 35 then
            _Text = _Text .. "{cr}";
        end

        g_MapAndHeroPreview.SelectKnight = function()
        end

        XGUIEng.ShowAllSubWidgets("/InGame/Dialog/BG",1);
        XGUIEng.ShowWidget("/InGame/Dialog/Backdrop",0);
        XGUIEng.ShowWidget(RequesterDialog,1);
        XGUIEng.ShowWidget(RequesterDialog_Yes,0);
        XGUIEng.ShowWidget(RequesterDialog_No,0);
        XGUIEng.ShowWidget(RequesterDialog_Ok,1);

        if type(_Action) == "function" then
            self.Data.Requester.ActionFunction = _Action;
            local Action = "XGUIEng.ShowWidget(RequesterDialog, 0)";
            Action = Action .. "; XGUIEng.PopPage()";
            Action = Action .. "; BundleDialogWindows.Local.Callback(BundleDialogWindows.Local)";
            XGUIEng.SetActionFunction(RequesterDialog_Ok, Action);
        else
            self.Data.Requester.ActionFunction = nil;
            local Action = "XGUIEng.ShowWidget(RequesterDialog, 0)";
            Action = Action .. "; XGUIEng.PopPage()";
            Action = Action .. "; BundleDialogWindows.Local.Callback(BundleDialogWindows.Local)";
            XGUIEng.SetActionFunction(RequesterDialog_Ok, Action);
        end

        XGUIEng.SetText(RequesterDialog_Message, "{center}" .. _Text);
        XGUIEng.SetText(RequesterDialog_Title, _Title);
        XGUIEng.SetText(RequesterDialog_Title.."White", _Title);
        XGUIEng.PushPage(RequesterDialog,false);

        XGUIEng.ShowWidget("/InGame/InGame/MainMenu/Container/QuickSave", 0);
        XGUIEng.ShowWidget("/InGame/InGame/MainMenu/Container/SaveGame", 0);
        if not KeyBindings_SaveGame_Orig_QSB_Windows then
            KeyBindings_SaveGame_Orig_QSB_Windows = KeyBindings_SaveGame;
            KeyBindings_SaveGame = function() end;
        end
    else
        self:DialogQueuePush("OpenDialog", {_Title, _Text, _Action});
    end
end

---
-- Öffnet einen Ja-Nein-Dialog. Sollte bereits ein Dialog zu sehen sein, wird
-- der Dialog der Dialogwarteschlange hinzugefügt.
--
-- @param _Title    Titel des Dialog
-- @param _Text     Text des Dialog
-- @param _Action   Callback-Funktion
-- @param _OkCancel Okay/Abbrechen statt Ja/Nein
-- @within Application-Space
-- @local
--
function BundleDialogWindows.Local:OpenRequesterDialog(_Title, _Text, _Action, _OkCancel)
    if XGUIEng.IsWidgetShown(RequesterDialog) == 0 then
        assert(type(_Title) == "string");
        assert(type(_Text) == "string");
        _Title = "{center}" .. _Title;

        self.OpenDialog(_Title, _Text, _Action);
        XGUIEng.ShowWidget(RequesterDialog_Yes,1);
        XGUIEng.ShowWidget(RequesterDialog_No,1);
        XGUIEng.ShowWidget(RequesterDialog_Ok,0);

        if _OkCancel ~= nil then
            XGUIEng.SetText(RequesterDialog_Yes, XGUIEng.GetStringTableText("UI_Texts/Ok_center"));
            XGUIEng.SetText(RequesterDialog_No, XGUIEng.GetStringTableText("UI_Texts/Cancel_center"));
        else
            XGUIEng.SetText(RequesterDialog_Yes, XGUIEng.GetStringTableText("UI_Texts/Yes_center"));
            XGUIEng.SetText(RequesterDialog_No, XGUIEng.GetStringTableText("UI_Texts/No_center"));
        end

        self.Data.Requester.ActionRequester = nil;
        if _Action then
            assert(type(_Action) == "function");
            self.Data.Requester.ActionRequester = _Action;
        end
        local Action = "XGUIEng.ShowWidget(RequesterDialog, 0)";
        Action = Action .. "; XGUIEng.PopPage()";
        Action = Action .. "; BundleDialogWindows.Local.CallbackRequester(BundleDialogWindows.Local, true)";
        XGUIEng.SetActionFunction(RequesterDialog_Yes, Action);
        local Action = "XGUIEng.ShowWidget(RequesterDialog, 0)";
        Action = Action .. "; XGUIEng.PopPage()";
        Action = Action .. "; BundleDialogWindows.Local.CallbackRequester(BundleDialogWindows.Local, false)"
        XGUIEng.SetActionFunction(RequesterDialog_No, Action);
    else
        self:DialogQueuePush("OpenRequesterDialog", {_Title, _Text, _Action, _OkCancel});
    end
end

---
-- Öffnet einen Auswahldialog. Sollte bereits ein Dialog zu sehen sein, wird
-- der Dialog der Dialogwarteschlange hinzugefügt.
--
-- @param _Title  Titel des Dialog
-- @param _Text   Text des Dialog
-- @param _Action Callback-Funktion
-- @param _List   Liste der Optionen
-- @within Application-Space
-- @local
--
function BundleDialogWindows.Local:OpenSelectionDialog(_Title, _Text, _Action, _List)
    if XGUIEng.IsWidgetShown(RequesterDialog) == 0 then
        self:OpenDialog(_Title, _Text, _Action);

        local HeroComboBoxID = XGUIEng.GetWidgetID(CustomGame.Widget.KnightsList);
        XGUIEng.ListBoxPopAll(HeroComboBoxID);
        for i=1,#_List do
            XGUIEng.ListBoxPushItem(HeroComboBoxID, Umlaute(_List[i]) );
        end
        XGUIEng.ListBoxSetSelectedIndex(HeroComboBoxID, 0);
        CustomGame.Knight = 0;

        local Action = "XGUIEng.ShowWidget(RequesterDialog, 0)";
        Action = Action .. "; XGUIEng.PopPage()";
        Action = Action .. "; XGUIEng.PopPage()";
        Action = Action .. "; XGUIEng.PopPage()";
        Action = Action .. ";BundleDialogWindows.Local.Callback(BundleDialogWindows.Local)";
        XGUIEng.SetActionFunction(RequesterDialog_Ok, Action);

        local Container = "/InGame/Singleplayer/CustomGame/ContainerSelection/";
        XGUIEng.SetText(Container .. "HeroComboBoxMain/HeroComboBox", "");
        if _List[1] then
            XGUIEng.SetText(Container .. "HeroComboBoxMain/HeroComboBox", _List[1]);
        end
        XGUIEng.PushPage(Container .. "HeroComboBoxContainer", false);
        XGUIEng.PushPage(Container .. "HeroComboBoxMain",false);
        XGUIEng.ShowWidget(Container .. "HeroComboBoxContainer", 0);
        local screen = {GUI.GetScreenSize()};
        local x1, y1 = XGUIEng.GetWidgetScreenPosition(RequesterDialog_Ok);
        XGUIEng.SetWidgetScreenPosition(Container .. "HeroComboBoxMain", x1-25, y1-90);
        XGUIEng.SetWidgetScreenPosition(Container .. "HeroComboBoxContainer", x1-25, y1-20);
    else
        self:DialogQueuePush("OpenSelectionDialog", {_Title, _Text, _Action, _List});
    end
end

---
-- Stellt die Hotkeys zum Speichern des Spiels wieder her.
--
-- @within Application-Space
-- @local
--
function BundleDialogWindows.Local:RestoreSaveGame()
    XGUIEng.ShowWidget("/InGame/InGame/MainMenu/Container/QuickSave", 1);
    XGUIEng.ShowWidget("/InGame/InGame/MainMenu/Container/SaveGame", 1);
    if KeyBindings_SaveGame_Orig_QSB_Windows then
        KeyBindings_SaveGame = KeyBindings_SaveGame_Orig_QSB_Windows;
        KeyBindings_SaveGame_Orig_QSB_Windows = nil;
    end
end

---
-- Überschreibt die originalen Dialogfunktionen, um Fehler in den vorhandenen
-- Funktionen zu vermeiden.
--
-- @within Application-Space
-- @local
--
function BundleDialogWindows.Local:DialogOverwriteOriginal()
    OpenDialog_Orig_Windows = OpenDialog;
    OpenDialog = function(_Message, _Title, _IsMPError)
        if XGUIEng.IsWidgetShown(RequesterDialog) == 0 then
            local Action = "XGUIEng.ShowWidget(RequesterDialog, 0)";
            Action = Action .. "; XGUIEng.PopPage()";
            XGUIEng.SetActionFunction(RequesterDialog_Ok, Action);
            OpenDialog_Orig_Windows(_Title, _Message);
        end
    end

    OpenRequesterDialog_Orig_Windows = OpenRequesterDialog;
    OpenRequesterDialog = function(_Message, _Title, action, _OkCancel, no_action)
        if XGUIEng.IsWidgetShown(RequesterDialog) == 0 then
            local Action = "XGUIEng.ShowWidget(RequesterDialog, 0)";
            Action = Action .. "; XGUIEng.PopPage()";
            XGUIEng.SetActionFunction(RequesterDialog_Yes, Action);
            local Action = "XGUIEng.ShowWidget(RequesterDialog, 0)";
            Action = Action .. "; XGUIEng.PopPage()";
            XGUIEng.SetActionFunction(RequesterDialog_No, Action);
            OpenRequesterDialog_Orig_Windows(_Message, _Title, action, _OkCancel, no_action);
        end
    end
end

---
-- Erzeugt ein Textfenster, dass einen beliebig großen Text anzeigen kann.
-- Optional kann ein Button genutzt werden, der eine Aktion ausführt, wenn
-- er gedrückt wird.
--
-- <b>Alias</b>: TextWindow:New
--
-- Parameterliste:
-- <table>
-- <tr>
-- <th>Index</th>
-- <th>Beschreibung</th>
-- </tr>
-- <tr>
-- <td>1</td>
-- <td>Titel des Fensters</td>
-- </tr>
-- <tr>
-- <td>2</td>
-- <td>Text des Fensters</td>
-- </tr>
-- <tr>
-- <td>3</td>
-- <td>Aktion nach dem Schließen</td>
-- </tr>
-- <tr>
-- <td>4</td>
-- <td>Beschriftung des Buttons</td>
-- </tr>
-- <tr>
-- <td>5</td>
-- <td>Callback des Buttons</td>
-- </tr>
-- </table>
--
-- @param ... Parameterliste
-- @return TextWindow: Konfiguriertes Fenster
-- @within TextWindow
--
function BundleDialogWindows.Local.TextWindow:New(...)
    assert(self == BundleDialogWindows.Local.TextWindow, "Can not be used from instance!")
    local window           = API.InstanceTable(self);
    window.Data.Caption    = arg[1] or window.Data.Caption;
    window.Data.Text       = arg[2] or window.Data.Text;
    window.Data.Action     = arg[3];
    window.Data.ButtonText = arg[4] or window.Data.ButtonText;
    window.Data.Callback   = arg[5] or window.Data.Callback;
    return window;
end

---
-- Fügt einen beliebigen Parameter hinzu. Parameter müssen immer als
-- Schlüssel-Wert-Paare angegeben werden und dürfen vorhandene Pare nicht
-- überschreiben.
--
-- <b>Alias</b>: TextWindow:AddParamater
--
-- @param _Key   Schlüssel
-- @param _Value Wert
-- @return self
-- @within TextWindow
--
function BundleDialogWindows.Local.TextWindow:AddParamater(_Key, _Value)
    assert(self ~= BundleDialogWindows.Local.TextWindow, "Can not be used in static context!");
    assert(self.Data[_Key] ~= nil, "Key '" .._Key.. "' already exists!");
    self.Data[_Key] = _Value;
    return self;
end

---
-- Setzt die Überschrift des TextWindow.
--
-- <b>Alias</b>: TextWindow:SetCaption
--
-- @param _Text Titel des Textfenster
-- @return self
-- @within TextWindow
--
function BundleDialogWindows.Local.TextWindow:SetCaption(_Text)
    assert(self ~= BundleDialogWindows.Local.TextWindow, "Can not be used in static context!");
    assert(type(_Text) == "string");
    self.Data.Caption = _Text;
    return self;
end

---
-- Setzt den Inhalt des TextWindow.
--
-- <b>Alias</b>: TextWindow:SetContent
--
-- @param _Text Inhalt des Textfenster
-- @return self
-- @within TextWindow
--
function BundleDialogWindows.Local.TextWindow:SetContent(_Text)
    assert(self ~= BundleDialogWindows.Local.TextWindow, "Can not be used in static context!");
    assert(type(_Text) == "string");
    self.Data.Text = _Text;
    return self;
end

---
-- Setzt die Close Action des TextWindow. Die Funktion wird beim schließen
-- des Fensters ausgeführt.
--
-- <b>Alias</b>: TextWindow:SetAction
--
-- @param _Function Close Callback
-- @return self
-- @within TextWindow
--
function BundleDialogWindows.Local.TextWindow:SetAction(_Function)
    assert(self ~= BundleDialogWindows.Local.TextWindow, "Can not be used in static context!");
    assert(nil or type(_Callback) == "function");
    self.Data.Action = _Function;
    return self;
end

---
-- Setzt einen Aktionsbutton im TextWindow.
--
-- Der Button muss mit einer Funktion versehen werden. Sobald der Button
-- betätigt wird, wird die Funktion ausgeführt.
--
-- <b>Alias</b>: TextWindow:SetButton
--
-- @param _Text     Beschriftung des Buttons
-- @param _Callback Aktion des Buttons
-- @return self
-- @within TextWindow
--
function BundleDialogWindows.Local.TextWindow:SetButton(_Text, _Callback)
    assert(self ~= BundleDialogWindows.Local.TextWindow, "Can not be used in static context!");
    if _Text then
        assert(type(_Text) == "string");
        assert(type(_Callback) == "function");
    end
    self.Data.ButtonText = _Text;
    self.Data.Callback   = _Callback;
    return self;
end

---
-- Zeigt ein erzeigtes Fenster an.
--
-- <b>Alias</b>: TextWindow:Show
--
-- @within TextWindow
--
function BundleDialogWindows.Local.TextWindow:Show()
    assert(self ~= BundleDialogWindows.Local.TextWindow, "Can not be used in static context!");
    BundleDialogWindows.Local.TextWindow.Data.Shown = true;
    self.Data.Shown = true;
    self:Prepare();

    XGUIEng.ShowWidget("/InGame/Root/Normal/ChatOptions",1);
    XGUIEng.ShowWidget("/InGame/Root/Normal/ChatOptions/ToggleWhisperTarget",1);
    if not self.Data.Action then
        XGUIEng.ShowWidget("/InGame/Root/Normal/ChatOptions/ToggleWhisperTarget",0);
    end
    XGUIEng.SetText("/InGame/Root/Normal/MessageLog/Name","{center}"..self.Data.Caption);
    XGUIEng.SetText("/InGame/Root/Normal/ChatOptions/ToggleWhisperTarget","{center}"..self.Data.ButtonText);
    GUI_Chat.ClearMessageLog();
    GUI_Chat.ChatlogAddMessage(self.Data.Text);

    local stringlen = string.len(self.Data.Text);
    local iterator  = 1;
    local carreturn = 0;
    while (true)
    do
        local s,e = string.find(self.Data.Text, "{cr}", iterator);
        if not e then
            break;
        end
        if e-iterator <= 58 then
            stringlen = stringlen + 58-(e-iterator);
        end
        iterator = e+1;
    end
    if (stringlen + (carreturn*55)) > 1000 then
        XGUIEng.ShowWidget("/InGame/Root/Normal/ChatOptions/ChatLogSlider",1);
    end
    Game.GameTimeSetFactor(GUI.GetPlayerID(), 0);
end

---
-- Initialisiert das TextWindow, bevor es angezeigt wird.
--
-- @within Application-Space
-- @local
--
function BundleDialogWindows.Local.TextWindow:Prepare()
    function GUI_Chat.CloseChatMenu()
        BundleDialogWindows.Local.TextWindow.Data.Shown = false;
        self.Data.Shown = false;
        if self.Data.Callback then
            self.Data.Callback(self);
        end
        XGUIEng.ShowWidget("/InGame/Root/Normal/ChatOptions",0);
        XGUIEng.ShowWidget("/InGame/Root/Normal/MessageLog",0);
        XGUIEng.ShowWidget("/InGame/Root/Normal/MessageLog/BG",1);
        XGUIEng.ShowWidget("/InGame/Root/Normal/MessageLog/Close",1);
        XGUIEng.ShowWidget("/InGame/Root/Normal/MessageLog/Slider",1);
        XGUIEng.ShowWidget("/InGame/Root/Normal/MessageLog/Text",1);
        Game.GameTimeReset(GUI.GetPlayerID());
    end

    function GUI_Chat.ToggleWhisperTargetUpdate()
        Game.GameTimeSetFactor(GUI.GetPlayerID(), 0);
    end

    function GUI_Chat.CheckboxMessageTypeWhisperUpdate()
        XGUIEng.SetText("/InGame/Root/Normal/ChatOptions/TextCheckbox","{center}"..self.Data.Caption);
    end

    function GUI_Chat.ToggleWhisperTarget()
        if self.Data.Action then
            self.Data.Action(self);
        end
    end

    function GUI_Chat.ClearMessageLog()
        g_Chat.ChatHistory = {}
    end

    function GUI_Chat.ChatlogAddMessage(_Message)
        table.insert(g_Chat.ChatHistory, _Message)
        local ChatlogMessage = ""
        for i,v in ipairs(g_Chat.ChatHistory) do
            ChatlogMessage = ChatlogMessage .. v .. "{cr}"
        end
        XGUIEng.SetText("/InGame/Root/Normal/ChatOptions/ChatLog", ChatlogMessage)
    end

    local lang = (Network.GetDesiredLanguage() == "de" and "de") or "en";
    if type(self.Data.Caption) == "table" then
        self.Data.Caption = self.Data.Caption[lang];
    end
    if type(self.Data.ButtonText) == "table" then
        self.Data.ButtonText = self.Data.ButtonText[lang];
    end
    if type(self.Data.Text) == "table" then
        self.Data.Text = self.Data.Text[lang];
    end

    XGUIEng.ShowWidget("/InGame/Root/Normal/ChatOptions/ChatModeAllPlayers",0);
    XGUIEng.ShowWidget("/InGame/Root/Normal/ChatOptions/ChatModeTeam",0);
    XGUIEng.ShowWidget("/InGame/Root/Normal/ChatOptions/ChatModeWhisper",0);
    XGUIEng.ShowWidget("/InGame/Root/Normal/ChatOptions/ChatChooseModeCaption",0);
    XGUIEng.ShowWidget("/InGame/Root/Normal/ChatOptions/Background/TitleBig",1);
    XGUIEng.ShowWidget("/InGame/Root/Normal/ChatOptions/Background/TitleBig/Info",0);
    XGUIEng.ShowWidget("/InGame/Root/Normal/ChatOptions/ChatLogCaption",0);
    XGUIEng.ShowWidget("/InGame/Root/Normal/ChatOptions/BGChoose",0);
    XGUIEng.ShowWidget("/InGame/Root/Normal/ChatOptions/BGChatLog",0);
    XGUIEng.ShowWidget("/InGame/Root/Normal/ChatOptions/ChatLogSlider",0);

    XGUIEng.ShowWidget("/InGame/Root/Normal/MessageLog",1);
    XGUIEng.ShowWidget("/InGame/Root/Normal/MessageLog/BG",0);
    XGUIEng.ShowWidget("/InGame/Root/Normal/MessageLog/Close",0);
    XGUIEng.ShowWidget("/InGame/Root/Normal/MessageLog/Slider",0);
    XGUIEng.ShowWidget("/InGame/Root/Normal/MessageLog/Text",0);

    XGUIEng.DisableButton("/InGame/Root/Normal/ChatOptions/ToggleWhisperTarget",0);

    XGUIEng.SetWidgetLocalPosition("/InGame/Root/Normal/MessageLog",0,95);
    XGUIEng.SetWidgetLocalPosition("/InGame/Root/Normal/MessageLog/Name",0,0);
    XGUIEng.SetTextColor("/InGame/Root/Normal/MessageLog/Name",51,51,121,255);
    XGUIEng.SetWidgetLocalPosition("/InGame/Root/Normal/ChatOptions/ChatLog",140,150);
    XGUIEng.SetWidgetSize("/InGame/Root/Normal/ChatOptions/Background/DialogBG/1 (2)/2",150,400);
    XGUIEng.SetWidgetPositionAndSize("/InGame/Root/Normal/ChatOptions/Background/DialogBG/1 (2)/3",400,500,350,400);
    XGUIEng.SetWidgetSize("/InGame/Root/Normal/ChatOptions/ChatLog",640,580);
    XGUIEng.SetWidgetSize("/InGame/Root/Normal/ChatOptions/ChatLogSlider",46,660);
    XGUIEng.SetWidgetLocalPosition("/InGame/Root/Normal/ChatOptions/ChatLogSlider",780,130);
    XGUIEng.SetWidgetLocalPosition("/InGame/Root/Normal/ChatOptions/ToggleWhisperTarget",110,760);
end

-- -------------------------------------------------------------------------- --

Core:RegisterBundle("BundleDialogWindows");

-- -------------------------------------------------------------------------- --
-- ########################################################################## --
-- #  Symfonia BundleBriefingSystem                                         # --
-- ########################################################################## --
-- -------------------------------------------------------------------------- --

---
-- Ermöglicht es Briefings und Cutscenes zu verwenden.
--
-- Briefings dienen zur Darstellung von Dialogen oder zur näheren Erleuterung
-- der aktuellen Spielsituation. Mit Multiple Choice können dem Spieler mehrere
-- Antwortmöglichkeiten gegeben werden, multiple Handlungsstränge gestartet
-- oder Menüstrukturen abgebildet werden.
--
-- Cutscenes dürfen kein Multiple Choice enthalten und werden immer nur ganz
-- abgespielt oder abgebrochen. Das Überspringen einzelner Seiten ist nicht
-- möglich. Cutscenes verfügen über eine neue Kamerasteuerung (Blickrichtung
-- und Ursprungspunkt) und sollten ausschließlich für szenerische Untermalung
-- der Handlung eingesetzt werden.
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
-- Setzt den Zustand von Quest Timern während biefings.
--
-- Niederlage Timer sind generell inaktiv, können aber aktiviert werden.
--
-- <b>Alias</b>: PauseQuestsDuringBriefings
--
-- @param _Flag Quest Timer pausiert
-- @within User-Space
--
function API.PauseQuestsDuringBriefings(_Flag)
    if GUI then
        API.Dbg("API.PauseQuestsDuringBriefings: Can only be used in the global script!");
        return;
    end
    return BundleDialogWindows.Global:PauseQuestsDuringBriefings(_Flag);
end
PauseQuestsDuringBriefings = API.PauseQuestsDuringBriefings;

---
-- Prüft, ob ein Briefing abgespielt wurde (beendet ist).
--
-- <b>Alias</b>: IsBriefingFinished
--
-- @param _Flag Quest Timer pausiert
-- @return boolean: Briefing ist beendet
-- @within User-Space
--
function API.IsBriefingFinished(_briefingID)
    if GUI then
        API.Dbg("API.IsBriefingFinished: Can only be used in the global script!");
        return;
    end
    return BundleDialogWindows.Global:IsBriefingFinished(_briefingID);
end
IsBriefingFinished = API.IsBriefingFinished;

---
-- Gibt die gewähtle Antwort für die MC Page zurück.
--
-- Wird eine Seite mehrmals durchlaufen, wird die jeweils letzte Antwort
-- zurückgegeben.
--
-- <b>Alias</b>: MCGetSelectedAnswer
--
-- @param _page Seite
-- @return number: Gewählte Antwort
-- @within User-Space
--
function API.MCGetSelectedAnswer(_page)
    if GUI then
        API.Dbg("API.MCGetSelectedAnswer: Can only be used in the global script!");
        return;
    end
    return BundleDialogWindows.Global:MCGetSelectedAnswer(_page);
end
MCGetSelectedAnswer = API.MCGetSelectedAnswer;

---
-- Gibt die Seite im aktuellen Briefing zurück.
--
-- Das aktuelle Briefing ist immer das letzte, das gestartet wurde.
--
-- <b>Alias</b>: GetCurrentBriefingPage
--
-- @param _pageNumber Index der Page
-- @return table: Page
-- @within User-Space
--
function API.GetCurrentBriefingPage(_pageNumber)
    if GUI then
        API.Dbg("API.GetCurrentBriefingPage: Can only be used in the global script!");
        return;
    end
    return BundleDialogWindows.Global:GetCurrentBriefingPage(_pageNumber);
end
GetCurrentBriefingPage = API.GetCurrentBriefingPage;

---
-- Gibt das aktuelle Briefing zurück.
--
-- Das aktuelle Briefing ist immer das letzte, das gestartet wurde.
--
-- <b>Alias</b>: GetCurrentBriefing
--
-- @return table: Briefing
-- @within User-Space
--
function API.GetCurrentBriefing()
    if GUI then
        API.Dbg("API.GetCurrentBriefing: Can only be used in the global script!");
        return;
    end
    return BundleDialogWindows.Global:GetCurrentBriefing();
end
GetCurrentBriefing = API.GetCurrentBriefing;

---
-- Initalisiert die Page-Funktionen für das übergebene Briefing.
--
-- <b>Alias</b>: AddPages
--
-- @param _briefing Quest Timer pausiert
-- @return function(3): AP, ASP, ASMC
-- @within User-Space
--
function API.AddPages(_briefing)
    if GUI then
        API.Dbg("API.AddPages: Can only be used in the global script!");
        return;
    end
    return BundleDialogWindows.Global:AddPages(_briefing);
end
AddPages = API.AddPages;

-- -------------------------------------------------------------------------- --
-- Application-Space                                                          --
-- -------------------------------------------------------------------------- --

BundleDialogWindows = {
    Global = {
        Data = {
            PlayedBriefings = {},
            QuestsPausedWhileBriefingActive = true,
            BriefingID = 0,
        }
    },
    Local = {
        Data = {}
    },
}

-- Global Script ---------------------------------------------------------------

---
-- Initalisiert das Bundle im globalen Skript.
--
-- @within Application-Space
-- @local
--
function BundleDialogWindows.Global:Install()
    self:InitalizeBriefingSystem();
end

---
-- Setzt den Zustand von Quest Timern während biefings.
--
-- Niederlage Timer sind generell inaktiv, können aber aktiviert werden.
--
-- @param _Flag Quest Timer pausiert
-- @within Application-Space
-- @local
--
function BundleDialogWindows.Global:PauseQuestsDuringBriefings(_Flag)
    self.Data.QuestsPausedWhileBriefingActive = _Flag == true;
end

---
-- Prüft, ob ein Briefing abgespielt wurde (beendet ist).
--
-- @param _Flag Quest Timer pausiert
-- @return boolean: Briefing ist beendet
-- @within Application-Space
-- @local
--
function BundleDialogWindows.Global:IsBriefingFinished(_briefingID)
    return self.Data.PlayedBriefings[_briefingID] == true;
end

---
-- Gibt die gewähtle Antwort für die MC Page zurück.
--
-- Wird eine Seite mehrmals durchlaufen, wird die jeweils letzte Antwort
-- zurückgegeben.
--
-- @param _page Seite
-- @return number: Gewählte Antwort
-- @within Application-Space
-- @local
--
function BundleDialogWindows.Global:MCGetSelectedAnswer(_page)
    if _page.mc and _page.mc.given then
        return _page.mc.given;
    end
    return 0;
end

---
-- Gibt die Seite im aktuellen Briefing zurück.
--
-- Das aktuelle Briefing ist immer das letzte, das gestartet wurde.
--
-- @param _pageNumber Index der Page
-- @return table: Page
-- @within Application-Space
-- @local
--
function BundleDialogWindows.Global:GetCurrentBriefingPage(_pageNumber)
    return BriefingSystem.currBriefing[_pageNumber];
end

---
-- Gibt das aktuelle Briefing zurück.
--
-- Das aktuelle Briefing ist immer das letzte, das gestartet wurde.
--
-- @return table: Briefing
-- @within Application-Space
-- @local
--
function BundleDialogWindows.Global:GetCurrentBriefing()
    return BriefingSystem.currBriefing;
end

---
-- Initalisiert die Page-Funktionen für das übergebene Briefing
--
-- @param _briefing Quest Timer pausiert
-- @return function(3): AP, ASP, ASMC
-- @within Application-Space
-- @local
--
function BundleDialogWindows.Global:AddPages(_briefing)
    ---
    -- Erstellt eine Seite in normaler Syntax oder als Cutscene.
    -- AP kann auch für Sprungbefehle genutzt werden. Dabei wird der
    -- Index der Zielseite angebenen.
    -- Für Multiple Choice dienen leere AP-Seiten als Signal, dass
    -- ein Briefing an dieser Stelle endet.
    -- 
    -- @param _page	Seite
    -- @return table: Page
    --
    local AP = function(_page)
        if _page and type(_page) == "table" then
            local lang = (Network.GetDesiredLanguage() == "de" and "de") or "en";
            if type(_page.title) == "table" then
                _page.title = _page.title[lang];
            end
            _page.title = _page.title or "";
            if type(_page.text) == "table" then
                _page.text = _page.text[lang];
            end
            _page.text = _page.text or "";

            -- Multiple Choice Support
            if _page.mc then
                if _page.mc.answers then
                    _page.mc.amount  = #_page.mc.answers;
                    assert(_page.mc.amount >= 1);
                    _page.mc.current = 1;

                    for i=1, _page.mc.amount do
                        if _page.mc.answers[i] then
                            if type(_page.mc.answers[i][1]) == "table" then
                                _page.mc.answers[i][1] = _page.mc.answers[i][1][lang];
                            end
                        end
                    end
                end
                if type(_page.mc.title) == "table" then
                    _page.mc.title = _page.mc.title [lang];
                end
                if type(_page.mc.text) == "table" then
                    _page.mc.text = _page.mc.text[lang];
                end
            end

            -- Cutscene Support
            if _page.view then
                _page.flyTime  = _page.view.FlyTime or 0;
                _page.duration = _page.view.Duration or 0;
            else
                if type(_page.position) == "table" then
                    if not _page.position.X then
                        _page.zOffset = _page.position[2];
                        _page.position = _page.position[1];
                    elseif _page.position.Z then
                        _page.zOffset = _page.position.Z;
                    end
                end

                if _page.lookAt ~= nil then
                    local lookAt = _page.lookAt;
                    if type(lookAt) == "table" then
                        _page.zOffset = lookAt[2];
                        lookAt = lookAt[1];
                    end

                    if type(lookAt) == "string" or type(lookAt) == "number" then
                        local eID    = GetID(lookAt);
                        local ori    = Logic.GetEntityOrientation(eID);
                        if Logic.IsBuilding(eID) == 0 then
                            ori = ori + 90;
                        end
                        local tpCh = 0.085 * string.len(_page.text);

                        _page.position = eID;
                        _page.duration = _page.duration or tpCh;
                        _page.flyTime  = _page.flyTime;
                        _page.rotation = (_page.rotation or 0) +ori;
                    end
                end
            end
            table.insert(_briefing, _page);
        else
            -- Sprünge, Rücksprünge und Abbruch
            table.insert(_briefing, (_page ~= nil and _page) or -1);
        end
        return _page;
    end
    
    ---
    -- Erstellt eine Seite in vereinfachter Syntax. Es wird davon
    -- Ausgegangen, dass das Entity ein Siedler ist. Die Kamera
    -- schaut den Siedler an.
    --
    -- @param _entity		Zielentity
    -- @param _title		Titel der Seite
    -- @param _text		    Text der Seite
    -- @param _dialogCamera Nahsicht an/aus
    -- @param _action       Callback-Funktion
    -- @return table: Page
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
    -- @param _entity		Zielentity
    -- @param _title		Titel der Seite
    -- @param _text		    Text der Seite
    -- @param _dialogCamera Nahsicht an/aus
    -- @param ...			Liste der Antworten und Sprungziele
    -- @return table: Page
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

---
-- Initalisiert das Briefing System im globalen Skript.
--
-- @within Application-Space
-- @local
--
function BundleDialogWindows.Global:InitalizeBriefingSystem()
    -- Setze Standardfarben
    DBlau   = "{@color:70,70,255,255}";
    Blau    = "{@color:153,210,234,255}";
    Weiss   = "{@color:255,255,255,255}";
    Rot     = "{@color:255,32,32,255}";
    Gelb    = "{@color:244,184,0,255}";
    Gruen   = "{@color:173,255,47,255}";
    Orange  = "{@color:255,127,0,255}";
    Mint    = "{@color:0,255,255,255}";
    Grau    = "{@color:180,180,180,255}";
    Trans   = "{@color:0,0,0,0}";

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

                -- Wenn ein Briefing läuft, vergeht keine Zeit in laufenden Quests
                if IsBriefingActive() then
                    if BundleDialogWindows.Global.Data.QuestsPausedWhileBriefingActive == true then
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
    -- Startet ein Briefing im Cutscene Mode. Alle nicht erlauten Operationen,
    -- wie seitenweises Überspringen oder Multiple Choice, sind deaktiviert
    -- bzw. verhindern den Start der Cutscene.
    --
    -- <b>Alias</b>: BriefingSystem.StartCutscene <br/>
    -- <b>Alias</b>: StartCutscene
    --
    -- @param _briefing Briefing-Tabelle
    -- @return number: Briefing-ID
    -- @within User-Space
    --
    function API.StartCutscene(_briefing)
        -- Seitenweises abbrechen ist nicht erlaubt
        _briefing.skipPerPage = false;

        for i=1, #_briefing, 1 do
            -- Multiple Choice ist nicht erlaubt
            if _briefing[i].mc then
                API.Dbg("API.StartCutscene: Unallowed multiple choice at page " ..i.. " found!");
                return;
            end
            -- Marker sind nicht erlaubt
            if _briefing[i].marker then
                API.Dbg("API.StartCutscene: Unallowed marker at page " ..i.. " found!");
                return;
            end
            -- Pointer sind nicht erlaubt
            if _briefing[i].pointer then
                API.Dbg("API.StartCutscene: Unallowed pointer at page " ..i.. " found!");
                return;
            end
            -- Exploration ist nicht erlaubt
            if _briefing[i].explore then
                API.Dbg("API.StartCutscene: Unallowed explore at page " ..i.. " found!");
                return;
            end
        end

        return BriefingSystem.StartBriefing(_briefing, true);
    end
    BriefingSystem.StartCutscene = API.StartCutscene;
    StartCutscene = API.StartCutscene;

    ---
    -- Startet ein Briefing. Im Cutscene Mode wird die normale Kamera
    -- deaktiviert und durch die Cutsene Kamera ersetzt. Außerdem
    -- können Grenzsteine ausgeblendet und der Himmel angezeigt werden.
    -- Die Okklusion wird abgeschaltet Alle Änderungen werden nach dem
    -- Briefing automatisch zurückgesetzt.
    -- Läuft bereits ein Briefing, kommt das neue in die Warteschlange.
    -- Es wird die ID des erstellten Briefings zurückgegeben.
    --
    -- <b>Alias</b>: BriefingSystem.StartBriefing <br/>
    -- <b>Alias</b>: StartBriefing
    --
    -- @param _briefing     Briefing-Table
    -- @param _cutsceneMode Cutscene-Mode nutzen?
    -- @return number: Briefing-ID
    -- @within User-Space
    --
    function API.StartBriefing(_briefing, _cutsceneMode)
        -- view wird nur Ausgeführt, wenn es sich um eine Cutscene handelt
        -- CutsceneMode = false -> alte Berechnung und Syntax
        _cutsceneMode = _cutsceneMode or false;
        Logic.ExecuteInLuaLocalState([[
            BriefingSystem.Flight.systemEnabled = ]]..tostring(not _cutsceneMode)..[[
        ]]);

        -- Briefing ID erzeugen
        BundleDialogWindows.Global.Data.BriefingID = BundleDialogWindows.Global.Data.BriefingID +1;
        _briefing.UniqueBriefingID = BundleDialogWindows.Global.Data.BriefingID;

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

        -- callback überschreiben
        _briefing.finished_Orig_QSB_Briefing = _briefing.finished;
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

            _briefing.finished_Orig_QSB_Briefing(self);
            BundleDialogWindows.Global.Data.PlayedBriefings[_briefing.UniqueBriefingID] = true;
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
        return BundleDialogWindows.Global.Data.BriefingID;
    end
    BriefingSystem.StartBriefing = API.StartBriefing;
    StartBriefing = API.StartBriefing;

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
    -- zutrifft. Diese Optionen sind dann nicht mehr auswählbar.

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
                        -- vorhandene IDs dürfen sich nicht mehr ändern
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

    -- Wenn eine Antwort ausgewählt wurde, wird der entsprechende
    -- Sprung durchgeführt. Wenn remove = true ist, wird die Option
    -- für den Rest des Briefings deaktiviert (für Rücksprünge).
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
-- Initalisiert das Bundle im lokalen Skript.
--
-- @within Application-Space
-- @local
--
function BundleDialogWindows.Local:Install()
    self:InitalizeBriefingSystem();
end

---
-- Initalisiert das Briefing System im lokalen Skript.
--
-- @within Application-Space
-- @local
--
function BundleDialogWindows.Local:InitalizeBriefingSystem()
    GameCallback_GUI_SelectionChanged_Orig_QSB_Briefing = GameCallback_GUI_SelectionChanged;
    GameCallback_GUI_SelectionChanged = function(_Source)
        GameCallback_GUI_SelectionChanged_Orig_QSB_Briefing(_Source);
        if IsBriefingActive() then
            GUI.ClearSelection();
        end
    end
    
    -- ---------------------------------------------------------------------- --
    
    DBlau     = "{@color:70,70,255,255}";
    Blau     = "{@color:153,210,234,255}";
    Weiss     = "{@color:255,255,255,255}";
    Rot         = "{@color:255,32,32,255}";
    Gelb       = "{@color:244,184,0,255}";
    Gruen     = "{@color:173,255,47,255}";
    Orange      = "{@color:255,127,0,255}";
    Mint      = "{@color:0,255,255,255}";
    Grau     = "{@color:180,180,180,255}";
    Trans     = "{@color:0,0,0,0}";

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

        -- -------------------------------------------------------------
        -- Cutscenes by totalwarANGEL                                 --
        -- -------------------------------------------------------------
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

        -- -------------------------------------------------------------

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

    -- Fügt einen text in die Warteschlange ein.
    --
    -- _text	Nachricht
    --
    function BriefingSystem.PushInformationText(_text)
        local length = string.len(_text) * 5;
        length = (length < 800 and 800) or length;
        table.insert(BriefingSystem.InformationTextQueue, {_text, length});
    end

    -- Entfernt einen Text aus der Warteschlange.
    --
    function BriefingSystem.PopInformationText()
        table.remove(BriefingSystem.InformationTextQueue, 1);
    end

    -- Kontrolliert die ANzeige der Notizen während eines Briefings.
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

    -- Setzt den Text, den Titel und die Antworten einer Multiple Choice
    -- Seite. Setzt außerdem die Dauer der Seite auf 11 1/2 Tage (in
    -- der echten Welt). Leider ist es ohne größeren Änderungen nicht
    -- möglich die Anzeigezeit einer Seite auf unendlich zu setzen.
    -- Es ist aber allgemein unwahrscheinlich, dass der Spieler 11,5
    -- Tage vor dem Briefing sitzt, ohne etwas zu tun.
    -- Das Fehlverhalten in diesem Fall ist unerforscht. Es würde dann
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

    -- Eine Antwort wurde ausgewählt (lokales Skript). Die Auswahl wird
    -- gepopt und ein Event an das globale Skript gesendet. Das Event
    -- erhält die Page ID, den Index der selektierten Antwort in der
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
            -- zum ursürunglichen Release der letzten Version.

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

            -- Die Cutscene Notation von totalwarANGEL ermöglicht es viele
            -- Kameraeffekte einfacher umzusetzen, da man die Kamera über
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
            -- Blendet zusätzlichen Text während eines Briefings ein. Siehe
            -- dazu Kommentar bei der Funktion.

            BriefingSystem.ControlInformationText();

            -- Multiple Choice ist bestätigt, wenn das Auswahlfeld
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

    -- -----------------------------------------------------------------
    -- Cutscene Functions by totalwarANGEL
    -- -----------------------------------------------------------------

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
                        -- Textlänge
                        local Length = string.len(_page.text);
                        Height = Height + math.ceil((Length/80));

                        -- Zeilenumbrüche
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

            -- Einfärben
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

-- -------------------------------------------------------------------------- --

Core:RegisterBundle("BundleDialogWindows");

--[[
----------------------------------------------------------------------------
    Reward_Briefing
    added by totalwarANGEL
    Ruft eine Funktion im Skript auf, die eine Briefing-ID zurück gibt.
    Diese wird dann in der Quest gespeichert und kann mit Trigger_Briefing
    verwendet werden.
    Die letzte Zeile der Funktion, die das Briefing erstellt und startet,
    sieht demzufolge so aus: return StartBriefing(briefing)
----------------------------------------------------------------------------
    Argument        | Beschreibung
  ------------------|---------------------------------------
    Funktion        | Funktion, die das Briefing erstellt
                    | und die ID zurück gibt.
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
    if not BriefingID and QSB.DEBUG_CheckWhileRuntime then
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

Core:RegisterBehavior(b_Reward_Briefing)

--[[
----------------------------------------------------------------------------
    Reprisal_Briefing
    added by totalwarANGEL
    Ruft eine Funktion im Skript auf, die eine Briefing-ID zurück gibt.
    Diese wird dann in der Quest gespeichert und kann mit Trigger_Briefing
    verwendet werden.
    Die letzte Zeile der Funktion, die das Briefing erstellt und startet,
    sieht demzufolge so aus: return StartBriefing(briefing)
----------------------------------------------------------------------------
    Argument        | Beschreibung
  ------------------|---------------------------------------
    Funktion        | Funktion, die das Briefing erstellt
                    | und die ID zurück gibt.
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
    if not BriefingID and QSB.DEBUG_CheckWhileRuntime then
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

Core:RegisterBehavior(b_Reprisal_Briefing)

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

Core:RegisterBehavior(b_Trigger_Briefing)-- -------------------------------------------------------------------------- --
-- ########################################################################## --
-- #  Symfonia BundleCastleStore                                            # --
-- ########################################################################## --
-- -------------------------------------------------------------------------- --

---
-- Dieses Bundle stellt ein Burglager zur Verfügung, das sich ähnlich wie das
-- normale Lager verhält. Das Burglager ist von der Ausbaustufe der Burg 
-- abhängig. Je weiter die Burg ausgebaut wird, desto höher ist das Limit.
-- Eine Ware wird dann im Burglager eingelagert, wenn das eingestellte Limit 
-- der Ware im Lagerhaus erreicht wird.
--
-- Der Spieler kann das allgemeine Verhalten des Lagers für alle Waren wählen,
-- und zusätzlich für einzelne Waren andere Verhalten bestimmen. Waren können
-- eingelagert und ausgelagert werden. Eingelagerte Waren können zusätzlich
-- gesperrt werden. Eine gesperrte Ware wird nicht wieder ausgelagert, auch
-- wenn Platz im Lager frei wird.
--
-- @usage
-- -- Ein Lager erzeugen:
-- MyStore = QSB.CatsleStore(1);
--
-- -- Ein Lager löschen:
-- MyStore:Dispose();
--
-- -- Gesamtmenge aller Waren im Burglager:
-- local Amount = MyStore:GetTotalAmount();
-- -- Menge einer Ware ermitteln:
-- -- Sicheres ermitteln aller Waren mit und mit ohne Burglager
-- -- Achtung: Dies ist eine statische Methode!
-- local Amount = QSB.CastleStore:GetGoodAmountWithCastleStore(Goods.G_Grain, 1, false);
-- Menge einer bestimmten Ware ermitteln:
-- local Amount = MyStore:GetAmount(Goods.G_Wood);
-- -- Aktuelles Limit erhalten:
-- MyStore:GetLimit();
--
-- -- Statisch das Lager eines Spielers erhalten:
-- local MyStore = QSB.CastleStore:GetInstance(1);
-- -- Nutzung der Instanz: s.o.
--
-- @module BundleCastleStore
-- @set sort=true
--

API = API or {};
QSB = QSB or {};

-- -------------------------------------------------------------------------- --
-- User-Space                                                                 --
-- -------------------------------------------------------------------------- --

-- Es gibt keine API-Funktionen!

-- -------------------------------------------------------------------------- --
-- Application-Space                                                          --
-- -------------------------------------------------------------------------- --

BundleCastleStore = {
    Global = {
        Data = {
            UpdateCastleStore = false,
            CastleStoreObjects = {},
        },
        CastleStore = {
            Data = {
                CapacityBase = 75,
                Goods = {
                    -- [Ware] = {Menge, Einlager-Flag, Gesperrt-Flag, Untergrenze}
                    [Goods.G_Wood]      = {0, true, false, 35},
                    [Goods.G_Stone]     = {0, true, false, 35},
                    [Goods.G_Iron]      = {0, true, false, 35},
                    [Goods.G_Carcass]   = {0, true, false, 15},
                    [Goods.G_Grain]     = {0, true, false, 15},
                    [Goods.G_RawFish]   = {0, true, false, 15},
                    [Goods.G_Milk]      = {0, true, false, 15},
                    [Goods.G_Herb]      = {0, true, false, 15},
                    [Goods.G_Wool]      = {0, true, false, 15},
                    [Goods.G_Honeycomb] = {0, true, false, 15},
                }
            },
        },
    },
    Local = {
        Data = {},
        
        CastleStore = {
            Data = {}
        },
        
        Description = {
            ShowCastle = {
                Text = {
                    de = "Finanzansicht",
                    en = "Financial view",
                },
            },
            
            ShowCastleStore = {
                Text = {
                    de = "Lageransicht",
                    en = "Storeage view",
                },
            },
            
            GoodButtonDisabled = {
                Text = {
                    de = "Diese Ware wird nicht angenommen.",
                    en = "This good will not be stored.",
                },
            },
            
            CityTab = {
                Title = {
                    de = "Waren bunkern",
                    en = "Keep goods",
                },
                Text = {
                    de = "- Lagert Waren im Burglager ein {cr}- Waren verbleiben auch im Lager, wenn Platz vorhanden ist",
                    en = "- Stores goods inside the store {cr}- Goods also remain in the warehouse when space is available",
                },
            },
            
            StorehouseTab = {
                Title = {
                    de = "Waren zwischenlagern",
                    en = "Store goods temporarily",
                },
                Text = {
                    de = "- Lagert Waren im Burglager ein {cr}- Lagert waren wieder aus, sobald Platz frei wird",
                    en = "- Stores goods inside the store {cr}- Allows to extrac goods as soon as space becomes available",
                },
            },
            
            MultiTab = {
                Title = {
                    de = "Lager räumen",
                    en = "Clear store",
                },
                Text = {
                    de = "- Lagert alle Waren aus {cr}- Benötigt Platz im Lagerhaus",
                    en = "- Removes all goods {cr}- Requires space in the storehouse",
                },
            },
        },
    },
}

-- Global Script ---------------------------------------------------------------

---
-- Initalisiert das Bundle im globalen Skript.
--
-- @within Application-Space
-- @local
--
function BundleCastleStore.Global:Install()
    QSB.CastleStore = BundleCastleStore.Global.CastleStore;
    self:OverwriteGameFunctions()
    API.AddSaveGameAction(BundleCastleStore.Local.OnSaveGameLoaded);
end

---
-- Erzeugt ein neues Burglager-Objekt und gibt es zurück.
--
-- <b>Alias</b>: QSB.CastleStore:New
--
-- @param number _PlayerID     PlayerID des Spielers
-- @return QSB.CastleStore
-- @within User-Space
--
function BundleCastleStore.Global.CastleStore:New(_PlayerID)
    assert(self == BundleCastleStore.Global.CastleStore, "Can not be used from instance!");
    local Store = API.InstanceTable(self);
    Store.Data.PlayerID = _PlayerID;
    BundleCastleStore.Global.Data.CastleStoreObjects[_PlayerID] = Store;
    
    if not self.Data.UpdateCastleStore then
        self.Data.UpdateCastleStore = true;
        StartSimpleJobEx(BundleCastleStore.Global.CastleStore.UpdateStores);
    end
    Logic.ExecuteInLuaLocalState([[
        QSB.CastleStore:CreateStore(]] ..Store.Data.PlayerID.. [[);
    ]])
    return Store;
end

---
-- Gibt die Burglagerinstanz für den Spieler zurück.
--
-- <b>Alias</b>: QSB.CastleStore:GetInstance
--
-- @param number _PlayerID     PlayerID des Spielers
-- @return QSB.CastleStore
-- @within User-Space
--
function BundleCastleStore.Global.CastleStore:GetInstance(_PlayerID)
    assert(self == BundleCastleStore.Global.CastleStore, "Can not be used from instance!");
    return BundleCastleStore.Global.Data.CastleStoreObjects[_PlayerID];
end

---
-- Gibt die Menge an Waren des Spielers zurück, eingeschlossen
-- der Waren im Burglager. Hat der Spieler kein Burglager, wird
-- nur die Menge im Lagerhaus zurückgegeben.
--
-- <b>Alias</b>: QSB.CastleStore:GetGoodAmountWithCastleStore
--
-- @param number _Good          Warentyp
-- @param number _PlayeriD      ID des Spielers
-- @return number
-- @within User-Space
--
function BundleCastleStore.Global.CastleStore:GetGoodAmountWithCastleStore(_Good, _PlayerID, _WithoutMarketplace)
    assert(self == BundleCastleStore.Global.CastleStore, "Can not be used from instance!");
    local CastleStore = self:GetInstance(_PlayerID);
    local Amount = GetPlayerGoodsInSettlement(_Good, _PlayerID, _WithoutMarketplace);
    
    if CastleStore ~= nil and _Good ~= Goods.G_Gold and Logic.GetGoodCategoryForGoodType(_Good) == GoodCategories.GC_Resource then
        Amount = Amount + CastleStore:GetAmount(_Good);
    end
    return Amount;
end

---
-- Zerstört das Burglager.
--
-- <b>Alias</b>: QSB.CastleStore:Dispose
--
-- @within User-Space
--
function BundleCastleStore.Global.CastleStore:Dispose()
    assert(self ~= BundleCastleStore.Global.CastleStore, "Can not be used in static context!");
    Logic.ExecuteInLuaLocalState([[
        QSB.CastleStore:DeleteStore(]] ..self.Data.PlayerID.. [[);
    ]])
    BundleCastleStore.Global.Data.CastleStoreObjects[self.Data.PlayerID] = nil;
end

---
-- Setzt die Obergrenze für eine Ware, ab der ins Burglager
-- ausgelagert wird.
--
-- <b>Alias</b>: QSB.CastleStore:SetUperLimitInStorehouseForGoodType
--
-- @param number _Good      Warentyp
-- @param number _Limit     Obergrenze
-- @return self
-- @within User-Space
--
function BundleCastleStore.Global.CastleStore:SetUperLimitInStorehouseForGoodType(_Good, _Limit)
    assert(self ~= BundleCastleStore.Global.CastleStore, "Can not be used in static context!");
    self.Data.Goods[_Good][4] = _Limit;
    Logic.ExecuteInLuaLocalState([[
        BundleCastleStore.Local.Data.CastleStore[]] ..self.Data.PlayerID.. [[].Goods[]] .._Good.. [[][4] = ]] .._Limit.. [[
    ]])
    return self;
end

---
-- Setzt den Basiswert für die maximale Kapazität des Burglagers.
--
-- <b>Alias</b>: QSB.CastleStore:SetStorageLimit
--
-- @param number _Limit     Maximale Kapazität
-- @return self
-- @within User-Space
--
function BundleCastleStore.Global.CastleStore:SetStorageLimit(_Limit)
    assert(self ~= BundleCastleStore.Global.CastleStore, "Can not be used in static context!");
    self.Data.CapacityBase = _Limit;
    Logic.ExecuteInLuaLocalState([[
        BundleCastleStore.Local.Data.CastleStore[]] ..self.Data.PlayerID.. [[].CapacityBase = ]] .._Limit.. [[
    ]])
    return self;
end

---
-- Gibt die Menge an Waren des Typs im Burglager zurück.
--
-- <b>Alias</b>: QSB.CastleStore:GetAmount
--
-- @param number _Good  Warentyp
-- @return number
-- @within User-Space
--
function BundleCastleStore.Global.CastleStore:GetAmount(_Good)
    assert(self ~= BundleCastleStore.Global.CastleStore, "Can not be used in static context!");
    if self.Data.Goods[_Good] then
        return self.Data.Goods[_Good][1];
    end
    return 0;
end

---
-- Gibt die Gesamtmenge aller Waren im Burglager zurück.
--
-- <b>Alias</b>: QSB.CastleStore:GetTotalAmount
--
-- @return number
-- @within User-Space
--
function BundleCastleStore.Global.CastleStore:GetTotalAmount()
    assert(self ~= BundleCastleStore.Global.CastleStore, "Can not be used in static context!");
    local TotalAmount = 0;
    for k, v in pairs(self.Data.Goods) do
        TotalAmount = TotalAmount + v[1];
    end
    return TotalAmount;
end

---
-- Gibt das aktuelle Lagerlimit zurück.
--
-- <b>Alias</b>: QSB.CastleStore:GetLimit
--
-- @return number
-- @within User-Space
--
function BundleCastleStore.Global.CastleStore:GetLimit()
    assert(self ~= BundleCastleStore.Global.CastleStore, "Can not be used in static context!");
    local Level = 0;
    local Headquarters = Logic.GetHeadquarters(self.Data.PlayerID);
    if Headquarters ~= 0 then
        Level = Logic.GetUpgradeLevel(Headquarters);
    end
    
    local Capacity = self.Data.CapacityBase;
    for i= 1, (Level+1), 1 do
        Capacity = Capacity * 2;
    end
    return Capacity;
end

---
-- Gibt zurück, ob die Ware akzeptiert wird.
--
-- <b>Alias</b>: QSB.CastleStore:IsGoodAccepted
--
-- @param number _Good  Warentyp
-- @return boolean
-- @within User-Space
--
function BundleCastleStore.Global.CastleStore:IsGoodAccepted(_Good)
    assert(self ~= BundleCastleStore.Global.CastleStore, "Can not be used in static context!");
    return self.Data.Goods[_Good][2] == true;
end

---
-- Setzt den Akzeptanzstatus der Ware.
--
-- <b>Alias</b>: QSB.CastleStore:SetGoodAccepted
--
-- @param number _Good      Watentyp
-- @param boolean _Flag     Akzeptanz-Flag
-- @return self
-- @within User-Space
--
function BundleCastleStore.Global.CastleStore:SetGoodAccepted(_Good, _Flag)
    assert(self ~= BundleCastleStore.Global.CastleStore, "Can not be used in static context!");
    self.Data.Goods[_Good][2] = _Flag == true;
    Logic.ExecuteInLuaLocalState([[
        QSB.CastleStore:SetAccepted(
            ]] ..self.Data.PlayerID.. [[, ]] .._Good.. [[, ]] ..tostring(_Flag == true).. [[
        )
    ]])
    return self;
end

---
-- Gibt zurück, ob die Ware gesperrt ist.
--
-- <b>Alias</b>: QSB.CastleStore:IsGoodLocked
--
-- @param number _Good  Warentyp
-- @return boolean
-- @within User-Space
--
function BundleCastleStore.Global.CastleStore:IsGoodLocked(_Good)
    assert(self ~= BundleCastleStore.Global.CastleStore, "Can not be used in static context!");
    return self.Data.Goods[_Good][3] == true;
end

---
-- Setzt ob die Ware gesperrt ist, also nicht ausgelagert wird.
--
-- <b>Alias</b>: QSB.CastleStore:SetGoodLocked
--
-- @param number _Good      Watentyp
-- @param boolean _Flag     Akzeptanz-Flag
-- @return self
-- @within User-Space
--
function BundleCastleStore.Global.CastleStore:SetGoodLocked(_Good, _Flag)
    assert(self ~= BundleCastleStore.Global.CastleStore, "Can not be used in static context!");
    self.Data.Goods[_Good][3] = _Flag == true;
    Logic.ExecuteInLuaLocalState([[
        QSB.CastleStore:SetLocked(
            ]] ..self.Data.PlayerID.. [[, ]] .._Good.. [[, ]] ..tostring(_Flag == true).. [[
        )
    ]])
    return self;
end

---
-- Setzt den Modus "Zwischenlagerung", als ob der Tab geklickt wird.
--
-- <b>Alias</b>: QSB.CastleStore:ActivateTemporaryMode
--
-- @return self
-- @within Application-Space
-- @local
--
function BundleCastleStore.Global.CastleStore:ActivateTemporaryMode()
    assert(self ~= BundleCastleStore.Global.CastleStore, "Can not be used in static context!");
    Logic.ExecuteInLocalLuaState([[
        QSB.CastleStore.OnStorehouseTabClicked(QSB.CastleStore, ]] ..self.Data.PlayerID.. [[)
    ]])
    return self;
end

---
-- Setzt den Modus "Bunkern", als ob der Tab geklickt wird.
--
-- <b>Alias</b>: QSB.CastleStore:ActivateStockMode
--
-- @return self
-- @within Application-Space
-- @local
--
function BundleCastleStore.Global.CastleStore:ActivateStockMode()
    assert(self ~= BundleCastleStore.Global.CastleStore, "Can not be used in static context!");
    Logic.ExecuteInLocalLuaState([[
        QSB.CastleStore.OnCityTabClicked(QSB.CastleStore, ]] ..self.Data.PlayerID.. [[)
    ]])
    return self;
end

---
-- Setzt den Modus "Auslagerung", als ob der Tab geklickt wird.
--
-- <b>Alias</b>: QSB.CastleStore:ActivateOutsourceMode
--
-- @return self
-- @within Application-Space
-- @local
--
function BundleCastleStore.Global.CastleStore:ActivateOutsourceMode()
    assert(self ~= BundleCastleStore.Global.CastleStore, "Can not be used in static context!");
    Logic.ExecuteInLocalLuaState([[
        QSB.CastleStore.OnMultiTabClicked(QSB.CastleStore, ]] ..self.Data.PlayerID.. [[)
    ]])
    return self;
end

---
-- Lagert eine Menge von Waren im Burglager ein.
--
-- <b>Alias</b>: QSB.CastleStore:Store
--
-- @param number _Good      Watentyp
-- @param number _Amount    Menge
-- @return self
-- @within Application-Space
-- @local
--
function BundleCastleStore.Global.CastleStore:Store(_Good, _Amount)
    assert(self ~= BundleCastleStore.Global.CastleStore, "Can not be used in static context!");
    if self:IsGoodAccepted(_Good) then
        if self:GetLimit() >= self:GetTotalAmount() + _Amount then
            local Level = Logic.GetUpgradeLevel(Logic.GetHeadquarters(self.Data.PlayerID));
            if GetPlayerResources(_Good, self.Data.PlayerID) > (self.Data.Goods[_Good][4] * (Level+1)) then
                AddGood(_Good, _Amount * (-1), self.Data.PlayerID);
                self.Data.Goods[_Good][1] = self.Data.Goods[_Good][1] + _Amount;
                Logic.ExecuteInLuaLocalState([[
                    QSB.CastleStore:SetAmount(
                        ]] ..self.Data.PlayerID.. [[, ]] .._Good.. [[, ]] ..self.Data.Goods[_Good][1].. [[
                    )
                ]]);
            end
        end
    end
    return self;
end

---
-- Lagert eine Menge von Waren aus dem Burglager aus.
--
-- <b>Alias</b>: QSB.CastleStore:Outsource
-- 
-- @param number _Good      Watentyp
-- @param number _Amount    Menge
-- @return self
-- @within Application-Space
-- @local
--
function BundleCastleStore.Global.CastleStore:Outsource(_Good, _Amount)
    assert(self ~= BundleCastleStore.Global.CastleStore, "Can not be used in static context!");
    local Level = Logic.GetUpgradeLevel(Logic.GetHeadquarters(self.Data.PlayerID));
    if Logic.GetPlayerUnreservedStorehouseSpace(self.Data.PlayerID) >= _Amount then
        if self:GetAmount(_Good) >= _Amount then
            AddGood(_Good, _Amount, self.Data.PlayerID);
            self.Data.Goods[_Good][1] = self.Data.Goods[_Good][1] - _Amount;
            Logic.ExecuteInLuaLocalState([[
                QSB.CastleStore:SetAmount(
                    ]] ..self.Data.PlayerID.. [[, ]] .._Good.. [[, ]] ..self.Data.Goods[_Good][1].. [[
                )
            ]]);
        end
    end
    return self;
end

---
-- Fügt eine Menge an Waren dem Burglager hinzu, solange noch
-- Platz vorhanden ist und die Ware angenommen wird.
--
-- <b>Alias</b>: QSB.CastleStore:Add
--
-- @param number _Good      Watentyp
-- @param number _Amount    Menge
-- @return self
-- @within User-Space
--
function BundleCastleStore.Global.CastleStore:Add(_Good, _Amount)
    assert(self ~= BundleCastleStore.Global.CastleStore, "Can not be used in static context!");
    if self:IsGoodAccepted(_Good) then
        for i= 1, _Amount, 1 do
            if self:GetLimit() > self:GetTotalAmount() then
                self.Data.Goods[_Good][1] = self.Data.Goods[_Good][1] + 1;
            end
        end
        Logic.ExecuteInLuaLocalState([[
            QSB.CastleStore:SetAmount(
                ]] ..self.Data.PlayerID.. [[, ]] .._Good.. [[, ]] ..self.Data.Goods[_Good][1].. [[
            )
        ]]);
    end
    return self;
end

---
-- Entfernt eine Menge an Waren aus dem Burglager ohne sie ins
-- Lagerhaus zu legen.
--
-- <b>Alias</b>: QSB.CastleStore:Remove
--
-- @param number _Good      Watentyp
-- @param number _Amount    Menge
-- @return self
-- @within User-Space
--
function BundleCastleStore.Global.CastleStore:Remove(_Good, _Amount)
    assert(self ~= BundleCastleStore.Global.CastleStore, "Can not be used in static context!");
    if self:GetAmount(_Good) > 0 then
        local ToRemove = (_Amount <= self:GetAmount(_Good) and _Amount) or self:GetAmount(_Good);
        self.Data.Goods[_Good][1] = self.Data.Goods[_Good][1] - ToRemove;
        Logic.ExecuteInLuaLocalState([[
            QSB.CastleStore:SetAmount(
                ]] ..self.Data.PlayerID.. [[, ]] .._Good.. [[, ]] ..self.Data.Goods[_Good][1].. [[
            )
        ]]);
    end
    return self;
end

---
-- Aktualisiert die Waren im Lager und im Burglager.
--
-- <b>Alias</b>: QSB.CastleStore.UpdateStores
--
-- @within Application-Space
-- @local
--
function BundleCastleStore.Global.CastleStore.UpdateStores()
    assert(self == nil, "This method is only procedural!");
    for k, v in pairs(BundleCastleStore.Global.Data.CastleStoreObjects) do
        if v ~= nil then
            local Level = Logic.GetUpgradeLevel(Logic.GetHeadquarters(v.Data.PlayerID));
            for kk, vv in pairs(v.Data.Goods) do
                if vv ~= nil then
                    -- Ware wird angenommen
                    if vv[2] == true then
                        local AmountInStore  = GetPlayerResources(kk, v.Data.PlayerID)
                        local AmountInCastle = v:GetAmount(kk)
                        -- Auslagern, wenn möglich
                        if AmountInStore < (v.Data.Goods[kk][4] * (Level+1)) then
                            if vv[3] == false then
                                local Amount = (v.Data.Goods[kk][4] * (Level+1)) - AmountInStore;
                                Amount = (Amount > 10 and 10) or Amount;
                                for i= 1, Amount, 1 do
                                    v:Outsource(kk, 1);
                                end
                            end
                        -- Einlagern, falls möglich
                        else
                            local Amount = (AmountInStore > 10 and 10) or AmountInStore;
                            for i= 1, Amount, 1 do
                                v:Store(kk, 1);
                            end
                        end
                    -- Ware ist gebannt
                    else
                        local Amount = (v:GetAmount(kk) >= 10 and 10) or v:GetAmount(kk);
                        for i= 1, Amount, 1 do
                            v:Outsource(kk, 1);
                        end
                    end
                end
            end
        end
    end
end

---
-- Wirt ausgeführt, nachdem ein Spielstand geladen wurde. Diese Funktion Stellt
-- alle nicht persistenten Änderungen wieder her.
--
-- @within Application-Space
-- @local
--
function BundleCastleStore.Global.OnSaveGameLoaded()
    API.Bridge("BundleCastleStore.Local:OverwriteGetStringTableText()")
end

---
-- Überschreibt die globalen Spielfunktionen, die mit dem Burglager in
-- Konfilckt stehen.
--
-- @within Application-Space
-- @local
--
function BundleCastleStore.Global:OverwriteGameFunctions()
    QuestTemplate.IsObjectiveCompleted_Orig_QSB_CastleStore = QuestTemplate.IsObjectiveCompleted;
    QuestTemplate.IsObjectiveCompleted = function(self, objective)
        local objectiveType = objective.Type;
        local data = objective.Data;
    
        if objective.Completed ~= nil then
            return objective.Completed;
        end
        
        if objectiveType == Objective.Produce then
            local GoodAmount = GetPlayerGoodsInSettlement(data[1], self.ReceivingPlayer, true);
            local CastleStore = QSB.CastleStore:GetInstance(self.ReceivingPlayer);
            if CastleStore and Logic.GetGoodCategoryForGoodType(data[1]) == GoodCategories.GC_Resource then
                GoodAmount = GoodAmount + CastleStore:GetAmount(data[1]);
            end
            if (not data[3] and GoodAmount >= data[2]) or (data[3] and GoodAmount < data[2]) then
                objective.Completed = true;
            end
        else
            return QuestTemplate.IsObjectiveCompleted_Orig_QSB_CastleStore(self, objective);
        end
    end
    
    QuestTemplate.SendGoods = function(self)
        for i=1, self.Objectives[0] do
            if self.Objectives[i].Type == Objective.Deliver then
                if self.Objectives[i].Data[3] == nil then
                    local goodType = self.Objectives[i].Data[1]
                    local goodQuantity = self.Objectives[i].Data[2]
                    
                    local amount = QSB.CastleStore:GetGoodAmountWithCastleStore(goodType, self.ReceivingPlayer, true);
                    if amount >= goodQuantity then
                        local Sender = self.ReceivingPlayer
                        local Target = self.Objectives[i].Data[6] and self.Objectives[i].Data[6] or self.SendingPlayer
                        
                        local expectedMerchant = {}
                        expectedMerchant.Good = goodType
                        expectedMerchant.Amount = goodQuantity
                        expectedMerchant.PlayerID = Target
                        expectedMerchant.ID = nil
                        self.Objectives[i].Data[5] = expectedMerchant
                        self.Objectives[i].Data[3] = 1
                        QuestMerchants[#QuestMerchants+1] = expectedMerchant
                        
                        if goodType == Goods.G_Gold then
                            local BuildingID = Logic.GetHeadquarters(Sender)
                            if BuildingID == 0 then
                                BuildingID = Logic.GetStoreHouse(Sender)
                            end
                            self.Objectives[i].Data[3] = Logic.CreateEntityAtBuilding(Entities.U_GoldCart, BuildingID, 0, Target)
                            Logic.HireMerchant(self.Objectives[i].Data[3], Target, goodType, goodQuantity, self.ReceivingPlayer)
                            Logic.RemoveGoodFromStock(BuildingID,goodType,goodQuantity)
                            if MapCallback_DeliverCartSpawned then
                                MapCallback_DeliverCartSpawned( self, self.Objectives[i].Data[3], goodType )
                            end
                        
                        elseif goodType == Goods.G_Water then
                            local BuildingID = Logic.GetMarketplace(Sender)
                        
                            self.Objectives[i].Data[3] = Logic.CreateEntityAtBuilding(Entities.U_Marketer, BuildingID, 0, Target)
                            Logic.HireMerchant(self.Objectives[i].Data[3], Target, goodType, goodQuantity, self.ReceivingPlayer)
                            Logic.RemoveGoodFromStock(BuildingID,goodType,goodQuantity)
                            if MapCallback_DeliverCartSpawned then
                                MapCallback_DeliverCartSpawned( self, self.Objectives[i].Data[3], goodType )
                            end
                            
                        else
                            if Logic.GetGoodCategoryForGoodType(goodType) == GoodCategories.GC_Resource then
                                local StorehouseID = Logic.GetStoreHouse(Target)
                                local NumberOfGoodTypes = Logic.GetNumberOfGoodTypesOnOutStock(StorehouseID)
                                if NumberOfGoodTypes ~= nil then
                                    for j = 0, NumberOfGoodTypes-1 do        
                                        local StoreHouseGoodType = Logic.GetGoodTypeOnOutStockByIndex(StorehouseID,j)
                                        local Amount = Logic.GetAmountOnOutStockByIndex(StorehouseID, j)
                                        if Amount >= goodQuantity then
                                            Logic.RemoveGoodFromStock(StorehouseID, StoreHouseGoodType, goodQuantity, false)                                        
                                        end
                                    end
                                end
                                
                                local SenderStorehouse = Logic.GetStoreHouse(Sender);
                                local AmountInStorehouse = GetPlayerResources(goodType, Sender);
                                if AmountInStorehouse < goodQuantity then
                                    local AmountDifference = goodQuantity - AmountInStorehouse;
                                    AddGood(goodType, AmountInStorehouse * (-1), Sender);
                                    QSB.CastleStore:GetInstance(self.ReceivingPlayer)
                                                   :Remove(goodType, AmountDifference);
                                else
                                    AddGood(goodType, goodQuantity * (-1), Sender);
                                end
                                self.Objectives[i].Data[3] = Logic.CreateEntityAtBuilding(Entities.U_ResourceMerchant, SenderStorehouse, 0, Target);
                                Logic.HireMerchant(self.Objectives[i].Data[3], Target, goodType, goodQuantity, self.ReceivingPlayer);
                            else
                                Logic.StartTradeGoodGathering(Sender, Target, goodType, goodQuantity, 0)
                            end
                        end
                    end
                end
            end
        end 
    end
end

-- Local Script ----------------------------------------------------------------

---
-- Initalisiert das Bundle im lokalen Skript.
--
-- @within Application-Space
-- @local
--
function BundleCastleStore.Local:Install()
    QSB.CastleStore = BundleCastleStore.Local.CastleStore;
    self:OverwriteGameFunctions();
    self:OverwriteGetStringTableText();
end

---
-- Erzeugt eine neue lokale Referenz zum Burglager des Spielers.
--
-- <b>Alias</b>: QSB.CastleStore:CreateStore
--
-- @param number _PlayerID      ID des Spielers
-- @within Application-Space
-- @local
--
function BundleCastleStore.Local.CastleStore:CreateStore(_PlayerID)
    assert(self == BundleCastleStore.Local.CastleStore, "Can not be used from instance!");
    local Store = {
        StoreMode = 1,
        CapacityBase = 75,
        Goods = {
            [Goods.G_Wood]      = {0, true, false, 35},
            [Goods.G_Stone]     = {0, true, false, 35},
            [Goods.G_Iron]      = {0, true, false, 35},
            [Goods.G_Carcass]   = {0, true, false, 15},
            [Goods.G_Grain]     = {0, true, false, 15},
            [Goods.G_RawFish]   = {0, true, false, 15},
            [Goods.G_Milk]      = {0, true, false, 15},
            [Goods.G_Herb]      = {0, true, false, 15},
            [Goods.G_Wool]      = {0, true, false, 15},
            [Goods.G_Honeycomb] = {0, true, false, 15},
        }
    }
    self.Data[_PlayerID] = Store;
end

---
-- Entfernt eine lokale Referenz auf ein Burglager des Spielers.
--
-- <b>Alias</b>: QSB.CastleStore:DeleteStore
--
-- @param number _PlayerID      ID des Spielers
-- @within Application-Space
-- @local
--
function BundleCastleStore.Local.CastleStore:DeleteStore(_PlayerID)
    assert(self == BundleCastleStore.Local.CastleStore, "Can not be used from instance!");
    self.Data[_PlayerID] = nil;
end

---
-- Gibt die Menge an Waren des Typs zurück.
--
-- <b>Alias</b>: QSB.CastleStore:GetAmount
--
-- @param number _PlayerID      ID des Spielers
-- @param number _Good          Warentyp
-- @return number
-- @within Application-Space
-- @local
--
function BundleCastleStore.Local.CastleStore:GetAmount(_PlayerID, _Good)
    assert(self == BundleCastleStore.Local.CastleStore, "Can not be used from instance!");
    if not self:HasCastleStore(_PlayerID) then
        return 0;
    end
    return self.Data[_PlayerID].Goods[_Good][1];
end

---
-- Gibt die Menge an Waren des Spielers zurück, eingeschlossen
-- der Waren im Burglager. Hat der Spieler kein Burglager, wird
-- nur die Menge im Lagerhaus zurückgegeben.
--
-- <b>Alias</b>: QSB.CastleStore:GetGoodAmountWithCastleStore
--
-- @param number _Good          Warentyp
-- @param number _PlayeriD      ID des Spielers
-- @return number
-- @within User-Space
--
function BundleCastleStore.Local.CastleStore:GetGoodAmountWithCastleStore(_Good, _PlayerID, _WithoutMarketplace)
    assert(self == BundleCastleStore.Local.CastleStore, "Can not be used from instance!");
    local Amount = GetPlayerGoodsInSettlement(_Good, _PlayerID, _WithoutMarketplace);
    if self:HasCastleStore(_PlayerID) then
        if _Good ~= Goods.G_Gold and Logic.GetGoodCategoryForGoodType(_Good) == GoodCategories.GC_Resource then
            Amount = Amount + self:GetAmount(_PlayerID, _Good);
        end
    end
    return Amount;
end

---
-- Gibt die Gesamtmenge aller Waren im Burglager zurück.
--
-- <b>Alias</b>: QSB.CastleStore:GetTotalAmount
--
-- @param number _PlayerID      ID des Spielers
-- @param number _Good          Warentyp
-- @return number
-- @within Application-Space
-- @local
--
function BundleCastleStore.Local.CastleStore:GetTotalAmount(_PlayerID)
    assert(self == BundleCastleStore.Local.CastleStore, "Can not be used from instance!");
    if not self:HasCastleStore(_PlayerID) then
        return 0;
    end
    local TotalAmount = 0;
    for k, v in pairs(self.Data[_PlayerID].Goods) do
        TotalAmount = TotalAmount + v[1];
    end
    return TotalAmount;
end

---
-- Ändert die Menge an Waren des Typs.
--
-- <b>Alias</b>: QSB.CastleStore:SetAmount
--
-- @param number _PlayerID      ID des Spielers
-- @param number _Good          Warentyp
-- @param number _Amount        Warenmenge
-- @return self
-- @within Application-Space
-- @local
--
function BundleCastleStore.Local.CastleStore:SetAmount(_PlayerID, _Good, _Amount)
    assert(self == BundleCastleStore.Local.CastleStore, "Can not be used from instance!");
    if not self:HasCastleStore(_PlayerID) then
        return;
    end
    self.Data[_PlayerID].Goods[_Good][1] = _Amount;
    return self;
end

---
-- Gibt zurück, ob die Ware des Typs akzeptiert wird.
--
-- <b>Alias</b>: QSB.CastleStore:IsAccepted
--
-- @param number _PlayerID      ID des Spielers
-- @param number _Good          Warentyp
-- @return boolean
-- @within Application-Space
-- @local
--
function BundleCastleStore.Local.CastleStore:IsAccepted(_PlayerID, _Good)
    assert(self == BundleCastleStore.Local.CastleStore, "Can not be used from instance!");
    if not self:HasCastleStore(_PlayerID) then
        return false;
    end
    if not self.Data[_PlayerID].Goods[_Good] then
        return false;
    end
    return self.Data[_PlayerID].Goods[_Good][2] == true;
end

---
-- Setzt eine Ware als akzeptiert.
--
-- <b>Alias</b>: QSB.CastleStore:SetAccepted
--
-- @param number _PlayerID      ID des Spielers
-- @param number _Good          Warentyp
-- @param boolean _Good         Akzeptanz-Flag
-- @return self
-- @within Application-Space
-- @local
--
function BundleCastleStore.Local.CastleStore:SetAccepted(_PlayerID, _Good, _Flag)
    assert(self == BundleCastleStore.Local.CastleStore, "Can not be used from instance!");
    if self:HasCastleStore(_PlayerID) then
        if self.Data[_PlayerID].Goods[_Good] then
            self.Data[_PlayerID].Goods[_Good][2] = _Flag == true;
        end
    end
    return self;
end

---
-- Gibt zurück, ob die Ware des Typs gesperrt ist.
--
-- <b>Alias</b>: QSB.CastleStore:IsLocked
--
-- @param number _PlayerID      ID des Spielers
-- @param number _Good          Warentyp
-- @return boolean
-- @within Application-Space
-- @local
--
function BundleCastleStore.Local.CastleStore:IsLocked(_PlayerID, _Good)
    assert(self == BundleCastleStore.Local.CastleStore, "Can not be used from instance!");
    if not self:HasCastleStore(_PlayerID) then
        return false;
    end
    if not self.Data[_PlayerID].Goods[_Good] then
        return false;
    end
    return self.Data[_PlayerID].Goods[_Good][3] == true;
end

---
-- Setzt eine Ware als gesperrt.
--
-- <b>Alias</b>: QSB.CastleStore:SetLocked
--
-- @param number _PlayerID      ID des Spielers
-- @param number _Good          Warentyp
-- @param boolean _Good         Akzeptanz-Flag
-- @return self
-- @within Application-Space
-- @local
--
function BundleCastleStore.Local.CastleStore:SetLocked(_PlayerID, _Good, _Flag)
    assert(self == BundleCastleStore.Local.CastleStore, "Can not be used from instance!");
    if self:HasCastleStore(_PlayerID) then
        if self.Data[_PlayerID].Goods[_Good] then
            self.Data[_PlayerID].Goods[_Good][3] = _Flag == true;
        end
    end
    return self;
end

---
-- Gibt zurück, ob der Spieler ein Burglager hat.
--
-- <b>Alias</b>: QSB.CastleStore:HasCastleStore
--
-- @param number _PlayerID      ID des Spielers
-- @return boolean
-- @within Application-Space
-- @local
--
function BundleCastleStore.Local.CastleStore:HasCastleStore(_PlayerID)
    assert(self == BundleCastleStore.Local.CastleStore, "Can not be used from instance!");
    return self.Data[_PlayerID] ~= nil;
end

---
-- Gibt die Referenz des Burglagers des Spielers zurück.
--
-- <b>Alias</b>: QSB.CastleStore:GetStore
--
-- @param number _PlayerID      ID des Spielers
-- @return table
-- @within Application-Space
-- @local
--
function BundleCastleStore.Local.CastleStore:GetStore(_PlayerID)
    assert(self == BundleCastleStore.Local.CastleStore, "Can not be used from instance!");
    return self.Data[_PlayerID];
end

---
-- Gibt das aktuelle Lagerlimit des Burglagers zurück.
--
-- <b>Alias</b>: QSB.CastleStore:GetLimit
--
-- @param number _PlayerID      ID des Spielers
-- @within Application-Space
-- @local
--
function BundleCastleStore.Local.CastleStore:GetLimit(_PlayerID)
    assert(self == BundleCastleStore.Local.CastleStore, "Can not be used from instance!");
    local Level = 0;
    local Headquarters = Logic.GetHeadquarters(_PlayerID);
    if Headquarters ~= 0 then
        Level = Logic.GetUpgradeLevel(Headquarters);
    end
    
    local Capacity = self.Data[_PlayerID].CapacityBase;
    for i= 1, (Level+1), 1 do
        Capacity = Capacity * 2;
    end
    return Capacity;
end

---
-- "Waren einlagern" wurde geklickt.
--
-- <b>Alias</b>: QSB.CastleStore:OnStorehouseTabClicked
--
-- @param number _PlayerID      ID des Spielers
-- @within Application-Space
-- @local
--
function BundleCastleStore.Local.CastleStore:OnStorehouseTabClicked(_PlayerID)
    assert(self == BundleCastleStore.Local.CastleStore, "Can not be used from instance!");
    self.Data[_PlayerID].StoreMode = 1;
    self:UpdateBehaviorTabs(_PlayerID);
    GUI.SendScriptCommand([[
        local Store = QSB.CastleStore:GetInstance(]] .._PlayerID.. [[);
        for k, v in pairs(Store.Data.Goods) do
            Store:SetGoodAccepted(k, true);
            Store:SetGoodLocked(k, false);
        end
    ]]);
end

---
-- "Waren bunkern" wurde gedrückt.
--
-- <b>Alias</b>: QSB.CastleStore:OnCityTabClicked
--
-- @param number _PlayerID      ID des Spielers
-- @within Application-Space
-- @local
--
function BundleCastleStore.Local.CastleStore:OnCityTabClicked(_PlayerID)
    assert(self == BundleCastleStore.Local.CastleStore, "Can not be used from instance!");
    self.Data[_PlayerID].StoreMode = 2;
    self:UpdateBehaviorTabs(_PlayerID);
    GUI.SendScriptCommand([[
        local Store = QSB.CastleStore:GetInstance(]] .._PlayerID.. [[);
        for k, v in pairs(Store.Data.Goods) do
            Store:SetGoodAccepted(k, true);
            Store:SetGoodLocked(k, true);
        end
    ]]);
end

---
-- "Lager räumen" wurde gedrückt.
--
-- <b>Alias</b>: QSB.CastleStore:OnMultiTabClicked
--
-- @param number _PlayerID      ID des Spielers
-- @within Application-Space
-- @local
--
function BundleCastleStore.Local.CastleStore:OnMultiTabClicked(_PlayerID)
    assert(self == BundleCastleStore.Local.CastleStore, "Can not be used from instance!");
    self.Data[_PlayerID].StoreMode = 3;
    self:UpdateBehaviorTabs(_PlayerID);
    GUI.SendScriptCommand([[
        local Store = QSB.CastleStore:GetInstance(]] .._PlayerID.. [[);
        for k, v in pairs(Store.Data.Goods) do
            Store:SetGoodAccepted(k, false);
        end
    ]]);
end

---
-- FIXME
--
-- <b>Alias</b>: QSB.CastleStore:GoodClicked
--
-- @param number _PlayerID      ID des Spielers
-- @within Application-Space
-- @local
--
function BundleCastleStore.Local.CastleStore:GoodClicked(_PlayerID, _GoodType)
    assert(self == BundleCastleStore.Local.CastleStore, "Can not be used from instance!");
    if self:HasCastleStore(_PlayerID) then
        local CurrentWirgetID = XGUIEng.GetCurrentWidgetID();
        GUI.SendScriptCommand([[
            local Store = QSB.CastleStore:GetInstance(]] .._PlayerID.. [[);
            local Accepted = not Store:IsGoodAccepted(]] .._GoodType.. [[)
            Store:SetGoodAccepted(]] .._GoodType.. [[, Accepted);
        ]]);
    end
end

---
-- Der Spieler wechselt zwischen den Ansichten in der Burg.
--
-- <b>Alias</b>: QSB.CastleStore:DestroyGoodsClicked
--
-- @param number _PlayerID      ID des Spielers
-- @within Application-Space
-- @local
--
function BundleCastleStore.Local.CastleStore:DestroyGoodsClicked(_PlayerID)
    assert(self == BundleCastleStore.Local.CastleStore, "Can not be used from instance!");
    if self:HasCastleStore(_PlayerID) then
        QSB.CastleStore.ToggleStore();
    end
end

---
-- Aktualisiert das Burgmenü, sobald sich die Selektion ändert.
--
-- <b>Alias</b>: QSB.CastleStore:SelectionChanged
--
-- @param number _PlayerID      ID des Spielers
-- @within Application-Space
-- @local
--
function BundleCastleStore.Local.CastleStore:SelectionChanged(_PlayerID)
    assert(self == BundleCastleStore.Local.CastleStore, "Can not be used from instance!");
    if self:HasCastleStore(_PlayerID) then
        local SelectedID = GUI.GetSelectedEntity();
        if Logic.GetHeadquarters(_PlayerID) == SelectedID then
            self:ShowCastleMenu();
        else
            self:RestoreStorehouseMenu();
        end
    end
end

---
-- Aktualisiert die Burglager-Tabs.
--
-- <b>Alias</b>: QSB.CastleStore:UpdateBehaviorTabs
--
-- @param number _PlayerID      ID des Spielers
-- @within Application-Space
-- @local
--
function BundleCastleStore.Local.CastleStore:UpdateBehaviorTabs(_PlayerID)
    assert(self == BundleCastleStore.Local.CastleStore, "Can not be used from instance!");
    if not QSB.CastleStore:HasCastleStore(GUI.GetPlayerID()) then
        return;
    end
    XGUIEng.ShowAllSubWidgets("/InGame/Root/Normal/AlignBottomRight/Selection/Storehouse/TabButtons", 0);
    if self.Data[_PlayerID].StoreMode == 1 then
        XGUIEng.ShowWidget("/InGame/Root/Normal/AlignBottomRight/Selection/Storehouse/TabButtons/StorehouseTabButtonUp", 1);
        XGUIEng.ShowWidget("/InGame/Root/Normal/AlignBottomRight/Selection/Storehouse/TabButtons/CityTabButtonDown", 1);
        XGUIEng.ShowWidget("/InGame/Root/Normal/AlignBottomRight/Selection/Storehouse/TabButtons/Tab03Down", 1);
    elseif self.Data[_PlayerID].StoreMode == 2 then
        XGUIEng.ShowWidget("/InGame/Root/Normal/AlignBottomRight/Selection/Storehouse/TabButtons/StorehouseTabButtonDown", 1);
        XGUIEng.ShowWidget("/InGame/Root/Normal/AlignBottomRight/Selection/Storehouse/TabButtons/CityTabButtonUp", 1);
        XGUIEng.ShowWidget("/InGame/Root/Normal/AlignBottomRight/Selection/Storehouse/TabButtons/Tab03Down", 1);
    else
        XGUIEng.ShowWidget("/InGame/Root/Normal/AlignBottomRight/Selection/Storehouse/TabButtons/StorehouseTabButtonDown", 1);
        XGUIEng.ShowWidget("/InGame/Root/Normal/AlignBottomRight/Selection/Storehouse/TabButtons/CityTabButtonDown", 1);
        XGUIEng.ShowWidget("/InGame/Root/Normal/AlignBottomRight/Selection/Storehouse/TabButtons/Tab03Up", 1);
    end
end

---
-- Aktualisiert die Mengenanzeige der Waren im Burglager.
--
-- <b>Alias</b>: QSB.CastleStore:UpdateGoodsDisplay
--
-- @param number _PlayerID      ID des Spielers
-- @within Application-Space
-- @local
--
function BundleCastleStore.Local.CastleStore:UpdateGoodsDisplay(_PlayerID, _CurrentWidget)
    assert(self == BundleCastleStore.Local.CastleStore, "Can not be used from instance!");
    if not self:HasCastleStore(_PlayerID) then
        return;
    end
    
    local MotherContainer  = "/InGame/Root/Normal/AlignBottomRight/Selection/Storehouse/InStorehouse/Goods";
    local WarningColor = "";
    if self:GetLimit(_PlayerID) == self:GetTotalAmount(_PlayerID) then
        WarningColor = "{@color:255,32,32,255}";
    end
    for k, v in pairs(self.Data[_PlayerID].Goods) do
        local GoodTypeName = Logic.GetGoodTypeName(k);
        local AmountWidget = MotherContainer.. "/" ..GoodTypeName.. "/Amount";
        local ButtonWidget = MotherContainer.. "/" ..GoodTypeName.. "/Button";
        local BGWidget = MotherContainer.. "/" ..GoodTypeName.. "/BG";
        XGUIEng.SetText(AmountWidget, "{center}" .. WarningColor .. v[1]);
        XGUIEng.DisableButton(ButtonWidget, 0)
        
        if self:IsAccepted(_PlayerID, k) then
            XGUIEng.SetMaterialColor(ButtonWidget, 0, 255, 255, 255, 255);
            XGUIEng.SetMaterialColor(ButtonWidget, 1, 255, 255, 255, 255);
            XGUIEng.SetMaterialColor(ButtonWidget, 7, 255, 255, 255, 255);
            --XGUIEng.SetMaterialColor(BGWidget, 0, 255, 255, 255, 255);
        else
            XGUIEng.SetMaterialColor(ButtonWidget, 0, 190, 90, 90, 255);
            XGUIEng.SetMaterialColor(ButtonWidget, 1, 190, 90, 90, 255);
            XGUIEng.SetMaterialColor(ButtonWidget, 7, 190, 90, 90, 255);
            --XGUIEng.SetMaterialColor(BGWidget, 0, 90, 90, 90, 255);
        end
    end
end

---
-- Aktualisiert die Lagerauslastungsanzeige des Burglagers.
--
-- <b>Alias</b>: QSB.CastleStore:UpdateStorageLimit
--
-- @param number _PlayerID      ID des Spielers
-- @within Application-Space
-- @local
--
function BundleCastleStore.Local.CastleStore:UpdateStorageLimit(_PlayerID)
    assert(self == BundleCastleStore.Local.CastleStore, "Can not be used from instance!");
    if not self:HasCastleStore(_PlayerID) then
        return;
    end
    local CurrentWidgetID = XGUIEng.GetCurrentWidgetID();
    local PlayerID = GUI.GetPlayerID();
    local StorageUsed = QSB.CastleStore:GetTotalAmount(PlayerID);
    local StorageLimit = QSB.CastleStore:GetLimit(PlayerID);
    local StorageLimitText = XGUIEng.GetStringTableText("UI_Texts/StorageLimit_colon");
    local Text = "{center}" ..StorageLimitText.. " " ..StorageUsed.. "/" ..StorageLimit;
    XGUIEng.SetText(CurrentWidgetID, Text);
end

---
-- Wechselt zwischen der Finanzansicht und dem Burglager.
--
-- <b>Alias</b>: QSB.CastleStore:ToggleStore
--
-- @within Application-Space
-- @local
--
function BundleCastleStore.Local.CastleStore:ToggleStore()
    assert(self == nil, "This function is procedural!");
    if QSB.CastleStore:HasCastleStore(GUI.GetPlayerID()) then
        if Logic.GetHeadquarters(GUI.GetPlayerID()) == GUI.GetSelectedEntity() then
            if XGUIEng.IsWidgetShown("/InGame/Root/Normal/AlignBottomRight/Selection/Castle") == 1 then
                QSB.CastleStore.ShowCastleStoreMenu(QSB.CastleStore);
            else
                QSB.CastleStore.ShowCastleMenu(QSB.CastleStore);
            end
        end
    end
end

---
-- Stellt das normale Lagerhausmenü wieder her.
--
-- <b>Alias</b>: QSB.CastleStore:RestoreStorehouseMenu
--
-- @within Application-Space
-- @local
--
function BundleCastleStore.Local.CastleStore:RestoreStorehouseMenu()
    XGUIEng.ShowAllSubWidgets("/InGame/Root/Normal/AlignBottomRight/Selection/Storehouse/TabButtons", 1);
    XGUIEng.ShowAllSubWidgets("/InGame/Root/Normal/AlignBottomRight/Selection/Storehouse/InCity/Goods", 1);
    XGUIEng.ShowWidget("/InGame/Root/Normal/AlignBottomRight/Selection/Storehouse/InCity", 0);
    SetIcon("/InGame/Root/Normal/AlignBottomRight/DialogButtons/PlayerButtons/DestroyGoods", {16, 8});
    
    local MotherPath = "/InGame/Root/Normal/AlignBottomRight/Selection/Storehouse/TabButtons/";
    SetIcon(MotherPath.. "StorehouseTabButtonUp/up/B_StoreHouse", {3, 13});
    SetIcon(MotherPath.. "StorehouseTabButtonDown/down/B_StoreHouse", {3, 13});
    SetIcon(MotherPath.. "CityTabButtonUp/up/CityBuildingsNumber", {8, 1});
    SetIcon(MotherPath.. "TabButtons/CityTabButtonDown/down/CityBuildingsNumber", {8, 1});
    SetIcon(MotherPath.. "TabButtons/Tab03Up/up/B_Castle_ME", {3, 14});
    SetIcon(MotherPath.. "Tab03Down/down/B_Castle_ME", {3, 14});

    for k, v in ipairs {"G_Carcass", "G_Grain", "G_Milk", "G_RawFish", "G_Iron","G_Wood", "G_Stone", "G_Honeycomb", "G_Herb", "G_Wool"} do
        local MotherPath = "/InGame/Root/Normal/AlignBottomRight/Selection/Storehouse/InStorehouse/Goods/";
        XGUIEng.SetMaterialColor(MotherPath.. v.. "/Button", 0, 255, 255, 255, 255);
        XGUIEng.SetMaterialColor(MotherPath.. v.. "/Button", 1, 255, 255, 255, 255);
        XGUIEng.SetMaterialColor(MotherPath.. v.. "/Button", 7, 255, 255, 255, 255);
    end
end

---
-- Das normale Burgmenü wird angezeigt.
--
-- <b>Alias</b>: QSB.CastleStore:ShowCastleMenu
--
-- @within Application-Space
-- @local
--
function BundleCastleStore.Local.CastleStore:ShowCastleMenu()
    local MotherPath = "/InGame/Root/Normal/AlignBottomRight/";
    XGUIEng.ShowWidget(MotherPath.. "Selection/BGBig", 0)
    XGUIEng.ShowWidget(MotherPath.. "Selection/Storehouse", 0)
    XGUIEng.ShowWidget(MotherPath.. "Selection/BGSmall", 1)
    XGUIEng.ShowWidget(MotherPath.. "Selection/Castle", 1)
    
    if g_HideSoldierPayment ~= nil then
        XGUIEng.ShowWidget(MotherPath.. "Selection/Castle/Treasury/Payment", 0)
        XGUIEng.ShowWidget(MotherPath.. "Selection/Castle/LimitSoldiers", 0)
    end
    GUI_BuildingInfo.PaymentLevelSliderUpdate()
    GUI_BuildingInfo.TaxationLevelSliderUpdate()
    GUI_Trade.StorehouseSelected()
    local AnchorInfoForSmallX, AnchorInfoForSmallY = XGUIEng.GetWidgetLocalPosition(MotherPath.. "Selection/AnchorInfoForSmall")
    XGUIEng.SetWidgetLocalPosition(MotherPath.. "Selection/Info", AnchorInfoForSmallX, AnchorInfoForSmallY)
    
    XGUIEng.ShowWidget(MotherPath.. "DialogButtons/PlayerButtons", 1)
    XGUIEng.ShowWidget(MotherPath.. "DialogButtons/PlayerButtons/DestroyGoods", 1)
    XGUIEng.DisableButton(MotherPath.. "DialogButtons/PlayerButtons/DestroyGoods", 0)
    SetIcon(MotherPath.. "DialogButtons/PlayerButtons/DestroyGoods", {10, 9})
end

---
-- Das Burglager wird angezeigt.
--
-- <b>Alias</b>: QSB.CastleStore:ShowCastleStoreMenu
--
-- @within Application-Space
-- @local
--
function BundleCastleStore.Local.CastleStore:ShowCastleStoreMenu()
    local MotherPath = "/InGame/Root/Normal/AlignBottomRight/";
    XGUIEng.ShowWidget(MotherPath.. "Selection/Selection/BGSmall", 0);
    XGUIEng.ShowWidget(MotherPath.. "Selection/Castle", 0);
    XGUIEng.ShowWidget(MotherPath.. "Selection/BGSmall", 0);
    XGUIEng.ShowWidget(MotherPath.. "Selection/BGBig", 1);
    XGUIEng.ShowWidget(MotherPath.. "Selection/Storehouse", 1);
    XGUIEng.ShowWidget(MotherPath.. "Selection/Storehouse/AmountContainer", 0);
    XGUIEng.ShowAllSubWidgets(MotherPath.. "Selection/Storehouse/TabButtons", 1);

    GUI_Trade.StorehouseSelected()
    local AnchorInfoForBigX, AnchorInfoForBigY = XGUIEng.GetWidgetLocalPosition(MotherPath.. "Selection/AnchorInfoForBig")
    XGUIEng.SetWidgetLocalPosition(MotherPath.. "Selection/Info", AnchorInfoForBigX, AnchorInfoForBigY)
    
    XGUIEng.ShowWidget(MotherPath.. "DialogButtons/PlayerButtons", 1)
    XGUIEng.ShowWidget(MotherPath.. "DialogButtons/PlayerButtons/DestroyGoods", 1)
    XGUIEng.ShowWidget(MotherPath.. "Selection/Storehouse/InStorehouse", 1)
    XGUIEng.ShowWidget(MotherPath.. "Selection/Storehouse/InMulti", 0)
    XGUIEng.ShowWidget(MotherPath.. "Selection/Storehouse/InCity", 1)
    XGUIEng.ShowAllSubWidgets(MotherPath.. "Selection/Storehouse/InCity/Goods", 0);
    XGUIEng.ShowWidget(MotherPath.. "Selection/Storehouse/InCity/Goods/G_Beer", 1)
    XGUIEng.DisableButton(MotherPath.. "DialogButtons/PlayerButtons/DestroyGoods", 0)
    
    local MotherPathDialog = MotherPath.. "DialogButtons/PlayerButtons/";
    local MotherPathTabs = MotherPath.. "Selection/Storehouse/TabButtons/";
    SetIcon(MotherPathDialog.. "DestroyGoods", {3, 14});
    SetIcon(MotherPathTabs.. "StorehouseTabButtonUp/up/B_StoreHouse", {10, 9});
    SetIcon(MotherPathTabs.. "StorehouseTabButtonDown/down/B_StoreHouse", {10, 9});
    SetIcon(MotherPathTabs.. "CityTabButtonUp/up/CityBuildingsNumber", {15, 6});
    SetIcon(MotherPathTabs.. "CityTabButtonDown/down/CityBuildingsNumber", {15, 6});
    SetIcon(MotherPathTabs.. "Tab03Up/up/B_Castle_ME", {7, 1});
    SetIcon(MotherPathTabs.. "Tab03Down/down/B_Castle_ME", {7, 1});
    
    self:UpdateBehaviorTabs(GUI.GetPlayerID());
end

---
-- Überschreibt die Textausgabe mit den eigenen Texten.
--
-- @within Application-Space
-- @local
--
function BundleCastleStore.Local:OverwriteGetStringTableText()
    GetStringTableText_Orig_QSB_CatsleStore = XGUIEng.GetStringTableText;
    XGUIEng.GetStringTableText = function(_key)
        local lang = (Network.GetDesiredLanguage() == "de" and "de") or "en";
        local SelectedID = GUI.GetSelectedEntity();
        local PlayerID = GUI.GetPlayerID();
        local CurrentWidgetID = XGUIEng.GetCurrentWidgetID();
        
        if _key == "UI_ObjectNames/DestroyGoods" then
            if XGUIEng.IsWidgetShown("/InGame/Root/Normal/AlignBottomRight/Selection/Castle") == 1 then
                return BundleCastleStore.Local.Description.ShowCastleStore.Text[lang];
            else
                return BundleCastleStore.Local.Description.ShowCastle.Text[lang];
            end
        end
        if _key == "UI_ObjectDescription/DestroyGoods" then
            return "";
        end
        
        if _key == "UI_ObjectNames/CityBuildingsNumber" then
            if Logic.GetHeadquarters(PlayerID) == SelectedID then
                return BundleCastleStore.Local.Description.CityTab.Title[lang];
            end
        end
        if _key == "UI_ObjectDescription/CityBuildingsNumber" then
            if Logic.GetHeadquarters(PlayerID) == SelectedID then
                return BundleCastleStore.Local.Description.CityTab.Text[lang];
            end
        end
        
        if _key == "UI_ObjectNames/B_StoreHouse" then
            if Logic.GetHeadquarters(PlayerID) == SelectedID then
                return BundleCastleStore.Local.Description.StorehouseTab.Title[lang];
            end
        end
        if _key == "UI_ObjectDescription/B_StoreHouse" then
            if Logic.GetHeadquarters(PlayerID) == SelectedID then
                return BundleCastleStore.Local.Description.StorehouseTab.Text[lang];
            end
        end
        
        if _key == "UI_ObjectNames/B_Castle_ME" then
            local WidgetMotherName = "/InGame/Root/Normal/AlignBottomRight/Selection/Storehouse/TabButtons/";
            local WidgetDownButton = WidgetMotherName.. "Tab03Down/down/B_Castle_ME";
            local WidgetUpButton = WidgetMotherName.. "Tab03Up/up/B_Castle_ME";
            if XGUIEng.GetWidgetPathByID(CurrentWidgetID) == WidgetDownButton or XGUIEng.GetWidgetPathByID(CurrentWidgetID) == WidgetUpButton then
                if Logic.GetHeadquarters(PlayerID) == SelectedID then
                    return BundleCastleStore.Local.Description.MultiTab.Title[lang];
                end
            end
        end
        if _key == "UI_ObjectDescription/B_Castle_ME" then
            if Logic.GetHeadquarters(PlayerID) == SelectedID then
                return BundleCastleStore.Local.Description.MultiTab.Text[lang];
            end
        end
        
        if _key == "UI_ButtonDisabled/NotEnoughGoods" then
            if Logic.GetHeadquarters(PlayerID) == SelectedID then
                return BundleCastleStore.Local.Description.GoodButtonDisabled.Text[lang];
            end
        end
        
        return GetStringTableText_Orig_QSB_CatsleStore(_key);
    end
end

---
-- Überschreibt die lokalen Spielfunktionen, die benötigt werden, damit das
-- Burglager funktioniert.
--
-- @within Application-Space
-- @local
--
function BundleCastleStore.Local:OverwriteGameFunctions()
    GameCallback_GUI_SelectionChanged_Orig_QSB_CastleStore = GameCallback_GUI_SelectionChanged;
    GameCallback_GUI_SelectionChanged = function(_Source)
        GameCallback_GUI_SelectionChanged_Orig_QSB_CastleStore(_Source);
        QSB.CastleStore:SelectionChanged(GUI.GetPlayerID());
    end
    
    GUI_Trade.GoodClicked_Orig_QSB_CastleStore = GUI_Trade.GoodClicked;
    GUI_Trade.GoodClicked = function()
        local GoodType = Goods[XGUIEng.GetWidgetNameByID(XGUIEng.GetWidgetsMotherID(XGUIEng.GetCurrentWidgetID()))];
        local SelectedID = GUI.GetSelectedEntity();
        local PlayerID   = GUI.GetPlayerID();
        
        if Logic.IsEntityInCategory(SelectedID, EntityCategories.Storehouse) == 1 then
            GUI_Trade.GoodClicked_Orig_QSB_CastleStore();
            return;
        end
        QSB.CastleStore:GoodClicked(PlayerID, GoodType);
    end
    
    GUI_Trade.DestroyGoodsClicked_Orig_QSB_CastleStore = GUI_Trade.DestroyGoodsClicked;
    GUI_Trade.DestroyGoodsClicked = function()
        local SelectedID = GUI.GetSelectedEntity();
        local PlayerID   = GUI.GetPlayerID();
        
        if Logic.IsEntityInCategory(SelectedID, EntityCategories.Storehouse) == 1 then
            GUI_Trade.DestroyGoodsClicked_Orig_QSB_CastleStore();
            return;
        end
        QSB.CastleStore:DestroyGoodsClicked(PlayerID);
    end
    
    GUI_Trade.SellUpdate_Orig_QSB_CastleStore = GUI_Trade.SellUpdate;
    GUI_Trade.SellUpdate = function()
        local SelectedID = GUI.GetSelectedEntity();
        local PlayerID   = GUI.GetPlayerID();
        
        if Logic.IsEntityInCategory(SelectedID, EntityCategories.Storehouse) == 1 then
            GUI_Trade.SellUpdate_Orig_QSB_CastleStore();
            return;
        end
        QSB.CastleStore:UpdateGoodsDisplay(PlayerID);
    end
    
    GUI_Trade.CityTabButtonClicked_Orig_QSB_CastleStore = GUI_Trade.CityTabButtonClicked;
    GUI_Trade.CityTabButtonClicked = function()
        local SelectedID = GUI.GetSelectedEntity();
        local PlayerID   = GUI.GetPlayerID();
        
        if Logic.IsEntityInCategory(SelectedID, EntityCategories.Storehouse) == 1 then
            GUI_Trade.CityTabButtonClicked_Orig_QSB_CastleStore();
            return;
        end
        QSB.CastleStore:OnCityTabClicked(PlayerID);
    end
    
    GUI_Trade.StorehouseTabButtonClicked_Orig_QSB_CastleStore = GUI_Trade.StorehouseTabButtonClicked;
    GUI_Trade.StorehouseTabButtonClicked = function()
        local SelectedID = GUI.GetSelectedEntity();
        local PlayerID   = GUI.GetPlayerID();
        
        if Logic.IsEntityInCategory(SelectedID, EntityCategories.Storehouse) == 1 then
            GUI_Trade.StorehouseTabButtonClicked_Orig_QSB_CastleStore();
            return;
        end
        QSB.CastleStore:OnStorehouseTabClicked(PlayerID);
    end
    
    GUI_Trade.MultiTabButtonClicked_Orig_QSB_CastleStore = GUI_Trade.MultiTabButtonClicked;
    GUI_Trade.MultiTabButtonClicked = function()
        local SelectedID = GUI.GetSelectedEntity();
        local PlayerID   = GUI.GetPlayerID();
        
        if Logic.IsEntityInCategory(SelectedID, EntityCategories.Storehouse) == 1 then
            GUI_Trade.MultiTabButtonClicked_Orig_QSB_CastleStore();
            return;
        end
        QSB.CastleStore:OnMultiTabClicked(PlayerID);
    end
    
    GUI_BuildingInfo.StorageLimitUpdate_Orig_QSB_CastleStore = GUI_BuildingInfo.StorageLimitUpdate;
    GUI_BuildingInfo.StorageLimitUpdate = function()
        local SelectedID = GUI.GetSelectedEntity();
        local PlayerID   = GUI.GetPlayerID();
        
        if Logic.IsEntityInCategory(SelectedID, EntityCategories.Storehouse) == 1 then
            GUI_BuildingInfo.StorageLimitUpdate_Orig_QSB_CastleStore();
            return;
        end
        QSB.CastleStore:UpdateStorageLimit(PlayerID);
    end
    
    -- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    
    GUI_Interaction.SendGoodsClicked = function()
        local Quest, QuestType = GUI_Interaction.GetPotentialSubQuestAndType(g_Interaction.CurrentMessageQuestIndex);
        if not Quest then
            return;
        end
        local QuestIndex = GUI_Interaction.GetPotentialSubQuestIndex(g_Interaction.CurrentMessageQuestIndex);
        local GoodType = Quest.Objectives[1].Data[1];
        local GoodAmount = Quest.Objectives[1].Data[2];
        local Costs = {GoodType, GoodAmount};
        local CanBuyBoolean, CanNotBuyString = AreCostsAffordable(Costs, true);
        
        local PlayerID = GUI.GetPlayerID();
        if Logic.GetGoodCategoryForGoodType(GoodType) == GoodCategories.GC_Resource then
            CanNotBuyString = XGUIEng.GetStringTableText("Feedback_TextLines/TextLine_NotEnough_Resources");
            CanBuyBoolean = false;
            if QSB.CastleStore:IsLocked(PlayerID, GoodType) then
                CanBuyBoolean = GetPlayerResources(GoodType, PlayerID) >= GoodAmount;
            else
                CanBuyBoolean = (GetPlayerResources(GoodType, PlayerID) + QSB.CastleStore:GetAmount(PlayerID, GoodType)) >= GoodAmount;
            end
        end
        
        local TargetPlayerID = Quest.Objectives[1].Data[6] and Quest.Objectives[1].Data[6] or Quest.SendingPlayer;
        local PlayerSectorType = PlayerSectorTypes.Thief;
        local IsReachable = CanEntityReachTarget(TargetPlayerID, Logic.GetStoreHouse(GUI.GetPlayerID()), Logic.GetStoreHouse(TargetPlayerID), nil, PlayerSectorType);
        if IsReachable == false then
            local MessageText = XGUIEng.GetStringTableText("Feedback_TextLines/TextLine_GenericUnreachable");
            Message(MessageText);
            return
        end
    
        if CanBuyBoolean == true then
            Sound.FXPlay2DSound( "ui\\menu_click");
            GUI.QuestTemplate_SendGoods(QuestIndex);
            GUI_FeedbackSpeech.Add("SpeechOnly_CartsSent", g_FeedbackSpeech.Categories.CartsUnderway, nil, nil);
        else
            Message(CanNotBuyString);
        end
    end
    
    GUI_Tooltip.SetCosts = function(_TooltipCostsContainer, _Costs, _GoodsInSettlementBoolean)
        local TooltipCostsContainerPath = XGUIEng.GetWidgetPathByID(_TooltipCostsContainer);
        local Good1ContainerPath = TooltipCostsContainerPath .. "/1Good";
        local Goods2ContainerPath = TooltipCostsContainerPath .. "/2Goods";
        local NumberOfValidAmounts = 0;
        local Good1Path;
        local Good2Path;
    
        for i = 2, #_Costs, 2 do
            if _Costs[i] ~= 0 then
                NumberOfValidAmounts = NumberOfValidAmounts + 1;
            end
        end
        if NumberOfValidAmounts == 0 then
            XGUIEng.ShowWidget(Good1ContainerPath, 0);
            XGUIEng.ShowWidget(Goods2ContainerPath, 0);
            return
        elseif NumberOfValidAmounts == 1 then
            XGUIEng.ShowWidget(Good1ContainerPath, 1);
            XGUIEng.ShowWidget(Goods2ContainerPath, 0);
            Good1Path = Good1ContainerPath .. "/Good1Of1";
        elseif NumberOfValidAmounts == 2 then
            XGUIEng.ShowWidget(Good1ContainerPath, 0);
            XGUIEng.ShowWidget(Goods2ContainerPath, 1);
            Good1Path = Goods2ContainerPath .. "/Good1Of2";
            Good2Path = Goods2ContainerPath .. "/Good2Of2";
        elseif NumberOfValidAmounts > 2 then
            GUI.AddNote("Debug: Invalid Costs table. Not more than 2 GoodTypes allowed.");
        end
    
        local ContainerIndex = 1;
        for i = 1, #_Costs, 2 do
            if _Costs[i + 1] ~= 0 then
                local CostsGoodType = _Costs[i];
                local CostsGoodAmount = _Costs[i + 1];
                local IconWidget;
                local AmountWidget;
                if ContainerIndex == 1 then
                    IconWidget = Good1Path .. "/Icon";
                    AmountWidget = Good1Path .. "/Amount";
                else
                    IconWidget = Good2Path .. "/Icon";
                    AmountWidget = Good2Path .. "/Amount";
                end
                SetIcon(IconWidget, g_TexturePositions.Goods[CostsGoodType], 44);
                local PlayerID = GUI.GetPlayerID();
                local PlayersGoodAmount;
                if _GoodsInSettlementBoolean == true then
                    PlayersGoodAmount = GetPlayerGoodsInSettlement(CostsGoodType, PlayerID, true);
                    if Logic.GetGoodCategoryForGoodType(CostsGoodType) == GoodCategories.GC_Resource then
                        if not QSB.CastleStore:IsLocked(PlayerID, CostsGoodType) then
                            PlayersGoodAmount = PlayersGoodAmount + QSB.CastleStore:GetAmount(PlayerID, CostsGoodType);
                        end
                    end
                else
                    local IsInOutStock;
                    local BuildingID;
                    if CostsGoodType == Goods.G_Gold then
                        BuildingID = Logic.GetHeadquarters(PlayerID);
                        IsInOutStock = Logic.GetIndexOnOutStockByGoodType(BuildingID, CostsGoodType);
                    else
                        BuildingID = Logic.GetStoreHouse(PlayerID);
                        IsInOutStock = Logic.GetIndexOnOutStockByGoodType(BuildingID, CostsGoodType);
                    end
                    if IsInOutStock ~= -1 then
                        PlayersGoodAmount = Logic.GetAmountOnOutStockByGoodType(BuildingID, CostsGoodType);
                    else
                        BuildingID = GUI.GetSelectedEntity();
                        if BuildingID ~= nil then
                            if Logic.GetIndexOnOutStockByGoodType(BuildingID, CostsGoodType) == nil then
                                BuildingID = Logic.GetRefillerID(GUI.GetSelectedEntity());
                            end
                            PlayersGoodAmount = Logic.GetAmountOnOutStockByGoodType(BuildingID, CostsGoodType);
                        else
                            PlayersGoodAmount = 0;
                        end
                    end
                end
                local Color = "";
                if PlayersGoodAmount < CostsGoodAmount then
                    Color = "{@script:ColorRed}";
                end
                if CostsGoodAmount > 0 then
                    XGUIEng.SetText(AmountWidget, "{center}" .. Color .. CostsGoodAmount);
                else
                    XGUIEng.SetText(AmountWidget, "");
                end
                ContainerIndex = ContainerIndex + 1;
            end
        end
    end
end

-- -------------------------------------------------------------------------- --

Core:RegisterBundle("BundleCastleStore");
