# SCHÉMAS VISUELS - SYSTÈME DE PERSISTANCE

**Compléments visuels au mémo principal**

---

## 📊 SCHÉMA 1 : STRUCTURE D'UN ENREGISTREMENT INDEXEDDB

```
┌────────────────────────────────────────────────────────────────┐
│  FlowiseGeneratedTableRecord                                   │
│  ID: 7f3d8a2c-4b5e-4a9f-8c1d-2e3f4a5b6c7d                     │
├────────────────────────────────────────────────────────────────┤
│  🔑 IDENTIFICATION                                             │
│  ├─ id: "7f3d8a2c-..." (UUID unique)                          │
│  ├─ sessionId: "session-2026-08-29-abc123"                    │
│  ├─ messageId: "msg-456def" (optionnel)                       │
│  └─ keyword: "Balance_Generale_2024_Q3"                       │
├────────────────────────────────────────────────────────────────┤
│  📄 CONTENU HTML (peut être compressé)                        │
│  html: "<table class='min-w-full'>                            │
│         <thead><tr><th>Compte</th><th>Libellé</th>            │
│         <th>Débit</th><th>Crédit</th></tr></thead>            │
│         <tbody>                                                │
│           <tr><td>411000</td><td>Clients</td>                 │
│               <td>125000</td><td>0</td></tr>                   │
│           <tr><td>401000</td><td>Fournisseurs</td>            │
│               <td>0</td><td>87500</td></tr>                    │
│           ... (48 autres lignes) ...                           │
│         </tbody></table>"                                      │
│                                                                │
│  Taille: 15,234 octets (15 KB)                                │
├────────────────────────────────────────────────────────────────┤
│  🔐 ANTI-DOUBLONS                                              │
│  fingerprint: "8a3f2d5c9e1b7f4a6d8c2e5f3b7a9d1c..."           │
│  (Hash SHA-256 de tout le contenu : headers + données)        │
├────────────────────────────────────────────────────────────────┤
│  📍 POSITIONNEMENT DOM                                         │
│  ├─ containerId: "chat-container-msg-456def"                  │
│  └─ position: 2 (3ème élément du conteneur)                   │
├────────────────────────────────────────────────────────────────┤
│  🕐 TRAÇABILITÉ                                                │
│  ├─ timestamp: "2026-08-29T18:30:45.123Z"                     │
│  ├─ source: "n8n" (ou "cached", "error")                      │
│  ├─ tableType: "generated"                                     │
│  └─ processed: false                                           │
├────────────────────────────────────────────────────────────────┤
│  📊 MÉTADONNÉES STRUCTURELLES                                  │
│  metadata: {                                                   │
│    rowCount: 50,                                               │
│    colCount: 4,                                                │
│    headers: ["Compte", "Libellé", "Débit", "Crédit"],        │
│    compressed: false,                                          │
│    originalSize: 15234,                                        │
│    dataTableId: "table-balance-2024-q3"                       │
│  }                                                             │
├────────────────────────────────────────────────────────────────┤
│  👤 MULTI-UTILISATEUR                                          │
│  user_id: "user-789ghi"                                        │
└────────────────────────────────────────────────────────────────┘
```

---

## 🔄 SCHÉMA 2 : CYCLE DE VIE D'UNE TABLE

