function Get-Rundll32Commands {
    param (
        [string]$Directory = "$env:SystemRoot\System32",
        [string]$DumpbinPath = "C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Tools\MSVC\14.44.35207\bin\Hostx64\x64",
        [switch]$NoPagination
    )

    Write-Host "Procurando DLLs em: $Directory" -ForegroundColor Cyan

    # Localiza o dumpbin.exe
    if (Test-Path "$DumpbinPath") {
        $dumpbin = Get-ChildItem -Path "$DumpbinPath" -Recurse -Filter dumpbin.exe -ErrorAction SilentlyContinue | Select-Object -First 1
    } else {
        $dumpbin = Get-Command dumpbin.exe -ErrorAction SilentlyContinue
    }

    if (-not $dumpbin) {
        Write-Host "`n❌ dumpbin.exe não encontrado!" -ForegroundColor Red
        Write-Host "Instale o Visual Studio Build Tools e indique o caminho via parâmetro -DumpbinPath" -ForegroundColor Yellow
        return
    }

    Write-Host "`n✔ dumpbin encontrado em: $($dumpbin.FullName)" -ForegroundColor Green

    $dlls = Get-ChildItem -Path $Directory -Filter *.dll -File -ErrorAction SilentlyContinue

    $results = @()

    foreach ($dll in $dlls) {
        Write-Host "Lendo exportações de $($dll.Name)..." -ForegroundColor Gray
        try {
            # Executa dumpbin e captura a saída (força UTF8)
            $raw = & "$($dumpbin.FullName)" /EXPORTS "`"$($dll.FullName)`"" 2>$null | Out-String -Width 4096

            # Extrai nomes de funções da secção EXPORTS
            $exports = $raw -split "`n" |
                ForEach-Object { $_.Trim() } |
                Where-Object { $_ -match '^\d+\s+[0-9A-F]+\s+[0-9A-F]+\s+(\S+)$' } |
                ForEach-Object { ($_ -split '\s+')[-1] } |
                Where-Object { $_ -match '^[A-Za-z_]' }

            if ($exports.Count -eq 0) {
                $results += "rundll32.exe $($dll.Name),(sem_exportações)"
            } else {
                foreach ($f in $exports) {
                    $results += "rundll32.exe $($dll.Name),$f"
                }
            }
        } catch {
            $results += "rundll32.exe $($dll.Name),(erro: $($_.Exception.Message))"
        }
    }

    if ($NoPagination) {
        $results
    } else {
        $results | more
    }
}

# Executar
Get-Rundll32Commands


