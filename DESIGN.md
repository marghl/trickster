# Trickster

## Status

Framework API v1 als frischer Kern implementiert. Die erste namenlose Persona der Tiefe ist mit einem harmlosen akustischen Streich angeschlossen. Weitere Streiche, Beziehungsreaktionen, Interaktionsstufenauswahl, Balancing und Spieltests stehen noch aus. Die frühere Prototyp-Implementierung befindet sich getrennt in `agi_hammerthief` und ist nicht Bestandteil des neuen Kerns.

## Grundidee

Das Projekt ist ein **Trickster-System für mehrere Naturgeister**. Der zuerst implementierte Kontext ist ein boshafter, vermutlich mythischer Geist der Tiefe, der in Bergwerken für Streiche, Ärger und unerklärliche Zwischenfälle verantwortlich gemacht wird.

Der Geist der Tiefe soll primär subtilen „Brainfuck“ veranstalten: kleine Veränderungen, die auch ein Versehen, eine falsche Erinnerung oder ein übersehenes Detail sein könnten. Der Spieler soll ein wenig an seinen Sinnen zweifeln, ohne dass ein Naturgeist offen als Ursache bestätigt wird.

Andere Naturgeister können später eigene Gebiete, Temperamente, Zeichen, Beziehungen und Gefahren besitzen. Sie verwenden denselben technischen Kern, sollen sich aber nicht wie umbenannte Varianten desselben Ereignisgenerators anfühlen.

## Designziele

- Eine stimmige, bergwerksbezogene Spielmechanik
- Subtile, seltene und schwer beweisbare Veränderungen
- Überraschende und schelmische Ereignisse statt eines gewöhnlichen Monsters
- Irritation und begrenzte Gefahr ohne unfairen oder unvermeidbaren Verlust
- Gute Einbindung in das bestehende Minetest-Spiel
- Verständliche Konfiguration für Serverbetreiber
- Möglichst geringe Abhängigkeit von anderen Mods
- Geschichten durch beobachtbare Ereignisse entstehen lassen, nicht durch vorgefertigte Erzählungen
- Spielern Raum für widersprüchliche Deutungen und eigene Serverlegenden geben
- Automatische Ereignisse und gelegentliche manuelle Auftritte konsistent derselben Persona zuordnen

## Trickster-System und Personas

**Trickster** bezeichnet den gemeinsamen technischen und dramaturgischen Rahmen, nicht eine einzelne Figur. Als Inspiration für Naturgeister und Verhaltensweisen eignen sich Klabautermann, Puck, Nis Puk und Rübezahl: Sie poltern, verwirren, warnen, helfen, bestrafen und bleiben in ihren Motiven schwer berechenbar.

Der Geist der Tiefe ist weder gewöhnlicher Questgeber noch gewöhnlicher Gegner. Er verwirrt, neckt, hilft oder warnt gelegentlich und kann bei passendem Anlass gefährlich werden. Seine Identität entsteht aus Domäne, wiederkehrenden Eigenheiten, Zeichen und Konsequenzen, nicht aus einem Namen, einer sichtbaren Figur oder erklärendem Text.

### Namenslosigkeit

Kein Naturgeist besitzt einen vom System veröffentlichten oder im Quellcode versteckten kanonischen Namen. Die Mod arbeitet ausschließlich mit Kontext, Verhalten und Umschreibungen. Interne Schlüssel wie `profile_01` oder `underground_01` sind bedeutungsarme technische Identifikatoren und keine Namen innerhalb der Spielwelt.

Bezeichnungen, wahre Namen, Sagen und Beziehungen entstehen ausschließlich durch Deutungen der Spieler. Die Mod bestätigt oder widerlegt diese Namen nicht und benötigt keine externe kanonische Sagensammlung.

### Persona-Modell

Jeder Naturgeist definiert mindestens:

- **Domäne:** beispielsweise Bergwerk, Wald, Wasser, Wetter oder verlassene Gebäude
- **Aktivierungsbedingungen:** Ort, Zeit, Alleinsein, Tätigkeit und Vorgeschichte
- **Temperament:** verspielt, neugierig, hilfreich, nachtragend oder feindselig
- **Zeichen:** Geräusche, Muster, Symbole und typische Veränderungen
- **Streiche und Gaben:** erlaubte Ereignisfamilien und deren Gewichtung
- **Gefahrenprofil:** erlaubte Schadensarten, Stärke und Abbruchbedingungen
- **Gedächtnis:** Beziehungen, frühere Begegnungen und offene Ereignisketten
- **Tabus:** Dinge, die diese Persona niemals tut

Der gemeinsame Kern stellt Scheduler, Gedächtnis, Schutzprüfungen, Transaktionen, Protokollierung und Regie bereit. Die Personas liefern Charakter und konkrete Ereignisse.

### Verbindliche Trennung von Persona und Wirkung

Jede Persona wird als eigenes Erweiterungspaket in einem eigenen Unterverzeichnis geführt. Dieses Paket beschreibt Persönlichkeit, Domäne, Aktivierungsbedingungen, Absichten, Gewichtungen, Tabus und die zugehörigen Streiche. Es bindet sich ausschließlich über eine definierte Registrierungs- und Erweiterungsschnittstelle an den gemeinsamen Kern an. Der Kern darf keine Kenntnis von der konkreten Identität oder Erzählung einer Persona benötigen.

Personas und Streiche dürfen keine Weltwirkung unmittelbar ausführen. Sie formulieren ausschließlich einen Ereigniswunsch oder Ereignisplan und fordern dafür ausdrücklich freigegebene Fähigkeiten des Frameworks an. Das gilt für:

- Nodes und Metadaten
- Spieler- und Fremdinventare
- Gesundheit, Bewegung und andere Spielerzustände
- Geräusche, Partikel und sonstige wahrnehmbare Effekte
- persistente Daten, Cooldowns und Beziehungen

Nur das Framework darf solche Wirkungen tatsächlich ausführen. Vor jeder Ausführung validiert es Ziel, aktuellen Zustand, Schutzrechte, Leistungsbudget, Cooldowns, Rücksetzbarkeit und alle weiteren Sicherheitsbedingungen erneut. Es führt die Wirkung atomar oder zuverlässig rücksetzbar aus, protokolliert das Ergebnis und meldet der Persona lediglich Erfolg, Ablehnung oder einen bedeutungsarmen Fehlergrund zurück.

