# ================================================================
# Script de Push ClaraVerse V3 - Commits Multiples
# Version: V23 - 09 Mars 2026 - Persistance No Isolation Chat OK V3
# Repository: https://github.com/sekadalle2024/Claraverse_v_23_03_09-2026_persistance_no_isolation_chat_ok_V3.git
# Solution: Division en commits < 30 MB chacun
# ================================================================

Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host "  Push ClaraVerse V3 - Commits Multiples                        " -ForegroundColor Cyan
Write-Host "  Solution pour projet > 90 MB                                   " -ForegroundColor Cyan
Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host ""

$repoUrl = "https://github.com/sekadalle2024/Claraverse_v_23_03_09-2026_persistance_no_isolation_chat_ok_V3.git"
$branche = "main"

# Fonction pour push avec retry
function Push-WithRetry {
    param(
        [string]$message,
        [int]$maxRetries = 3
    )
    
    $retry = 0
    while ($retry -lt $maxRetries) {
        Write-Host "  Push tentative $($retry + 1)/$maxRetries..." -ForegroundColor Gray
        
        $pushOutput = git push -u origin $branche 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "  ✓ Push reussi: $message" -ForegroundColor Green
            return $true
        }
        
        Write-Host "  Erreur: $pushOutput" -ForegroundColor Red
        
        $retry++
        if ($retry -lt $maxRetries) {
            Write-Host "  Nouvelle tentative dans 10 secondes..." -ForegroundColor Yellow
            Start-Sleep -Seconds 10
        }
    }
    
    Write-Host "  ✗ Push echoue apres $maxRetries tentatives" -ForegroundColor Red
    return $false
}

# Etape 1: Verifier le commit existant
Write-Host "1. Verification du commit existant..." -ForegroundColor Yellow
$lastCommit = git log -1 --oneline
Write-Host "  Dernier commit: $lastCommit" -ForegroundColor Gray

# Etape 2: Annuler le gros commit (garder les fichiers)
Write-Host ""
Write-Host "2. Annulation du gros commit (fichiers conserves)..." -ForegroundColor Yellow
git reset --soft HEAD~1
Write-Host "  ✓ Commit annule, fichiers conserves dans staging" -ForegroundColor Green

# Etape 3: Configuration Git optimale
Write-Host ""
Write-Host "3. Configuration Git optimale..." -ForegroundColor Yellow
git config core.compression 0
git config http.postBuffer 1048576000
git config http.lowSpeedTime 999999
git config http.lowSpeedLimit 0
Write-Host "  ✓ Configuration appliquee" -ForegroundColor Green

# Etape 4: Vérifier le remote
Write-Host ""
Write-Host "4. Verification du repository distant..." -ForegroundColor Yellow
$currentRemote = git remote get-url origin
Write-Host "  Repository: $currentRemote" -ForegroundColor Gray

Write-Host ""
Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host "  DEBUT DU PUSH EN 6 PARTIES                                    " -ForegroundColor Cyan
Write-Host "=================================================================" -ForegroundColor Cyan

