#Requires -Version 5.1

<#
====================================================================
 WINDOWS 11 - PROJECT FILE AUDITOR
====================================================================

Monitoriza projetos de:

  C# / .NET
  Visual Studio
  Python
  Node.js
  JavaScript
  TypeScript
  React
  Angular
  Vue
  HTML / CSS
  Chrome Extensions
  VS Code
  Docker
  Git / CI/CD
  Configurações

DETECTA:

  CREATED
  MODIFIED
  DELETED
  RENAMED

GUARDA:

  SHA-256
  versões anteriores
  diferenças de texto
  tamanho anterior/novo
  data/hora
  utilizador/processo quando disponível através da auditoria
  relatório HTML
  CSV
  LOG

====================================================================
#>

$ErrorActionPreference = "SilentlyContinue"

# ================================================================
# CONFIGURAÇÃO
# ================================================================

# Altere para a pasta onde estão os seus projetos.
#
# Exemplos:
#
# $MonitorPath = "$env:USERPROFILE\source\repos"
# $MonitorPath = "$env:USERPROFILE\Documents\"
# $MonitorPath = "D:\Projetos"
#
$MonitorPath = "$env:USERPROFILE\Documents"

# Pasta onde o sistema guarda os dados
$StoragePath = "$env:USERPROFILE\FileAudit"

# Tamanho máximo por versão guardada
$MaxBackupSize = 50MB

# ================================================================
# EXTENSÕES C# / .NET
# ================================================================

$CSharpExtensions = @(

    ".cs",
    ".csx",
    ".cshtml",
    ".razor",
    ".csproj",
    ".fs",
    ".fsx",
    ".fsi",
    ".fsproj",
    ".vb",
    ".vbhtml",
    ".vbproj",

    ".sln",
    ".slnx",
    ".suo",

    ".props",
    ".targets",
    ".proj",
    ".projitems",

    ".resx",
    ".resources",

    ".xaml",
    ".xaml.cs",

    ".config",

    ".ruleset",
    ".editorconfig",

    ".runsettings",

    ".nupkg",
    ".nuspec",

    ".snk",

    ".dll.config",
    ".exe.config",

    ".json"
)

# ================================================================
# PYTHON
# ================================================================

$PythonExtensions = @(

    ".py",
    ".pyw",
    ".pyi",
    ".pyx",
    ".pxd",
    ".pxi",

    ".pyc",
    ".pyo",

    ".ipynb",

    ".toml",
    ".ini",
    ".cfg",

    ".pickle",
    ".pkl"
)

# ================================================================
# NODE.JS / JAVASCRIPT / TYPESCRIPT
# ================================================================

$NodeExtensions = @(

    ".js",
    ".jsx",

    ".ts",
    ".tsx",

    ".mjs",
    ".cjs",

    ".mts",
    ".cts",

    ".map",

    ".json",

    ".json5",

    ".npmrc",
    ".nvmrc",

    ".yarnrc",
    ".yarnrc.yml",

    ".babelrc",
    ".babelrc.json",
    ".babelrc.js",

    ".eslintrc",
    ".eslintrc.js",
    ".eslintrc.json",
    ".eslintignore",

    ".prettierrc",
    ".prettierrc.json",
    ".prettierignore",

    ".stylelintrc",
    ".stylelintrc.json",

    ".swcrc",

    ".graphql",
    ".gql"
)

# ================================================================
# WEB
# ================================================================

$WebExtensions = @(

    ".html",
    ".htm",

    ".css",
    ".scss",
    ".sass",
    ".less",

    ".svg",

    ".xml",

    ".webmanifest",

    ".wasm",

    ".astro",

    ".svelte",

    ".vue",

    ".handlebars",
    ".hbs",

    ".ejs",

    ".pug",

    ".jade",

    ".twig",

    ".liquid"
)

# ================================================================
# REACT / ANGULAR / VUE
# ================================================================

$FrameworkExtensions = @(

    ".jsx",
    ".tsx",

    ".vue",
    ".svelte",

    ".component.ts",
    ".component.html",
    ".component.scss",
    ".component.css",

    ".module.css",
    ".module.scss",

    ".stories.js",
    ".stories.jsx",
    ".stories.ts",
    ".stories.tsx",

    ".spec.js",
    ".spec.jsx",
    ".spec.ts",
    ".spec.tsx",

    ".test.js",
    ".test.jsx",
    ".test.ts",
    ".test.tsx"
)