Diese Grenze ist Teil der atomaren Sicherheitsregel. Eine Persona darf weder direkte Luanti-Manipulationsfunktionen für ihre Streiche verwenden noch Sicherheitsprüfungen ersetzen, abschwächen oder umgehen. Benötigt ein neuer Streich eine bisher unbekannte Wirkungsklasse, muss zuerst eine allgemeine, geprüfte Framework-Fähigkeit entworfen und freigegeben werden. Bis dahin ist der Streich nicht ausführbar.

Vorgesehene Entwicklungsreihenfolge:

1. gemeinsames Framework und sichere Fähigkeiten
2. Persona-Registrierung und Persona-Modell
3. Beziehung, Absicht und Auswahl der Interaktionsstufe
4. konkrete Streiche als Persona-Erweiterungen

### Akteursgebundene Handlungen mit `fakelib`

Für Handlungen, die regulär von einem Spieler ausgehen könnten, soll das Framework `fakelib` als Abhängigkeit und Kompatibilitätsadapter verwenden. Es erzeugt dafür einen Fake-Player mit Name, Position, Blickrichtung und – falls erforderlich – Inventarreferenz des betroffenen Spielers. Dadurch können bestehende Protection-, Eigentums-, Node- und Inventar-Callbacks die Handlung unter denselben Bedingungen beurteilen wie eine gewöhnliche Spielerhandlung.

Der Fake-Player ist keine Sicherheitsgarantie und erteilt niemals selbst eine Freigabe. Das Framework muss weiterhin alle Vorbedingungen prüfen, die passenden `allow_*`-Callbacks aufrufen, den Zustand unmittelbar vor der Änderung erneut vergleichen, die Änderung transaktional ausführen und anschließend die zugehörigen `on_*`-Callbacks benachrichtigen. Mods dürfen Fake-Player erkennen oder ablehnen; in diesem Fall wird die Handlung verworfen.

### Freigegebene Behälter und Inventaroperationen

Das Framework darf Gegenstände in einem Node-Inventar einlegen, daraus entnehmen oder innerhalb beziehungsweise zwischen freigegebenen Inventaren verschieben. Eine pauschale Freigabe aller Inventare ist ausgeschlossen. Stattdessen besitzt jeder unterstützte Behälter ein explizites Fähigkeitsprofil mit mindestens:

- exaktem Node-Namen
- erlaubten Inventarlisten
- getrennten Rechten für Einlegen, Entnehmen und Verschieben
- Mengen- und Stackgrenzen pro Ereignis
- erforderlichen Protection-, Eigentums- und Callback-Prüfungen
- Regeln für zulässige Quellen, Ziele und Umwandlungen
- Rücksetz- und Protokollierungsverfahren

Zunächst werden nur einfache, ausdrücklich freigegebene Behälter unterstützt. Shops, Verkaufsautomaten, Maschinen, Produktionsinventare, Netzwerk-Inventare und unbekannte Nodes stehen nicht auf der Whitelist. Zusätzlich wird eine Blacklist für direkt verbundene Automatisierungs- und Maschinenkomponenten geführt, beispielsweise Tubes, Hopper, Sortierer und Controller. Befindet sich eine solche Verbindung an einem ansonsten erlaubten Behälter, wird das Ereignis verworfen.

Die Blacklist ist nur eine zusätzliche Sperre. Fehlende Blacklist-Einträge dürfen niemals ein unbekanntes Inventar freigeben. Eine unbegrenzte Suche durch Inventarnetze findet nicht statt; bei unklarer oder nicht mit engem Budget prüfbarer Verbindung wird abgebrochen.

### Wirkungstresor und Erfüllungsverträge

Entnommene Gegenstände dürfen vorübergehend in einem persistenten, transaktionsgesicherten Wirkungstresor verwahrt werden. „Rückgabe“ ist dabei weiter gefasst und kann drei Formen haben:

1. **Identische Rückgabe:** derselbe Gegenstand wird wieder bereitgestellt.
2. **Gleichwertige Rückgabe:** Art und Menge bleiben materiell gleich, Ort oder konkrete Stacks dürfen sich ändern.
3. **Umgewandelte Rückgabe:** das Material wird nach einem ausdrücklich freigegebenen Rezept Bestandteil einer bleibenden Wirkung, beispielsweise eines gebauten Baumes.

Jede Entnahme benötigt vorab einen vollständigen Erfüllungsvertrag. Dieser nennt Quelle, Gegenstände, Menge, Zweck, Zielwirkung, erlaubtes Umwandlungsrezept, Erfolgskriterium und Rückfallweg. Das Framework entscheidet nicht frei über ungefähren Wert oder symbolische Gleichwertigkeit. Ein Geräusch, eine Spur oder ein wertloser Gegenstand kann daher nicht nachträglich als Ausgleich für entnommenen Besitz gelten.

Der Ablauf lautet grundsätzlich:

```text
Plan und vollständige Zielwirkung prüfen
→ Material transaktional im Wirkungstresor sichern
→ Ausgangszustand und Rückfallweg persistent vormerken
→ Wirkung atomar oder wiederaufnehmbar ausführen
→ vollständige Erfüllung kontrollieren
→ Material als eingelöst markieren und Transaktion abschließen
```

Scheitert die Wirkung oder bleibt ihr Zustand unklar, wird das Material nicht als eingelöst markiert. Es bleibt gesichert und muss identisch oder gleichwertig zurückgegeben werden können. Mehrteilige Bauwirkungen dürfen keine fremden Nodes überschreiben, benötigen ein festes Größenbudget und müssen Schutzrechte sowie geladene Weltbereiche für sämtliche Zielpositionen vor der Entnahme prüfen.

### Doppelte Herkunftsprotokollierung

Eine mit `fakelib` ausgeführte Handlung darf in gewöhnlichen Spiel- oder Mod-Protokollen unter dem Namen des betroffenen Spielers erscheinen. Dies unterstützt die erzählerische Behauptung, der Spieler habe die Veränderung selbst vorgenommen. Das Verhalten fremder Mods wird dabei nicht erzwungen: Sie dürfen Fake-Player kennzeichnen, ignorieren oder ablehnen.

Die tatsächliche Urheberschaft darf niemals aus dem geschützten Diagnose- und Transaktionsprotokoll verschwinden. Jede solche Handlung erhält dort mindestens Transaktionskennung, Persona-ID, betroffenen Spieler, tatsächliche Ausführungsquelle, Wirkung, Materialbewegungen und Ergebnis. Die Herkunft wird eindeutig unterschieden:

