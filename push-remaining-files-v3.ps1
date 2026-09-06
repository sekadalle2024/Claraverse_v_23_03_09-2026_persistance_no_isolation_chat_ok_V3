# ================================================================
# Script Auto Push Fichiers Restants - ClaraVerse V3
# ================================================================

function Push-WithRetry {
    param([int]$maxRetries = 5)
    
    for ($i = 1; $i -le $maxRetries; $i++) {
        Write-Host "  Tentative $i/$maxRetries..." -ForegroundColor Gray
        
        # Flush DNS avant chaque tentative
        ipconfig /flushdns 2>&1 | Out-Null
        Start-Sleep -Seconds 3
        
        $output = git push origin fresh-v3:main 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "  ✓ Push reussi!" -ForegroundColor Green
            return $true
        }
        
        Write-Host "  Echec..." -ForegroundColor Red
        
        if ($i -lt $maxRetries) {
            Write-Host "  Attente 20 secondes..." -ForegroundColor Yellow
            Start-Sleep -Seconds 20
        }
    }
    
    Write-Host "  ✗ Echec apres $maxRetries tentatives" -ForegroundColor Red
    return $false
}

Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host "  PUSH FICHIERS RESTANTS - CLARAVERSE V3                        " -ForegroundColor Cyan
Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host ""

# Vérifier l'état actuel
Write-Host "Etat actuel:" -ForegroundColor Yellow
git log --oneline -3
Write-Host ""

# Liste des commits à créer
$commits = @(
    @{Name="3: public/"; Files=@("public/"); Message="V3 - Part 3: Fichiers publics"},
    @{Name="4: index.html"; Files=@("index.html"); Message="V3 - Part 4: Index HTML"},
    @{Name="5: py_backend/"; Files=@("py_backend/"); Message="V3 - Part 5: Backend Python"},
    @{Name="6: Doc Systeme persistance"; Files=@("Doc Systeme persistance chat/"); Message="V3 - Part 6: Doc Systeme persistance"},
    @{Name="7: Doc menu"; Files=@("Doc menu demarrer/"); Message="V3 - Part 7: Doc menu demarrer"},
    @{Name="8: Doc export"; Files=@("Doc export rapport/"); Message="V3 - Part 8: Doc export rapport"},
    @{Name="9: Doc Lead Balance"; Files=@("Doc_Lead_Balance/"); Message="V3 - Part 9: Doc Lead Balance"},
    @{Name="10: Doc Etat Fin"; Files=@("Doc_Etat_Fin/"); Message="V3 - Part 10: Doc Etat Financier"},
    @{Name="11: Doc papier travail"; Files=@("Doc papier de travail javascript/"); Message="V3 - Part 11: Doc papier travail"},
    @{Name="12: Doc Github"; Files=@("Doc_Github_Issue/"); Message="V3 - Part 12: Doc Github Issue"},
    @{Name="13: Autres docs"; Files=@("Doc Koyeb deploy/", "Doc backend github/", "deploiement-netlify/", "Doc cross ref documentaire menu/"); Message="V3 - Part 13: Autres documentations"},
    @{Name="14: Fichiers racine *.md"; Files=@("*.md"); Message="V3 - Part 14: Fichiers Markdown"},
    @{Name="15: Fichiers racine *.txt"; Files=@("*.txt"); Message="V3 - Part 15: Fichiers texte"},
    @{Name="16: Scripts PS1"; Files=@("*.ps1"); Message="V3 - Part 16: Scripts PowerShell"},
    @{Name="17: Backup src/"; Files=@("src/"); Message="V3 - Part 17: Backup et fichiers src restants"},
    @{Name="18: Tous fichiers restants"; Files=@("."); Message="V3 - Part 18: Fichiers restants"}
)

$successCount = 0
$failCount = 0

foreach ($commit in $commits) {
    Write-Host ""
    Write-Host "=================================================================" -ForegroundColor Cyan
    Write-Host "  Commit $($commit.Name)" -ForegroundColor Cyan
    Write-Host "=================================================================" -ForegroundColor Cyan
    
    # Ajouter les fichiers
    $addSuccess = $true
    foreach ($file in $commit.Files) {
        git add $file 2>&1 | Out-Null
        if ($LASTEXITCODE -ne 0 -and $file -ne ".") {
            Write-Host "  Attention: Impossible d ajouter $file" -ForegroundColor Yellow
            $addSuccess = $false
        }
    }
    
    if (-not $addSuccess -and $commit.Name -notlike "*restants*") {
        Write-Host "  Aucun fichier à ajouter, passage au suivant" -ForegroundColor Gray
        continue
    }
    
    # Créer le commit
    $commitOutput = git commit -m $commit.Message 2>&1
    
    if ($commitOutput -match "nothing to commit") {
        Write-Host "  Aucun changement pour ce commit" -ForegroundColor Gray
        continue
    }
    
    Write-Host "  ✓ Commit cree: $($commit.Message)" -ForegroundColor Green
    
    # Push avec retry
    if (Push-WithRetry) {
        $successCount++
        Write-Host "  ✓ Push reussi pour: $($commit.Name)" -ForegroundColor Green
    } else {
        $failCount++
        Write-Host "  ✗ Push echoue pour: $($commit.Name)" -ForegroundColor Red
        Write-Host ""
        Write-Host "ARRET: Impossible de continuer" -ForegroundColor Red
        Write-Host "Utilisez GitHub Desktop pour finir le push" -ForegroundColor Yellow
        exit 1
    }
    
    # Pause entre les commits
    Start-Sleep -Seconds 5
}

Write-Host ""
Write-Host "=================================================================" -ForegroundColor Green
Write-Host "  RESUME DU PUSH                                                 " -ForegroundColor Green
Write-Host "=================================================================" -ForegroundColor Green
Write-Host "  Commits reussis: $successCount" -ForegroundColor Green
Write-Host "  Commits echoues: $failCount" -ForegroundColor $(if ($failCount -eq 0) { "Green" } else { "Red" })
Write-Host ""
Write-Host "Etat final:" -ForegroundColor Yellow
git status
Write-Host ""
Write-Host "Repository GitHub V3:" -ForegroundColor Cyan
Write-Host "  https://github.com/sekadalle2024/Claraverse_v_23_03_09-2026_persistance_no_isolation_chat_ok_V3" -ForegroundColor White
Write-Host ""