```
┌──────────────────────────────────────────────────────────────────┐
│  PHASE 1 : CRÉATION INITIALE                                     │
├──────────────────────────────────────────────────────────────────┤
│                                                                  │
│  [Flowise/N8N génère HTML]                                      │
│           ↓                                                      │
│  Event: flowise:table:integrated                                │
│           ↓                                                      │
│  ┌─────────────────────────────────────┐                        │
│  │ flowiseTableBridge                  │                        │
│  │ ├─ Détecte messageId                │                        │
│  │ ├─ Génère fingerprint (SHA-256)     │                        │
│  │ └─ Vérifie doublons                 │                        │
│  └─────────────────────────────────────┘                        │
│           ↓                                                      │
│  ❓ Table existe déjà ?                                          │
│     ├─ OUI → SKIP ou UPDATE                                     │
│     └─ NON → NOUVELLE SAUVEGARDE                                │
│           ↓                                                      │
│  ┌─────────────────────────────────────┐                        │
│  │ flowiseTableService                 │                        │
│  │ ├─ Compression (si > 50KB)          │                        │
│  │ ├─ Extraction metadata              │                        │
│  │ └─ Création record complet          │                        │
│  └─────────────────────────────────────┘                        │
│           ↓                                                      │
│  ┌─────────────────────────────────────┐                        │
│  │ IndexedDB.put()                     │                        │
│  │ Store: clara_generated_tables       │                        │
│  └─────────────────────────────────────┘                        │
│           ↓                                                      │
│  ✅ Table sauvegardée (ID retourné)                             │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────────┐
│  PHASE 2 : MODIFICATIONS UTILISATEUR                             │
├──────────────────────────────────────────────────────────────────┤
│                                                                  │
│  [Utilisateur édite cellule]                                    │
│           ↓                                                      │
│  🔍 MutationObserver détecte                                     │
│     - type: 'childList' ou 'characterData'                      │
│     - target: table[data-keyword="Balance_2024"]                │
│           ↓                                                      │
│  ┌─────────────────────────────────────┐                        │
│  │ dirtyTables.add("Balance_2024")     │                        │
│  │ "Table marquée comme modifiée"      │                        │
│  └─────────────────────────────────────┘                        │
│           ↓                                                      │
│  ⏱️ Attente 10 secondes (interval)                              │
│           ↓                                                      │
│  ┌─────────────────────────────────────┐                        │
│  │ performAutoSave()                   │                        │
│  │ ├─ Pour chaque dirtyTable:          │                        │
│  │ │  ├─ Récupère table du DOM         │                        │
│  │ │  ├─ Génère nouveau fingerprint    │                        │
│  │ │  ├─ Compare avec ancien           │                        │
│  │ │  └─ Si différent → UPDATE         │                        │
│  │ └─ Nettoie dirtyTables              │                        │
│  └─────────────────────────────────────┘                        │
│           ↓                                                      │
│  ┌─────────────────────────────────────┐                        │
│  │ updateGeneratedTable(existingId)    │                        │
│  │ ├─ Conserve même ID ✅               │                        │
│  │ ├─ Nouveau HTML                     │                        │
│  │ ├─ Nouveau fingerprint              │                        │
│  │ └─ Nouveau timestamp                │                        │
│  └─────────────────────────────────────┘                        │
│           ↓                                                      │
│  ✅ Table mise à jour (ÉCRASE ancien contenu)                   │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────────┐
│  PHASE 3 : RESTAURATION                                          │
├──────────────────────────────────────────────────────────────────┤
│                                                                  │
│  [Utilisateur change de session]                                │
│           ↓                                                      │
│  Event: claraverse:session:changed                              │
│           ↓                                                      │
│  ┌─────────────────────────────────────┐                        │
│  │ restoreSessionTables(newSessionId)  │                        │
│  │ ├─ Query IndexedDB par sessionId    │                        │
│  │ ├─ Filtre tables traitées           │                        │
│  │ ├─ Décompresse HTML (si compressé)  │                        │
│  │ └─ Trie par timestamp               │                        │
│  └─────────────────────────────────────┘                        │
│           ↓                                                      │
│  📊 Liste des tables [50 tables]                                │
│           ↓                                                      │
│  ┌─────────────────────────────────────┐                        │
│  │ Pour chaque table:                  │                        │
│  │ ├─ Crée <div> wrapper               │                        │
│  │ ├─ Attribut data-restored="true"    │                        │
│  │ ├─ Insère dans containerId          │                        │
│  │ └─ Position correcte (0, 1, 2...)   │                        │
│  └─────────────────────────────────────┘                        │
│           ↓                                                      │
│  ✅ Tables affichées dans le chat                               │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘
```

---

## 🔍 SCHÉMA 3 : LOGIQUE ANTI-DOUBLONS

