<#
.SYNOPSIS
    Configura as permissões NTFS na pasta C:\Program Files\PRIMAVERA e em todas as pastas e ficheiros para impedir expressamente a sua eliminação.

.DESCRIPTION
    1. Remove a herança de permissões provenientes de C:\Program Files.
    2. Concede permissões ao grupo "Todos" (Everyone) de Leitura, Execução e Escrita.
    3. Aplica uma regra explícita de NEGAÇÃO (DENY) de Eliminação (Delete e DeleteSubdirectoriesAndFiles) ao grupo "Todos".
       No Windows NTFS, uma regra DENY tem prioridade máxima sobre qualquer permissão ALLOW,
       garantindo que NINGUÉM (nem administradores, nem o utilizador que criou o ficheiro) consiga apagar ficheiros ou pastas.
    4. Mantém Controlo Total para Administradores e SYSTEM para efeitos de permissões e gestão.
    5. Propaga e força a herança de forma limpa a todos os ficheiros e subpastas existentes.
#>

[CmdletBinding()]
param (
    [switch]$Desbloquear  # Executar com -Desbloquear se no futuro precisar de remover a proteção para manutenção
)

# 1. Verificar e garantir privilégios de Administrador
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Warning "Este script necessita de ser executado como Administrador. A solicitar elevação de privilégios..."
    Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

$caminho = "C:\Program Files\PRIMAVERA"
Write-Host "Pasta selecionada: $caminho" -ForegroundColor Cyan

# 2. Validar se a pasta de destino existe
if (-not (Test-Path -LiteralPath $caminho)) {
    Write-Host "ERRO: A pasta não existe: $caminho" -ForegroundColor Red
    exit 1
}

try {
    $acl = Get-Acl -LiteralPath $caminho
    $everyoneSid = New-Object System.Security.Principal.SecurityIdentifier([System.Security.Principal.WellKnownSidType]::WorldSid, $null)
    $adminSid = New-Object System.Security.Principal.SecurityIdentifier([System.Security.Principal.WellKnownSidType]::BuiltinAdministratorsSid, $null)
    $systemSid = New-Object System.Security.Principal.SecurityIdentifier([System.Security.Principal.WellKnownSidType]::LocalSystemSid, $null)

    $denyRights = [System.Security.AccessControl.FileSystemRights]::Delete -bor [System.Security.AccessControl.FileSystemRights]::DeleteSubdirectoriesAndFiles
    $denyRule = New-Object System.Security.AccessControl.FileSystemAccessRule(
        $everyoneSid,
        $denyRights,
        [System.Security.AccessControl.InheritanceFlags]"ContainerInherit, ObjectInherit",
        [System.Security.AccessControl.PropagationFlags]::None,
        [System.Security.AccessControl.AccessControlType]::Deny
    )

    if ($Desbloquear) {
        Write-Host "A remover regra de bloqueio de eliminação..." -ForegroundColor Yellow
        $acl.RemoveAccessRuleAll($denyRule)
        Set-Acl -LiteralPath $caminho -AclObject $acl
        icacls "$caminho\*" /reset /T /C | Out-Null
        Write-Host "Bloqueio de eliminação removido com sucesso." -ForegroundColor Green
        exit 0
    }

    Write-Host "A remover herança e a aplicar bloqueio estrito de eliminação..." -ForegroundColor Yellow

    # Desativar herança e remover regras herdadas
    $acl.SetAccessRuleProtection($true, $false)

    # Limpar regras residuais antigas
    foreach ($access in @($acl.Access)) {
        $acl.PurgeAccessRules($access.IdentityReference)
    }

    # REGRA CRÍTICA: Regra explícita de DENY (Negação) de Eliminação para Todos
    # Previne a eliminação de ficheiros (Delete) e a eliminação de subpastas/ficheiros filhos (DeleteSubdirectoriesAndFiles)
    $acl.AddAccessRule($denyRule)

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

    # Aplicar na raiz
    Set-Acl -LiteralPath $caminho -AclObject $acl
    Write-Host "Permissões aplicadas com sucesso na pasta raiz." -ForegroundColor Green

    # Propagar a todos os ficheiros e subpastas existentes
    Write-Host "A propagar regras a todos os ficheiros e subpastas..." -ForegroundColor Yellow
    icacls "$caminho\*" /reset /T /C | Out-Null

    Write-Host "Permissões aplicadas e propagadas com sucesso." -ForegroundColor Green
    Write-Host "A eliminação de qualquer ficheiro ou pasta dentro de '$caminho' está BLOQUEADA." -ForegroundColor Green

    Write-Host "`n=== Permissões configuradas em $caminho ===" -ForegroundColor Cyan
    icacls $caminho
}
catch {
    Write-Host "ERRO: Ocorreu uma falha ao aplicar as permissões: $_" -ForegroundColor Red
    exit 1
}