- `player_initiated`
- `trickster_acting_as_player`
- `admin_directed`
- `automatic_persona_event`

Gewöhnliche Logs dürfen somit Teil der Täuschung sein; Sicherheits-, Diagnose- und Transaktionslogs bleiben wahrheitsgemäß und vollständig.

## Erscheinung

- Der Geist der Tiefe besitzt praktisch keine sichtbare Textur.
- Er besitzt keine sinnvoll angreifbare Hitbox.
- Er tritt nicht als gewöhnliches Mob auf und soll nicht wie ein gewöhnliches Mob bekämpft werden.
- Seine Anwesenheit wird fast ausschließlich durch Veränderungen der Umgebung bemerkbar.
- Direkte Meldungen, Namensanzeigen und eindeutige Partikeleffekte werden vermieden.

## Streiche

### Lichtquellen versetzen

Der Geist der Tiefe kann eine Lichtquelle an eine nahe gelegene, plausible Position verschieben. Die ursprüngliche und die neue Position müssen für die jeweilige Lichtquelle geeignet sein. Der Streich darf keine geschützten Bereiche verändern.

### Licht flackern lassen

Der Geist kann eine nahe Lichtquelle kurzzeitig schwächer werden oder erlöschen lassen und anschließend zuverlässig den ursprünglichen Zustand wiederherstellen. Das Flackern soll kurz, selten und leicht als Engine- oder Wahrnehmungseffekt misszuverstehen sein. Die Wiederherstellung muss auch bei Serverneustart und unerwartetem Abbruch gesichert sein.

### Inventar umsortieren

Der Geist kann ein Werkzeug innerhalb des Spielerinventars in einen anderen freien Slot legen oder zwei geeignete Werkzeuge vertauschen. Gegenstände werden weder gelöscht noch aus dem Inventar entfernt. Aktive Formulare oder andere Inventaraktionen dürfen dadurch nicht gestört werden.

### Erze versetzen

Der Geist kann einzelne Erzblöcke in der unmittelbaren Umgebung an eine andere plausible Stelle im selben Gestein verschieben. Erzart und Menge bleiben dabei erhalten. Bereits freigelegte Erze eignen sich besonders, weil der Spieler sich an ihre Position erinnern könnte.

### Verirrte Geräusche

Der Geist kann außerhalb des Sichtfelds einzelne, leise Geräusche auslösen, die auch durch normale Spiel- oder Enginevorgänge entstehen könnten. Verwendet werden nach Möglichkeit bereits registrierte Node-Sounds, beispielsweise ein kurzer Schritt, ein Schlag gegen Stein, eine gesetzte Fackel oder eine betätigte Tür. Es gibt keinen unverwechselbaren eigenen Sound.

Geräusche dürfen keine nicht stattfindende Gefahr eindeutig ankündigen und sollen nicht in kurzen Folgen wiederholt werden. Ihre Position liegt seitlich oder hinter dem Spieler und nicht direkt an dessen Position.

## Dramaturgie

- Ereignisse treten selten und mit unregelmäßigen Abständen auf.
- Mehrere Streiche sollen nicht unmittelbar hintereinander stattfinden.
- Der erste Kontext bevorzugt Bergwerke, Dunkelheit, längere Aufenthalte unter Tage und insbesondere Situationen ohne weitere Zeugen.
- Die Veränderungen bleiben klein; ein einzelnes Ereignis soll leicht als Irrtum erklärbar sein.
- Es gibt keine eindeutige Bestätigung, dass ein Naturgeist existiert.
- Wiederholungen desselben Streichs werden vermieden, damit kein leicht erkennbares Muster entsteht.

### Serverlegenden

Die Mod erzeugt Anlässe, aber keine fertigen Gerüchte. Spieler sollen Beobachtungen austauschen, normale Zufälle möglicherweise Naturgeistern zuschreiben und ihre Hypothesen im bestehenden Wiki oder später zusätzlich in Discord festhalten können. Das verborgene Admin-Protokoll dient ausschließlich der technischen Nachvollziehbarkeit und wird nicht automatisch veröffentlicht.

Wiederkehrende Symbole, Vorlieben oder Ereignisketten können später scheinbar unabhängige Vorfälle verbinden. Sie müssen selten bleiben und dürfen niemals so eindeutig sein, dass die Naturgeister zu einem gewöhnlichen, vollständig verstandenen Spielsystem werden.

### Prozedurale Streiche

Langfristig sollen Streiche nicht nur aus einem festen Katalog stammen, sondern aus sicheren Bausteinen zusammengesetzt werden:

1. **Auslöser:** Tiefe, Alleinsein, Tätigkeit, Zufallsimpuls oder frühere Begegnung
2. **Kontext:** Spieler, Ort, vorhandene sichere Ziele und knappe Vorgeschichte
3. **Absicht:** verwirren, necken, selten helfen oder eine rätselhafte Spur hinterlassen
4. **Zielobjekt:** ausschließlich ein zuvor sicher identifizierter Ort oder Gegenstand
5. **Aktion:** versetzen, kurz verändern, ergänzen oder akustisch andeuten
6. **Stil:** aktuelle Vorlieben, Eigenheiten und vermeintliche Regeln des beteiligten Geistes
7. **Sicherheitsprüfung:** Schutzrechte, Schaden, Rücksetzbarkeit und Leistungsbudget
8. **Ausführung und Gedächtnis:** Ereignis anwenden und knapp protokollieren

Gewichtete Zufallsauswahl, variable Parameter, Wiederholungsbremsen und kontextabhängige Ereignisse sollen mit wenigen Grundmechaniken viele Varianten erzeugen. Neue Mechaniken dürfen nur ergänzt werden, wenn sie dieselben Sicherheitsregeln erfüllen wie der bestehende Kern.

### Falsche Muster

Das System arbeitet nicht vollkommen gleichmäßig zufällig. Der Generator darf gelegentlich ein scheinbares Muster andeuten, ohne es anschließend zuverlässig fortzusetzen. Beispielsweise können zwei ähnliche Ereignisse unter vergleichbaren Bedingungen auftreten, worauf eine lange Ruhephase oder ein völlig anderer Streich folgt.

