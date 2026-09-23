<#
.SYNOPSIS
    Configura as permissões NTFS numa pasta à escolha do utilizador (Full Control ou Permissões sem apagar) e em todas as suas subpastas e ficheiros.

.DESCRIPTION
    - 1º Pergunta qual o tipo de permissão a aplicar:
        1. Full Control (Controlo Total para Todos, Administradores e SYSTEM).
        2. Permissões sem apagar (Leitura, Execução e Escrita para Todos, com bloqueio explícito DENY de eliminação).
    - 2º Pergunta qual a pasta onde aplicar as permissões.
    - Remove a herança de permissões da pasta pai.
    - Mantém Controlo Total para Administradores e SYSTEM.
    - Propaga e repõe as regras recursivamente em todas as pastas e ficheiros existentes.
    - Suporta o parâmetro opcional -Desbloquear para remover a restrição de eliminação caso seja necessária manutenção.
#>

[CmdletBinding()]
param (
    [Parameter(Position = 0, Mandatory = $false)]
    [string]$TipoPermissao,

    [Parameter(Position = 1, Mandatory = $false)]
    [string]$Caminho,

    [switch]$Desbloquear
)

# Caso o utilizador tenha passado o caminho como 1º argumento por engano
if ($TipoPermissao -and (Test-Path -LiteralPath $TipoPermissao -PathType Container) -and -not $Caminho) {
    $Caminho = $TipoPermissao
    $TipoPermissao = $null
}

# 1. Verificar e garantir privilégios de Administrador
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Warning "Este script necessita de ser executado como Administrador. A solicitar elevação de privilégios..."
    $argList = "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
    if ($TipoPermissao) { $argList += " -TipoPermissao `"$TipoPermissao`"" }
    if ($Caminho) { $argList += " -Caminho `"$Caminho`"" }
    if ($Desbloquear) { $argList += " -Desbloquear" }
    Start-Process powershell.exe -ArgumentList $argList -Verb RunAs
    exit
}

# 2. Perguntar o tipo de permissão (1º passo)
$modoPermissao = $null
if (-not $Desbloquear) {
    while ($modoPermissao -notin @("FullControl", "SemApagar")) {
        if (-not [string]::IsNullOrWhiteSpace($TipoPermissao)) {
            switch -Regex ($TipoPermissao.Trim().ToLower()) {
                "^(1|full|fullcontrol|full control|controlo total)$" { $modoPermissao = "FullControl"; break }
                "^(2|semapagar|sem apagar|sem_apagar|sem eliminar)$" { $modoPermissao = "SemApagar"; break }
                default {
                    Write-Host "Opção de permissão inválida: '$TipoPermissao'" -ForegroundColor Red
                    $TipoPermissao = $null
                }
            }
        }

        if (-not $modoPermissao) {
            Write-Host "`n================ TIPO DE PERMISSÃO ================" -ForegroundColor Cyan
            Write-Host "1 - Full Control (Controlo Total)"
            Write-Host "2 - Permissões sem apagar (Leitura/Escrita com bloqueio de eliminação)"
            Write-Host "===================================================" -ForegroundColor Cyan
            $entradaTipo = Read-Host "Selecione o tipo de permissão pretendido (1 ou 2)"
            if ([string]::IsNullOrWhiteSpace($entradaTipo)) {
                Write-Host "Opção não pode estar vazia. A cancelar operação." -ForegroundColor Yellow
                exit
            }

            switch -Regex ($entradaTipo.Trim().ToLower()) {
                "^(1|full|fullcontrol|full control|controlo total)$" { $modoPermissao = "FullControl" }
                "^(2|semapagar|sem apagar|sem_apagar|sem eliminar)$" { $modoPermissao = "SemApagar" }
                default {
                    Write-Host "Opção inválida. Por favor escolha 1 para Full Control ou 2 para Permissões sem apagar.`n" -ForegroundColor Yellow
                }
            }
        }
    }

    if ($modoPermissao -eq "FullControl") {
        Write-Host "`nTipo selecionado: Full Control (Controlo Total)" -ForegroundColor Green
    } else {
        Write-Host "`nTipo selecionado: Permissões sem apagar (Bloqueio de Eliminação)" -ForegroundColor Green
    }
}

# 3. Perguntar o caminho da pasta (2º passo)
while ([string]::IsNullOrWhiteSpace($Caminho) -or -not (Test-Path -LiteralPath $Caminho -PathType Container)) {
    if (-not [string]::IsNullOrWhiteSpace($Caminho)) {
        Write-Host "ERRO: O caminho especificado não existe ou não é uma diretoria válida: '$Caminho'" -ForegroundColor Red
    }
    $entrada = Read-Host "`nIntroduza o caminho da pasta a aplicar as permissões (ex: C:\Program Files\PRIMAVERA)"
    if ([string]::IsNullOrWhiteSpace($entrada)) {
        Write-Host "Caminho não pode estar vazio. A cancelar operação." -ForegroundColor Yellow
        exit
    }
    # Remover aspas caso o utilizador tenha colado o caminho com aspas
    $Caminho = $entrada.Trim().Trim('"').Trim("'")
}

Write-Host "`nPasta selecionada: $Caminho" -ForegroundColor Cyan

