// ========================================
// FONCTIONS DE DIAGNOSTIC POUR BOUTONS
// ========================================

// Bouton "💾 Sauvegarder"
window.manualSave = function() {
  if (window.flowiseTableBridge && window.flowiseTableBridge.performAutoSave) {
    window.flowiseTableBridge.performAutoSave()
      .then(() => alert('✅ SAUVEGARDE MANUELLE\n\nToutes les tables modifiées ont été sauvegardées !\n\nConsultez la console F12 pour les détails.'))
      .catch(err => alert('❌ Erreur sauvegarde:\n\n' + err.message));
  } else {
    alert('❌ ERREUR\n\nSystème auto-save non disponible.\n\nVérifiez la console F12.');
  }
};

// Bouton "🔍 Diagnostic"
window.diagnosticAutoSave = function() {
  const bridge = window.flowiseTableBridge;
  let msg = '🔍 DIAGNOSTIC AUTO-SAVE\n\n';
  msg += '1. Bridge existe ? ' + (bridge ? '✅ OUI' : '❌ NON') + '\n';
  if (bridge) {
    msg += '2. MutationObserver ? ' + (bridge.mutationObserver !== null ? '✅ ACTIF' : '❌ INACTIF') + '\n';
    msg += '3. performAutoSave ? ' + (typeof bridge.performAutoSave === 'function' ? '✅ OUI' : '❌ NON') + '\n';
    msg += '4. dirtyTables.size ? ' + (bridge.dirtyTables?.size || 0) + ' table(s)\n';
    msg += '5. autoSaveInterval ? ' + (bridge.autoSaveInterval !== null ? '✅ ACTIF' : '❌ INACTIF') + '\n';
  } else {
    msg += '\n❌ CRITIQUE: Bridge non initialisé\nRebuild requis !';
  }
  alert(msg);
};

// Bouton "🔧 Force Save"
window.forceSave = function() {
  const bridge = window.flowiseTableBridge;
  if (!bridge || bridge.dirtyTables.size === 0) {
    alert('ℹ️ AUCUNE TABLE MODIFIÉE\n\nAucune table en attente de sauvegarde.');
    return;
  }
  let msg = '💾 FORCER SAUVEGARDE\n\nTables en attente:\n';
  const tables = Array.from(bridge.dirtyTables);
  tables.forEach((t, i) => {
    msg += (i+1) + '. ' + t + '\n';
  });
  msg += '\n🔄 Tentative sauvegarde...';
  alert(msg);
  setTimeout(() => {
    bridge.performAutoSave()
      .then(() => alert('✅ SUCCÈS\n\nSauvegarde effectuée !\nVérifier console F12.'))
      .catch(err => alert('❌ ÉCHEC\n\nErreur: ' + err.message + '\n\nStack:\n' + err.stack));
  }, 500);
};

// Bouton "🔍 Debug Lookup"
window.debugLookup = async function() {
  try {
    const db = await new Promise((res, rej) => {
      const req = indexedDB.open('clara_db');
      req.onsuccess = () => res(req.result);
      req.onerror = () => rej(req.error);
    });
    
    if (!db.objectStoreNames.contains('clara_generated_tables')) {
      alert('⚠️ BASE VIDE\n\nclara_db existe mais clara_generated_tables pas encore créé.\n\nGénérez une table avec GPT pour initialiser le store.');
      db.close();
      return;
    }
    
    const tx = db.transaction(['clara_generated_tables'], 'readonly');
    const store = tx.objectStore('clara_generated_tables');
    const allTables = await new Promise((res, rej) => {
      const req = store.getAll();
      req.onsuccess = () => res(req.result);
      req.onerror = () => rej(req.error);
    });
    db.close();
    
    let msg = '🔍 DEBUG LOOKUP\n\n';
    msg += '📊 Total tables: ' + allTables.length + '\n\n';
    
    if (allTables.length === 0) {
      msg += '⚠️ Aucune table sauvegardée\n\nGénérez une table avec GPT';
      alert(msg);
      return;
    }
    
    const sessions = {};
    allTables.forEach(t => {
      const sid = t.sessionId || 'unknown';
      sessions[sid] = (sessions[sid] || 0) + 1;
    });
    
    msg += '📋 Tables par session:\n';
    Object.entries(sessions).forEach(([sid, count]) => {
      const shortId = sid === 'unknown' ? 'unknown' : sid.substring(0,8) + '...';
      msg += '  • ' + shortId + ': ' + count + '\n';
    });
    
    const fps = new Set(allTables.map(t => t.fingerprint).filter(f => f));
    msg += '\n🔑 Fingerprints uniques: ' + fps.size + '\n';
    if (allTables.length > fps.size) {
      msg += '⚠️ DOUBLONS DÉTECTÉS: ' + (allTables.length - fps.size) + ' table(s)\n';
    }
    
    msg += '\n📝 Dernières 5 tables:\n';
    allTables.slice(-5).forEach((t, i) => {
      const kw = t.keyword || 'no-keyword';
      const fp = t.fingerprint ? t.fingerprint.substring(0,8) + '...' : 'no-fp';
      const sid = t.sessionId ? t.sessionId.substring(0,8) + '...' : 'no-session';
      msg += (i+1) + '. ' + kw + '\n   FP: ' + fp + '\n   Sess: ' + sid + '\n';
    });
    
    alert(msg);
  } catch (err) {
    alert('❌ ERREUR\n\n' + err.message + '\n\nVérifiez:\n- clara_db existe ?\n- clara_generated_tables créé ?');
  }
};

