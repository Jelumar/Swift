-- -------------------------------------------------------------------------- --
-- ########################################################################## --
-- #  Synfonia ClassicBehaviorBundle                                        # --
-- ########################################################################## --
-- -------------------------------------------------------------------------- --

---
--
--
-- @module ClassicBehaviorBundle
--

API = API or {};
QSB = QSB or {};

-- -------------------------------------------------------------------------- --
-- User Space                                                                 --
-- -------------------------------------------------------------------------- --



-- -------------------------------------------------------------------------- --
-- Goals                                                                      --
-- -------------------------------------------------------------------------- --

---
-- Ein Interaktives Objekt muss benutzt werden.
--
-- @param _ScriptName Skriptname des interaktiven Objektes
-- @return table: Behavior
-- @within Goals
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

function b_Goal_ActivateObject:GetGoalTable(__quest_)
    return {Objective.Object, { self.ScriptName } }
end

function b_Goal_ActivateObject:AddParameter(__index_, __parameter_)
   if __index_ == 0 then
        self.ScriptName = __parameter_
   end
end

function b_Goal_ActivateObject:GetMsgKey()
    return "Quest_Object_Activate"
end

AddQuestBehavior(b_Goal_ActivateObject);

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
-- @return table: Behavior
-- @within Goals
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
        { ParameterType.Custom, en = "To different player", de = "Anderer Empfaenger" },
        { ParameterType.Custom, en = "Ignore capture", de = "Abfangen ignorieren" },
    },
}


function b_Goal_Deliver:GetGoalTable(__quest_)
    local GoodType = Logic.GetGoodTypeID(self.GoodTypeName)
    return { Objective.Deliver, GoodType, self.GoodAmount, self.OverrideTarget, self.IgnoreCapture }
end

function b_Goal_Deliver:AddParameter(__index_, __parameter_)
    if (__index_ == 0) then
        self.GoodTypeName = __parameter_
    elseif (__index_ == 1) then
        self.GoodAmount = __parameter_ * 1
    elseif (__index_ == 2) then
        self.OverrideTarget = tonumber(__parameter_)
    elseif (__index_ == 3) then
        self.IgnoreCapture = AcceptAlternativeBoolean(__parameter_)
    end
end

function b_Goal_Deliver:GetCustomData( __index_ )
    local Data = {}
    if __index_ == 0 then
        for k, v in pairs( Goods ) do
            if string.find( k, "^G_" ) then
                table.insert( Data, k )
            end
        end
        table.sort( Data )
    elseif __index_ == 2 then
        table.insert( Data, "-" )
        for i = 1, 8 do
            table.insert( Data, i )
        end
    elseif __index_ == 3 then
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

AddQuestBehavior(b_Goal_Deliver);

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
-- @return table: Behavior
-- @within Goals
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

function b_Goal_Diplomacy:GetGoalTable(__quest_)
    return { Objective.Diplomacy, self.PlayerID, DiplomacyStates[self.DiplState] }
end

function b_Goal_Diplomacy:AddParameter(__index_, __parameter_)
    if (__index_ == 0) then
        self.PlayerID = __parameter_ * 1
    elseif (__index_ == 1) then
        self.DiplState = __parameter_
    end
end

function b_Goal_Diplomacy:GetIcon()
    return {6,3};
end

AddQuestBehavior(b_Goal_Diplomacy);

-- -------------------------------------------------------------------------- --

---
-- Das Heimatterritorium des Spielers muss entdeckt werden.
--
-- Das Heimatterritorium ist immer das, wo sich Burg oder Lagerhaus der
-- zu entdeckenden Partei befinden.
--
-- @param _PlayerID ID der zu entdeckenden Partei
-- @returns table: Behavior
-- @within Goals
--
function Goal_DiscoverPlayer(...)
    return b_Goal_DiscoverPlayerN.new(...);
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

function b_Goal_DiscoverPlayer:AddParameter(__index_, __parameter_)
    if (__index_ == 0) then
        self.PlayerID = __parameter_ * 1
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

AddQuestBehavior(b_Goal_DiscoverPlayer);

-- -------------------------------------------------------------------------- --

---
-- Ein Territorium muss erstmalig vom Auftragnehmer betreten werden.
--
-- @param _Territory Name oder ID des Territorium
-- @return table: Behavior
-- @within Goals
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

