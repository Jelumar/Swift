-- Input/Output API --------------------------------------------------------- --

---
-- Modul für die Eingabe durch den Spieler und die Ausgabe von Texten.
--
-- <b>Hinweis</b>: Diese Funktionen können nicht in Multiplayer Maps benutzt
-- werden, wenn sie mit der History Edition spielbar sein sollen.
--
-- Du kannst vordefinierte Farben in Textausgaben verwenden. Außerdem kannst
-- du für Skriptnamen und Entitytypen Platzhalter zu definieren. Diese
-- Platzhalter können auch lokalisiert werden.
--
-- Du kannst ferner verschiedene Input Dialoge nutzen, um Ausgaben anzuzeigen.
-- Außerdem kannst du vom Spieler Eingaben fordern.
--
-- TODO: Implement hot keys
--
-- <b>Vorausgesetzte Module:</b>
-- <ul>
-- <li><a href="Swift_0_Core.api.html">(0) Core</a></li>
-- </ul>
--
-- @within Beschreibung
-- @set sort=true
--

---
-- Schreibt eine Nachricht in das Debug Window. Der Text erscheint links am
-- Bildschirm und ist nicht statisch.
--
-- <b>Hinweis:</b> Texte werden automatisch lokalisiert und Platzhalter ersetzt.
--
-- <b>Alias:</b> GUI_Note
--
-- @param[type=string] _Text Anzeigetext
-- @within Anwenderfunktionen
--
-- @usage API.Note("Das ist eine flüchtige Information!");
--
function API.Note(_Text)
    ModuleInputOutputCore.Shared:Note(_Text);
end
GUI_Note = API.Note;

---
-- Schreibt eine Nachricht in das Debug Window. Der Text erscheint links am
-- Bildschirm und verbleibt dauerhaft am Bildschirm.
--
-- <b>Hinweis:</b> Texte werden automatisch lokalisiert und Platzhalter ersetzt.
--
-- <b>Alias:</b> GUI_StaticNote
--
-- @param[type=string] _Text Anzeigetext
-- @within Anwenderfunktionen
--
-- @usage API.StaticNote("Das ist eine dauerhafte Information!");
--
function API.StaticNote(_Text)
    ModuleInputOutputCore.Shared:StaticNote(_Text);
end
GUI_StaticNote = API.StaticNote;

---
-- Schreibt eine Nachricht unten in das Nachrichtenfenster. Die Nachricht
-- verschwindet nach einigen Sekunden.
--
-- <b>Hinweis:</b> Texte werden automatisch lokalisiert und Platzhalter ersetzt.
--
-- <b>Alias:</b> GUI_Message<
--
-- @param[type=string] _Text Anzeigetext
-- @within Anwenderfunktionen
--
-- @usage API.Message("Das ist eine Nachricht!");
--
function API.Message(_Text)
    ModuleInputOutputCore.Shared:Message(_Text);
end
GUI_Message = API.Message;

---
-- Löscht alle Nachrichten im Debug Window.
--
-- @within Anwenderfunktionen
--
-- @usage API.ClearNotes();
--
function API.ClearNotes()
    ModuleInputOutputCore.Shared:ClearNotes();
end
GUI_ClearNotes = API.ClearNotes;

---
-- Ermittelt den lokalisierten Text anhand der eingestellten Sprache der QSB.
--
-- Wird ein normaler String übergeben, wird dieser sofort zurückgegeben. Im
-- Gegensatz zur Funktion im Core Modul wird hier immer sichergestellt, dass
-- die Rückgabe ein String ist.
--
-- <b>Hinweis</b>: Diese Funktion ersetzt die Lokalisierung aus dem Core Modul.
--
-- @param _Text Anzeigetext (String oder Table)
-- @return[type=string] Message
-- @within Anwenderfunktionen
--
-- @usage local Text = API.Localize({de = "Deutsch", en = "English"});
--
function API.Localize(_Text)
    return ModuleInputOutputCore.Shared:Localize(_Text);
end

