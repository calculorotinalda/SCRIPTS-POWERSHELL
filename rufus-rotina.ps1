Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName System.Windows.Forms

# =======================
# ADMIN CHECK (CORRIGIDO)
# =======================
$principal = New-Object Security.Principal.WindowsPrincipal `
    ([Security.Principal.WindowsIdentity]::GetCurrent())

if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    [System.Windows.MessageBox]::Show(
        "Execute como ADMINISTRADOR",
        "Erro",
        [System.Windows.MessageBoxButton]::OK,
        [System.Windows.MessageBoxImage]::Error
    ) | Out-Null
    exit
}

# =======================
# XAML – Fluent Dark UI
# =======================
[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        Title="Rufus PowerShell Pro"
        Height="560" Width="820"
        WindowStartupLocation="CenterScreen"
        Background="#0f172a"
        Foreground="White">

<Grid Margin="20">
<Grid.RowDefinitions>
<RowDefinition Height="Auto"/>
<RowDefinition Height="Auto"/>
<RowDefinition Height="Auto"/>
<RowDefinition Height="*"/>
<RowDefinition Height="Auto"/>
</Grid.RowDefinitions>

<TextBlock Text="Rufus PowerShell Pro"
           FontSize="28"
           FontWeight="Bold"/>

<StackPanel Grid.Row="1" Margin="0,20,0,0">
<TextBlock Text="Dispositivo USB"/>
<ComboBox Name="UsbList" Height="36"/>
</StackPanel>

<StackPanel Grid.Row="2" Margin="0,15,0,0">
<TextBlock Text="Imagem ISO"/>
<DockPanel>
<TextBox Name="IsoPath" Height="36" Width="560"/>
<Button Name="BrowseIso" Content="Selecionar" Width="140" Margin="10,0,0,0"/>
</DockPanel>
</StackPanel>

<GroupBox Grid.Row="3" Header="Opções" Margin="0,20,0,0">
<StackPanel>
<CheckBox Name="AutoMode" Content="Detecção automática (UEFI / BIOS)" IsChecked="True"/>
<StackPanel Orientation="Horizontal" Margin="0,10,0,0">
<TextBlock Text="Sistema de ficheiros:" Margin="0,0,10,0"/>
<ComboBox Name="FsBox" Width="120">
<ComboBoxItem Content="FAT32"/>
<ComboBoxItem Content="NTFS"/>
</ComboBox>
</StackPanel>

<TextBox Name="LogBox"
         Margin="0,15,0,0"
         Height="160"
         Background="#020617"
         Foreground="#22c55e"
         IsReadOnly="True"
         VerticalScrollBarVisibility="Auto"/>
</StackPanel>
</GroupBox>

<StackPanel Grid.Row="4" Margin="0,20,0,0">
<ProgressBar Name="Progress" Height="20"/>
<Button Name="StartBtn"
        Content="CRIAR USB BOOTÁVEL"
        Height="46"
        FontSize="16"
        Margin="0,12,0,0"/>
</StackPanel>

</Grid>
</Window>
"@

# =======================
# LOAD WINDOW
# =======================
$reader = New-Object System.Xml.XmlNodeReader $xaml
$window = [Windows.Markup.XamlReader]::Load($reader)

# CONTROLS
$UsbList   = $window.FindName("UsbList")
$IsoPath  = $window.FindName("IsoPath")
$BrowseIso= $window.FindName("BrowseIso")
$StartBtn = $window.FindName("StartBtn")
$LogBox   = $window.FindName("LogBox")
$Progress = $window.FindName("Progress")
$FsBox    = $window.FindName("FsBox")

function Log {
    param($msg)
    $LogBox.AppendText("$msg`r`n")
    $LogBox.ScrollToEnd()
}

# =======================
# LOAD USB DISKS
# =======================
Get-Disk | Where-Object BusType -eq 'USB' | ForEach-Object {
    $UsbList.Items.Add("Disco $($_.Number) - $([math]::Round($_.Size/1GB)) GB")
}

$FsBox.SelectedIndex = 0

# =======================
# ISO PICKER
# =======================
$BrowseIso.Add_Click({
    $dlg = New-Object System.Windows.Forms.OpenFileDialog
    $dlg.Filter = "ISO (*.iso)|*.iso"
    if ($dlg.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $IsoPath.Text = $dlg.FileName
    }
})

# =======================
# START PROCESS
# =======================
$StartBtn.Add_Click({

    if (-not $UsbList.SelectedItem -or -not $IsoPath.Text) {
        [System.Windows.MessageBox]::Show("Selecione USB e ISO") | Out-Null
        return
    }

    $diskNumber = ($UsbList.SelectedItem -split " ")[1]
    $fs  = $FsBox.Text
    $iso = $IsoPath.Text

    $confirm = [System.Windows.MessageBox]::Show(
        "ESTE DISCO SERÁ FORMATADO. Continuar?",
        "Aviso",
        [System.Windows.MessageBoxButton]::YesNo,
        [System.Windows.MessageBoxImage]::Warning
    )

    if ($confirm -ne [System.Windows.MessageBoxResult]::Yes) { return }

    $Progress.Value = 5
    Log "Limpando disco..."
    Clear-Disk -Number $diskNumber -RemoveData -Confirm:$false

    Initialize-Disk -Number $diskNumber -PartitionStyle GPT
    $Progress.Value = 20

    Log "Criando partição..."
    $part = New-Partition -DiskNumber $diskNumber -UseMaximumSize -AssignDriveLetter

    Log "Formatando ($fs)..."
    Format-Volume -Partition $part -FileSystem $fs -NewFileSystemLabel "BOOT" -Confirm:$false

    $Progress.Value = 40
    Log "Montando ISO..."
    $isoMount  = Mount-DiskImage -ImagePath $iso -PassThru
    $isoLetter = (Get-Volume -DiskImage $isoMount).DriveLetter

    $Progress.Value = 60
    Log "Copiando arquivos..."
    Copy-Item "$($isoLetter):\*" "$($part.DriveLetter):\" -Recurse -Force

    Dismount-DiskImage -ImagePath $iso

    $Progress.Value = 100
    Log "✔ USB bootável criado com sucesso!"
})

$window.ShowDialog() | Out-Null
