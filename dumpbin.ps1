function Get-Rundll32Commands {
    param (
        [string]$Directory = "$env:SystemRoot\System32", # Diretório padrão onde as DLLs estão localizadas.
        # Comentário: Define o diretório onde as DLLs serão buscadas. Padrão: %SystemRoot%\System32.

        [switch]$NoPagination # Opção para desativar a paginação da saída.
        # Comentário: Se usado, a saída não será paginada com "| more".
    )

    # Verifica se o dumpbin.exe está disponível no sistema.
    $dumpbinPath = "C:\Program Files (x86)\Microsoft Visual Studio\2019\Community\VC\Tools\MSVC\14.29.30133\bin\Hostx64\x64\dumpbin.exe"
    if (-not (Test-Path $dumpbinPath)) {
        Write-Host "Erro: dumpbin.exe não encontrado. Verifique o caminho." -ForegroundColor Red
        return
    }
    # Comentário: O script verifica se o dumpbin.exe existe no caminho especificado.

    # Obtém todas as DLLs no diretório especificado.
    $dlls = Get-ChildItem -Path $Directory -Filter *.dll
    # Comentário: Lista todos os arquivos com extensão ".dll" no diretório fornecido.

    Write-Host "Listando DLLs e funções exportadas..." -ForegroundColor Yellow
    # Comentário: Exibe uma mensagem inicial para informar o usuário sobre a operação em andamento.

    # Itera sobre cada DLL e extrai funções exportadas.
    $output = foreach ($dll in $dlls) {
        $dllPath = $dll.FullName
        # Comentário: Obtém o caminho completo da DLL atual.

        # Usa o dumpbin.exe para listar funções exportadas.
        $functions = & $dumpbinPath /exports $dllPath 2>&1 | Where-Object { $_ -match "^\s+\d+\s+\w+\s+(\S+)" } | ForEach-Object { $matches[1] }
        # Comentário: O comando acima executa o dumpbin.exe para extrair nomes de funções exportadas da DLL.

        if ($functions.Count -gt 0) {
            "DLL: $($dll.Name)"
            # Comentário: Exibe o nome da DLL atual.

            foreach ($func in $functions) {
                "  rundll32.exe $($dll.Name),$func"
                # Comentário: Gera um comando rundll32.exe válido para cada função exportada.
            }
        }
    }
    # Comentário: O loop "foreach" processa todas as DLLs e gera comandos rundll32.exe para funções exportadas.

    # Exibe a saída com ou sem paginação.
    if ($NoPagination) {
        $output
        # Comentário: Se o parâmetro -NoPagination for usado, exibe a saída completa sem dividir em páginas.
    } else {
        $output | more
        # Comentário: Divide a saída em páginas usando "| more", permitindo que o usuário avance página por página.
    }
}
Get-Rundll32Commands