---
-- Ersetzt alle Platzhalter im Text oder in der Table.
--
-- Mögliche Platzhalter:
-- <ul>
-- <li>{name:xyz} - Ersetzt einen Skriptnamen mit dem zuvor gesetzten Wert.</li>
-- <li>{type:xyz} - Ersetzt einen Typen mit dem zuvor gesetzten Wert.</li>
-- </ul>
--
-- Außerdem werden einige Standardfarben ersetzt.
-- <pre>{COLOR}</pre>
-- Ersetze {COLOR} in deinen Texten mit einer der gelisteten Farben.
--
-- <table border="1">
-- <tr><th>Platzhalter</th><th>Farbe</th><th>RGBA</th></tr>
--
-- <tr><td>red</td>     <td>Rot</td>          <td>255,80,80,255</td></tr>
-- <tr><td>blue</td>    <td>Blau</td>         <td>104,104,232,255</td></tr>
-- <tr><td>yellow</td>  <td>Gelp</td>         <td>255,255,80,255</td></tr>
-- <tr><td>green</td>   <td>Grün</td>         <td>80,180,0,255</td></tr>
-- <tr><td>white</td>   <td>Weiß</td>         <td>255,255,255,255</td></tr>
-- <tr><td>black</td>   <td>Schwarz</td>      <td>0,0,0,255</td></tr>
-- <tr><td>grey</td>    <td>Grau</td>         <td>140,140,140,255</td></tr>
-- <tr><td>azure</td>   <td>Azurblau</td>     <td>255,176,30,255</td></tr>
-- <tr><td>orange</td>  <td>Orange</td>       <td>255,176,30,255</td></tr>
-- <tr><td>amber</td>   <td>Bernstein</td>    <td>224,197,117,255</td></tr>
-- <tr><td>violet</td>  <td>Violett</td>      <td>180,100,190,255</td></tr>
-- <tr><td>pink</td>    <td>Rosa</td>         <td>255,170,200,255</td></tr>
-- <tr><td>scarlet</td> <td>Scharlachrot</td> <td>190,0,0,255</td></tr>
-- <tr><td>magenta</td> <td>Magenta</td>      <td>190,0,89,255</td></tr>
-- <tr><td>olive</td>   <td>Olivgrün</td>     <td>74,120,0,255</td></tr>
-- <tr><td>sky</td>     <td>Himmelsblau</td>  <td>145,170,210,255</td></tr>
-- <tr><td>tooltip</td> <td>Tooltip-Blau</td> <td>51,51,120,255</td></tr>
-- <tr><td>lucid</td>   <td>Transparent</td>  <td>0,0,0,0</td></tr>
-- </table>
--
-- @param _Message Text oder Table mit Texten
-- @return Ersetzter Text
-- @within Anwenderfunktionen
--
-- @usage local Placeholder = API.ConvertPlaceholders("{scarlet}Dieser Text ist rot!");
-- local Placeholder2 = API.ConvertPlaceholders("{name:placeholder2} wird ersetzt!");
-- local Placeholder3 = API.ConvertPlaceholders("{type:U_KnightHealing} wird ersetzt!");
--
function API.ConvertPlaceholders(_Message)
    if type(_Message) == "table" then
        for k, v in pairs(_Message) do
            _Message[k] = ModuleInputOutputCore.Shared:ConvertPlaceholders(v);
        end
        return API.Localize(_Message);
    elseif type(_Message) == "string" then
        return ModuleInputOutputCore.Shared:ConvertPlaceholders(_Message);
    else
        return _Message;
    end
end

---
-- Fügt einen Platzhalter für den angegebenen Namen hinzu.
--
-- Innerhalb des Textes wird der Plathalter wie folgt geschrieben:
-- <pre>{name:YOUR_NAME}</pre>
-- YOUR_NAME muss mit dem Namen ersetzt werden.
--
-- @param[type=string] _Name        Name, der ersetzt werden soll
-- @param[type=string] _Replacement Wert, der ersetzt wird
-- @within Anwenderfunktionen
--
-- @usage API.AddNamePlaceholder("Scriptname", "Horst");
-- API.AddNamePlaceholder("Scriptname", {de = "Kuchen", en = "Cake"});
--
function API.AddNamePlaceholder(_Name, _Replacement)
    if type(_Replacement) == "function" or type(_Replacement) == "thread" then
        error("API.AddNamePlaceholder: Only strings, numbers, or tables are allowed!");
        return;
    end
    ModuleInputOutputCore.Shared.Placeholders.Names[_Name] = _Replacement;
