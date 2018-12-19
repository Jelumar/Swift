-- -------------------------------------------------------------------------- --
-- ########################################################################## --
-- #  Symfonia BundleTravelingSalesman                                       # --
-- ########################################################################## --
-- -------------------------------------------------------------------------- --

---
-- Mit diesem Bundle wird ein Fahrender Händler angeboten der periodisch den
-- Hafen mit einem Schiff anfährt. Dabei kann der Fahrtweg frei mit Wegpunkten
-- bestimmt werden. Es können auch mehrere Spieler zu Händlern gemacht werden.
--
-- <p><a href="#API.TravelingSalesmanActivate">Schiffshändler aktivieren</a></p>
--
-- @within Modulbeschreibung
-- @set sort=true
--
BundleTravelingSalesman = {};

API = API or {};
QSB = QSB or {};

QSB.TravelingSalesman = {
	Harbors = {}
};

-- -------------------------------------------------------------------------- --
-- User-Space                                                                 --
-- -------------------------------------------------------------------------- --

---
-- Erstellt einen fahrender Händler mit zufälligen Angeboten.
--
-- Soll immer das selbe angeboten werden, darf nur ein Angebotsblock
-- definiert werden.
-- Es kann mehr als einen fahrender Händler auf der Map geben.
--
-- <b>Alias</b>: ActivateTravelingSalesman
--
-- @param _PlayerID [number] Spieler-ID des Händlers
-- @param _Offers [table] Liste an Angeboten
-- @param _Waypoints [table] Wegpunktliste Anfahrt
-- @param _Reversed [table] Wegpunktliste Abfahrt
-- @param _Appearance [table] Ankunft und Abfahrt
-- @param _RotationMode [boolean] Angebote werden der Reihe nach durchgegangen
-- @within Anwenderfunktionen
--
-- @usage -- Angebote deklarieren
-- local Offers = {
--     {
--         {"G_Gems", 5,},
--         {"G_Iron", 5,},
--         {"G_Beer", 2,},
--     },
--     {
--         {"G_Stone", 5,},
--         {"G_Sheep", 1,},
--         {"G_Cheese", 2,},
--         {"G_Milk", 5,},
--     },
--     {
--         {"G_Grain", 5,},
--         {"G_Broom", 2,},
--         {"G_Sheep", 1,},
--     },
--     {
--         {"U_CatapultCart", 1,},
--         {"U_MilitarySword", 3,},
--         {"U_MilitaryBow", 3,},
--     },
-- };
-- -- Es sind maximal 4 Angebote pro Block erlaubt. Es können Waren, Soldaten
-- -- oder Entertainer angeboten werden. Es wird immer automatisch 1 Block
-- -- selektiert und die ANgebote gesetzt.
--
-- -- Wegpunkte deklarieren
-- local Waypoints = {"WP1", "WP2", "WP3", "WP4"};
-- -- Es gibt nun zwei Möglichkeiten:
-- -- 1. Durch weglassen des Reversed Path werden die Wegpunkte durch das
-- -- Schiff bei der Abfahrt automatisch rückwärts abgefahren.
-- -- 2. Es wird ein anderer Pfad für die Abfahrt deklariert.
--
-- -- Anfahrt und Abfanrtsmonate deklarieren
-- local Appearance = {{4, 6}, {8, 10}};
-- -- Auch hier gibt es 2 Möglichkeiten:
-- -- 1. Neue Anfahrts- und Abfahrtszeiten setzen.
-- -- 2. _Apperance weglassen / nil setzen und den Standard verwenden
-- -- (März bis Mai und August bis Oktober)
--
-- -- Jetzt kann ein fahrender Händler erzeugt werden
-- API.TravelingSalesmanActivate(2, Offers, Waypoints, nil, Appearance);
-- -- Hier ist der Rückweg automatisch die Umkehr des Hinwegs (_Reversed = nil).
--
-- -- _Reversed und _Apperance können in den meisten Fällen immer weggelassen
-- -- bzw. nil sein!
-- API.TravelingSalesmanActivate(2, Offers, Waypoints);
--
function API.TravelingSalesmanActivate(_PlayerID, _Offers, _Waypoints, _Reversed, _Appearance, _RotationMode)
    if GUI then
        API.Log("Can not execute API.TravelingSalesmanActivate in local script!");
        return;
    end
    return new{QSB.TravelingSalesman, _PlayerID}
        :SetOffers(_Offers)
        :SetApproachRoute(_Waypoints)
        :SetReturnRouteRoute(_Reversed)
        :SetApperance(_Appearance)
        :UseOfferRotation(_Flag);