try {
    $acl = Get-Acl -LiteralPath $Caminho
    $everyoneSid = New-Object System.Security.Principal.SecurityIdentifier([System.Security.Principal.WellKnownSidType]::WorldSid, $null)
    $adminSid = New-Object System.Security.Principal.SecurityIdentifier([System.Security.Principal.WellKnownSidType]::BuiltinAdministratorsSid, $null)
    $systemSid = New-Object System.Security.Principal.SecurityIdentifier([System.Security.Principal.WellKnownSidType]::LocalSystemSid, $null)

    # Definir regra explícita de DENY (Delete e DeleteSubdirectoriesAndFiles)
    $denyRights = [System.Security.AccessControl.FileSystemRights]::Delete -bor [System.Security.AccessControl.FileSystemRights]::DeleteSubdirectoriesAndFiles
    $denyRule = New-Object System.Security.AccessControl.FileSystemAccessRule(
        $everyoneSid,
        $denyRights,
        [System.Security.AccessControl.InheritanceFlags]"ContainerInherit, ObjectInherit",
        [System.Security.AccessControl.PropagationFlags]::None,
        [System.Security.AccessControl.AccessControlType]::Deny
    )

    # Modo Desbloquear (remover proteção para manutenção)
    if ($Desbloquear) {
        Write-Host "Modo de desbloqueio ativado: A remover bloqueio de eliminação..." -ForegroundColor Yellow
        $acl.RemoveAccessRuleAll($denyRule)
        Set-Acl -LiteralPath $Caminho -AclObject $acl
        icacls "$Caminho\*" /reset /T /C | Out-Null
        Write-Host "Bloqueio de eliminação removido com sucesso em '$Caminho'." -ForegroundColor Green
        exit 0
    }

    Write-Host "A desativar herança e a configurar permissões..." -ForegroundColor Yellow

    # Desativar herança e remover regras herdadas da pasta pai
    $acl.SetAccessRuleProtection($true, $false)

    # Limpar regras residuais antigas
    foreach ($access in @($acl.Access)) {
        $acl.PurgeAccessRules($access.IdentityReference)
    }

    # Permitir Administradores (Full Control)
    $adminRule = New-Object System.Security.AccessControl.FileSystemAccessRule(
        $adminSid,
        [System.Security.AccessControl.FileSystemRights]::FullControl,
        [System.Security.AccessControl.InheritanceFlags]"ContainerInherit, ObjectInherit",
        [System.Security.AccessControl.PropagationFlags]::None,
        [System.Security.AccessControl.AccessControlType]::Allow
    )
    $acl.AddAccessRule($adminRule)

    # Permitir SYSTEM (Full Control)
    $systemRule = New-Object System.Security.AccessControl.FileSystemAccessRule(
        $systemSid,
        [System.Security.AccessControl.FileSystemRights]::FullControl,
        [System.Security.AccessControl.InheritanceFlags]"ContainerInherit, ObjectInherit",
        [System.Security.AccessControl.PropagationFlags]::None,
        [System.Security.AccessControl.AccessControlType]::Allow
    )
    $acl.AddAccessRule($systemRule)

    # Aplicar regra para o grupo Todos consoante a escolha do utilizador
    if ($modoPermissao -eq "FullControl") {
        Write-Host "A aplicar Controlo Total (Full Control) para Todos..." -ForegroundColor Yellow
        $everyoneRule = New-Object System.Security.AccessControl.FileSystemAccessRule(
            $everyoneSid,
            [System.Security.AccessControl.FileSystemRights]::FullControl,
            [System.Security.AccessControl.InheritanceFlags]"ContainerInherit, ObjectInherit",
            [System.Security.AccessControl.PropagationFlags]::None,
            [System.Security.AccessControl.AccessControlType]::Allow
        )
        $acl.AddAccessRule($everyoneRule)
    }
    elseif ($modoPermissao -eq "SemApagar") {
        Write-Host "A aplicar regras com bloqueio estrito de eliminação para Todos..." -ForegroundColor Yellow
        # REGRA CRÍTICA: Regra explícita de DENY (Negação) de Eliminação para Todos
        $acl.AddAccessRule($denyRule)

        # Permitir Todos (Leitura, Execução, Escrita e Sincronização)
        $allowRights = [System.Security.AccessControl.FileSystemRights]"ReadAndExecute, Write, Synchronize"
        $everyoneAllowRule = New-Object System.Security.AccessControl.FileSystemAccessRule(
            $everyoneSid,
            $allowRights,
            [System.Security.AccessControl.InheritanceFlags]"ContainerInherit, ObjectInherit",
            [System.Security.AccessControl.PropagationFlags]::None,
            [System.Security.AccessControl.AccessControlType]::Allow
        )
        $acl.AddAccessRule($everyoneAllowRule)
    }

    # Aplicar ACL na raiz da pasta selecionada
    Set-Acl -LiteralPath $Caminho -AclObject $acl
    Write-Host "Permissões aplicadas com sucesso na pasta raiz." -ForegroundColor Green

    # Propagar e forçar herança limpa a todos os ficheiros e subpastas
    Write-Host "A propagar regras a todos os ficheiros e subpastas..." -ForegroundColor Yellow
    icacls "$Caminho\*" /reset /T /C | Out-Null

    Write-Host "`nPermissões aplicadas e propagadas com sucesso." -ForegroundColor Green
    if ($modoPermissao -eq "FullControl") {
        Write-Host "A pasta '$Caminho' foi configurada com Controlo Total (Full Control)." -ForegroundColor Green
    } else {
        Write-Host "A eliminação de qualquer ficheiro ou pasta dentro de '$Caminho' está BLOQUEADA." -ForegroundColor Green
    }

    # Exibir resumo das permissões configuradas
    Write-Host "`n=== Permissões configuradas em $Caminho ===" -ForegroundColor Cyan
    icacls $Caminho
}
catch {
    Write-Host "ERRO: Ocorreu uma falha ao aplicar as permissões: $_" -ForegroundColor Red
    exit 1
}
