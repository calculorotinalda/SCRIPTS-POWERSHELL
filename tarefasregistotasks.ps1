# Script para listar tarefas agendadas no Registro do Windows com IDs

# Definir as chaves do Registro onde as tarefas estão armazenadas
$logonKey = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"
$tasksKey = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\TaskCache\Tasks"

# Função para listar entradas em uma chave do Registro
function List-RegistryEntries {
    param (
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [string]$keyPath,
        [string]$description
    )
    Write-Output "`n=== $description ==="
    if (Test-Path $keyPath) {
        Get-ItemProperty -Path $keyPath | ForEach-Object {
            foreach ($property in $_.PSObject.Properties) {
                if ($property.Name -notin @("PSPath", "PSParentPath", "PSChildName", "PSProvider")) {
                    Write-Output "$($property.Name): $($property.Value)"
                }
            }
        }
    } else {
        Write-Output "Chave do Registro não encontrada: $keyPath"
    }
}

# Função para listar tarefas agendadas no TaskCache com IDs
function List-TasksInTaskCache {
    param (
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [string]$keyPath
    )
    Write-Output "`n=== Tarefas Agendadas (TaskCache) ==="
    if (Test-Path $keyPath) {
        Get-ChildItem -Path $keyPath | ForEach-Object {
            # Obter o ID da tarefa (nome da subchave)
            $taskId = $_.PSChildName
            # Obter o nome e o XML da tarefa
            $taskName = (Get-ItemProperty -Path $_.PSPath).Path
            $taskXml = (Get-ItemProperty -Path $_.PSPath).XML
            # Exibir o ID, nome e XML da tarefa
            Write-Output "ID da Tarefa: $taskId"
            Write-Output "Nome da Tarefa: $taskName"
            Write-Output "XML da Tarefa: $taskXml`n"
        }
    } else {
        Write-Output "Chave do Registro não encontrada: $keyPath"
    }
}

# Listar tarefas de Logon
List-RegistryEntries -keyPath $logonKey -description "Tarefas de Logon (Run)"

# Listar tarefas agendadas no TaskCache com paginação usando | more
List-TasksInTaskCache -keyPath $tasksKey | more