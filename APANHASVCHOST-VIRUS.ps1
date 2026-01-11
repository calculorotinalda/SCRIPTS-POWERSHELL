function Get-SvchostWithoutService {
    # Inicializar contador
    $contador = 0

    # Obter todos os processos svchost.exe
    $svchostProcesses = Get-Process svchost | Where-Object { $_.Path }

    # Listar processos que não possuem serviços associados
    foreach ($process in $svchostProcesses) {
        try {
            # Obter serviços associados ao processo
            $services = Get-WmiObject Win32_Service | Where-Object { $_.ProcessId -eq $process.Id }

            # Verificar se não há serviços associados
            if ($services.Count -eq 0) {
                Write-Host "Processo ID: $($process.Id)"
                Write-Host "Caminho Executável: $($process.Path)"
                Write-Host "---------------------------------------"

                # Incrementar contador
                $contador++
            }
        } catch {
            Write-Warning "Erro ao processar ID $($process.Id): $($_.Exception.Message)"
        }
    }

    # Exibir total de processos sem serviços associados
    Write-Host "Total de processos svchost.exe sem serviços associados: $contador"
}

Get-SvchostWithoutService