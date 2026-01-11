# Caminho a analisar
$path = "C:\"

# Tamanho mínimo em bytes (1 GB = 1 * 1024^3)
$minSize = 1GB

Write-Host "Procurando ficheiros maiores que 1 GB em $path ..." -ForegroundColor Cyan
Write-Host ""

# Obter todos os ficheiros maiores que o tamanho mínimo
Get-ChildItem -Path $path -Recurse -ErrorAction SilentlyContinue -Force |
    Where-Object { -not $_.PSIsContainer -and $_.Length -gt $minSize } |
    Select-Object FullName, 
                  @{Name="Tamanho(GB)"; Expression = { "{0:N2}" -f ($_.Length / 1GB) }},
                  LastWriteTime |
    Sort-Object Length -Descending |
    Format-Table -AutoSize

Write-Host ""
Write-Host "Pesquisa concluída." -ForegroundColor Green