- Ein Muster besteht höchstens aus zwei oder drei zusammengehörig wirkenden Ereignissen.
- Danach folgt zwingend eine längere, zufällige Ruhephase.
- Derselbe Ablauf darf nicht regelmäßig wiederkehren.
- Die Ereignisse dürfen keine verlässliche Spielmechanik oder farmbare Reaktion bilden.
- Ereignisse nach dem Umdrehen oder bei der Rückkehr in einen bekannten Stollen sind erlaubt, dürfen aber nicht jedes Mal auftreten.

### Tiefenfaktor

Die Aktivität des Geistes der Tiefe hängt weich von der Y-Koordinate des Spielers ab:

```text
t = clamp((-y - 500) / 2000, 0, 1)
Tiefenfaktor = t² × (3 - 2t)
```

Die Smoothstep-Kurve ergibt folgende Richtwerte:

| Y-Koordinate | Tiefenfaktor |
|---:|---:|
| −500 und höher | 0 % |
| −1000 | 15,6 % |
| −1500 | 50 % |
| −2000 | 84,4 % |
| −2500 und tiefer | 100 % |

Der Tiefenfaktor bestimmt nicht unmittelbar die Ereigniswahrscheinlichkeit. Er wird mit einer niedrigen maximalen Grundwahrscheinlichkeit und weiteren Faktoren wie Alleinsein, Dunkelheit, Aufenthaltsdauer und Ruhezeit multipliziert. Dadurch bleiben Ereignisse selbst in großer Tiefe selten.

## Sicherheitsregeln

### Atomare Designregel: Technische Sicherheit ist unantastbar

> **Die technische Sicherheit darf unter keinen Umständen, durch keine Persona, keinen Beziehungsscore, keine Gefahrenstufe, keinen Zufallswurf und keinen manuellen Admin-Eingriff abgeschwächt, umgangen oder außer Kraft gesetzt werden.**

Diese Regel ist atomar und steht über allen anderen Designregeln. Ein Ereignis, das die technische Sicherheit nicht vollständig nachweisen kann, wird nicht abgeschwächt ausgeführt, sondern vollständig verworfen. „Böse“, „zornig“, „tödlich“ oder „manuell ausgelöst“ sind niemals Ausnahmen.

Zur unveränderlichen technischen Sicherheit gehören insbesondere:

- keine Datenkorruption, Duplizierung oder unbeabsichtigte Löschung
- keine beschädigten Maschinen, Inventare oder persistenten Weltzustände
- Schutzgebiete und Eigentumsregeln immer respektieren
- keine Wirkung auf ausgeloggte oder noch nicht vollständig geladene Spieler
- keine Manipulation ungeladener Mapblocks und kein erzwungenes Nachladen nur für Ereignisse
- transaktionale oder zuverlässig rücksetzbare Weltänderungen
- erneute Prüfung sämtlicher Vorbedingungen unmittelbar vor der Ausführung
- Abbruch bei unbekanntem, widersprüchlichem oder zwischenzeitlich verändertem Zustand
- feste Arbeits-, Such- und Speicherbudgets gegen Serverlast und Endlosschleifen
- keine Möglichkeit, über Admin-Regie oder externe Schnittstellen beliebigen Lua-Code auszuführen

Technische Sicherheit ist von **spielerischer Gnade** zu unterscheiden. Ein Naturgeist darf abhängig von Persona und Beziehung weniger gnädig, gefährlich oder sogar tödlich werden. Er darf dafür jedoch ausschließlich vorher ausdrücklich freigegebene, technisch sichere Mechaniken verwenden.

- Keine Gegenstände oder Blöcke vernichten.
- Keine wertvollen Ressourcen erzeugen oder duplizieren.
- Keine Änderungen in geschützten Bereichen.
- Keine unausweichlichen Todesfallen oder willkürlichen Soforttode erzeugen.
- Behälterinhalte und fremde Inventare zunächst nicht verändern.
- Alle Streiche müssen einzeln konfigurierbar und vollständig abschaltbar sein.
- Optionales Diagnoseprotokoll für Administratoren, jedoch keine Meldung an betroffene Spieler.
- Maschinen, produktive Anlagen und deren Inventare nicht verändern.
- Keine unerwünschten Teleports, dauerhaft blockierten Zugänge oder erzwungenen Todesfälle.
- Vor jeder tatsächlichen Änderung alle Vorbedingungen erneut prüfen.
- Änderungen mit Rücksetzinformationen ausführen, wenn eine Unterbrechung inkonsistente Zustände erzeugen könnte.
- Ein späterer Testmodus protokolliert Entscheidungen, ohne sie auszuführen.
- Ein administrativer Not-Aus beendet Automatik und verwirft noch nicht ausgeführte Ereignisse.

## Gefahr und Schaden

Naturgeister müssen nicht harmlos sein. Sie dürfen Spieler verletzen, erschrecken, behindern oder in eine riskante Lage bringen, wenn das Ereignis zur Persona und zum Kontext passt. Gefahr soll eine mögliche Konsequenz einer Begegnung sein und nicht bloß ein dekorativer Effekt.

### Grundsätze

- Schaden ist **begrenzt, kontextabhängig und konfigurierbar**.
- Ein automatisches Einzelereignis darf einen zuvor gesunden Spieler nicht unvermeidbar töten.
- Der aktuelle Gesundheitszustand wird unmittelbar vor der Wirkung erneut geprüft.
- Bei niedrigen Lebenspunkten wird ein gefährlicher Effekt abgeschwächt, ersetzt oder verworfen.
- Gefahr benötigt grundsätzlich eine erkennbare Ursache, ein Vorzeichen oder eine realistische Reaktionsmöglichkeit.
- Wiederholter Schaden erhält eine eigene längere Ruhephase und ein serverweites Gefahrenbudget.
- Rüstung, Schutzmechaniken und vorhandene Spielregeln sollen möglichst normal gelten.
- Besitzverlust, zerstörte Maschinen und gelöschte Gegenstände werden nicht als Ersatz für körperlichen Schaden verwendet.
- Manuelle Admin-Ereignisse unterliegen denselben Grenzen, sofern nicht ausdrücklich ein normales, freiwillig begonnenes Kampfereignis inszeniert wird.

### Gefahrenstufen

