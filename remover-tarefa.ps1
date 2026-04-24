Clear-Host

Write-Host "===================================" -ForegroundColor Cyan
Write-Host " TAREFAS AGENDADAS NO SISTEMA"
Write-Host "===================================" -ForegroundColor Cyan
Write-Host ""

$tasks = Get-ScheduledTask | Sort-Object TaskName

if ($tasks.Count -eq 0) {
    Write-Host "Nenhuma tarefa encontrada."
    exit
}

Write-Host "Total de tarefas: $($tasks.Count)"
Write-Host ""

for ($i = 0; $i -lt $tasks.Count; $i++) {
    Write-Host "$($i+1) - $($tasks[$i].TaskName)" -ForegroundColor Green
}

do {
    Write-Host ""
    $selection = Read-Host "Digite um número entre 1 e $($tasks.Count)"

    $valido = $selection -match '^\d+$' -and
              [int]$selection -ge 1 -and
              [int]$selection -le $tasks.Count

    if (-not $valido) {
        Write-Host "Número inválido. Tente novamente." -ForegroundColor Red
    }

} until ($valido)

$selectedTask = $tasks[[int]$selection - 1]

Write-Host ""
Write-Host "Selecionado: $($selectedTask.TaskName)" -ForegroundColor Yellow

$confirm = Read-Host "Tem certeza que deseja apagar? (S/N)"

if ($confirm -match '^[sS]$') {
    Unregister-ScheduledTask `
        -TaskName $selectedTask.TaskName `
        -TaskPath $selectedTask.TaskPath `
        -Confirm:$false

    Write-Host "Tarefa removida com sucesso." -ForegroundColor Red
}
else {
    Write-Host "Operação cancelada." -ForegroundColor Cyan
}

Write-Host ""
Write-Host "Processo finalizado."