# ================================================================
# CHROME EXTENSIONS / BROWSER EXTENSIONS
# ================================================================

$ChromeExtensions = @(

    # Manifest
    ".json",

    # JavaScript
    ".js",
    ".mjs",
    ".cjs",

    # TypeScript
    ".ts",
    ".tsx",

    # HTML
    ".html",
    ".htm",

    # CSS
    ".css",
    ".scss",
    ".sass",
    ".less",

    # SVG / imagens vetoriais
    ".svg",

    # WebAssembly
    ".wasm",

    # Service workers
    ".js",

    # Localization
    ".json",

    # Templates
    ".html",
    ".hbs",
    ".handlebars",

    # Source maps
    ".map"
)

# ================================================================
# VS CODE
# ================================================================

$VSCodeExtensions = @(

    ".code-workspace",

    ".code-snippets",

    ".vscode",

    ".json",
    ".jsonc"
)

# ================================================================
# DOCKER
# ================================================================

$DockerExtensions = @(

    ".dockerfile",

    ".dockerignore",

    ".containerignore",

    ".yaml",
    ".yml",

    ".compose.yml",
    ".compose.yaml"
)

# ================================================================
# GIT / CI/CD
# ================================================================

$DevOpsExtensions = @(

    ".gitignore",
    ".gitattributes",

    ".gitmodules",

    ".gitkeep",

    ".yaml",
    ".yml",

    ".toml",

    ".ini",

    ".env",
    ".env.local",
    ".env.development",
    ".env.production",
    ".env.test",

    ".properties",

    ".tf",
    ".tfvars",

    ".hcl"
)

# ================================================================
# DATABASE / SQL
# ================================================================

$DatabaseExtensions = @(

    ".sql",

    ".sqlite",
    ".sqlite3",

    ".db",

    ".prisma",

    ".graphql",
    ".gql"
)

# ================================================================
# TESTES
# ================================================================

$TestExtensions = @(

    ".test.js",
    ".test.jsx",
    ".test.ts",
    ".test.tsx",

    ".spec.js",
    ".spec.jsx",
    ".spec.ts",
    ".spec.tsx",

    ".feature",

    ".robot",

    ".http"
)

# ================================================================
# DOCUMENTAÇÃO / CONFIGURAÇÃO
# ================================================================

$DocumentationExtensions = @(

    ".md",
    ".markdown",

    ".txt",

    ".rst",

    ".adoc",

    ".csv",

    ".xml",

    ".yaml",
    ".yml",

    ".json",
    ".jsonc",

    ".toml",

    ".ini",

    ".cfg",

    ".conf",

    ".config",

    ".properties",

    ".env"
)

# ================================================================
# EXTENSÕES DE TEXTO ADICIONAIS
# ================================================================

$OtherTextExtensions = @(

    ".bat",
    ".cmd",

    ".ps1",
    ".psm1",
    ".psd1",

    ".sh",
    ".bash",
    ".zsh",

    ".fish",

    ".sql",

    ".lua",
    ".rb",
    ".php",
    ".go",
    ".rs",
    ".java",
    ".kt",
    ".swift",

    ".c",
    ".h",
    ".cpp",
    ".hpp",

    ".asm",

    ".proto",

    ".graphql",

    ".make",

    ".gradle",

    ".cs"
)

# ================================================================
# JUNTAR TODAS AS EXTENSÕES
# ================================================================

$TextExtensions = @(
    $CSharpExtensions
    $PythonExtensions
    $NodeExtensions
    $WebExtensions
    $FrameworkExtensions
    $ChromeExtensions
    $VSCodeExtensions
    $DockerExtensions
    $DevOpsExtensions
    $DatabaseExtensions
    $TestExtensions
    $DocumentationExtensions
    $OtherTextExtensions
) |
    ForEach-Object {
        $_.ToLower()
    } |
    Sort-Object -Unique

# ================================================================
# FICHEIROS SEM EXTENSÃO IMPORTANTES
# ================================================================

