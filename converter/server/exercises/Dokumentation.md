Aufgabendatenbank
=================

Web-API
-------
Man kann eine Aufgabe abfragen indem man einen GET-Request an `get.php` schickt mit dem Parameter `id=..`, der die ID der Aufgabensammlung enthält.

Rückgabe ist ein JSON-String der folgenden Form:
```json
{
  "id": "Aufgabensammlungs-ID",
  "exercises": [
    {"AufgabenID1":"Inhalt Aufgabe1"},
    {"AufgabenID2":"Inhalt Aufgabe2"}
  ],
  "status": true
}
```

Im Fehlerfall:
```json
{
    "status": false,
    "error": "Fehlermeldung"
}
```

Kommandozeilen-Interface
------------------------
Mit `cli.php` kann man Aufgaben und Collections in der Datenbank verwalten. Siehe `./cli.php --help`