| Stufe | Wirkung | Beispiel |
|---|---|---|
| 0 – Irritation | kein mechanischer Schaden | Geräusch, Flackern, versetztes Werkzeug |
| 1 – Unbehagen | kurze ungefährliche Behinderung | Dunkelheit, verlangsamtes Arbeiten, kurzer Schreckeffekt |
| 2 – Warnschuss | kleiner direkter Schaden | leichter Stoß, Kratzer, wenige Lebenspunkte Verlust |
| 3 – Bedrohung | merklicher, aber überlebbarer Schaden | begrenzter Steinschlag mit Vorzeichen und Fluchtmöglichkeit |
| 4 – Konfrontation | ernsthafte Gefahr | nur selten, deutlich angekündigt und mit echter Gegenwehr oder Fluchtoption |

Die Automatik beginnt mit den Stufen 0 bis 2. Stufe 3 wird erst nach Spieltests und gesonderter Sicherheitsprüfung freigeschaltet. Stufe 4 bleibt zunächst manueller Regie oder späteren ausdrücklich entworfenen Begegnungen vorbehalten.

### Mögliche gefährliche Handlungen des Geistes der Tiefe

- Ein einzelner kleiner Stein trifft den Spieler nach vorherigem Knacken oder Rieseln.
- Eine Lichtquelle erlischt länger als gewöhnlich, während ein sicherer Rückweg bestehen bleibt.
- Ein kurzer Stoß bewegt den Spieler nur auf sicherem, geprüftem Untergrund.
- Ein Werkzeug „schlägt zurück“ und verursacht geringen Schaden, ohne Haltbarkeit oder Besitz zu verändern.
- Ein angekündigter kleiner Geröllfall versperrt kurz einen unwichtigen Bereich oder verursacht bei Nichtreaktion begrenzten Schaden.

Nicht vorgesehen sind unbemerkte hohe Schadensspitzen, Stöße an Abgründen, Ersticken durch gesetzte Nodes, Lava- oder Wasserfallen sowie Veränderungen, die einen ausgeloggten Spieler beim Wiederkehren töten können.

## Beziehungen zwischen Spielern und Naturgeistern

Jedes Paar aus Spieler und Naturgeist besitzt einen eigenen persistenten Beziehungsscore:

```text
Beziehung[Spieler][Naturgeist] = −100 bis +100
```

| Score | Verhältnis |
|---:|---|
| +75 bis +100 | ausgesprochen wohlgesinnt |
| +30 bis +74 | freundlich |
| −29 bis +29 | neutral oder unberechenbar |
| −30 bis −74 | verärgert |
| −75 bis −100 | Feindschaft |

Ein Spieler kann zu verschiedenen Naturgeistern gleichzeitig völlig unterschiedliche Beziehungen haben. Der Score wird persistent, begrenzt und datensparsam gespeichert.

### Interaktionsstufen

Der Beziehungsscore beeinflusst die Wahrscheinlichkeitsverteilung zwischen fünf Interaktionsstufen:

1. **Hilfreich:** Warnung, Orientierung, Licht oder kleine Gabe
2. **Wohlwollend-schelmisch:** verwirrender, überwiegend ungefährlicher Streich
3. **Unheimlich:** deutliche Verunsicherung oder vorübergehende Behinderung
4. **Schädlich:** direkter Schaden oder eine reale gefährliche Situation
5. **Tödlich:** der Naturgeist versucht tatsächlich, den Spieler zu töten

Vorläufige Ausgangsverteilung für das spätere Balancing:

| Beziehung | Hilfreich | Schelmisch | Unheimlich | Schädlich | Tödlich |
|---:|---:|---:|---:|---:|---:|
| +80 | 60 % | 30 % | 9 % | 1 % | 0 % |
| +30 | 30 % | 45 % | 20 % | 5 % | 0 % |
| 0 | 10 % | 40 % | 35 % | 14 % | 1 % |
| −50 | 2 % | 10 % | 35 % | 45 % | 8 % |
| −90 | 0 % | 2 % | 13 % | 50 % | 35 % |

Diese Werte sind Startpunkte, keine endgültige Balance. Personaeigenschaften wie Güte, Bosheit, Gefährlichkeit, Zorn, Gnade und Nachtragendsein verschieben die Verteilung zusätzlich. Ein freundlicher Naturgeist reagiert auf denselben negativen Score anders als ein grundsätzlich grausamer Geist.

### Veränderung der Beziehung

Mögliche Einflüsse sind:

- passende Opfergaben oder Rituale
- Respektieren oder Ignorieren einer Warnung
- Schutz oder Beschädigung eines besonderen Ortes
- Annahme, Ablehnung oder Missbrauch einer Gabe
- Verhalten innerhalb der Domäne des Naturgeistes
- Reaktion auf frühere Streiche und Begegnungen
- Angriff auf eine sichtbare Manifestation
- ausdrückliche Entscheidung bei einem manuellen Admin-Auftritt

Wiederholbare Handlungen erhalten abnehmende Wirkung und eigene Sperrzeiten. Beziehungen dürfen nicht durch monotone Wiederholung einfach gefarmt werden. Änderungen werden mit knappem Grund protokolliert, damit Admins Fehler und unerwartete Eskalationen nachvollziehen können.

### Eskalation

Tödliche Feindschaft soll normalerweise als Entwicklung erkennbar werden:

```text
Streich → Warnzeichen → kleiner Schaden → deutliche Warnung
        → gefährliche Begegnung → mögliche tödliche Eskalation
```

Ein tödliches Ereignis bedeutet, dass der Geist den Tod des Spielers in Kauf nimmt oder beabsichtigt. Es garantiert den Tod nicht: Vorbereitung, Ausrüstung, Flucht und kluges Verhalten dürfen weiterhin helfen. Eine Persona kann heimtückisch sein, doch der Verlauf soll im Rückblick als Beziehungsgeschichte verständlich werden.

## Persönliche Cooldowns

Cooldowns werden persistent pro Spieler geführt und überstehen Abmelden sowie Serverneustarts.

- **Allgemeiner Spieler-Cooldown:** Nach einem Geist-Ereignis bleibt der Spieler für alle automatischen Naturgeist-Ereignisse gesperrt.
- **Persona-Spieler-Cooldown:** Derselbe Naturgeist erhält gegenüber diesem Spieler eine zusätzliche, längere Sperre.
- **Gefahren-Cooldown:** Schädliche oder tödliche Ereignisse erzwingen eine besonders lange Ruhephase.
- **Beziehungsaktions-Cooldown:** Wiederholbare Opfergaben, Provokationen und Rituale können den Score nicht in kurzer Folge verändern.

Vorläufige Planungswerte:

