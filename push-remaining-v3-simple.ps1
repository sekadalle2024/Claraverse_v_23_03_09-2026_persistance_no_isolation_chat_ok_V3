# Push Remaining Files V3

function Push-Commit {
    param([string]$msg)
    
    for ($i = 1; $i -le 5; $i++) {
        Write-Host "Push tentative $i/5..." -ForegroundColor Yellow
        ipconfig /flushdns 2>&1 | Out-Null
        Start-Sleep -Seconds 3
        
        $result = git push origin fresh-v3:main 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host "SUCCESS!" -ForegroundColor Green
            return $true
        }
        
        if ($i -lt 5) { Start-Sleep -Seconds 20 }
    }
    
    Write-Host "FAILED after 5 attempts" -ForegroundColor Red
    return $false
}

Write-Host "=== PUSH REMAINING FILES V3 ===" -ForegroundColor Cyan
Write-Host ""

# Commit 3: public/
Write-Host "Commit 3: public/" -ForegroundColor Yellow
git add public/ 2>&1 | Out-Null
$c = git commit -m "V3 - Part 3: Fichiers publics" 2>&1
if ($c -notmatch "nothing to commit") {
    Write-Host "Commit created" -ForegroundColor Green
    if (-not (Push-Commit "public")) { exit 1 }
}

# Commit 4: index.html
Write-Host "`nCommit 4: index.html" -ForegroundColor Yellow
git add index.html 2>&1 | Out-Null
$c = git commit -m "V3 - Part 4: Index HTML" 2>&1
if ($c -notmatch "nothing to commit") {
    Write-Host "Commit created" -ForegroundColor Green
    if (-not (Push-Commit "index")) { exit 1 }
}

# Commit 5: py_backend/
Write-Host "`nCommit 5: py_backend/" -ForegroundColor Yellow
git add py_backend/ 2>&1 | Out-Null
$c = git commit -m "V3 - Part 5: Backend Python" 2>&1
if ($c -notmatch "nothing to commit") {
    Write-Host "Commit created" -ForegroundColor Green
    if (-not (Push-Commit "backend")) { exit 1 }
}

# Commit 6: Doc Systeme persistance
Write-Host "`nCommit 6: Doc Systeme persistance" -ForegroundColor Yellow
git add "Doc Systeme persistance chat/" 2>&1 | Out-Null
$c = git commit -m "V3 - Part 6: Doc Systeme persistance" 2>&1
if ($c -notmatch "nothing to commit") {
    Write-Host "Commit created" -ForegroundColor Green
    if (-not (Push-Commit "doc persistance")) { exit 1 }
}

# Commit 7-11: Autres docs
$docs = @(
    @{Path="Doc menu demarrer/"; Msg="V3 - Part 7: Doc menu demarrer"},
    @{Path="Doc export rapport/"; Msg="V3 - Part 8: Doc export rapport"},
    @{Path="Doc_Lead_Balance/"; Msg="V3 - Part 9: Doc Lead Balance"},
    @{Path="Doc_Etat_Fin/"; Msg="V3 - Part 10: Doc Etat Financier"},
    @{Path="Doc papier de travail javascript/"; Msg="V3 - Part 11: Doc papier travail"}
)

foreach ($doc in $docs) {
    Write-Host "`nCommit: $($doc.Path)" -ForegroundColor Yellow
    git add $doc.Path 2>&1 | Out-Null
    $c = git commit -m $doc.Msg 2>&1
    if ($c -notmatch "nothing to commit") {
        Write-Host "Commit created" -ForegroundColor Green
        if (-not (Push-Commit $doc.Path)) { exit 1 }
    }
}

# Commit 12: Doc Github
Write-Host "`nCommit 12: Doc Github Issue" -ForegroundColor Yellow
git add Doc_Github_Issue/ 2>&1 | Out-Null
$c = git commit -m "V3 - Part 12: Doc Github Issue" 2>&1
if ($c -notmatch "nothing to commit") {
    Write-Host "Commit created" -ForegroundColor Green
    if (-not (Push-Commit "github issue")) { exit 1 }
}

# Commit 13: Autres docs
Write-Host "`nCommit 13: Autres documentations" -ForegroundColor Yellow
git add "Doc Koyeb deploy/" "Doc backend github/" "deploiement-netlify/" "Doc cross ref documentaire menu/" 2>&1 | Out-Null
$c = git commit -m "V3 - Part 13: Autres documentations" 2>&1
if ($c -notmatch "nothing to commit") {
    Write-Host "Commit created" -ForegroundColor Green
    if (-not (Push-Commit "autres docs")) { exit 1 }
}

# Commit 14-16: Fichiers racine
Write-Host "`nCommit 14: Fichiers Markdown" -ForegroundColor Yellow
git add *.md 2>&1 | Out-Null
$c = git commit -m "V3 - Part 14: Fichiers Markdown" 2>&1
if ($c -notmatch "nothing to commit") {
    Write-Host "Commit created" -ForegroundColor Green
    if (-not (Push-Commit "markdown")) { exit 1 }
}

Write-Host "`nCommit 15: Fichiers texte" -ForegroundColor Yellow
git add *.txt 2>&1 | Out-Null
$c = git commit -m "V3 - Part 15: Fichiers texte" 2>&1
if ($c -notmatch "nothing to commit") {
    Write-Host "Commit created" -ForegroundColor Green
    if (-not (Push-Commit "txt")) { exit 1 }
}

Write-Host "`nCommit 16: Scripts PowerShell" -ForegroundColor Yellow
git add *.ps1 2>&1 | Out-Null
$c = git commit -m "V3 - Part 16: Scripts PowerShell" 2>&1
if ($c -notmatch "nothing to commit") {
    Write-Host "Commit created" -ForegroundColor Green
    if (-not (Push-Commit "ps1")) { exit 1 }
}

# Commit 17: Backup src/ restant
Write-Host "`nCommit 17: Fichiers src restants" -ForegroundColor Yellow
git add src/ 2>&1 | Out-Null
$c = git commit -m "V3 - Part 17: Fichiers src restants" 2>&1
if ($c -notmatch "nothing to commit") {
    Write-Host "Commit created" -ForegroundColor Green
    if (-not (Push-Commit "src backup")) { exit 1 }
}

# Commit 18: Tous fichiers restants
Write-Host "`nCommit 18: Tous fichiers restants" -ForegroundColor Yellow
git add . 2>&1 | Out-Null
$c = git commit -m "V3 - Part 18: Fichiers restants" 2>&1
if ($c -notmatch "nothing to commit") {
    Write-Host "Commit created" -ForegroundColor Green
    if (-not (Push-Commit "restants")) { exit 1 }
}

Write-Host ""
Write-Host "=== PUSH COMPLETE ===" -ForegroundColor Green
Write-Host ""
git status
Write-Host ""
Write-Host "Repository: https://github.com/sekadalle2024/Claraverse_v_23_03_09-2026_persistance_no_isolation_chat_ok_V3" -ForegroundColor Cyan
