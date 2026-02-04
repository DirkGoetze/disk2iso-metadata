# disk2iso-metadata - Metadata Framework für disk2iso

🎯 Zentrales Metadata-Framework mit Provider-System für alle Disc-Typen in disk2iso.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Platform: Linux](https://img.shields.io/badge/Platform-Linux-blue.svg)](https://www.debian.org/)
[![Shell: Bash](https://img.shields.io/badge/Shell-Bash-green.svg)](https://www.gnu.org/software/bash/)
[![Version](https://img.shields.io/badge/Version-1.2.1-blue.svg)](VERSION)

## ✨ Features

- 🔌 **Provider-System** - Modulares Registrierungssystem für Metadata-Provider (MusicBrainz, TMDB, Discogs, etc.)
- 🔄 **Generic Workflow** - Query/Wait/Apply-Pattern für alle Provider
- 💾 **Cache-Management** - Intelligente Zwischenspeicherung von Metadaten
- 🎯 **State-Machine Integration** - Nahtlose Integration in disk2iso State-Machine
- 🌍 **Mehrsprachig** - 4 Sprachen (de, en, es, fr)
- 📊 **API-Integration** - REST-API Support für externe Abfragen

## 🏗️ Architektur

### Provider-System

Das Framework ermöglicht die dynamische Registrierung von Metadata-Providern:

```bash
# Provider registrieren (in Provider-Modul)
metadata_register_provider "musicbrainz" \
    "musicbrainz_query" \
    "musicbrainz_wait_for_selection" \
    "musicbrainz_apply_metadata"

# Automatischer Aufruf durch Framework
metadata_query_all_providers      # Ruft alle registrierten Provider auf
metadata_wait_for_selection        # Wartet auf Nutzer-Auswahl
metadata_apply_selected            # Wendet gewählte Metadaten an
```

### Workflow

```
1. Query Phase
   └─> Framework ruft query-Funktion aller Provider auf
       └─> Provider suchen nach Metadaten
           └─> Ergebnisse werden zwischengespeichert

2. Wait Phase
   └─> Framework wartet auf Nutzer-Auswahl (Web-UI/API)
       └─> Provider zeigen ihre Ergebnisse an

3. Apply Phase
   └─> Framework ruft apply-Funktion des gewählten Providers auf
       └─> Provider schreibt Metadaten in Dateien/Tags
```

## 🧩 Verfügbare Provider

| Provider | Status | Beschreibung | Repository |
|----------|--------|--------------|------------|
| [MusicBrainz](https://github.com/DirkGoetze/disk2iso-musicbrainz) | ✅ Stabil | Audio-CD Metadaten mit Disc-ID Lookup | [GitHub](https://github.com/DirkGoetze/disk2iso-musicbrainz) |
| [TMDB](https://github.com/DirkGoetze/disk2iso-tmdb) | ✅ Stabil | Film-/TV-Metadaten mit Cover-Art | [GitHub](https://github.com/DirkGoetze/disk2iso-tmdb) |
| Discogs | 🚧 Geplant | Erweiterte Audio-Metadaten | - |

## 📦 Installation

### Als disk2iso-Modul

Das Metadata-Framework wird **automatisch mit disk2iso installiert** (Core-Komponente).

```bash
# disk2iso Installation
git clone https://github.com/DirkGoetze/disk2iso.git
cd disk2iso
sudo ./install.sh
```

### Standalone (für Entwicklung)

```bash
# Repository klonen
git clone https://github.com/DirkGoetze/disk2iso-metadata.git
cd disk2iso-metadata

# Framework-Bibliothek einbinden
source lib/libmetadata.sh

# Abhängigkeiten prüfen
metadata_check_dependencies
```

## 🔧 Konfiguration

**Datei:** `conf/libmetadata.ini`

```ini
# Metadata Framework Konfiguration
METADATA_CACHE_DIR=/tmp/disk2iso/metadata
METADATA_CACHE_TTL=3600
METADATA_AUTO_APPLY=false
METADATA_PROVIDER_TIMEOUT=30
```

**Beschreibung:**
- `METADATA_CACHE_DIR`: Verzeichnis für Metadaten-Cache
- `METADATA_CACHE_TTL`: Cache-Gültigkeit in Sekunden
- `METADATA_AUTO_APPLY`: Automatische Anwendung der ersten Treffer
- `METADATA_PROVIDER_TIMEOUT`: Timeout für Provider-Abfragen

## 💻 API

### Provider registrieren

```bash
metadata_register_provider <name> <query_func> <wait_func> <apply_func>
```

**Parameter:**
- `name`: Eindeutiger Provider-Name
- `query_func`: Funktion für Metadaten-Suche
- `wait_func`: Funktion für Nutzer-Auswahl
- `apply_func`: Funktion zum Anwenden der Metadaten

**Beispiel:**
```bash
metadata_register_provider "tmdb" \
    "tmdb_query" \
    "tmdb_wait_for_selection" \
    "tmdb_apply_metadata"
```

### Workflow-Funktionen

```bash
# Alle Provider abfragen
metadata_query_all_providers

# Auf Auswahl warten
metadata_wait_for_selection

# Metadaten anwenden
metadata_apply_selected <provider> <result_id>
```

### Cache-Management

```bash
# Cache initialisieren
metadata_init_cache

# Cache lesen
metadata_get_cached <disc_id> <provider>

# Cache schreiben
metadata_set_cache <disc_id> <provider> <data>

# Cache löschen
metadata_clear_cache [disc_id]
```

## 🔌 Provider entwickeln

**Minimales Provider-Modul:**

```bash
#!/bin/bash
# lib/libmyprovider.sh

# 1. Query-Funktion (Metadaten suchen)
myprovider_query() {
    local disc_type="$1"
    local disc_id="$2"
    
    # API-Abfrage durchführen
    # Ergebnisse in JSON speichern
    # Return 0 bei Erfolg
}

# 2. Wait-Funktion (Auf Nutzer-Auswahl warten)
myprovider_wait_for_selection() {
    # Ergebnisse in UI anzeigen
    # Warten auf API-Callback
    # Return 0 bei Auswahl
}

# 3. Apply-Funktion (Metadaten anwenden)
myprovider_apply_metadata() {
    local result_id="$1"
    
    # Gewählte Metadaten laden
    # In Dateien/Tags schreiben
    # Return 0 bei Erfolg
}

# 4. Provider registrieren
metadata_register_provider "myprovider" \
    "myprovider_query" \
    "myprovider_wait_for_selection" \
    "myprovider_apply_metadata"
```

## 🌍 Mehrsprachigkeit

Das Framework unterstützt 4 Sprachen:

- 🇩🇪 **Deutsch** (`lang/libmetadata.de`)
- 🇬🇧 **Englisch** (`lang/libmetadata.en`)
- 🇪🇸 **Spanisch** (`lang/libmetadata.es`)
- 🇫🇷 **Französisch** (`lang/libmetadata.fr`)

**Sprache ändern:**
```bash
# In disk2iso.conf
LANGUAGE="en"
```

## 📊 Statistiken

- **Dateigröße:** ~34 KB (843 Zeilen)
- **Funktionen:** 25+ Framework-Funktionen
- **Provider-API:** 3 Callback-Funktionen pro Provider
- **Cache-System:** TTL-basiert mit automatischer Bereinigung

## 🔗 Integration

### disk2iso Core

Das Framework ist integraler Bestandteil von disk2iso:

```bash
# In disk2iso.sh
source lib/libmetadata.sh
metadata_check_dependencies

# Automatischer Aufruf in State-Machine
state_metadata_query() {
    metadata_query_all_providers || return 1
}

state_metadata_wait() {
    metadata_wait_for_selection || return 1
}

state_metadata_apply() {
    metadata_apply_selected || return 1
}
```

### Web-Interface

```python
# Flask Route für Metadaten-Auswahl
@app.route('/api/metadata/select', methods=['POST'])
def select_metadata():
    provider = request.json['provider']
    result_id = request.json['result_id']
    # Trigger metadata_apply_selected
```

## 🐛 Debugging

```bash
# Debug-Modus aktivieren
export DEBUG_METADATA=true

# Provider-Status anzeigen
metadata_list_providers

# Cache-Inhalt prüfen
ls -lh /tmp/disk2iso/metadata/

# Log-Ausgabe
tail -f /var/log/disk2iso/disk2iso.log | grep METADATA
```

## 📝 Changelog

Siehe [CHANGELOG.md](CHANGELOG.md) für Details zu allen Änderungen.

## 📄 Lizenz

MIT License - siehe [LICENSE](LICENSE) Datei.

## 🔗 Links

- **Hauptprojekt:** [disk2iso](https://github.com/DirkGoetze/disk2iso)
- **MusicBrainz Provider:** [disk2iso-musicbrainz](https://github.com/DirkGoetze/disk2iso-musicbrainz)
- **TMDB Provider:** [disk2iso-tmdb](https://github.com/DirkGoetze/disk2iso-tmdb)
- **Dokumentation:** [disk2iso Handbuch](https://github.com/DirkGoetze/disk2iso/blob/main/doc/Handbuch.md)

## 👤 Autor

**D. Götze**

## 🙏 Danksagungen

- MusicBrainz API für Audio-Metadaten
- TMDB API für Film-/TV-Metadaten
- disk2iso Community