$ImportantFilesWithoutExtension = @(

    "Dockerfile",
    "dockerfile",

    "Makefile",
    "makefile",

    "Jenkinsfile",

    "Procfile",

    "Vagrantfile",

    "Gemfile",

    "Rakefile",

    "Brewfile",

    "LICENSE",

    "README",

    "README.md",

    "CHANGELOG",

    "AUTHORS",

    "CONTRIBUTING",

    "CODEOWNERS",

    "MANIFEST",

    "requirements",

    "Pipfile",

    "Justfile",

    "Taskfile"
)

# ================================================================
# CAMINHOS
# ================================================================

$DatabasePath = Join-Path $StoragePath "database.json"

$LogPath = Join-Path $StoragePath "events.csv"

$TextLogPath = Join-Path $StoragePath "events.log"

$HtmlPath = Join-Path $StoragePath "report.html"

$VersionsPath = Join-Path $StoragePath "Versions"

# ================================================================
# VERIFICAR ADMIN
# ================================================================

$Identity = [Security.Principal.WindowsIdentity]::GetCurrent()

$Principal = New-Object Security.Principal.WindowsPrincipal($Identity)

if (-not $Principal.IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator
)) {

    Write-Host ""
    Write-Host "ERRO: execute PowerShell como Administrador." `
        -ForegroundColor Red

    exit 1
}

# ================================================================
# CRIAR PASTAS
# ================================================================

foreach ($Folder in @(
    $StoragePath,
    $VersionsPath
)) {

    if (-not (Test-Path $Folder)) {

        New-Item `
            -ItemType Directory `
            -Path $Folder `
            -Force |
            Out-Null
    }
}

# ================================================================
# VERIFICAR SE O CAMINHO EXISTE
# ================================================================

if (-not (Test-Path $MonitorPath)) {

    Write-Host ""
    Write-Host "A pasta não existe:" -ForegroundColor Red
    Write-Host $MonitorPath
    Write-Host ""

    exit 1
}

# ================================================================
# FUNÇÃO HASH
# ================================================================

