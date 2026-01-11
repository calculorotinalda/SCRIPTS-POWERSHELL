function Get-DllRundll32Commands {
    param (
        [string]$DumpBinPath = "C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Tools\MSVC\14.43.34808\bin\Hostx64\x86\dumpbin.exe",
        # Comentário: Define o caminho para o dumpbin.exe.

        [switch]$NoPagination
        # Comentário: Se usado, a saída não será paginada com "| more".
    )

    # Verifica se o dumpbin.exe existe no caminho especificado.
    if (-not (Test-Path $DumpBinPath)) {
        Write-Host "Erro: dumpbin.exe não encontrado em $DumpBinPath." -ForegroundColor Red
        return
    }
    # Comentário: Verifica se o dumpbin.exe está disponível no caminho especificado.

    # Solicita ao usuário o nome da DLL.
    $dllName = Read-Host "Digite o nome da DLL (ex.: shell32.dll)"
    if ([string]::IsNullOrWhiteSpace($dllName)) {
        Write-Host "Erro: O nome da DLL não pode estar vazio." -ForegroundColor Red
        return
    }
    # Comentário: Lê o nome da DLL fornecido pelo usuário e verifica se ele não está vazio.

    # Define o caminho completo para a DLL especificada.
    $dllPath = "$env:SystemRoot\System32\$dllName"
    if (-not (Test-Path $dllPath)) {
        Write-Host "Erro: A DLL '${dllName}' não foi encontrada em $dllPath." -ForegroundColor Red
        return
    }
    # Comentário: Verifica se a DLL especificada existe no diretório System32.

    Write-Host "Listando funções exportadas de ${dllName}..." -ForegroundColor Yellow
    # Comentário: Exibe uma mensagem inicial informando que as funções estão sendo listadas.

    try {
        # Usa dumpbin.exe para listar as funções exportadas da DLL especificada.
        $functions = & $DumpBinPath /exports $dllPath 2>&1 | 
                    Select-String -Pattern "^\s+\d+\s+\w+\s+[\w@?#$%&*]+" | 
                    ForEach-Object { ($_ -split "\s+")[-1] }
        # Comentário: O comando acima executa o dumpbin.exe e extrai apenas os nomes das funções exportadas.
    } catch {
        Write-Host "Erro ao processar '${dllName}': $_" -ForegroundColor Red
        return
    }

    if ($functions.Count -gt 0) {
        "DLL: ${dllName}"
        # Comentário: Exibe o nome da DLL.

        foreach ($func in $functions) {
            "  rundll32.exe ${dllName},$func"
            # Comentário: Gera um comando rundll32.exe válido para cada função exportada.
        }
    } else {
        Write-Host "Nenhuma função exportada encontrada em '${dllName}'." -ForegroundColor Yellow
    }

    # Exibe a saída com ou sem paginação.
    if ($NoPagination) {
        $output
        # Comentário: Se o parâmetro -NoPagination for usado, exibe a saída completa sem dividir em páginas.
    } else {
        $output | more
        # Comentário: Divide a saída em páginas usando "| more", permitindo que o usuário avance página por página.
    }
}
Get-DllRundll32Commands