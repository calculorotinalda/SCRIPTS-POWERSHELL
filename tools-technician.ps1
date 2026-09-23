# ============================================================
# WINDOWS TECHNICIAN TOOLKIT
# 40 FERRAMENTAS PARA TÉCNICOS DE INFORMÁTICA
# ============================================================

$ErrorActionPreference = "SilentlyContinue"

function Pause-Menu {
    Write-Host ""
    Read-Host "Prima ENTER para voltar ao menu"
}

function Test-Admin {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)

    return $principal.IsInRole(
        [Security.Principal.WindowsBuiltInRole]::Administrator
    )
}

function Show-Menu {

    Clear-Host

    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host "             WINDOWS TECHNICIAN TOOLKIT" -ForegroundColor Yellow
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""

    if (Test-Admin) {
        Write-Host " Estado: ADMINISTRADOR" -ForegroundColor Green
    }
    else {
        Write-Host " Estado: UTILIZADOR NORMAL" -ForegroundColor Red
    }

    Write-Host ""
    Write-Host "================ SISTEMA E MANUTENÇÃO =====================" -ForegroundColor Cyan

    Write-Host "[01] Gestor de Tarefas"
    Write-Host "[02] Gestor de Dispositivos"
    Write-Host "[03] Gestão de Discos"
    Write-Host "[04] Visualizador de Eventos"
    Write-Host "[05] Informações do Sistema"
    Write-Host "[06] Configuração do Sistema"
    Write-Host "[07] Serviços do Windows"
    Write-Host "[08] Verificar Ficheiros do Sistema - SFC"
    Write-Host "[09] Reparar Imagem do Windows - DISM"
    Write-Host "[10] Verificar Disco - CHKDSK"
    Write-Host "[11] Abrir PowerShell"
    Write-Host "[12] Abrir CMD"
    Write-Host "[13] Configuração de Rede"
    Write-Host "[14] Diagnóstico de Rede"
    Write-Host "[15] Editor do Registo"
    Write-Host "[16] Política de Grupo"
    Write-Host "[17] Restauro do Sistema"
    Write-Host "[18] Gestão do Computador"
    Write-Host "[19] Gestor de Arranque"
    Write-Host "[20] Ambiente de Recuperação WinRE"

    Write-Host ""
    Write-Host "================ DIAGNÓSTICO AVANÇADO =====================" -ForegroundColor Cyan

    Write-Host "[21] Informações do Processador"
    Write-Host "[22] Informações da Memória RAM"
    Write-Host "[23] Informações da BIOS"
    Write-Host "[24] Informações da Placa Gráfica"
    Write-Host "[25] Informações dos Discos"
    Write-Host "[26] Estado SMART dos Discos"
    Write-Host "[27] Lista de Drivers"
    Write-Host "[28] Exportar Drivers"
    Write-Host "[29] Verificar Windows Update"
    Write-Host "[30] Abrir Windows Update"
    Write-Host "[31] Programas Instalados"
    Write-Host "[32] Processos em Execução"
    Write-Host "[33] Serviços em Execução"
    Write-Host "[34] Tarefas Agendadas"
    Write-Host "[35] Ligações TCP Ativas"
    Write-Host "[36] Teste de Latência de Rede"
    Write-Host "[37] Informações Completas da Rede"
    Write-Host "[38] Limpar Ficheiros Temporários"
    Write-Host "[39] Limpar Cache DNS"
    Write-Host "[40] Reiniciar Computador"

    Write-Host ""
    Write-Host "[0] Sair" -ForegroundColor Red
    Write-Host ""

    return Read-Host "Digite o número da função que deseja executar"
}


