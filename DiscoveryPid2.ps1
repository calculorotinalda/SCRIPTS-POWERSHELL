```text
Clear-Host

Write-Host "=============================================" -ForegroundColor Cyan
Write-Host " LIGACOES TCP ESTABLISHED" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host ""

$connections = Get-NetTCPConnection -State Established -ErrorAction SilentlyContinue

if ($connections) {
    foreach ($conn in ($connections | Sort-Object OwningProcess)) {

        $nome = "Desconhecido"

        try {
            $p = Get-Process -Id $conn.OwningProcess -ErrorAction Stop
            $nome = $p.ProcessName
        }
        catch {}

        Write-Host ("PID: {0} | Processo: {1} | {2}:{3} -> {4}:{5} | {6}" -f `
            $conn.OwningProcess,
            $nome,
            $conn.LocalAddress,
            $conn.LocalPort,
            $conn.RemoteAddress,
            $conn.RemotePort,
            $conn.State)
    }
}
else {
    Write-Host "Nenhuma ligacao ESTABLISHED encontrada." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host " ESCOLHER PID" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host ""

do {
    $entrada = Read-Host "Introduza o PID"

    if ($entrada -match "^\d+$") {
        $pidNumero = [int]$entrada
        break
    }

    Write-Host "PID invalido. Introduza apenas numeros." -ForegroundColor Red

} while ($true)

Write-Host ""
Write-Host "=============================================" -ForegroundColor Green
Write-Host " INFORMACAO DO PID $pidNumero" -ForegroundColor Green
Write-Host "=============================================" -ForegroundColor Green
Write-Host ""

$proc = Get-CimInstance Win32_Process -Filter "ProcessId=$pidNumero" -ErrorAction SilentlyContinue

if (-not $proc) {
    Write-Host "O PID $pidNumero nao esta em execucao." -ForegroundColor Red
    Read-Host "Prima ENTER para sair"
    exit
}

Write-Host "PID              : $($proc.ProcessId)"
Write-Host "Nome             : $($proc.Name)"

if ($proc.ExecutablePath) {
    Write-Host "Executavel       : $($proc.ExecutablePath)"
}
else {
    Write-Host "Executavel       : [nao disponivel]"
}

if ($proc.CommandLine) {
    Write-Host "CommandLine      : $($proc.CommandLine)"
}
else {
    Write-Host "CommandLine      : [nao disponivel]"
}

Write-Host "PID Pai          : $($proc.ParentProcessId)"

$parent = Get-CimInstance Win32_Process -Filter "ProcessId=$($proc.ParentProcessId)" -ErrorAction SilentlyContinue

if ($parent) {
    Write-Host "Processo Pai     : $($parent.Name)"

    if ($parent.ExecutablePath) {
        Write-Host "Caminho Pai      : $($parent.ExecutablePath)"
    }
}

Write-Host ""
Write-Host "=============================================" -ForegroundColor Yellow
Write-Host " SERVICO ASSOCIADO" -ForegroundColor Yellow
Write-Host "=============================================" -ForegroundColor Yellow
Write-Host ""

$servicos = Get-CimInstance Win32_Service -ErrorAction SilentlyContinue |
    Where-Object { $_.ProcessId -eq $pidNumero }

if ($servicos) {

    foreach ($servico in $servicos) {

        Write-Host "Nome do servico  : $($servico.Name)"
        Write-Host "DisplayName      : $($servico.DisplayName)"
        Write-Host "Estado           : $($servico.State)"
        Write-Host "Arranque         : $($servico.StartMode)"
        Write-Host "Conta            : $($servico.StartName)"
        Write-Host "Caminho          : $($servico.PathName)"
        Write-Host ""
    }
}
else {
    Write-Host "Nenhum servico associado diretamente a este PID."
}

Write-Host "=============================================" -ForegroundColor Magenta
Write-Host " UTILIZADOR" -ForegroundColor Magenta
Write-Host "=============================================" -ForegroundColor Magenta
Write-Host ""

try {
    $p2 = Get-Process -Id $pidNumero -IncludeUserName -ErrorAction Stop
    Write-Host "Utilizador       : $($p2.UserName)"
}
catch {
    Write-Host "Utilizador       : [sem permissao]" -ForegroundColor Yellow
    Write-Host "Execute o PowerShell como Administrador." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host " LIGACOES DO PID $pidNumero" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host ""

$pidConnections = Get-NetTCPConnection -OwningProcess $pidNumero -ErrorAction SilentlyContinue

if ($pidConnections) {

    $pidConnections |
        Select-Object State,LocalAddress,LocalPort,RemoteAddress,RemotePort,OwningProcess |
        Format-Table -AutoSize
}
else {
    Write-Host "Nenhuma ligacao TCP encontrada."
}

Write-Host ""
Write-Host "=============================================" -ForegroundColor Green
Write-Host " ANALISE TERMINADA" -ForegroundColor Green
Write-Host "=============================================" -ForegroundColor Green
Write-Host ""

Read-Host "Prima ENTER para sair"
```
