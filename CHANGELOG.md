# Change Log
All notable changes to this project should be documented in this file.

## 04.09.2016 - <TODAY>
### Added
- this changelog :ok_hand:
- ssh support
- moodle build script (`gulp scorm`)
- math4refugees and matet shows the new version
- added new test for tab navigation
- added new tests for intersite obj (are scores saved there)
- added new test for checking that old userinput is entered in input fields
- tests now do not show ConnectionRefused Errors anymore, and pipline succeeds on default (changed phantomjs version in package.json)

### Fixed
- user input is now reloaded into input fields again #68

## 03.09.2016
* Neue Converter- Anweisungen im README, oder sieh TUB-Beta-Version (http://guest6.mulf.tu-berlin.de/beta/)
* Alle Englische Texte und Korrekturen
* Responsive Design (auch für Handy und Tablet geeignet), refaktorisiert auf Bootstrap, XSLT Templates und eigene Renderer Klasse
* Javascript und CSS eingebaut über Package Manager (Gulp, Bower)
* Javascript Refaktorisierung von intersite als eigenes JS modul
* TTM refaktorisiert auf eigene Parser Klasse
* Continuous Integration über GitLab läuft (http://guest6.mulf.tu-berlin.de/gitlab-ci/)
* Test Coverage läuft (http://guest6.mulf.tu-berlin.de/gitlab-ci/coverage/)
* TU-Berlin Feedback Server läuft

## 11.08.2016
* Test Coverage läuft (http://guest6.mulf.tu-berlin.de/gitlab-ci/coverage/)
* Feedback Server läuft (http://guest6.mulf.tu-berlin.de/server/feedbacktool/showstatistics.html)
* TTM refaktorisiert auf eigene Parser Klasse
* Responsive Design eingebaut, refaktorisiert auf Bootstrap, XSLT Templates und eigene Renderer Klasse
* Neue Englische Texte und Korrekturen En und De

(Angefangen)
* Login geht soweit. Neuer Server mit Django angefangen.
* Automatisches Testen und Bauen (https://gitlab.tubit.tu-berlin.de/stefan.born/VEUNDMINT_TUB_Brueckenkurs/pipelines)
* Javascript Packetmanager eingebaut und Refaktorisierung
* Mintmod Refaktorisierung
* UML-Diagramme, Dokumentation im Wiki

(To do)
* Bislang keine Übernahme von TUB-Entwicklungen in der Codebasis vom KIT
* Bislang keine Rückmeldung von der RWTH Aachen

## 25.07.2017
* Korrigierte englische Texte.
* Korrigierte Lösungen.
* Anmeldung/Login/Logout funktioniert (Konto löschen nicht).
* Unit-Test Framework und Tests in /src/test/ ausarbeitet.
* Build Skripts in /tools/makefiles ausarbeitet.

## 07.07.2016
* Internationalisierung: die ersten 3 Kapitel der Englischen Version sind da.
* Internationalisierung: Eine 2-sprachige EN- / DE- Version kann jetzt mithilfe einer Make-Datei erstellt werden (tools/makefiles/multilang).
* Benutzerfreundlichkeit: Eine statische Testseite soll als Proof-of-Concept für Responsive Design dienen (tu9bootstrapVersion).

## 20.06.2016
* Internationalisierung: UI-Texte sind jetzt in src/files/i18n. Texte in Javascript- (src/files) und Python- (src/plugins/VEUNDMINT/Option.py) Dateien sind entsprechend angepasst.
* Internationalisierung: Englische Übersetzung des Kapitel 1 Mathematikkurs (module_veundmint/VBKM01/vbkm01_eng.tex) sowie Makros (src/tex/mintmod_engl.tex) hinzugekommen
* Internationalisierung: Es ist jetzt möglich, nur die Deutsche oder nur die Englische Version des Kurses zu bauen (src/plugins/VEUNDMINT/Option.py). Später soll es möglich sein, beide Versionen gleichzeitig zu bauen.
* Tests: Systemtestssuite von Unit Tests in src/tests/sytemtests
