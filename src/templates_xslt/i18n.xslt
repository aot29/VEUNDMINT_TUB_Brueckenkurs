<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

	<!-- 
	
	Change this to dynamic loading of strings, using built-in i18n dynamic loading, 
	but first change event handling, see issue #2 
	
	-->
	
	<xsl:template name="i18n">
		<xsl:param name="lang" />
		<xsl:choose>
		<xsl:when test="$lang = 'en'">
			<xsl:call-template name="i18n_en"/>
		</xsl:when>
		<xsl:otherwise>
			<xsl:call-template name="i18n_de"/>
		</xsl:otherwise>
	</xsl:choose>
	</xsl:template>
		
	<xsl:template name="i18n_en">
		<script>
			$.i18n().load( {en:{
				"@metadata": {
					"authors": [
						"Clara Hummel"
					],
					"last-updated": "2016-06-09",
					"locale": "$lang"
				},
				"msg-incorrect-input" : "Incorrect input",
				"msg-missing-input" : "No input",
				"msg-incorrect-answer" : "Incorrect answer",
				"msg-incorrect-value" : "Incorrect value",
				"msg-incorrect-quantity" : "Incorrect solution set",
				"msg-unanswered-question" : "Question has not been answered yet",
				"msg-still-incorrect-input" : "Input is not correct yet",
				"msg-correct-answer" : "This is a correct answer",
				"msg-malformed-input" : "Input form is incorrect",
				"msg-incorrect-interval" : "is not the desired interval",
				"msg-completed-test" : "$1 has been completed",
				"msg-reached-points" : "Scored points in test: $1",
				"msg-max-points" : "Maximal scored points: $1",
				"msg-dispatched-test" : "The test will be submitted if a minimum of one point has been scored.",
				"msg-not-dispatched-test" : "The test has not been submitted yet.",
				"msg-submitted-test" : "The test has been submitted. However it can still be edited and submitted again.",
				"msg-reached-point-ratio" : "$1% of points have been scored",
				"msg-transfered-result" : "Your score will be submitted for statistical analysis",
			
				"ui-userid" : "(ID: $1))",
				"ui-not-loggedin" : "Not logged in",
				"ui-max-points" : "Points scored: $1 of $2",
				"ui-reached-points" : "Points scored: $1",
				"ui-necessary-points" : "Total score: $1",
				"ui-missing-tooltip" : "(there wil be no tips during the test)",
				"ui-login" : "Log in",
				"ui-course-data" : "Course data",

				"VBKM_MISCCOURSEDATA": "My course data",
				"VBKM_MISCSEARCH": "Search",
				"VBKM_MISCSETTINGS": "Register for the course",
				"VBKM_MISCLOGIN" : "Log in",
				"VBKM_MISCLOGOUT" : "Log out",
				"VBKM_MISCFAVORITES" : "Favorites",
			
				"hint-databutton" : "Course data",
				"hint-homebutton" : "Back to course homepage",
				"hint-listebutton" : "View index",
				"hint-menubutton" : "Click here to show or hide navigation bar",
				"hint-zoominbutton" : "Increases font size",
				"hint-zoomoutbutton" : "Decreases font size",
				"hint-settingsbutton" : "Settings",
				"hint-confbutton" : "Shows preferences and other settings",
				"hint-loginbutton" : "Register for the course",
				"ui-loginbutton" : "Login",
				"hint-logout" : "The course will be closed and the data for user $1 will be saved.",
				"hint-sharebutton" : "Share this page",
				"hint-favoritesbutton" : "Current favourites",
			
				"msg-shared-page" : "Share this page via:",
				"msg-current-favorites" : "Current favourites",
				"msg-failed-connection" : "Communication with platform failed. The course can only be worked on anonymously",
				"msg-failed-userdata" : "Your user data could not be downloaded from server. An automated email has been sent to the administrator. However you can work on the course anonymously, entered answers will not be saved though",
			
				"ui-no-user" : "No user logged in",
				"ui-unknown-user" : "User $1 ($2 $3), not logged onto server",
				"ui-known-user" : "User $1 ($2 $3) logged onto server",
				"ui-username" : "Username",
				"ui-password" : "Password",
				"ui-login" : "Log in",
				"ui-loginbutton" : "Log in",
				"ui-logout" : "Logout ($1)",
				"ui-logoutbutton" : "Logout",
				"ui-signupbutton" : "Register for the course",

				"hint-loginbutton" : "Here you can register for the course. The course is currently worked on anonymously",
				"msg-local-persistence" : "Data will only be stored in this browser and on this computer",
				"msg-no-persistence" : "No course data will be saved",
				"msg-long-username" : "User $1",
				"msg-scorm-username" : "User  $1 $2",
				"msg-missing-userdata" : "No user data available yet. The course will be worked on anonymously",
				"msg-persistence-both" : "Data will be stored in this browser and on server",
				"msg-failed-login" : "Log in failed",
				"msg-missing-logindata" : "No log in data found",
				"msg-missing-browserdata" : "No log in data saved in browser",
				"msg-persistence-deactivated" : "Data storage has been deactivated by the user, no course data will be stored",
				"msg-failed-localpersistence" : "The browser can not store local data. Input in input boxes will not be saved",
				"msg-successful-localpersistence" : "The browser can store course data, $1 Bytes are occupied by course data",
				"msg-total-progress" : "Visited $1 of $2 module units altogether",
				"msg-total-points" : "Scored $1 out of $2 points in the exercises altogether",
				"msg-total-test" : "Scored $1 of $2 points in the final test altogether.",
				"msg-failed-test" : "Final test has not been passed yet",
				"msg-passed-test" : "Final test PASSED",
				"msg-change-localpersistence" : "The browser can not store local data, input in input boxes will not be saved. If applicable modify your selections on the settings page",
				"msg-confirm-persistence" : "Without local data storage your user data and course data will be lost. Do you want to continue anyways?",
				"msg-repeat-login" : "Username or password are incorrect. Please try again",
				"msg-confirm-reset" : "Do you really want to delete all course data $1? This process can not be undone",
				"msg-confirm-delete" : "Do you really want to delete all user data and course data $1? This process can not be undone",
				"msg-badlength-username" : "Your log in name  must contain a minimum of 6 and a maximum of 18 characters",
				"msg-badchars-username" : "Your log in name can only contain Latin characters, numbers and the special characters _-+",
				"msg-badlength-password" : "Your password must contain a minimum of 6 and a maximum of 18 characters",
				"msg-badchars-password" : "Your password can only contain Latin characters, numbers and the special characters _-+",
				"msg-failed-createuser" : "Data can not be stored, user can not be created",
				"msg-activate-localpersistence" : "Data can not be stored, local data storage has to be activated in settings first",
				"msg-prompt" : "Enter a password for user $1:",
				"msg-repeat-prompt" : "Please enter your password again",
				"msg-inconsistent-password" : "The passwords do not match",
				"msg-duplicate-username" : "The user $1 already exists on the server, please enter a new username",
				"msg-failed-createuser" : "User $1 could not be created. Please try again later. The user will only be created in the browser",
				"msg-unavailable-username" : "The username has already been taken",
				"msg-available-username" : "This username is available.",
				"msg-failed-server" : "Communication with server \"$1\" failed",
				"msg-unavailable-login" : "Login failed!",
				"msg-duplicate-username" : "Username $1 exists already on the server, please choose another username.",
				"msg-myaccount" : "My account",
			
				"explanation_subsection": "Introduction to the subject",
				"explanation_xcontent": "Learning step",
				"explanation_exercises": "Exercises",
				"explanation_test": "Final test",
				"chapter": "Chapter",
				"subsection": "Section",
				"module_starttext": "Launch module",
				"module_solutionlink": "See the solution",
				"module_solution": "Solution",
				"module_solutionback": "Back to the exercise",
				"module_content": "Course Content",
				"module_moreinfo": "More information",
				"module_helpsitetitle": "Start page",
				"module_labelprefix": "Module",
				"subsection_labelprefix": "Section",
				"subsubsection_labelprefix": "Subsection",
				"exercise_labelprefix": "Exercise",
				"example_labelprefix": "Example",
				"experiment_labelprefix": "Experiment",
				"image_labelprefix": "Image",
				"table_labelprefix": "Table",
				"equation_labelprefix": "Equation",
				"theorem_labelprefix": "Theorem",
				"video_labelprefix": "Video",
				"brokenlabel": "(VERWEIS)",
				"feedback_sendit": "Send feedback",
				"qexport_download_tex": "Source code of this exercise in LaTeX format",
				"qexport_download_doc": "Source code of this exercise in Word-Format",
				"message_done": "All exercises solved",
				"message_progress": "Exercises partially solved",
				"message_problem": "Some answers are incorrect",
				"modstartbox_tocline": "This module has the following sections:",
				"legend" : "Legend",
				"roulette_text": "In the online version, exercises from an exercise list will be shown here",
				"roulette_new": "New exercise",
				"roulette_instruction": "Reduce as far as possible",
				"course-title": "Preparatory Online Course in Mathematics",
				}
				} );
		</script>
	</xsl:template>
	
	<xsl:template name="i18n_de">
		<script>
			$.i18n().load( {de:{
				"@metadata": {
					"authors": [
						"Alvaro Ortiz"
					],
					"last-updated": "2016-06-03",
					"locale": "de"
				},
				"msg-incorrect-input" : "Fehlerhafte Eingabe",
				"msg-missing-input" : "Keine Eingabe",
				"msg-incorrect-answer" : "Lösung inkorrekt",
				"msg-incorrect-value" : "Wert inkorrekt",
				"msg-incorrect-quantity" : "Lösungsmenge inkorrekt",
				"msg-unanswered-question" : "Frage noch nicht beantwortet",
				"msg-still-incorrect-input" : "Eingabe ist noch nicht richtig",
				"msg-correct-answer" : "Dies ist eine richtige Lösung",
				"msg-malformed-input" : "Form der Eingabe ist fehlerhaft",
				"msg-incorrect-interval" : "Ist nicht das gesuchte Intervall",
				"msg-completed-test" : "$1 wurde abgeschlossen",
				"msg-reached-points" : "Im Test erreichte Punkte: $1",
				"msg-max-points" : "Maximal erreichte Punkte: $1",
				"msg-dispatched-test" : "Der Test wird abgeschickt, wenn mindestens ein Punkt erreicht wurde.",
				"msg-not-dispatched-test" : "Der Test ist noch nicht abgeschickt.",
				"msg-submitted-test" : "Test ist eingereicht, kann aber weiter bearbeitet und erneut abgeschickt werden.",
				"msg-reached-point-ratio" : "Es wurden $1% der Punkte erreicht!",
				"msg-transfered-result" : "Die Punktzahl wurde zur statistischen Auswertung übertragen",
				"ui-userid" : "(ID: $1))",
				"ui-not-loggedin" : "Nicht angemeldet",
				"ui-max-points" : "Punkte erreicht: $1 von $2",
				"ui-reached-points" : "Punkte erreicht: $1",
				"ui-necessary-points" : "Punkte zu erreichen: $1",
				"ui-missing-tooltip" : "(im laufenden Test keine Tipps)",
				"ui-login" : "Anmelden",
				"ui-course-data" : "Kursdaten",
				
				"VBKM_MISCCOURSEDATA": "Meine Kursdaten",
				"VBKM_MISCSEARCH": "Suchen",
				"VBKM_MISCSETTINGS": "Anmeldung zum Kurs",
				"VBKM_MISCLOGIN" : "Benutzer anmelden",
				"VBKM_MISCLOGOUT" : "Logout",
				"VBKM_MISCFAVORITES" : "Aktuelle Favoriten",
				
				"hint-homebutton" : "Zurück zur Homepage des Kurses",
				"hint-databutton" : "Meine Kursdaten anzeigen",
				"hint-listebutton" : "Stichwortverzeichnis anzeigen",
				"hint-menubutton" : "Hier klicken um Navigationsleisten ein- oder auszublenden",
				"hint-zoominbutton" : "Vergrößert die Schriftgröße",
				"hint-zoomoutbutton" : "Verkleinert die Schriftgröße",
				"hint-settingsbutton" : "Zeigt persönliche Daten zum Kurs und weitere Einstellungen an",
				"hint-loginbutton" : "Hier können Sie sich zum Kurs persönlich anmelden, im Moment wird der Kurs anonym bearbeitet.", 
				"ui-loginbutton" : "Anmelden",
				"hint-logout" : "Der Kurs wird geschlossen und die eingegebenen Daten für Benutzer $1 gespeichert.",
				"hint-sharebutton" : "Diese Seite teilen",
				"hint-favoritesbutton" : "Aktuelle Favoriten",

				"msg-shared-page" : "Diese Seite teilen über:",
				"msg-current-favorites" : "Aktuelle Favoriten:",
				"msg-failed-connection" : "Kommunikation der Lernplattform fehlgeschlagen, Kurs kann nur anonym bearbeitet werden!",
				"msg-failed-userdata" : "Ihre Benutzerdaten konnten nicht vom Server geladen werden, eine automatische eMail an den Administrator wurde verschickt. Sie können den Kurs trotzdem anonym bearbeiten, eingetragene Lösungen werden jedoch nicht gespeichert!",
				"ui-no-user" : "Kein Benutzer angemeldet",
				"ui-unknown-user" : "Benutzer $1 ($2 $3), nicht am Server angemeldet",
				"ui-known-user" : "Benutzer $1 ($2 $3) am Server angemeldet",
				"ui-username" : "Benutzername",
				"ui-password" : "Passwort",
				"ui-login" : "Benutzer anmelden",
				"ui-loginbutton" : "Anmelden",
				"ui-logoutbutton" : "Abmelden",
				"ui-signupbutton" : "Account erstellen",
				"ui-logout" : "Logout ($1)",
			
				"msg-local-persistence" : "Datenspeicherung nur in diesem Browser und diesem Rechner.",
				"msg-no-persistence" : "Es werden kene Kursdaten gespeichert.",
				"msg-long-username" : "Benutzername $1",
				"msg-scorm-username" : "Benutzer $1 $2",
				"msg-missing-userdata" : "Noch keine Benutzerdaten vorhanden, Kurs wird anonym bearbeitet",
				"msg-persistence-both" : "Datenspeicherung in diesem Browser und auf dem Server",
				"msg-failed-login" : "Anmeldevorgang gescheitert!",
				"msg-missing-logindata" : "Keine Anmeldedaten gefunden!",
				"msg-missing-browserdata" : "Keine Anmeldedaten im Browser gespeichert!",
				"msg-persistence-deactivated" : "Datenspeicherung wurde durch den Benutzer deaktiviert, es werden keine Kursdaten gespeichert.",
				"msg-failed-localpersistence" : "Der Browser kann keine lokalen Daten speichern, Eingaben in Aufgabenfeldern werden nicht gespeichert.",
				"msg-successful-localpersistence" : "Der Browser kann die Kursdaten speichern, es werden momentan $1 Bytes durch Kursdaten belegt.",
				"msg-total-progress" : "Insgesamt $1 von $2 Lerneinheiten des Moduls besucht.",
				"msg-total-points" : "Insgesamt $1 von $2 Punkten der Aufgaben erreicht.",
				"msg-total-test" : "Insgesamt $1 von $2 Punkten im Abschlusstest erreicht.",
				"msg-failed-test" : "Abschlusstest ist noch nicht bestanden.",
				"msg-passed-test" : "Abschlusstest ist BESTANDEN.",
				"msg-change-localpersistence" : "Der Browser kann keine lokalen Daten speichern, Eingaben in Aufgabenfeldern werden nicht gespeichert. Modifizieren Sie ggf. die Auswahl auf der Einstellungsseite.",
				"msg-confirm-persistence" : "Ohne lokale Datenspeicherung gehen die Benutzer- und Kursdaten verloren. Trotzdem ohne Datenspeicherung fortfahren?",
				"msg-repeat-login" : "Benutzername oder Passwort sind nicht korrekt, bitte versuchen Sie es nochmal.",
				"msg-confirm-reset" : "Wirklich alle Kursdaten $1 löschen? Dieser Vorgang kann nicht rückgängig gemacht werden!",
				"msg-confirm-delete" : "Wirklich alle Benutzer- und Kursdaten $1 löschen? Dieser Vorgang kann nicht rückgängig gemacht werden!",
				"msg-badlength-username" : "Der Loginname muss mindestens 6 und höchstens 18 Zeichen enthalten",
				"msg-badchars-username" : "Im Loginnamen sind nur lateinische Buchstaben und Zahlen sowie die Sonderzeichen _-+ erlaubt.",
				"msg-badlength-password" : "Das Passwort muss mindestens 6 und höchstens 18 Zeichen enthalten",
				"msg-badchars-password" : "Im Passwort sind nur lateinische Buchstaben und Zahlen sowie die Sonderzeichen _-+ erlaubt.",
				"msg-failed-createuser" : "Keine Datenspeicherung möglich, kann Benutzer nicht anlegen",
				"msg-activate-localpersistence" : "Keine Datenspeicherung möglich, lokale Datenspeicherung muss zuerst in den Einstellungen aktiviert werden.",
				"msg-prompt" : "Geben Sie das Passwort für den Benutzer $1 ein:",
				"msg-repeat-prompt" : "Geben Sie das Passwort zur Sicherheit nochmal ein:",
				"msg-inconsistent-password" : "Die Passwörter stimmen nicht überein.",
				"msg-failed-createuser" : "Benutzer $1 konnte nicht angelegt werden, versuchen Sie es zu einem anderen Zeitpunkt nochmal. Der Benutzer wird nur im Browser angelegt.",
				"msg-unavailable-username" : "Benutzername ist schon vergeben.",
				"msg-available-username" : "Dieser Benutzername ist verfügbar.",
				"msg-failed-server" : "Kommunikation mit dem Server \"$1\" nicht möglich",
				"msg-unavailable-login" : "Keine Anmeldung möglich!",
				"msg-duplicate-username" : "Benutzer $1 existiert schon auf dem Server, bitte geben Sie einen neuen Benutzernamen ein.",
				"msg-myaccount" : "Mein Account",
			
				"explanation_subsection": "Einführung in Thema",
				"explanation_xcontent": "Lernabschnitt",
				"explanation_exercises": "Übungsaufgaben",
				"explanation_test": "Abschlusstest",
				"chapter": "Kapitel",
				"subsection": "Abschnitt",
				"module_starttext": "Modul starten",
				"module_solutionlink": "Lösung ansehen",
				"module_solution": "Lösung",
				"module_solutionback": "Zurück zur Aufgabe",
				"module_content": "Kursinhalt",
				"module_moreinfo": "Mehr Informationen",
				"module_helpsitetitle": "Einstiegsseite",
				"module_labelprefix": "Modul",
				"subsection_labelprefix": "Abschnitt",
				"subsubsection_labelprefix": "Unterabschnitt",
				"exercise_labelprefix": "Aufgabe",
				"example_labelprefix": "Beispiel",
				"experiment_labelprefix": "Experiment",
				"image_labelprefix": "Abbildung",
				"table_labelprefix": "Tabelle",
				"equation_labelprefix": "Gleichung",
				"theorem_labelprefix": "Satz",
				"video_labelprefix": "Video",
				"brokenlabel": "(VERWEIS)",
				"feedback_sendit": "Meldung abschicken",
				"qexport_download_tex": "Quellcode dieser Aufgabe im LaTeX-Format",
				"qexport_download_doc": "Quellcode dieser Aufgabe im Word-Format",
				"message_done": "Alle Aufgaben gelöst",
				"message_progress": "Aufgaben teilweise gelöst",
				"message_problem": "Einige Aufgaben falsch beantwortet",
				"modstartbox_tocline": "Dieses Modul gliedert sich in folgende Abschnitte:",
				"legend" : "Legende",
				"roulette_text": "In der Onlineversion erscheinen hier Aufgaben aus einer Aufgabenliste",
				"roulette_new": "Neue Aufgabe",
				"roulette_instruction": "Kürzen Sie soweit möglich",
				"course-title": "Onlinebrückenkurs Mathematik"
			}
			} );
		</script>
	</xsl:template>

</xsl:stylesheet>