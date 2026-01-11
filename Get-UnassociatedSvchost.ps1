function Get-UnassociatedSvchost {
<#
.SYNOPSIS
    Lista processos svchost.exe que não têm serviços associados.

.DESCRIPTION
    Esta função identifica instâncias de svchost.exe em execução que não têm
    serviços Windows associados, o que pode indicar processos órfãos ou suspeitos.
    É possível filtrar por PID específico ou exportar os resultados para CSV.

.PARAMETER PID
    (Opcional) Especifica o ID de processo (PID) de um svchost.exe para verificar apenas esse.
function Get-UnassociatedSvchost {
<#
.SYNOPSIS
    Lista processos svchost.exe que não têm serviços associados.

.DESCRIPTION
    Esta função identifica instâncias de svchost.exe em execução que não têm
    serviços Windows associados, o que pode indicar processos órfãos ou suspeitos.
    É possível filtrar por ID de processo específico ou exportar os resultados para CSV.

.PARAMETER ProcessId
    (Opcional) Especifica o ID de processo (PID) de um svchost.exe para verificar apenas esse.

.PARAMETER ExportPath
    (Opcional) Caminho completo para um ficheiro CSV onde guardar os resultados.

.EXAMPLE
    Get-UnassociatedSvchost

    Lista todos os svchost.exe sem serviços associados.

.EXAMPLE
    Get-UnassociatedSvchost -ProcessId 4321

    Verifica apenas o svchost.exe com ID 4321.

.EXAMPLE
    Get-UnassociatedSvchost -ExportPath "C:\Relatorios\svchost_suspeitos.csv"

    Exporta todos os resultados para o ficheiro CSV indicado.

.NOTES
    Autor: Pedro Gonçalves
    Versão: 1.2
    Data: 2025-10-11
#>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [int]$ProcessId,

        [Parameter(Mandatory=$false)]
        [string]$ExportPath
    )

    try {
        # Obtém todos os svchost.exe, ou um específico se ProcessId for passado
        if ($ProcessId) {
            $processes = Get-Process -Id $ProcessId -ErrorAction Stop | Where-Object { $_.ProcessName -eq "svchost" }
        } else {
            $processes = Get-Process -Name svchost -ErrorAction Stop
        }

        $results = @()

        foreach ($proc in $processes) {
            $procId = $proc.Id
            $services = Get-WmiObject Win32_Service | Where-Object { $_.ProcessId -eq $procId }

            if (-not $services) {
                $procInfo = Get-CimInstance Win32_Process -Filter "ProcessId=$procId"

                # Obter o dono do processo
                $owner = "N/A"
                try {
                    $ownerInfo = $procInfo | Invoke-CimMethod -MethodName GetOwner
                    if ($ownerInfo.User) { $owner = $ownerInfo.User }
                } catch { }

                # Calcular hash do executável
                $fileHash = "N/A"
                if ($procInfo.ExecutablePath) {
                    try {
                        $fileHash = (Get-FileHash $procInfo.ExecutablePath -Algorithm SHA256 -ErrorAction Stop).Hash
                    } catch {
                        $fileHash = "Erro ao calcular hash"
                    }
                }

                # Adicionar à lista de resultados
                $results += [PSCustomObject]@{
                    ProcessId     = $procId
                    ProcessName   = $proc.ProcessName
                    Executable    = $procInfo.ExecutablePath
                    CommandLine   = $procInfo.CommandLine
                    ParentPID     = $procInfo.ParentProcessId
                    Owner         = $owner
                    FileHash      = $fileHash
                }
            }
        }

        if ($results.Count -eq 0) {
            Write-Host "✅ Nenhum svchost.exe sem serviços associados foi encontrado." -ForegroundColor Green
        } else {
            Write-Host "⚠️  Foram encontrados $($results.Count) svchost.exe sem serviços associados:" -ForegroundColor Yellow
            $results | Format-Table -AutoSize
        }

        # Exportar CSV se for indicado
        if ($ExportPath) {
            $results | Export-Csv -Path $ExportPath -NoTypeInformation -Encoding UTF8
            Write-Host "`n📁 Resultados exportados para: $ExportPath" -ForegroundColor Cyan
        }

    } catch {
        Write-Error "Erro: $($_.Exception.Message)"
    }
}
Get-UnassociatedSvchost
