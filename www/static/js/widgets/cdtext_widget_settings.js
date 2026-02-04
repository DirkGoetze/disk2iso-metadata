/**
 * ============================================================================
 * disk2iso - CD-TEXT Provider Widget Settings JavaScript
 * ============================================================================
 * Filepath: www/static/js/widgets/cdtext_widget_settings.js
 * 
 * Beschreibung:
 *   Client-seitiges JavaScript für das CD-TEXT Provider Einstellungs-Widget
 *   - Lädt CD-TEXT Provider Konfiguration
 *   - Injiziert Widget in Settings-Seite
 * ============================================================================
 */

/**
 * Injiziert das CD-TEXT Provider Settings Widget ins DOM
 */
async function injectCdtextSettingsWidget() {
    const container = document.getElementById('cdtext-settings-container');
    if (!container) {
        console.warn('CD-TEXT settings container nicht gefunden');
        return;
    }

    try {
        // Lade Widget-Template
        const response = await fetch('/api/widgets/cdtext/settings');
        if (!response.ok) {
            throw new Error(`HTTP ${response.status}: ${response.statusText}`);
        }

        const data = await response.json();
        
        // Injiziere HTML
        container.innerHTML = data.html;

        // Setze Werte aus Config
        if (data.config) {
            // Aktivierung
            const enabledField = document.getElementById('cdtext-enabled');
            if (enabledField && data.config.CDTEXT_ENABLED !== undefined) {
                enabledField.value = data.config.CDTEXT_ENABLED;
            }

            // Priorität
            const priorityField = document.getElementById('cdtext-priority');
            if (priorityField && data.config.CDTEXT_PRIORITY !== undefined) {
                priorityField.value = data.config.CDTEXT_PRIORITY;
            }
        }

        console.log('CD-TEXT provider settings widget erfolgreich injiziert');
    } catch (error) {
        console.error('Fehler beim Laden des CD-TEXT provider settings widgets:', error);
        container.innerHTML = `
            <div class="error-box">
                <i class="fas fa-exclamation-triangle"></i>
                <p>Fehler beim Laden der CD-TEXT Provider Einstellungen: ${error.message}</p>
            </div>
        `;
    }
}

// Auto-Inject beim Laden der Seite (wenn Container vorhanden)
if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', injectCdtextSettingsWidget);
} else {
    injectCdtextSettingsWidget();
}