```
┌────────────────────────────────────────────────────────────────┐
│  NOUVELLE SAUVEGARDE DEMANDÉE                                  │
│  keyword: "Balance_2024"                                       │
│  sessionId: "session-abc123"                                   │
│  tableElement: <table>...</table>                              │
└────────────────────────────────────────────────────────────────┘
                          ↓
        ┌─────────────────────────────────────┐
        │ ÉTAPE 1 : Vérification par KEYWORD  │
        │ findTableByKeywordAndSession()      │
        └─────────────────────────────────────┘
                          ↓
                ┌─────────┴─────────┐
                │                   │
           ❌ AUCUNE           ✅ TROUVÉE
        (Passer Étape 2)    existing.id = "xyz789"
                │                   │
                │                   ↓
                │         ┌──────────────────────────┐
                │         │ Générer fingerprint      │
                │         │ newFP = sha256(contenu)  │
                │         └──────────────────────────┘
                │                   ↓
                │         ┌─────────┴──────────┐
                │         │                    │
                │   newFP == oldFP?     newFP != oldFP?
                │    (IDENTIQUE)        (MODIFIÉ)
                │         │                    │
                │         ↓                    ↓
                │   🛑 SKIP               🔄 UPDATE
                │   "Table inchangée"     updateGeneratedTable(
                │   return;                 existing.id,
                │                           newHTML,
                │                           newFingerprint,
                │                           newTimestamp
                │                         )
                │                           ↓
                │                     ✅ MÊME ID conservé
                │                     (Écrase ancien contenu)
                │
                ↓
        ┌─────────────────────────────────────┐
        │ ÉTAPE 2 : Vérification par          │
        │ FINGERPRINT seul (fallback)         │
        │ tableExists(sessionId, fingerprint) │
        └─────────────────────────────────────┘
                          ↓
                ┌─────────┴─────────┐
                │                   │
           ❌ NON TROUVÉ        ✅ TROUVÉ
                │            (Même fingerprint
                │             déjà sauvegardé)
                │                   │
                ↓                   ↓
        ┌───────────────┐    🛑 SKIP
        │ ÉTAPE 3 :     │    "Doublon détecté"
        │ NOUVELLE      │    return;
        │ SAUVEGARDE    │
        └───────────────┘
                ↓
    ┌──────────────────────────┐
    │ saveGeneratedTable()     │
    │ ├─ Nouveau UUID          │
    │ ├─ Nouveau record        │
    │ └─ IndexedDB.put()       │
    └──────────────────────────┘
                ↓
        ✅ NOUVELLE TABLE
        (ID unique généré)
```

---

## 🗂️ SCHÉMA 4 : ORGANISATION DES DONNÉES DANS INDEXEDDB

```
IndexedDB Browser Storage
│
└─ clara_db (v13)
   │
   ├─ clara_sessions (Store)
   │  ├─ Record: { id: "session-abc", title: "Chat 1", ... }
   │  ├─ Record: { id: "session-xyz", title: "Chat 2", ... }
   │  └─ ...
   │
   ├─ clara_messages (Store)
   │  ├─ Record: { id: "msg-123", sessionId: "session-abc", ... }
   │  ├─ Record: { id: "msg-456", sessionId: "session-abc", ... }
   │  └─ ...
   │
   └─ clara_generated_tables (Store) 🎯 NOTRE FOCUS
      │
      ├─ 🔑 PRIMARY KEY: id (UUID unique)
      │
      ├─ 📇 INDEX: sessionId (non-unique)
      │  ├─ "session-abc123" → [table1, table2, table5, ...]
      │  ├─ "session-xyz789" → [table3, table4, ...]
      │  └─ ...
      │
      ├─ 📇 INDEX: keyword (non-unique)
      │  ├─ "Balance_2024" → [table1, table8, table12]
      │  ├─ "Grand_Livre_Mars" → [table2, table9]
      │  └─ ...
      │
      ├─ 📇 INDEX: fingerprint (non-unique)
      │  ├─ "8a3f2d5c..." → [table1]
      │  ├─ "9b4e3f6d..." → [table2]
      │  └─ ...
      │
      ├─ 📇 INDEX: timestamp (non-unique)
      │  └─ Tri chronologique
      │
      └─ 📄 RECORDS (chaque table complète)
         │
         ├─ Record 1:
         │  {
         │    id: "7f3d8a2c-...",
         │    sessionId: "session-abc123",
         │    keyword: "Balance_2024",
         │    html: "<table>...",
         │    fingerprint: "8a3f2d5c...",
         │    timestamp: "2026-08-29T10:00:00Z",
         │    metadata: { rowCount: 50, ... }
         │  }
         │
         ├─ Record 2:
         │  {
         │    id: "a1b2c3d4-...",
         │    sessionId: "session-abc123",
         │    keyword: "Grand_Livre_Mars",
         │    html: "<table>...",
         │    ...
         │  }
         │
         └─ ... (milliers d'enregistrements possibles)
```

