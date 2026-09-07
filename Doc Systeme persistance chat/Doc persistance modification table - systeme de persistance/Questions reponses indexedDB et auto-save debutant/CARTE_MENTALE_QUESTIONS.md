# 🧠 CARTE MENTALE - Questions Complémentaires Système Persistance

**Date** : 29 Août 2026  
**Format** : Mindmap textuelle  
**Public** : Vue d'ensemble rapide

---

## 🎯 VUE GLOBALE

```
                        SYSTÈME DE PERSISTANCE
                        CLARAVERSE TABLES
                               |
                ┌──────────────┼──────────────┐
                │              │              │
          FINGERPRINT    TEMPORISATION   STRUCTURE
           (Empreinte)    (Triggers)     (IndexedDB)
                │              │              │
        ┌───────┼───────┐      │      ┌───────┼───────┐
        │       │       │      │      │       │       │
     Concept Calcul  Usage   Délais  Format  HTML  Données
```

---

## 1. 🔐 FINGERPRINT (Empreinte Digitale)

```
FINGERPRINT
│
├─ 📖 CONCEPT
│  ├─ Qu'est-ce ? → Hash unique du contenu
│  ├─ Analogie → Code-barre / ISBN livre
│  ├─ Objectif → Détecter doublons
│  └─ Algorithme → SHA-256 (FNV-1a)
│
├─ 🧮 CALCUL
│  ├─ Entrées
│  │  ├─ Headers (en-têtes)
│  │  ├─ Rows (lignes données)
│  │  └─ Structure (dimensions)
│  │
│  ├─ Processus
│  │  ├─ 1. Extraction données
│  │  ├─ 2. JSON.stringify()
│  │  ├─ 3. Hash FNV-1a
│  │  └─ 4. Hex string 32 chars
│  │
│  └─ Sortie
│     └─ "a3f8d2c5e7b9f1a4..." (32 chars)
│
├─ ⚡ SENSIBILITÉ
│  ├─ 1 lettre modifiée → Hash différent
│  ├─ 1 espace ajouté → Hash différent
│  ├─ 1 ligne ajoutée → Hash différent
│  └─ ✅ Voulu (détection précise)
│
├─ 💡 SEL ALÉATOIRE ?
│  ├─ Suggestion → Ajouter 5 chars random
│  ├─ Problème 1 → Perte déduplication
│  ├─ Problème 2 → Gonflement base
│  ├─ Solution actuelle → Fingerprint pur
│  └─ ❌ Non recommandé
│
└─ 🔧 STRUCTURE COMPLEXE
   ├─ Tables → Modifications multiples DOM
   ├─ Ajout ligne → 7 mutations détectées
   ├─ Timer 10s → Attend fin modifications
   └─ ✅ Adapté DOM complexe
```

---

## 2. ⏱️ TEMPORISATION ET TRIGGERS

```
TEMPORISATION
│
├─ ⏰ DÉLAI AUTO-SAVE
│  ├─ Valeur actuelle → 10 secondes (10000ms)
│  ├─ Définition → AUTO_SAVE_INTERVAL_MS
│  ├─ Fichier → flowiseTableBridge.ts:68
│  ├─ Modifiable ? → ✅ Oui
│  │  ├─ Méthode 1 → Modifier code source
│  │  └─ Méthode 2 → setAutoSaveInterval()
│  │
│  └─ Comparaison délais
│     ├─ 1s → ⚠️ Surcharge extrême
│     ├─ 3s → ⚠️ Charge élevée
│     ├─ 10s → ✅ OPTIMAL
│     ├─ 30s → Perte 30s acceptable
│     └─ 60s → ⚠️ Risque perte données
│
├─ 📡 DÉCLENCHEUR PRINCIPAL
│  ├─ Nom → MutationObserver
│  ├─ Rôle → Caméra surveillance DOM
│  │
│  ├─ Configuration
│  │  ├─ childList: true → Ajout/suppression
│  │  ├─ subtree: true → Tous descendants
│  │  ├─ characterData: true → Changement texte
│  │  └─ attributes: false → Ignorer styles
│  │
│  ├─ Chaîne événements
│  │  ├─ 1. User modifie cellule
│  │  ├─ 2. DOM change
│  │  ├─ 3. MutationObserver détecte
│  │  ├─ 4. Identifie quelle table
│  │  ├─ 5. Ajoute à dirtyTables
│  │  ├─ 6. Attend 10s
│  │  └─ 7. performAutoSave()
│  │
│  └─ Types détectés
│     ├─ ✅ Texte modifié
│     ├─ ✅ Ligne ajoutée
│     ├─ ✅ Ligne supprimée
│     ├─ ✅ Colonne ajoutée
│     └─ ❌ Style CSS (ignoré)
│
├─ 🚫 CAS NON-SAUVEGARDE
│  ├─ Cas 1 → Fingerprint identique
│  ├─ Cas 2 → Aucune table modifiée
│  ├─ Cas 3 → Session non détectée
│  ├─ Cas 4 → Table sans ID
│  └─ Cas 5 → Quota dépassé
│
└─ ⚙️ RÉDUIRE DÉLAI 3S
   ├─ Faisable ? → ✅ Oui techniquement
   ├─ Recommandé ? → ❌ Non
   ├─ Impact
   │  ├─ CPU → +300% (5-8% vs 1-2%)
   │  ├─ Batterie → -20% durée vie
   │  └─ IndexedDB → Chargé
   │
   └─ Alternative
      └─ Bouton sauvegarde manuelle
         └─ window.manualSave()
```

