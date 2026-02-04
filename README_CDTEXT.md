# disk2iso-metadata - CD-TEXT Provider

Metadaten-Provider für eingebettete CD-TEXT-Informationen auf Audio-CDs.

## 📋 Übersicht

CD-TEXT ist ein optionaler Metadaten-Standard für Audio-CDs (Red Book Standard), der Album- und Track-Informationen direkt auf der CD speichert - ohne externe Datenbank-Abfrage.

**Verfügbarkeit**: ~10-20% aller Audio-CDs  
**Geschwindigkeit**: < 1 Sekunde  
**Internet**: ❌ Nicht erforderlich

## 🎯 Features

- ✅ **Offline-Extraktion** - Kein Internet erforderlich
- ✅ **Sofortige Verfügbarkeit** - Auslesen in unter 1 Sekunde
- ✅ **100% Genauigkeit** - Offizielle Daten vom Label
- ✅ **3 Fallback-Methoden** - cd-info, icedax, cdda2wav
- ✅ **Provider-Framework** - Automatische Integration in libmetadata

## 📦 Installation

### System-Dependencies

```bash
# Empfohlen: Alle 3 Tools für maximale Kompatibilität
sudo apt install libcdio-utils icedax cdda2wav

# Minimal: Nur cd-info (beste Methode)
sudo apt install libcdio-utils
```

### Modul-Dateien

```
disk2iso-metadata/
├── lib/
│   └── libcdtext.sh           # Provider-Modul
├── conf/
│   └── libcdtext.ini          # Manifest
├── lang/
│   ├── libcdtext.de           # Deutsche Nachrichten
│   ├── libcdtext.en           # Englische Nachrichten
│   ├── libcdtext.es           # Spanische Nachrichten
│   └── libcdtext.fr           # Französische Nachrichten
└── doc/
    └── 04_Module/
        └── 04-4_Metadaten/
            └── 04-4-1_CD-Text.md  # Handbuch
```

## 🔧 Konfiguration

**Datei**: `conf/libcdtext.ini`

```ini
[module]
name = cdtext
version = 1.0.0
enabled = true
bundled_with = metadata

[dependencies]
external =
optional = cd-info,icedax,cdda2wav

[provider]
type = metadata
priority = 50
supported_media = audio-cd
```

**Priorität ändern** (höher = bevorzugt):
```ini
# CD-TEXT vor MusicBrainz bevorzugen
priority = 150
```

## 💻 API

### Provider-Funktionen

```bash
# Prüfe Verfügbarkeit
cdtext_test_available
# Rückgabe: 0 = Verfügbar, 1 = Nicht verfügbar

# Hole Priorität
cdtext_get_priority
# Ausgabe: 50

# Extrahiere Metadaten
cdtext_get_metadata "/dev/sr0"
# Rückgabe: 0 = Erfolg, 1 = Keine CD-TEXT Daten
# Setzt: DISC_DATA[artist], DISC_DATA[album], DISC_DATA[track.N.title]
```

### Unterstützte Felder

**Album-Level**:
- `artist` - Haupt-Künstler
- `album` - Album-Titel
- `track_count` - Anzahl Tracks

**Track-Level** (optional):
- `track.N.title` - Track-Titel
- `track.N.artist` - Track-Künstler
- `track.N.composer` - Komponist
- `track.N.songwriter` - Songwriter
- `track.N.arranger` - Arrangeur

## 🔄 Workflow

### Automatische Integration

CD-TEXT ist als Provider im Metadata-Framework registriert:

```
1. Audio-CD eingelegt
   ↓
2. Metadata-Framework startet Provider-Abfrage
   ↓
3. MusicBrainz (Priorität: 100) - Versuche Disc-ID Lookup
   ↓ (falls fehlgeschlagen)
4. CD-TEXT (Priorität: 50) - Lese eingebettete Daten
   ↓
5. Metadaten verfügbar für ISO-Erstellung
```

### Manuelle Nutzung

```bash
# CD-TEXT direkt auslesen (ohne Framework)
source lib/libcdtext.sh
cdtext_check_dependencies || exit 1

cdtext_get_metadata "/dev/sr0"
if [ $? -eq 0 ]; then
    echo "Artist: ${DISC_DATA[artist]}"
    echo "Album: ${DISC_DATA[album]}"
fi
```

## 📊 Verfügbarkeit

**CD-TEXT nach Genre**:
- Klassik: ~40%
- Jazz: ~30%
- Pop/Rock: ~10%
- Metal: ~5%

**CD-TEXT nach Jahr**:
- 1983-1995: < 1% (vor Standard)
- 1996-2000: ~5%
- 2001-2010: ~15%
- 2011-heute: ~25%

## 🔍 Troubleshooting

### Kein CD-TEXT gefunden

```bash
# Prüfe ob Tools installiert sind
which cd-info icedax cdda2wav

# Teste manuell
cd-info --cdtext-only /dev/sr0
```

**Lösung**: Automatischer Fallback zu MusicBrainz

### Falsche Zeichen (Umlaute)

**Problem**: ISO-8859-1 vs. UTF-8 Encoding

**Lösung**: MusicBrainz hat korrekte Unicode-Daten

### Nur Album, keine Track-Titel

**Häufig**: ~50% der CDs mit CD-TEXT haben nur Album-Daten

**Lösung**: disk2iso kombiniert automatisch:
- Album/Artist von CD-TEXT
- Track-Titel von MusicBrainz

## 📚 Dokumentation

- **Handbuch**: [doc/04_Module/04-4_Metadaten/04-4-1_CD-Text.md](doc/04_Module/04-4_Metadaten/04-4-1_CD-Text.md)
- **Provider-Vergleich**: [doc/04_Module/04-4_Metadaten.md](doc/04_Module/04-4_Metadaten.md#provider-vergleich)

## 🔗 Siehe auch

- [Kapitel 4.4.11: MusicBrainz-Provider](https://github.com/DirkGoetze/disk2iso-musicbrainz)
- [Kapitel 4.4.21: TMDB-Provider](https://github.com/DirkGoetze/disk2iso-tmdb)
- [libmetadata Framework](lib/libmetadata.sh)

## 📄 Lizenz

Siehe [LICENSE](LICENSE) im Hauptverzeichnis.
