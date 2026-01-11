[string]$DumpBinPath = "C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Tools\MSVC\14.43.34808\bin\Hostx64\x86\dumpbin.exe"

function Get-Shell32Rundll32Commands {
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

    # Define o caminho completo para a shell32.dll.
    $shell32Path = "$env:SystemRoot\System32\shell32.dll"
    if (-not (Test-Path $shell32Path)) {
        Write-Host "Erro: shell32.dll não encontrada." -ForegroundColor Red
        return
    }
    # Comentário: Verifica se a shell32.dll existe no diretório System32.

    Write-Host "Listando funções exportadas da shell32.dll..." -ForegroundColor Yellow
    # Comentário: Exibe uma mensagem inicial informando que as funções estão sendo listadas.

    try {
        # Usa dumpbin.exe para listar as funções exportadas da shell32.dll.
        $functions = & $DumpBinPath /exports $shell32Path 2>&1 | 
                    Select-String -Pattern "^\s+\d+\s+\w+\s+[\w@?#$%&*]+" | 
                    ForEach-Object { ($_ -split "\s+")[-1] }
        # Comentário: O comando acima executa o dumpbin.exe e extrai apenas os nomes das funções exportadas.
        # Explicação do regex:
        # - "^\s+\d+\s+\w+\s+[\w@?#$%&*]+": Captura linhas contendo números, seguidos por um nome de função.
        # - ($_ -split "\s+")[-1]: Extrai o último elemento da linha (o nome da função).
    } catch {
        Write-Host "Erro ao processar shell32.dll: $_" -ForegroundColor Red
        return
    }

    if ($functions.Count -gt 0) {
        "DLL: shell32.dll"
        # Comentário: Exibe o nome da DLL.

        foreach ($func in $functions) {
            "  rundll32.exe shell32.dll,$func"
            # Comentário: Gera um comando rundll32.exe válido para cada função exportada.
        }
    } else {
        Write-Host "Nenhuma função exportada encontrada na shell32.dll." -ForegroundColor Yellow
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
Get-Shell32Rundll32Commands