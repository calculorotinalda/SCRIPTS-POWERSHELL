Add-Type -AssemblyName System.Windows.Forms

function Download-YouTubeVideo {
    param (
        [string]$url,
        [string]$OutputPath
    )

    # Verificar se youtube-dl está instalado
    if (-not (Get-Command youtube-dl -ErrorAction SilentlyContinue)) {
        [System.Windows.Forms.MessageBox]::Show("youtube-dl não está instalado. Por favor, instale youtube-dl e tente novamente.", "Erro", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
        return
    }

    # Comando para baixar vídeo
    $command = "youtube-dl -o `"$OutputPath%(title)s.%(ext)s`" $url"

    try {
        Invoke-Expression $command
        [System.Windows.Forms.MessageBox]::Show("Download concluído com sucesso!", "Sucesso", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
    }
    catch {
        [System.Windows.Forms.MessageBox]::Show("Ocorreu um erro ao tentar baixar o vídeo: $_", "Erro", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    }
}

# Criar janela de entrada
$form = New-Object System.Windows.Forms.Form
$form.Text = "Download YouTube Video"
$form.Size = New-Object System.Drawing.Size(400, 200)
$form.StartPosition = "CenterScreen"

# Campo para URL
$labelUrl = New-Object System.Windows.Forms.Label
$labelUrl.Text = "URL:"
$labelUrl.Location = New-Object System.Drawing.Point(10, 20)
$form.Controls.Add($labelUrl)

$textboxUrl = New-Object System.Windows.Forms.TextBox
$textboxUrl.Size = New-Object System.Drawing.Size(250, 20)
$textboxUrl.Location = New-Object System.Drawing.Point(80, 20)
$form.Controls.Add($textboxUrl)

# Campo para Caminho de Saída
$labelOutput = New-Object System.Windows.Forms.Label
$labelOutput.Text = "Caminho de Saída:"
$labelOutput.Location = New-Object System.Drawing.Point(10, 60)
$form.Controls.Add($labelOutput)

$textboxOutput = New-Object System.Windows.Forms.TextBox
$textboxOutput.Size = New-Object System.Drawing.Size(250, 20)
$textboxOutput.Location = New-Object System.Drawing.Point(80, 60)
$form.Controls.Add($textboxOutput)

# Botão para Iniciar Download
$buttonDownload = New-Object System.Windows.Forms.Button
$buttonDownload.Text = "Download"
$buttonDownload.Location = New-Object System.Drawing.Point(150, 100)
$buttonDownload.Add_Click({
    $url = $textboxUrl.Text
    $OutputPath = $textboxOutput.Text
    Download-YouTubeVideo -url $url -OutputPath $OutputPath
    $form.Close()
})
$form.Controls.Add($buttonDownload)

# Mostrar a janela
$form.Add_Shown({$form.Activate()})
[System.Windows.Forms.Application]::Run($form)