function b_Goal_DiscoverTerritory:AddParameter(__index_, __parameter_)
    if (__index_ == 0) then
        self.TerritoryID = tonumber(__parameter_)
        if not self.TerritoryID then
            self.TerritoryID = GetTerritoryIDByName(__parameter_)
        end
        assert( self.TerritoryID > 0 )
    end
end

function b_Goal_DiscoverTerritory:GetMsgKey()
    return "Quest_Discover_Territory"
end

AddQuestBehavior(b_Goal_DiscoverTerritory);

-- -------------------------------------------------------------------------- --

---
-- Eine andere Partei muss besiegt werden.
--
-- Die Partei gilt als besiegt, wenn ein Hauptgebäude (Burg, Kirche, Lager)
-- zerstört wurde. Achtung: Funktioniert nicht bei Banditen!
--
-- @return table: Behavior
-- @within Goals
--
function Goal_DestroyPlayer(...)
    return b_Goal_DestroyPlayer:new(...);
end

b_Goal_DestroyPlayer = {
    Name = "Goal_DestroyPlayer",
    Description = {
        en = "Goal: Destroy a player (destroy a main building)",
        de = "Ziel: Zerstoere einen Spieler (ein Hauptgebaeude muss zerstoert werden).",
    },
    Parameter = {
        { ParameterType.PlayerID, en = "Player", de = "Spieler" },
    },
}

function b_Goal_DestroyPlayer:GetGoalTable()
    assert( self.PlayerID <= 8 and self.PlayerID >= 1, "Error in " .. self.Name .. ": GetGoalTable: PlayerID is invalid")
    return { Objective.DestroyPlayers, self.PlayerID }
end

function b_Goal_DestroyPlayer:AddParameter(__index_, __parameter_)
    if (__index_ == 0) then
        self.PlayerID = __parameter_ * 1
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

AddQuestBehavior(b_Goal_DestroyPlayer)

-- -------------------------------------------------------------------------- --

---
-- Es sollen Informationen aus der Burg gestohlen werden.
--
-- Der Spieler muss einen Dieb entsenden um Informationen aus der Burg zu
-- stehlen. Achtung: Das ist nur bei Feinden möglich!
--
-- @param _PlayerID ID der Partei
-- @return table: Behavior
-- @within Goals
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

function b_Goal_StealInformation:AddParameter(__index_, __parameter_)

    if (__index_ == 0) then
        self.PlayerID = __parameter_ * 1
    end

end

function b_Goal_StealInformation:GetMsgKey()
    return "Quest_Steal_Info"

end

AddQuestBehavior(b_Goal_StealInformation);

-- -------------------------------------------------------------------------- --

---
-- Alle Einheiten des Spielers müssen zerstört werden.
--
-- @param _PlayerID ID des Spielers
-- @return table: Behavior
-- @within Goals
--
function Goal_DestroyAllPlayerUnits(...)
    return b_Goal_DestroyAllPlayerUnits:new(...);
end

b_Goal_DestroyAllPlayerUnits = {
    Name = "Goal_DestroyAllPlayerUnits",
    Description = {
        en = "Goal: Destroy all units owned by player (be careful with script entities)",
        de = "Ziel: Zerstoere alle Einheiten eines Spielers (vorsicht mit Script-Entities)",
    },
    Parameter = {
        { ParameterType.PlayerID, en = "Player", de = "Spieler" },
    },
}

function b_Goal_DestroyAllPlayerUnits:GetGoalTable()
    return { Objective.DestroyAllPlayerUnits, self.PlayerID }
end

function b_Goal_DestroyAllPlayerUnits:AddParameter(__index_, __parameter_)
    if (__index_ == 0) then
        self.PlayerID = __parameter_ * 1
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

AddQuestBehavior(b_Goal_DestroyAllPlayerUnits);

-- -------------------------------------------------------------------------- --

---
-- Ein benanntes Entity muss zerstört werden.
--
-- @param _ScriptName Skriptname des Ziels
-- @return table: Behavior
-- @within Goals
--
function Goal_DestroyScriptEntity(...)
    return b_Goal_DestroyScriptEntity:new(...);
end