---

## 🧮 SCHÉMA 5 : CALCUL DU FINGERPRINT

```
TABLE HTML
┌─────────────────────────────────────────┐
│ <table>                                 │
│   <thead>                               │
│     <tr>                                │
│       <th>Compte</th>                   │
│       <th>Libellé</th>                  │
│       <th>Débit</th>                    │
│       <th>Crédit</th>                   │
│     </tr>                               │
│   </thead>                              │
│   <tbody>                               │
│     <tr>                                │
│       <td>411000</td>                   │
│       <td>Clients</td>                  │
│       <td>125000</td>                   │
│       <td>0</td>                        │
│     </tr>                               │
│     <tr>                                │
│       <td>401000</td>                   │
│       <td>Fournisseurs</td>             │
│       <td>0</td>                        │
│       <td>87500</td>                    │
│     </tr>                               │
│     ... 48 autres lignes ...            │
│   </tbody>                              │
│ </table>                                │
└─────────────────────────────────────────┘
              ↓
    ┌─────────────────────┐
    │ EXTRACTION          │
    │ extractHeaders()    │
    │ extractAllRows()    │
    └─────────────────────┘
              ↓
┌─────────────────────────────────────────┐
│ DONNÉES STRUCTURÉES                     │
│ {                                       │
│   headers: [                            │
│     "Compte",                           │
│     "Libellé",                          │
│     "Débit",                            │
│     "Crédit"                            │
│   ],                                    │
│   rows: [                               │
│     ["411000", "Clients", "125000", "0"]│
│     ["401000", "Fournisseurs", "0",     │
│      "87500"],                          │
│     ... 48 autres ...                   │
│   ],                                    │
│   structure: {                          │
│     rowCount: 50,                       │
│     colCount: 4                         │
│   }                                     │
│ }                                       │
└─────────────────────────────────────────┘
              ↓
    ┌─────────────────────┐
    │ JSON.stringify()    │
    └─────────────────────┘
              ↓
┌─────────────────────────────────────────┐
│ STRING COMPLÈTE (signature)             │
│ '{"headers":["Compte","Libellé",...'    │
└─────────────────────────────────────────┘
              ↓
    ┌─────────────────────┐
    │ HASH FNV-1a         │
    │ (algorithme rapide) │
    └─────────────────────┘
              ↓
┌─────────────────────────────────────────┐
│ FINGERPRINT FINAL (32 caractères hex)   │
│ "8a3f2d5c9e1b7f4a6d8c2e5f3b7a9d1c"     │
└─────────────────────────────────────────┘

⚡ PROPRIÉTÉS DU FINGERPRINT :
✅ Unique par contenu (probabilité collision < 0.00001%)
✅ Déterministe (même contenu → même hash)
✅ Sensible (1 caractère différent → hash totalement différent)
✅ Rapide à calculer (<1ms pour table 1000 lignes)
```

---

## 🎭 SCHÉMA 6 : SCÉNARIOS DE DOUBLONS

### Scénario A : ÉVITÉ ✅ (fonctionnement normal)

```
Session: "session-abc123"

T0: Création initiale
┌────────────────────────────────┐
│ Keyword: "Balance_2024"        │
│ Fingerprint: "8a3f..."         │
│ ID: "table-001"                │
└────────────────────────────────┘

T1: Tentative sauvegarde identique (skip)
┌────────────────────────────────┐
│ Keyword: "Balance_2024"        │
│ Fingerprint: "8a3f..." (même)  │
│ ❌ SKIP (doublon détecté)      │
└────────────────────────────────┘

Résultat dans IndexedDB:
┌────────────────────────────────┐
│ ✅ 1 seul enregistrement       │
│ ID: "table-001"                │
└────────────────────────────────┘
```