// Bouton "🔎 Rechercher Table"
window.searchTable = async function() {
  const search = prompt('🔎 Rechercher table par nom\n\nEntrez mot-clé (ex: modelized, Table_4, Compte):', 'modelized');
  if (!search) return;
  
  console.log('🔎 [DIAGNOSTIC] Recherche: ' + search);
  
  const allTables = document.querySelectorAll('table');
  const domMatches = [];
  allTables.forEach((table, i) => {
    const kw = table.getAttribute('data-keyword') || '';
    const dtid = table.getAttribute('data-table-id') || '';
    const text = table.textContent.substring(0, 100);
    if (kw.toLowerCase().includes(search.toLowerCase()) || text.toLowerCase().includes(search.toLowerCase())) {
      domMatches.push({
        index: i+1,
        keyword: kw || 'N/A',
        dataTableId: dtid || '❌ MANQUANT',
        rows: table.querySelectorAll('tr').length,
        text: text.substring(0, 50) + '...'
      });
    }
  });
  
  try {
    const db = await new Promise((res, rej) => {
      const req = indexedDB.open('clara_db');
      req.onsuccess = () => res(req.result);
      req.onerror = () => rej(req.error);
    });
    
    const tx = db.transaction(['clara_generated_tables'], 'readonly');
    const store = tx.objectStore('clara_generated_tables');
    const allDBTables = await new Promise((res, rej) => {
      const req = store.getAll();
      req.onsuccess = () => res(req.result);
      req.onerror = () => rej(req.error);
    });
    db.close();
    
    const dbMatches = allDBTables.filter(t => (t.keyword || '').toLowerCase().includes(search.toLowerCase()));
    
    let msg = '🔎 RECHERCHE: "' + search + '"\n\n';
    msg += '📊 DOM: ' + domMatches.length + ' trouvée(s)\n';
    msg += '💾 IndexedDB: ' + dbMatches.length + ' trouvée(s)\n\n';
    
    if (domMatches.length > 0) {
      msg += '✅ TABLES DOM:\n';
      domMatches.forEach(t => {
        msg += '  ' + t.index + '. ' + t.keyword + '\n';
        msg += '     ID: ' + t.dataTableId + '\n';
        msg += '     Lignes: ' + t.rows + '\n';
      });
    } else {
      msg += '❌ Aucune table DOM trouvée\n';
    }
    
    if (dbMatches.length > 0) {
      msg += '\n💾 TABLES INDEXEDDB:\n';
      dbMatches.forEach(t => {
        msg += '  • ' + t.keyword + '\n';
        msg += '    ID: ' + t.id.substring(0, 12) + '...\n';
        msg += '    data-table-id: ' + (t.metadata?.dataTableId || '❌ manquant') + '\n';
        msg += '    Session: ' + (t.sessionId || 'N/A').substring(0, 8) + '...\n';
      });
    } else {
      msg += '\n❌ Aucune table IndexedDB trouvée\n';
    }
    
    if (domMatches.length === 0 && dbMatches.length > 0) {
      msg += '\n⚠️ PROBLÈME DÉTECTÉ:\nTable sauvegardée mais pas dans DOM !\nPeut expliquer problème restauration.';
    } else if (domMatches.length > 0 && dbMatches.length === 0) {
      msg += '\n⚠️ PROBLÈME DÉTECTÉ:\nTable dans DOM mais pas sauvegardée !\nModifiez-la pour déclencher sauvegarde.';
    } else if (domMatches.length > 0 && dbMatches.length > 0) {
      if (domMatches[0].dataTableId === '❌ MANQUANT') {
        msg += '\n🚨 PROBLÈME CRITIQUE:\nTable sans data-table-id !\nGénérera doublons à chaque modification.';
      } else {
        msg += '\n✅ Configuration OK';
      }
    }
    
    console.log(msg);
    alert(msg);
  } catch (err) {
    alert('❌ ERREUR DB\n\n' + err.message);
  }
};