| Cooldown | Bereich |
|---|---:|
| Allgemeiner Spieler-Cooldown | 60–180 Minuten |
| Persona-Spieler-Cooldown | 2–6 Stunden |
| Nach schädlichem Ereignis | mindestens mehrere Stunden |
| Nach tödlichem Ereignis oder Tötungsversuch | sehr lange, separat festzulegende Ruhephase |

Falsche Muster und Ereignisketten dürfen diese Mindestabstände nicht umgehen. Ein Folgeereignis wird verschoben oder verworfen, wenn irgendein persönlicher Cooldown noch aktiv ist.

## Persönlichkeit und Gedächtnis

### Persönlichkeitsparameter

Eine spätere Version kann die Auswahl jedes Naturgeistes durch verborgene Parameter steuern:

- **Schabernack:** Häufigkeit und Intensität verwirrender Ereignisse
- **Hilfsbereitschaft:** Chance auf seltene nützliche oder warnende Handlungen
- **Geheimniskrämerei:** Stärke der Spuren und Erkennbarkeit von Zusammenhängen
- **Neugier:** Reaktion auf neue Orte, Tätigkeiten und Spieler
- **Nachtragendsein:** Wahrscheinlichkeit, frühere Begegnungen erneut aufzugreifen
- **Zorn:** Bereitschaft, von Irritation zu Warnung oder begrenzter Gefahr zu wechseln
- **Gnade:** Wahrscheinlichkeit, einen gefährlichen Effekt wegen niedriger Gesundheit oder früherer Konsequenzen abzubrechen
- **Bosheit:** Verschiebung der Interaktionsverteilung in Richtung Schaden und tödlicher Absicht
- **Gefährlichkeit:** Stärke und Auswahl der technisch freigegebenen gefährlichen Mechaniken

Die Werte dürfen nicht als sichtbare Charakterwerte erscheinen. Sie sollen Tendenzen erzeugen, keine festen Regeln.

### Begrenztes Gedächtnis

Jeder Naturgeist darf sich ausgewählte Informationen merken:

- Zeitpunkt und Art vergangener Begegnungen pro Spieler
- zuletzt verwendete Ziele und Streichfamilien
- wenige aktuelle Vorlieben oder Abneigungen
- offene Ereignisketten und mögliche Fortsetzungen
- tatsächliche und nur vorgetäuschte Muster
- Beziehungsscore und letzte begründete Änderungen pro Spieler und Persona
- allgemeine, Persona- und Gefahren-Cooldowns

Es findet keine vollständige Daueraufzeichnung aller Spieleraktionen statt. Das Gedächtnis erhält feste Größen- und Altersgrenzen; alte Einträge werden gelöscht oder zu knappen Tendenzen zusammengefasst. Persistente Schreibvorgänge erfolgen gebündelt und selten.

## Automatik und manuelle Regie

Automatik und Admin-Auftritt sollen als zwei Quellen derselben Identität funktionieren.

### Automatischer Kern

- seltene, reversible und je nach Persona harmlose bis begrenzt gefährliche Ereignisse
- prozedurale Auswahl aus sicheren Mechaniken
- kleines persistentes Gedächtnis
- kein regelmäßiger persönlicher Eingriff erforderlich

### Manueller Auftritt

Ein Admin kann später einen Naturgeist persönlich darstellen, improvisieren, sprechen, Rätsel stellen oder sichere Ereignisse gezielt freigeben. Die automatische Aktivität muss dabei pausiert oder eingeschränkt werden können. Manuelle Ereignisse nutzen dieselben Sicherheitsprüfungen und möglichst dasselbe Gedächtnis wie die Automatik.

Besonders größere Brüche etablierter Gewohnheiten sollen manuell ausgelöst werden:

| Eingriff | Wirkung |
|---|---|
| Regelbruch | Eine bekannte Gewohnheit einmalig verletzen |
| Umkehrung | Eine Vorliebe zeitweise ins Gegenteil verkehren |
| Täuschung | Spuren erzeugen, die eine falsche Theorie stützen |
| Neue Scheinregel | Eine Ausnahme wie den Beginn eines neuen Musters wirken lassen |
| Rückkehr | Nach einer Phase wieder zum bisherigen Verhalten zurückkehren |

Der automatische Kern darf kleine falsche Muster erzeugen. Gezielte Reaktionen auf von Spielern diskutierte Theorien bleiben jedoch Admin-Regie; die Mod soll dafür keinen Chat-Inhalt automatisch auswerten.

## Offene Fragen

- Wie können Spieler auf seine Streiche reagieren?
- Soll es Hinweise, Schutzmaßnahmen oder zwergische Rituale geben?
- Dürfen seltene manuell inszenierte Auftritte außerhalb von Bergwerken stattfinden, obwohl die Automatik unter Tage bleibt?
- Wie selten dürfen hilfreiche oder warnende Ereignisse sein, ohne den Charakter des jeweiligen Naturgeistes zu verwässern?
- Welche Lichtquellen und Erze dürfen bewegt werden?
- Welche Spiele und Mods sollen unterstützt werden?
- Welche wiederkehrenden Symbole wären erkennbar, aber nicht zu eindeutig?
- Soll die langfristige Häufigkeitsgrenze pro Spieler oder zusätzlich serverweit gelten?

## Umgesetzter Kern

- Registrierungs-Hooks für Persona-Beschreibungen und planbildende Interaktionen
- strikte Trennung zwischen Persona-Plänen und kernseitig registrierten Wirkungen
- persistente Beziehungen, allgemeine Cooldowns, Persona-Cooldowns, Gefahren-Cooldowns und begrenztes Gedächtnis
- persistente Transaktionsjournale mit Wiederanlauf nach Serverneustart
- persistenter Wirkungstresor mit identischer, gleichwertiger oder umgewandelter Erfüllung
- `fakelib`-Adapter für akteursgebundene Protection-, Eigentums- und Callback-Prüfungen
- exakte Fähigkeitsprofile für Node-Inventare sowie Sperren für angrenzende Automation
- sichere Grundwirkungen für profilierte Geräusche, profilierte Node-Verlagerung und Slots im Spieler-Hauptinventar
- Planwarteschlange mit festem Arbeitsbudget und höchstens einem ausgeführten Plan pro Intervall
- Betriebsarten `active`, `directing` und `paused` mit administrativem Not-Aus
- wahrheitsgemäßes Diagnose- und Transaktionsprotokoll mit eindeutiger Herkunft
- Testmodus, der Pläne vollständig vorbereitet und prüft, aber keine Wirkung oder Cooldowns ausführt
- API v1 beschränkt einen Plan auf genau eine Wirkung, bis ein planweiter Transaktions- und Rollbackmechanismus existiert
- lastarmer Persona-Direktor mit höchstens einer fälligen Spielerprüfung pro Sekunde
- erste Persona `underground_01` mit Tiefen-, Aufenthalts- und Alleinseinsfaktor
- erster harmloser Streich: leises gewöhnliches Spielgeräusch hinter oder seitlich vom Spieler
- nach erfolgreichem Ereignis 60–180 Minuten allgemeiner und 2–6 Stunden Persona-Cooldown