### Scénario B : ÉVITÉ ✅ (mise à jour)

```
Session: "session-abc123"

T0: Création initiale
┌────────────────────────────────┐
│ Keyword: "Balance_2024"        │
│ Fingerprint: "8a3f..."         │
│ ID: "table-001"                │
│ Cellule A1: "125000"           │
└────────────────────────────────┘

T1: Modification utilisateur
┌────────────────────────────────┐
│ Keyword: "Balance_2024"        │
│ Fingerprint: "9b4e..." (≠)     │
│ ✅ UPDATE table-001            │
│ Cellule A1: "135000" (modifié) │
└────────────────────────────────┘

Résultat dans IndexedDB:
┌────────────────────────────────┐
│ ✅ Toujours 1 enregistrement   │
│ ID: "table-001" (même)         │
│ Contenu: nouveau (écrasé)      │
└────────────────────────────────┘
```

### Scénario C : NORMAL ✅ (sessions différentes)

```
Session A: "session-abc123"
┌────────────────────────────────┐
│ Keyword: "Balance_2024"        │
│ ID: "table-001"                │
│ SessionId: "session-abc123"    │
└────────────────────────────────┘

Session B: "session-xyz789"
┌────────────────────────────────┐
│ Keyword: "Balance_2024"        │
│ ID: "table-002"                │
│ SessionId: "session-xyz789"    │
└────────────────────────────────┘

Résultat dans IndexedDB:
┌────────────────────────────────┐
│ ✅ 2 enregistrements NORMAUX   │
│ (sessions différentes)         │
│ table-001 (session A)          │
│ table-002 (session B)          │
└────────────────────────────────┘
```

### Scénario D : DOUBLON ⚠️ (bug race condition)

```
Session: "session-abc123"

T0: Sauvegarde 1 démarre
┌────────────────────────────────┐
│ Keyword: "Balance_2024"        │
│ 1️⃣ Vérification: aucune table  │
│    existante (base vide)       │
└────────────────────────────────┘

T0+50ms: Sauvegarde 2 démarre (avant fin de 1)
┌────────────────────────────────┐
│ Keyword: "Balance_2024"        │
│ 2️⃣ Vérification: aucune table  │
│    existante (1 pas fini)      │
└────────────────────────────────┘

T0+100ms: Sauvegarde 1 termine
┌────────────────────────────────┐
│ ✅ ID: "table-001" créé         │
└────────────────────────────────┘

T0+150ms: Sauvegarde 2 termine
┌────────────────────────────────┐
│ ✅ ID: "table-002" créé         │
└────────────────────────────────┘

Résultat dans IndexedDB:
┌────────────────────────────────┐
│ ⚠️ DOUBLON (2 enregistrements) │
│ table-001 (session A)          │
│ table-002 (session A) ← Bug    │
│ Même keyword, même session !   │
└────────────────────────────────┘

🛠️ FIX : Mutex/Lock pendant vérification
```

---

## 📱 SCHÉMA 7 : VUE DOM vs INDEXEDDB

