#!/bin/bash
# ===========================================================================
# CD-TEXT Metadata Provider
# ===========================================================================
# Filepath: lib/libcdtext.sh
#
# Beschreibung:
#   Provider-Modul für CD-TEXT Metadaten-Extraktion
#   Liest eingebettete Metadaten direkt von der Audio-CD
#
# ---------------------------------------------------------------------------
# Dependencies: liblogging, libmetadata (optional: icedax, cd-info, cdda2wav)
# ---------------------------------------------------------------------------
# Author: D.Götze
# Version: 1.0.0
# Last Change: 2026-02-04
# ===========================================================================

# ===========================================================================
# DEPENDENCY CHECK
# ===========================================================================
readonly MODULE_NAME_CDTEXT="cdtext"
SUPPORT_CDTEXT=false
INITIALIZED_CDTEXT=false
ACTIVATED_CDTEXT=false
CDTEXT_PRIORITY=50  # Default-Priorität (überschreibbar via INI)

# ===========================================================================
# cdtext_check_dependencies
# ---------------------------------------------------------------------------
# Funktion.: Prüfe alle Modul-Abhängigkeiten
# Parameter: keine
# Rückgabe.: 0 = Verfügbar, 1 = Nicht verfügbar
# Extras...: Setzt SUPPORT_CDTEXT=true/false
# ===========================================================================
cdtext_check_dependencies() {
    log_debug "CD-TEXT: Prüfe Abhängigkeiten..."

    # Alle Modul Abhängigkeiten prüfen
    check_module_dependencies "$MODULE_NAME_CDTEXT" || return 1

    # Lade Modul-Konfiguration
    load_config_cdtext || return 1

    # Setze Verfügbarkeit
    SUPPORT_CDTEXT=true
    log_debug "CD-TEXT: Abhängigkeiten erfüllt"
    
    log_info "CD-TEXT Provider verfügbar"
    return 0
}

# ===========================================================================
# load_config_cdtext
# ---------------------------------------------------------------------------
# Funktion.: Lade CD-TEXT Provider Konfiguration
# Parameter: keine
# Rückgabe.: 0 = Erfolgreich geladen
# ===========================================================================
load_config_cdtext() {
    # Lese enabled aus INI (Standard: true)
    local enabled
    enabled=$(settings_get_value_ini "$MODULE_NAME_CDTEXT" "module" "enabled" "true")
    
    # Setze Aktivierung
    if [[ "$enabled" == "true" ]]; then
        ACTIVATED_CDTEXT=true
    else
        ACTIVATED_CDTEXT=false
        log_info "CD-TEXT: Deaktiviert via Konfiguration"
    fi
    
    # Lese Priorität aus INI (Standard: 50)
    local priority
    priority=$(settings_get_value_ini "$MODULE_NAME_CDTEXT" "provider" "priority" "50")
    CDTEXT_PRIORITY="${priority}"
    
    INITIALIZED_CDTEXT=true
    
    log_info "CD-TEXT: Konfiguration geladen (enabled=$enabled, priority=$CDTEXT_PRIORITY)"
    return 0
}

# ===========================================================================
# is_cdtext_ready
# ---------------------------------------------------------------------------
# Funktion.: Prüfe ob CD-TEXT Provider bereit ist
# Parameter: keine
# Rückgabe.: 0 = Bereit, 1 = Nicht bereit
# ===========================================================================
is_cdtext_ready() {
    [[ "$SUPPORT_CDTEXT" == "true" ]] && \
    [[ "$INITIALIZED_CDTEXT" == "true" ]] && \
    [[ "$ACTIVATED_CDTEXT" == "true" ]]
}

# ===========================================================================
# cdtext_get_priority
# ---------------------------------------------------------------------------
# Funktion.: Gibt Provider-Priorität zurück
# Parameter: keine
# Rückgabe.: Priorität (0-100, höher = bevorzugt)
# Hinweis..: CD-TEXT: 50 (Standard, konfigurierbar via libcdtext.ini)
# ===========================================================================
cdtext_get_priority() {
    echo "${CDTEXT_PRIORITY:-50}"
}