do {

    $opcao = Show-Menu

    switch ($opcao) {

        # =====================================================
        # 1 - 20
        # =====================================================

        "1"  { Start-Process "taskmgr.exe" }
        "01" { Start-Process "taskmgr.exe" }

        "2"  { Start-Process "devmgmt.msc" }
        "02" { Start-Process "devmgmt.msc" }

        "3"  { Start-Process "diskmgmt.msc" }
        "03" { Start-Process "diskmgmt.msc" }

        "4"  { Start-Process "eventvwr.msc" }
        "04" { Start-Process "eventvwr.msc" }

        "5"  { Start-Process "msinfo32.exe" }
        "05" { Start-Process "msinfo32.exe" }

        "6"  { Start-Process "msconfig.exe" }
        "06" { Start-Process "msconfig.exe" }

        "7"  { Start-Process "services.msc" }
        "07" { Start-Process "services.msc" }

        "8" {
            Write-Host ""
            Write-Host "A executar SFC..." -ForegroundColor Yellow

            sfc.exe /scannow

            Pause-Menu
        }

        "08" {
            Write-Host ""
            Write-Host "A executar SFC..." -ForegroundColor Yellow

            sfc.exe /scannow

            Pause-Menu
        }

        "9" {
            Write-Host ""
            Write-Host "A executar DISM..." -ForegroundColor Yellow

            DISM.exe /Online /Cleanup-Image /RestoreHealth

            Pause-Menu
        }

        "09" {
            Write-Host ""
            Write-Host "A executar DISM..." -ForegroundColor Yellow

            DISM.exe /Online /Cleanup-Image /RestoreHealth

            Pause-Menu
        }

        "10" {
            Write-Host ""
            chkdsk.exe C: /scan
            Pause-Menu
        }

        "11" {
            Start-Process "powershell.exe"
        }

        "12" {
            Start-Process "cmd.exe"
        }

        "13" {
            Start-Process "ncpa.cpl"
        }

        "14" {

            Clear-Host

            Write-Host "DIAGNÓSTICO DE REDE" -ForegroundColor Cyan
            Write-Host ""

            Write-Host "[1] IPConfig"
            Write-Host "[2] Limpar DNS"
            Write-Host "[3] Ping Google DNS"
            Write-Host "[4] NSLookup"
            Write-Host "[5] Tracert"

            $rede = Read-Host "Escolha"

            switch ($rede) {

                "1" {
                    ipconfig /all
                }

                "2" {
                    ipconfig /flushdns
                }

                "3" {
                    ping 8.8.8.8
                }

                "4" {
                    $dominio = Read-Host "Domínio"
                    nslookup $dominio
                }

                "5" {
                    $destino = Read-Host "Destino"
                    tracert $destino
                }
            }

            Pause-Menu
        }

        "15" {
            Start-Process "regedit.exe"
        }

        "16" {
            Start-Process "gpedit.msc"
        }

        "17" {
            Start-Process "rstrui.exe"
        }

        "18" {
            Start-Process "compmgmt.msc"
        }

        "19" {
            bcdedit /enum
            Pause-Menu
        }

        "20" {

            Write-Host ""
            $confirmar = Read-Host "Reiniciar para WinRE? (S/N)"

            if ($confirmar -eq "S") {
                shutdown /r /o /f /t 0
            }
        }


        # =====================================================
        # 21 - 40
        # =====================================================

        "21" {

            Clear-Host

            Write-Host "INFORMAÇÕES DO PROCESSADOR" -ForegroundColor Cyan
            Write-Host ""

            Get-CimInstance Win32_Processor |
            Select-Object Name,
                          Manufacturer,
                          NumberOfCores,
                          NumberOfLogicalProcessors,
                          MaxClockSpeed |
            Format-List

            Pause-Menu
        }


        "22" {

            Clear-Host

            Write-Host "INFORMAÇÕES DA MEMÓRIA RAM" -ForegroundColor Cyan
            Write-Host ""

            Get-CimInstance Win32_PhysicalMemory |
            Select-Object Manufacturer,
                          PartNumber,
                          Capacity,
                          Speed,
                          DeviceLocator |
            Format-Table -AutoSize

            Pause-Menu
        }


        "23" {

            Clear-Host

            Write-Host "INFORMAÇÕES DA BIOS" -ForegroundColor Cyan
            Write-Host ""

            Get-CimInstance Win32_BIOS |
            Select-Object Manufacturer,
                          SMBIOSBIOSVersion,
                          SerialNumber,
                          ReleaseDate |
            Format-List

            Pause-Menu
        }


        "24" {

            Clear-Host

            Write-Host "INFORMAÇÕES DA PLACA GRÁFICA" -ForegroundColor Cyan
            Write-Host ""

            Get-CimInstance Win32_VideoController |
            Select-Object Name,
                          DriverVersion,
                          VideoModeDescription,
                          AdapterRAM |
            Format-List

            Pause-Menu
        }


        "25" {

            Clear-Host

            Write-Host "INFORMAÇÕES DOS DISCOS" -ForegroundColor Cyan
            Write-Host ""

            Get-CimInstance Win32_DiskDrive |
            Select-Object Model,
                          SerialNumber,
                          InterfaceType,
                          MediaType,
                          Size |
            Format-Table -AutoSize

            Pause-Menu
        }


        "26" {

            Clear-Host

            Write-Host "ESTADO SMART DOS DISCOS" -ForegroundColor Cyan
            Write-Host ""

            Get-CimInstance -Namespace root\wmi `
                -ClassName MSStorageDriver_FailurePredictStatus |
            Select-Object InstanceName,
                          PredictFailure,
                          Reason |
            Format-Table -AutoSize

            Pause-Menu
        }


        "27" {

            Clear-Host

            Write-Host "DRIVERS INSTALADOS" -ForegroundColor Cyan
            Write-Host ""

            Get-CimInstance Win32_PnPSignedDriver |
            Select-Object DeviceName,
                          Manufacturer,
                          DriverVersion,
                          DriverDate |
            Sort-Object DeviceName |
            Format-Table -AutoSize

            Pause-Menu
        }


        "28" {

            $pasta = Read-Host "Digite a pasta para exportar os drivers"

            if (!(Test-Path $pasta)) {
                New-Item -ItemType Directory -Path $pasta -Force | Out-Null
            }

            Write-Host ""
            Write-Host "A exportar drivers..." -ForegroundColor Yellow

            pnputil /export-driver * $pasta

            Write-Host ""
            Write-Host "Exportação concluída." -ForegroundColor Green

            Pause-Menu
        }


        "29" {

            Clear-Host

            Write-Host "VERIFICAÇÃO DO WINDOWS UPDATE" -ForegroundColor Cyan
            Write-Host ""

            Get-Service wuauserv

            Write-Host ""
            Write-Host "Serviço Windows Update verificado."

            Pause-Menu
        }


        "30" {

            Start-Process "ms-settings:windowsupdate"
        }


        "31" {

            Clear-Host

            Write-Host "PROGRAMAS INSTALADOS" -ForegroundColor Cyan
            Write-Host ""

            Get-ItemProperty `
            HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*,
            HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* |
            Where-Object {$_.DisplayName} |
            Select-Object DisplayName,
                          DisplayVersion,
                          Publisher |
            Sort-Object DisplayName |
            Format-Table -AutoSize

            Pause-Menu
        }


        "32" {

            Clear-Host

            Write-Host "PROCESSOS EM EXECUÇÃO" -ForegroundColor Cyan
            Write-Host ""

            Get-Process |
            Sort-Object CPU -Descending |
            Select-Object -First 30 `
                Name,
                Id,
                CPU,
                WorkingSet |
            Format-Table -AutoSize

            Pause-Menu
        }


        "33" {

            Clear-Host

            Write-Host "SERVIÇOS EM EXECUÇÃO" -ForegroundColor Cyan
            Write-Host ""

            Get-Service |
            Where-Object {$_.Status -eq "Running"} |
            Sort-Object DisplayName |
            Format-Table Status,
                          Name,
                          DisplayName -AutoSize

            Pause-Menu
        }


        "34" {

            Clear-Host

            Write-Host "TAREFAS AGENDADAS" -ForegroundColor Cyan
            Write-Host ""

            Get-ScheduledTask |
            Select-Object TaskName,
                          TaskPath,
                          State |
            Sort-Object TaskPath |
            Format-Table -AutoSize

            Pause-Menu
        }


        "35" {

            Clear-Host

            Write-Host "LIGAÇÕES TCP ATIVAS" -ForegroundColor Cyan
            Write-Host ""

            Get-NetTCPConnection |
            Select-Object LocalAddress,
                          LocalPort,
                          RemoteAddress,
                          RemotePort,
                          State,
                          OwningProcess |
            Format-Table -AutoSize

            Pause-Menu
        }


        "36" {

            Clear-Host

            Write-Host "TESTE DE LATÊNCIA" -ForegroundColor Cyan
            Write-Host ""

            $destino = Read-Host "Digite o endereço a testar"

            Test-Connection $destino -Count 5

            Pause-Menu
        }


        "37" {

            Clear-Host

            Write-Host "INFORMAÇÕES COMPLETAS DA REDE" -ForegroundColor Cyan
            Write-Host ""

            Get-NetIPConfiguration |
            Format-List

            Write-Host ""
            Write-Host "ADAPTADORES:"
            
            Get-NetAdapter |
            Format-Table -AutoSize

            Pause-Menu
        }


        "38" {

            Clear-Host

            Write-Host "LIMPEZA DE FICHEIROS TEMPORÁRIOS" -ForegroundColor Cyan
            Write-Host ""

            $confirmar = Read-Host "Deseja limpar os ficheiros temporários? (S/N)"

            if ($confirmar -eq "S") {

                Remove-Item "$env:TEMP\*" `
                    -Recurse `
                    -Force `
                    -ErrorAction SilentlyContinue

                Remove-Item "C:\Windows\Temp\*" `
                    -Recurse `
                    -Force `
                    -ErrorAction SilentlyContinue

                Write-Host ""
                Write-Host "Limpeza concluída." -ForegroundColor Green
            }

            Pause-Menu
        }


        "39" {

            Clear-Host

            Write-Host "A LIMPAR CACHE DNS..." -ForegroundColor Yellow

            ipconfig /flushdns

            Write-Host ""
            Write-Host "Cache DNS limpo." -ForegroundColor Green

            Pause-Menu
        }


        "40" {

            Clear-Host

            Write-Host "REINICIAR COMPUTADOR" -ForegroundColor Red
            Write-Host ""

            $confirmar = Read-Host "Tem a certeza que deseja reiniciar? (S/N)"

            if ($confirmar -eq "S") {

                shutdown.exe /r /t 0
            }
        }


        "0" {

            Clear-Host

            Write-Host ""
            Write-Host "Windows Technician Toolkit encerrado." -ForegroundColor Green
            Write-Host ""
        }


        default {

            Write-Host ""
            Write-Host "Opção inválida!" -ForegroundColor Red

            Start-Sleep -Seconds 2
        }
    }

}
while ($opcao -ne "0")