```
┌──────────────────────────────────────────────────────────────┐
│  NAVIGATEUR - VUE DOM (Temporaire)                          │
├──────────────────────────────────────────────────────────────┤
│                                                              │
│  <div id="chat-container">                                  │
│    <div class="message assistant">                          │
│      <p>Voici la balance générale :</p>                     │
│      <table data-keyword="Balance_2024"                     │
│             data-table-id="table-001"                       │
│             data-restored="true">    ← Marqueur restauration│
│        <thead>                                              │
│          <tr>                                               │
│            <th>Compte</th>                                  │
│            <th>Libellé</th>                                 │
│            <th>Débit</th>                                   │
│            <th>Crédit</th>                                  │
│          </tr>                                              │
│        </thead>                                             │
│        <tbody>                                              │
│          <tr>                                               │
│            <td>411000</td>                                  │
│            <td>Clients</td>                                 │
│            <td>125000</td>                                  │
│            <td>0</td>                                       │
│          </tr>                                              │
│          ... 49 autres lignes ...                           │
│        </tbody>                                             │
│      </table>                                               │
│    </div>                                                   │
│  </div>                                                     │
│                                                              │
│  ⚠️ SI UTILISATEUR FERME ONGLET → TOUT PERDU               │
│  ✅ MAIS SAUVEGARDÉ DANS INDEXEDDB...                       │
│                                                              │
└──────────────────────────────────────────────────────────────┘
                            ↕️
                    (Synchronisation)
                            ↕️
┌──────────────────────────────────────────────────────────────┐
│  INDEXEDDB - STOCKAGE PERSISTANT (Permanent)                │
├──────────────────────────────────────────────────────────────┤
│                                                              │
│  clara_db → clara_generated_tables                          │
│                                                              │
│  Record {                                                   │
│    id: "table-001",                                         │
│    sessionId: "session-abc123",                             │
│    keyword: "Balance_2024",                                 │
│    html: "<table data-keyword=\"Balance_2024\"             │
│           data-table-id=\"table-001\"                       │
│           data-restored=\"true\">                           │
│           <thead>...EXACTEMENT LE MÊME HTML...</thead>      │
│           <tbody>...(50 lignes)...</tbody>                  │
│           </table>",                                        │
│    fingerprint: "8a3f2d5c9e1b7f4a...",                      │
│    containerId: "chat-container",                           │
│    position: 0,                                             │
│    timestamp: "2026-08-29T18:30:45.123Z",                   │
│    source: "n8n",                                           │
│    metadata: {                                              │
│      rowCount: 50,                                          │
│      colCount: 4,                                           │
│      headers: ["Compte", "Libellé", "Débit", "Crédit"],   │
│      compressed: false                                      │
│    }                                                        │
│  }                                                          │
│                                                              │
│  ✅ PERSISTE MÊME SI :                                      │
│     - Onglet fermé                                          │
│     - Navigateur fermé                                      │
│     - Ordinateur redémarré                                  │
│     - Changement de session dans le chat                    │
│                                                              │
│  ⚠️ SEUL EFFACEMENT POSSIBLE :                              │
│     - Suppression manuelle via DevTools                     │
│     - Nettoyage navigateur (Clear browsing data)            │
│     - Code JavaScript explicite (deleteGeneratedTable)      │
│                                                              │
└──────────────────────────────────────────────────────────────┘
```

---

## 🧭 SCHÉMA 8 : NAVIGATION ENTRE SESSIONS

