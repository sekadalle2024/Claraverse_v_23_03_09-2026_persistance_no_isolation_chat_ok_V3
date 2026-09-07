# GUIDE DÉBUTANT - Système de Sauvegarde des Tables

**Pour quelqu'un qui connaît les bases : React, JavaScript, bases de données**

Date : 29 Août 2026  
Niveau : Débutant / Intermédiaire

---

## 🎯 L'ESSENTIEL EN 1 MINUTE

**Le problème à résoudre :**  
Les tables générées par l'IA dans le chat doivent être sauvegardées automatiquement pour ne pas être perdues quand on ferme le navigateur ou qu'on change de conversation.

**La solution :**  
On sauvegarde les tables dans **IndexedDB** (une base de données locale dans le navigateur), et un système d'**auto-save** détecte automatiquement les modifications pour les sauvegarder toutes les 10 secondes.

---

## 📦 C'EST QUOI INDEXEDDB ?

### Analogie Simple

Imaginez votre application comme un **restaurant** :

- **LocalStorage** = Un petit tiroir avec 10 places (limite ~5 MB)
- **IndexedDB** = Un grand entrepôt avec des milliers d'étagères (limite ~500 MB à plusieurs GB)

**IndexedDB c'est** :
- 🏪 Un grand espace de stockage **dans votre navigateur**
- 📦 Organisé comme une base de données (tables, index, recherches)
- 💾 Les données restent **même si vous fermez le navigateur**
- 🔒 Accessible **uniquement par votre application** (sécurisé)

### Comparaison avec ce que vous connaissez

| Si vous connaissez | IndexedDB c'est comme |
|-------------------|----------------------|
| **SQL (MySQL, PostgreSQL)** | Une base SQL mais dans le navigateur |
| **MongoDB** | Pareil : des objets JSON stockés localement |
| **localStorage** | La version "grande taille" avec recherche avancée |
| **Excel** | Un fichier Excel invisible que JavaScript peut lire/écrire |

---

## 🗄️ STRUCTURE DE LA BASE (SIMPLIFIÉ)

### Notre Base : `clara_db`

C'est comme avoir **un classeur Excel** nommé `clara_db` avec plusieurs **feuilles** (appelées "stores").

**Feuille qui nous intéresse** : `clara_generated_tables`

### Ce qu'on enregistre dans chaque ligne

Imaginez un tableau Excel avec ces colonnes :

| ID | Session | Mot-clé | HTML Table | Date | Taille | Compressé |
|----|---------|---------|------------|------|--------|-----------|
| abc123 | session-1 | Balance_2024 | `<table>...</table>` | 29/08/2026 18:30 | 50 lignes | Non |
| def456 | session-1 | Grand_Livre | `<table>...</table>` | 29/08/2026 18:35 | 120 lignes | Oui |
| ghi789 | session-2 | Balance_2024 | `<table>...</table>` | 29/08/2026 19:00 | 45 lignes | Non |

**Chaque ligne = une table sauvegardée**

### Les Champs Importants

```javascript
{
  id: "abc123",                    // 🆔 Numéro unique (comme numéro de facture)
  sessionId: "session-1",          // 💬 À quelle conversation appartient cette table
  keyword: "Balance_2024",         // 🏷️ Nom/titre de la table
  html: "<table>...</table>",      // 📄 Le code HTML complet de la table
  timestamp: "2026-08-29T18:30:45Z", // 🕐 Quand elle a été créée
  fingerprint: "a3f8d2...",        // 🔐 Empreinte digitale du contenu (pour détecter doublons)
  metadata: {                      // 📊 Infos sur la table
    rowCount: 50,                  // Nombre de lignes
    colCount: 4,                   // Nombre de colonnes
    compressed: false              // Est-ce compressé ?
  }
}
```

---

## 💾 COMMENT ÇA FONCTIONNE ?

### 1. Quand une Table est Générée

```
Utilisateur tape : "Donne-moi la balance 2024"
         ↓
IA génère une table HTML
         ↓
JavaScript détecte : "Nouvelle table !"
         ↓
🎯 SAUVEGARDE IMMÉDIATE dans IndexedDB
         ↓
Table visible dans le chat + Sauvegardée en arrière-plan
```

**Temps** : Moins de 0.1 seconde

### 2. Quand Vous Modifiez une Table

