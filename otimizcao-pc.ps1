<#
.SYNOPSIS
    Limpeza e Otimização do Windows - arquivos temporários, reciclagem, caches e logs.

.DESCRIPTION
    Este script realiza:
    - Limpeza de arquivos temporários do Windows e usuário
    - Esvaziamento da Lixeira
    - Limpeza de caches de navegador e logs do sistema
    - Permite agendar execução semanal automaticamente

.PARAMETER CreateScheduledTask
    Se presente, cria uma task agendada semanalmente

.EXAMPLE
    .\WindowsCleanup.ps1 -CreateScheduledTask
#>

param(
    [switch]$CreateScheduledTask
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# --- Elevar privilégios ---
function Ensure-Elevated {
    if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
        Write-Host "A tentar elevar privilégios..." -ForegroundColor Yellow
        $psi = New-Object System.Diagnostics.ProcessStartInfo
        $psi.FileName = (Get-Process -Id $PID).Path
        $args = $MyInvocation.UnboundArguments -join ' '
        $psi.Arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`" $args"
        $psi.Verb = "runas"
        try { [System.Diagnostics.Process]::Start($psi) | Out-Null } catch {
            Write-Error "Elevação cancelada ou falhou. Execute o PowerShell como Administrador."
        }
        Exit
    }
}

Ensure-Elevated

function Clear-Folder($path) {
    if (Test-Path $path) {
        try {
            Get-ChildItem -Path $path -Recurse -Force -ErrorAction SilentlyContinue |
                Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
            Write-Host "✔ Limpeza concluída: $path" -ForegroundColor Green
        } catch {
            Write-Warning "Falha ao limpar ${path}: $_"
        }
    }
}


# --- Limpeza principal ---
function Cleanup-Windows {
    Write-Host "🧹 Iniciando limpeza do Windows..." -ForegroundColor Cyan

    # 1. Limpar arquivos temporários do usuário
    Clear-Folder "$env:TEMP"
    Clear-Folder "$env:LOCALAPPDATA\Temp"

    # 2. Limpar logs e caches do Windows
    Clear-Folder "$env:SystemRoot\Temp"
    Clear-Folder "$env:WINDIR\Logs"

    # 3. Esvaziar Lixeira
    try {
        Write-Host "♻ Esvaziando Lixeira..." -ForegroundColor Cyan
        $shell = New-Object -ComObject Shell.Application
        $shell.Namespace(0x0a).Items() | ForEach-Object { Remove-Item $_.Path -Recurse -Force -ErrorAction SilentlyContinue }
        Write-Host "✔ Lixeira esvaziada" -ForegroundColor Green
    } catch {
        Write-Warning "Falha ao esvaziar a Lixeira: $_"
    }

    # 4. Limpar caches de navegadores (Chrome/Edge/Firefox - se instalados)
    $browsers = @(
        "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Cache",
        "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Cache",
        "$env:APPDATA\Mozilla\Firefox\Profiles"
    )
    foreach ($b in $browsers) {
        Clear-Folder $b
    }

    Write-Host "🎉 Limpeza concluída!" -ForegroundColor Green
}

# --- Função para criar task agendada ---
function Create-WeeklyTask {
    param($scriptPath)
    $taskName = "WindowsCleanup-Semanal"
    $action = New-ScheduledTaskAction -Execute 'PowerShell.exe' -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`""
    $trigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek Sunday -At 03:00AM
    $principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest

    try {
        Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Principal $principal -Force
        Write-Host "✅ Task agendada criada: $taskName (domingos às 03:00)" -ForegroundColor Green
    } catch {
        Write-Warning "Falha ao criar task agendada: $_"
    }
}

# --- Execução ---
try {
    Cleanup-Windows

    if ($CreateScheduledTask) {
        Create-WeeklyTask -scriptPath $PSCommandPath
    }
}
catch {
    Write-Error "Erro durante a execução: $_"
}
