# 🚫 MÉMO : Désactivation du système Provider LLM (Clara's Pocket)

**Date :** 29 août 2026  
**Auteur :** Kiro  
**Problème :** L'application affiche une erreur "Provider Not Responding - Clara's Pocket service is not available" bloquant l'utilisation  
**Cause :** Le système de vérification automatique du provider LLM (ancien système) est toujours actif  
**Solution :** Désactiver les vérifications automatiques du provider car les appels API se font désormais via les workflows n8n

---

## 🎯 CONTEXTE

L'application Claraverse utilise **désormais des workflows n8n** pour les appels API (dossier `src/services`), mais l'ancien système de provider LLM (Clara's Pocket) était encore actif en arrière-plan et tentait de vérifier la disponibilité du service au démarrage et avant chaque envoi de message.

### 🔴 Symptômes observés

1. **Popup d'erreur au démarrage** : "Provider Not Responding"
2. **Message d'erreur** : "Clara's Pocket service is not available"
3. **Impossibilité d'utiliser l'application** sans fermer le popup
4. **Blocage des messages** même avec workflows n8n fonctionnels

---

## ✅ CORRECTIONS APPLIQUÉES

### Fichier : `src/components/Clara_Components/clara_assistant_input.tsx`

#### 1️⃣ **Désactivation de la vérification AVANT envoi de message**

**Ligne ~3221** : Commenté la vérification du provider avant `handleSend()`

```typescript
// 🚫 DÉSACTIVÉ : Vérification provider (utilise workflows n8n maintenant)
// const isProviderHealthy = await checkProviderHealth();
// if (!isProviderHealthy) {
//   console.log('🟡 [INPUT] handleSend aborted: provider not healthy');
//   return; // Don't send message if provider is not healthy
// }
console.log('✅ [INPUT] Provider check DISABLED - using n8n workflows');
```

**Impact :**  
✅ Les messages peuvent être envoyés **sans vérifier** si Clara's Pocket est disponible  
✅ Les workflows n8n fonctionnent normalement  

#### 2️⃣ **Désactivation de la vérification AUTOMATIQUE au chargement**

**Ligne ~3633** : Commenté le `useEffect` qui vérifiait automatiquement le provider

```typescript
// 🚫 DÉSACTIVÉ : Vérification automatique du provider (utilise workflows n8n maintenant)
// useEffect(() => {
//   if (sessionConfig?.aiConfig?.provider) {
//     checkProviderHealth();
//   }
// }, [sessionConfig?.aiConfig?.provider, checkProviderHealth]);
console.log('✅ [INIT] Provider auto-check DISABLED - using n8n workflows');
```

**Impact :**  
✅ Plus de popup d'erreur au démarrage de l'application  
✅ L'application charge normalement sans vérifier Clara's Pocket  

---

## 🧪 TESTS À EFFECTUER

### Test 1 : Démarrage de l'application
```bash
npm run dev
```

**Résultat attendu :**  
✅ Aucun popup "Provider Not Responding"  
✅ Application charge normalement  
✅ Console affiche : `✅ [INIT] Provider auto-check DISABLED - using n8n workflows`

### Test 2 : Envoi d'un message
1. Ouvrir l'interface de chat
2. Taper un message
3. Cliquer "Envoyer"

**Résultat attendu :**  
✅ Message envoyé sans erreur  
✅ Workflow n8n appelé correctement  
✅ Console affiche : `✅ [INPUT] Provider check DISABLED - using n8n workflows`

### Test 3 : Workflows n8n opérationnels
Vérifier que les workflows continuent de fonctionner :

```typescript
// Dans src/services (ex: chatFlowService.ts)
// Les appels n8n doivent fonctionner normalement
await fetch('http://localhost:5678/webhook/...')
```

**Résultat attendu :**  
✅ Workflows n8n répondent correctement  
✅ Aucune dépendance au système provider LLM  

---

## 📋 CODE LEGACY NON MODIFIÉ (pour référence)

### Fonction `checkProviderHealth()` conservée

La fonction `checkProviderHealth()` (ligne ~3073) est **conservée mais non appelée**.

**Pourquoi la conserver ?**  
- Peut servir de référence si besoin de réactiver partiellement
- Évite de casser des imports/références dans d'autres fichiers
- Permet un rollback facile si nécessaire

**Fonction :** `checkProviderHealth()`, `handleStartClaraCore()`, `handleSwitchToClaraCore()`

### Autres fichiers NON modifiés

Ces fichiers contiennent du code lié à Clara's Pocket mais ne sont **pas modifiés** car non actifs :

- `src/db/index.ts` : Gestion BDD providers (inactive)
- `src/contexts/ProvidersContext.tsx` : Context providers (non utilisé)
- `src/components/Settings.tsx` : Panneau settings providers (non affiché)
- `src/services/claraNotebookService.ts` : Interface notebook (autre module)
- `src/utils/providerConfigStorage.ts` : Storage config (non appelé)

---

## 🔄 ARCHITECTURE ACTUELLE

### Ancien système (DÉSACTIVÉ)
```
Clara_Assistant_Input.tsx
     ↓
checkProviderHealth() → Clara's Pocket / Providers LLM
     ↓
Affiche erreur si indisponible
```

### Nouveau système (ACTIF)
```
Clara_Assistant_Input.tsx
     ↓
handleSend() (sans vérification provider)
     ↓
Services (src/services)
     ↓
Workflows n8n (http://localhost:5678/webhook/...)
```

---

## 🎯 COMMANDES DE LANCEMENT

### 🚀 Développement (mode dev)

#### Lancer l'application seule
```bash
npm run dev
```
**Utilisation :** Frontend uniquement (Vite dev server)  
**Port :** Par défaut 5173  
**Workflows n8n :** Doivent tourner séparément sur port 5678

#### Lancer l'application + backend Python
```bash
npm run dev:full
# OU
npm run start:all
```
**Utilisation :** Frontend (Vite) + Backend Python (py_backend/main.py)  
**Note :** Le backend Python n'est peut-être plus nécessaire si workflows n8n remplacent tout

---

### 🔨 Production (build)

#### Build seul
```bash
npm run build
```
**Résultat :** Génère le dossier `dist/` avec l'application compilée  
**Node memory :** Utilise `--max-old-space-size=8192` (8 Go RAM pour éviter crashes)

#### Build + Backend Python
```bash
npm run build:prod
```
**Résultat :** Build frontend + lance backend Python en mode production

#### Preview du build
```bash
npm run preview
```
**Utilisation :** Teste le build localement avant déploiement

#### Preview + Backend
```bash
npm run preview:full
```
**Utilisation :** Preview frontend + backend Python simultanément

---

### 🛠️ Scripts spéciaux

#### Rebuild (si existe)
```bash
npm run rebuild
```
**⚠️ ATTENTION :** Ce script n'existe **PAS** dans votre `package.json` actuel  
**Alternative :** Utiliser `npm run clean:install` pour réinstallation complète

#### Clean install (réinstallation complète)
```bash
npm run clean:install
```
**Action :**
1. Supprime `node_modules/`
2. Supprime `package-lock.json`
3. Réinstalle toutes les dépendances

---

### 🧪 Tests

#### Tests unitaires (single run)
```bash
npm run test
# OU
npm run test:ci
```

#### Tests en mode watch
```bash
npm run test:watch
```

#### Tests avec interface UI
```bash
npm run test:ui
```

#### Tests avec coverage
```bash
npm run test:coverage
```

---

### 🐳 Docker (si utilisé)

```bash
# Build image Docker
npm run docker:build

# Lancer conteneur Docker
npm run docker:run

# Build + Push vers registry
npm run docker:all
```

---

### ⚡ Backend Python séparé

Si vous devez lancer le backend Python manuellement :

```bash
cd py_backend
python main.py
```

**Note :** Vérifiez si ce backend est encore nécessaire avec les workflows n8n

---

## ⚠️ NOTES IMPORTANTES

### 1. Configuration `index.html`
Le fichier `index.html` n'a **pas été modifié** pour cette correction car :
- Il ne contient pas de code direct appelant Clara's Pocket
- Les scripts de diagnostic utilisent `clara_db` (IndexedDB) uniquement
- Aucun script inline n'initialise le système provider
- Les vérifications provider se font dans les composants React (TypeScript)

**Impact du précédent update index.html :**  
Lors d'une mise à jour précédente de `index.html`, aucun code lié au système provider LLM n'a été ajouté. Les modifications portaient uniquement sur :
- Scripts de diagnostic IndexedDB
- Scripts de persistance des tables (system auto-save)
- Hooks anti-doublons (FloTableDB → clara_db)

**Conclusion :** Le fichier `index.html` reste neutre vis-à-vis du système provider.

### 2. Workflows n8n
Les workflows dans `src/services` continuent de fonctionner **indépendamment** :
- `chatFlowService.ts`
- `flowiseTableBridge.ts`
- `flowiseTableService.ts`
- Tous les services utilisant `fetch()` vers n8n

### 3. Réactivation possible
Si besoin de réactiver Clara's Pocket :
1. Décommenter les lignes dans `clara_assistant_input.tsx`
2. Configurer un provider dans Settings
3. Relancer l'application

---

## 🔍 DÉBOGAGE

### Console logs ajoutés

#### Au chargement (initialisation)
```
✅ [INIT] Provider auto-check DISABLED - using n8n workflows
```

#### Avant envoi message
```
✅ [INPUT] Provider check DISABLED - using n8n workflows
```

### Vérifier les workflows n8n
```bash
# Console F12 → Network
# Filtrer : localhost:5678
# Vérifier les requêtes vers workflows
```

---

## 📦 FICHIERS MODIFIÉS

```
src/components/Clara_Components/clara_assistant_input.tsx
```

**Total :** 1 fichier  
**Lignes modifiées :** 2 blocs (commentés + logs ajoutés)

---

## ✅ VALIDATION

### Checklist de validation
- [ ] Application démarre sans popup d'erreur
- [ ] Messages peuvent être envoyés
- [ ] Workflows n8n répondent correctement
- [ ] Logs de désactivation visibles dans console
- [ ] Aucune régression sur autres fonctionnalités

### Retour en arrière (rollback)
Si problème, décommenter les lignes dans `clara_assistant_input.tsx` :

```typescript
// Restaurer ligne ~3221
const isProviderHealthy = await checkProviderHealth();
if (!isProviderHealthy) {
  return;
}

// Restaurer ligne ~3633
useEffect(() => {
  if (sessionConfig?.aiConfig?.provider) {
    checkProviderHealth();
  }
}, [sessionConfig?.aiConfig?.provider, checkProviderHealth]);
```

---

## 📚 DOCUMENTS ASSOCIÉS

- [LISTE_FICHIERS_SYSTEME_PERSISTANCE.md](./LISTE_FICHIERS_SYSTEME_PERSISTANCE.md) : Architecture persistance
- [00_MEMO_ARCHITECTURE_ISOLATION_CHATS_COMPLET.md](./00_MEMO_ARCHITECTURE_ISOLATION_CHATS_COMPLET.md) : Architecture isolation
- [00_BACKEND_REPARE_ET_OPERATIONNEL_04_AVRIL_2026.txt](../00_BACKEND_REPARE_ET_OPERATIONNEL_04_AVRIL_2026.txt) : Workflows n8n

---

## 📞 SUPPORT

En cas de problème :

1. **Vérifier console F12** : Logs de désactivation présents ?
2. **Vérifier workflows n8n** : Serveur actif sur port 5678 ?
3. **Vérifier services** : Fichiers dans `src/services` fonctionnels ?
4. **Rollback** : Restaurer code commenté si nécessaire

---

**FIN DU MÉMO**