```
Vous modifiez une cellule : "125000" → "135000"
         ↓
MutationObserver détecte le changement
         ↓
Table marquée comme "modifiée" (dirty)
         ↓
⏱️ Attente de 10 secondes
         ↓
🎯 AUTO-SAVE : Mise à jour dans IndexedDB
         ↓
Nouvelle version sauvegardée (ancienne écrasée)
```

**Pourquoi 10 secondes ?**  
Pour éviter de sauvegarder à chaque frappe (trop lourd). On attend que vous ayez fini vos modifications.

### 3. Quand Vous Changez de Conversation

```
Vous cliquez sur "Conversation 2"
         ↓
JavaScript charge session-2
         ↓
Recherche dans IndexedDB : "Toutes les tables de session-2"
         ↓
Trouvé : 5 tables
         ↓
🎯 RESTAURATION : Insertion des 5 tables dans le chat
         ↓
Vous voyez toutes vos anciennes tables
```

**Temps** : Moins de 0.5 seconde

---

## 🔐 COMMENT ON ÉVITE LES DOUBLONS ?

### Le Problème

Si vous sauvegardez 3 fois la même table, vous auriez :

```
IndexedDB
├─ Balance_2024 (version 1)
├─ Balance_2024 (version 2)  ← Doublon !
└─ Balance_2024 (version 3)  ← Doublon !
```

❌ Gaspillage d'espace  
❌ Confusion : quelle version est la bonne ?

### La Solution : Empreinte Digitale (Fingerprint)

**Concept** : Comme une empreinte digitale humaine, chaque contenu de table a une signature unique.

**Comment ça marche ?**

1. On prend **tout le contenu** de la table (headers + données)
2. On calcule un **hash** (code unique) avec un algorithme
3. Ce hash devient l'**empreinte digitale**

**Exemple** :

```javascript
Table 1 :
| Compte | Libellé   | Débit  |
|--------|-----------|--------|
| 411000 | Clients   | 125000 |
| 401000 | Fourniss. | 87500  |

Fingerprint : "a3f8d2c5e7b9..."

Table 2 (identique) :
| Compte | Libellé   | Débit  |
|--------|-----------|--------|
| 411000 | Clients   | 125000 |
| 401000 | Fourniss. | 87500  |

Fingerprint : "a3f8d2c5e7b9..." ← Pareil !

Table 3 (différente) :
| Compte | Libellé   | Débit  |
|--------|-----------|--------|
| 411000 | Clients   | 135000 | ← Changé
| 401000 | Fourniss. | 87500  |

Fingerprint : "x9y2z4k8m1n3..." ← Différent !
```

### Vérification Avant Sauvegarde

```javascript
// Pseudo-code simplifié
function sauvegarderTable(table) {
  // 1. Calculer l'empreinte de la nouvelle table
  const nouvelleEmpreinte = calculerHash(table);
  
  // 2. Chercher si une table existe déjà avec ce nom
  const tableExistante = chercherDansIndexedDB(table.keyword);
  
  if (tableExistante) {
    // 3. Comparer les empreintes
    if (tableExistante.fingerprint === nouvelleEmpreinte) {
      console.log("❌ Table identique, pas besoin de sauvegarder");
      return; // On arrête ici
    } else {
      console.log("✅ Table modifiée, mise à jour");
      mettreAJour(tableExistante.id, table); // Même ID, nouveau contenu
    }
  } else {
    console.log("✅ Nouvelle table, sauvegarde");
    creerNouvelle(table); // Nouvel ID
  }
}
```

**Résultat** : Maximum **1 seule version** de "Balance_2024" dans une conversation.

---

## 🎭 LES 3 FICHIERS PRINCIPAUX

### 1. `indexedDB.ts` - Le Gardien de la Base

**Rôle** : Gérer la connexion et les opérations sur IndexedDB

**Analogie** : C'est le **portier de l'entrepôt**. Il ouvre les portes, vous laisse entrer, et note ce que vous prenez/déposez.

**Actions principales** :
```javascript
// Ouvrir la base
const db = await indexedDB.open('clara_db');

// Sauvegarder une table
await indexedDB.put(table);

// Récupérer toutes les tables d'une session
const tables = await indexedDB.getBySession(sessionId);

// Supprimer une table
await indexedDB.delete(tableId);
```

**Quand intervient-il ?**  
À chaque fois qu'on veut lire/écrire dans la base.

