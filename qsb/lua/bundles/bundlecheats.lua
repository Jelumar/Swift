-- -------------------------------------------------------------------------- --
-- ########################################################################## --
-- #  Symfonia BundleCheats                                                 # --
-- ########################################################################## --
-- -------------------------------------------------------------------------- --

---
-- Mit diesem Bundle kann die Nutzung der Cheats verboten oder erlaubt werden.
--
-- Es sind nur die normalen Cheats betroffen. Wenn der Debug der QSB aktiv
-- ist, können Cheats nicht deaktiviert werden.
--
-- @within Modulbeschreibung
-- @set sort=true
--
BundleCheats = {};

API = API or {};
QSB = QSB or {};

-- -------------------------------------------------------------------------- --
-- User-Space                                                                 --
-- -------------------------------------------------------------------------- --

---
-- Deaktiviert die Tastenkombination zum Einschalten der Cheats.
--
-- <p><b>Alias:</b> KillCheats</p>
--
-- @within Anwenderfunktionen
--
function API.ForbidCheats()
    if GUI then
        API.Bridge("API.ForbidCheats()");
        return;
    end
    return BundleCheats.Global:KillCheats();
end
KillCheats = API.ForbidCheats;

---
-- Aktiviert die Tastenkombination zum Einschalten der Cheats.
--
-- <p><b>Alias:</b> RessurectCheats</p>
--
-- @within Anwenderfunktionen
--
function API.AllowCheats()
    if GUI then
        API.Bridge("API.AllowCheats()");
        return;
    end
    return BundleCheats.Global:RessurectCheats();
end
RessurectCheats = API.AllowCheats;

-- -------------------------------------------------------------------------- --
-- Application-Space                                                          --
-- -------------------------------------------------------------------------- --

BundleCheats = {
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
-- @within Internal
-- @local
--
function BundleCheats.Global:Install()
    API.AddSaveGameAction(BundleCheats.Global.OnSaveGameLoaded);
end

-- -------------------------------------------------------------------------- --

---
-- Deaktiviert die Tastenkombination zum Einschalten der Cheats.
--
-- @within Internal
-- @local
--
function BundleCheats.Global:KillCheats()
    self.Data.CheatsForbidden = true;
    API.Bridge("BundleCheats.Local:KillCheats()");
end

---
-- Aktiviert die Tastenkombination zum Einschalten der Cheats.
--
-- @within Internal
-- @local
--
function BundleCheats.Global:RessurectCheats()
    self.Data.CheatsForbidden = false;
    API.Bridge("BundleCheats.Local:RessurectCheats()");
end

-- -------------------------------------------------------------------------- --

---
-- Stellt nicht-persistente Änderungen nach dem laden wieder her.
--
-- @within Internal
-- @local
--
function BundleCheats.Global.OnSaveGameLoaded()
    -- Cheats sperren --
    if BundleCheats.Global.Data.CheatsForbidden == true then
        BundleCheats.Global:KillCheats();
    end
end

-- -------------------------------------------------------------------------- --

---
-- Deaktiviert die Tastenkombination zum Einschalten der Cheats.
--
-- @within Internal
-- @local
--
function BundleCheats.Local:KillCheats()
    Input.KeyBindDown(
        Keys.ModifierControl + Keys.ModifierShift + Keys.Divide,
        "KeyBindings_EnableDebugMode(0)",
        2,
        false
    );
end

---
-- Aktiviert die Tastenkombination zum Einschalten der Cheats.
--
-- @within Internal
-- @local
--
function BundleCheats.Local:RessurectCheats()
    Input.KeyBindDown(
        Keys.ModifierControl + Keys.ModifierShift + Keys.Divide,
        "KeyBindings_EnableDebugMode(2)",
        2,
        false
    );
end

-- -------------------------------------------------------------------------- --

Core:RegisterBundle("BundleCheats");
