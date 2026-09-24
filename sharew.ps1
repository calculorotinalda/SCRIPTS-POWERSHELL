<#
.SYNOPSIS
    Configureert NTFS-machtigingen op een map of een uitvoerbaar bestand (.exe) naar keuze van de gebruiker (Volledig beheer, Alleen-lezen, Lezen en schrijven of Geen machtigingen).

.DESCRIPTION
    - Stap 1: Vraagt welk type machtiging moet worden toegepast:
        1. Volledig beheer (Full Control voor Iedereen/Everyone, Administrators en SYSTEM).
        2. Alleen-lezen (Alleen lezen en uitvoeren voor Iedereen, met expliciete DENY-verwijderblokkering - ZONDER schrijfrechten).
        3. Lezen en schrijven (Lezen, uitvoeren en schrijven voor Iedereen, met expliciete DENY-verwijderblokkering).
        4. Geen machtigingen (Geen toegang tot bestanden of mappen voor Iedereen - alleen Administrators en SYSTEM).
    - Stap 2: Vraagt het pad (map of .exe-bestand) waarop de machtigingen moeten worden toegepast.
        Voorbeeld map: C:\Program Files\PRIMAVERA
        Voorbeeld bestand: C:\Program Files (x86)\WINTOUCH\SGW\Wintouch.exe
    - Schakelt overname van machtigingen uit.
    - Behoudt Volledig beheer voor Administrators en SYSTEM.
    - Bij mappen: propageert en herstelt de regels recursief op alle bestaande submappen en bestanden.
    - Bij bestanden: past de machtigingen rechtstreeks toe op het uitvoerbare bestand.
    - Ondersteunt de optionele parameter -Desbloquear om de verwijderblokkering op te heffen voor onderhoud.
#>

[CmdletBinding()]
param (
    [Parameter(Position = 0, Mandatory = $false)]
    [string]$TipoPermissao,

    [Parameter(Position = 1, Mandatory = $false)]
    [string]$Caminho,

    [switch]$Desbloquear
)

# Configureer UTF-8 consolecodering voor correcte weergave van tekens
try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch {}

# Als de gebruiker het pad per ongeluk als eerste argument heeft doorgegeven
if ($TipoPermissao -and -not $Caminho -and ($TipoPermissao -notin @("1", "2", "3", "4", "full", "fullcontrol", "leitura", "soleitura", "semapagar", "nodelete", "lezen", "alleen-lezen", "geen", "geentoegang", "geen-toegang", "nopermission", "noaccess")) -and (Test-Path -LiteralPath $TipoPermissao)) {
    $Caminho = $TipoPermissao
    $TipoPermissao = $null
}

# Automatische correctie als het pad per ongeluk een voorvoegsel bevat (bijv. "...): C:\pad...")
if ($Caminho -and -not (Test-Path -LiteralPath $Caminho)) {
    $cClean = $Caminho.Trim().Trim('&').Trim().Trim('"').Trim("'").Trim()
    if ($cClean -match '(?:\):|\)\s*:)\s*(.+)$') {
        $extracted = $Matches[1].Trim().Trim('"').Trim("'")
        if (Test-Path -LiteralPath $extracted) {
            $Caminho = $extracted
        }
    }
}

# 1. Beheerdersrechten controleren en aanvragen indien nodig
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Warning "Dit script moet als Administrator worden uitgevoerd. Beheerdersrechten worden aangevraagd..."
    $scriptPath = $PSCommandPath
    if (-not $scriptPath) { $scriptPath = $MyInvocation.MyCommand.Definition }
    $argList = "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`""
    if ($TipoPermissao) { $argList += " -TipoPermissao `"$TipoPermissao`"" }
    if ($Caminho) { $argList += " -Caminho `"$Caminho`"" }
    if ($Desbloquear) { $argList += " -Desbloquear" }
    Start-Process powershell.exe -ArgumentList $argList -Verb RunAs
    exit
}

