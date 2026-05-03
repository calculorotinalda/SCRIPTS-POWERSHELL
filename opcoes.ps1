function Show-Menu {
    Clear-Host
    Write-Host "===== FERRAMENTAS DE MANUTENÇÃO =====" -ForegroundColor Cyan
    Write-Host "1. Limpar cache do Windows e Google Chrome"
    Write-Host "2. Corrigir problemas de rede e firewall"
    Write-Host "3. Localizar ficheiros grandes (>512MB)"
    Write-Host "4. Verificar IPs na rede"
    Write-Host "5. Remover ficheiros temporários"
    Write-Host "0. Sair"
    Write-Host "====================================="
}

function Limpar-Cache {
    Write-Host "A limpar cache do Windows..." -ForegroundColor Yellow
    
    ipconfig /flushdns
    Clear-DnsClientCache

    Write-Host "A limpar cache do Google Chrome..." -ForegroundColor Yellow

    $chromeCachePaths = @(
        "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Cache",
        "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Code Cache",
        "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\GPUCache"
    )

    foreach ($path in $chromeCachePaths) {
        if (Test-Path $path) {
            Remove-Item "$path\*" -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    Write-Host "Cache limpa com sucesso!" -ForegroundColor Green
    Pause
}

function Corrigir-Rede {
    Write-Host "A corrigir problemas de rede..." -ForegroundColor Yellow

    netsh advfirewall reset
    netsh int ip reset
    netsh winsock reset

    Write-Host "Comandos executados. Reinicie o PC para aplicar todas as alterações." -ForegroundColor Green
    Pause
}

function Procurar-FicheirosGrandes {
    Write-Host "A procurar ficheiros maiores que 512MB..." -ForegroundColor Yellow

    $limit = 512MB

    Get-ChildItem -Path C:\ -Recurse -ErrorAction SilentlyContinue |
        Where-Object { $_.Length -gt $limit } |
        Select-Object FullName, @{Name="Tamanho(MB)";Expression={[math]::Round($_.Length / 1MB,2)}} |
        Sort-Object "Tamanho(MB)" -Descending |
        Format-Table -AutoSize

    Pause
}

function Scan-Rede {
    Write-Host "A verificar IPs na rede..." -ForegroundColor Yellow

    $baseIP = (Get-NetIPAddress -AddressFamily IPv4 |
               Where-Object {$_.IPAddress -notlike "169.*" -and $_.IPAddress -notlike "127.*"} |
               Select-Object -First 1).IPAddress

    if (!$baseIP) {
        Write-Host "Não foi possível detectar a rede." -ForegroundColor Red
        Pause
        return
    }

    $subnet = $baseIP.Substring(0, $baseIP.LastIndexOf(".") + 1)

    Write-Host "A fazer scan à rede: $subnet" -ForegroundColor Cyan

    1..254 | ForEach-Object {
        $ip = "$subnet$_"
        if (Test-Connection -ComputerName $ip -Count 1 -Quiet -ErrorAction SilentlyContinue) {
            Write-Host "Ativo: $ip" -ForegroundColor Green
        }
    }

    Pause
}

function Limpar-Temp {
    Write-Host "A remover ficheiros temporários..." -ForegroundColor Yellow

    $paths = @(
        "$env:TEMP\*",
        "C:\Windows\Temp\*",
        "C:\Windows\Prefetch\*"
    )

    foreach ($path in $paths) {
        if (Test-Path $path) {
            Remove-Item $path -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    Write-Host "Ficheiros temporários removidos!" -ForegroundColor Green
    Pause
}

# LOOP PRINCIPAL
do {
    Show-Menu
    $opcao = Read-Host "Escolha uma opção"

    switch ($opcao) {
        "1" { Limpar-Cache }
        "2" { Corrigir-Rede }
        "3" { Procurar-FicheirosGrandes }
        "4" { Scan-Rede }
        "5" { Limpar-Temp }
        "0" { break }
        default { Write-Host "Opção inválida!" -ForegroundColor Red; Pause }
    }

} while ($opcao -ne "0")