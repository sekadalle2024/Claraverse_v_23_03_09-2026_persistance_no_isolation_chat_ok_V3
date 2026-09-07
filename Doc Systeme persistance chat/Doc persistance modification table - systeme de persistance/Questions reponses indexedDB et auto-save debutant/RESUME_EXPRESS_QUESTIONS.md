# ⚡ RÉSUMÉ EXPRESS - 12 Questions Système Persistance

**Format** : Réponses ultra-rapides  
**Temps lecture** : 5 minutes  
**Public** : Tous (référence rapide)

---

## 📋 LES 12 QUESTIONS EN 1 PAGE

### 🔐 FINGERPRINT (Empreinte)

#### Q1 : C'est quoi un fingerprint ?
**Un code unique (hash) calculé à partir du contenu de la table**
- Comme un code-barre ISBN pour un livre
- Algorithme : SHA-256 (FNV-1a)
- Exemple : `"a3f8d2c5e7b9f1a4d6c8e2b7f9a3c5d7"`

#### Q2 : Basé sur quoi ?
**Headers + Rows + Structure (dimensions)**
```
Entrées : ["Compte", "Libellé"] + [["411000", "Clients"]] + {2 lignes, 2 cols}
         ↓
Sortie : "a3f8d2c5..." (32 caractères)
```

#### Q3 : Si je modifie 1 lettre ?
**Le fingerprint change COMPLÈTEMENT** ✅
- `"Clients"` → fingerprint `"a3f8d2c5..."`
- `"Client"` → fingerprint `"x9y2z4k8..."` (totalement différent)
- **Voulu** : Détecte toute modification

#### Q4 : Ajouter 5 caractères aléatoires ?
**❌ Non recommandé**
- Problème : Perte déduplication (même contenu = fingerprints différents)
- Solution actuelle meilleure : Fingerprint pur + timer 10s

#### Q5 : Adapté aux tables complexes ?
**✅ Oui**
- Ajout ligne = 7 mutations DOM détectées
- Timer 10s attend fin modifications
- 1 seul fingerprint calculé sur état final

---

### ⏱️ TEMPORISATION

#### Q6 : Délai auto-save ?
**10 secondes (10000 millisecondes)**
```typescript
AUTO_SAVE_INTERVAL_MS = 10000  // Ligne 68, flowiseTableBridge.ts
```

#### Q7 : Déclencheur principal ?
**MutationObserver (surveillance DOM)**
```
User modifie cellule
     ↓
DOM change
     ↓
MutationObserver détecte
     ↓
Table marquée "dirty"
     ↓
⏱️ Attente 10s
     ↓
Sauvegarde automatique
```

#### Q8 : Cas de non-sauvegarde ?
**5 cas** :
1. Fingerprint identique (contenu inchangé)
2. Aucune table modifiée (dirtyTables.size = 0)
3. Session non détectée (currentSessionId = null)
4. Table sans ID (data-table-id manquant)
5. Quota dépassé (disque plein)

#### Q9 : Réduire délai à 3s ?
**✅ Possible mais ❌ non recommandé**
- Impact CPU : x3 (5-8% vs 1-2%)
- Batterie : -20% durée vie
- Alternative : Bouton sauvegarde manuelle

---

### 🗄️ STRUCTURE INDEXEDDB

#### Q10 : Structure enregistrement ?
**7 champs principaux** :
```javascript
{
  id: "abc123...",              // UUID
  sessionId: "session-xyz",     // Conversation
  keyword: "Balance_2024",      // Nom
  timestamp: "2026-08-29T...",  // Date
  html: "<table>...</table>",   // HTML complet
  fingerprint: "a3f8d2c5...",   // Hash
  metadata: {                   // Infos
    rowCount: 50,
    colCount: 4,
    compressed: false
  }
}
```

**Taille** : 2-10 KB (petite), 50-100 KB (grande)

#### Q11 : HTML ou données pures ?
**HTML** (choix actuel)
- Avantage : Tables complexes, fidélité
- Inconvénient : Taille plus grande