b_Goal_DestroyScriptEntity = {
    Name = "Goal_DestroyScriptEntity",
    Description = {
        en = "Goal: Destroy an entity",
        de = "Ziel: Zerstoere eine Entitaet",
    },
    Parameter = {
        { ParameterType.ScriptName, en = "Script name", de = "Skriptname" },
    },
}

function b_Goal_DestroyScriptEntity:GetGoalTable()
    return {Objective.DestroyEntities, 1, { self.ScriptName } }
end

function b_Goal_DestroyScriptEntity:AddParameter(__index_, __parameter_)
    if (__index_ == 0) then
        self.ScriptName = __parameter_
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

AddQuestBehavior(b_Goal_DestroyScriptEntity);

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
-- @return table: Behavior
-- @within Goals
--
function Goal_DestroyType(...)
    return b_Goal_DestroyType:new(...);
end

b_Goal_DestroyType = {
    Name = "Goal_DestroyType",
    Description = {
        en = "Goal: Destroy entity types",
        de = "Ziel: Zerstoere Entitaetstypen",
    },
    Parameter = {
        { ParameterType.Custom, en = "Type name", de = "Typbezeichnung" },
        { ParameterType.Number, en = "Amount", de = "Anzahl" },
        { ParameterType.Custom, en = "Player", de = "Spieler" },
    },
}

function b_Goal_DestroyType:GetGoalTable(__quest_)
    return {Objective.DestroyEntities, 2, Entities[self.EntityName], self.Amount, self.PlayerID }
end

function b_Goal_DestroyType:AddParameter(__index_, __parameter_)
    if (__index_ == 0) then
        self.EntityName = __parameter_
    elseif (__index_ == 1) then
        self.Amount = __parameter_ * 1
        self.DestroyTypeAmount = self.Amount
    elseif (__index_ == 2) then
        self.PlayerID = __parameter_ * 1
    end
end

function b_Goal_DestroyType:GetCustomData( __index_ )
    local Data = {}
    if __index_ == 0 then
        for k, v in pairs( Entities ) do
            if string.find( k, "^[ABU]_" ) then
                table.insert( Data, k )
            end
        end
        table.sort( Data )
    elseif __index_ == 2 then
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

AddQuestBehavior(b_Goal_DestroyType);

-- -------------------------------------------------------------------------- --
-- Reprisal                                                                   --
-- -------------------------------------------------------------------------- --

---
-- Deaktiviert ein interaktives Objekt
--
-- @param _ScriptName Skriptname des interaktiven Objektes
-- @return table: Behavior
-- @within Reprisals
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

function b_Reprisal_ObjectDeactivate:AddParameter(__index_, __parameter_)

    if (__index_ == 0) then
        self.ScriptName = __parameter_
    end

end

function b_Reprisal_ObjectDeactivate:CustomFunction(__quest_)
    InteractiveObjectDeactivate(self.ScriptName);
end

function b_Reprisal_ObjectDeactivate:DEBUG(__quest_)
    if not Logic.IsInteractiveObject(GetID(self.ScriptName)) then
        local text = string.format("%s Reprisal_ObjectDeactivate: '%s' is not a interactive object!", __quest_.Identifier, self.ScriptName);
        self.WarningPrinted = true;
        warn(text);
    end
    local eID = GetID(self.ScriptName);
    if QSB.InitalizedObjekts[eID] and QSB.InitalizedObjekts[eID] == __quest_.Identifier then
        dbg(""..__quest_.Identifier.." "..self.Name..": you can not deactivate in the same quest the object is initalized!");
        return true;
    end
    return false;
end

AddQuestBehavior(b_Reprisal_ObjectDeactivate);

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
-- @return table: Behavior
-- @within Reprisals
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

function b_Reprisal_ObjectActivate:AddParameter(__index_, __parameter_)
    if (__index_ == 0) then
        self.ScriptName = __parameter_
    elseif (__index_ == 1) then
        local parameter = 0
        if __parameter_ == "Always" or 1 then
            parameter = 1
        end
        self.UsingState = parameter
    end
end

function b_Reprisal_ObjectActivate:CustomFunction(__quest_)
    InteractiveObjectActivate(self.ScriptName, self.UsingState);
end

function b_Reprisal_ObjectActivate:GetCustomData( __index_ )
    if __index_ == 1 then
        return {"Knight only", "Always"}
    end
end

