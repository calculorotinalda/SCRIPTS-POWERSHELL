# ==============================
# PS1 ➜ EXE GUI CONVERTER (FIXED)
# ==============================

# FORÇAR STA (CRÍTICO)
if ([Threading.Thread]::CurrentThread.ApartmentState -ne 'STA') {
    powershell -sta -File $PSCommandPath
    exit
}

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Verificar / instalar PS2EXE
try {
    if (-not (Get-Module -ListAvailable -Name ps2exe)) {
        Install-Module ps2exe -Scope CurrentUser -Force -AllowClobber
    }
    Import-Module ps2exe -Force
}
catch {
    [System.Windows.Forms.MessageBox]::Show(
        "Erro ao instalar/importar PS2EXE:`n$($_.Exception.Message)",
        "Erro crítico",[System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Error
    )
    exit
}

# ==============================
# GUI
# ==============================

$form = New-Object System.Windows.Forms.Form
$form.Text = "PS1 → EXE Converter (PRO)"
$form.Size = New-Object System.Drawing.Size(560,380)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = "FixedDialog"
$form.MaximizeBox = $false

$font = New-Object System.Drawing.Font("Segoe UI",10)

function New-Label($text,$x,$y){
    $l = New-Object System.Windows.Forms.Label
    $l.Text = $text
    $l.Location = "$x,$y"
    $l.Font = $font
    $l
}

$form.Controls.Add((New-Label "Ficheiro PS1:" 20 30))
$form.Controls.Add((New-Label "Ícone (.ico) opcional:" 20 100))
$form.Controls.Add((New-Label "Destino EXE:" 20 170))

$txtPs1  = New-Object System.Windows.Forms.TextBox
$txtIcon = New-Object System.Windows.Forms.TextBox
$txtOut  = New-Object System.Windows.Forms.TextBox

$txtPs1.Location  = "20,55"
$txtIcon.Location = "20,125"
$txtOut.Location  = "20,195"

$txtPs1.Width = $txtIcon.Width = $txtOut.Width = 380

$form.Controls.AddRange(@($txtPs1,$txtIcon,$txtOut))

function New-Button($text,$x,$y){
    $b = New-Object System.Windows.Forms.Button
    $b.Text = $text
    $b.Location = "$x,$y"
    $b
}

$btnPs1  = New-Button "Selecionar" 420 55
$btnIcon = New-Button "Selecionar" 420 125
$btnOut  = New-Button "Selecionar" 420 195

$form.Controls.AddRange(@($btnPs1,$btnIcon,$btnOut))

$btnConvert = New-Object System.Windows.Forms.Button
$btnConvert.Text = "🚀 Converter para EXE"
$btnConvert.Size = "240,45"
$btnConvert.Location = "160,260"
$btnConvert.BackColor = [System.Drawing.Color]::FromArgb(0,120,215)
$btnConvert.ForeColor = "White"
$btnConvert.FlatStyle = "Flat"
$btnConvert.Font = New-Object System.Drawing.Font("Segoe UI",11,[System.Drawing.FontStyle]::Bold)
$form.Controls.Add($btnConvert)

# ==============================
# EVENTOS
# ==============================

$btnPs1.Add_Click({
    $dlg = New-Object System.Windows.Forms.OpenFileDialog
    $dlg.Filter = "PowerShell (*.ps1)|*.ps1"
    if ($dlg.ShowDialog() -eq "OK") {
        $txtPs1.Text = $dlg.FileName
        $txtOut.Text = [System.IO.Path]::ChangeExtension($dlg.FileName,"exe")
    }
})

$btnIcon.Add_Click({
    $dlg = New-Object System.Windows.Forms.OpenFileDialog
    $dlg.Filter = "Ícones (*.ico)|*.ico"
    if ($dlg.ShowDialog() -eq "OK") { $txtIcon.Text = $dlg.FileName }
})

$btnOut.Add_Click({
    $dlg = New-Object System.Windows.Forms.SaveFileDialog
    $dlg.Filter = "Executável (*.exe)|*.exe"
    if ($dlg.ShowDialog() -eq "OK") { $txtOut.Text = $dlg.FileName }
})

$btnConvert.Add_Click({
    if (-not (Test-Path $txtPs1.Text)) {
        [System.Windows.Forms.MessageBox]::Show("Selecione um PS1 válido.","Aviso")
        return
    }

    try {
        $params = @{
            InputFile    = $txtPs1.Text
            OutputFile   = $txtOut.Text
            NoConsole    = $true
            STA          = $true
            x64          = $true
            RequireAdmin = $true
            NoError      = $true
        }

        if ($txtIcon.Text -and (Test-Path $txtIcon.Text)) {
            $params.IconFile = $txtIcon.Text
        }

        Invoke-ps2exe @params

        [System.Windows.Forms.MessageBox]::Show(
            "EXE criado com sucesso!`nCompatível com GUI e Scanner.",
            "Sucesso",[System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Information
        )
    }
    catch {
        [System.Windows.Forms.MessageBox]::Show($_.Exception.Message,"Erro")
    }
})

$form.ShowDialog()