function Get-SHA256 {

    param(
        [string]$File
    )

    try {

        if (Test-Path $File -PathType Leaf) {

            return (
                Get-FileHash `
                    -Path $File `
                    -Algorithm SHA256 `
                    -ErrorAction Stop
            ).Hash
        }

    }
    catch {}

    return ""
}

# ================================================================
# FUNÇÃO - VERIFICAR SE É FICHEIRO DE TEXTO
# ================================================================

function Is-TextFile {

    param(
        [string]$File
    )

    $Name = [IO.Path]::GetFileName($File)

    if ($ImportantFilesWithoutExtension -contains $Name) {
        return $true
    }

    $Extension = [IO.Path]::GetExtension($File).ToLower()

    return $TextExtensions -contains $Extension
}

# ================================================================
# FUNÇÃO - NOME SEGURO
# ================================================================

function Get-SafeName {

    param(
        [string]$Path
    )

    $Bytes = [Text.Encoding]::UTF8.GetBytes($Path)

    return (
        [Convert]::ToBase64String($Bytes)
    ).Replace("=","").Replace("/","_").Replace("+","-")
}

# ================================================================
# FUNÇÃO - GUARDAR VERSÃO
# ================================================================

function Save-Version {

    param(
        [string]$File
    )

    try {

        if (-not (Test-Path $File -PathType Leaf)) {
            return ""
        }

        $Info = Get-Item $File

        if ($Info.Length -gt $MaxBackupSize) {

            return ""
        }

        $SafeName = Get-SafeName $File

        $Folder = Join-Path `
            $VersionsPath `
            $SafeName

        if (-not (Test-Path $Folder)) {

            New-Item `
                -ItemType Directory `
                -Path $Folder `
                -Force |
                Out-Null
        }

        $Timestamp = Get-Date `
            -Format "yyyyMMdd_HHmmss_fff"

        $Destination = Join-Path `
            $Folder `
            "$Timestamp-$($Info.Name)"

        Copy-Item `
            -Path $File `
            -Destination $Destination `
            -Force

        return $Destination
    }
    catch {

        return ""
    }
}

# ================================================================
# FUNÇÃO - COMPARAR TEXTO
# ================================================================

function Compare-TextVersion {

    param(
        [string]$OldFile,
        [string]$NewFile
    )

    if (-not (Test-Path $OldFile)) {
        return ""
    }

    if (-not (Test-Path $NewFile)) {
        return ""
    }

    if (-not (Is-TextFile $NewFile)) {
        return ""
    }

    try {

        $Old = Get-Content `
            -Path $OldFile `
            -ErrorAction Stop

        $New = Get-Content `
            -Path $NewFile `
            -ErrorAction Stop

        $Difference = Compare-Object `
            -ReferenceObject $Old `
            -DifferenceObject $New `
            -IncludeEqual:$false

        if (-not $Difference) {
            return "Sem diferença textual."
        }

        $Result = @()

        foreach ($Line in $Difference) {

            if ($Line.SideIndicator -eq "<=") {

                $Result += "- $($Line.InputObject)"
            }

            elseif ($Line.SideIndicator -eq "=>") {

                $Result += "+ $($Line.InputObject)"
            }
        }

        return ($Result -join "`r`n")

    }
    catch {

        return "Não foi possível comparar."
    }
}

# ================================================================
# FUNÇÃO - OBTER UTILIZADOR/PROCESSO VIA AUDITORIA DO WINDOWS
# ================================================================

function Get-AuditActor {

    param(
        [string]$File
    )

    try {

        # Procura nos últimos 3 segundos eventos 4663 (tentativa de acesso a objeto com êxito)
        $FilterXml = @"
<QueryList>
  <Query Id="0" Path="Security">
    <Select Path="Security">*[System[(EventID=4663) and TimeCreated[timediff(@SystemTime) &lt;= 3000]]]</Select>
  </Query>
</QueryList>
"@

        $Events = Get-WinEvent -FilterXml $FilterXml -MaxEvents 10 -ErrorAction Stop

        foreach ($Evt in $Events) {

            $ObjectName = $Evt.Properties[6].Value

            if ($ObjectName -eq $File) {

                $SubjectUserName = $Evt.Properties[1].Value
                $ProcessName = [IO.Path]::GetFileName($Evt.Properties[11].Value)

                if ($SubjectUserName -and $ProcessName) {
                    return "$SubjectUserName ($ProcessName)"
                }
            }
        }
    }
    catch {}

    return ""
}

# ================================================================
# FUNÇÃO - LOG
# ================================================================

function Write-EventLog {

    param(

        [string]$Type,

        [string]$File,

        [string]$OldHash = "",

        [string]$NewHash = "",

        [string]$Details = ""
    )

    $Actor = Get-AuditActor -File $File

    if ($Actor) {
        $Details = if ($Details) { "$Details | Ator: $Actor" } else { "Ator: $Actor" }
    }

    $Object = [PSCustomObject]@{

        Date =
            (Get-Date).ToString("yyyy-MM-dd HH:mm:ss.fff")

        Type =
            $Type

        File =
            $File

        OldHash =
            $OldHash

        NewHash =
            $NewHash

        Details =
            $Details
    }

    if (-not (Test-Path $LogPath)) {

        $Object |
            Export-Csv `
                -Path $LogPath `
                -NoTypeInformation `
                -Encoding UTF8
    }

    else {

        $Object |
            Export-Csv `
                -Path $LogPath `
                -NoTypeInformation `
                -Append `
                -Encoding UTF8
    }

    $Text =
        "[$($Object.Date)] [$Type] $File"

    if ($Details) {
        $Text += " | $Details"
    }

    Add-Content `
        -Path $TextLogPath `
        -Value $Text `
        -Encoding UTF8

    switch ($Type) {

        "CREATED" {
            Write-Host $Text -ForegroundColor Green
        }

        "MODIFIED" {
            Write-Host $Text -ForegroundColor Yellow
        }

        "DELETED" {
            Write-Host $Text -ForegroundColor Red
        }

        "RENAMED" {
            Write-Host $Text -ForegroundColor Cyan
        }

        default {
            Write-Host $Text
        }
    }

    # Atualiza o relatório HTML imediatamente a cada evento
    Update-HTMLReport
}

# ================================================================
# ESTADO
# ================================================================

function Load-State {

    if (-not (Test-Path $DatabasePath)) {
        return @{}
    }

    try {

        $Json = Get-Content `
            -Path $DatabasePath `
            -Raw |
            ConvertFrom-Json

        $State = @{}

        foreach ($P in $Json.PSObject.Properties) {

            $State[$P.Name] = @{

                Hash =
                    $P.Value.Hash

                Size =
                    $P.Value.Size

                LastWrite =
                    $P.Value.LastWrite

            }
        }

        return $State

    }
    catch {

        return @{}
    }
}

function Save-State {

    param(
        $State
    )

    $State |
        ConvertTo-Json -Depth 10 |
        Set-Content `
            -Path $DatabasePath `
            -Encoding UTF8
}

# ================================================================
# SNAPSHOT
# ================================================================

function Get-Snapshot {

    $State = @{}

    Write-Host ""
    Write-Host "A analisar projeto:" `
        -ForegroundColor Cyan

    Write-Host $MonitorPath

    Get-ChildItem `
        -Path $MonitorPath `
        -File `
        -Recurse `
        -Force `
        -ErrorAction SilentlyContinue |
    ForEach-Object {

        $Hash = Get-SHA256 $_.FullName

        $State[$_.FullName] = @{

            Hash =
                $Hash

            Size =
                $_.Length

            LastWrite =
                $_.LastWriteTime.ToString("o")
        }
    }

    return $State
}

# ================================================================
# AUDITORIA WINDOWS
# ================================================================

Write-Host ""
Write-Host "A ativar auditoria de ficheiros..." `
    -ForegroundColor Cyan

# Usar GUID universal para funcionar em qualquer idioma do Windows (English, Português, etc.)
auditpol /set `
    /subcategory:"{0CCE921D-69AE-11D9-BED3-505054503030}" `
    /success:enable `
    /failure:enable |
    Out-Null

Write-Host "Auditoria ativa." `
    -ForegroundColor Green

# ================================================================
# SACL
# ================================================================

Write-Host ""
Write-Host "A configurar SACL..." `
    -ForegroundColor Cyan

try {

    $Acl = Get-Acl $MonitorPath

    $IdentityReference =
        New-Object System.Security.Principal.NTAccount("Everyone")

    $Rights =
        [Security.AccessControl.FileSystemRights]::WriteData `
        -bor
        [Security.AccessControl.FileSystemRights]::AppendData `
        -bor
        [Security.AccessControl.FileSystemRights]::Delete `
        -bor
        [Security.AccessControl.FileSystemRights]::DeleteSubdirectoriesAndFiles `
        -bor
        [Security.AccessControl.FileSystemRights]::WriteAttributes `
        -bor
        [Security.AccessControl.FileSystemRights]::WriteExtendedAttributes

    $Inheritance =
        [Security.AccessControl.InheritanceFlags]::ContainerInherit `
        -bor
        [Security.AccessControl.InheritanceFlags]::ObjectInherit

    $AuditRule =
        New-Object Security.AccessControl.FileSystemAuditRule(
            $IdentityReference,
            $Rights,
            $Inheritance,
            [Security.AccessControl.PropagationFlags]::None,
            [Security.AccessControl.AuditFlags]::Success
        )

    $Acl.AddAuditRule($AuditRule)

    Set-Acl `
        -Path $MonitorPath `
        -AclObject $Acl

    Write-Host "SACL configurada." `
        -ForegroundColor Green
}
catch {

    Write-Host "Não foi possível configurar a SACL." `
        -ForegroundColor Yellow
}

# ================================================================
# ESTADO INICIAL
# ================================================================

$State = Load-State

if ($State.Count -eq 0) {

    Write-Host ""
    Write-Host "A criar snapshot inicial..." `
        -ForegroundColor Cyan

    $State = Get-Snapshot

    Save-State $State

    Write-Host ""
    Write-Host "Snapshot criado." `
        -ForegroundColor Green
}

# ================================================================
# LIMPEZA DE SUBSCRITORES ANTERIORES
# ================================================================

function Unregister-ExistingWatchers {

    foreach ($Source in @("ProjectCreated", "ProjectChanged", "ProjectDeleted", "ProjectRenamed", "ReportTimer")) {

        Get-EventSubscriber -SourceIdentifier $Source -ErrorAction SilentlyContinue |
            Unregister-Event -Force -ErrorAction SilentlyContinue
    }
}

Unregister-ExistingWatchers

# ================================================================
# FILE SYSTEM WATCHER
# ================================================================

Write-Host ""
Write-Host "A iniciar FileSystemWatcher..." `
    -ForegroundColor Cyan

$Watcher =
    New-Object System.IO.FileSystemWatcher

$Watcher.Path =
    $MonitorPath

$Watcher.IncludeSubdirectories =
    $true

$Watcher.InternalBufferSize =
    65536

$Watcher.NotifyFilter =
    [IO.NotifyFilters]::FileName `
    -bor
    [IO.NotifyFilters]::DirectoryName `
    -bor
    [IO.NotifyFilters]::LastWrite `
    -bor
    [IO.NotifyFilters]::Size `
    -bor
    [IO.NotifyFilters]::CreationTime

$Watcher.EnableRaisingEvents =
    $true

# ================================================================
# CREATED
# ================================================================

Register-ObjectEvent `
    -InputObject $Watcher `
    -EventName Created `
    -SourceIdentifier ProjectCreated `
    -Action {

        $File =
            $Event.SourceEventArgs.FullPath

        Start-Sleep -Milliseconds 150

        if (Test-Path $File -PathType Leaf) {

            $Hash =
                Get-SHA256 $File

            $Backup =
                Save-Version $File

            try {
                $Info = Get-Item $File
                $State[$File] = @{
                    Hash      = $Hash
                    Size      = $Info.Length
                    LastWrite = $Info.LastWriteTime.ToString("o")
                }
                Save-State $State
            }
            catch {}

            Write-EventLog `
                -Type "CREATED" `
                -File $File `
                -NewHash $Hash `
                -Details "Novo ficheiro. Backup=$Backup"
        }
        elseif (Test-Path $File -PathType Container) {
            Write-EventLog `
                -Type "CREATED" `
                -File $File `
                -Details "Nova pasta criada."
        }
        else {
            Write-EventLog `
                -Type "CREATED" `
                -File $File `
                -Details "Novo ficheiro detetado (removido rapidamente)."
        }
    } |
    Out-Null

# ================================================================
# MODIFIED
# ================================================================

Register-ObjectEvent `
    -InputObject $Watcher `
    -EventName Changed `
    -SourceIdentifier ProjectChanged `
    -Action {

        $File =
            $Event.SourceEventArgs.FullPath

        Start-Sleep -Milliseconds 700

        if (-not (Test-Path $File -PathType Leaf)) {
            return
        }

        $NewHash =
            Get-SHA256 $File

        if (-not $NewHash) {
            return
        }

        $OldHash = ""

        if ($State.ContainsKey($File)) {

            $OldHash =
                $State[$File].Hash
        }

        if ($OldHash -eq $NewHash) {
            return
        }

        # Obter a versão anterior mais recente antes de guardar a nova versão
        $SafeName = Get-SafeName $File
        $Folder = Join-Path $VersionsPath $SafeName
        $PrevBackup = $null
        if (Test-Path $Folder) {
            $PrevBackup = Get-ChildItem -Path $Folder -File -ErrorAction SilentlyContinue |
                Where-Object { $_.Extension -ne ".diff" } |
                Sort-Object LastWriteTime -Descending |
                Select-Object -First 1
        }

        $Backup =
            Save-Version $File

        $Details =
            "Tamanho atual=$((Get-Item $File).Length) bytes"

        if ($Backup) {

            $Details +=
                " | Versão guardada=$Backup"
        }

        # Se for ficheiro de texto e houver versão anterior guardada, calcula as diferenças textuais
        if ($PrevBackup -and (Is-TextFile $File)) {
            $Diff = Compare-TextVersion -OldFile $PrevBackup.FullName -NewFile $File
            if ($Diff -and $Diff -ne "Sem diferença textual.") {
                $DiffFile = "$Backup.diff"
                $Diff | Set-Content -Path $DiffFile -Encoding UTF8 -ErrorAction SilentlyContinue
                $AddedLines = ($Diff -split "`r?`n" | Where-Object { $_ -like "+ *" }).Count
                $RemovedLines = ($Diff -split "`r?`n" | Where-Object { $_ -like "- *" }).Count
                $Details += " | Diff: +$AddedLines / -$RemovedLines linhas (Salvo em $DiffFile)"
            }
        }

        Write-EventLog `
            -Type "MODIFIED" `
            -File $File `
            -OldHash $OldHash `
            -NewHash $NewHash `
            -Details $Details

        try {

            $Info =
                Get-Item $File

            $State[$File] = @{

                Hash =
                    $NewHash

                Size =
                    $Info.Length

                LastWrite =
                    $Info.LastWriteTime.ToString("o")
            }

            Save-State $State
        }
        catch {}
    } |
    Out-Null

# ================================================================
# DELETED
# ================================================================

Register-ObjectEvent `
    -InputObject $Watcher `
    -EventName Deleted `
    -SourceIdentifier ProjectDeleted `
    -Action {

        $File =
            $Event.SourceEventArgs.FullPath

        $OldHash = ""

        $Size = ""

        if ($State.ContainsKey($File)) {

            $OldHash =
                $State[$File].Hash

            $Size =
                $State[$File].Size
        }

        $Details = if ($Size) { "Ficheiro apagado. Tamanho anterior=$Size bytes" } else { "Ficheiro ou pasta apagada." }

        Write-EventLog `
            -Type "DELETED" `
            -File $File `
            -OldHash $OldHash `
            -Details $Details

        if ($State.ContainsKey($File)) {

            $State.Remove($File)

            Save-State $State
        }

    } |
    Out-Null

# ================================================================
# RENAMED
# ================================================================

Register-ObjectEvent `
    -InputObject $Watcher `
    -EventName Renamed `
    -SourceIdentifier ProjectRenamed `
    -Action {

        $Old =
            $Event.SourceEventArgs.OldFullPath

        $New =
            $Event.SourceEventArgs.FullPath

        Write-EventLog `
            -Type "RENAMED" `
            -File $New `
            -Details "Nome anterior=$Old"

        if ($State.ContainsKey($Old)) {

            $OldState =
                $State[$Old]

            $State.Remove($Old)

            if (Test-Path $New -PathType Leaf) {

                $Hash =
                    Get-SHA256 $New

                $Info =
                    Get-Item $New

                $State[$New] = @{

                    Hash =
                        $Hash

                    Size =
                        $Info.Length

                    LastWrite =
                        $Info.LastWriteTime.ToString("o")
                }
            }

            Save-State $State
        }

    } |
    Out-Null

# ================================================================
# HTML
# ================================================================

function Update-HTMLReport {

    if (-not (Test-Path $LogPath)) {
        return
    }

    $Events =
        Import-Csv $LogPath |
        Sort-Object Date -Descending

    $Rows = ""

    foreach ($Event in $Events) {

        $Class = switch ($Event.Type) {

            "CREATED" {
                "created"
            }

            "MODIFIED" {
                "modified"
            }

            "DELETED" {
                "deleted"
            }

            "RENAMED" {
                "renamed"
            }

            default {
                ""
            }
        }

        # Usa [System.Net.WebUtility] compatível com PowerShell 5.1 e Core sem dependências adicionais
        $EncodedFile = [System.Net.WebUtility]::HtmlEncode($Event.File)
        $EncodedDetails = [System.Net.WebUtility]::HtmlEncode($Event.Details)

        $Rows += @"
<tr class="$Class">

<td>$($Event.Date)</td>

<td>
<b>$($Event.Type)</b>
</td>

<td>
$EncodedFile
</td>

<td class="hash">
$($Event.OldHash)
</td>

<td class="hash">
$($Event.NewHash)
</td>

<td>
$EncodedDetails
</td>

</tr>
"@
    }

    $HTML = @"
<!DOCTYPE html>

<html lang="pt">

<head>

<meta charset="UTF-8">

<title>Auditoria de projetos</title>

<style>

body {
    font-family: Arial, sans-serif;
    margin: 25px;
    background: #f2f2f2;
}

h1 {
    color: #222;
}

.info {
    background: white;
    padding: 15px;
    margin-bottom: 20px;
    border-radius: 8px;
}

table {
    width: 100%;
    border-collapse: collapse;
    background: white;
}

th {
    background: #222;
    color: white;
    padding: 10px;
    position: sticky;
    top: 0;
}

td {
    padding: 8px;
    border-bottom: 1px solid #ddd;
    vertical-align: top;
}

.created {
    background: #ddffdd;
}

.modified {
    background: #fff2b8;
}

.deleted {
    background: #ffd5d5;
}

.renamed {
    background: #d7eaff;
}

.hash {
    font-family: monospace;
    font-size: 10px;
    word-break: break-all;
}

</style>

</head>

<body>

<h1>Auditoria de projetos</h1>

<div class="info">

<b>Computador:</b>
$env:COMPUTERNAME

<br>

<b>Utilizador:</b>
$env:USERNAME

<br>

<b>Projetos:</b>
$MonitorPath

<br>

<b>Gerado:</b>
$(Get-Date)

<br>

<b>Extensões monitorizadas:</b>
$($TextExtensions.Count)

<br>

<b>Ficheiros especiais:</b>
$($ImportantFilesWithoutExtension.Count)

</div>

<table>

<tr>

<th>Data</th>

<th>Tipo</th>

<th>Ficheiro</th>

<th>Hash anterior</th>

<th>Hash novo</th>

<th>Detalhes</th>

</tr>

$Rows

</table>

</body>

</html>
"@

    $HTML |
        Set-Content `
            -Path $HtmlPath `
            -Encoding UTF8
}

# ================================================================
# ATUALIZAR RELATÓRIO PERIODICAMENTE
# ================================================================

$Timer =
    New-Object System.Timers.Timer

$Timer.Interval =
    60000

$Timer.AutoReset =
    $true

Register-ObjectEvent `
    -InputObject $Timer `
    -EventName Elapsed `
    -SourceIdentifier ReportTimer `
    -Action {

        Update-HTMLReport

    } |
    Out-Null

$Timer.Start()

Update-HTMLReport

# ================================================================
# RESUMO
# ================================================================

Write-Host ""
Write-Host "====================================================" `
    -ForegroundColor Green

Write-Host "       MONITORIZAÇÃO DE PROJETOS ATIVA" `
    -ForegroundColor Green

Write-Host "====================================================" `
    -ForegroundColor Green

Write-Host ""

Write-Host "Projetos:"
Write-Host $MonitorPath

Write-Host ""

Write-Host "Extensões de texto monitorizadas:"
Write-Host $TextExtensions.Count

Write-Host ""

Write-Host "Incluído:"
Write-Host "  C# / .NET"
Write-Host "  Visual Studio"
Write-Host "  Python"
Write-Host "  Node.js"
Write-Host "  JavaScript"
Write-Host "  TypeScript"
Write-Host "  React"
Write-Host "  Angular"
Write-Host "  Vue"
Write-Host "  Svelte"
Write-Host "  HTML/CSS"
Write-Host "  Chrome Extensions"
Write-Host "  VS Code"
Write-Host "  Docker"
Write-Host "  Git"
Write-Host "  CI/CD"
Write-Host "  SQL"
Write-Host "  Testes"
Write-Host ""

Write-Host "Log:"
Write-Host $TextLogPath

Write-Host ""

Write-Host "CSV:"
Write-Host $LogPath

Write-Host ""

Write-Host "Relatório HTML:"
Write-Host $HtmlPath

Write-Host ""

Write-Host "Versões:"
Write-Host $VersionsPath

Write-Host ""
Write-Host "CTRL+C para terminar."
Write-Host ""

# ================================================================
# LOOP COM LIMPEZA AUTOMÁTICA EM FINALLY
# ================================================================

try {
    while ($true) {

        Wait-Event -Timeout 5 |
            Out-Null
    }
}
finally {

    Write-Host ""
    Write-Host "A parar monitorização e a libertar recursos..." -ForegroundColor Yellow

    if ($Watcher) {
        $Watcher.EnableRaisingEvents = $false
        $Watcher.Dispose()
    }

    if ($Timer) {
        $Timer.Stop()
        $Timer.Dispose()
    }

    Unregister-ExistingWatchers

    Write-Host "Recursos libertados com sucesso." -ForegroundColor Green
}
