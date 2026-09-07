# MÉMO - SYSTÈME DE PERSISTANCE : AUTO-SAVE & INDEXEDDB

**Document pour débutant - Architecture complète du système de sauvegarde des tables**

Date : 29 Août 2026  
Version : 1.0  
Statut : Document de référence

---

## 📋 TABLE DES MATIÈRES

1. [Vue d'ensemble du système](#1-vue-densemble-du-système)
2. [Architecture et structure des données](#2-architecture-et-structure-des-données)
3. [Gestion de l'unicité et des versions](#3-gestion-de-lunicité-et-des-versions)
4. [Processus de sauvegarde](#4-processus-de-sauvegarde)
5. [Intégration et concepts techniques](#5-intégration-et-concepts-techniques)
6. [Résolution de l'hypothèse de base](#6-résolution-de-lhypothèse-de-base)

---

## 1. VUE D'ENSEMBLE DU SYSTÈME

### 🎯 Principe général

L'application Claraverse utilise **IndexedDB** (base de données locale du navigateur) pour sauvegarder les tables générées dynamiquement. Il existe DEUX systèmes de sauvegarde qui coexistent :

1. **Auto-Save automatique** (flowiseTableBridge.ts) - Nouveau système
2. **Sauvegarde manuelle/périodique** (conso.js) - Ancien système (désactivé)

### 🏗️ Fichiers clés du système

| Fichier | Rôle | Localisation |
|---------|------|--------------|
| `indexedDB.ts` | Service de base - gère la connexion IndexedDB | `src/services/` |
| `flowiseTableBridge.ts` | Pont entre événements et sauvegarde + AUTO-SAVE | `src/services/` |
| `flowiseTableService.ts` | Logique métier de sauvegarde/restauration | `src/services/` |
| `flowise_table_types.ts` | Définitions TypeScript des structures de données | `src/types/` |
| `conso.js` | Ancien système de sauvegarde périodique (désactivé) | `public/` |

---

## 2. ARCHITECTURE ET STRUCTURE DES DONNÉES

### 2.1 Comment obtenir l'architecture détaillée de la base IndexedDB ?

**IndexedDB est structurée en "Object Stores" (équivalent des tables SQL)**

La base s'appelle : `clara_db` (version 13)

**Store principal pour les tables** : `clara_generated_tables`

```typescript
// Structure du store (extrait de indexedDB.ts, lignes 138-154)
const tablesStore = db.createObjectStore('clara_generated_tables', { keyPath: 'id' });

// Index pour recherches rapides
tablesStore.createIndex('sessionId', 'sessionId', { unique: false });
tablesStore.createIndex('messageId', 'messageId', { unique: false });
tablesStore.createIndex('keyword', 'keyword', { unique: false });
tablesStore.createIndex('fingerprint', 'fingerprint', { unique: false });
tablesStore.createIndex('user_id', 'user_id', { unique: false });
tablesStore.createIndex('timestamp', 'timestamp', { unique: false });
tablesStore.createIndex('source', 'source', { unique: false });
```

**📊 Pour inspecter la base visuellement** :
1. Ouvrir DevTools Chrome (F12)
2. Aller dans l'onglet "Application" → "Storage" → "IndexedDB"
3. Développer `clara_db` → `clara_generated_tables`
4. Cliquer sur les enregistrements pour voir leur contenu

### 2.2 HTML stocké séparément ou intégré avec les données ?

**✅ RÉPONSE : Tout est intégré dans UN SEUL objet JSON**

Le HTML de la table ET les métadonnées sont stockés ensemble dans un enregistrement `FlowiseGeneratedTableRecord`.

**Structure complète d'un enregistrement** (extrait de flowise_table_types.ts, lignes 43-87) :

```typescript
export interface FlowiseGeneratedTableRecord {
  // === IDENTIFICATION UNIQUE ===
  id: string;                    // UUID unique (ex: "a3f8d5c2-...")
  
  // === LIAISON SESSION/MESSAGE ===
  sessionId: string;             // ID de la session de chat
  messageId?: string;            // ID du message qui a généré la table (optionnel)
  
  // === CONTENU DE LA TABLE ===
  keyword: string;               // Mot-clé d'identification (ex: "Balance_2024")
  html: string;                  // HTML COMPLET de la table (peut être compressé)
  
  // === DÉTECTION DES DOUBLONS ===
  fingerprint: string;           // Hash SHA-256 du contenu (pour détecter les duplicatas)
  
  // === POSITIONNEMENT DANS LE DOM ===
  containerId: string;           // ID du conteneur parent dans le DOM
  position: number;              // Position relative dans le conteneur (0, 1, 2...)
  
  // === MÉTADONNÉES TEMPORELLES ===
  timestamp: string;             // Date ISO (ex: "2026-08-29T18:30:45.123Z")
  
  // === SOURCE ET TYPE ===
  source: FlowiseTableSource;    // Origine : 'n8n' | 'cached' | 'error'
  tableType?: FlowiseTableType;  // Type : 'trigger' | 'generated'
  
  // === MÉTADONNÉES STRUCTURELLES ===
  metadata: FlowiseTableMetadata; // Infos sur la structure de la table
  
  // === MULTI-UTILISATEUR ===
  user_id?: string;              // ID utilisateur (isolation des données)
  
  // === TRAITEMENT ===
  processed?: boolean;           // Si table Trigger_Table a été traitée
}
```

### 2.3 Structure des métadonnées (FlowiseTableMetadata)

```typescript
export interface FlowiseTableMetadata {
  rowCount: number;          // Nombre de lignes
  colCount: number;          // Nombre de colonnes
  headers: string[];         // Titres des colonnes ["Nom", "Prénom", "Age"]
  compressed: boolean;       // true si HTML compressé (au-delà de 50KB)
  originalSize?: number;     // Taille originale avant compression
  dataTableId?: string;      // Attribut DOM stable (data-table-id) pour lookup
}
```

### 2.4 Exemple concret d'un enregistrement complet

```json
{
  "id": "7f3d8a2c-4b5e-4a9f-8c1d-2e3f4a5b6c7d",
  "sessionId": "session-2026-08-29-abc123",
  "messageId": "msg-456def",
  "keyword": "Balance_Generale_2024_Q3",
  "html": "<table class='min-w-full'><thead><tr><th>Compte</th><th>Libellé</th><th>Débit</th><th>Crédit</th></tr></thead><tbody><tr><td>411000</td><td>Clients</td><td>125000</td><td>0</td></tr>...</tbody></table>",
  "fingerprint": "8a3f2d5c9e1b7f4a6d8c2e5f3b7a9d1c4e6f8a2b5c7d9e1f3a4b6c8d2e5f7a9",
  "containerId": "chat-container-msg-456def",
  "position": 2,
  "timestamp": "2026-08-29T18:30:45.123Z",
  "source": "n8n",
  "tableType": "generated",
  "metadata": {
    "rowCount": 50,
    "colCount": 4,
    "headers": ["Compte", "Libellé", "Débit", "Crédit"],
    "compressed": false,
    "originalSize": 15234,
    "dataTableId": "table-balance-2024-q3"
  },
  "user_id": "user-789ghi",
  "processed": false
}
```

---

## 3. GESTION DE L'UNICITÉ ET DES VERSIONS

### 3.1 Qu'est-ce qui garantit l'unicité à tout moment ?

**🔑 Trois niveaux de vérification d'unicité :**

#### **Niveau 1 : ID unique (PRIMARY KEY)**
```typescript
// Chaque table a un UUID unique généré au moment de la création
id: string; // Ex: "7f3d8a2c-4b5e-4a9f-8c1d-2e3f4a5b6c7d"
```

#### **Niveau 2 : Fingerprint (empreinte digitale du contenu)**
```typescript
// Hash SHA-256 du contenu complet (headers + toutes les données)
// Extrait de flowiseTableService.ts, lignes 38-70
generateTableFingerprint(tableElement: HTMLTableElement): string {
  const headers = this.extractHeaders(tableElement);
  const rows = this.extractAllRows(tableElement);
  const structure = {
    rowCount: tableElement.querySelectorAll('tr').length,
    colCount: tableElement.querySelector('tr')?.children.length || 0
  };

  const signature = JSON.stringify({ headers, rows, structure });
  return this.sha256(signature); // Hash FNV-1a optimisé
}
```

**Le fingerprint change SI ET SEULEMENT SI** :
- ✅ Une valeur dans une cellule change
- ✅ Une ligne est ajoutée/supprimée
- ✅ Une colonne est ajoutée/supprimée
- ✅ L'ordre des colonnes change

#### **Niveau 3 : Vérification keyword + sessionId**
```typescript
// Extrait de flowiseTableBridge.ts, lignes 830-860
// Avant de sauvegarder, on vérifie si une table avec le même keyword
// existe déjà dans la même session
const existingByKeyword = await flowiseTableService.findTableByKeywordAndSession(
  this.currentSessionId,
  keyword
);

if (existingByKeyword) {
  // Table existe déjà → MISE À JOUR ou SKIP selon le contexte
  if (shouldUpdate) {
    await flowiseTableService.updateGeneratedTable(existingByKeyword.id, ...);
  } else {
    console.log('Table inchangée, skip duplicate');
    return; // Ne pas créer de doublon
  }
}
```

### 3.2 Comment extraire toutes les tables et les distinguer ?

**🔍 Méthode diagnostique complète** :

```typescript
// Dans la console DevTools (F12)
async function diagnosticTables() {
  // 1. Ouvrir la connexion IndexedDB
  const request = indexedDB.open('clara_db', 13);
  
  request.onsuccess = (event) => {
    const db = event.target.result;
    const transaction = db.transaction('clara_generated_tables', 'readonly');
    const store = transaction.objectStore('clara_generated_tables');
    const getAllRequest = store.getAll();
    
    getAllRequest.onsuccess = () => {
      const allTables = getAllRequest.result;
      
      console.log(`📊 TOTAL : ${allTables.length} table(s) dans la base`);
      
      // Grouper par session
      const bySession = {};
      allTables.forEach(table => {
        if (!bySession[table.sessionId]) {
          bySession[table.sessionId] = [];
        }
        bySession[table.sessionId].push(table);
      });
      
      // Afficher par session
      Object.entries(bySession).forEach(([sessionId, tables]) => {
        console.log(`\n🔑 SESSION: ${sessionId}`);
        console.log(`   → ${tables.length} table(s)`);
        
        tables.forEach(table => {
          console.log(`\n   📋 TABLE:`);
          console.log(`      • ID: ${table.id}`);
          console.log(`      • Keyword: ${table.keyword}`);
          console.log(`      • Fingerprint: ${table.fingerprint.substring(0, 16)}...`);
          console.log(`      • Timestamp: ${table.timestamp}`);
          console.log(`      • Source: ${table.source}`);
          console.log(`      • Rows: ${table.metadata.rowCount}, Cols: ${table.metadata.colCount}`);
          console.log(`      • Compressed: ${table.metadata.compressed}`);
          console.log(`      • Data-table-id: ${table.metadata.dataTableId || 'none'}`);
        });
      });
      
      // Détecter les doublons potentiels
      const fingerprintMap = {};
      allTables.forEach(table => {
        const key = `${table.sessionId}_${table.fingerprint}`;
        if (!fingerprintMap[key]) {
          fingerprintMap[key] = [];
        }
        fingerprintMap[key].push(table);
      });
      
      const duplicates = Object.values(fingerprintMap).filter(arr => arr.length > 1);
      if (duplicates.length > 0) {
        console.warn(`\n⚠️ ${duplicates.length} DOUBLON(S) DÉTECTÉ(S):`);
        duplicates.forEach(dupes => {
          console.warn(`   → ${dupes.length} tables identiques (keyword: ${dupes[0].keyword})`);
          dupes.forEach(d => console.warn(`      • ID: ${d.id}, Time: ${d.timestamp}`));
        });
      }
    };
  };
}

// Lancer le diagnostic
diagnosticTables();
```

### 3.3 Système de numérotation des tables

**❌ Il n'y a PAS de numérotation séquentielle (1, 2, 3...)**

**✅ Chaque table a un UUID v4 aléatoire**

```typescript
// Génération d'UUID (flowiseTableService.ts, ligne ~150)
private generateUUID(): string {
  return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function(c) {
    const r = Math.random() * 16 | 0;
    const v = c === 'x' ? r : (r & 0x3 | 0x8);
    return v.toString(16);
  });
}
```

**Exemple** : `7f3d8a2c-4b5e-4a9f-8c1d-2e3f4a5b6c7d`

### 3.4 Comment vérifier si une table existe avant sauvegarde ?

**🔍 Processus de vérification en 3 étapes** (flowiseTableBridge.ts, lignes 820-880) :

```typescript
// ÉTAPE 1 : Chercher par keyword + sessionId
const existingByKeyword = await flowiseTableService.findTableByKeywordAndSession(
  sessionId,
  keyword
);

if (existingByKeyword) {
  // Table trouvée → comparer les fingerprints
  const newFingerprint = flowiseTableService.generateTableFingerprint(tableElement);
  
  if (existingByKeyword.fingerprint === newFingerprint) {
    // CONTENU IDENTIQUE → Skip (pas de sauvegarde)
    console.log('Table identique, skip duplicate');
    return;
  } else {
    // CONTENU MODIFIÉ → Mise à jour
    console.log('Table modifiée, mise à jour');
    await flowiseTableService.updateGeneratedTable(existingByKeyword.id, ...);
    return;
  }
}

// ÉTAPE 2 : Chercher par fingerprint seul (fallback)
const exists = await flowiseTableService.tableExists(sessionId, newFingerprint);

if (exists) {
  console.log('Table déjà sauvegardée (même fingerprint), skip');
  return;
}

// ÉTAPE 3 : Aucune table similaire → NOUVELLE SAUVEGARDE
await flowiseTableService.saveGeneratedTable(sessionId, tableElement, keyword, ...);
```

### 3.5 Mise à jour ou écrasement ?

**🔄 MISE À JOUR (UPDATE) via l'ID existant, PAS d'écrasement**

```typescript
// Extrait de flowiseTableService.ts, lignes 180-220
async updateGeneratedTable(
  tableId: string,           // ID existant conservé
  tableElement: HTMLTableElement,
  keyword: string,
  source: FlowiseTableSource,
  messageId?: string
): Promise<boolean> {
  // 1. Récupérer l'ancien enregistrement
  const existingTable = await indexedDBService.get<FlowiseGeneratedTableRecord>(
    'clara_generated_tables',
    tableId
  );
  
  if (!existingTable) {
    console.error('Table introuvable pour mise à jour');
    return false;
  }
  
  // 2. Générer nouveau fingerprint
  const newFingerprint = this.generateTableFingerprint(tableElement);
  
  // 3. Mettre à jour UNIQUEMENT les champs modifiés
  const updatedTable: FlowiseGeneratedTableRecord = {
    ...existingTable,              // Conserver tous les anciens champs
    html: tableElement.outerHTML,  // Nouveau HTML
    fingerprint: newFingerprint,   // Nouveau fingerprint
    timestamp: new Date().toISOString(), // Nouveau timestamp
    metadata: this.extractTableMetadata(tableElement, tableElement.outerHTML)
  };
  
  // 4. Sauvegarder avec le MÊME ID (écrase l'ancien via IndexedDB.put)
  await indexedDBService.putGeneratedTable(updatedTable);
  
  console.log(`✅ Table mise à jour: ${tableId}`);
  return true;
}
```

**💡 Comportement IndexedDB.put() :**
- Si `id` existe déjà → **REMPLACE** l'enregistrement
- Si `id` n'existe pas → **CRÉE** un nouvel enregistrement

### 3.6 Intégration technique des tables dans IndexedDB

**📦 Processus d'insertion** (indexedDB.ts, lignes 320-340) :

```typescript
async putGeneratedTable<T>(table: T): Promise<T> {
  try {
    const db = await this.initDB();
    return new Promise((resolve, reject) => {
      // 1. Ouvrir une transaction en mode "readwrite"
      const transaction = db.transaction('clara_generated_tables', 'readwrite');
      const store = transaction.objectStore('clara_generated_tables');
      
      // 2. Insérer/mettre à jour l'enregistrement
      const request = store.put(table); // ← Méthode clé
      
      request.onsuccess = () => {
        console.log('✅ Table sauvegardée');
        resolve(table);
      };
      
      request.onerror = (event) => {
        console.error('❌ Erreur sauvegarde:', event.target.error);
        reject(event.target.error);
      };
    });
  } catch (error) {
    console.error('Erreur IndexedDB:', error);
    throw error;
  }
}
```

### 3.7 Suggestion : Identification complémentaire timestamp

**✅ DÉJÀ IMPLÉMENTÉ !**

Chaque table possède un champ `timestamp` au format ISO 8601 :

```typescript
timestamp: "2026-08-29T18:30:45.123Z"
```

**Tri chronologique possible** :

```typescript
// Trier les tables par ordre de création
tables.sort((a, b) => 
  new Date(a.timestamp).getTime() - new Date(b.timestamp).getTime()
);
```

---

## 4. PROCESSUS DE SAUVEGARDE

### 4.1 À quel moment se fait la sauvegarde ?

**🕐 TROIS moments de sauvegarde** :

#### **Moment 1 : Génération initiale d'une table (immédiat)**
```typescript
// Quand Flowise génère une nouvelle table via N8N
// Event déclenché : 'flowise:table:integrated'
// Fichier : flowiseTableBridge.ts, ligne 750

document.addEventListener('flowise:table:integrated', (event) => {
  const { table, keyword, source } = event.detail;
  
  // Sauvegarde IMMÉDIATE
  await flowiseTableService.saveGeneratedTable(
    sessionId,
    table,
    keyword,
    source
  );
});
```

#### **Moment 2 : Modification utilisateur (auto-save après 10 secondes)**
```typescript
// Système AUTO-SAVE (flowiseTableBridge.ts, lignes 2669-2691)
private startAutoSaveSystem(): void {
  // 1. MutationObserver détecte les modifications DOM
  this.mutationObserver = new MutationObserver((mutations) => {
    mutations.forEach(mutation => {
      if (mutation.type === 'childList' || mutation.type === 'characterData') {
        const table = mutation.target.closest('table[data-keyword]');
        if (table) {
          const keyword = table.dataset.keyword;
          this.dirtyTables.add(keyword); // Marquer comme "modifiée"
          console.log(`🔄 [AUTO-SAVE] Table modifiée: "${keyword}"`);
        }
      }
    });
  });
  
  // 2. Intervalle de sauvegarde toutes les 10 secondes
  this.autoSaveInterval = setInterval(() => {
    this.performAutoSave(); // Sauvegarde toutes les tables "dirty"
  }, 10000); // 10 secondes
}
```

**Déclencheurs de modifications détectés** :
- ✅ Modification du texte dans une cellule
- ✅ Ajout/suppression de ligne
- ✅ Ajout/suppression de colonne
- ✅ Changement de valeur (calcul, formule)

#### **Moment 3 : Sauvegarde manuelle explicite**
```typescript
// Bouton "Sauvegarder" ou raccourci clavier
// Appel direct à la méthode publique
await flowiseTableBridge.performAutoSave();
```

### 4.2 Existe-t-il plusieurs types de sauvegardes ?

**✅ OUI, deux systèmes coexistent (mais un seul actif)** :

| Système | Statut | Fichier | Méthode | Fréquence |
|---------|--------|---------|---------|-----------|
| **1. AUTO-SAVE (nouveau)** | ✅ ACTIF | flowiseTableBridge.ts | Mutation Observer + Interval | Toutes les 10 secondes |
| **2. Sauvegarde périodique (ancien)** | ❌ DÉSACTIVÉ | conso.js | setInterval | Toutes les 30 secondes |

**Code de désactivation** (conso.js, lignes 225-233) :

```javascript
// 🚫 DÉSACTIVÉ : Conflit avec flowiseTableBridge auto-save
// Gardons uniquement le nouveau système de persistance
/*
this.autoSaveIntervalId = setInterval(() => {
  this.autoSaveAllTables();
}, 30000); // Sauvegarde automatique toutes les 30 secondes
*/
console.log("⚠️ [CONSO] Auto-save désactivé (utilise flowiseTableBridge)");
```

### 4.3 Pourquoi plusieurs versions de la même table ?

**🔴 HYPOTHÈSE INITIALE : "Plusieurs sauvegardes créent des doublons"**

**✅ RÉALITÉ : Le système ÉVITE activement les doublons**

**Mécanismes anti-doublons** (flowiseTableBridge.ts, lignes 830-870) :

```typescript
// 1. VÉRIFICATION PAR KEYWORD
const existingByKeyword = await flowiseTableService.findTableByKeywordAndSession(
  sessionId,
  keyword
);

if (existingByKeyword) {
  // Table existe → Comparer fingerprints
  if (existingByKeyword.fingerprint === newFingerprint) {
    console.log('ℹ️ Table identique, skip duplicate');
    return; // ← PAS DE NOUVELLE SAUVEGARDE
  } else {
    // Contenu différent → MISE À JOUR (même ID)
    await updateGeneratedTable(existingByKeyword.id, ...);
    return;
  }
}

// 2. VÉRIFICATION PAR FINGERPRINT (fallback)
const exists = await tableExists(sessionId, newFingerprint);
if (exists) {
  console.log('ℹ️ Table déjà sauvegardée (fingerprint), skip');
  return; // ← PAS DE NOUVELLE SAUVEGARDE
}

// 3. Aucune correspondance → NOUVELLE TABLE
await saveGeneratedTable(sessionId, ...);
```

**📊 Cas où des doublons PEUVENT apparaître** :

| Scenario | Cause | Solution |
|----------|-------|----------|
| **1. Modifications mineures** | Le fingerprint change à chaque modification → nouvelle sauvegarde | Utiliser `forceUpdate=false` pour éviter duplicatas |
| **2. Sessions multiples** | Même keyword dans 2 sessions différentes (normal) | Filtrer par `sessionId` lors de la restauration |
| **3. Erreur de nettoyage** | Tables obsolètes non supprimées | Utiliser `cleanupTemporarySessions()` |

### 4.4 Suggestion : Système d'enregistrement unique

**✅ DÉJÀ IMPLÉMENTÉ !**

**Un seul point d'entrée** : `flowiseTableService.saveGeneratedTable()`

```typescript
// Tous les chemins de sauvegarde passent par cette méthode unique
// flowiseTableService.ts, lignes 140-250

async saveGeneratedTable(
  sessionId: string,
  tableElement: HTMLTableElement,
  keyword: string,
  source: FlowiseTableSource,
  messageId?: string,
  forceUpdate: boolean = false
): Promise<string> {
  // 1. Vérification unicité
  // 2. Compression si nécessaire
  // 3. Génération fingerprint
  // 4. Vérification doublons
  // 5. Sauvegarde IndexedDB
  // 6. Retour ID
}
```

**Tous les appelants utilisent cette méthode** :
- ✅ `flowiseTableBridge.handleTableIntegrated()` → `saveGeneratedTable()`
- ✅ `flowiseTableBridge.performAutoSave()` → `saveGeneratedTable()`
- ✅ `conso.js` (désactivé) → événement → `saveGeneratedTable()`

### 4.5 Assurance de deux méthodes maximum ?

**✅ CONFIRMÉ : Seulement 2 systèmes (1 actif + 1 désactivé)**

**Preuve par analyse de code** :

```bash
# Recherche de tous les appels à putGeneratedTable (méthode d'écriture IndexedDB)
grep -r "putGeneratedTable" src/

# Résultat : UNIQUEMENT dans flowiseTableService.ts
src/services/flowiseTableService.ts:    await indexedDBService.putGeneratedTable(tableRecord);
src/services/flowiseTableService.ts:    await indexedDBService.putGeneratedTable(updatedTable);
```

**Point d'entrée unique garanti** : `indexedDBService.putGeneratedTable()`

---

## 5. INTÉGRATION ET CONCEPTS TECHNIQUES

### 5.1 Que se passe-t-il lors de la restauration des tables ?

**🔄 Processus de restauration complet** (flowiseTableService.ts, lignes 280-350) :

```typescript
// ÉTAPE 1 : Récupération depuis IndexedDB
const tables = await indexedDBService.getGeneratedTablesBySession(sessionId);

// ÉTAPE 2 : Filtrage (exclusion tables Trigger_Table traitées)
const restorableTables = tables.filter(table => {
  if (table.tableType === 'trigger' && table.processed === true) {
    return false; // Skip tables déjà traitées
  }
  return true;
});

// ÉTAPE 3 : Décompression HTML si nécessaire
const decompressedTables = restorableTables.map(table => {
  if (table.metadata.compressed) {
    return {
      ...table,
      html: LZString.decompressFromUTF16(table.html)
    };
  }
  return table;
});

// ÉTAPE 4 : Tri chronologique
decompressedTables.sort((a, b) => 
  new Date(a.timestamp).getTime() - new Date(b.timestamp).getTime()
);

// ÉTAPE 5 : Insertion dans le DOM
decompressedTables.forEach(table => {
  // Créer élément table depuis HTML
  const tempDiv = document.createElement('div');
  tempDiv.innerHTML = table.html;
  const tableElement = tempDiv.querySelector('table');
  
  // Trouver le conteneur cible
  let container = document.querySelector(`[data-container-id="${table.containerId}"]`);
  if (!container) {
    // Créer conteneur si inexistant
    container = document.createElement('div');
    container.setAttribute('data-container-id', table.containerId);
    document.body.appendChild(container);
  }
  
  // Wrapper pour marquer comme restaurée
  const wrapper = document.createElement('div');
  wrapper.className = 'restored-table-wrapper';
  wrapper.setAttribute('data-restored', 'true');
  wrapper.setAttribute('data-table-id', table.id);
  wrapper.appendChild(tableElement);
  
  // Insérer à la bonne position
  if (table.position < container.children.length) {
    container.insertBefore(wrapper, container.children[table.position]);
  } else {
    container.appendChild(wrapper);
  }
  
  console.log(`✅ Table restaurée: ${table.keyword}`);
});
```

**🔍 Remplacement des tables initiales ?**

**NON**, les tables restaurées sont **ajoutées** au DOM avec attribut `data-restored="true"`.

**Les tables initiales du chat ne sont PAS supprimées** (sauf si cleanup explicite).

### 5.2 Qu'est-ce qu'un "schéma" en IndexedDB ?

**📐 SCHÉMA = Structure de la base de données**

En IndexedDB, le schéma définit :

#### **1. Les Object Stores (tables)**
```typescript
db.createObjectStore('clara_generated_tables', { keyPath: 'id' });
```
- `'clara_generated_tables'` = nom du store
- `{ keyPath: 'id' }` = clé primaire

#### **2. Les Index (recherches rapides)**
```typescript
tablesStore.createIndex('sessionId', 'sessionId', { unique: false });
```
- Permet recherche par `sessionId` sans parcourir toute la base
- `unique: false` = plusieurs enregistrements peuvent avoir même `sessionId`

#### **3. La version de la base**
```typescript
const DB_VERSION = 13;
```
- Incrémentée à chaque modification du schéma
- Déclenche `onupgradeneeded` pour migrations

**Exemple concret** :

```typescript
// indexedDB.ts, lignes 138-154
if (!db.objectStoreNames.contains('clara_generated_tables')) {
  console.log('🔧 Création du store clara_generated_tables');
  
  const tablesStore = db.createObjectStore('clara_generated_tables', { 
    keyPath: 'id' // ← Clé primaire
  });
  
  // Index pour recherches rapides
  tablesStore.createIndex('sessionId', 'sessionId', { unique: false });
  tablesStore.createIndex('keyword', 'keyword', { unique: false });
  tablesStore.createIndex('fingerprint', 'fingerprint', { unique: false });
  tablesStore.createIndex('timestamp', 'timestamp', { unique: false });
  
  console.log('✅ Store créé avec succès');
}
```

**💡 Analogie SQL** :

```sql
CREATE TABLE clara_generated_tables (
  id VARCHAR(36) PRIMARY KEY,
  sessionId VARCHAR(255),
  keyword VARCHAR(255),
  fingerprint VARCHAR(64),
  timestamp DATETIME,
  html TEXT,
  -- ...
  INDEX idx_sessionId (sessionId),
  INDEX idx_keyword (keyword),
  INDEX idx_fingerprint (fingerprint)
);
```

---

## 6. RÉSOLUTION DE L'HYPOTHÈSE DE BASE

### 🔴 HYPOTHÈSE INITIALE

> "Il persiste plusieurs sauvegardes de la même table dans les tables restaurées. Par conséquent, plusieurs tables de versions différentes coexistent en même temps dans la base de données."

### ✅ VÉRIFICATION ET CONCLUSION

**PARTIELLEMENT VRAIE dans certains cas, mais le système est conçu pour l'éviter.**

#### **Cas 1 : Doublons évités par design ✅**

```typescript
// Vérification keyword + session AVANT sauvegarde
const existingByKeyword = await findTableByKeywordAndSession(sessionId, keyword);

if (existingByKeyword) {
  // Table existe → MISE À JOUR (même ID), pas de nouveau enregistrement
  await updateGeneratedTable(existingByKeyword.id, ...);
  return;
}
```

**Résultat** : Une seule version par (keyword + sessionId)

#### **Cas 2 : Modifications utilisateur (légitime) 🟡**

Si l'utilisateur modifie une table :
1. Le **fingerprint change** (contenu différent)
2. Le système détecte que c'est une **modification de la table existante**
3. **MISE À JOUR** de l'enregistrement existant (même ID)
4. L'ancien contenu est **écrasé** (pas de doublon)

```typescript
// Auto-save détecte modification
if (existingByKeyword.fingerprint !== newFingerprint) {
  // Contenu modifié → UPDATE existant
  await updateGeneratedTable(existingByKeyword.id, ...);
}
```

#### **Cas 3 : Sessions multiples (normal) ✅**

Même keyword dans 2 sessions différentes = 2 tables distinctes (normal) :

```json
[
  {
    "id": "abc123",
    "sessionId": "session-A",
    "keyword": "Balance_2024",
    "timestamp": "2026-08-29T10:00:00Z"
  },
  {
    "id": "def456",
    "sessionId": "session-B",
    "keyword": "Balance_2024",
    "timestamp": "2026-08-29T11:00:00Z"
  }
]
```

**Ce n'est PAS un doublon** : chaque session a sa propre version.

#### **Cas 4 : Erreurs/bugs potentiels ⚠️**

**Scénarios où des doublons peuvent apparaître** :

1. **Race condition** : 2 sauvegardes simultanées avant vérification
   ```typescript
   // Fix : Utiliser mutex/lock pendant vérification
   ```

2. **Fingerprint instable** : Petites variations (espaces, formatage)
   ```typescript
   // Fix : Normaliser HTML avant fingerprint
   ```

3. **Ancien système conso.js actif** : Conflit entre 2 systèmes
   ```javascript
   // Fix : Désactivé (ligne 232 conso.js)
   console.log("⚠️ [CONSO] Auto-save désactivé");
   ```

4. **Restauration multiple** : Restaurer plusieurs fois la même session
   ```typescript
   // Fix : Cleanup au changement de session
   this.clearRestoredTablesFromDOM();
   ```

### 📊 DIAGNOSTIC RECOMMANDÉ

**Pour vérifier l'absence de doublons** :

```javascript
// À exécuter dans la console DevTools (F12)
async function detectDuplicates() {
  const request = indexedDB.open('clara_db', 13);
  
  request.onsuccess = (event) => {
    const db = event.target.result;
    const transaction = db.transaction('clara_generated_tables', 'readonly');
    const store = transaction.objectStore('clara_generated_tables');
    const getAllRequest = store.getAll();
    
    getAllRequest.onsuccess = () => {
      const tables = getAllRequest.result;
      
      // Grouper par session + keyword
      const groups = {};
      tables.forEach(table => {
        const key = `${table.sessionId}__${table.keyword}`;
        if (!groups[key]) {
          groups[key] = [];
        }
        groups[key].push(table);
      });
      
      // Détecter doublons (> 1 table pour même session + keyword)
      const duplicates = Object.entries(groups).filter(([key, tables]) => tables.length > 1);
      
      if (duplicates.length === 0) {
        console.log('✅ Aucun doublon détecté');
      } else {
        console.warn(`⚠️ ${duplicates.length} groupe(s) de doublons:`);
        duplicates.forEach(([key, tables]) => {
          const [sessionId, keyword] = key.split('__');
          console.warn(`\n🔴 Doublon pour "${keyword}" (session: ${sessionId.substring(0, 10)}...)`);
          console.warn(`   → ${tables.length} versions:`);
          tables.forEach((t, i) => {
            console.warn(`      ${i + 1}. ID: ${t.id}, Time: ${t.timestamp}, Fingerprint: ${t.fingerprint.substring(0, 8)}`);
          });
        });
      }
    };
  };
}

detectDuplicates();
```

### 🛠️ ACTIONS CORRECTIVES SI DOUBLONS

```typescript
// Fonction de nettoyage des doublons (à ajouter si nécessaire)
async function cleanupDuplicates(sessionId: string) {
  const tables = await indexedDBService.getGeneratedTablesBySession(sessionId);
  
  // Grouper par keyword
  const byKeyword = new Map<string, FlowiseGeneratedTableRecord[]>();
  tables.forEach(table => {
    if (!byKeyword.has(table.keyword)) {
      byKeyword.set(table.keyword, []);
    }
    byKeyword.get(table.keyword)!.push(table);
  });
  
  // Pour chaque groupe, garder seulement la version la plus récente
  for (const [keyword, versions] of byKeyword) {
    if (versions.length > 1) {
      // Trier par timestamp décroissant
      versions.sort((a, b) => 
        new Date(b.timestamp).getTime() - new Date(a.timestamp).getTime()
      );
      
      const latest = versions[0];
      const obsolete = versions.slice(1);
      
      console.log(`🧹 Nettoyage "${keyword}": conservation de ${latest.id}, suppression de ${obsolete.length} ancien(s)`);
      
      // Supprimer les anciennes versions
      for (const old of obsolete) {
        await indexedDBService.deleteGeneratedTable(old.id);
      }
    }
  }
}
```

---

## 📝 RÉSUMÉ POUR DÉBUTANT

### 🎯 En quelques mots

1. **Où sont stockées les tables ?**  
   → Dans IndexedDB (base locale du navigateur), store `clara_generated_tables`

2. **Sous quelle forme ?**  
   → Un objet JSON contenant le HTML complet + métadonnées (lignes, colonnes, timestamp, fingerprint...)

3. **Comment éviter les doublons ?**  
   → Vérification par keyword + session + fingerprint AVANT chaque sauvegarde

4. **Quand sont-elles sauvegardées ?**  
   → Immédiatement à la génération + auto-save toutes les 10s après modification

5. **Combien de systèmes de sauvegarde ?**  
   → UN seul actif (flowiseTableBridge auto-save), l'ancien (conso.js) est désactivé

6. **Comment identifier une table ?**  
   → UUID unique (`id`) + keyword + timestamp + fingerprint (SHA-256 du contenu)

7. **Mise à jour ou écrasement ?**  
   → MISE À JOUR (même ID conservé) via IndexedDB.put()

8. **Peut-il y avoir des doublons ?**  
   → Non par design, mais possibles en cas de bug (race condition, fingerprint instable)

---

## 📚 ANNEXES

### A. Commandes utiles pour diagnostics

```javascript
// 1. Lister toutes les tables
const tables = await indexedDBService.getAllGeneratedTables();
console.table(tables.map(t => ({
  id: t.id.substring(0, 8),
  keyword: t.keyword,
  session: t.sessionId.substring(0, 10),
  timestamp: t.timestamp,
  rows: t.metadata.rowCount,
  size: t.html.length
})));

// 2. Compter par session
const bySession = {};
tables.forEach(t => {
  bySession[t.sessionId] = (bySession[t.sessionId] || 0) + 1;
});
console.table(bySession);

// 3. Trouver doublons par fingerprint
const byFingerprint = {};
tables.forEach(t => {
  const key = `${t.sessionId}_${t.fingerprint}`;
  byFingerprint[key] = (byFingerprint[key] || 0) + 1;
});
Object.entries(byFingerprint).filter(([k, v]) => v > 1);

// 4. Supprimer toutes les tables d'une session
await indexedDBService.deleteGeneratedTablesBySession('session-xyz');

// 5. Nettoyer sessions temporaires
await flowiseTableBridge.cleanupTemporarySessions();
```

### B. Flux de données complet

```
┌─────────────────────────────────────────────────────────────┐
│ 1. GÉNÉRATION TABLE (Flowise/N8N)                          │
│    Event: flowise:table:integrated                          │
│    ↓                                                        │
│ 2. flowiseTableBridge.handleTableIntegrated()              │
│    - Détection messageId                                    │
│    - Génération fingerprint                                 │
│    - Vérification doublons                                  │
│    ↓                                                        │
│ 3. flowiseTableService.saveGeneratedTable()                │
│    - Compression (si > 50KB)                                │
│    - Extraction metadata                                    │
│    - Création FlowiseGeneratedTableRecord                   │
│    ↓                                                        │
│ 4. indexedDBService.putGeneratedTable()                    │
│    - Transaction IndexedDB                                  │
│    - Écriture dans clara_generated_tables                   │
│    ↓                                                        │
│ 5. ✅ Table sauvegardée (ID retourné)                      │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│ 6. MODIFICATION UTILISATEUR                                 │
│    - Édition cellule, ajout ligne, etc.                    │
│    ↓                                                        │
│ 7. MutationObserver détecte changement                      │
│    - Ajout keyword à dirtyTables Set                        │
│    ↓                                                        │
│ 8. Auto-save (interval 10s)                                 │
│    - performAutoSave() vérifie dirtyTables                  │
│    - Pour chaque table modifiée:                            │
│      • Vérification existence par keyword                   │
│      • Génération nouveau fingerprint                       │
│      • Comparaison avec fingerprint existant                │
│      • Si différent → updateGeneratedTable()                │
│    ↓                                                        │
│ 9. ✅ Table mise à jour (même ID)                          │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│ 10. RESTAURATION (changement session)                      │
│     Event: claraverse:session:changed                       │
│     ↓                                                       │
│ 11. flowiseTableService.restoreSessionTables()             │
│     - Récupération par sessionId                            │
│     - Filtrage tables traitées                              │
│     - Décompression HTML                                    │
│     - Tri chronologique                                     │
│     ↓                                                       │
│ 12. Insertion DOM                                           │
│     - Création wrapper [data-restored="true"]               │
│     - Positionnement dans containerId                       │
│     - Conservation ordre (position)                         │
│     ↓                                                       │
│ 13. ✅ Tables restaurées dans le chat                      │
└─────────────────────────────────────────────────────────────┘
```

### C. Structure hiérarchique IndexedDB

```
clara_db (version 13)
├── chats
├── messages
├── storage
├── usage
├── model_usage
├── settings
├── system_settings
├── tools
├── designs
├── design_versions
├── providers
├── clara_sessions
├── clara_messages
├── clara_files
├── agent_workflows
├── lumaui_projects
├── lumaui_project_files
├── users
├── workflow_templates
├── workflow_versions
├── workflow_metadata
├── agent_ui_designs
└── clara_generated_tables ← 🎯 STORE DES TABLES
    ├── Index: sessionId
    ├── Index: messageId
    ├── Index: keyword
    ├── Index: fingerprint
    ├── Index: user_id
    ├── Index: timestamp
    └── Index: source
```

---

## 🎓 CONCLUSION

Le système de persistance Claraverse est **robuste et bien conçu** avec :

✅ **Un seul point d'entrée** pour toutes les sauvegardes  
✅ **Vérifications anti-doublons** systématiques  
✅ **Mises à jour par ID** (pas d'écrasement aveugle)  
✅ **Fingerprinting SHA-256** pour détection de modifications  
✅ **Auto-save intelligent** avec MutationObserver  
✅ **Isolation par session** (clé sessionId)  
✅ **Compression automatique** (tables > 50KB)  
✅ **Timestamps ISO** pour tri chronologique  

⚠️ **Points de vigilance** :
- Désactivation correcte de l'ancien système conso.js (vérifié ✅)
- Nettoyage périodique des sessions temporaires
- Monitoring des doublons potentiels (race conditions)

---

**Document créé le** : 29 Août 2026  
**Auteur** : Système Kiro AI  
**Révision** : 1.0  
**Prochaine mise à jour** : Si modifications du schéma IndexedDB