end
ActivateTravelingSalesman = API.TravelingSalesmanActivate;

---
-- Zerstört den fahrender Händler. Der Spieler wird dabei natürlich
-- nicht zerstört.
--
-- <b>Alias</b>: DeactivateTravelingSalesman
--
-- @param _PlayerID [number] Spieler-ID des Händlers
-- @within Anwenderfunktionen
--
-- @usage -- Fahrenden Händler von Spieler 2 löschen
-- API.TravelingSalesmanDeactivate(2)
--
function API.TravelingSalesmanDeactivate(_PlayerID)
    if GUI then
        API.Bridge("API.TravelingSalesmanDeactivate(" .._PlayerID.. ")");
        return;
    end
    QSB.TravelingSalesman:GetInstance(_PlayerID):Dispose();
end
DeactivateTravelingSalesman = API.TravelingSalesmanDeactivate;

---
-- Legt fest, ob die diplomatischen Beziehungen zwischen dem Spieler und dem
-- Hafen überschrieben werden.
--
-- Die diplomatischen Beziehungen werden überschrieben, wenn sich ein Schiff
-- im Hafen befinden und wenn es abreist. Der Hafen ist "Handelspartner", wenn
-- ein Schiff angelegt hat, sonst "Bekannt".
--
-- Bei diplomatischen Beziehungen geringer als "Bekannt", kann es zu Fehlern
-- kommen. Dann werden Handelsangebote angezeigt, konnen aber nicht durch
-- den Spieler erworben werden.
--
-- <b>Hinweis</b>: Standardmäßig als aktiv voreingestellt.
--
-- <b>Alias</b>: TravelingSalesmanDiplomacyOverride
--
-- @param _PlayerID [number] Spieler-ID des Händlers
-- @param _Flag [boolean] Diplomatie überschreiben
-- @within Anwenderfunktionen
--
-- @usage -- Spieler 2 überschreibt nicht mehr die Diplomatie
-- API.TravelingSalesmanDiplomacyOverride(2, false)
--
function API.TravelingSalesmanDiplomacyOverride(_PlayerID, _Flag)
    if GUI then
        API.Bridge("API.TravelingSalesmanDiplomacyOverride(" .._PlayerID.. ", " ..tostring(_Flag).. ")");
        return;
    end
    QSB.TravelingSalesman:GetInstance(_PlayerID):UseChangeDiplomacy(_Flag);
end
TravelingSalesmanDiplomacyOverride = API.TravelingSalesmanDiplomacyOverride;

---
-- Legt fest, ob die Angebote der Reihe nach durchgegangen werden (beginnt von
-- vorn, wenn am Ende angelangt) oder zufällig ausgesucht werden.
--
-- <b>Alias</b>: TravelingSalesmanRotationMode
--
-- @param _PlayerID [number] Spieler-ID des Händlers
-- @param _Flag [boolean] Angebotsrotation einschalten
-- @within Anwenderfunktionen
--
-- @usage -- Spieler 2 geht Angebote der Reihe nach durch.
-- API.TravelingSalesmanRotationMode(2, true)
--
function API.TravelingSalesmanRotationMode(_PlayerID, _Flag)
    if GUI then
        API.Bridge("API.TravelingSalesmanRotationMode(" .._PlayerID.. ", " ..tostring(_Flag).. ")");
        return;
    end
    QSB.TravelingSalesman:GetInstance(_PlayerID):UseOfferRotation(_Flag);
end
TravelingSalesmanRotationMode = API.TravelingSalesmanRotationMode;

-- -------------------------------------------------------------------------- --
-- Application-Space                                                          --
-- -------------------------------------------------------------------------- --

BundleTravelingSalesman = {
    Global = {
        Data = {},
    },
};

-- Global Script ---------------------------------------------------------------

---
-- Initialisiert das Bundle im globalen Skript.
-- @within Internal
-- @local
--
function BundleTravelingSalesman.Global:Install()
    StartSimpleJobEx(BundleTravelingSalesman.Global.TravelingSalesmanController);
end

---
-- Ruft die Loop-Funktion aller Fahrenden Händler auf.
-- @within Internal
-- @local
--
function BundleTravelingSalesman.Global.TravelingSalesmanController()
    for i= 1, 8, 1 do
        if QSB.TravelingSalesman:GetInstance(i) then
            QSB.TravelingSalesman:GetInstance(i):Loop();
        end
    end