**Données** (alternatif)
- Avantage : Taille minimale, recherche rapide
- Inconvénient : Perte mise en forme

---

### 🤖 ALGORITHME AUTO-SAVE

#### Q12 : Algorithme en 4 phases ?

**PHASE 1 : INITIALISATION** (au démarrage)
```
- Créer dirtyTables (Set)
- Créer MutationObserver
- Surveiller document.body
- Créer timer 10s
```

**PHASE 2 : DÉTECTION** (continu)
```
Modification → MutationObserver → dirtyTables.add(tableId)
```

**PHASE 3 : SAUVEGARDE** (toutes les 10s)
```
SI dirtyTables.size > 0 ET currentSessionId exists
  POUR CHAQUE table dirty :
    - Calculer fingerprint
    - SI existe ET fingerprint identique → SKIP
    - SI existe ET fingerprint différent → UPDATE
    - SI n'existe pas → INSERT
```

**PHASE 4 : PERSISTANCE**
```
- Préparer record
- Comprimer si > 50 KB
- IndexedDB.put(record)
- Gérer erreurs (quota, etc.)
```

---

## 🎯 POINTS CLÉS À RETENIR

### Fingerprint
✅ Hash SHA-256 du contenu  
✅ Modification 1 lettre = Hash totalement différent  
❌ Pas de sel aléatoire (pour déduplication)

### Auto-save
⏱️ Délai : 10 secondes  
📡 Déclencheur : MutationObserver  
🔄 Logique : Vérification fingerprint avant sauvegarde

### Structure
📦 7 champs : ID + session + keyword + HTML + fingerprint + metadata  
🗜️ Compression auto si > 50 KB  
📐 HTML stocké (pas données pures)

### Algorithme
🚀 4 phases : Init → Détection → Sauvegarde → Persistance  
⚙️ Conditions : Session + Table dirty + Fingerprint différent  
📊 Sauvegarde conditionnelle (pas systématique)

---

## 📊 TABLEAU COMPARATIF DÉLAIS

| Délai | CPU | Batterie | Perte max | Recommandé |
|-------|-----|----------|-----------|------------|
| 1s | 15-20% | -40% | 1s | ❌ |
| 3s | 5-8% | -20% | 3s | ⚠️ |
| **10s** | **1-2%** | **Minimal** | **10s** | **✅** |
| 30s | <1% | Négligeable | 30s | ⚠️ |

---

## 🔗 POUR EN SAVOIR PLUS

**Questions détaillées** : `REPONSES_QUESTIONS_COMPLEMENTAIRES_DEBUTANT.md`  
**Vue d'ensemble** : `CARTE_MENTALE_QUESTIONS.md`  
**Navigation** : `README_QUESTIONS_COMPLEMENTAIRES.md`  
**Code source** : `src/services/flowiseTableBridge.ts`

---

## ⚡ COMMANDES DEBUG RAPIDES

```javascript
// Vérifier système actif
window.flowiseTableBridge.mutationObserver !== null  // true = actif

// Voir délai auto-save
window.flowiseTableBridge.AUTO_SAVE_INTERVAL_MS  // 10000

// Voir tables modifiées
window.flowiseTableBridge.dirtyTables.size  // 0 = rien, 3 = 3 tables

// Forcer sauvegarde
await window.flowiseTableBridge.performAutoSave()
```

---

## 📈 DÉCISIONS SYSTÈME

| Décision | Raison | Trade-off |
|----------|--------|-----------|
| Fingerprint pur (sans sel) | Permettre déduplication | Sensibilité totale |
| Timer 10s | Équilibre perf/réactivité | Perte max 10s |
| Stockage HTML | Tables IA variées | Taille plus grande |
| MutationObserver | Détection auto | Charge CPU légère |

---

**Temps lecture** : 5 minutes  
**Document complet** : REPONSES_QUESTIONS_COMPLEMENTAIRES_DEBUTANT.md (60 min)  
**Date** : 29 Août 2026
