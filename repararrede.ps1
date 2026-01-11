<#
.SYNOPSIS
Script de diagnóstico e reparo completo da conectividade de rede e HTTPS no Windows.

.DESCRIPTION
1️⃣ Reseta Winsock e TCP/IP
2️⃣ Limpa cache DNS e proxy
3️⃣ Reseta Firewall do Windows e libera tráfego de saída
4️⃣ Desativa temporariamente IPv6
5️⃣ Configura DNS confiáveis
6️⃣ Testa conectividade HTTP/HTTPS
7️⃣ Verifica filtros de antivírus ou drivers de captura

#>

Write-Host "=== SCRIPT DE REPARO DE REDE - INICIANDO ===`n" -ForegroundColor Cyan

# 1️⃣ Reset Winsock e TCP/IP
Write-Host "[1] Resetando Winsock e TCP/IP..." -ForegroundColor Yellow
netsh winsock reset
netsh int ip reset
Write-Host "✔ Winsock e TCP/IP resetados.`n" -ForegroundColor Green

# 2️⃣ Limpar DNS e proxy
Write-Host "[2] Limpando cache DNS e proxy..." -ForegroundColor Yellow
ipconfig /flushdns
netsh winhttp reset proxy
Write-Host "✔ Cache DNS e proxy limpos.`n" -ForegroundColor Green

# 3️⃣ Reset firewall e liberar saída HTTPS
Write-Host "[3] Resetando Firewall e liberando saída HTTPS..." -ForegroundColor Yellow
netsh advfirewall reset
Set-NetFirewallProfile -Profile Domain,Private,Public -DefaultOutboundAction Allow
netsh advfirewall firewall add rule name="Allow HTTPS Outbound" dir=out action=allow protocol=TCP remoteport=443
Write-Host "✔ Firewall resetado e HTTPS liberado.`n" -ForegroundColor Green

# 4️⃣ Desativar IPv6 temporariamente
Write-Host "[4] Desativando IPv6 temporariamente..." -ForegroundColor Yellow
$adapters = Get-NetAdapter | Where-Object {$_.Status -eq "Up"}
foreach ($a in $adapters) {
    Disable-NetAdapterBinding -Name $a.Name -ComponentID ms_tcpip6 -ErrorAction SilentlyContinue
}
Write-Host "✔ IPv6 desativado.`n" -ForegroundColor Green

# 5️⃣ Configurar DNS confiáveis (Google + Cloudflare)
Write-Host "[5] Configurando DNS confiáveis..." -ForegroundColor Yellow
foreach ($a in $adapters) {
    Set-DnsClientServerAddress -InterfaceAlias $a.Name -ServerAddresses ("8.8.8.8","1.1.1.1")
}
Write-Host "✔ DNS configurados.`n" -ForegroundColor Green

# 6️⃣ Teste de conectividade
Write-Host "[6] Testando conectividade HTTP/HTTPS..." -ForegroundColor Yellow

$testSites = @("google.com","api.nuget.org")
foreach ($site in $testSites) {
    Write-Host "`nTestando $site (porta 80 e 443):" -ForegroundColor Cyan
    Test-NetConnection $site -Port 80
    Test-NetConnection $site -Port 443
}

# 7️⃣ Verificar filtros de antivírus ou drivers de captura
Write-Host "`n[7] Verificando filtros de antivírus e drivers de captura..." -ForegroundColor Yellow
Get-NetAdapterBinding | Where-Object {$_.ComponentID -like "*filter*"} | Select-Object Name, ComponentID, Enabled

Write-Host "`n=== SCRIPT FINALIZADO ===" -ForegroundColor Cyan
Write-Host "⚠️ Se os testes de porta 80/443 ainda falharem, verifique antivírus, VPN, proxy ou rede bloqueada."