---

## 3. 🗄️ STRUCTURE INDEXEDDB

```
STRUCTURE INDEXEDDB
│
├─ 📦 ENREGISTREMENT TABLE
│  │
│  ├─ IDENTIFIANTS
│  │  ├─ id → UUID unique
│  │  ├─ sessionId → ID conversation
│  │  └─ tableId → ID DOM
│  │
│  ├─ MÉTADONNÉES
│  │  ├─ keyword → Nom/titre
│  │  ├─ timestamp → Date ISO
│  │  ├─ source → n8n|flowise|gpt|user_edit
│  │  └─ messageId → ID message (optionnel)
│  │
│  ├─ CONTENU
│  │  ├─ html → HTML complet
│  │  └─ fingerprint → Hash SHA-256
│  │
│  └─ MÉTADONNÉES SUPPLÉMENTAIRES
│     └─ metadata
│        ├─ rowCount → Nb lignes
│        ├─ colCount → Nb colonnes
│        ├─ size → Taille bytes
│        ├─ compressed → Booléen
│        └─ version → Numéro version
│
├─ 📊 TAILLE ÉLÉMENTS
│  ├─ id → 36 bytes
│  ├─ sessionId → 40-60 bytes
│  ├─ keyword → 20-100 bytes
│  ├─ timestamp → 27 bytes
│  ├─ html → 500-50000 bytes 🔴
│  ├─ fingerprint → 32 bytes
│  └─ metadata → 50-100 bytes
│  │
│  └─ Total moyen
│     ├─ Petite table → 2-10 KB
│     └─ Grande table → 50-100 KB
│
├─ 🗜️ COMPRESSION
│  ├─ Seuil → > 50 KB
│  ├─ Algorithme → LZ-String
│  ├─ Ratio → 60-80%
│  └─ Exemple → 100 KB → 20-40 KB
│
└─ 🔀 HTML vs DONNÉES
   │
   ├─ APPROCHE HTML (actuelle)
   │  ├─ Stockage → HTML complet
   │  ├─ Avantages
   │  │  ├─ ✅ Insertion DOM simple
   │  │  ├─ ✅ Conserve mise en forme
   │  │  └─ ✅ Tables complexes
   │  ├─ Inconvénients
   │  │  ├─ ⚠️ Taille plus grande
   │  │  └─ ⚠️ Recherche plus lente
   │  └─ Cas usage → Tables IA variées
   │
   └─ APPROCHE DONNÉES (alternative)
      ├─ Stockage → JSON structuré
      ├─ Avantages
      │  ├─ ✅ Taille minimale
      │  ├─ ✅ Recherche rapide
      │  └─ ✅ Export facile
      ├─ Inconvénients
      │  ├─ ⚠️ Perte mise en forme
      │  └─ ⚠️ Reconstruction HTML
      └─ Cas usage → Données tabulaires simples
```

---

## 4. 🤖 ALGORITHME AUTO-SAVE

