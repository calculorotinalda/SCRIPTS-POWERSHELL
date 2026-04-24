function Show-Menu {
    Clear-Host
    Write-Host "===== GERENCIADOR DE STARTUP =====" -ForegroundColor Cyan
    Write-Host "1. Listar todos os itens"
    Write-Host "2. Buscar por nome"
    Write-Host "3. Remover por nome"
    Write-Host "4. Sair"
    Write-Host "=================================="
}

function Get-StartupItems {
    Get-CimInstance Win32_StartupCommand | 
    Select-Object Name, Command, Location
}

function Convert-RegistryPath($path) {
    if ($path -like "HKLM*") {
        return $path -replace "^HKLM", "Registry::HKEY_LOCAL_MACHINE"
    }
    elseif ($path -like "HKCU*") {
        return $path -replace "^HKCU", "Registry::HKEY_CURRENT_USER"
    }
    else {
        return $null
    }
}
function Remove-StartupItem($item) {

    # 🔹 REGISTO (Run / RunOnce)
    if ($item.Location -match "Run") {

        $regPath = Convert-RegistryPath $item.Location

        if ($regPath -and (Test-Path $regPath)) {

            # Verificar se o caminho requer privilégios administrativos
            $requiresAdmin = $regPath -like "*HKEY_LOCAL_MACHINE*"
            
            if ($requiresAdmin -and -not (Is-Administrator)) {
                Write-Host "⚠️  Item protegido em HKLM: $($item.Name)" -ForegroundColor Yellow
                Write-Host "Este item requer privilégios administrativos para ser removido." -ForegroundColor Yellow
                $continue = Read-Host "Deseja tentar executar com privilégios elevados? (s/n)"
                if ($continue -eq "s") {
                    # Reexecutar o script com privilégios administrativos
                    Restart-AsAdmin
                    return $false
                }
                return $false
            }

            # Obter todas as propriedades do caminho do registro
            $props = Get-ItemProperty -Path $regPath -ErrorAction SilentlyContinue
            
            # Verificar se alguma propriedade corresponde ao nome do item
            $matchingProp = $props.PSObject.Properties | Where-Object { 
                $_.Name -eq $item.Name -or 
                $_.Name -eq $item.Name.Trim() -or
                $_.Name -like "*$($item.Name)*"
            } | Select-Object -First 1

            if ($matchingProp) {
                try {
                    # Tentar remover com diferentes opções de erro
                    Remove-ItemProperty -Path $regPath -Name $matchingProp.Name -ErrorAction Stop -Force
                    Write-Host "✓ Removido do registro: $($item.Name)" -ForegroundColor Green
                    return $true
                }
                catch {
                    Write-Host "✗ Erro ao remover do registro: $($item.Name)" -ForegroundColor Red
                    Write-Host "  Detalhes: $_" -ForegroundColor Red
                    
                    # Se for erro de permissão, sugerir executar como admin
                    if ($_.Exception.Message -like "*acesso*" -or $_.Exception.Message -like "*permissão*") {
                        Write-Host "  ➜ Este item requer privilégios administrativos." -ForegroundColor Yellow
                        Write-Host "  ➜ Execute o PowerShell como Administrador e tente novamente." -ForegroundColor Yellow
                    }
                    return $false
                }
            } else {
                Write-Host "⚠️  Item não encontrado no registro: $($item.Name)" -ForegroundColor Yellow
                Write-Host "  Propriedades disponíveis em ${regPath}:" -ForegroundColor Cyan
                $props.PSObject.Properties.Name | Where-Object { $_ -notlike "*PS*" } | ForEach-Object { Write-Host "    - $_" }
                return $false
            }
        }
        
        Write-Host "⚠️  Caminho de registro não encontrado: ${regPath}" -ForegroundColor Yellow
        return $false
    }

    # 🔹 STARTUP (.lnk)
    if ($item.Location -eq "Startup") {

        $paths = @(
            "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup",
            "$env:ProgramData\Microsoft\Windows\Start Menu\Programs\Startup"
        )

        $found = $false
        foreach ($p in $paths) {
            $fileName = Split-Path $item.Command -Leaf
            $fullPath = Join-Path $p $fileName

            if (Test-Path $fullPath) {
                try {
                    Remove-Item $fullPath -Force -ErrorAction Stop
                    Write-Host "✓ Atalho removido: $fullPath" -ForegroundColor Green
                    $found = $true
                }
                catch {
                    Write-Host "✗ Erro ao remover atalho: $fullPath" -ForegroundColor Red
                    Write-Host "  Detalhes: $_" -ForegroundColor Red
                }
            }
        }
        
        if (-not $found) {
            Write-Host "⚠️  Atalho não encontrado para: $($item.Name)" -ForegroundColor Yellow
        }
        return $found
    }

    # 🔥 SERVIÇOS (não remover)
    try {
        $service = Get-Service -Name $item.Name -ErrorAction SilentlyContinue
        if ($service) {
            Write-Host "⚠️  $($item.Name) é um serviço do sistema" -ForegroundColor Yellow
            Write-Host "  Serviços devem ser gerenciados com 'services.msc' ou 'sc.exe'" -ForegroundColor Cyan
            return $false
        }
    }
    catch {
        # Ignora erros na verificação de serviço
    }

    # ❌ OUTROS
    Write-Host "❓ Item não identificado: $($item.Name)" -ForegroundColor Yellow
    Write-Host "  Localização: $($item.Location)" -ForegroundColor Cyan
    Write-Host "  Comando: $($item.Command)" -ForegroundColor Cyan
    return $false
}

