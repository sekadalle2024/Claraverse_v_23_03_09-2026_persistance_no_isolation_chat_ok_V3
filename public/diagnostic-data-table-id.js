/**
 * DIAGNOSTIC DATA-TABLE-ID
 * ========================
 * 
 * Objectif: Vérifier quelles tables ont/n'ont pas data-table-id
 * 
 * Utilisation: Cliquer bouton "🔬 Diagnostic data-table-id"
 */

(function diagnosticDataTableId() {
    console.log('🔬 [DIAGNOSTIC] Vérification data-table-id sur toutes les tables...');
    
    // Trouver toutes les tables dans le DOM
    const allTables = document.querySelectorAll('table');
    
    console.log(`📊 Total tables DOM: ${allTables.length}`);
    
    const withId = [];
    const withoutId = [];
    
    allTables.forEach((table, index) => {
        const dataTableId = table.getAttribute('data-table-id');
        const keyword = table.getAttribute('data-keyword');
        
        const info = {
            index: index + 1,
            dataTableId: dataTableId || '❌ MANQUANT',
            keyword: keyword || 'N/A',
            rows: table.querySelectorAll('tr').length,
            cols: table.querySelector('tr')?.children.length || 0
        };
        
        if (dataTableId) {
            withId.push(info);
        } else {
            withoutId.push(info);
        }
    });
    
    console.log(`\n✅ Tables AVEC data-table-id: ${withId.length}`);
    withId.forEach(t => {
        console.log(`  ${t.index}. "${t.keyword}" → id="${t.dataTableId.substring(0, 12)}..."`);
    });
    
    console.log(`\n❌ Tables SANS data-table-id: ${withoutId.length}`);
    if (withoutId.length > 0) {
        console.warn('⚠️ PROBLÈME DÉTECTÉ: Tables sans data-table-id généreront des doublons !');
        withoutId.forEach(t => {
            console.warn(`  ${t.index}. "${t.keyword}" → ${t.rows}×${t.cols} cells`);
        });
        console.log('\n💡 SOLUTION: Ces tables doivent recevoir data-table-id à la création');
    } else {
        console.log('✅ Toutes les tables ont data-table-id !');
    }
    
    // Rapport final
    const report = {
        totalDOM: allTables.length,
        withId: withId.length,
        withoutId: withoutId.length,
        percentage: ((withId.length / allTables.length) * 100).toFixed(1) + '%'
    };
    
    console.log(`\n📋 RAPPORT FINAL:`);
    console.log(`   Tables DOM: ${report.totalDOM}`);
    console.log(`   Avec ID: ${report.withId} (${report.percentage})`);
    console.log(`   Sans ID: ${report.withoutId}`);
    
    if (report.withoutId > 0) {
        alert(`⚠️ ${report.withoutId} table(s) sans data-table-id détectées !\n\nCes tables généreront des doublons à chaque modification.\n\nConsultez la console pour détails.`);
    } else {
        alert(`✅ Toutes les ${report.totalDOM} tables ont data-table-id !\n\nLe système devrait fonctionner correctement.`);
    }
})();