end

---
-- Fügt einen Platzhalter für einen Entity-Typ hinzu.
--
-- Innerhalb des Textes wird der Plathalter wie folgt geschrieben:
-- <pre>{type:ENTITY_TYP}</pre>
-- ENTITY_TYP muss mit einem Entity-Typ ersetzt werden. Der Typ wird ohne
-- Entities. davor geschrieben.
--
-- @param[type=string] _Type        Typname, der ersetzt werden soll
-- @param[type=string] _Replacement Wert, der ersetzt wird
-- @within Anwenderfunktionen
--
-- @usage API.AddNamePlaceholder("U_KnightHealing", "Arroganze Ziege");
-- API.AddNamePlaceholder("B_Castle_SE", {de = "Festung des Bösen", en = "Fortress of evil"});
--
function API.AddEntityTypePlaceholder(_Type, _Replacement)
    if Entities[_Type] == nil then
        error("API.AddEntityTypePlaceholder: EntityType does not exist!");
        return;
    end
    ModuleInputOutputCore.Shared.Placeholders.EntityTypes[_Type] = _Replacement;
end

---
-- Das Dialog Modul ermöglicht es Dialogfenster anzuzeigen.
--
-- <b>Vorausgesetzte Module:</b>
-- <ul>
-- <li><a href="Swift_0_Core.api.html">(1) Core</a></li>
-- </ul>
--
-- @within Beschreibung
-- @set sort=true
--

---
-- Öffnet einen Info-Dialog. Sollte bereits ein Dialog zu sehen sein, wird
-- der Dialog der Dialogwarteschlange hinzugefügt.
--
-- <b>Hinweis</b>: Aus dem globalen Skript aufgerufen muss der Name der Action
-- als String angegeben werden. Es wird dann eine Funktion im lokalen Skript
-- als Aktion aufgerufen.
--
-- @param[type=string]   _Title  Titel des Dialog
-- @param[type=string]   _Text   Text des Dialog
-- @param                _Action Funktionsreferenz
-- @within Anwenderfunktionen
--
-- @usage
-- API.DialogInfoBox("Wichtige Information", "Diese Information ist Spielentscheidend!");
--
function API.DialogInfoBox(_Title, _Text, _Action)
    if not GUI then
        if _Action and type(_Action) ~= "string" then
            return;
        end
        Logic.ExecuteInLuaLocalState(string.format(
            [[ModuleInputOutputCore.Local:OpenDialog(%s, %s, %s)]],
            API.ConvertPlaceholders(API.Localize(_Title)),
            API.ConvertPlaceholders(API.Localize(_Text)),
            _Action
        ));
        return;
    end

    _Title = API.ConvertPlaceholders(API.Localize(_Title));
    _Text  = API.ConvertPlaceholders(API.Localize(_Text));
    return ModuleInputOutputCore.Local:OpenDialog(_Title, _Text, _Action);
end

