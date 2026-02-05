/**
 * CD-Text Module - Dependencies Widget (4x1)
 * Zeigt CD-Text Provider spezifische Tools (cd-info, icedax, cdda2wav)
 * Version: 1.0.0
 */

function loadCdtextDependencies() {
    fetch('/api/system')
        .then(response => response.json())
        .then(data => {
            if (data.success && data.software) {
                updateCdtextDependencies(data.software);
            }
        })
        .catch(error => {
            console.error('Fehler beim Laden der CD-Text-Dependencies:', error);
            showCdtextDependenciesError();
        });
}

function updateCdtextDependencies(softwareList) {
    const tbody = document.getElementById('cdtext-dependencies-tbody');
    if (!tbody) return;
    
    // CD-Text-spezifische Tools (aus libcdtext.ini [dependencies])
    const cdtextTools = [
        { name: 'cd-info', display_name: 'cd-info (libcdio)' },
        { name: 'icedax', display_name: 'icedax (cdrkit)' },
        { name: 'cdda2wav', display_name: 'cdda2wav (cdrtools)' }
    ];
    
    let html = '';
    
    cdtextTools.forEach(tool => {
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

function showCdtextDependenciesError() {
    const tbody = document.getElementById('cdtext-dependencies-tbody');
    if (!tbody) return;
    
    tbody.innerHTML = '<tr><td colspan="4" style="text-align: center; padding: 20px; color: #e53e3e;">Fehler beim Laden</td></tr>';
}

// Auto-Load
if (document.getElementById('cdtext-dependencies-widget')) {
    loadCdtextDependencies();
}
