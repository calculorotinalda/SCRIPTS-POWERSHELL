# ============================================================
# WINDOWS TECHNICIAN TOOLKIT
# Menu de ferramentas para técnicos de informática
# ============================================================

$ErrorActionPreference = "SilentlyContinue"

function Pause-Menu {
    Write-Host ""
    Read-Host "Prima ENTER para voltar ao menu"
}

function Test-Admin {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Show-Menu {

    Clear-Host

    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host "          WINDOWS TECHNICIAN TOOLKIT" -ForegroundColor Yellow
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""

    if (Test-Admin) {
        Write-Host " Estado: PowerShell executado como ADMINISTRADOR" -ForegroundColor Green
    }
    else {
        Write-Host " Estado: PowerShell NÃO está como Administrador" -ForegroundColor Red
    }

    Write-Host ""
    Write-Host " [01] Gestor de Tarefas"
    Write-Host " [02] Gestor de Dispositivos"
    Write-Host " [03] Gestão de Discos"
    Write-Host " [04] Visualizador de Eventos"
    Write-Host " [05] Informações do Sistema"
    Write-Host " [06] Configuração do Sistema"
    Write-Host " [07] Serviços do Windows"
    Write-Host " [08] Verificar Ficheiros do Sistema (SFC)"
    Write-Host " [09] Reparar Imagem do Windows (DISM)"
    Write-Host " [10] Verificar Disco (CHKDSK)"
    Write-Host " [11] PowerShell"
    Write-Host " [12] Prompt de Comandos (CMD)"
    Write-Host " [13] Configuração de Rede"
    Write-Host " [14] Diagnóstico de Rede"
    Write-Host " [15] Editor do Registo"
    Write-Host " [16] Editor de Política de Grupo"
    Write-Host " [17] Restauro do Sistema"
    Write-Host " [18] Gestão do Computador"
    Write-Host " [19] Gestor de Arranque"
    Write-Host " [20] Ambiente de Recuperação do Windows"
    Write-Host ""
    Write-Host " [0]  Sair"
    Write-Host ""

    return (Read-Host "Digite o número da função que deseja executar")
}

do {

    $opcao = Show-Menu

    switch ($opcao) {

        "1" {
            Start-Process "taskmgr.exe"
        }

        "01" {
            Start-Process "taskmgr.exe"
        }

        "2" {
            Start-Process "devmgmt.msc"
        }

        "02" {
            Start-Process "devmgmt.msc"
        }

        "3" {
            Start-Process "diskmgmt.msc"
        }

        "03" {
            Start-Process "diskmgmt.msc"
        }

        "4" {
            Start-Process "eventvwr.msc"
        }

        "04" {
            Start-Process "eventvwr.msc"
        }

        "5" {
            Start-Process "msinfo32.exe"
        }

        "05" {
            Start-Process "msinfo32.exe"
        }

        "6" {
            Start-Process "msconfig.exe"
        }

        "06" {
            Start-Process "msconfig.exe"
        }

        "7" {
            Start-Process "services.msc"
        }

        "07" {
            Start-Process "services.msc"
        }

        "8" {
            Write-Host ""
            Write-Host "A executar SFC /SCANNOW..." -ForegroundColor Yellow
            sfc.exe /scannow
            Pause-Menu
        }

        "08" {
            Write-Host ""
            Write-Host "A executar SFC /SCANNOW..." -ForegroundColor Yellow
            sfc.exe /scannow
            Pause-Menu
        }

        "9" {
            Write-Host ""
            Write-Host "A executar DISM..." -ForegroundColor Yellow
            Write-Host "Este processo pode demorar alguns minutos." -ForegroundColor Gray

            DISM.exe /Online /Cleanup-Image /RestoreHealth

            Pause-Menu
        }

        "09" {
            Write-Host ""
            Write-Host "A executar DISM..." -ForegroundColor Yellow
            Write-Host "Este processo pode demorar alguns minutos." -ForegroundColor Gray

            DISM.exe /Online /Cleanup-Image /RestoreHealth

            Pause-Menu
        }

        "10" {
            Write-Host ""
            Write-Host "A verificar o disco C:..." -ForegroundColor Yellow

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

            Write-Host "============================================================"
            Write-Host "           DIAGNÓSTICO DE REDE"
            Write-Host "============================================================"
            Write-Host ""

            Write-Host "[1] Mostrar configuração IP"
            Write-Host "[2] Limpar cache DNS"
            Write-Host "[3] Testar Google DNS"
            Write-Host "[4] Testar DNS de um domínio"
            Write-Host "[5] Ver rota até um endereço"
            Write-Host ""

            $rede = Read-Host "Escolha uma opção"

            switch ($rede) {

                "1" {
                    ipconfig /all
                }

                "2" {
                    ipconfig /flushdns
                }

                "3" {
                    ping.exe 8.8.8.8
                }

                "4" {
                    $dominio = Read-Host "Digite o domínio (exemplo: google.com)"
                    nslookup.exe $dominio
                }

                "5" {
                    $destino = Read-Host "Digite o endereço (exemplo: google.com)"
                    tracert.exe $destino
                }

                default {
                    Write-Host "Opção inválida." -ForegroundColor Red
                }
            }

            Pause-Menu
        }

        "15" {
            Start-Process "regedit.exe"
        }

        "16" {
            if (Test-Path "$env:windir\System32\gpedit.msc") {
                Start-Process "gpedit.msc"
            }
            else {
                Write-Host ""
                Write-Host "O Editor de Política de Grupo não está disponível nesta edição do Windows." -ForegroundColor Red
                Pause-Menu
            }
        }

        "17" {
            Start-Process "rstrui.exe"
        }

        "18" {
            Start-Process "compmgmt.msc"
        }

        "19" {

            Clear-Host

            Write-Host "============================================================"
            Write-Host "              GESTOR DE ARRANQUE"
            Write-Host "============================================================"
            Write-Host ""

            Write-Host "[1] Mostrar configuração BCD"
            Write-Host "[2] Abrir Configuração do Sistema (MSConfig)"
            Write-Host ""

            $boot = Read-Host "Escolha uma opção"

            switch ($boot) {

                "1" {
                    bcdedit.exe /enum
                    Pause-Menu
                }

                "2" {
                    Start-Process "msconfig.exe"
                }

                default {
                    Write-Host "Opção inválida." -ForegroundColor Red
                    Pause-Menu
                }
            }
        }

        "20" {

            Clear-Host

            Write-Host "============================================================"
            Write-Host "       AMBIENTE DE RECUPERAÇÃO DO WINDOWS"
            Write-Host "============================================================"
            Write-Host ""

            Write-Host "Será necessário reiniciar o computador."
            Write-Host ""

            $confirmar = Read-Host "Deseja reiniciar agora para o WinRE? (S/N)"

            if ($confirmar -eq "S" -or $confirmar -eq "s") {
                shutdown.exe /r /o /f /t 0
            }
        }

        "0" {
            Write-Host ""
            Write-Host "A sair..." -ForegroundColor Yellow
        }

        default {
            Write-Host ""
            Write-Host "Opção inválida. Escolha um número entre 0 e 20." -ForegroundColor Red
            Start-Sleep -Seconds 2
        }
    }

} while ($opcao -ne "0")