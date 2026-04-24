# DELETOR FINAL - SEM ERROS DE SINTAXE
Clear-Host
Write-Host "=== DELETOR DE TAREFAS (UNICAS) ===" -ForegroundColor Green
Write-Host ""

# Lista UNICA de tarefas
$tarefasUnicas = @{}
$resultadoSchtasks = schtasks /query /fo LIST /v 2>$null
$linhasTarefa = $resultadoSchtasks | Select-String "^TaskName:"

foreach ($linha in $linhasTarefa) {
    $nomeTarefa = ($linha.Line -replace "^TaskName:\s*", "").Trim()
    if ($nomeTarefa -ne "" -and -not $tarefasUnicas.ContainsKey($nomeTarefa)) {
        $tarefasUnicas[$nomeTarefa] = $true
    }
}

$contador = 1
$listaNumerada = @{}
$tarefasUnicas.Keys | ForEach-Object {
    $listaNumerada[$contador] = $_
    Write-Host "$contador : $_" -ForegroundColor Cyan
    $contador++
}

Write-Host "`nTotal de tarefas UNICAS: $($contador-1)" -ForegroundColor Yellow

# Selecao
$selecionadas = @()
Write-Host "Exemplos: 1, 3-5, 1,4,7" -ForegroundColor Gray

while ($true) {
    $inputUser = Read-Host "`nDigite numeros (ou 'fim'): "
    if ($inputUser -eq "fim") { break }
    
    $partesInput = $inputUser -split ","
    $novosNums = @()
    
    foreach ($parte in $partesInput) {
        $parteLimpa = $parte.Trim()
        if ($parteLimpa -match "^(\d+)-(\d+)$") {
            $start = [int]$matches[1]
            $end = [int]$matches[2]
            for ($i = $start; $i -le $end; $i++) {
                if ($listaNumerada.ContainsKey($i) -and $selecionadas -notcontains $i) {
                    $novosNums += $i
                }
            }
        } elseif ($parteLimpa -match "^\d+$") {
            $num = [int]$parteLimpa
            if ($listaNumerada.ContainsKey($num) -and $selecionadas -notcontains $num) {
                $novosNums += $num
            }
        }
    }
    
    if ($novosNums.Count -gt 0) {
        $selecionadas += $novosNums
        Write-Host "Adicionado $($novosNums.Count) | Total: $($selecionadas.Count)" -ForegroundColor Green
    } else {
        Write-Host "Invalido!" -ForegroundColor Red
    }
}

if ($selecionadas.Count -eq 0) {
    Write-Host "Nada selecionado"
    Read-Host "Enter para sair"
    exit
}

# Confirmacao
Write-Host "`n=== A CONFIRMAR ===" -ForegroundColor Red
$listaFinal = @()
foreach ($numSel in $selecionadas) {
    $listaFinal += $listaNumerada[$numSel]
}

foreach ($tarefaFinal in $listaFinal) {
    Write-Host "  $tarefaFinal" -ForegroundColor Yellow
}

$confirmInput = Read-Host "`nDigite 'SIM' para DELETAR: "
if ($confirmInput -ne "SIM") {
    Write-Host "Cancelado"
    Read-Host "Enter para sair"
    exit
}

# EXECUCAO
Write-Host "`n=== DELETANDO ===" -ForegroundColor Red
$sucessos = 0
$naoEncontradas = 0

foreach ($tarefaUnica in $listaFinal | Select-Object -Unique) {
    Write-Host "$tarefaUnica ... " -NoNewline -ForegroundColor White
    $cmdResult = schtasks /delete /tn "`"$tarefaUnica`"" /f 2>&1
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "DELETADA" -ForegroundColor Green
        $sucessos++
    } else {
        Write-Host "NAO_ENCONTRADA" -ForegroundColor Gray
        $naoEncontradas++
    }
}

Write-Host "`n=== FINAL ===" -ForegroundColor Green
Write-Host "DELETADAS: $sucessos"
Write-Host "NAO_ENCONTRADAS: $naoEncontradas"
Read-Host "Enter para sair"