# Função auxiliar para verificar se é administrador
function Is-Administrator {
    $identity = [System.Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object System.Security.Principal.WindowsPrincipal($identity)
    return $principal.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Função para reiniciar o script como administrador
function Restart-AsAdmin {
    $scriptPath = $MyInvocation.ScriptName
    if (-not $scriptPath) {
        Write-Host "Não foi possível reiniciar automaticamente. Execute manualmente como Administrador." -ForegroundColor Yellow
        return
    }
    
    $arguments = "-NoExit -File `"$scriptPath`""
    try {
        Start-Process powershell -Verb RunAs -ArgumentList $arguments
        Write-Host "Reiniciando como Administrador..." -ForegroundColor Green
        exit
    }
    catch {
        Write-Host "Erro ao reiniciar como Administrador: $_" -ForegroundColor Red
    }
}

do {
    Show-Menu
    $opcao = Read-Host "Escolha uma opção"

    switch ($opcao) {

        "1" {
            Clear-Host
            Get-StartupItems | Format-Table -AutoSize
            Pause
        }

        "2" {
            $nome = Read-Host "Digite parte do nome"
            $result = Get-StartupItems | Where-Object { $_.Name -like "*$nome*" }

            if ($result) {
                $result | Format-Table -AutoSize
            } else {
                Write-Host "Nenhum item encontrado." -ForegroundColor Yellow
            }
            Pause
        }

        "3" {
            $nome = Read-Host "Digite parte do nome para remover"
            $items = Get-StartupItems | Where-Object { $_.Name -like "*$nome*" }

            if (-not $items) {
                Write-Host "Nenhum item encontrado." -ForegroundColor Yellow
                Pause
                continue
            }

            $i = 1
            foreach ($item in $items) {
                Write-Host "$i. $($item.Name)"
                $i++
            }

            $index = Read-Host "Escolha o número para remover (ou 0 para cancelar)"

            if ($index -eq 0) { continue }

            $selected = $items[$index - 1]

            if ($selected) {
                $confirm = Read-Host "Confirma remoção de '$($selected.Name)'? (s/n)"
                if ($confirm -eq "s") {
                    Remove-StartupItem $selected
                } else {
                    Write-Host "Cancelado."
                }
            }

            Pause
        }

        "4" {
            Write-Host "Saindo..."
        }

        default {
            Write-Host "Opção inválida." -ForegroundColor Red
            Pause
        }
    }

} while ($opcao -ne "4")