end

-- Klassen ------------------------------------------------------------------ --

QSB.TravelingSalesmanInstances = {};

---
-- Diese Klasse definiert den Fahrenden Händler.
-- @within Klassen
-- @local
--
QSB.TravelingSalesman = class {
    ---
    -- Konstruktor
    -- @param[type=number] _PlayerID Player-ID des Händlers
    -- @within QSB.TravelingSalesman
    -- @local
    --
    construct = function(self, _PlayerID)
        self.m_PlayerID = _PlayerID;
        self.m_Offers = {};
        self.m_Appearance = {{3, 5}, {7, 9}};
        self.m_Waypoints = {};
        self.m_Reversed = {};
        self.m_ChangeDiplomacy = true;
        self.m_OfferRotation = false;
        self.m_LastOffer = 0;
        self.m_Status = 0;

        QSB.TravelingSalesmanInstances[_PlayerID] = self;
    end
}

---
-- Gibt die Instanz des Fahrenden Händlers für die Player-ID zurück.
--
-- Sollte keine Instanz für den Spieler existieren, wird eine Null-Instanz
-- erzeugt und zurückgegeben.
--
-- @param[type=number] _PlayerID Player-ID des Händlers
-- @return[type=table] Instanz
-- @within QSB.TravelingSalesman
-- @local
--
function QSB.TravelingSalesman:GetInstance(_PlayerID)
    if QSB.TravelingSalesmanInstances[_PlayerID] then
        return QSB.TravelingSalesmanInstances[_PlayerID];
    end
    local NullInstance = new{QSB.TravelingSalesman, _PlayerID};
    NullInstance.SymfoniaDebugValue_NullInstance = true;
    return NullInstance;
end

---
-- Gibt die ID des ersten aktiven menschlichen Spielers zurück.
-- @return[type=number] Player-ID
-- @within QSB.TravelingSalesman
-- @local
--
function QSB.TravelingSalesman:GetHumanPlayer()
    for i= 1, 8, 1 do
        if Logic.PlayerGetIsHumanFlag(1) == true then
            return i;
        end
    end
    return 0;
end

---
-- Entfernt alle Angebotsblöcke des Fahrenden Händlers.
-- @return[type=table] self
-- @within QSB.TravelingSalesman
-- @local
--
function QSB.TravelingSalesman:ClearOffers()
    return self:SetOffers({});
end

---
-- Setzt eine Liste von Angebotsblöcken für den Fahrenden Händler.
-- @param[type=table] _Offers Definierte Angebotsblöcke
-- @return[type=table] self
-- @within QSB.TravelingSalesman
-- @local
--
function QSB.TravelingSalesman:SetOffers(_Offers)
    self.m_Offers = _Offers;
    return self;
end

---
-- Fügt dem Fahrenden Händler einen Angebotsblock hinzu. Es wird zuerst der
-- Warentyp als String und danach die Anzahl angegeben.
-- @return[type=table] self
-- @within QSB.TravelingSalesman
-- @local
--
function QSB.TravelingSalesman:AddOffer(...)
    local Offer = {};
    for i= 1, #arg, 2 do
        table.insert(Offer, {arg[i], arg[i+1]});
    end
    table.insert(self.m_Offers, Offer);
    return self;
end

---
-- Löscht die Aufenthaltszeitspanne des Fahrenden Händlers.
-- @return[type=table] self
-- @within QSB.TravelingSalesman
-- @local
--
function QSB.TravelingSalesman:ClearApperance()
    return self:SetApperance({});
end

---
-- Fügt einen Zeitraum zur Aufenthalt des Fliegenden Händlers hinzu. Ein
-- Zeitraum besteht aus Startmonat und Endmonat.
-- @return[type=table] self
-- @within QSB.TravelingSalesman
-- @local
--
function QSB.TravelingSalesman:AddApperance(_Start, _End)
    table.insert(self.m_Appearance, {_Start, _End});
    return self;
end

---
-- Setzt die Aufenthaltszeitspanne des Fliegenden Händlers
-- @param[type=table] _Apperance Aufenthaltszeitspanne
-- @return[type=table] self
-- @within QSB.TravelingSalesman
-- @local
--
function QSB.TravelingSalesman:SetApperance(_Apperance)
    self.m_Appearance = _Apperance or self.m_Appearance;
    return self;
