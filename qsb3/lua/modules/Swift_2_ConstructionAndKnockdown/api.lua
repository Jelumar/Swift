--[[
Swift_2_ConstructionAndKnockdown/API

Copyright (C) 2021 - 2022 totalwarANGEL - All Rights Reserved.

This file is part of Swift. Swift is created by totalwarANGEL.
You may use and modify this file unter the terms of the MIT licence.
(See https://en.wikipedia.org/wiki/MIT_License)
]]

---
-- Ermöglicht den Gebäudebau zu beschränken.
--
-- Der Bau von Gebäudetypen oder Gebäudekategorien kann reguliert werden.
-- Verbote können für bestimmte Bereiche (kreisförmige Gebiete um ein Zentrum)
-- oder ganze Territorien vereinbart werden.
--
-- <b>Hinweis</b>: Werden Mauern oder Palisaden verboten, werden diese zwar
-- gesetzt, aber sofort danach wieder zerstört. Der Wagen mit den Steinen kehrt
-- dann in das Lagerhaus zurück.
--
-- <b>Hinweis</b>: Es können nur Abrisse verhindert werden, wenn ein Gebäude
-- für den Abriss einen Siedler benötigt.
--
-- <b>Vorausgesetzte Module:</b>
-- <ul>
-- <li><a href="Swift_1_EntityEventCore.api.html">(1) Entity Event Core</a></li>
-- <li><a href="Swift_1_JobsCore.api.html">(1) Jobs Core</a></li>
-- </ul>
--
-- @within Beschreibung
-- @set sort=true
--

---
-- Events, auf die reagiert werden kann.
--
-- @field BuildingKnockdown Ein Gebäude wurde zum Abriss markiert. (Parameter: EntityID, PlayerID, _State)
--                          <br>Gebäude, die noch nicht fertig gebaut sind, werden sofort abgerissen!
--
-- @within Event
--
QSB.ScriptEvents = QSB.ScriptEvents or {};

---
-- Erzeugt eine neue Baubeschränkung.
--
-- Eine Baubeschränkung muss <b>true</b> zurückgeben, wenn ein Gebäudetyp oder
-- eine Gebäudekategorie gebaut werden darf. Im Gegenzug muss <b>false</b>
-- zurückgegeben werden, wenn der Bau nicht gestattet sein soll.
--
-- @param[type=function] _Function Bedingung der Beschränkung
-- @return[type=number] ID der Beschränkung
-- @within Anwenderfunktionen
-- @see API.GetForbidConstructTypeAtTerritory
-- @see API.GetForbidConstructCategoryAtTerritory
-- @see API.GetForbidConstructTypeInArea
-- @see API.GetForbidConstructCategoryInArea
-- @see API.GetPermitConstructTypeAtTerritory
-- @see API.GetPermitConstructCategoryAtTerritory
-- @see API.GetPermitConstructTypeInArea
-- @see API.GetPermitConstructCategoryInArea
--
-- @usage
-- -- Vordefinierte Bedingung:
-- -- Bäckereien dürfen nicht auf Territorium 13 gebaut werden.
-- local ID = API.AddConstructionRestriction(
--     API.GetForbidConstructTypeAtTerritory(1, 13, Entities.B_Bakery)
-- );
-- -- Benutzerdefinierte Bedingung:
-- -- Steinmauern können nur auf Territorium 7 gebaut werden.
-- local ID = API.AddConstructionRestriction(function(_PlayerID, _Type, _x, _y)
--     if  _PlayerID == 1
--     and Logic.IsEntityTypeInCategory(_Type, EntityCategories.Palisade) == 0
--     and Logic.IsEntityTypeInCategory(_Type, EntityCategories.Wall) == 1 then
--         if Logic.GetTerritoryAtPosition(_x, _y) ~= 7 then
--             return false;
--         end
--     end
--     return true;
-- end);
--
function API.AddConstructionRestriction(_Function)
    local ID = ModuleConstructionControl.Global:GenerateConstructionConditionID();
    ModuleConstructionControl.Global.ConstructionConditions[ID] = _Function;
    return ID;
end

---
-- Entfernt eine Baubeschränkung.
-- @param[type=number] _ID ID der Beschränkung
-- @within Anwenderfunktionen
--
-- @usage API.RemoveConstructionRestriction(SomeRestrictionID);
--
function API.RemoveConstructionRestriction(_ID)
    ModuleConstructionControl.Global.ConstructionConditions[_ID] = nil;
end

---
-- Erzeugt eine Bedinungsfunktion.
--
-- Der Entitytyp kann <u>nur</u> im Territorium gebaut werden.
--
-- @param[type=number] _PlayerID   ID des Spielers
-- @param[type=number] _Territory  ID des Territorium
-- @param[type=number] _EntityType Entity Type
-- @return[type=function] Bedingungsfunktion
-- @within Anwenderfunktionen
--
function API.GetPermitConstructTypeAtTerritory(_PlayerID, _Territory, _EntityType)
    return function(_Player, _Type, _x, _y)
        if _Player == _PlayerID and _Type == _EntityType then
            return Logic.GetTerritoryAtPosition(_x, _y) == _Territory;
        end
        return true;
    end
end

---
-- Erzeugt eine Bedinungsfunktion.
--
-- Der Entitytyp kann <u>nicht</u> im Territorium gebaut werden.
--
-- @param[type=number] _PlayerID   ID des Spielers
-- @param[type=number] _Territory  ID des Territorium
-- @param[type=number] _EntityType Entity Type
-- @return[type=function] Bedingungsfunktion
-- @within Anwenderfunktionen
--
function API.GetForbidConstructTypeAtTerritory(_PlayerID, _Territory, _EntityType)
    return function(_Player, _Type, _x, _y)
        if _Player == _PlayerID and _Type == _EntityType then
            return Logic.GetTerritoryAtPosition(_x, _y) ~= _Territory;
        end
        return true;
    end
end

---
-- Erzeugt eine Bedinungsfunktion.
--
-- Die Kategorie kann <u>nur</u> im Territorium gebaut werden.
--
-- @param[type=number] _PlayerID  ID des Spielers
-- @param[type=number] _Territory ID des Territorium
-- @param[type=number] _Category  Entity Category
-- @return[type=function] Bedingungsfunktion
-- @within Anwenderfunktionen
--
function API.GetPermitConstructCategoryAtTerritory(_PlayerID, _Territory, _Category)
    return function(_Player, _Type, _x, _y)
        if _Player == _PlayerID and Logic.IsEntityTypeInCategory(_Type, _Category) == 1 then
            return Logic.GetTerritoryAtPosition(_x, _y) == _Territory;
        end
        return true;
    end
end

---
-- Erzeugt eine Bedinungsfunktion.
--
-- Die Kategorie kann <u>nicht</u> im Territorium gebaut werden.
--
-- @param[type=number] _PlayerID  ID des Spielers
-- @param[type=number] _Territory ID des Territorium
-- @param[type=number] _Category  Entity Category
-- @return[type=function] Bedingungsfunktion
-- @within Anwenderfunktionen
--
function API.GetForbidConstructCategoryAtTerritory(_PlayerID, _Territory, _Category)
    return function(_Player, _Type, _x, _y)
        if _Player == _PlayerID and Logic.IsEntityTypeInCategory(_Type, _Category) == 1 then
            return Logic.GetTerritoryAtPosition(_x, _y) ~= _Territory;
        end
        return true;
    end
end

---
-- Erzeugt eine Bedinungsfunktion.
--
-- Der Entitytyp kann <u>nur</u> im Gebiet gebaut werden.
--
-- @param[type=number] _PlayerID   ID des Spielers
-- @param[type=string] _AreaCenter Gebietszentrum
-- @param[type=number] _AreaSize   Gebietsradius
-- @param[type=number] _EntityType Entity Type
-- @return[type=function] Bedingungsfunktion
-- @within Anwenderfunktionen
--
function API.GetPermitConstructTypeInArea(_PlayerID, _AreaCenter, _AreaSize, _EntityType)
    return function(_Player, _Type, _x, _y)
        if _Player == _PlayerID and _Type == _EntityType then
            return GetDistance({X= _x, Y= _y}, _AreaCenter) <= _AreaSize;
        end
        return true;
    end
end

---
-- Erzeugt eine Bedinungsfunktion.
--
-- Der Entitytyp kann <u>nicht</u> im Gebiet gebaut werden.
--
-- @param[type=number] _PlayerID   ID des Spielers
-- @param[type=string] _AreaCenter Gebietszentrum
-- @param[type=number] _AreaSize   Gebietsradius
-- @param[type=number] _EntityType Entity Type
-- @return[type=function] Bedingungsfunktion
-- @within Anwenderfunktionen
--
function API.GetForbidConstructTypeInArea(_PlayerID, _AreaCenter, _AreaSize, _EntityType)
    return function(_Player, _Type, _x, _y)
        if _Player == _PlayerID and _Type == _EntityType then
            return GetDistance({X= _x, Y= _y}, _AreaCenter) > _AreaSize;
        end
        return true;
    end
end

---
-- Erzeugt eine Bedinungsfunktion.
--
-- Die Kategorie kann <u>nur</u> im Gebiet gebaut werden.
--
-- @param[type=number] _PlayerID   ID des Spielers
-- @param[type=string] _AreaCenter Gebietszentrum
-- @param[type=number] _AreaSize   Gebietsradius
-- @param[type=number] _Category   Entity Category
-- @return[type=function] Bedingungsfunktion
-- @within Anwenderfunktionen
--
function API.GetPermitConstructCategoryInArea(_PlayerID, _AreaCenter, _AreaSize, _Category)
    return function(_Player, _Type, _x, _y)
        if _Player == _PlayerID and Logic.IsEntityTypeInCategory(_Type, _Category) == 1 then
            return GetDistance({X= _x, Y= _y}, _AreaCenter) <= _AreaSize;
        end
        return true;
    end
end

---
-- Erzeugt eine Bedinungsfunktion.
--
-- Die Kategorie kann <u>nicht</u> im Gebiet gebaut werden.
--
-- @param[type=number] _PlayerID   ID des Spielers
-- @param[type=string] _AreaCenter Gebietszentrum
-- @param[type=number] _AreaSize   Gebietsradius
-- @param[type=number] _Category   Entity Category
-- @return[type=function] Bedingungsfunktion
-- @within Anwenderfunktionen
--
function API.GetForbidConstructCategoryInArea(_PlayerID, _AreaCenter, _AreaSize, _Category)
    return function(_Player, _Type, _x, _y)
        if _Player == _PlayerID and Logic.IsEntityTypeInCategory(_Type, _Category) == 1 then
            return GetDistance({X= _x, Y= _y}, _AreaCenter) > _AreaSize;
        end
        return true;
    end
end

---
-- Erzeugt eine neue Abrissbeschränkung.
--
-- Eine Abrissbeschränkung muss <b>true</b> zurückgeben, wenn ein Gebäudetyp
-- oder eine Gebäudekategorie abgerissen werden darf. Im Gegenzug muss
-- <b>false</b> zurückgegeben werden, wenn der Besitzer das Gebäude nicht
-- abreißen können sein soll.
--
-- @param[type=function] _Function Bedingung der Beschränkung
-- @return[type=number] ID der Beschränkung
-- @within Anwenderfunktionen
--
-- @see API.GetForbidKnockdownTypeAtTerritory
-- @see API.GetForbidKnockdownCategoryAtTerritory
-- @see API.GetForbidKnockdownTypeInArea
-- @see API.GetForbidKnockdownCategoryInArea
-- @see API.GetPermitKnockdownTypeAtTerritory
-- @see API.GetPermitKnockdownCategoryAtTerritory
-- @see API.GetPermitKnockdownTypeInArea
-- @see API.GetPermitKnockdownCategoryInArea
--
-- @usage
-- -- Vordefinierte Bedingung:
-- -- Bäckereien dürfen nicht auf Territorium 13 abgerissen werden.
-- local ID = API.AddKnockdownRestriction(
--     API.GetForbidKnockdownTypeAtTerritory(1, 13, Entities.B_Bakery)
-- );
-- -- Benutzerdefinierte Bedingung:
-- -- Das Gebäude mit dem namen "Bakery" darf nicht abgerissen werden.
-- local ID = API.AddKnockdownRestriction(function(_EntityID)
--     return Logic.GetEntityName(_EntityID) ~= "Bakery";
-- end);
--
function API.AddKnockdownRestriction(_Function)
    local ID = ModuleConstructionControl.Global:GenerateKnockdownConditionID();
    ModuleConstructionControl.Global.KnockdownConditions[ID] = _Function;
    return ID;
end

---
-- Entfernt eine Abrissbeschränkung.
-- @param[type=number] _ID ID der Beschränkung
-- @within Anwenderfunktionen
--
-- @usage API.RemoveKnockdownRestriction(SomeRestrictionID);
--
function API.RemoveKnockdownRestriction(_ID)
    ModuleConstructionControl.Global.KnockdownConditions[_ID] = nil;
end

---
-- Erzeugt eine Bedinungsfunktion.
--
-- Der Entitytyp kann <u>nicht</u> im Territorium abgerissen werden.
--
-- @param[type=number] _PlayerID   ID des Spielers
-- @param[type=number] _Territory  ID des Territorium
-- @param[type=number] _EntityType Entity Type
-- @return[type=function] Bedingungsfunktion
-- @within Anwenderfunktionen
--
function API.GetForbidKnockdownTypeAtTerritory(_PlayerID, _Territory, _EntityType)
    return function(_EntityID)
        if Logic.EntityGetPlayer(_EntityID) == _PlayerID then
            if Logic.GetEntityType(_EntityID) == _EntityType then
                return GetTerritoryUnderEntity(_EntityID) ~= _Territory;
            end
        end
        return true;
    end
end

---
-- Erzeugt eine Bedinungsfunktion.
--
-- Der Entitytyp kann <u>nur</u> im Territorium abgerissen werden.
--
-- @param[type=number] _PlayerID   ID des Spielers
-- @param[type=number] _Territory  ID des Territorium
-- @param[type=number] _EntityType Entity Type
-- @return[type=function] Bedingungsfunktion
-- @within Anwenderfunktionen
--
function API.GetPermitKnockdownTypeAtTerritory(_PlayerID, _Territory, _EntityType)
    return function(_EntityID)
        if Logic.EntityGetPlayer(_EntityID) == _PlayerID then
            if Logic.GetEntityType(_EntityID) == _EntityType then
                return GetTerritoryUnderEntity(_EntityID) == _Territory;
            end
        end
        return true;
    end
end

---
-- Erzeugt eine Bedinungsfunktion.
--
-- Die Kategorie kann <u>nicht</u> im Territorium abgerissen werden.
--
-- @param[type=number] _PlayerID   ID des Spielers
-- @param[type=number] _Territory  ID des Territorium
-- @param[type=number] _Category   Entity Category
-- @return[type=function] Bedingungsfunktion
-- @within Anwenderfunktionen
--
function API.GetForbidKnockdownCategoryAtTerritory(_PlayerID, _Territory, _Category)
    return function(_EntityID)
        if Logic.EntityGetPlayer(_EntityID) == _PlayerID then
            if Logic.IsEntityTypeInCategory(_EntityID, _Category) == 1 then
                return GetTerritoryUnderEntity(_EntityID) ~= _Territory;
            end
        end
        return true;
    end
end

---
-- Erzeugt eine Bedinungsfunktion.
--
-- Die Kategorie kann <u>nur</u> im Territorium abgerissen werden.
--
-- @param[type=number] _PlayerID   ID des Spielers
-- @param[type=number] _Territory  ID des Territorium
-- @param[type=number] _Category   Entity Category
-- @return[type=function] Bedingungsfunktion
-- @within Anwenderfunktionen
--
function API.GetPermitKnockdownCategoryAtTerritory(_PlayerID, _Territory, _Category)
    return function(_EntityID)
        if Logic.EntityGetPlayer(_EntityID) == _PlayerID then
            if Logic.IsEntityTypeInCategory(_EntityID, _Category) == 1 then
                return GetTerritoryUnderEntity(_EntityID) == _Territory;
            end
        end
        return true;
    end
end

---
-- Erzeugt eine Bedinungsfunktion.
--
-- Der Entitytyp kann <u>nicht</u> im Gebiet abgerissen werden.
--
-- @param[type=number] _PlayerID   ID des Spielers
-- @param[type=number] _AreaCenter Gebietszentrum
-- @param[type=number] _AreaSize   Gebietsradius
-- @param[type=number] _EntityType Entity Type
-- @return[type=function] Bedingungsfunktion
-- @within Anwenderfunktionen
--
function API.GetForbidKnockdownTypeInArea(_PlayerID, _AreaCenter, _AreaSize, _EntityType)
    return function(_EntityID)
        if Logic.EntityGetPlayer(_EntityID) == _PlayerID then
            if Logic.GetEntityType(_EntityID) == _EntityType then
                return API.GetDistance(_EntityID, _AreaCenter) > _AreaSize;
            end
        end
        return true;
    end
end

---
-- Erzeugt eine Bedinungsfunktion.
--
-- Der Entitytyp kann <u>nur</u> im Gebiet abgerissen werden.
--
-- @param[type=number] _PlayerID   ID des Spielers
-- @param[type=number] _AreaCenter Gebietszentrum
-- @param[type=number] _AreaSize   Gebietsradius
-- @param[type=number] _EntityType Entity Type
-- @return[type=function] Bedingungsfunktion
-- @within Anwenderfunktionen
--
function API.GetPermitKnockdownTypeInArea(_PlayerID, _AreaCenter, _AreaSize, _EntityType)
    return function(_EntityID)
        if Logic.EntityGetPlayer(_EntityID) == _PlayerID then
            if Logic.GetEntityType(_EntityID) == _EntityType then
                return API.GetDistance(_EntityID, _AreaCenter) <= _AreaSize;
            end
        end
        return true;
    end
end

---
-- Erzeugt eine Bedinungsfunktion.
--
-- Die Kategorie kann <u>nicht</u> im Gebiet abgerissen werden.
--
-- @param[type=number] _PlayerID   ID des Spielers
-- @param[type=number] _AreaCenter Gebietszentrum
-- @param[type=number] _AreaSize   Gebietsradius
-- @param[type=number] _Category   Entity Category
-- @return[type=function] Bedingungsfunktion
-- @within Anwenderfunktionen
--
function API.GetForbidKnockdownCategoryInArea(_PlayerID, _AreaCenter, _AreaSize, _Category)
    return function(_EntityID)
        if Logic.EntityGetPlayer(_EntityID) == _PlayerID then
            if Logic.IsEntityTypeInCategory(_EntityID, _Category) == 1 then
                return API.GetDistance(_EntityID, _AreaCenter) > _AreaSize;
            end
        end
        return true;
    end
end

---
-- Erzeugt eine Bedinungsfunktion.
--
-- Die Kategorie kann <u>nur</u> im Gebiet abgerissen werden.
--
-- @param[type=number] _PlayerID   ID des Spielers
-- @param[type=number] _AreaCenter Gebietszentrum
-- @param[type=number] _AreaSize   Gebietsradius
-- @param[type=number] _Category   Entity Category
-- @return[type=function] Bedingungsfunktion
-- @within Anwenderfunktionen
--
function API.GetPermitKnockdownCategoryInArea(_PlayerID, _AreaCenter, _AreaSize, _Category)
    return function(_EntityID)
        if Logic.EntityGetPlayer(_EntityID) == _PlayerID then
            if Logic.IsEntityTypeInCategory(_EntityID, _Category) == 1 then
                return API.GetDistance(_EntityID, _AreaCenter) <= _AreaSize;
            end
        end
        return true;
    end
end

-- Local callbacks

function SCP.ConstructionAndKnockdown.CancelKnockdown(_BuildingID, _PlayerID, _State)
    ModuleConstructionControl.Global:CheckCancelBuildingKnockdown(_BuildingID, _PlayerID, _State)
end