```
┌────────────────────────────────────────────────────────────┐
│  UTILISATEUR CHANGE DE SESSION                             │
└────────────────────────────────────────────────────────────┘
                          ↓
        ┌─────────────────────────────────────┐
        │ SESSION A → SESSION B               │
        │ "session-abc123" → "session-xyz789" │
        └─────────────────────────────────────┘
                          ↓
        ┌─────────────────────────────────────┐
        │ Event: claraverse:session:changed   │
        │ detail: {                           │
        │   sessionId: "session-xyz789"       │
        │ }                                   │
        └─────────────────────────────────────┘
                          ↓
        ┌─────────────────────────────────────┐
        │ ÉTAPE 1 : Nettoyage DOM             │
        │ clearRestoredTablesFromDOM()        │
        │ ├─ Supprime [data-restored="true"]  │
        │ └─ Libère mémoire visuelle          │
        └─────────────────────────────────────┘
                          ↓
        ┌─────────────────────────────────────┐
        │ ÉTAPE 2 : Requête IndexedDB         │
        │ Query: sessionId = "session-xyz789" │
        └─────────────────────────────────────┘
                          ↓
┌──────────────────────────────────────────────────────────────┐
│  IndexedDB retourne tables de la SESSION B                   │
│  [                                                           │
│    { id: "t1", keyword: "Grand_Livre", ... },               │
│    { id: "t2", keyword: "Journal", ... },                   │
│    { id: "t3", keyword: "Bilan", ... }                      │
│  ]                                                           │
└──────────────────────────────────────────────────────────────┘
                          ↓
        ┌─────────────────────────────────────┐
        │ ÉTAPE 3 : Décompression             │
        │ (si metadata.compressed === true)   │
        └─────────────────────────────────────┘
                          ↓
        ┌─────────────────────────────────────┐
        │ ÉTAPE 4 : Tri chronologique         │
        │ sort((a, b) => a.timestamp - b.time)│
        └─────────────────────────────────────┘
                          ↓
        ┌─────────────────────────────────────┐
        │ ÉTAPE 5 : Insertion DOM             │
        │ Pour chaque table:                  │
        │ ├─ Créer wrapper                    │
        │ │  <div data-restored="true">       │
        │ ├─ Parser HTML                      │
        │ ├─ Insérer dans containerId         │
        │ └─ Position correcte                │
        └─────────────────────────────────────┘
                          ↓
┌──────────────────────────────────────────────────────────────┐
│  ÉCRAN UTILISATEUR - SESSION B                               │
│  ┌────────────────────────────────────────────────────────┐ │
│  │ Chat Session B                                          │ │
│  │ ┌────────────────────────────────────────────────────┐ │ │
│  │ │ 📊 Grand Livre (restaurée)                         │ │ │
│  │ │ <table>...</table>                                 │ │ │
│  │ └────────────────────────────────────────────────────┘ │ │
│  │ ┌────────────────────────────────────────────────────┐ │ │
│  │ │ 📋 Journal (restaurée)                             │ │ │
│  │ │ <table>...</table>                                 │ │ │
│  │ └────────────────────────────────────────────────────┘ │ │
│  │ ┌────────────────────────────────────────────────────┐ │ │
│  │ │ 💼 Bilan (restaurée)                               │ │ │
│  │ │ <table>...</table>                                 │ │ │
│  │ └────────────────────────────────────────────────────┘ │ │
│  └────────────────────────────────────────────────────────┘ │
│                                                              │
│  ✅ TABLES SESSION A toujours en IndexedDB (intactes)       │
│  ✅ TABLES SESSION B restaurées visuellement                │
└──────────────────────────────────────────────────────────────┘
```

---

## 🎯 RÉCAPITULATIF VISUEL : POINTS CLÉS

```
╔═══════════════════════════════════════════════════════════════╗
║  COMPRENDRE LE SYSTÈME EN 10 POINTS                          ║
╠═══════════════════════════════════════════════════════════════╣
║                                                               ║
║  1️⃣  STOCKAGE : IndexedDB (base locale navigateur)           ║
║      Store: clara_generated_tables                           ║
║                                                               ║
║  2️⃣  FORMAT : JSON complet (HTML + métadonnées)              ║
║      Taille moyenne: 15-50 KB par table                      ║
║                                                               ║
║  3️⃣  IDENTIFICATION : UUID unique (32 caractères)            ║
║      Exemple: "7f3d8a2c-4b5e-4a9f-8c1d-2e3f4a5b6c7d"        ║
║                                                               ║
║  4️⃣  ANTI-DOUBLONS : Fingerprint SHA-256                     ║
║      Hash de tout le contenu (headers + données)             ║
║                                                               ║
║  5️⃣  ISOLATION : Par sessionId                               ║
║      Chaque chat a ses propres tables                        ║
║                                                               ║
║  6️⃣  SAUVEGARDE : 3 moments                                  ║
║      - Création initiale (immédiat)                          ║
║      - Modification user (auto-save 10s)                     ║
║      - Manuelle (bouton/shortcut)                            ║
║                                                               ║
║  7️⃣  MISE À JOUR : Par ID (pas de doublon)                   ║
║      Même ID conservé → écrase ancien contenu                ║
║                                                               ║
║  8️⃣  COMPRESSION : Automatique si > 50KB                     ║
║      Algorithme: LZ-String UTF-16                            ║
║                                                               ║
║  9️⃣  RESTAURATION : Chronologique                            ║
║      Tri par timestamp lors de la restauration               ║
║                                                               ║
║  🔟  PERSISTANCE : Permanente                                ║
║      Survit à la fermeture navigateur/ordinateur             ║
║                                                               ║
╚═══════════════════════════════════════════════════════════════╝
```

---

**Fin des schémas visuels**

Pour plus de détails techniques, consultez le **MEMO_SYSTEME_PERSISTANCE_AUTOSAVE_INDEXEDDB.md**