# Partie 1: Code Source React/TypeScript (src/)
Write-Host ""
Write-Host "Partie 1/6: Code Source React/TypeScript..." -ForegroundColor Cyan
git reset HEAD . 2>&1 | Out-Null
git add src/ 2>&1 | Out-Null
$commitResult = git commit -m "ClaraVerse V3 - Partie 1/6: Code Source React/TypeScript" 2>&1
if ($commitResult -notmatch "nothing to commit") {
    Write-Host "  ✓ Commit cree" -ForegroundColor Green
    if (-not (Push-WithRetry "Code Source")) {
        Write-Host ""
        Write-Host "ECHEC - Utilisez GitHub Desktop comme alternative" -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "  - Aucun changement" -ForegroundColor Gray
}

# Partie 2: Backend Python (py_backend/)
Write-Host ""
Write-Host "Partie 2/6: Backend Python..." -ForegroundColor Cyan
git add py_backend/ 2>&1 | Out-Null
$commitResult = git commit -m "ClaraVerse V3 - Partie 2/6: Backend Python" 2>&1
if ($commitResult -notmatch "nothing to commit") {
    Write-Host "  ✓ Commit cree" -ForegroundColor Green
    if (-not (Push-WithRetry "Backend Python")) {
        Write-Host ""
        Write-Host "ECHEC" -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "  - Aucun changement" -ForegroundColor Gray
}

# Partie 3: Fichiers Publics (public/)
Write-Host ""
Write-Host "Partie 3/6: Fichiers Publics..." -ForegroundColor Cyan
git add public/ 2>&1 | Out-Null
$commitResult = git commit -m "ClaraVerse V3 - Partie 3/6: Fichiers Publics" 2>&1
if ($commitResult -notmatch "nothing to commit") {
    Write-Host "  ✓ Commit cree" -ForegroundColor Green
    if (-not (Push-WithRetry "Fichiers Publics")) {
        Write-Host ""
        Write-Host "ECHEC" -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "  - Aucun changement" -ForegroundColor Gray
}

# Partie 4: Documentation Systeme Persistance
Write-Host ""
Write-Host "Partie 4/6: Documentation Systeme Persistance..." -ForegroundColor Cyan
git add "Doc Systeme persistance chat/" 2>&1 | Out-Null
$commitResult = git commit -m "ClaraVerse V3 - Partie 4/6: Documentation Systeme Persistance" 2>&1
if ($commitResult -notmatch "nothing to commit") {
    Write-Host "  ✓ Commit cree" -ForegroundColor Green
    if (-not (Push-WithRetry "Documentation Persistance")) {
        Write-Host ""
        Write-Host "ECHEC" -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "  - Aucun changement" -ForegroundColor Gray
}

# Partie 5: Autres documentations
Write-Host ""
Write-Host "Partie 5/6: Autres documentations..." -ForegroundColor Cyan
git add "Doc menu demarrer/" "Doc export rapport/" "Doc_Lead_Balance/" "Doc_Etat_Fin/" "Doc papier de travail javascript/" "Doc_Github_Issue/" "Doc Koyeb deploy/" "Doc backend github/" "deploiement-netlify/" "Doc cross ref documentaire menu/" 2>&1 | Out-Null
$commitResult = git commit -m "ClaraVerse V3 - Partie 5/6: Autres documentations" 2>&1
if ($commitResult -notmatch "nothing to commit") {
    Write-Host "  ✓ Commit cree" -ForegroundColor Green
    if (-not (Push-WithRetry "Autres documentations")) {
        Write-Host ""
        Write-Host "ECHEC" -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "  - Aucun changement" -ForegroundColor Gray
}

# Partie 6: Configuration et fichiers restants
Write-Host ""
Write-Host "Partie 6/6: Configuration et fichiers restants..." -ForegroundColor Cyan
git add . 2>&1 | Out-Null
$commitResult = git commit -m "ClaraVerse V3 - Partie 6/6: Configuration et fichiers divers" 2>&1
if ($commitResult -notmatch "nothing to commit") {
    Write-Host "  ✓ Commit cree" -ForegroundColor Green
    if (-not (Push-WithRetry "Configuration")) {
        Write-Host ""
        Write-Host "ECHEC" -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "  - Aucun changement" -ForegroundColor Gray
}

Write-Host ""
Write-Host "=================================================================" -ForegroundColor Green
Write-Host "           PUSH TERMINE AVEC SUCCES !                           " -ForegroundColor Green
Write-Host "=================================================================" -ForegroundColor Green
Write-Host ""
Write-Host "Verification finale..." -ForegroundColor Yellow
git status
Write-Host ""
Write-Host "Repository GitHub V3:" -ForegroundColor Cyan
Write-Host "   $repoUrl" -ForegroundColor White
Write-Host ""
