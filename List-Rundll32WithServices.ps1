function Get-RunDllPath {
    # Obter os processos rundll32
    $rundll32Processes = Get-Process rundll32 | Where-Object { $_.Path }

    foreach ($process in $rundll32Processes) {
        try {
            # Obter a linha de comando para encontrar o nome da DLL
            $commandLine = (Get-CimInstance Win32_Process -Filter "ProcessId=$($process.Id)").CommandLine

            # Extraindo o nome da DLL
            if ($commandLine -match 'rundll32.*? "?(?<dllName>[^\s",]+)"?') {
                $dllName = $matches['dllName']

                # Procurar o caminho completo da DLL no sistema
                $dllPath = Get-ChildItem -Path "C:\Windows\System32\" -Filter $dllName -Recurse -ErrorAction SilentlyContinue

                if ($dllPath) {
                    Write-Host "Processo ID: $($process.Id)"
                    Write-Host "Executável: $($process.Path)"
                    Write-Host "DLL encontrada: $($dllPath.FullName)"
                } else {
                    Write-Host "DLL $dllName não foi encontrada no sistema."
                }
            }
        } catch {
            Write-Warning "Erro ao processar ID $($process.Id): $($_.Message)"
        }
    }
}

# Executar a função
Get-RunDllPath
