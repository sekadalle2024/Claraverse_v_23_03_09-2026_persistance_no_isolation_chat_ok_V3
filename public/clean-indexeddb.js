/**
 * SCRIPT DE NETTOYAGE INDEXEDDB
 * ==============================
 * 
 * Objectif: Supprimer clara_db pour forcer recréation avec DB_VERSION 13
 *          (index unique sessionId_fingerprint supprimé, lookup par data-table-id)
 * 
 * Utilisation:
 * 1. Cliquer bouton "🧹 Nettoyer IndexedDB"
 * 2. La page se rechargera automatiquement
 * 3. clara_db sera recréé en version 13 (propre)
 * 
 * Fichier: public/clean-indexeddb.js
 * Date: 29 août 2026 - Mise à jour DB_VERSION 13
 */

(function cleanIndexedDB() {
    console.log('🧹 [CLEAN] Démarrage nettoyage IndexedDB...');
    
    const databases = ['clara_db', 'FloTableDB']; // Supprimer les deux bases
    let deletedCount = 0;
    
    databases.forEach((dbName, index) => {
        const deleteRequest = indexedDB.deleteDatabase(dbName);
        
        deleteRequest.onsuccess = function() {
            console.log(`✅ [CLEAN] ${dbName} supprimé avec succès`);
            deletedCount++;
            
            // Recharger quand toutes les bases sont supprimées
            if (deletedCount === databases.length) {
                console.log('✅ [CLEAN] Nettoyage terminé !');
                console.log('🔄 [CLEAN] Rechargement dans 2 secondes...');
                setTimeout(() => {
                    window.location.reload();
                }, 2000);
            }
        };
        
        deleteRequest.onerror = function(event) {
            console.warn(`⚠️ [CLEAN] ${dbName} non trouvé ou erreur (peut être normal)`);
            deletedCount++;
            
            // Continuer même si erreur
            if (deletedCount === databases.length) {
                console.log('🔄 [CLEAN] Rechargement dans 2 secondes...');
                setTimeout(() => {
                    window.location.reload();
                }, 2000);
            }
        };
        
        deleteRequest.onblocked = function() {
            console.warn(`⚠️ [CLEAN] ${dbName} bloqué - Fermez autres onglets`);
            alert('⚠️ Suppression bloquée\n\nVeuillez:\n1. Fermer tous les autres onglets Claraverse\n2. Réessayer le nettoyage');
        };
    });
    
    console.log('⏳ [CLEAN] Suppression en cours...');
})();