function b_Reprisal_ObjectActivate:DEBUG(__quest_)
    if not Logic.IsInteractiveObject(GetID(self.ScriptName)) then
        local text = string.format("%s Goal_IO_ObjectActivate: '%s' is not a interactive object!", __quest_.Identifier, self.ScriptName);
        self.WarningPrinted = true;
        warn(text);
    end
    local eID = GetID(self.ScriptName);
    if QSB.InitalizedObjekts[eID] and QSB.InitalizedObjekts[eID] == __quest_.Identifier then
        dbg(""..__quest_.Identifier.." "..self.Name..": you can not activate in the same quest the object is initalized!");
        return true;
    end
    return false;
end

AddQuestBehavior(b_Reprisal_ObjectActivate);

-- -------------------------------------------------------------------------- --

---
-- Der diplomatische Status zwischen Sender und Empfänger verschlechtert sich
-- um eine Stufe.
--
-- @return table: Behavior
-- @within Reprisals
--
function Reprisal_DiplomacyDecrease(...)
    return b_Reprisal_DiplomacyDecrease:new(...);
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

function b_Reprisal_DiplomacyDecrease:CustomFunction(__quest_)
    local Sender = __quest_.SendingPlayer;
    local Receiver = __quest_.ReceivingPlayer;
    local State = GetDiplomacyState(Receiver, Sender);
    if State > -2 then
        SetDiplomacyState(Receiver, Sender, State-1);
    end
end

function b_Reprisal_DiplomacyDecrease:AddParameter(__index_, __parameter_)
    if (__index_ == 0) then
        self.PlayerID = __parameter_ * 1
    end
end

AddQuestBehavior(b_Reprisal_DiplomacyDecrease);

-- -------------------------------------------------------------------------- --

---
-- Änder den Diplomatiestatus zwischen zwei Spielern.
--
-- @param _Party1   ID der ersten Partei
-- @param _Party2   ID der zweiten Partei
-- @param _State    Neuer Diplomatiestatus
-- @return table: Behavior
-- @within Reprisals
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

function b_Reprisal_Diplomacy:AddParameter(__index_, __parameter_)
    if (__index_ == 0) then
        self.PlayerID1 = __parameter_ * 1
    elseif (__index_ == 1) then
        self.PlayerID2 = __parameter_ * 1
    elseif (__index_ == 2) then
        self.Relation = DiplomacyStates[__parameter_]
    end
end

function b_Reprisal_Diplomacy:CustomFunction(__quest_)
    SetDiplomacyState(self.PlayerID1, self.PlayerID2, self.Relation);
end

function b_Reprisal_Diplomacy:DEBUG(__quest_)
    if not tonumber(self.PlayerID1) or self.PlayerID1 < 1 or self.PlayerID1 > 8 then
        dbg(__quest_.Identifier .. " " .. self.Name .. ": PlayerID 1 is invalid!");
        return true;
    elseif not tonumber(self.PlayerID2) or self.PlayerID2 < 1 or self.PlayerID2 > 8 then
        dbg(__quest_.Identifier .. " " .. self.Name .. ": PlayerID 2 is invalid!");
        return true;
    elseif not tonumber(self.Relation) or self.Relation < -2 or self.Relation > 2 then
        dbg(__quest_.Identifier .. " " .. self.Name .. ": '"..self.Relation.."' is a invalid diplomacy state!");
        return true;
    end
    return false;
end

AddQuestBehavior(b_Reprisal_Diplomacy);

-- -------------------------------------------------------------------------- --



-- -------------------------------------------------------------------------- --
-- Rewards                                                                    --
-- -------------------------------------------------------------------------- --

---
-- Deaktiviert ein interaktives Objekt
--
-- @param _ScriptName Skriptname des interaktiven Objektes
-- @return table: Behavior
-- @within Rewards
--
function Reward_ObjectDeactivate(...)
    return b_Reward_ObjectDeactivate:new(...);
end

b_Reward_ObjectDeactivate = API.InstanceTable(b_Reprisal_ObjectDeactivate);
b_Reward_ObjectDeactivate.Name             = "Reward_ObjectDeactivate";
b_Reward_ObjectDeactivate.Description.de   = "Reward: Deactivates an interactive object";
b_Reward_ObjectDeactivate.Description.en   = "Lohn: Deaktiviert ein interaktives Objekt";
b_Reward_ObjectDeactivate.GetReprisalTable = nil;