# 2. Vraag het type machtiging (stap 1)
$modoPermissao = $null
if (-not $Desbloquear) {
    $tentativasTipo = 0
    while ($modoPermissao -notin @("FullControl", "SoLeitura", "LeituraEscrita", "GeenToegang")) {
        if (-not [string]::IsNullOrWhiteSpace($TipoPermissao)) {
            switch -Regex ($TipoPermissao.Trim().ToLower()) {
                "^(1|full|fullcontrol|full control|volledig|volledig beheer|controlo total)$" { $modoPermissao = "FullControl"; break }
                "^(2|lezen|alleen lezen|alleen-lezen|alleenlezen|read|readonly|read-only|so leitura|so_leitura|só leitura|só_leitura|soleitura|leitura)$" { $modoPermissao = "SoLeitura"; break }
                "^(3|lezen en schrijven|schrijven|semapagar|sem apagar|sem_apagar|escrita|leituraescrita|leitura e escrita|lezen en schrijven|nodelete)$" { $modoPermissao = "LeituraEscrita"; break }
                "^(4|geen|geen toegang|geen_toegang|geen machtiging|geen machtigingen|geen_machtigingen|no permission|no permissions|nopermission|no access|noaccess|none|sem permissao|sem permissão|sem_permissao|sem_permissão|bloquear)$" { $modoPermissao = "GeenToegang"; break }
                default {
                    Write-Host "Ongeldige machtigingsoptie: '$TipoPermissao'" -ForegroundColor Red
                    $TipoPermissao = $null
                }
            }
        }

        if (-not $modoPermissao) {
            if ([Console]::IsInputRedirected) {
                Write-Host "Niet-interactieve uitvoering gedetecteerd: geef het type machtiging en het pad op via parameters." -ForegroundColor Yellow
                Write-Host "Voorbeeld: .\sharew.ps1 -TipoPermissao 4 -Caminho `"C:\pad\naar\bestand.exe`"`n" -ForegroundColor Cyan
                exit 1
            }

            Write-Host "`n================ TYPE MACHTIGING ================" -ForegroundColor Cyan
            Write-Host "1 - Volledig beheer (Full Control)"
            Write-Host "2 - Alleen-lezen (Lezen en uitvoeren met verwijderblokkering - ZONDER schrijven)"
            Write-Host "3 - Lezen en schrijven (met verwijderblokkering)"
            Write-Host "4 - Geen machtigingen (Geen toegang tot bestanden of mappen - No permission)"
            Write-Host "=================================================" -ForegroundColor Cyan
            $entradaTipo = Read-Host "Selecteer het gewenste type machtiging (1, 2, 3 of 4)"
            if ([string]::IsNullOrWhiteSpace($entradaTipo)) {
                $tentativasTipo++
                if ($tentativasTipo -ge 3) {
                    Write-Host "Optie mag niet leeg zijn. Bewerking geannuleerd na 3 pogingen." -ForegroundColor Yellow
                    exit 1
                }
                Write-Host "Optie mag niet leeg zijn. Voer alstublieft 1, 2, 3 of 4 in.`n" -ForegroundColor Yellow
                continue
            }

            switch -Regex ($entradaTipo.Trim().ToLower()) {
                "^(1|full|fullcontrol|full control|volledig|volledig beheer|controlo total)$" { $modoPermissao = "FullControl" }
                "^(2|lezen|alleen lezen|alleen-lezen|alleenlezen|read|readonly|read-only|so leitura|so_leitura|só leitura|só_leitura|soleitura|leitura)$" { $modoPermissao = "SoLeitura" }
                "^(3|lezen en schrijven|schrijven|semapagar|sem apagar|sem_apagar|escrita|leituraescrita|leitura e escrita|lezen en schrijven|nodelete)$" { $modoPermissao = "LeituraEscrita" }
                "^(4|geen|geen toegang|geen_toegang|geen machtiging|geen machtigingen|geen_machtigingen|no permission|no permissions|nopermission|no access|noaccess|none|sem permissao|sem permissão|sem_permissao|sem_permissão|bloquear)$" { $modoPermissao = "GeenToegang" }
                default {
                    Write-Host "Ongeldige optie. Kies 1 voor Volledig beheer, 2 voor Alleen-lezen, 3 voor Lezen en schrijven of 4 voor Geen machtigingen.`n" -ForegroundColor Yellow
                }
            }
        }
    }

    if ($modoPermissao -eq "FullControl") {
        Write-Host "`nGeselecteerd type: Volledig beheer (Full Control)" -ForegroundColor Green
    } elseif ($modoPermissao -eq "SoLeitura") {
        Write-Host "`nGeselecteerd type: Alleen-lezen (Verwijderblokkering en zonder schrijven)" -ForegroundColor Green
    } elseif ($modoPermissao -eq "LeituraEscrita") {
        Write-Host "`nGeselecteerd type: Lezen en schrijven (Verwijderblokkering)" -ForegroundColor Green
    } else {
        Write-Host "`nGeselecteerd type: Geen machtigingen (Geen toegang tot bestanden of mappen)" -ForegroundColor Green
    }
}