Noch nicht umgesetzt sind weitere Streiche, Beziehungsänderungen aus Spielhandlungen, eine beziehungsabhängige Interaktionsstufenauswahl, Behälterentnahmen als ausführbare Wirkung und materielle Bau- oder Umwandlungsrezepte.

## Ausbauplanung

### Nächster Ausbau

- Testmodus ohne tatsächliche Änderungen
- Administrativer Not-Aus und klarer Zustand `aktiv`, `Regiebetrieb` oder `pausiert`
- Begrenztes persistentes Gedächtnis für Begegnungen und Vorlieben
- Verborgene Persönlichkeitsparameter
- Sichere manuelle Befehle zum Auslösen, Verschieben oder Verwerfen eines geplanten Ereignisses
- Seltene harmlose Spuren wie wertlose Gegenstände, kleine Dekorationen oder rätselhafte Symbole; erst nach genauer Missbrauchs- und Rücksetzprüfung
- Mehrteilige, optionale Ereignisketten ohne Pflichtquest und ohne garantierte Auflösung
- Technische Trennung zwischen gemeinsamem Trickster-Kern und Persona-Modulen
- Allgemeines Gefahrenbudget mit Gesundheits-, Fluchtweg- und Wiederholungsprüfung
- Erster ungefährlicher oder leicht schädlicher Effekt des Geistes der Tiefe auf Gefahrenstufe 1 oder 2
- Persona-Registrierung für weitere Naturgeister, zunächst ohne zweite konkrete Figur festzulegen
- Persistenter Beziehungsscore pro Spieler und Persona
- Persistente allgemeine und Persona-spezifische Spieler-Cooldowns
- Auswahl der Interaktionsstufe aus Beziehung, Persona und aktuellem Zustand

Mögliche spätere Admin-Kommandos sind konzeptionell `appear`, `prank`, `gift`, `possess` und `vanish`. Namen, Rechte und genaue Wirkung werden erst bei der Implementierung festgelegt; es wird keine Schnittstelle zum Ausführen beliebigen Lua-Codes geben.

### Optionale Version 2.5: Web-Regiepult

Das Regiepult ist eine optionale, separat abgesicherte Webanwendung. Die Mod bleibt ohne sie vollständig funktionsfähig. Denkbare Bereiche:

- Online-Spieler, letzter Streich und aktueller Automatikzustand
- Umschalten zwischen Automatik, Regiebetrieb und Pause
- Einsehen begrenzter Vorlieben, Beziehungen und Gewohnheiten
- sichere Ereignisvorschläge erzeugen, prüfen, freigeben oder verwerfen
- gezielte Ausnahme, Umkehrung oder falsche Spur vorbereiten
- Ereignisarchiv sowie Not-Aus, Abbruch und Rücksetzung
- persönliche Regieaktionen für einen vom Admin dargestellten Naturgeist

Eine mögliche Architektur besteht aus Browser, authentifiziertem Webdienst und einer engen Befehlswarteschlange zur Luanti-Mod. Die Verbindung wird erst später festgelegt. Anforderungen sind HTTPS, Anmeldung, minimale Berechtigungen, keine öffentliche ungeschützte Admin-API und keine Übertragung oder Ausführung freien Lua-Codes. Abfragen erfolgen selten und werden anhand echter Servermessungen abgestimmt.

Besondere Regiefunktionen:

1. **Jetzt nicht:** geplantes Ereignis verhindern oder verschieben
2. **Gezielte Ausnahme:** eine bekannte Gewohnheit einmalig außer Kraft setzen
3. **Fernsteuerung:** ein geprüftes Ereignis in einem ausgewählten Kontext freigeben

## Technische Notizen

- Kanonischer Modname: `trickster`
- Anzeigename: `Trickster`
- Zielplattform: Luanti / Minetest
- Langfristige Architektur: gemeinsamer Trickster-Kern mit registrierten Persona-Modulen

Die konkrete Serverinstallation darf einmalig einen manuellen Tarnnamen erhalten. Der Quellcode verwendet dafür `minetest.get_current_modname()` und keine fest codierten Node-, Einstellungs- oder Logpräfixe. Entwicklungsverzeichnis und Dokumentation behalten den Namen `trickster`. Die vollständige Vorgehensweise und ihre Migrationsgrenzen stehen in `README.md`.

### Lastarme Architektur

- Eine einzige zentrale Zeitsteuerung verwaltet alle Spielerzustände.
- Der Globalstep erhöht normalerweise nur einen Zeitakkumulator; die eigentliche Prüfung erfolgt ungefähr alle 30 Sekunden.
- Oberhalb von Y = −500, während einer Ruhephase oder bei mehreren Zeugen endet die Prüfung sofort.
- Wahrscheinlichkeitsfaktoren werden ausschließlich aus bereits verfügbaren Spielerpositionen und kleinen Zustandswerten berechnet.
- Es gibt keine unsichtbaren Entities, keine ABMs und keine dauernden Node-Suchen.
- Welt-Suchen beginnen erst, nachdem die seltene Ereignisentscheidung bereits positiv ausgefallen ist.
- Pro Arbeitsschritt wird höchstens ein aufwendiger Streichkandidat serverweit untersucht. Weitere Kandidaten warten in einer kleinen Queue.
- Jeder Streich besitzt ein Such- und Änderungsbudget. Wird darin kein sicheres Ziel gefunden, verfällt das Ereignis.
- Der überwiegende Zustand ist `schlafend`; mögliche spätere Zustände sind `schlafend`, `planend` und `aktiv`.
- Als vorsichtiger langfristiger Zielwert gilt höchstens ungefähr ein automatischer Streich serverweit alle 15 bis 30 Minuten. Der tatsächliche Wert wird anhand von Spielgefühl und Profiling bestimmt.
- Geplante Arbeit wird bei Bedarf über mehrere Serverticks verteilt und sofort abgebrochen, wenn Bedingungen nicht mehr passen.
- Performance wird auf dem echten Server gemessen; theoretische Abschätzungen ersetzen kein Profiling.