b_Reward_ObjectDeactivate.GetRewardTable = function(self)
    return { Reward.Custom,{self, self.CustomFunction} }
end

AddQuestBehavior(b_Reprisal_ObjectDeactivate);

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
-- @return table: Behavior
-- @within Rewards
--
function Reward_ObjectActivate(...)
    return Reward_ObjectActivate:new(...);
end

b_Reward_ObjectActivate = API.InstanceTable(b_Reprisal_ObjectActivate);
b_Reward_ObjectActivate.Name             = "Reward_ObjectActivate";
b_Reward_ObjectActivate.Description.de   = "Reward: Activates an interactive object";
b_Reward_ObjectActivate.Description.en   = "Lohn: Aktiviert ein interaktives Objekt";
b_Reward_ObjectActivate.GetReprisalTable = nil;

b_Reward_ObjectActivate.GetRewardTable = function(self)
    return { Reward.Custom,{self, self.CustomFunction} };
end

AddQuestBehavior(b_Reward_ObjectActivate);

-- -------------------------------------------------------------------------- --

---
-- Initialisiert ein interaktives Objekt.
--
-- Interaktive Objekte können Kosten und Belohnungen enthalten, müssen sie
-- jedoch nicht. Ist eine Wartezeit angegeben, kann das Objekt erst nach
-- Ablauf eines Cooldowns benutzt werden.
--
-- @param _ScriptName    Skriptname des interaktiven Objektes
-- @param _Distance      Entfernung zur Aktivierung
-- @param _Time          Wartezeit bis zur Aktivierung
-- @param _RewType1      Warentyp der Belohnung
-- @param _RewAmount     Menge der Belohnung
-- @param _CostType1     Typ der 1. Ware
-- @param _CostAmount1   Menge der 1. Ware
-- @param _CostType2     Typ der 2. Ware
-- @param _CostAmount2   Menge der 2. Ware
-- @param _Status        Aktivierung (0: Held, 1: immer, 2: niemals)
-- @return table: Behavior
-- @within Rewards
--
function Reward_ObjectInit(...)
    return Reward_ObjectInit:new(...);
end

