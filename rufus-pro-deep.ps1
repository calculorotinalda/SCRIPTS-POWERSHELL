Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName WindowsBase

# =======================
# ADMIN CHECK
# =======================
$principal = New-Object Security.Principal.WindowsPrincipal ([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    [System.Windows.MessageBox]::Show("Execute como ADMINISTRADOR para acessar discos USB", "Privilégios Administrativos", "OK", "Error") | Out-Null
    exit
}

# =======================
# CONFIGURAÇÕES
# =======================
$Global:Theme = @{
    Primary = "#3b82f6"
    Secondary = "#10b981"
    Dark = "#0f172a"
    Darker = "#020617"
    Light = "#f8fafc"
    Danger = "#ef4444"
    Warning = "#f59e0b"
    Success = "#22c55e"
    Gray = "#64748b"
    GrayLight = "#94a3b8"
}

# =======================
# LOG SYSTEM
# =======================
$LogFile = "$PSScriptRoot\rufus_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"

function Write-Log {
    param(
        [string]$Message,
        [string]$Level = "INFO"
    )
    
    $timestamp = Get-Date -Format "HH:mm:ss.fff"
    $logEntry = "[$timestamp] [$Level] $Message"
    
    # Adiciona ao arquivo de log
    Add-Content -Path $LogFile -Value $logEntry -Force
    
    # Adiciona à interface com cores
    $colorCode = switch ($Level) {
        "SUCCESS" { "#22c55e" }
        "ERROR"   { "#ef4444" }
        "WARNING" { "#f59e0b" }
        "INFO"    { "#3b82f6" }
        default   { "#94a3b8" }
    }
    
    $icon = switch ($Level) {
        "SUCCESS" { "✓" }
        "ERROR"   { "✗" }
        "WARNING" { "⚠" }
        "INFO"    { "ℹ" }
        default   { "➤" }
    }
    
    # Cria um bloco de texto formatado
    $run = New-Object System.Windows.Documents.Run
    $run.Text = "$icon $Message`r`n"
    
    try {
        $color = [System.Windows.Media.Color]::FromArgb(255, 
            [byte]::Parse($colorCode.Substring(1,2), 'HexNumber'),
            [byte]::Parse($colorCode.Substring(3,2), 'HexNumber'),
            [byte]::Parse($colorCode.Substring(5,2), 'HexNumber')
        )
        $run.Foreground = New-Object System.Windows.Media.SolidColorBrush($color)
    }
    catch {
        $run.Foreground = [System.Windows.Media.Brushes]::White
    }
    
    $paragraph = New-Object System.Windows.Documents.Paragraph($run)
    $LogBox.Document.Blocks.Add($paragraph)
    $LogBox.ScrollToEnd()
}

# =======================
# HELPERS AVANÇADOS
# =======================
function Get-IsoType {
    param([string]$IsoPath)
    
    try {
        $mount = Mount-DiskImage $IsoPath -PassThru -ErrorAction Stop
        $volume = Get-Volume -DiskImage $mount
        $driveL = $volume.DriveLetter
        
        # Detecta tipo de ISO - Correção de Sintaxe aqui
        if ((Test-Path "$($driveL):\sources\install.wim") -or (Test-Path "$($driveL):\sources\install.esd")) {
            $type = "Windows"
        }
        elseif ((Test-Path "$($driveL):\casper") -or (Test-Path "$($driveL):\boot") -or (Test-Path "$($driveL):\isolinux")) {
            $type = "Linux"
        }
        else {
            $type = "Outro"
        }
        
        return [PSCustomObject]@{
            Type = $type
            DriveLetter = $driveL
        }
    }
    catch {
        Write-Log "Erro ao analisar ISO: $_" -Level "ERROR"
        return $null
    }
    finally {
        if ($mount) { 
            try { Dismount-DiskImage $IsoPath } catch {}
        }
    }
}

function Get-UsbDisks {
    Get-Disk | Where-Object { 
        $_.BusType -eq "USB" -and $_.Size -gt 0 
    } | ForEach-Object {
        [PSCustomObject]@{
            Number = $_.Number
            FriendlyName = $_.FriendlyName
            Model = $_.Model
            SizeGB = [math]::Round($_.Size / 1GB, 2)
            SizeBytes = $_.Size
            PartitionStyle = $_.PartitionStyle
        }
    }
}

# =======================
# XAML SIMPLIFICADO
# =======================
[xml]$xaml = @'
<Window 
    xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
    Title="Rufus PowerShell Pro"
    Height="750"
    Width="1000"
    WindowStartupLocation="CenterScreen"
    Background="#0f172a"
    ResizeMode="CanResizeWithGrip">

    <Grid Margin="15">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>
        
        <!-- HEADER -->
        <Border Grid.Row="0" Background="#1e293b" CornerRadius="10" Padding="15" Margin="0,0,0,10">
            <StackPanel>
                <StackPanel Orientation="Horizontal">
                    <TextBlock Text="⚡" FontSize="28" Margin="0,0,10,0"/>
                    <StackPanel>
                        <TextBlock Text="Rufus PowerShell Pro" FontSize="24" FontWeight="Bold" Foreground="#3b82f6"/>
                        <TextBlock Text="Criador de USB Bootável" FontSize="13" Foreground="#94a3b8"/>
                    </StackPanel>
                </StackPanel>
                
                <Grid Margin="0,10,0,0">
                    <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="*"/>
                        <ColumnDefinition Width="Auto"/>
                    </Grid.ColumnDefinitions>
                    
                    <ProgressBar 
                        x:Name="Progress" 
                        Height="8" 
                        Background="#334155"
                        Foreground="#10b981"/>
                    
                    <TextBlock 
                        x:Name="ProgressText"
                        Grid.Column="1" 
                        Text="0%" 
                        Margin="10,0,0,0"
                        FontWeight="Bold"
                        VerticalAlignment="Center"
                        Foreground="White"/>
                </Grid>
            </StackPanel>
        </Border>
        
        <!-- MAIN CONTENT -->
        <Grid Grid.Row="1">
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width="*"/>
                <ColumnDefinition Width="*"/>
            </Grid.ColumnDefinitions>
            
            <!-- LEFT COLUMN -->
            <StackPanel Grid.Column="0" Margin="0,0,5,0">
                <!-- ISO SELECTION -->
                <Border Background="#1e293b" CornerRadius="8" Padding="15" Margin="0,0,0,10">
                    <StackPanel>
                        <TextBlock Text="📁 Arquivo ISO" FontSize="16" FontWeight="Bold" Foreground="White" Margin="0,0,0,10"/>
                        
                        <ListBox 
                            x:Name="IsoList" 
                            Height="100" 
                            Background="#0f172a"
                            BorderThickness="1"
                            BorderBrush="#334155"
                            Foreground="White"/>
                        
                        <StackPanel Orientation="Horizontal" Margin="0,10,0,0">
                            <Button x:Name="AddIso" Content="Adicionar ISO" Background="#3b82f6" Margin="0,0,5,0" Padding="10,5"/>
                            <Button x:Name="RemoveIso" Content="Remover" Background="#64748b" Padding="10,5"/>
                            <Button x:Name="ClearIso" Content="Limpar" Background="#64748b" Margin="5,0,0,0" Padding="10,5"/>
                        </StackPanel>
                        
                        <TextBlock 
                            x:Name="IsoInfo"
                            Margin="0,10,0,0"
                            Foreground="#94a3b8"
                            FontSize="11"
                            TextWrapping="Wrap"/>
                    </StackPanel>
                </Border>
                
                <!-- USB SELECTION -->
                <Border Background="#1e293b" CornerRadius="8" Padding="15">
				<StackPanel>
					<TextBlock Text="💾 Dispositivo USB" FontSize="16" FontWeight="Bold" Foreground="White" Margin="0,0,0,10"/>
					
					<ComboBox 
						x:Name="UsbBox" 
						Height="35"
						Background="White"
						Foreground="Black"
						BorderThickness="1"
						BorderBrush="#334155"
						FontSize="13"/>
					
					<StackPanel Orientation="Horizontal" Margin="0,10,0,0">
						<Button x:Name="RefreshUsb" Content="Atualizar Lista" Background="#64748b" Margin="0,0,5,0" Padding="10,5"/>
						<Button x:Name="FormatUsb" Content="Formatar" Background="#f59e0b" Padding="10,5"/>
					</StackPanel>
					
					<Border Background="White" CornerRadius="4" Margin="0,10,0,0" Padding="5">
						<TextBlock 
							x:Name="UsbInfo"
							Foreground="Black"
							FontSize="11"
							TextWrapping="Wrap"/>
					</Border>
				</StackPanel>
			</Border>
            </StackPanel>
            
            <!-- RIGHT COLUMN -->
            <StackPanel Grid.Column="1" Margin="5,0,0,0">
                <!-- OPTIONS -->
                <Border Background="#1e293b" CornerRadius="8" Padding="15" Margin="0,0,0,10">
                    <StackPanel>
                        <TextBlock Text="⚙️ Configurações" FontSize="16" FontWeight="Bold" Foreground="White" Margin="0,0,0,10"/>
                        
                        <CheckBox 
                            x:Name="AutoMode" 
                            Content="Modo Automático (Recomendado)"
                            IsChecked="True"
                            Foreground="White"
                            FontWeight="SemiBold"
                            Margin="0,0,0,5"/>
                        
                        <TextBlock Text="Esquema de Partição:" Foreground="#94a3b8" Margin="0,10,0,5"/>
                        
                        <RadioButton 
                            x:Name="ModeUEFI" 
                            Content="UEFI (GPT + FAT32)"
                            GroupName="PartitionMode"
                            Foreground="White"
                            Margin="0,2"/>
                        <RadioButton 
                            x:Name="ModeBIOS" 
                            Content="BIOS (MBR + NTFS)"
                            GroupName="PartitionMode"
                            Foreground="White"
                            Margin="0,2"/>
                        <RadioButton 
                            x:Name="ModeHybrid" 
                            Content="Híbrido (UEFI + BIOS)"
                            GroupName="PartitionMode"
                            IsChecked="True"
                            Foreground="White"
                            Margin="0,2,0,10"/>
                        
                        <CheckBox 
                            x:Name="DDMode" 
                            Content="Linux DD Mode (RAW)"
                            Foreground="White"
                            Margin="0,0,0,5"/>
                            
                        <CheckBox 
                            x:Name="QuickFormat" 
                            Content="Formatação Rápida"
                            IsChecked="True"
                            Foreground="White"/>
                    </StackPanel>
                </Border>
                
                <!-- LOG -->
                <Border Background="#1e293b" CornerRadius="8" Padding="15" Height="250">
                    <Grid>
                        <Grid.RowDefinitions>
                            <RowDefinition Height="Auto"/>
                            <RowDefinition Height="*"/>
                            <RowDefinition Height="Auto"/>
                        </Grid.RowDefinitions>
                        
                        <TextBlock Text="📝 Log de Operações" FontSize="16" FontWeight="Bold" Foreground="White" Margin="0,0,0,10"/>
                        
                        <RichTextBox 
                            x:Name="LogBox"
                            Grid.Row="1"
                            Background="#0f172a"
                            BorderThickness="0"
                            Foreground="White"
                            FontFamily="Consolas"
                            FontSize="11"
                            IsReadOnly="True"
                            VerticalScrollBarVisibility="Auto"/>
                        
                        <StackPanel Grid.Row="2" Orientation="Horizontal" Margin="0,10,0,0">
                            <Button x:Name="ClearLog" Content="Limpar Log" Background="#64748b" Padding="10,5"/>
                            <Button x:Name="SaveLog" Content="Salvar Log" Background="#64748b" Margin="5,0,0,0" Padding="10,5"/>
                        </StackPanel>
                    </Grid>
                </Border>
            </StackPanel>
        </Grid>
        
        <!-- FOOTER -->
        <Border Grid.Row="2" Background="#1e293b" CornerRadius="8" Padding="15" Margin="0,10,0,0">
            <Grid>
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="Auto"/>
                </Grid.ColumnDefinitions>
                
                <StackPanel Orientation="Horizontal">
                    <TextBlock Text="🔒" Margin="0,0,5,0"/>
                    <StackPanel>
                        <TextBlock Text="Modo Administrador Ativo" FontWeight="SemiBold" Foreground="White"/>
                        <TextBlock Text="Pronto para criar USB bootável" Foreground="#94a3b8" FontSize="11"/>
                    </StackPanel>
                </StackPanel>
                
                <Button 
                    x:Name="StartBtn"
                    Grid.Column="1"
                    Content="INICIAR CRIAÇÃO DO USB"
                    Background="#10b981"
                    FontSize="13"
                    FontWeight="Bold"
                    Padding="30,10"
                    Foreground="White"/>
            </Grid>
        </Border>
    </Grid>
</Window>
'@

# =======================
# LOAD UI
# =======================
try {
    $reader = New-Object System.Xml.XmlNodeReader $xaml
    $window = [Windows.Markup.XamlReader]::Load($reader)
    
    # Find all controls
    $IsoList = $window.FindName("IsoList")
    $AddIso = $window.FindName("AddIso")
    $RemoveIso = $window.FindName("RemoveIso")
    $ClearIso = $window.FindName("ClearIso")
    $UsbBox = $window.FindName("UsbBox")
    $RefreshUsb = $window.FindName("RefreshUsb")
    $FormatUsb = $window.FindName("FormatUsb")
    $LogBox = $window.FindName("LogBox")
    $StartBtn = $window.FindName("StartBtn")
    $AutoMode = $window.FindName("AutoMode")
    $ModeUEFI = $window.FindName("ModeUEFI")
    $ModeBIOS = $window.FindName("ModeBIOS")
    $ModeHybrid = $window.FindName("ModeHybrid")
    $DDMode = $window.FindName("DDMode")
    $QuickFormat = $window.FindName("QuickFormat")
    $ClearLog = $window.FindName("ClearLog")
    $SaveLog = $window.FindName("SaveLog")
    $Progress = $window.FindName("Progress")
    $ProgressText = $window.FindName("ProgressText")
    $IsoInfo = $window.FindName("IsoInfo")
    $UsbInfo = $window.FindName("UsbInfo")
    
    # Inicializa o log
    $LogBox.Document = New-Object System.Windows.Documents.FlowDocument
    
    Write-Log "Aplicação iniciada com sucesso" -Level "SUCCESS"
    Write-Log "Modo Administrador: Ativo" -Level "INFO"
}
catch {
    [System.Windows.MessageBox]::Show("Erro ao carregar interface: $_`n`nVerifique se todos os assemblies estão carregados.", "Erro", "OK", "Error")
    exit
}

# =======================
# FUNÇÕES AUXILIARES
# =======================
function Format-Progress {
    param([int]$Percent)
    
    $window.Dispatcher.Invoke([action]{
        $Progress.Value = $Percent
        $ProgressText.Text = "$Percent%"
    })
}

function Update-UsbInfo {
    if ($UsbBox.SelectedItem -and $UsbBox.SelectedItem -is [PSCustomObject]) {
        $disk = $UsbBox.SelectedItem
        $UsbInfo.Text = "Disco #$($disk.Number) | $($disk.SizeGB) GB | $($disk.Model)"
    }
}

function Update-IsoInfo {
    if ($IsoList.SelectedItem) {
        $iso = $IsoList.SelectedItem
        $size = [math]::Round((Get-Item $iso.Path).Length / 1GB, 2)
        $IsoInfo.Text = "Tamanho: ${size} GB | Tipo: $($iso.Type)"
    }
}

# =======================
# USB LIST FUNCTIONS
# =======================
function Load-UsbList {
    $UsbBox.Items.Clear()
    $disks = Get-UsbDisks
    
    if ($disks.Count -eq 0) {
        $UsbBox.Items.Add([PSCustomObject]@{
            FriendlyName = "Nenhum USB detectado"
            SizeGB = 0
            Number = 0
            Model = ""
        })
        $UsbBox.IsEnabled = $false
        $UsbInfo.Text = "Conecte um dispositivo USB e clique em Atualizar"
    }
    else {
        foreach ($disk in $disks) {
            $UsbBox.Items.Add($disk)
        }
        $UsbBox.IsEnabled = $true
        $UsbBox.SelectedIndex = 0
        Update-UsbInfo
    }
    
    Write-Log "Lista de USBs atualizada: $($disks.Count) dispositivo(s)" -Level "INFO"
}

# =======================
# EVENT HANDLERS
# =======================
$AddIso.Add_Click({
    $dialog = New-Object System.Windows.Forms.OpenFileDialog
    $dialog.Filter = "Imagens ISO (*.iso)|*.iso|Todos os arquivos (*.*)|*.*"
    $dialog.Title = "Selecionar arquivo ISO"
    
    if ($dialog.ShowDialog() -eq "OK") {
        $isoInfo = Get-IsoType $dialog.FileName
        if ($isoInfo) {
            $item = [PSCustomObject]@{
                Path = $dialog.FileName
                Type = $isoInfo.Type
            }
            $IsoList.Items.Add($item)
            Write-Log "ISO adicionada: $(Split-Path $dialog.FileName -Leaf)" -Level "SUCCESS"
        }
    }
})

$RemoveIso.Add_Click({
    if ($IsoList.SelectedItem) {
        $item = $IsoList.SelectedItem
        $IsoList.Items.Remove($item)
        Write-Log "ISO removida" -Level "INFO"
    }
})

$ClearIso.Add_Click({
    $IsoList.Items.Clear()
    $IsoInfo.Text = ""
    Write-Log "Lista de ISOs limpa" -Level "INFO"
})

$RefreshUsb.Add_Click({
    Load-UsbList
})

$FormatUsb.Add_Click({
    if ($UsbBox.SelectedItem -and $UsbBox.SelectedItem -is [PSCustomObject] -and $UsbBox.SelectedItem.Number -gt 0) {
        $disk = $UsbBox.SelectedItem
        $confirm = [System.Windows.MessageBox]::Show(
            "Formatar dispositivo USB?`n`n$($disk.FriendlyName)`n$($disk.SizeGB) GB`n`n⚠️ TODOS OS DADOS SERÃO PERDIDOS!",
            "Confirmação",
            "YesNo",
            "Warning"
        )
        
        if ($confirm -eq "Yes") {
            try {
                Write-Log "Formatando USB..." -Level "WARNING"
                Clear-Disk -Number $disk.Number -RemoveData -Confirm:$false
                Initialize-Disk -Number $disk.Number -PartitionStyle GPT
                $partition = New-Partition -DiskNumber $disk.Number -UseMaximumSize -AssignDriveLetter
                Format-Volume -DriveLetter $partition.DriveLetter -FileSystem FAT32 -NewFileSystemLabel "USB_BOOT" -Confirm:$false
                
                Write-Log "USB formatado com sucesso" -Level "SUCCESS"
                Load-UsbList
            }
            catch {
                Write-Log "Erro ao formatar USB: $_" -Level "ERROR"
            }
        }
    }
})

$ClearLog.Add_Click({
    $LogBox.Document = New-Object System.Windows.Documents.FlowDocument
    Write-Log "Log limpo" -Level "INFO"
})

$SaveLog.Add_Click({
    $dialog = New-Object Microsoft.Win32.SaveFileDialog
    $dialog.Filter = "Arquivo de Log (*.log)|*.log|Arquivo de Texto (*.txt)|*.txt"
    $dialog.FileName = "rufus_log_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
    
    if ($dialog.ShowDialog() -eq $true) {
        $text = New-Object System.Text.StringBuilder
        foreach ($block in $LogBox.Document.Blocks) {
            $text.AppendLine($block.Content.Text)
        }
        [System.IO.File]::WriteAllText($dialog.FileName, $text.ToString())
        Write-Log "Log salvo: $($dialog.FileName)" -Level "SUCCESS"
    }
})

$UsbBox.Add_SelectionChanged({
    Update-UsbInfo
})

$IsoList.Add_SelectionChanged({
    Update-IsoInfo
})

# =======================
# MAIN PROCESS
# =======================
$StartBtn.Add_Click({
    # Validações
    if ($IsoList.Items.Count -eq 0) {
        [System.Windows.MessageBox]::Show("Selecione uma ISO para continuar", "Aviso", "OK", "Warning")
        return
    }
    
    if (-not $UsbBox.SelectedItem -or $UsbBox.SelectedItem.Number -eq 0) {
        [System.Windows.MessageBox]::Show("Selecione um dispositivo USB válido", "Aviso", "OK", "Warning")
        return
    }
    
    $iso = $IsoList.SelectedItem
    $disk = $UsbBox.SelectedItem
    
    # Confirmação final
    $confirm = [System.Windows.MessageBox]::Show(
        "Criar USB bootável?`n`n" +
        "ISO: $(Split-Path $iso.Path -Leaf)`n" +
        "USB: $($disk.FriendlyName)`n" +
        "Tamanho: $($disk.SizeGB) GB`n`n" +
        "⚠️ Todos os dados no USB serão apagados!",
        "Confirmação",
        "YesNo",
        "Warning"
    )
    
    if ($confirm -ne "Yes") {
        Write-Log "Operação cancelada" -Level "INFO"
        return
    }
    
    # Desabilita botão durante processo
    $StartBtn.IsEnabled = $false
    $StartBtn.Content = "PROCESSANDO..."
    $StartBtn.Background = $Theme.Gray
    
    try {
        Write-Log "="*50 -Level "INFO"
        Write-Log "INICIANDO CRIAÇÃO DE USB BOOTÁVEL" -Level "INFO"
        Write-Log "="*50 -Level "INFO"
        
        Format-Progress 10
        Write-Log "1. Preparando dispositivo USB..." -Level "INFO"
        
        # Limpa o disco
        Clear-Disk -Number $disk.Number -RemoveData -Confirm:$false
        
        Format-Progress 30
        Write-Log "2. Inicializando disco..." -Level "INFO"
        
        # Escolhe esquema de partição
        if ($ModeUEFI.IsChecked) {
            Initialize-Disk -Number $disk.Number -PartitionStyle GPT
            Write-Log "   Esquema: GPT (UEFI)" -Level "INFO"
        }
        else {
            Initialize-Disk -Number $disk.Number -PartitionStyle MBR
            Write-Log "   Esquema: MBR (BIOS)" -Level "INFO"
        }
        
        Format-Progress 50
        Write-Log "3. Criando partição..." -Level "INFO"
        
        # Cria partição
        $partition = New-Partition -DiskNumber $disk.Number -UseMaximumSize -IsActive -AssignDriveLetter
        
        Format-Progress 60
        Write-Log "4. Formatando..." -Level "INFO"
        
        # Formata
        if ($QuickFormat.IsChecked) {
            Format-Volume -DriveLetter $partition.DriveLetter -FileSystem FAT32 -NewFileSystemLabel "BOOT_USB" -Confirm:$false
        }
        else {
            Format-Volume -DriveLetter $partition.DriveLetter -FileSystem FAT32 -NewFileSystemLabel "BOOT_USB" -Full -Confirm:$false
        }
        
        Format-Progress 70
        Write-Log "5. Copiando arquivos da ISO..." -Level "INFO"
        
        # Monta ISO e copia arquivos
        $mount = Mount-DiskImage $iso.Path -PassThru
        $isoVolume = Get-Volume -DiskImage $mount
        $source = "$($isoVolume.DriveLetter):\"
        $destination = "$($partition.DriveLetter):\"
        
        # Copia arquivos
        Copy-Item "$source*" $destination -Recurse -Force
        
        Dismount-DiskImage $iso.Path
        
        Format-Progress 95
        Write-Log "6. Finalizando..." -Level "INFO"
        
        # Configurações para Windows
        if ($iso.Type -eq "Windows") {
            Write-Log "   Aplicando configurações Windows..." -Level "INFO"
            
            $wimPath = "$destination\sources\install.wim"
            if (Test-Path $wimPath -and (Get-Item $wimPath).Length -gt 4GB) {
                Write-Log "   install.wim > 4GB, dividindo..." -Level "WARNING"
                dism /Split-Image /ImageFile:$wimPath `
                     /SWMFile:"$destination\sources\install.swm" `
                     /FileSize:3800 | Out-Null
                Remove-Item $wimPath -Force
            }
        }
        
        Format-Progress 100
        Write-Log "✅ USB BOOTÁVEL CRIADO COM SUCESSO!" -Level "SUCCESS"
        Write-Log "Dispositivo: $($partition.DriveLetter):\" -Level "SUCCESS"
        
        [System.Windows.MessageBox]::Show(
            "✅ USB Bootável criado com sucesso!`n`n" +
            "Dispositivo: $($partition.DriveLetter):\`n" +
            "Pronto para uso.",
            "Sucesso",
            "OK",
            "Information"
        )
        
    }
    catch {
        Write-Log "❌ ERRO: $_" -Level "ERROR"
        [System.Windows.MessageBox]::Show(
            "Erro durante a criação do USB:`n`n$_",
            "Erro",
            "OK",
            "Error"
        )
    }
    finally {
        # Restaura botão
        $StartBtn.IsEnabled = $true
        $StartBtn.Content = "INICIAR CRIAÇÃO DO USB"
        $StartBtn.Background = $Theme.Success
        Format-Progress 0
    }
})

# =======================
# INITIALIZE
# =======================
Load-UsbList

$window.Add_Loaded({
    Write-Log "Interface carregada com sucesso" -Level "SUCCESS"
})

# Exibe a janela
$window.ShowDialog() | Out-Null