---
-- Öffnet einen Ja-Nein-Dialog. Sollte bereits ein Dialog zu sehen sein, wird
-- der Dialog der Dialogwarteschlange hinzugefügt.
--
-- Um die Entscheigung des Spielers abzufragen, wird ein Callback benötigt.
-- Das Callback bekommt eine Boolean übergeben, sobald der Spieler die
-- Entscheidung getroffen hat.
--
-- <b>Hinweis</b>: Aus dem globalen Skript aufgerufen muss der Name der Action
-- als String angegeben werden. Es wird dann eine Funktion im lokalen Skript
-- als Aktion aufgerufen.
--
-- @param[type=string]   _Title    Titel des Dialog
-- @param[type=string]   _Text     Text des Dialog
-- @param                _Action   Funktionsreferenz
-- @param[type=boolean]  _OkCancel Okay/Abbrechen statt Ja/Nein
-- @within Anwenderfunktionen
--
-- @usage
-- function YesNoAction(_yes)
--     if _yes then GUI.AddNote("Ja wurde gedrückt"); end
-- end
-- API.DialogRequestBox("Frage", "Möchtest du das wirklich tun?", YesNoAction, false);
--
function API.DialogRequestBox(_Title, _Text, _Action, _OkCancel)
    if not GUI then
        if _Action and type(_Action) ~= "string" then
            return;
        end
        Logic.ExecuteInLuaLocalState(string.format(
            [[ModuleInputOutputCore.Local:OpenRequesterDialog(%s, %s, %s, %s)]],
            API.ConvertPlaceholders(API.Localize(_Title)),
            API.ConvertPlaceholders(API.Localize(_Text)),
            _Action,
            tostring(_OkCancel == true)
        ));
        return;
    end
    _Title = API.ConvertPlaceholders(API.Localize(_Title));
    _Text = API.ConvertPlaceholders(API.Localize(_Text));
    return ModuleInputOutputCore.Local:OpenRequesterDialog(_Title, _Text, _Action, _OkCancel);
end

---
-- Öffnet einen Auswahldialog. Sollte bereits ein Dialog zu sehen sein, wird
-- der Dialog der Dialogwarteschlange hinzugefügt.
--
-- In diesem Dialog wählt der Spieler eine Option aus einer Liste von Optionen
-- aus. Anschließend erhält das Callback den Index der selektierten Option.
--
-- <b>Hinweis</b>: Aus dem globalen Skript aufgerufen muss der Name der Action
-- als String angegeben werden. Es wird dann eine Funktion im lokalen Skript
-- als Aktion aufgerufen.
--
-- @param[type=string]   _Title  Titel des Dialog
-- @param[type=string]   _Text   Text des Dialog
-- @param                _Action Funktionsreferenz
-- @param[type=table]    _List   Liste der Optionen
-- @within Anwenderfunktionen
--
-- @usage
-- function OptionsAction(_idx)
--     GUI.AddNote(_idx.. " wurde ausgewählt!");
-- end
-- local List = {"Option A", "Option B", "Option C"};
-- API.DialogSelectBox("Auswahl", "Wähle etwas aus!", OptionsAction, List);
--
function API.DialogSelectBox(_Title, _Text, _Action, _List)
    if not GUI then
        if _Action and type(_Action) ~= "string" then
            return;
        end
        Logic.ExecuteInLuaLocalState(string.format(
            [[ModuleInputOutputCore.Local:OpenSelectionDialog(%s, %s, %s, %s)]],
            API.ConvertPlaceholders(API.Localize(_Title)),
            API.ConvertPlaceholders(API.Localize(_Text)),
            _Action,
            table.toString(_List)
        ));
        return;
    end
    _Title = API.ConvertPlaceholders(API.Localize(_Title));
    _Text = API.ConvertPlaceholders(API.Localize(_Text));
    _Text = _Text .. "{cr}";
    ModuleInputOutputCore.Local:OpenSelectionDialog(_Title, _Text, _Action, _List);
end

---
-- Bereitet die Texteingabe über den Chat Input vor.
--
-- <b>Hinweis</b>: Der Spieler kann den Input nicht mit Esc verlassen. Der Input
-- kann nur durch Enter geschlossen werden. Das dedeutet, dass evtl. ein leerer
-- String übergeben wird. In diesem Fall wurde nichts eingegeben.
--
-- @usage
-- API.ShowTextInput();
--
function API.ShowTextInput()
    if not GUI then
        Logic.ExecuteInLuaLocalState([[
            ModuleInputOutputCore.Local:PrepareInputVariable()
            ModuleInputOutputCore.Local:ShowInputBox()
        ]]);
    else
        ModuleInputOutputCore.Local:PrepareInputVariable();
        ModuleInputOutputCore.Local:ShowInputBox();
    end
end

