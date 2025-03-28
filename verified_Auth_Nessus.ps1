# Script Simplificado de Verificação de Configurações de Sistema

# Função para exibir resultados com cores
function Write-Result {
    param (
        [string]$Message,
        [string]$Status
    )
    $color = if ($Status -eq 'OK') { 'Green' } else { 'Red' }
    Write-Host "${Message}: $Status" -ForegroundColor $color
}

# 1. Verifica se o serviço WMI está em execução
function Verificar-WMIService {
    $service = Get-Service -Name winmgmt -ErrorAction SilentlyContinue
    if ($service -and $service.Status -eq 'Running') {
        Write-Result "Serviço WMI (Winmgmt)" "OK"
        return $true
    }
    else {
        Write-Result "Serviço WMI (Winmgmt)" "NÃO OK"
        return $false
    }
}

# 2. Testa uma consulta WMI
function Testar-ConsultaWMI {
    try {
        Get-WmiObject -Class Win32_OperatingSystem -ErrorAction Stop | Out-Null
        Write-Result "Consulta WMI (Win32_OperatingSystem)" "OK"
        return $true
    }
    catch {
        Write-Result "Consulta WMI (Win32_OperatingSystem)" "NÃO OK"
        return $false
    }
}

# 3. Verifica se o serviço de Registro Remoto está configurado como Automático
function Verificar-RegistroRemoto {
    $service = Get-Service -Name RemoteRegistry -ErrorAction SilentlyContinue
    if ($service -and $service.StartType -eq 'Automatic') {
        Write-Result "Serviço de Registro Remoto (RemoteRegistry)" "OK"
        return $true
    }
    else {
        Write-Result "Serviço de Registro Remoto (RemoteRegistry)" "NÃO OK"
        return $false
    }
}

# 4. Verifica e testa os compartilhamentos ADMIN$ e C$
function Verificar-Compartilhamentos {
    param (
        [string[]]$Compartilhamentos = @("ADMIN$", "C$")
    )
    foreach ($share in $Compartilhamentos) {
        try {
            # Testa o caminho UNC para cada compartilhamento
            $path = \\localhost\$share
            $shareExist = Test-Path $path
            if ($shareExist) {
                Write-Result "Compartilhamento $share" "OK"
            }
            else {
                Write-Result "Compartilhamento $share" "NÃO OK"
            }
        }
        catch {
            Write-Result "Compartilhamento $share" "NÃO OK"
        }
    }
}

# 5. Verifica se File & Printer Sharing estão habilitados
function Verificar-FileAndPrinterSharing {
    try {
        # Obter regras de firewall para File and Printer Sharing
        $fpSharingRules = Get-NetFirewallRule -DisplayGroup "File and Printer Sharing" -ErrorAction SilentlyContinue
        if ($fpSharingRules) {
            # Verificar se pelo menos uma regra está habilitada e com ação Allow
            $enabledRules = $fpSharingRules | Where-Object { $_.Enabled -eq 'True' -and $_.Action -eq 'Allow' }
            if ($enabledRules.Count -ge 1) {
                Write-Result "File & Printer Sharing Habilitado" "OK"
                return $true
            }
            else {
                Write-Result "File & Printer Sharing Habilitado" "NÃO OK"
                return $false
            }
        }
        else {
            Write-Result "File & Printer Sharing Habilitado" "NÃO OK"
            return $false
        }
    }
    catch {
        Write-Result "File & Printer Sharing Habilitado" "NÃO OK"
        return $false
    }
}

# 6. Verifica se as portas 139 e 445 estão abertas
function Verificar-PortasAbertas {
    param (
        [int[]]$Portas = @(139, 445)
    )
    foreach ($porta in $Portas) {
        try {
            # Checar se há alguma regra de firewall que permite o tráfego de entrada na porta
            $rules = Get-NetFirewallRule -Direction Inbound -Action Allow -Enabled True -ErrorAction SilentlyContinue |
                     Get-NetFirewallPortFilter |
                     Where-Object { $_.LocalPort -eq $porta }
            if ($rules) {
                Write-Result "Porta $porta Aberta" "OK"
            }
            else {
                Write-Result "Porta $porta Aberta" "NÃO OK"
            }
        }
        catch {
            Write-Result "Porta $porta Aberta" "NÃO OK"
        }
    }
}

# Execução das verificações
Write-Host "Iniciando verificações de sistema..." -ForegroundColor Cyan

# Variáveis para armazenar resultados
$wmiStatus         = Verificar-WMIService
$wmiQuery          = Testar-ConsultaWMI
$registroRemoto    = Verificar-RegistroRemoto
$compartilhamentos = Verificar-Compartilhamentos
$filePrinterShare  = Verificar-FileAndPrinterSharing
$portasAbertas     = Verificar-PortasAbertas

Write-Host "Verificações concluídas." -ForegroundColor Cyan