end

---
-- Setzt die Route für die Ankunft des Fahrenden Händlers.
-- @param[type=table] _List Liste der Wegpunkte
-- @return[type=table] self
-- @within QSB.TravelingSalesman
-- @local
--
function QSB.TravelingSalesman:SetApproachRoute(_List)
    self.m_Waypoints = copy(_List);
    self.m_SpawnPos = self.m_Waypoints[1];
    self.m_Destination = self.m_Waypoints[#_List];
    return self;
end

---
-- Setzt die Wegpunkte für die Abfahrt des Fliegenden Händlers. Ist die Liste
-- nil, werden die Wegpunkte für die Anfahrt invertiert.
-- @param[type=table] _List Liste der Wegpunkte
-- @return[type=table] self
-- @within QSB.TravelingSalesman
-- @local
--
function QSB.TravelingSalesman:SetReturnRouteRoute(_List)
    local Reversed = _List;
    if type(Reversed) ~= "table" then
        Reversed = {};
        for i= #self.m_Waypoints, 1, -1 do
            table.insert(Reversed, self.m_Waypoints[i]);
        end
    end
    self.m_Reversed = copy(Reversed);
    return self;
end

---
-- Aktiviert oder deaktiviert die sequentielle Abarbeitung der Angebote dieses
-- Fliegenden Händlers.
-- @param[type=boolean] _Flag Angebote sequenziell durchlaufen
-- @return[type=table] self
-- @within QSB.TravelingSalesman
-- @local
--
function QSB.TravelingSalesman:UseOfferRotation(_Flag)
    self.m_OfferRotation = _Flag == true;
    return self;
end

---
-- Aktiviert oder deaktiviert die automatische Anpasung der Diplomatie.
-- @param[type=boolean] _Flag Diplomatie wird überschrieben
-- @return[type=table] self
-- @within QSB.TravelingSalesman
-- @local
--
function QSB.TravelingSalesman:UseChangeDiplomacy(_Flag)
    self.m_ChangeDiplomacy = _Flag == true;
    return self;
end

---
-- Invalidiert die Instanz dieses Fliegenden Händlers.
-- @within QSB.TravelingSalesman
-- @local
--
function QSB.TravelingSalesman:Dispose()
    Logic.RemoveAllOffers(Logic.GetStoreHouse(self.m_PlayerID));
    DestroyEntity("TravelingSalesmanShip_Player" ..self.m_PlayerID);
    QSB.TravelingSalesmanInstances[self.m_PlayerID] = nil;
end

---
-- Gibt einen Block Angebote für diesen Fahrenden Händler zurück.
-- @return[type=table] Angebote
-- @within QSB.TravelingSalesman
-- @local
--
function QSB.TravelingSalesman:NextOffer()
    local NextOffer;
    if self.m_OfferRotation then
        self.m_LastOffer = self.m_LastOffer +1;
        if self.m_LastOffer > #self.m_Offers then
            self.m_LastOffer = 1;
        end
        NextOffer = self.m_Offers[self.m_LastOffer];
    else
        local RandomIndex = 1;
        if #self.m_Offers > 1 then
            repeat
                RandomIndex = math.random(1,#self.m_Offers);
            until (RandomIndex ~= self.m_LastOffer);
        end
        self.m_LastOffer = RandomIndex;
        NextOffer = self.m_Offers[self.m_LastOffer];
    end
    return NextOffer;
end

---
-- Zeigt die Info-Nachricht an, wenn ein Schiff im Hafen anlegt.
-- @return[type=table] self
-- @within QSB.TravelingSalesman
-- @local
--
function QSB.TravelingSalesman:DisplayInfoMessage()
    if ((IsBriefingActive and not IsBriefingActive()) or true) then
        local InfoQuest = Quests[GetQuestID("TravelingSalesman_Info_P" ..self.m_PlayerID)];
        if InfoQuest then
            API.RestartQuest("TravelingSalesman_Info_P" ..self.m_PlayerID, true);
            InfoQuest:SetMsgKeyOverride();
            InfoQuest:SetIconOverride();
            InfoQuest:Trigger();
            return self;
        end

        local lang = (Network.GetDesiredLanguage() == "de" and "de") or "en";
        local Text = { de = "Ein Schiff hat angelegt. Es bringt Güter von weit her.",
                       en = "A ship is at the pier. It deliver goods from far away."};
        QuestTemplate:New(
            "TravelingSalesman_Info_P" ..self.m_PlayerID,
            self.m_PlayerID,
            self:GetHumanPlayer(),
            {{ Objective.Dummy,}},
            {{ Triggers.Time, 0 }},
            0,
            nil, nil, nil, nil, false, true,
            nil, nil,
            Text[lang],
            nil
        );
    end
    return self;
end

---
-- Fügt dem Fahrenden Händler ein neues Angebot hinzu.
-- @return[type=table] self
-- @within QSB.TravelingSalesman
-- @local
--
function QSB.TravelingSalesman:IntroduceNewOffer()
    MerchantSystem.TradeBlackList[self.m_PlayerID] = {};
    MerchantSystem.TradeBlackList[self.m_PlayerID][0] = #MerchantSystem.TradeBlackList[3];

    local traderId = Logic.GetStoreHouse(self.m_PlayerID);
    local offer = self:NextOffer();
    Logic.RemoveAllOffers(traderId);

    if #offer > 0 then
        for i=1,#offer,1 do
            local offerType = offer[i][1];
            local isGoodType = false;
            for k,v in pairs(Goods)do
                if k == offerType then
                    isGoodType = true;
                end
            end

            if isGoodType then
                local amount = offer[i][2];
                AddOffer(traderId,amount,Goods[offerType], 9999);
            else
                if Logic.IsEntityTypeInCategory(Entities[offerType],EntityCategories.Military)== 0 then
                    AddEntertainerOffer(traderId,Entities[offerType]);
                else
                    local amount = offer[i][2];
                    AddMercenaryOffer(traderId,amount,Entities[offerType], 9999);
                end
            end
        end
    end
    if self.m_ChangeDiplomacy then
        SetDiplomacyState(self:GetHumanPlayer(), self.m_PlayerID, DiplomacyStates.TradeContact);
    end
    Logic.SetTraderPlayerState(Logic.GetStoreHouse(self.m_PlayerID), self:GetHumanPlayer(), 1);
    return self;
end

---
-- Steuert den Ablauf des fliegenden Händlers.
-- @return[type=table] self
-- @within QSB.TravelingSalesman
-- @local
--
function QSB.TravelingSalesman:Loop()
    if not self.SymfoniaDebugValue_NullInstance and Logic.PlayerGetIsHumanFlag(self.m_PlayerID) == false then
        if self.m_Status == 0 then
            local month = Logic.GetCurrentMonth();
            local start = false;
            for i=1, #self.m_Appearance,1 do
                if month == self.m_Appearance[i][1] then
                    start = true;
                end
            end
            if start then
                local orientation = Logic.GetEntityOrientation(GetID(self.m_SpawnPos))
                local ID = CreateEntity(0, Entities.D_X_TradeShip, GetPosition(self.m_SpawnPos), "TravelingSalesmanShip_Player" ..self.m_PlayerID, orientation);
                Path:new(ID,self.m_Waypoints, nil, nil, nil, nil, true, nil, nil, 300);
                self.m_Status = 1;
            end

        elseif self.m_Status == 1 then
            if IsNear("TravelingSalesmanShip_Player" ..self.m_PlayerID, self.m_Destination, 400) then
                self:IntroduceNewOffer():DisplayInfoMessage();
                self.m_Status = 2;
            end
            
        elseif self.m_Status == 2 then
            local month = Logic.GetCurrentMonth();
            local stop = false;
            for i=1, #self.m_Appearance,1 do
                if month == self.m_Appearance[i][2] then
                    stop = true;
                end
            end

            if stop then
                if self.m_ChangeDiplomacy then
                    SetDiplomacyState(self:GetHumanPlayer(), self.m_PlayerID, DiplomacyStates.EstablishedContact);
                end
                Path:new(GetID("TravelingSalesmanShip_Player" ..self.m_PlayerID), self.m_Reversed, nil, nil, nil, nil, true, nil, nil, 300);
                Logic.RemoveAllOffers(Logic.GetStoreHouse(self.m_PlayerID));
                self.m_Status = 3;
            end

        elseif self.m_Status == 3 then
            if IsNear("TravelingSalesmanShip_Player" ..self.m_PlayerID, self.m_SpawnPos, 400) then
                DestroyEntity("TravelingSalesmanShip_Player" ..self.m_PlayerID);
                self.m_Status = 0;
            end
        end
    end
    return self;
end

-- -------------------------------------------------------------------------- --

Core:RegisterBundle("BundleTravelingSalesman");