```
ALGORITHME AUTO-SAVE
│
├─ PHASE 1 : INITIALISATION
│  ├─ Démarrage application
│  ├─ Créer dirtyTables (Set)
│  ├─ Créer MutationObserver
│  ├─ Surveiller document.body
│  └─ Créer timer 10s (setInterval)
│
├─ PHASE 2 : DÉTECTION
│  ├─ Mode → Asynchrone continu
│  │
│  ├─ Branche A : Modification user
│  │  ├─ User modifie cellule
│  │  ├─ DOM change
│  │  ├─ MutationObserver détecte
│  │  └─ dirtyTables.add(tableId)
│  │
│  └─ Branche B : Timer 10s
│     └─ performAutoSave() appelé
│
├─ PHASE 3 : SAUVEGARDE
│  ├─ Vérifications préalables
│  │  ├─ dirtyTables.size > 0 ? → Sinon SKIP
│  │  └─ currentSessionId exists ? → Sinon ERROR
│  │
│  ├─ Pour chaque tableId dirty
│  │  ├─ Récupérer élément DOM
│  │  ├─ Calculer fingerprint
│  │  ├─ Vérifier existence
│  │  │  │
│  │  │  ├─ Table existe ?
│  │  │  │  ├─ OUI → Fingerprint identique ?
│  │  │  │  │  ├─ OUI → SKIP
│  │  │  │  │  └─ NON → UPDATE
│  │  │  │  │
│  │  │  │  └─ NON → INSERT
│  │  │  │
│  │  │  └─ Retirer de dirtyTables
│  │  │
│  │  └─ Rapport final
│  │     ├─ Sauvegardées : X
│  │     ├─ Ignorées : Y
│  │     └─ Erreurs : Z
│  │
│  └─ Logique conditionnelle
│     │
│     ├─ SI currentSessionId == null
│     │  └─ RETURN (erreur)
│     │
│     ├─ SI dirtyTables.size == 0
│     │  └─ RETURN (rien à faire)
│     │
│     ├─ SI table pas dans DOM
│     │  └─ SKIP (table supprimée)
│     │
│     ├─ SI fingerprint identique
│     │  └─ SKIP (pas de changement)
│     │
│     └─ SINON
│        └─ SAVE (mise à jour ou insert)
│
└─ PHASE 4 : PERSISTANCE
   ├─ Préparer record
   │  ├─ Générer UUID
   │  ├─ Calculer fingerprint
   │  ├─ Extraire métadonnées
   │  ├─ Comprimer si > 50KB
   │  └─ Assembler record
   │
   ├─ Sauvegarder IndexedDB
   │  ├─ Ouvrir DB clara_db
   │  ├─ Transaction clara_generated_tables
   │  ├─ store.put(record)
   │  └─ Attendre confirmation
   │
   └─ Gestion erreurs
      ├─ QuotaExceededError
      │  ├─ Nettoyer anciennes tables
      │  └─ Réessayer
      │
      └─ Autres erreurs
         └─ LOG + Réessai prochain cycle
```

---

## 🔗 LIENS ENTRE CONCEPTS

```
FINGERPRINT ──────────┐
    │                 │
    │                 ▼
    │           ANTI-DOUBLON
    │                 │
    │                 ▼
    └────────► PERFORMAUTOSAVE ◄────┐
                      │              │
                      ▼              │
              VÉRIFICATION       TIMER 10S
                      │              │
                      ▼              │
              INDEXEDDB.PUT          │
                      │              │
                      └──────────────┘
                    
MUTATIONOBSERVER ──────────┐
    │                      │
    │                      ▼
    └───────────► DIRTYTABLES.ADD
                      │
                      │
                      ▼
              ATTENTE 10 SECONDES
                      │
                      ▼
              PERFORMAUTOSAVE
```

---

## 📊 FLUX COMPLET

