/**
 * Metadata Framework - Dependencies Widget (4x1)
 * Zeigt Metadata Framework Core-Tools (jq, curl)
 * Version: 1.0.0
 */

function loadMetadataDependencies() {
    fetch('/api/system')
        .then(response => response.json())
        .then(data => {
            if (data.success && data.software) {
                updateMetadataDependencies(data.software);
            }
        })
        .catch(error => {
            console.error('Fehler beim Laden der Metadata-Dependencies:', error);
            showMetadataDependenciesError();
        });
}

function updateMetadataDependencies(softwareList) {
    const tbody = document.getElementById('metadata-dependencies-tbody');
    if (!tbody) return;
    
    // Metadata Framework Core-Tools (aus libmetadata.ini [dependencies])
    const metadataTools = [
        { name: 'jq', display_name: 'jq (JSON processor)' },
        { name: 'curl', display_name: 'curl' }
    ];
    
    let html = '';
    
    metadataTools.forEach(tool => {
        const software = softwareList.find(s => s.name === tool.name);
        if (software) {
            html += renderSoftwareRow(tool.display_name, software);
        }
    });
    
    if (html === '') {
        html = '<tr><td colspan="4" style="text-align: center; padding: 20px; color: #999;">Keine Informationen verfügbar</td></tr>';
    }
    
    tbody.innerHTML = html;
}

function showMetadataDependenciesError() {
    const tbody = document.getElementById('metadata-dependencies-tbody');
    if (!tbody) return;
    
    tbody.innerHTML = '<tr><td colspan="4" style="text-align: center; padding: 20px; color: #e53e3e;">Fehler beim Laden</td></tr>';
}

// Auto-Load
if (document.getElementById('metadata-dependencies-widget')) {
    loadMetadataDependencies();
}