b_Reward_ObjectInit = {
    Name = "Reward_ObjectInit",
    Description = {
        en = "Reward: Setup an interactive object with costs and rewards.",
        de = "Lohn: Initialisiert ein interaktives Objekt mit seinen Kosten und Schaetzen.",
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

function b_Reward_ObjectInit:AddParameter(__index_, __parameter_)
    if (__index_ == 0) then
        self.ScriptName = __parameter_
    elseif (__index_ == 1) then
        self.Distance = __parameter_ * 1
    elseif (__index_ == 2) then
        self.Waittime = __parameter_ * 1
    elseif (__index_ == 3) then
        self.RewardType = __parameter_
    elseif (__index_ == 4) then
        self.RewardAmount = tonumber(__parameter_)
    elseif (__index_ == 5) then
        self.FirstCostType = __parameter_
    elseif (__index_ == 6) then
        self.FirstCostAmount = tonumber(__parameter_)
    elseif (__index_ == 7) then
        self.SecondCostType = __parameter_
    elseif (__index_ == 8) then
        self.SecondCostAmount = tonumber(__parameter_)
    elseif (__index_ == 9) then
        local parameter = nil
        if __parameter_ == "Always" or 1 then
            parameter = 1
        elseif __parameter_ == "Never" or 2 then
            parameter = 2
        elseif __parameter_ == "Knight only" or 0 then
            parameter = 0
        end
        self.UsingState = parameter
    end
end

function b_Reward_ObjectInit:CustomFunction(__quest_)
    local eID = GetID(self.ScriptName);
    if eID == 0 then
        return;
    end
    QSB.InitalizedObjekts[eID] = __quest_.Identifier;

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

function b_Reward_ObjectInit:GetCustomData( __index_ )
    if __index_ == 3 or __index_ == 5 or __index_ == 7 then
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
    elseif __index_ == 9 then
        return {"-", "Knight only", "Always", "Never",}
    end
end

function b_Reward_ObjectInit:DEBUG(__quest_)
    if Logic.IsInteractiveObject(GetID(self.ScriptName)) == false then
        dbg("Reward_ObjectInit "..__quest_.Identifier..": '"..self.ScriptName.."' is not a interactive object!");
        return true;
    end
    if self.UsingState ~= 1 and self.Distance < 50 then
        warn(""..__quest_.Identifier.." "..self.Name..": distance is maybe too short!");
    end
    if self.Waittime < 0 then
        dbg(""..__quest_.Identifier.." "..self.Name..": waittime must be equal or greater than 0!");
        return true;
    end
    if self.RewardType and self.RewardType ~= "-" then
        if not Goods[self.RewardType] then
            dbg(""..__quest_.Identifier.." "..self.Name..": '"..self.RewardType.."' is invalid good type!");
            return true;
        elseif self.RewardAmount < 1 then
            dbg(""..__quest_.Identifier.." "..self.Name..": amount can not be 0 or negative!");
            return true;
        end
    end
    if self.FirstCostType and self.FirstCostType ~= "-" then
        if not Goods[self.FirstCostType] then
            dbg(""..__quest_.Identifier.." "..self.Name..": '"..self.FirstCostType.."' is invalid good type!");
            return true;
        elseif self.FirstCostAmount < 1 then
            dbg(""..__quest_.Identifier.." "..self.Name..": amount can not be 0 or negative!");
            return true;
        end
    end
    if self.SecondCostType and self.SecondCostType ~= "-" then
        if not Goods[self.SecondCostType] then
            dbg(""..__quest_.Identifier.." "..self.Name..": '"..self.SecondCostType.."' is invalid good type!");
            return true;
        elseif self.SecondCostAmount < 1 then
            dbg(""..__quest_.Identifier.." "..self.Name..": amount can not be 0 or negative!");
            return true;
        end
    end
    return false;
end

AddQuestBehavior(b_Reward_ObjectInit);

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
-- @return table: Behavior
-- @within Rewards
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

function b_Reward_ObjectSetCarts:AddParameter(__index_, __parameter_)
    if __index_ == 0 then
        self.ScriptName = __parameter_
    elseif __index_ == 1 then
        if not __parameter_ or __parameter_ == "default" then
            __parameter_ = "U_ResourceMerchant";
        end
        self.CostResourceCart = __parameter_
    elseif __index_ == 2 then
        if not __parameter_ or __parameter_ == "default" then
            __parameter_ = "U_GoldCart";
        end
        self.CostGoldCart = __parameter_
    elseif __index_ == 3 then
        if not __parameter_ or __parameter_ == "default" then
            __parameter_ = "U_ResourceMerchant";
        end
        self.RewardResourceCart = __parameter_
    elseif __index_ == 4 then
        if not __parameter_ or __parameter_ == "default" then
            __parameter_ = "U_GoldCart";
        end
        self.RewardGoldCart = __parameter_
    end
end

function b_Reward_ObjectSetCarts:CustomFunction(__quest_)
    local eID = GetID(self.ScriptName);
    Logic.InteractiveObjectSetRewardResourceCartType(eID, Entities[self.RewardResourceCart]);
    Logic.InteractiveObjectSetRewardGoldCartType(eID, Entities[self.RewardGoldCart]);
    Logic.InteractiveObjectSetCostGoldCartType(eID, Entities[self.CostResourceCart]);
    Logic.InteractiveObjectSetCostResourceCartType(eID, Entities[self.CostGoldCart]);
end

function b_Reward_ObjectSetCarts:GetCustomData( __index_ )
    if __index_ == 2 or __index_ == 4 then
        return {"U_GoldCart", "U_GoldCart_Mission", "U_Noblemen_Cart", "U_RegaliaCart"}
    elseif __index_ == 1 or __index_ == 3 then
        local Data = {"U_ResourceMerchant", "U_Medicus", "U_Marketer"}
        if g_GameExtraNo > 0 then
            table.insert(Data, "U_NPC_Resource_Monk_AS");
        end
        return Data;
    end
end

function b_Reward_ObjectSetCarts:DEBUG(__quest_)
    if (not Entities[self.CostResourceCart]) or (not Entities[self.CostGoldCart])
    or (not Entities[self.RewardResourceCart]) or (not Entities[self.RewardGoldCart]) then
        dbg(""..__quest_.Identifier.." "..self.Name..": invalid cart type!");
        return true;
    end

    local eID = GetID(self.ScriptName);
    if QSB.InitalizedObjekts[eID] and QSB.InitalizedObjekts[eID] == __quest_.Identifier then
        dbg(""..__quest_.Identifier.." "..self.Name..": you can not change carts in the same quest the object is initalized!");
        return true;
    end
    return false;
end

AddQuestBehavior(b_Reward_ObjectSetCarts);

-- -------------------------------------------------------------------------- --

---
-- Änder den Diplomatiestatus zwischen zwei Spielern.
--
-- @param _Party1   ID der ersten Partei
-- @param _Party2   ID der zweiten Partei
-- @param _State    Neuer Diplomatiestatus
-- @return table: Behavior
-- @within Reprisals
--
function Reward_Diplomacy(...)
    return b_Reprisal_Diplomacy:new(...);
end

b_Reward_Diplomacy = API.InstanceTable(b_Reprisal_Diplomacy);
b_Reward_Diplomacy.Name             = "Reward_ObjectDeactivate";
b_Reward_Diplomacy.Description.de   = "Reward: Sets Diplomacy state of two Players to a stated value.";
b_Reward_Diplomacy.Description.en   = "Lohn: Setzt den Diplomatiestatus zweier Spieler auf den angegebenen Wert.";
b_Reward_Diplomacy.GetReprisalTable = nil;

b_Reward_ObjectDeactivate.GetRewardTable = function(self)
    return { Reward.Custom,{self, self.CustomFunction} }
end

-- -------------------------------------------------------------------------- --

---
-- Verbessert die diplomatischen Beziehungen zwischen Sender und Empfänger
-- um einen Grad.
--
-- @return table: Behavior
-- @within Rewards
--
function Reward_DiplomacyIncrease(...)
    return b_Reward_DiplomacyIncrease:new(...);
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

function b_Reward_DiplomacyIncrease:CustomFunction(__quest_)
    local Sender = __quest_.SendingPlayer;
    local Receiver = __quest_.ReceivingPlayer;
    local State = GetDiplomacyState(Receiver, Sender);
    if State < 2 then
        SetDiplomacyState(Receiver, Sender, State+1);
    end
end

function b_Reward_DiplomacyIncrease:AddParameter(__index_, __parameter_)
    if (__index_ == 0) then
        self.PlayerID = __parameter_ * 1
    end
end

AddQuestBehavior(b_Reward_DiplomacyIncrease);

-- -------------------------------------------------------------------------- --

---
-- Erzeugt Handelsangebote im Lagerhaus des angegebenen Spielers.
--
-- Sollen Angebote gelöscht werden, muss "-" als Ware ausgewählt werden.
--
-- ACHTUNG: Stadtlagerhäuser können keine Söldner anbieten!
--
-- @param _PlayerID     Partei, die Anbietet
-- @param _OfferAmount1 Menge des 1. Angebot
-- @param _OfferType1   Ware oder Typ des 1. Angebot
-- @param _OfferAmount2 Menge des 2. Angebot
-- @param _OfferType2   Ware oder Typ des 2. Angebot
-- @param _OfferAmount3 Menge des 3. Angebot
-- @param _OfferType3   Ware oder Typ des 3. Angebot
-- @param _OfferAmount4 Menge des 4. Angebot
-- @param _OfferType4   Ware oder Typ des 4. Angebot
-- @return table: Behavior
-- @within Rewards
--
function Reward_TradeOffers(...)
    return b_Reward_TradeOffers:new(...);
end

b_Reward_TradeOffers = {
    Name = "Reward_TradeOffers",
    Description = {
        en = "Reward: Deletes all existing offers for a merchant and sets new offers, if given",
        de = "Lohn: Loescht alle Angebote eines Haendlers und setzt neue, wenn angegeben",
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

function b_Reward_TradeOffers:AddParameter(__index_, __parameter_)
    if (__index_ == 0) then
        self.PlayerID = __parameter_
    elseif (__index_ == 1) then
        self.AmountOffer1 = tonumber(__parameter_)
    elseif (__index_ == 2) then
        self.Offer1 = __parameter_
    elseif (__index_ == 3) then
        self.AmountOffer2 = tonumber(__parameter_)
    elseif (__index_ == 4) then
        self.Offer2 = __parameter_
    elseif (__index_ == 5) then
        self.AmountOffer3 = tonumber(__parameter_)
    elseif (__index_ == 6) then
        self.Offer3 = __parameter_
    elseif (__index_ == 7) then
        self.AmountOffer4 = tonumber(__parameter_)
    elseif (__index_ == 8) then
        self.Offer4 = __parameter_
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

function b_Reward_TradeOffers:DEBUG(__quest_)
    if Logic.GetStoreHouse(self.PlayerID ) == 0 then
        dbg(__quest_.Identifier .. ": Error in " .. self.Name .. ": Player " .. self.PlayerID .. " is dead. :-(")
        return true
    end
end

function b_Reward_TradeOffers:GetCustomData(__index_)
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
    if (__index_ == 0) then
        return Players
    elseif (__index_ == 1) or (__index_ == 3) or (__index_ == 5) or (__index_ == 7) then
        return Amount
    elseif (__index_ == 2) or (__index_ == 4) or (__index_ == 6) or (__index_ == 8) then
        return Offers
    end
end

AddQuestBehavior(b_Reward_TradeOffers)

-- -------------------------------------------------------------------------- --
-- Trigger                                                                    --
-- -------------------------------------------------------------------------- --

---
-- Starte den Quest, wenn ein anderer Spieler entdeckt wurde.
--
-- Ein Spieler ist dann entdeckt, wenn sein Heimatterritorium aufgedeckt wird.
--
-- @param _PlayerID Zu entdeckender Spieler
-- @return table: Behavior
-- @within Trigger
--
function Trigger_PlayerDiscovered(...)
    return b_Trigger_PlayerDiscovered:new(...);
end

b_Trigger_PlayerDiscovered = {
    Name = "Trigger_PlayerDiscovered",
    Description = {
        en = "Trigger: if a given player has been discovered",
        de = "Ausloeser: wenn ein angegebener Spieler entdeckt wurde",
    },
    Parameter = {
        { ParameterType.PlayerID, en = "Player", de = "Spieler" },
    },
}

function b_Trigger_PlayerDiscovered:GetTriggerTable(__quest_)
    return {Triggers.PlayerDiscovered, self.PlayerID}
end

function b_Trigger_PlayerDiscovered:AddParameter(__index_, __parameter_)
    if (__index_ == 0) then
        self.PlayerID = __parameter_ * 1;
    end
end

AddQuestBehavior(b_Trigger_PlayerDiscovered);

-- -------------------------------------------------------------------------- --

---
-- Starte den Quest, wenn zwischen dem Empfänger und der angegebenen Partei
-- der geforderte Diplomatiestatus herrscht.
--
-- @param _PlayerID ID der Partei
-- @param _State    Diplomatie-Status
-- @return table: Behavior
-- @within Trigger
--
function Trigger_OnDiplomacy(...)
    return b_Trigger_OnDiplomacy:new(...);
end

b_Trigger_OnDiplomacy = {
    Name = "Trigger_OnDiplomacy",
    Description = {
        en = "Trigger: if diplomatic relations have been established with a player",
        de = "Ausloeser: wenn ein angegebener Diplomatie-Status mit einem Spieler erreicht wurde.",
    },
    Parameter = {
        { ParameterType.PlayerID, en = "Player", de = "Spieler" },
        { ParameterType.DiplomacyState, en = "Relation", de = "Beziehung" },
    },
}

function b_Trigger_OnDiplomacy:GetTriggerTable(__quest_)
    return {Triggers.Diplomacy, self.PlayerID, assert( DiplomacyStates[self.DiplState] ) }
end

function b_Trigger_OnDiplomacy:AddParameter(__index_, __parameter_)
    if (__index_ == 0) then
        self.PlayerID = __parameter_ * 1
    elseif (__index_ == 1) then
        self.DiplState = __parameter_
    end
end

AddQuestBehavior(b_Trigger_OnDiplomacy);

-- -------------------------------------------------------------------------- --
-- Application Space                                                          --
-- -------------------------------------------------------------------------- --

ClassicBehaviorBundle = {
    Global = {},
    Local = {}
};

-- Global Script ---------------------------------------------------------------

---
-- Initialisiert das Bundle im globalen Skript.
-- @local
--
function ClassicBehaviorBundle.Global:Install()

end

-- Local Script ----------------------------------------------------------------

---
-- Initialisiert das Bundle im lokalen Skript.
-- @local
--
function ClassicBehaviorBundle.Local:Install()

end
