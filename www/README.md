# Metadata Widget Settings

Einstellungswidget für das Metadata Framework in disk2iso.

## 📋 Übersicht

Das Metadata-Widget ermöglicht die Konfiguration folgender Framework-Parameter:

- **Auswahl-Timeout**: Wie lange auf Benutzer-Metadaten-Auswahl gewartet wird (Standard: 60s)
- **Cache-Aktivierung**: Zwischenspeichern von API-Abfragen (Standard: aktiviert)
- **Prüfintervall**: Wie oft während des Timeouts geprüft wird (Standard: 1s)  
- **Default Apply-Funktion**: Name der Standard-Anwendungsfunktion (Entwickler-Option)

## 📦 Installation

### Dateien

```
disk2iso/
├── www/
│   ├── templates/
│   │   └── widgets/
│   │       └── metadata_widget_settings.html
│   ├── static/
│   │   └── js/
│   │       └── widgets/
│   │           └── metadata_widget_settings.js
│   └── routes/
│       └── widgets/
│           └── metadata_widget_settings.py
```

### Integration in settings.html

```html
<!-- Metadata Framework (libmetadata) -->
<div id="metadata-settings-container"></div>

<!-- JavaScript -->
<script src="{{ url_for('static', filename='js/widgets/metadata_widget_settings.js') }}"></script>
```

### Blueprint-Registrierung in app.py

```python
from routes.widgets.metadata_widget_settings import metadata_widget_settings_bp
app.register_blueprint(metadata_widget_settings_bp)
```

## 🔧 Konfiguration

Das Widget liest Einstellungen aus `disk2iso-metadata/conf/libmetadata.ini`:

```ini
[framework]
selection_timeout = 60
cache_enabled = true
check_interval = 1
default_apply_func = metadata_default_apply
```

## 📡 API-Endpunkt

**GET** `/api/widgets/metadata/settings`

Liefert Widget-HTML und aktuelle Konfiguration:

```json
{
  "success": true,
  "html": "<div class='settings-section'>...</div>",
  "config": {
    "METADATA_SELECTION_TIMEOUT": 60,
    "METADATA_CACHE_ENABLED": "true",
    "METADATA_CHECK_INTERVAL": 1,
    "METADATA_DEFAULT_APPLY_FUNC": "metadata_default_apply"
  }
}
```

## 🎨 Verwendung

Das Widget wird automatisch beim Laden der Settings-Seite injiziert:

1. `injectMetadataSettingsWidget()` lädt Widget-HTML vom Server
2. Formularfelder werden mit aktuellen Config-Werten befüllt
3. Änderungen werden über `handleFieldChange()` (aus settings.js) getrackt
4. Speichern über zentrale Save-Funktion

## 📝 Hinweise

- Die Provider-spezifischen Einstellungen (TMDB API Key, etc.) befinden sich in separaten Widgets
- Änderungen erfordern einen Neustart des disk2iso-Service
- Standard-Werte werden bei fehlenden INI-Einträgen verwendet