# 3. Vraag het pad naar de map of het bestand (stap 2)
$tentativasCaminho = 0
while ([string]::IsNullOrWhiteSpace($Caminho) -or -not (Test-Path -LiteralPath $Caminho)) {
    if (-not [string]::IsNullOrWhiteSpace($Caminho)) {
        Write-Host "FOUT: Het opgegeven pad bestaat niet of is ongeldig: '$Caminho'" -ForegroundColor Red
    }

    if ([Console]::IsInputRedirected) {
        Write-Host "Niet-interactieve uitvoering gedetecteerd: geef het pad op via parameter." -ForegroundColor Yellow
        Write-Host "Voorbeeld: .\sharew.ps1 -TipoPermissao 4 -Caminho `"C:\pad\naar\bestand.exe`"`n" -ForegroundColor Cyan
        exit 1
    }

    $entrada = Read-Host "`nVoer het pad in van de map of het uitvoerbare bestand (.exe) waarop de machtigingen moeten worden toegepast (bijv. C:\Program Files\PRIMAVERA of C:\Program Files (x86)\WINTOUCH\SGW\Wintouch.exe)"
    if ([string]::IsNullOrWhiteSpace($entrada)) {
        $tentativasCaminho++
        if ($tentativasCaminho -ge 3) {
            Write-Host "Pad mag niet leeg zijn. Bewerking geannuleerd na 3 pogingen." -ForegroundColor Yellow
            exit 1
        }
        Write-Host "Pad mag niet leeg zijn. Voer alstublieft het volledige pad in.`n" -ForegroundColor Yellow
        continue
    }
    # Verwijder aanhalingstekens of voorvoegsels als de gebruiker het pad heeft geplakt
    $Caminho = $entrada.Trim().Trim('&').Trim().Trim('"').Trim("'").Trim()

    # Als de gebruiker per ongeluk een deel van de vraag heeft meegeplakt (bijv. "...): C:\pad...")
    if (-not (Test-Path -LiteralPath $Caminho)) {
        if ($Caminho -match '(?:\):|\)\s*:)\s*(.+)$') {
            $extracted = $Matches[1].Trim().Trim('"').Trim("'")
            if (Test-Path -LiteralPath $extracted) {
                $Caminho = $extracted
            }
        }
    }
}

$Caminho = (Resolve-Path -LiteralPath $Caminho).Path
$isContainer = (Test-Path -LiteralPath $Caminho -PathType Container)

if ($isContainer) {
    Write-Host "`nGeselecteerde map: $Caminho" -ForegroundColor Cyan
} else {
    Write-Host "`nGeselecteerd bestand: $Caminho" -ForegroundColor Cyan
}

