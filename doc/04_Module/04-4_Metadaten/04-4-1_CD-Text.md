# Kapitel 4.4.1: CD-TEXT-Provider

Automatische Metadaten-Extraktion direkt von der Audio-CD ohne externe API.

## Inhaltsverzeichnis

1. [Übersicht](#übersicht)
2. [CD-TEXT Standard](#cd-text-standard)
3. [Extraktion-Methoden](#extraktion-methoden)
4. [Verfügbarkeit](#verfügbarkeit)
5. [Provider-Priorität](#provider-priorität)
6. [Troubleshooting](#troubleshooting)

---

## Übersicht

### Was ist CD-TEXT?

**CD-TEXT** ist ein Metadaten-Standard für Audio-CDs nach **Red Book** (IEC 60908):

- **Eingebettet**: Daten werden in den Lead-In-Bereich der CD geschrieben
- **Offline**: Keine Internet-Verbindung erforderlich
- **Sofort verfügbar**: Lesen dauert < 1 Sekunde
- **Optional**: Nur ~10-20% aller Audio-CDs enthalten CD-TEXT

**Standard seit**: 1996 (CD-TEXT Specification Extension)

### Warum CD-TEXT?

#### ✅ Vorteile

**Offline-Fähigkeit**:
- Funktioniert ohne Internet
- Keine API-Abfragen erforderlich
- Perfekt für Offline-Archivierung

**Geschwindigkeit**:
- Sofortiges Auslesen (< 1s)
- Keine Wartezeit auf API-Response
- Keine Rate-Limits

**Genauigkeit**:
- Offizielle Daten vom Label
- Keine Verwechslungen mit anderen Releases
- Exakt die Version, die auf der CD ist

#### ❌ Nachteile

**Geringe Verbreitung**:
- Nur 10-20% aller CDs enthalten CD-TEXT
- Meist nur auf neueren CDs (ab 2000)
- Klassik/Jazz häufiger als Pop/Rock

**Fehlende Cover**:
- CD-TEXT enthält keine Bilder
- Nur Text-Metadaten verfügbar

**Begrenzte Daten**:
- Nur grundlegende Informationen
- Keine Genre-Tags, Ratings etc.

### CD-TEXT vs. MusicBrainz

| Feature | CD-TEXT | MusicBrainz |
|---------|---------|-------------|
| **Verfügbarkeit** | 10-20% der CDs | ~95% via Disc-ID |
| **Internet** | ❌ Nicht erforderlich | ✅ Erforderlich |
| **Geschwindigkeit** | < 1 Sekunde | 2-5 Sekunden |
| **Cover Art** | ❌ Nicht verfügbar | ✅ Cover Art Archive |
| **Genauigkeit** | ⭐⭐⭐⭐⭐ (vom Label) | ⭐⭐⭐⭐⭐ (Community) |
| **Zusatzdaten** | Minimal | Umfassend |

**Empfehlung**: CD-TEXT als **erste Wahl** (Fallback zu MusicBrainz wenn nicht verfügbar)

---

## CD-TEXT Standard

### Red Book Spezifikation

**CD-TEXT Block** im Lead-In:
- **Position**: Subcode-Kanal R-W (vor Audio-Daten)
- **Größe**: ~5 KB pro CD
- **Encoding**: ASCII oder ISO-8859-1 (Latin-1)

### Unterstützte Felder

#### Album-Level (Disc)

| Feld | Beschreibung | Beispiel |
|------|--------------|----------|
| **TITLE** | Album-Titel | "Dark Side of the Moon" |
| **PERFORMER** | Haupt-Artist | "Pink Floyd" |
| **SONGWRITER** | Komponist (optional) | "Roger Waters" |
| **COMPOSER** | Komponist (optional) | "Richard Wright" |
| **ARRANGER** | Arrangeur (optional) | "Bob Ezrin" |
| **MESSAGE** | Notizen (optional) | "Remastered 2011" |

#### Track-Level (pro Track)

Jeder Track kann haben:
- **TITLE**: Track-Titel
- **PERFORMER**: Track-Artist (falls abweichend)
- **SONGWRITER**: Track-Komponist
- **COMPOSER**: Track-Komponist
- **ARRANGER**: Track-Arrangeur

**Beispiel**:
```
Disc:
  TITLE: "Greatest Hits"
  PERFORMER: "Various Artists"

Track 1:
  TITLE: "Bohemian Rhapsody"
  PERFORMER: "Queen"

Track 2:
  TITLE: "Hotel California"
  PERFORMER: "Eagles"
```

### Zeichensatz

**Standard**: ISO-8859-1 (Latin-1)
- Unterstützt: À, É, Ñ, Ü, ß
- **Nicht** unterstützt: Chinesisch, Japanisch, Kyrillisch

**Moderne CDs**: Manchmal UTF-8 (nicht standardkonform)

---

## Extraktion-Methoden

### Unterstützte Tools

disk2iso unterstützt **3 Fallback-Methoden** zur CD-TEXT-Extraktion:

#### 1. cd-info (libcdio-utils) - **Empfohlen**

**Installation**:
```bash
sudo apt install libcdio-utils
```

**Vorteile**:
- ✅ Beste Track-Detail-Erkennung
- ✅ Vollständige Feld-Unterstützung (TITLE, PERFORMER, COMPOSER, etc.)
- ✅ Sauberes Parsing von Track-Sektionen

**Beispiel-Ausgabe**:
```
CD-TEXT for Track 1:
  TITLE: Bohemian Rhapsody
  PERFORMER: Queen
  SONGWRITER: Freddie Mercury
  
CD-TEXT for Track 2:
  TITLE: Another One Bites the Dust
  PERFORMER: Queen
```

**Verwendung durch disk2iso**:
```bash
cd-info --no-header --no-device-info --cdtext-only /dev/sr0
```

#### 2. icedax (cdrkit) - **Alternative**

**Installation**:
```bash
sudo apt install icedax
```

**Vorteile**:
- ✅ Zuverlässige Album-Daten
- ✅ Track-Arrays (Tracktitle[1], Trackperformer[1], ...)

**Beispiel-Ausgabe**:
```
Albumtitle: Dark Side of the Moon
Performer: Pink Floyd
Tracktitle[1]: Speak to Me
Tracktitle[2]: Breathe
Trackperformer[1]: Pink Floyd
```

**Verwendung durch disk2iso**:
```bash
icedax -J -H -D /dev/sr0 -v all 2>&1
```

#### 3. cdda2wav (cdrtools) - **Legacy**

**Installation**:
```bash
sudo apt install cdda2wav
```

**Hinweis**: Ähnlich wie icedax, aber aus Original cdrtools-Paket

**Verwendung durch disk2iso**:
```bash
cdda2wav -J -H -D /dev/sr0 -v all 2>&1
```

### Automatische Tool-Auswahl

disk2iso versucht die Tools in dieser Reihenfolge:

```
1. cd-info vorhanden? → Verwende cd-info
2. icedax vorhanden? → Verwende icedax
3. cdda2wav vorhanden? → Verwende cdda2wav
4. Nichts verfügbar → Kein CD-TEXT (Fallback zu MusicBrainz)
```

---

## Verfügbarkeit

### CD-TEXT in der Praxis

**Häufigkeit nach Genre**:

| Genre | CD-TEXT-Anteil | Hinweis |
|-------|----------------|---------|
| **Klassik** | ~40% | Oft vollständige Track-Titel |
| **Jazz** | ~30% | Viele Reissues mit CD-TEXT |
| **Pop/Rock** | ~10% | Meist nur neue Releases |
| **Metal** | ~5% | Sehr selten |
| **Indie** | ~15% | Unabhängige Labels nutzen häufiger |

**Häufigkeit nach Erscheinungsjahr**:

| Zeitraum | CD-TEXT-Anteil |
|----------|----------------|
| **1983-1995** | < 1% (vor Standard) |
| **1996-2000** | ~5% (Standard neu) |
| **2001-2010** | ~15% (zunehmend) |
| **2011-heute** | ~25% (Streaming-Rückgang) |

### Prüfung auf CD-TEXT

**Mit cd-info**:
```bash
cd-info --cdtext-only /dev/sr0
```

**Ausgabe wenn vorhanden**:
```
CD-TEXT for Disc:
  TITLE: The Dark Side of the Moon
  PERFORMER: Pink Floyd
```

**Ausgabe wenn nicht vorhanden**:
```
(Keine Ausgabe oder "No CD-TEXT")
```

---

## Provider-Priorität

### Metadata-Framework Integration

CD-TEXT ist als **Provider** im Metadata-Framework registriert:

```bash
# Provider-Informationen
Provider-Name: cdtext
Provider-Typ: metadata
Unterstützte Medien: audio-cd
Priorität: 50 (Mittel)
```

### Prioritäts-Reihenfolge

Das Metadata-Framework ruft Provider in dieser Reihenfolge auf:

```
1. MusicBrainz (Priorität: 100) - Höchste Priorität
   └─► Disc-ID → 95% Erfolgsrate
   
2. CD-TEXT (Priorität: 50) - Mittlere Priorität
   └─► Eingebettete Daten → 10-20% Verfügbarkeit
   
3. Manuelle Eingabe (Priorität: 0) - Fallback
   └─► User-Input wenn alle Provider fehlschlagen
```

**Warum MusicBrainz vor CD-TEXT?**
- **Cover Art**: MusicBrainz liefert Cover, CD-TEXT nicht
- **Zusatzdaten**: Genre, Release-Datum, MBIDs
- **Verfügbarkeit**: 95% vs. 20%

**Wann wird CD-TEXT verwendet?**
- MusicBrainz-API nicht erreichbar (Offline-Modus)
- Keine Disc-ID berechenbar (defekte CD)
- User bevorzugt CD-TEXT (Konfiguration)

### Konfiguration

**In `conf/libcdtext.ini`**:
```ini
[provider]
type = metadata
priority = 50
supported_media = audio-cd
```

**Priorität ändern** (höher = bevorzugt):
```bash
# CD-TEXT bevorzugen (vor MusicBrainz)
priority = 150
```

---

## Troubleshooting

### Kein CD-TEXT gefunden

**Symptom**:
```
CD-TEXT: Keine Metadaten gefunden
```

**Ursachen**:

1. **CD enthält kein CD-TEXT** (90% der Fälle)
   - **Lösung**: Automatischer Fallback zu MusicBrainz

2. **Tool nicht installiert**
   ```bash
   # Prüfen
   which cd-info icedax cdda2wav
   
   # Installieren
   sudo apt install libcdio-utils icedax
   ```

3. **CD-Laufwerk unterstützt kein CD-TEXT**
   - **Selten**: Die meisten modernen Laufwerke unterstützen es
   - **Test**: Andere CD mit bekanntem CD-TEXT testen

4. **Beschädigte CD**
   - Lead-In-Bereich unleserlich
   - **Lösung**: MusicBrainz verwenden

### Falsche Zeichen (Umlaute)

**Symptom**:
```
Artist: "Mtley Cre"  (statt "Mötley Crüe")
```

**Ursache**: Encoding-Problem (ISO-8859-1 vs. UTF-8)

**Lösung**: Tools unterstützen meist nur Latin-1

```bash
# Keine echte Lösung - MusicBrainz nutzen
# MusicBrainz hat korrekte Unicode-Daten
```

### Unvollständige Track-Titel

**Symptom**:
```
Album: "Greatest Hits"
Artist: "Queen"
Track 1: (leer)
Track 2: (leer)
```

**Ursache**: CD enthält nur Album-Level CD-TEXT, keine Track-Daten

**Häufigkeit**: ~50% der CDs mit CD-TEXT haben keine Track-Titel

**Lösung**: 
```bash
# disk2iso kombiniert automatisch:
# - Album/Artist von CD-TEXT
# - Track-Titel von MusicBrainz
```

### Tool-Ausgabe nicht erkannt

**Symptom**:
```
[DEBUG] cd-info output: (...)
[ERROR] CD-TEXT: Parse fehlgeschlagen
```

**Ursache**: Unerwartetes Ausgabeformat (neue Tool-Version)

**Debug**:
```bash
# Manuelle Tool-Ausgabe prüfen
cd-info --cdtext-only /dev/sr0 > /tmp/cdtext.log
cat /tmp/cdtext.log
```

**Melden**: GitHub Issue mit `/tmp/cdtext.log` anhängen

---

## Best Practices

### Optimale Konfiguration

**Für maximale Offline-Fähigkeit**:
```ini
# conf/libcdtext.ini
[provider]
priority = 150  # Vor MusicBrainz
```

**Für beste Datenqualität**:
```ini
# Standard-Einstellung beibehalten
priority = 50  # Nach MusicBrainz
```

### Tool-Installation

**Empfohlen** (alle 3 Tools installieren für maximale Kompatibilität):
```bash
sudo apt install libcdio-utils icedax cdda2wav
```

**Minimal** (nur cd-info):
```bash
sudo apt install libcdio-utils
```

### Offline-Archivierung

**Workflow für Offline-Nutzung**:

1. **CD-TEXT bevorzugen**:
   ```bash
   # libcdtext.ini: priority = 150
   ```

2. **Bei Fehlschlag**: Manuelle Eingabe statt MusicBrainz

3. **Internet-Verbindung**: Später Cover von MusicBrainz nachladen

---

## Zusammenfassung

### CD-TEXT im Überblick

| ✅ Vorteile | ❌ Nachteile |
|------------|-------------|
| Offline-fähig | Nur 10-20% Verfügbarkeit |
| < 1 Sekunde | Keine Cover Art |
| 100% genau (vom Label) | Begrenzte Metadaten |
| Keine API-Keys | Encoding-Probleme möglich |
| Keine Rate-Limits | Oft nur Album, keine Tracks |

### Wann CD-TEXT verwenden?

**Perfekt für**:
- Offline-Archivierung
- Schnelle Batch-Verarbeitung
- Wenn CD nachweislich CD-TEXT enthält

**Nicht optimal für**:
- Maximale Metadaten-Vollständigkeit
- Cover Art erforderlich
- Alte CDs (vor 2000)

### Integration in disk2iso

CD-TEXT ist **automatisch** integriert:
- Keine Konfiguration erforderlich
- Automatischer Fallback zu MusicBrainz
- Kombiniert Album-Daten (CD-TEXT) + Track-Titel (MusicBrainz) wenn sinnvoll

**Module**: `libcdtext.sh` (Provider), `libmetadata.sh` (Framework)

---

## Weiterführende Links

- **Red Book Standard**: IEC 60908 (nicht frei verfügbar)
- **CD-TEXT Specification**: https://www.scs.stanford.edu/~zyedidia/docs/cdtext.pdf
- **libcdio Dokumentation**: https://www.gnu.org/software/libcdio/
- **cdrtools**: https://sourceforge.net/projects/cdrtools/

**Nächstes Kapitel**: [4.4.11 MusicBrainz-Provider](04-4-11_MusicBrainz.md)