---

### 2. `flowiseTableService.ts` - Le Chef d'Orchestre

**Rôle** : Coordonner les sauvegardes et restaurations

**Analogie** : C'est le **manager du restaurant**. Il décide quoi faire : sauvegarder, mettre à jour, restaurer, compresser...

**Actions principales** :
```javascript
// Sauvegarder une nouvelle table
await flowiseTableService.saveGeneratedTable(
  sessionId,
  tableElement,
  keyword
);

// Mettre à jour une table existante
await flowiseTableService.updateGeneratedTable(
  tableId,
  tableElement
);

// Restaurer toutes les tables d'une session
const tables = await flowiseTableService.restoreSessionTables(sessionId);

// Vérifier si table existe déjà (anti-doublon)
const exists = await flowiseTableService.tableExists(sessionId, fingerprint);
```

**Quand intervient-il ?**  
Quand une table doit être sauvegardée, restaurée ou vérifiée.

---

### 3. `flowiseTableBridge.ts` - Le Surveillant Auto-Save

**Rôle** : Détecter les changements et déclencher les sauvegardes automatiques

**Analogie** : C'est la **caméra de surveillance** qui regarde si quelque chose change dans le restaurant.

**Actions principales** :
```javascript
// Démarrer la surveillance
startAutoSaveSystem() {
  // Observer les modifications DOM
  this.mutationObserver.observe(document.body);
  
  // Timer : vérifier toutes les 10 secondes
  setInterval(() => {
    this.performAutoSave(); // Sauvegarder tables modifiées
  }, 10000);
}

// Marquer une table comme modifiée
this.dirtyTables.add("Balance_2024");

// Sauvegarder toutes les tables modifiées
await this.performAutoSave();
```

**Quand intervient-il ?**  
En permanence en arrière-plan, surveille les modifications 24/7.

---

## 🔄 CYCLE DE VIE COMPLET (VERSION SIMPLE)

### Scénario : Vous travaillez sur une balance comptable

```
┌─────────────────────────────────────────────────────────┐
│ ÉTAPE 1 : GÉNÉRATION                                    │
└─────────────────────────────────────────────────────────┘

Vous : "Crée une balance 2024"
   ↓
IA génère le HTML de la table
   ↓
flowiseTableBridge détecte : "Nouvelle table !"
   ↓
flowiseTableService calcule l'empreinte digitale
   ↓
Vérifie IndexedDB : "Balance_2024 existe ?"
   → NON
   ↓
indexedDB.put() → Sauvegarde
   ↓
✅ Table visible + Sauvegardée

┌─────────────────────────────────────────────────────────┐
│ ÉTAPE 2 : MODIFICATION (5 minutes plus tard)            │
└─────────────────────────────────────────────────────────┘

Vous modifiez "125000" → "135000" dans une cellule
   ↓
MutationObserver détecte le changement
   ↓
flowiseTableBridge marque : dirtyTables.add("Balance_2024")
   ↓
⏱️ Attente 10 secondes
   ↓
performAutoSave() déclenché
   ↓
flowiseTableService calcule nouvelle empreinte
   ↓
Vérifie IndexedDB : "Balance_2024 existe ?"
   → OUI
   ↓
Compare empreintes :
   Ancienne : "a3f8d2..."
   Nouvelle : "x9y2z4..." → Différent !
   ↓
indexedDB.put() → Mise à jour (même ID)
   ↓
✅ Nouvelle version sauvegardée

┌─────────────────────────────────────────────────────────┐
│ ÉTAPE 3 : FERMETURE NAVIGATEUR                          │
└─────────────────────────────────────────────────────────┘

Vous fermez Chrome
   ↓
IndexedDB reste intact (données persistantes)
   ↓
Lendemain, vous rouvrez Chrome
   ↓
Claraverse démarre
   ↓
flowiseTableService.restoreSessionTables()
   ↓
indexedDB recherche : "Toutes tables de session actuelle"
   ↓
Trouve : Balance_2024 (dernière version)
   ↓
Insère HTML dans le DOM
   ↓
✅ Vous retrouvez votre table modifiée

┌─────────────────────────────────────────────────────────┐
│ ÉTAPE 4 : CHANGEMENT DE CONVERSATION                    │
└─────────────────────────────────────────────────────────┘

Vous cliquez : "Conversation 2"
   ↓
flowiseTableBridge détecte : "Session changée !"
   ↓
Nettoie les anciennes tables affichées
   ↓
flowiseTableService.restoreSessionTables(session-2)
   ↓
indexedDB recherche : "Tables de session-2"
   ↓
Trouve : Grand_Livre, Bilan
   ↓
Insère dans le DOM
   ↓
✅ Vous voyez les tables de la conversation 2
```

