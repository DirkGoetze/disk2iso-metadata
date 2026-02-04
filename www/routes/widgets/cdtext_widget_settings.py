#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
============================================================================
disk2iso - CD-TEXT Provider Widget Settings Route
============================================================================
Filepath: www/routes/widgets/cdtext_widget_settings.py

Beschreibung:
    Flask Blueprint für CD-TEXT Provider Einstellungs-Widget
    - Lädt CD-TEXT Provider-Konfiguration aus libcdtext.ini
    - Liefert HTML-Template und Config-Daten an Frontend
============================================================================
"""

from flask import Blueprint, jsonify, render_template
import subprocess
import os

# Blueprint erstellen
cdtext_widget_settings_bp = Blueprint(
    'cdtext_widget_settings',
    __name__,
    url_prefix='/api/widgets/cdtext'
)

# Pfade
INSTALL_DIR = os.environ.get('DISK2ISO_INSTALL_DIR', '/opt/disk2iso')
METADATA_DIR = os.path.join(INSTALL_DIR, '..', 'disk2iso-metadata')  # Siblings


def get_cdtext_config():
    """
    Liest CD-TEXT Provider-Konfiguration aus libcdtext.ini
    
    Returns:
        dict: Konfigurationswerte
    """
    config = {
        'CDTEXT_ENABLED': 'true',
        'CDTEXT_PRIORITY': 50
    }
    
    try:
        # Bash-Script zum Lesen der INI-Werte
        script = f"""
source {INSTALL_DIR}/lib/libsettings.sh

# Lese CD-TEXT Provider-Werte aus INI
ENABLED=$(config_get_value_ini "cdtext" "module" "enabled" "true")
PRIORITY=$(config_get_value_ini "cdtext" "provider" "priority" "50")

# Ausgabe als Key=Value
echo "CDTEXT_ENABLED=$ENABLED"
echo "CDTEXT_PRIORITY=$PRIORITY"
        """
        
        result = subprocess.run(
            ['bash', '-c', script],
            capture_output=True,
            text=True,
            timeout=5
        )
        
        if result.returncode == 0:
            # Parse Output
            for line in result.stdout.strip().split('\n'):
                if '=' in line:
                    key, value = line.split('=', 1)
                    # Konvertiere numerische Werte
                    if key == 'CDTEXT_PRIORITY':
                        try:
                            config[key] = int(value)
                        except ValueError:
                            pass  # Behalte Default
                    else:
                        config[key] = value
    
    except Exception as e:
        print(f"Fehler beim Lesen der CD-TEXT Provider Config: {e}")
    
    return config


@cdtext_widget_settings_bp.route('/settings', methods=['GET'])
def get_cdtext_settings_widget():
    """
    API-Endpoint: Liefert CD-TEXT Provider Settings Widget HTML + Config
    
    Returns:
        JSON: {
            'html': str,      # Widget HTML
            'config': dict    # Aktuelle Konfiguration
        }
    """
    try:
        # Lade Config
        config = get_cdtext_config()
        
        # Rendere Template
        html = render_template('widgets/cdtext_widget_settings.html')
        
        return jsonify({
            'success': True,
            'html': html,
            'config': config
        })
    
    except Exception as e:
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500


def register_blueprint(app):
    """
    Registriert Blueprint in Flask App
    
    Args:
        app: Flask Application Instanz
    """
    app.register_blueprint(cdtext_widget_settings_bp)
