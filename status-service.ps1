function Set-ServiceProperties {
    # Obtém todos os serviços e os armazena em uma variável
    $services = Get-Service

    # Apresenta os serviços ao usuário, incluindo as colunas "Status", "Name" e "DisplayName"
    Write-Host "Serviços:"
    $services | Format-Table Status, Name, DisplayName -AutoSize

    # Solicita ao usuário o nome do serviço a ser controlado
    $serviceName = Read-Host "Digite o nome do serviço que deseja controlar:"

    # Verifica se o serviço existe
    $service = Get-Service $serviceName

    # Se o serviço existir, exibe o estado atual e pergunta o novo tipo de arranque
    if ($service) {
        Write-Host "O serviço '$serviceName' está atualmente em '$($service.Status)' e seu tipo de arranque é '$($service.StartupType)'."

        # Lista de tipos de arranque válidos
        $validStartupTypes = "Automatic", "Manual", "Disabled"

        # Solicita o novo tipo de arranque
        $newStartupType = Read-Host "Digite o novo tipo de arranque desejado para o serviço ($($validStartupTypes -join ', ')):"

        # Valida o tipo de arranque informado
        if ($validStartupTypes -contains $newStartupType) {
            # Altera o tipo de arranque do serviço
            Set-Service -Name $serviceName -StartupType $newStartupType

            # Lista de status válidos para o usuário escolher
            $validStatuses = "Running", "Stopped", "Paused"

            # Solicita o novo status
            $newStatus = Read-Host "Digite o novo status desejado para o serviço ($($validStatuses -join ', ')):"

            # Valida o status informado
            if ($validStatuses -contains $newStatus) {
                # Altera o estado do serviço
                if ($newStatus -eq "Stopped") {
                    Stop-ServiceAndDependents -ServiceName $serviceName
                } elseif ($newStatus -eq "Running") {
                    Start-Service -Name $serviceName
                } elseif ($newStatus -eq "Paused") {
                    Suspend-Service -Name $serviceName
                }

                Write-Host "O status e o tipo de arranque do serviço '$serviceName' foram alterados com sucesso."
            } else {
                Write-Host "Status inválido. Por favor, escolha entre as opções válidas."
            }
        } else {
            Write-Host "Tipo de arranque inválido. Por favor, escolha entre as opções válidas."
        }
    } else {
        Write-Host "O serviço '$serviceName' não foi encontrado."
    }
}

function Stop-ServiceAndDependents {
    param (
        [string]$ServiceName
    )

    # Obter o serviço e seus dependentes
    $service = Get-Service -Name $ServiceName
    $dependents = Get-Service | Where-Object { $_.DependentServices -contains $service }

    # Parar os dependentes primeiro
    foreach ($dependent in $dependents) {
        Write-Host "Parando serviço dependente: $($dependent.Name)"
        Stop-ServiceSafely -ServiceName $dependent.Name
    }

    # Parar o serviço principal
    Write-Host "Parando serviço: $($service.Name)"
    Stop-ServiceSafely -ServiceName $service.Name
}

function Stop-ServiceSafely {
    param (
        [string]$ServiceName
    )

    try {
        Stop-Service -Name $ServiceName -Force
    } catch {
        Write-Host "Não foi possível parar o serviço '$ServiceName': $_"
    }
}

Set-ServiceProperties