try {
    $acl = Get-Acl -LiteralPath $Caminho
    $everyoneSid = New-Object System.Security.Principal.SecurityIdentifier([System.Security.Principal.WellKnownSidType]::WorldSid, $null)
    $adminSid = New-Object System.Security.Principal.SecurityIdentifier([System.Security.Principal.WellKnownSidType]::BuiltinAdministratorsSid, $null)
    $systemSid = New-Object System.Security.Principal.SecurityIdentifier([System.Security.Principal.WellKnownSidType]::LocalSystemSid, $null)

    # Configuratie van overnamevlaggen en weigeringsrechten afhankelijk van map of bestand
    if ($isContainer) {
        $inheritFlags = [System.Security.AccessControl.InheritanceFlags]"ContainerInherit, ObjectInherit"
        $propagationFlags = [System.Security.AccessControl.PropagationFlags]::None
        $denyRights = [System.Security.AccessControl.FileSystemRights]::Delete -bor [System.Security.AccessControl.FileSystemRights]::DeleteSubdirectoriesAndFiles
    } else {
        $inheritFlags = [System.Security.AccessControl.InheritanceFlags]::None
        $propagationFlags = [System.Security.AccessControl.PropagationFlags]::None
        $denyRights = [System.Security.AccessControl.FileSystemRights]::Delete
    }

    # Definieer expliciete DENY-regel voor verwijderen
    $denyRule = New-Object System.Security.AccessControl.FileSystemAccessRule(
        $everyoneSid,
        $denyRights,
        $inheritFlags,
        $propagationFlags,
        [System.Security.AccessControl.AccessControlType]::Deny
    )

    # Ontgrendelingsmodus (verwijderblokkering opheffen voor onderhoud)
    if ($Desbloquear) {
        Write-Host "Ontgrendelingsmodus geactiveerd: Verwijderblokkering opheffen..." -ForegroundColor Yellow
        $acl.RemoveAccessRuleAll($denyRule)
        # Eventuele overige weigeringsregels van de groep Everyone verwijderen
        foreach ($access in @($acl.Access)) {
            if ($access.AccessControlType -eq [System.Security.AccessControl.AccessControlType]::Deny -and $access.IdentityReference.Value -eq $everyoneSid.Value) {
                $acl.RemoveAccessRule($access)
            }
        }
        Set-Acl -LiteralPath $Caminho -AclObject $acl
        if ($isContainer) {
            icacls "$Caminho\*" /reset /T /C | Out-Null
        }
        Write-Host "Verwijderblokkering succesvol verwijderd voor '$Caminho'." -ForegroundColor Green
        exit 0
    }

    Write-Host "Overname van machtigingen uitschakelen en nieuwe machtigingen configureren..." -ForegroundColor Yellow

    # Overname uitschakelen en overgeërfde regels van bovenliggende map verwijderen
    $acl.SetAccessRuleProtection($true, $false)

    # Oude resterende regels opschonen
    foreach ($access in @($acl.Access)) {
        $acl.PurgeAccessRules($access.IdentityReference)
    }

    # Administrators toestaan (Full Control)
    $adminRule = New-Object System.Security.AccessControl.FileSystemAccessRule(
        $adminSid,
        [System.Security.AccessControl.FileSystemRights]::FullControl,
        $inheritFlags,
        $propagationFlags,
        [System.Security.AccessControl.AccessControlType]::Allow
    )
    $acl.AddAccessRule($adminRule)

    # SYSTEM toestaan (Full Control)
    $systemRule = New-Object System.Security.AccessControl.FileSystemAccessRule(
        $systemSid,
        [System.Security.AccessControl.FileSystemRights]::FullControl,
        $inheritFlags,
        $propagationFlags,
        [System.Security.AccessControl.AccessControlType]::Allow
    )
    $acl.AddAccessRule($systemRule)

    # Regel voor de groep Iedereen (Everyone) toepassen volgens de keuze van de gebruiker
    if ($modoPermissao -eq "FullControl") {
        Write-Host "Volledig beheer (Full Control) toepassen voor Iedereen (Everyone)..." -ForegroundColor Yellow
        $everyoneRule = New-Object System.Security.AccessControl.FileSystemAccessRule(
            $everyoneSid,
            [System.Security.AccessControl.FileSystemRights]::FullControl,
            $inheritFlags,
            $propagationFlags,
            [System.Security.AccessControl.AccessControlType]::Allow
        )
        $acl.AddAccessRule($everyoneRule)
    }
    elseif ($modoPermissao -eq "SoLeitura") {
        Write-Host "Alleen-lezen machtigingen (met verwijderblokkering en zonder schrijven) toepassen voor Iedereen (Everyone)..." -ForegroundColor Yellow
        # EXPLICIETE DENY-regel: Verwijderen blokkeren voor Iedereen
        $acl.AddAccessRule($denyRule)

        # Iedereen ALLEEN Lezen en Uitvoeren toestaan (ZONDER schrijfrechten)
        $allowRights = [System.Security.AccessControl.FileSystemRights]"ReadAndExecute, Synchronize"
        $everyoneAllowRule = New-Object System.Security.AccessControl.FileSystemAccessRule(
            $everyoneSid,
            $allowRights,
            $inheritFlags,
            $propagationFlags,
            [System.Security.AccessControl.AccessControlType]::Allow
        )
        $acl.AddAccessRule($everyoneAllowRule)
    }
    elseif ($modoPermissao -eq "LeituraEscrita") {
        Write-Host "Machtigingen voor lezen en schrijven met verwijderblokkering toepassen voor Iedereen (Everyone)..." -ForegroundColor Yellow
        # EXPLICIETE DENY-regel: Verwijderen blokkeren voor Iedereen
        $acl.AddAccessRule($denyRule)

        # Iedereen toestaan (Lezen, Uitvoeren, Schrijven en Synchroniseren)
        $allowRights = [System.Security.AccessControl.FileSystemRights]"ReadAndExecute, Write, Synchronize"
        $everyoneAllowRule = New-Object System.Security.AccessControl.FileSystemAccessRule(
            $everyoneSid,
            $allowRights,
            $inheritFlags,
            $propagationFlags,
            [System.Security.AccessControl.AccessControlType]::Allow
        )
        $acl.AddAccessRule($everyoneAllowRule)
    }
    elseif ($modoPermissao -eq "GeenToegang") {
        Write-Host "Geen machtigingen configureren (toegang ontzegd voor alle standaardgebruikers)..." -ForegroundColor Yellow
        # Geen enkele 'Allow'-regel toevoegen voor Iedereen (Everyone).
        # Alleen Administrators en SYSTEM behouden volledige toegang.
    }

    # ACL toepassen op het geselecteerde object (hoofdmap of bestand)
    Set-Acl -LiteralPath $Caminho -AclObject $acl
    if ($isContainer) {
        Write-Host "Machtigingen succesvol toegepast op de hoofdmap." -ForegroundColor Green
        # Schone overname forceren op alle bestanden en submappen
        Write-Host "Regels doorvoeren naar alle bestanden en submappen..." -ForegroundColor Yellow
        icacls "$Caminho\*" /reset /T /C | Out-Null
    } else {
        Write-Host "Machtigingen succesvol toegepast op het bestand." -ForegroundColor Green
    }

    Write-Host "`nMachtigingen succesvol toegepast en geconfigureerd." -ForegroundColor Green
    if ($modoPermissao -eq "FullControl") {
        if ($isContainer) {
            Write-Host "De map '$Caminho' is geconfigureerd met Volledig beheer (Full Control)." -ForegroundColor Green
        } else {
            Write-Host "Het bestand '$Caminho' is geconfigureerd met Volledig beheer (Full Control)." -ForegroundColor Green
        }
    } elseif ($modoPermissao -eq "SoLeitura") {
        if ($isContainer) {
            Write-Host "De map '$Caminho' is geconfigureerd als ALLEEN-LEZEN (verwijderen en schrijven zijn GEBLOKKEERD)." -ForegroundColor Green
        } else {
            Write-Host "Het bestand '$Caminho' is geconfigureerd als ALLEEN-LEZEN (verwijderen en schrijven zijn GEBLOKKEERD)." -ForegroundColor Green
        }
    } elseif ($modoPermissao -eq "LeituraEscrita") {
        if ($isContainer) {
            Write-Host "De map '$Caminho' is geconfigureerd met Lezen/Schrijven en verwijderen is GEBLOKKEERD." -ForegroundColor Green
        } else {
            Write-Host "Het bestand '$Caminho' is geconfigureerd met Lezen/Schrijven en verwijderen is GEBLOKKEERD." -ForegroundColor Green
        }
    } else {
        if ($isContainer) {
            Write-Host "De map '$Caminho' is geconfigureerd met GEEN MACHTIGINGEN (toegang ontzegd voor alle standaardgebruikers)." -ForegroundColor Green
        } else {
            Write-Host "Het bestand '$Caminho' is geconfigureerd met GEEN MACHTIGINGEN (toegang ontzegd voor alle standaardgebruikers)." -ForegroundColor Green
        }
    }

    # Overzicht van de geconfigureerde machtigingen weergeven
    Write-Host "`n=== Geconfigureerde machtigingen op $Caminho ===" -ForegroundColor Cyan
    icacls $Caminho
}
catch {
    Write-Host "FOUT: Er is een fout opgetreden bij het toepassen van de machtigingen: $_" -ForegroundColor Red
    exit 1
}