---

## 🤔 QUESTIONS FRÉQUENTES

### Q1 : Où sont stockées les données ?

**R :** Dans votre navigateur, sur votre disque dur.

**Chemin typique** :
```
Windows :
C:\Users\VotreNom\AppData\Local\Google\Chrome\User Data\Default\IndexedDB\

Mac :
~/Library/Application Support/Google/Chrome/Default/IndexedDB/
```

**Visible dans Chrome DevTools** :
F12 → Application → Storage → IndexedDB → clara_db

---

### Q2 : Que se passe-t-il si j'ouvre l'application dans 2 onglets ?

**R :** Chaque onglet partage la **même** base IndexedDB.

**Conséquence** :
- ✅ Les modifications dans onglet 1 sont vues par onglet 2
- ⚠️ Attention : possibilité de conflits si vous éditez la même table simultanément
- 🔄 Solution : Le système sauvegarde la dernière modification (last write wins)

---

### Q3 : Combien d'espace de stockage disponible ?

**R :** Ça dépend du navigateur :

| Navigateur | Limite Typique |
|-----------|----------------|
| Chrome | ~60% espace disque disponible (plusieurs GB) |
| Firefox | ~50% espace disque disponible |
| Safari | ~1 GB |
| Edge | ~60% espace disque disponible |

**En pratique** :
- 1 table simple = ~15 KB
- 1000 tables = ~15 MB
- Vous pouvez stocker **des milliers** de tables sans problème

---

### Q4 : Les données sont-elles sécurisées ?

**R :** Oui et non.

✅ **Sécurisé contre** :
- Autres sites web (isolation par domaine)
- Autres applications sur votre PC
- Accès réseau externe

❌ **PAS sécurisé contre** :
- Quelqu'un avec accès à votre ordinateur (peut ouvrir DevTools)
- Malware sur votre PC
- Vous-même si vous faites "Clear browsing data"

**Recommandation** : Ne stockez pas de données ultra-sensibles (mots de passe, numéros de carte bancaire) dans IndexedDB.

---

### Q5 : Comment voir mes données sauvegardées ?

**R :** Via Chrome DevTools :

```
1. Ouvrir l'application Claraverse
2. Appuyer sur F12 (ou Clic droit → Inspecter)
3. Onglet "Application"
4. Sidebar gauche : Storage → IndexedDB → clara_db
5. Cliquer sur "clara_generated_tables"
6. Vous voyez toutes vos tables sauvegardées
7. Cliquer sur une ligne pour voir le détail
```

**Ce que vous verrez** :
- L'ID unique
- Le nom (keyword)
- Le HTML complet
- La date de création
- Le fingerprint
- Les métadonnées

---

### Q6 : Comment supprimer toutes les données ?

**R :** Plusieurs méthodes :

**Méthode 1 : Via Chrome**
```
Chrome → Paramètres → Confidentialité et sécurité
→ Effacer les données de navigation
→ Cocher "Cookies et données de sites"
→ Effacer les données
```

**Méthode 2 : Via DevTools**
```
F12 → Application → Storage → IndexedDB
→ Clic droit sur "clara_db"
→ "Delete database"
```

**Méthode 3 : Via Console JavaScript**
```javascript
// Supprimer toute la base
indexedDB.deleteDatabase('clara_db');

// Ou supprimer uniquement les tables d'une session
await indexedDBService.deleteGeneratedTablesBySession('session-abc123');
```

---

### Q7 : Pourquoi 10 secondes pour l'auto-save ?

**R :** C'est un **compromis** :

| Délai | Avantages | Inconvénients |
|-------|-----------|---------------|
| **1 seconde** | Sauvegarde ultra-rapide | Surcharge (sauvegarde à chaque frappe) |
| **10 secondes** ✅ | Équilibre performance/réactivité | Perte max 10s de travail si crash |
| **30 secondes** | Moins de charge système | Risque perte de 30s de modifications |
| **1 minute** | Très léger | Frustrant si oubli de sauvegarder |

