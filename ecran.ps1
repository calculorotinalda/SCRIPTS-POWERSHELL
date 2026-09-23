# Obter informação do ecrã através do EDID
$monitors = Get-CimInstance -Namespace root\wmi -ClassName WmiMonitorBasicDisplayParams

foreach ($monitor in $monitors) {
    $widthCm  = $monitor.MaxHorizontalImageSize
    $heightCm = $monitor.MaxVerticalImageSize

    if ($widthCm -and $heightCm) {
        $diagonalCm = [Math]::Sqrt(
            ($widthCm * $widthCm) +
            ($heightCm * $heightCm)
        )

        $diagonalInches = $diagonalCm / 2.54

        Write-Host "Tamanho do ecrã: $([Math]::Round($diagonalInches, 1)) polegadas"
        Write-Host "Dimensões: $widthCm cm x $heightCm cm"
    }
    else {
        Write-Host "Não foi possível determinar o tamanho físico do ecrã."
    }
}
