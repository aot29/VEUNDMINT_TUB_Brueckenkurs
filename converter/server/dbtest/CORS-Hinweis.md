Hinweise zu CORS (Cross Origin Resource Sharing)
===============================================

Wegen Cross Origin Resource Sharing funktioniert der Aufruf der API per Javascript nur dann, wenn man den Javascript-Code von derselben Domain geladen hat, auf die man zugreift. Für das Testen der API bedeutet dass, dass sich der Javascript-Code nicht testen lässt ohne ihn vorher auf den Server zu laden. Leider gibt es meines Wissens technisch keine Möglichkeit, das einfacher hinzubekommen, außer die same origin policy im Webbrowser komplett abzuschalten (was nicht zu empfehlen ist).

Für den Fall, dass sich das User-Management auf einem anderen Server befindet als der Javascript-Code, benötigt dieser zwei zusätzliche HTTP-Header ( kann man in der Apache-Config setzen ):
* `Header set Access-Control-Allow-Origin "http://domain.von.der.der.js-code.kommt"`, hier ist es nicht möglich, einfach `"*"` zu setzen, da dann der nächste Header nicht mehr funktioniert ( und somit keine Cookies mehr )
* `Header set Access-Control-Allow-Credential true` ( dieser Header ermöglicht die Nutzung von Cookies)

Quellen:
* http://stackoverflow.com/a/7189502/1717115
* https://developer.mozilla.org/en-US/docs/Web/HTTP/Access_control_CORS#Requests_with_credentials