```
┌─────────────────────────────────────────────────────────┐
│ ÉVÉNEMENT : User modifie table                          │
└─────────────────────────────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────────────────────┐
│ MutationObserver détecte changement DOM                 │
└─────────────────────────────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────────────────────┐
│ Identifier table modifiée (data-table-id)               │
└─────────────────────────────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────────────────────┐
│ dirtyTables.add(tableId)                                 │
└─────────────────────────────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────────────────────┐
│ ⏱️ ATTENTE 10 SECONDES                                  │
└─────────────────────────────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────────────────────┐
│ Timer déclenche performAutoSave()                        │
└─────────────────────────────────────────────────────────┘
         │
         ├─► dirtyTables.size == 0 ? ──► SKIP
         │
         ├─► currentSessionId == null ? ──► ERROR
         │
         └─► Pour chaque table dirty :
             │
             ├─► Récupérer HTML complet
             │
             ├─► Calculer fingerprint
             │
             ├─► Chercher table existante (keyword+session)
             │   │
             │   ├─ Existe + même fingerprint ──► SKIP
             │   │
             │   ├─ Existe + fingerprint différent ──► UPDATE
             │   │   └─► flowiseTableService.updateGeneratedTable()
             │   │
             │   └─ N'existe pas ──► INSERT
             │       └─► flowiseTableService.saveGeneratedTable()
             │
             └─► IndexedDB.put(record)
                 │
                 ├─ Succès ──► ✅ Sauvegarde OK
                 │
                 └─ Échec quota ──► Nettoyer + Réessayer
```

---

## 🎯 DÉCISIONS CLÉS

```
DÉCISION 1 : Fingerprint Pur (Sans Sel)
├─ Raison → Permettre déduplication
├─ Avantage → Détecte vraies modifications
└─ Trade-off → Sensibilité totale (voulu)

DÉCISION 2 : Timer 10 Secondes
├─ Raison → Équilibre perf/réactivité
├─ Avantage → Attend fin modifications multiples
└─ Trade-off → Perte max 10s si crash

DÉCISION 3 : Stockage HTML
├─ Raison → Tables IA variées et complexes
├─ Avantage → Restauration fidèle
└─ Trade-off → Taille plus grande

DÉCISION 4 : MutationObserver
├─ Raison → Détection automatique
├─ Avantage → Aucune action user requise
└─ Trade-off → Charge CPU légère

DÉCISION 5 : Compression > 50KB
├─ Raison → Économiser espace
├─ Avantage → Ratio 60-80%
└─ Trade-off → CPU compression/décompression
```

---

## ✅ CHECKLIST RAPIDE

```
☑ Fingerprint
  ├─ [ ] Comprendre concept hash
  ├─ [ ] Connaître entrées (headers+rows+structure)
  ├─ [ ] Savoir pourquoi pas de sel aléatoire
  └─ [ ] Identifier cas sensibilité

☑ Temporisation
  ├─ [ ] Mémoriser délai 10s
  ├─ [ ] Comprendre MutationObserver
  ├─ [ ] Lister 5 cas non-sauvegarde
  └─ [ ] Savoir modifier délai

☑ Structure
  ├─ [ ] Connaître 7 champs principaux
  ├─ [ ] Comprendre compression auto
  ├─ [ ] Différencier HTML vs Données
  └─ [ ] Estimer tailles typiques

☑ Algorithme
  ├─ [ ] Mémoriser 4 phases
  ├─ [ ] Comprendre logique conditionnelle
  ├─ [ ] Tracer flux complet
  └─ [ ] Expliquer extraction données
```

---

## 🚀 ACTIONS POSSIBLES

```
CONSULTER CODE SOURCE
├─ flowiseTableBridge.ts
│  ├─ Ligne 68 → AUTO_SAVE_INTERVAL_MS
│  ├─ Ligne 2669 → startAutoSaveSystem()
│  └─ Ligne 2724 → performAutoSave()
│
├─ flowiseTableService.ts
│  ├─ Ligne 53 → generateTableFingerprint()
│  ├─ Ligne 197 → saveGeneratedTable()
│  └─ Ligne 2022 → updateGeneratedTable()
│
└─ indexedDB.ts
   └─ Opérations CRUD

MODIFIER SYSTÈME
├─ Changer délai auto-save
│  └─ Modifier AUTO_SAVE_INTERVAL_MS
│
├─ Ajouter logging
│  └─ console.log() dans performAutoSave()
│
└─ Personnaliser fingerprint
   └─ Modifier generateTableFingerprint()

DÉBOGUER
├─ Ouvrir Console F12
├─ Observer logs [AUTO-SAVE]
├─ Inspecter IndexedDB (DevTools)
└─ Vérifier dirtyTables.size
```

---

**Document créé le** : 29 Août 2026  
**Format** : Carte mentale textuelle  
**Usage** : Référence visuelle rapide  
**Source** : REPONSES_QUESTIONS_COMPLEMENTAIRES_DEBUTANT.md
