# =========================================
# SCANNER DE REDE GUI - VERSÃO CORRIGIDA
# Compatível com PS1 e EXE (ps2exe)
# =========================================

# FORÇAR STA (CRÍTICO)
if ([Threading.Thread]::CurrentThread.ApartmentState -ne 'STA') {
    powershell -sta -File $PSCommandPath
    exit
}

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# =========================================
# FORM
# =========================================

$form = New-Object System.Windows.Forms.Form
$form.Text = "🔍 Scanner de Rede Profissional"
$form.Size = New-Object System.Drawing.Size(860,560)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = "FixedDialog"
$form.MaximizeBox = $false

$font = New-Object System.Drawing.Font("Segoe UI",10)

# =========================================
# LABELS
# =========================================

function New-Label($text,$x,$y){
    $l = New-Object System.Windows.Forms.Label
    $l.Text = $text
    $l.Location = "$x,$y"
    $l.Font = $font
    $l.AutoSize = $true
    $l
}

$form.Controls.Add((New-Label "IP Inicial:" 15 15))
$form.Controls.Add((New-Label "IP Final:" 15 45))
$form.Controls.Add((New-Label "Portas TCP (ex: 22,80,443):" 15 75))

# =========================================
# INPUTS
# =========================================

$txtStart = New-Object System.Windows.Forms.TextBox
$txtStart.Location = "190,12"
$txtStart.Width = 150
$txtStart.Text = "192.168.1.1"

$txtEnd = New-Object System.Windows.Forms.TextBox
$txtEnd.Location = "190,42"
$txtEnd.Width = 150
$txtEnd.Text = "192.168.1.254"

$txtPorts = New-Object System.Windows.Forms.TextBox
$txtPorts.Location = "190,72"
$txtPorts.Width = 260
$txtPorts.Text = "22,80,443,3389"

$form.Controls.AddRange(@($txtStart,$txtEnd,$txtPorts))

# =========================================
# BOTÕES
# =========================================

$btnScan = New-Object System.Windows.Forms.Button
$btnScan.Text = "▶ Iniciar Scan"
$btnScan.Location = "480,20"
$btnScan.Size = "160,40"

$btnExport = New-Object System.Windows.Forms.Button
$btnExport.Text = "💾 Exportar CSV"
$btnExport.Location = "650,20"
$btnExport.Size = "160,40"

$form.Controls.AddRange(@($btnScan,$btnExport))

# =========================================
# PROGRESS BAR
# =========================================

$progress = New-Object System.Windows.Forms.ProgressBar
$progress.Location = "15,110"
$progress.Size = "810,20"

$form.Controls.Add($progress)

# =========================================
# LISTVIEW (CORRIGIDO – SEM DisplayIndex BUG)
# =========================================

$list = New-Object System.Windows.Forms.ListView
$list.Location = "15,145"
$list.Size = "810,360"
$list.View = "Details"
$list.FullRowSelect = $true
$list.GridLines = $true
$list.HideSelection = $false

# COLUNAS (FORMA CORRETA PARA EXE)
$colIP = New-Object System.Windows.Forms.ColumnHeader
$colIP.Text = "IP"
$colIP.Width = 140

$colHost = New-Object System.Windows.Forms.ColumnHeader
$colHost.Text = "Hostname"
$colHost.Width = 220

$colStatus = New-Object System.Windows.Forms.ColumnHeader
$colStatus.Text = "Status"
$colStatus.Width = 90

$colPorts = New-Object System.Windows.Forms.ColumnHeader
$colPorts.Text = "Portas Abertas"
$colPorts.Width = 330

$list.Columns.AddRange(@(
    $colIP,
    $colHost,
    $colStatus,
    $colPorts
))

$form.Controls.Add($list)

# =========================================
# FUNÇÕES
# =========================================

function Test-IP($ip){
    Test-Connection -ComputerName $ip -Count 1 -Quiet -ErrorAction SilentlyContinue
}

function Get-Hostname($ip){
    try { [System.Net.Dns]::GetHostEntry($ip).HostName }
    catch { "" }
}

function Test-Port($ip,$port){
    try{
        $client = New-Object System.Net.Sockets.TcpClient
        $iar = $client.BeginConnect($ip,$port,$null,$null)
        $ok = $iar.AsyncWaitHandle.WaitOne(200,$false)
        $client.Close()
        $ok
    }catch{ $false }
}

# =========================================
# EVENTO SCAN
# =========================================

$btnScan.Add_Click({

    $list.Items.Clear()

    $startParts = $txtStart.Text.Split(".")
    $endParts   = $txtEnd.Text.Split(".")

    $baseIP = "$($startParts[0]).$($startParts[1]).$($startParts[2])"
    $start = [int]$startParts[3]
    $end   = [int]$endParts[3]

    $ports = $txtPorts.Text -split "," | ForEach-Object { $_.Trim() }

    $ips = @()
    for ($i = $start; $i -le $end; $i++) {
        $ips += "$baseIP.$i"
    }

    $progress.Value = 0
    $progress.Maximum = $ips.Count

    foreach ($ip in $ips) {

        $progress.Value++
        [System.Windows.Forms.Application]::DoEvents()

        if (Test-IP $ip) {

            $hostname = Get-Hostname $ip
            $openPorts = @()

            foreach ($p in $ports) {
                if (Test-Port $ip $p) {
                    $openPorts += $p
                }
            }

            $item = New-Object System.Windows.Forms.ListViewItem($ip)
            $item.SubItems.Add($hostname)
            $item.SubItems.Add("Ativo")
            $item.SubItems.Add(($openPorts -join ", "))

            $list.Items.Add($item)
        }
    }
})

# =========================================
# EXPORTAR CSV
# =========================================

$btnExport.Add_Click({
    if ($list.Items.Count -eq 0) { return }

    $dlg = New-Object System.Windows.Forms.SaveFileDialog
    $dlg.Filter = "CSV (*.csv)|*.csv"

    if ($dlg.ShowDialog() -eq "OK") {

        $data = foreach ($item in $list.Items) {
            [PSCustomObject]@{
                IP       = $item.Text
                Hostname = $item.SubItems[1].Text
                Status   = $item.SubItems[2].Text
                Portas   = $item.SubItems[3].Text
            }
        }

        $data | Export-Csv $dlg.FileName -NoTypeInformation -Encoding UTF8
    }
})

# =========================================
$form.ShowDialog()