**Pourquoi pas instant ?**  
Si vous tapez 50 caractères en 5 secondes, on aurait 50 sauvegardes inutiles.

---

### Q8 : Que se passe-t-il si mon disque est plein ?

**R :** Le système gère l'erreur :

```javascript
try {
  await indexedDB.put(table);
  console.log("✅ Sauvegarde OK");
} catch (error) {
  if (error.name === 'QuotaExceededError') {
    console.error("⚠️ Disque plein !");
    
    // Tentative 1 : Supprimer anciennes tables
    await nettoyerAnciennesTables();
    
    // Tentative 2 : Réessayer sauvegarde
    await indexedDB.put(table);
  }
}
```

**Actions automatiques** :
1. Détection de l'erreur "Quota dépassé"
2. Suppression des tables les plus anciennes
3. Nouvelle tentative de sauvegarde
4. Si échec : Alerte utilisateur

---

## 🎨 ANALOGIE FINALE : LE SYSTÈME COMME UNE BIBLIOTHÈQUE

Imaginez le système comme une **bibliothèque municipale** :

| Composant | Rôle dans la Bibliothèque |
|-----------|---------------------------|
| **IndexedDB** | L'entrepôt avec les étagères |
| **flowiseTableService** | Le bibliothécaire qui classe les livres |
| **flowiseTableBridge** | La caméra qui détecte nouveaux livres |
| **Une table** | Un livre |
| **keyword** | Le titre du livre |
| **fingerprint** | Le code-barre ISBN (unique) |
| **sessionId** | Le rayon (Fiction, Sciences, etc.) |
| **timestamp** | La date d'ajout à la collection |
| **Auto-save** | L'assistant qui range automatiquement |

**Scénario complet** :

1. **Nouveau livre arrive** (table générée)
   → Le bibliothécaire (service) vérifie si ce titre existe déjà
   → Scanne le code-barre (fingerprint)
   → Si nouveau : Range dans le bon rayon (sessionId)

2. **Livre modifié** (table éditée)
   → La caméra (bridge) détecte le changement
   → Attend 10 secondes (au cas où d'autres modifications)
   → Le bibliothécaire met à jour la fiche du livre

3. **Lecteur cherche un livre** (restauration)
   → Demande : "Tous les livres du rayon Sciences" (sessionId)
   → Bibliothécaire consulte le catalogue (IndexedDB)
   → Ressort tous les livres demandés
   → Les pose sur la table de lecture (DOM)

---

## 📚 POUR ALLER PLUS LOIN

**Documentation complémentaire** :

0. **`REPONSES_QUESTIONS_COMPLEMENTAIRES_DEBUTANT.md`** ⭐ **NOUVEAU**  
   → Réponses détaillées aux 12 questions techniques avancées :
   - Concept et gestion du Fingerprint (empreinte digitale)
   - Temporisation et déclencheurs (délais, événements)
   - Structure complète des données IndexedDB
   - Algorithme détaillé de l'auto-save

1. **`SCHEMAS_VISUELS_PERSISTANCE.md`**  
   → Schémas et diagrammes visuels

2. **`REPONSES_DIRECTES_AUX_QUESTIONS.md`**  
   → Réponses techniques détaillées avec code

3. **`MEMO_SYSTEME_PERSISTANCE_AUTOSAVE_INDEXEDDB.md`**  
   → Documentation complète pour développeurs

**Documentation officielle** :
- [MDN - IndexedDB](https://developer.mozilla.org/en-US/docs/Web/API/IndexedDB_API)
- [MDN - MutationObserver](https://developer.mozilla.org/en-US/docs/Web/API/MutationObserver)

---

## ✅ RÉSUMÉ EN 5 POINTS

1. **📦 Stockage** : IndexedDB = base de données locale dans le navigateur
2. **💾 Sauvegarde** : Automatique à la création + toutes les 10s si modification
3. **🔐 Anti-doublon** : Empreinte digitale (fingerprint) pour détecter contenu identique
4. **🔄 Persistance** : Les données restent même si vous fermez le navigateur
5. **🎯 Simplicité** : Tout automatique, vous n'avez rien à faire !

---

**Document créé le** : 29 Août 2026  
**Pour** : Débutants connaissant React/JS/BDD  
**Niveau** : ⭐⭐☆☆☆ (Débutant-Intermédiaire)

