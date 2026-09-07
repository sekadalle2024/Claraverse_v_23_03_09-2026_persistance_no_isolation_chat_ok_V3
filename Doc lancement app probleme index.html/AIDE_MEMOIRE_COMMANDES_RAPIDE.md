# 🚀 AIDE-MÉMOIRE RAPIDE - Commandes Claraverse

## 📌 COMMANDES ESSENTIELLES

### Mode Développement

```powershell
# Méthode standard (RECOMMANDÉE)
npm run dev

# Méthode alternative
npx vite

# Avec exposition réseau
npx vite --host
```

**Résultat** : Serveur dev sur http://localhost:5173/

---

### Mode Production

```powershell
# Build complet avec nettoyage (RECOMMANDÉ)
.\REBUILD.ps1

# Build simple
npm run build

# Build + Preview
npm run build
npm run preview
```

---

## ⚙️ SCRIPT REBUILD.PS1

### ✅ TOUJOURS VALABLE

**Ce qu'il fait** :
1. Arrête processus Node
2. Supprime caches (`dist`, `.vite`)
3. Vérifie désactivation conso.js
4. Build production
5. Vérifie build compilé
6. Lance serveur dev

**Quand l'utiliser** :
- ✅ Avant déploiement
- ✅ Après modifs importantes
- ✅ En cas de comportement étrange
- ✅ Pour build propre garanti

**Aucune modification nécessaire** - Il détecte automatiquement les nouveaux fichiers.

---

## 📦 NOUVEAUX FICHIERS

### Créés le 29/08/2026

- ✅ `public/diagnostic-buttons.js` - Fonctions diagnostic (5 fonctions)
- ✅ Modification `index.html` - Simplification boutons onclick

### Scripts Existants

- ✅ `public/restore-lock-manager.js` - **Inchangé**
- ✅ `public/single-restore-on-load.js` - **Inchangé**
- ✅ `REBUILD.ps1` - **Toujours valable**

---

## 🔍 VÉRIFICATION RAPIDE

### Après Build

```powershell
# 1. Vérifier dossier dist existe
ls dist/

# 2. Lancer dev server
npm run dev

# 3. Ouvrir navigateur
# http://localhost:5173/
```

### Dans Console F12

```javascript
// Vérifier fonctions existent
typeof window.manualSave         // "function"
typeof window.searchTable        // "function"
```

---

## 🚨 EN CAS DE PROBLÈME

```powershell
# Nettoyage complet
Remove-Item -Recurse -Force dist
Remove-Item -Recurse -Force node_modules\.vite

# Rebuild
.\REBUILD.ps1
```

---

## 📊 CHANGEMENTS vs ANCIENNE VERSION

| Aspect | Avant | Après |
|--------|-------|-------|
| **Boutons HTML** | onclick inline 3000+ chars | onclick simple `window.searchTable()` |
| **Code JavaScript** | Dans index.html | Dans `/public/diagnostic-buttons.js` |
| **Build** | ❌ Échec parse5 | ✅ Réussi en 4m54s |
| **REBUILD.ps1** | ✅ Valable | ✅ Toujours valable |
| **Scripts existants** | Fonctionnels | ✅ Toujours fonctionnels |
| **Commandes** | Inchangées | ✅ Identiques |

---

## ✅ RÉSUMÉ

**Questions fréquentes** :

1. **REBUILD.ps1 toujours valable ?**  
   → ✅ **OUI** - Aucune modification nécessaire

2. **Anciennes commandes fonctionnent ?**  
   → ✅ **OUI** - `npm run dev`, `npm run build`, etc.

3. **Anciens scripts impactés ?**  
   → ✅ **NON** - restore-lock-manager.js et single-restore-on-load.js inchangés

4. **Nouveaux scripts changent quelque chose ?**  
   → ✅ **OUI** - Code plus propre et maintenable, mais comportement identique

---

**Voir mémo complet** : `MEMO_RESOLUTION_BUILD_HTML_29_AOUT_2026.md`