# ===========================================================================
# cdtext_get_metadata
# ---------------------------------------------------------------------------
# Funktion.: CD-TEXT Metadaten von Audio-CD auslesen
# Parameter: $1 = CD-Device (z.B. /dev/sr0)
# Rückgabe.: 0 = Metadaten gefunden, 1 = Keine CD-TEXT Daten
# Setzt....: DISC_DATA[artist], DISC_DATA[album], DISC_DATA[track_count]
#            DISC_DATA[track.N.title], DISC_DATA[track.N.artist] (optional)
# Provider.: cdtext (eingebettet in Disc)
# Hinweis..: CD-TEXT nach Red Book Standard unterstützt pro Track:
#            TITLE, PERFORMER, SONGWRITER, COMPOSER, ARRANGER, MESSAGE
# ===========================================================================
cdtext_get_metadata() {
    local cd_device="${1:-$CD_DEVICE}"
    local artist=""
    local album=""
    local track_count=0
    local found_tracks=false
    
    [[ -z "$cd_device" ]] && {
        log_error "CD-TEXT: Kein CD-Device angegeben"
        return 1
    }
    
    log_info "CD-TEXT: Versuche Metadaten zu lesen..."
    
    # Methode 1: cd-info (aus libcdio-utils) - BESTE Methode für Track-Details
    if command -v cd-info >/dev/null 2>&1; then
        local cdtext_output
        cdtext_output=$(cd-info --no-header --no-device-info --cdtext-only "$cd_device" 2>/dev/null)
        
        if [[ -n "$cdtext_output" ]]; then
            # Extrahiere Album-Level Daten (erste TITLE/PERFORMER Einträge)
            album=$(echo "$cdtext_output" | grep -i "TITLE" | head -1 | cut -d':' -f2- | xargs)
            artist=$(echo "$cdtext_output" | grep -i "PERFORMER" | head -1 | cut -d':' -f2- | xargs)
            
            # Extrahiere Track-Level Daten (cd-info Format: "CD-TEXT for Track N:")
            local current_track=0
            local in_track_section=false
            
            while IFS= read -r line; do
                # Erkenne Track-Sektion: "CD-TEXT for Track 1:"
                if [[ "$line" =~ ^CD-TEXT\ for\ Track\ ([0-9]+): ]]; then
                    current_track="${BASH_REMATCH[1]}"
                    in_track_section=true
                    ((track_count++))
                    continue
                fi
                
                # Erkenne Disc-Sektion (Ende der Track-Daten)
                if [[ "$line" =~ ^CD-TEXT\ for\ Disc: ]]; then
                    in_track_section=false
                    continue
                fi
                
                # Lese Track-Daten
                if [[ "$in_track_section" == true ]] && [[ $current_track -gt 0 ]]; then
                    if [[ "$line" =~ ^[[:space:]]*TITLE:[[:space:]]*(.*) ]]; then
                        local track_title="${BASH_REMATCH[1]}"
                        if [[ -n "$track_title" ]]; then
                            DISC_DATA["track.${current_track}.title"]="$track_title"
                            found_tracks=true
                        fi
                    elif [[ "$line" =~ ^[[:space:]]*PERFORMER:[[:space:]]*(.*) ]]; then
                        local track_artist="${BASH_REMATCH[1]}"
                        if [[ -n "$track_artist" ]]; then
                            DISC_DATA["track.${current_track}.artist"]="$track_artist"
                        fi
                    elif [[ "$line" =~ ^[[:space:]]*COMPOSER:[[:space:]]*(.*) ]]; then
                        local track_composer="${BASH_REMATCH[1]}"
                        if [[ -n "$track_composer" ]]; then
                            DISC_DATA["track.${current_track}.composer"]="$track_composer"
                        fi
                    elif [[ "$line" =~ ^[[:space:]]*SONGWRITER:[[:space:]]*(.*) ]]; then
                        local track_songwriter="${BASH_REMATCH[1]}"
                        if [[ -n "$track_songwriter" ]]; then
                            DISC_DATA["track.${current_track}.songwriter"]="$track_songwriter"
                        fi
                    elif [[ "$line" =~ ^[[:space:]]*ARRANGER:[[:space:]]*(.*) ]]; then
                        local track_arranger="${BASH_REMATCH[1]}"
                        if [[ -n "$track_arranger" ]]; then
                            DISC_DATA["track.${current_track}.arranger"]="$track_arranger"
                        fi
                    fi
                fi
            done <<< "$cdtext_output"
            
            if [[ -n "$artist" ]] && [[ -n "$album" ]]; then
                # Setze DISC_DATA Array
                discdata_set_artist "$artist"
                discdata_set_album "$album"
                [[ $track_count -gt 0 ]] && discdata_set_track_count "$track_count"
                
                # Setze Provider
                discinfo_set_provider "cdtext"
                
                if [[ "$found_tracks" == true ]]; then
                    log_info "CD-TEXT: Gefunden - $artist - $album ($track_count Tracks mit Titeln)"
                else
                    log_info "CD-TEXT: Gefunden - $artist - $album"
                fi
                return 0
            fi
        fi
    fi
    
    # Methode 2: icedax (aus cdrtools/cdrkit)
    if command -v icedax >/dev/null 2>&1; then
        local cdtext_output
        cdtext_output=$(icedax -J -H -D "$cd_device" -v all 2>&1)
        
        if [[ -n "$cdtext_output" ]]; then
            album=$(echo "$cdtext_output" | grep "^Albumtitle:" | head -1 | cut -d':' -f2- | xargs)
            artist=$(echo "$cdtext_output" | grep "^Performer:" | head -1 | cut -d':' -f2- | xargs)
            
            local max_track=0
            while IFS= read -r line; do
                if [[ "$line" =~ ^Tracktitle\[([0-9]+)\]:[[:space:]]*(.*) ]]; then
                    local track_num="${BASH_REMATCH[1]}"
                    local track_title="${BASH_REMATCH[2]}"
                    if [[ -n "$track_title" ]]; then
                        DISC_DATA["track.${track_num}.title"]="$track_title"
                        found_tracks=true
                        [[ $track_num -gt $max_track ]] && max_track=$track_num
                    fi
                elif [[ "$line" =~ ^Trackperformer\[([0-9]+)\]:[[:space:]]*(.*) ]]; then
                    local track_num="${BASH_REMATCH[1]}"
                    local track_artist="${BASH_REMATCH[2]}"
                    [[ -n "$track_artist" ]] && DISC_DATA["track.${track_num}.artist"]="$track_artist"
                elif [[ "$line" =~ ^Trackcomposer\[([0-9]+)\]:[[:space:]]*(.*) ]]; then
                    local track_num="${BASH_REMATCH[1]}"
                    local track_composer="${BASH_REMATCH[2]}"
                    [[ -n "$track_composer" ]] && DISC_DATA["track.${track_num}.composer"]="$track_composer"
                fi
            done <<< "$cdtext_output"
            
            [[ $max_track -gt $track_count ]] && track_count=$max_track
            
            if [[ -n "$artist" ]] && [[ -n "$album" ]]; then
                discdata_set_artist "$artist"
                discdata_set_album "$album"
                [[ $track_count -gt 0 ]] && discdata_set_track_count "$track_count"
                discinfo_set_provider "cdtext"
                
                if [[ "$found_tracks" == true ]]; then
                    log_info "CD-TEXT: Gefunden - $artist - $album ($track_count Tracks mit Titeln)"
                else
                    log_info "CD-TEXT: Gefunden - $artist - $album"
                fi
                return 0
            fi
        fi
    fi
    
    # Methode 3: cdda2wav (aus cdrtools)
    if command -v cdda2wav >/dev/null 2>&1; then
        local cdtext_output
        cdtext_output=$(cdda2wav -J -H -D "$cd_device" -v all 2>&1)
        
        if [[ -n "$cdtext_output" ]]; then
            album=$(echo "$cdtext_output" | grep "^Albumtitle:" | head -1 | cut -d':' -f2- | xargs)
            artist=$(echo "$cdtext_output" | grep "^Performer:" | head -1 | cut -d':' -f2- | xargs)
            
            local max_track=0
            while IFS= read -r line; do
                if [[ "$line" =~ ^Tracktitle\[([0-9]+)\]:[[:space:]]*(.*) ]]; then
                    local track_num="${BASH_REMATCH[1]}"
                    local track_title="${BASH_REMATCH[2]}"
                    if [[ -n "$track_title" ]]; then
                        DISC_DATA["track.${track_num}.title"]="$track_title"
                        found_tracks=true
                        [[ $track_num -gt $max_track ]] && max_track=$track_num
                    fi
                elif [[ "$line" =~ ^Trackperformer\[([0-9]+)\]:[[:space:]]*(.*) ]]; then
                    local track_num="${BASH_REMATCH[1]}"
                    local track_artist="${BASH_REMATCH[2]}"
                    [[ -n "$track_artist" ]] && DISC_DATA["track.${track_num}.artist"]="$track_artist"
                fi
            done <<< "$cdtext_output"
            
            [[ $max_track -gt $track_count ]] && track_count=$max_track
            
            if [[ -n "$artist" ]] && [[ -n "$album" ]]; then
                discdata_set_artist "$artist"
                discdata_set_album "$album"
                [[ $track_count -gt 0 ]] && discdata_set_track_count "$track_count"
                discinfo_set_provider "cdtext"
                
                if [[ "$found_tracks" == true ]]; then
                    log_info "CD-TEXT: Gefunden - $artist - $album ($track_count Tracks mit Titeln)"
                else
                    log_info "CD-TEXT: Gefunden - $artist - $album"
                fi
                return 0
            fi
        fi
    fi
    
    log_info "CD-TEXT: Keine Metadaten gefunden"
    return 1
}

# ===========================================================================
# cdtext_test_available
# ---------------------------------------------------------------------------
# Funktion.: Prüft ob CD-TEXT Provider verfügbar ist
# Parameter: keine
# Rückgabe.: 0 = Verfügbar, 1 = Nicht verfügbar
# ===========================================================================
cdtext_test_available() {
    is_cdtext_ready
}