### Spielerzustand

Pro verbundenem Spieler werden nur kleine Zustandswerte gehalten:

- Zeitpunkt der nächsten Wahrscheinlichkeitsprüfung
- Beginn des aktuellen Aufenthalts unter Tage
- Ende der persönlichen Ruhephase
- letzter ausgeführter Streich
- Zustand einer möglichen falschen Serie
- wenige kürzlich verwendete Ziele, damit sie nicht sofort erneut gewählt werden

Diese Daten werden im Arbeitsspeicher gehalten und nur beim Verlassen, Herunterfahren oder in großen Abständen gespeichert. Es erfolgen keine dauernden Schreibzugriffe auf den Mod-Speicher.

### Kandidatensuche

- Inventarstreiche benötigen keine Weltsuche.
- Geräusche benötigen keine Weltsuche; geeignete registrierte Node-Sounds werden einmalig beim Laden der Mods gesammelt.
- Für Lichtquellen und Erze wird `find_nodes_in_area` nur nach einem bereits ausgelösten Ereignis und nur mit einer kleinen, expliziten Node-Liste verwendet.
- Die Suchbereiche bleiben klein und vollständig in bereits geladenen Mapblocks.
- Sichtfeld-, Schutz- und Plausibilitätsprüfungen erfolgen nur für wenige gefundene Kandidaten.

### Lichtflackern und Wiederherstellung

Unterstützte Lichtquellen erhalten jeweils eine kurzzeitig dunklere Ersatz-Node mit identischer Darstellung und Ausrichtung. Vor dem Austausch wird die Wiederherstellung vorgemerkt. Nach kurzer Zeit wird die Original-Node zurückgesetzt.

Eine LBM stellt verbliebene Flacker-Nodes beim Laden ihres Mapblocks automatisch wieder her. Dadurch bleiben nach Serverabsturz oder Neustart keine dunklen Ersatz-Nodes in der Welt. Es werden nur ausdrücklich freigegebene einfache Lichtquellen unterstützt; Maschinen und schaltbare Lampen bleiben unberührt.

### Falsche Muster ohne zusätzliche Timer

Falsche Serien werden als kleine Zustandsmaschine in der normalen 30-Sekunden-Prüfung verwaltet. Es werden keine separaten dauernden Timer pro Spieler angelegt. Nach einem Ereignis kann selten ein zweites, ähnlich wirkendes Ereignis für ein späteres Zeitfenster vorgemerkt werden. Danach erzwingt der Zustand eine längere Ruhephase.

## Entscheidungen

- Der Geist der Tiefe ist keine gewöhnliche sichtbare oder bekämpfbare Kreatur.
- Der Schwerpunkt liegt auf subtiler Wahrnehmungsirritation.
- Die Streiche betreffen zunächst Lichtquellen, Inventarslots, Erze und verirrte Spielgeräusche.
- Eingriffe in Loren und Schienensysteme sind ausdrücklich nicht vorgesehen, weil sie nicht zuverlässig gegen Unfälle und Schäden abgesichert werden können.
- Streiche verändern Besitz oder Ressourcen höchstens räumlich; sie vernichten nichts.
- Kein Naturgeist erhält zwingend einen eindeutig identifizierbaren eigenen Sound.
- Der Ereignisgenerator darf falsche Muster andeuten und anschließend bewusst brechen.
- Trickster ist das übergeordnete System für mehrere namenlose Naturgeister; der zuerst implementierte Kontext gehört zur Tiefe und zu Bergwerken.
- Naturgeister dürfen begrenzten Schaden verursachen und gefährlich werden; vollständige Harmlosigkeit ist kein Designziel.
- Automatische und manuell inszenierte Ereignisse einer Persona repräsentieren dieselbe Figur und unterliegen demselben Gefahren- und Sicherheitsmodell.
- Spielerkommunikation, Wiki und mögliche Discord-Diskussionen tragen die Legendenbildung; die Mod erzeugt keine automatischen Gerüchte.
- Größere gezielte Regelbrüche und Reaktionen auf Spielertheorien bleiben einer späteren Admin-Regie vorbehalten.
- Ein Web-Regiepult ist eine optionale langfristige Erweiterung und keine Voraussetzung für den Modbetrieb.
- Technische Sicherheit ist eine atomare, absolut unantastbare Designregel und kann durch keine andere Regel überschrieben werden.
- Jeder Spieler besitzt zu jedem Naturgeist einen eigenen persistenten Beziehungsscore von −100 bis +100.
- Beziehung und Persona bestimmen gemeinsam die Verteilung von hilfreichen bis tödlichen Interaktionsstufen.
- Ein Naturgeist kann bei extremer Feindschaft tödlich handeln; Bosheit reduziert spielerische Gnade, niemals technische Sicherheitsprüfungen.
- Allgemeine, Persona-spezifische und gefährlichkeitsabhängige Cooldowns werden persistent pro Spieler geführt.
- Jede Persona liegt mit ihren Definitionen und Streichen in einem eigenen Erweiterungsverzeichnis und registriert sich über eine festgelegte Framework-Schnittstelle.
- Sämtliche Welt-, Spieler- und Wahrnehmungswirkungen werden ausschließlich durch geprüfte Fähigkeiten des Frameworks ausgeführt; Persona- und Streichcode beschreibt und beantragt Wirkungen nur.
- `fakelib` wird als Akteurs- und Kompatibilitätsadapter verwendet, ersetzt jedoch keine Prüfung oder Freigabe durch das Framework.
- Node-Inventare werden ausschließlich über exakte Fähigkeitsprofile freigegeben; Shops, Maschinen, Produktions- und automatisierte Inventare bleiben zunächst ausgeschlossen.
- Entnommener Besitz verbleibt im Wirkungstresor, bis ein vorab definierter Erfüllungsvertrag vollständig erfüllt oder eine materielle Rückgabe gesichert ist.
- Gewöhnliche Spielprotokolle dürfen eine Handlung dem nachgebildeten Spieler zuschreiben; das geschützte Diagnose- und Transaktionsprotokoll hält die tatsächliche Trickster-Urheberschaft immer vollständig fest.
