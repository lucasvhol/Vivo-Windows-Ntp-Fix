#Requires -Version 5.1

[CmdletBinding()]
param(
    [switch]$AllowDomainMember,
    [switch]$NoPause,
    [switch]$Yes
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$language = if ((Get-UICulture).Name -like 'pt-*') { 'pt' } else { 'en' }
$strings = @{
    pt = @{
        title = 'Correcao de sincronizacao de horario para a rede Vivo'
        description = 'Configura o Windows para usar os servidores publicos do NTP.br.'
        confirm = 'Pressione ENTER para aplicar a correcao ou CTRL+C para cancelar'
        registry = '[1/4] Adicionando os servidores NTP.br ao Windows'
        service = '[2/4] Preparando o servico de Horario do Windows'
        configure = '[3/4] Configurando os servidores usados na sincronizacao'
        synchronize = '[4/4] Sincronizando o relogio'
        complete = 'Correcao aplicada com sucesso.'
        source = 'Fonte de horario atual'
        status = 'Status da sincronizacao'
        error = 'Nao foi possivel aplicar a correcao'
        exit = 'Pressione ENTER para sair'
        admin_error = 'Nao foi possivel solicitar privilegios de administrador.'
        script_path_error = 'Salve o script em um arquivo antes de executa-lo.'
        domain_error = 'Este computador pertence a um dominio. A sincronizacao deve seguir a configuracao da organizacao. Use -AllowDomainMember apenas se voce administra este dominio.'
        policy_error = 'A sincronizacao de horario e controlada por uma Politica de Grupo. Entre em contato com o administrador do computador.'
        command_error = 'O comando w32tm falhou com o codigo de saida'
        source_error = 'O Windows nao confirmou um servidor NTP.br como fonte de horario.'
        retry = 'A primeira tentativa nao respondeu. Tentando novamente'
    }
    en = @{
        title = 'Clock synchronization fix for Vivo networks'
        description = 'Configures Windows to use the public NTP.br time servers.'
        confirm = 'Press ENTER to apply the fix or CTRL+C to cancel'
        registry = '[1/4] Adding NTP.br servers to Windows'
        service = '[2/4] Preparing the Windows Time service'
        configure = '[3/4] Configuring the servers used for synchronization'
        synchronize = '[4/4] Synchronizing the clock'
        complete = 'The fix was applied successfully.'
        source = 'Current time source'
        status = 'Synchronization status'
        error = 'The fix could not be applied'
        exit = 'Press ENTER to exit'
        admin_error = 'Administrator privileges could not be requested.'
        script_path_error = 'Save the script to a file before running it.'
        domain_error = 'This computer is joined to a domain. Time synchronization should follow your organization configuration. Use -AllowDomainMember only if you administer this domain.'
        policy_error = 'Time synchronization is controlled by Group Policy. Contact the computer administrator.'
        command_error = 'The w32tm command failed with exit code'
        source_error = 'Windows did not confirm an NTP.br server as its time source.'
        retry = 'The first attempt did not respond. Trying again'
    }
}[$language]

function Test-IsAdministrator {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = [Security.Principal.WindowsPrincipal]::new($identity)
    return $principal.IsInRole(
        [Security.Principal.WindowsBuiltInRole]::Administrator
    )
}

function Start-ElevatedScript {
    if ([string]::IsNullOrWhiteSpace($PSCommandPath)) {
        throw $strings.script_path_error
    }

    $argumentList = @(
        '-NoProfile'
        '-ExecutionPolicy'
        'Bypass'
        '-File'
        "`"$PSCommandPath`""
    )
    if ($AllowDomainMember) {
        $argumentList += '-AllowDomainMember'
    }
    if ($NoPause) {
        $argumentList += '-NoPause'
    }
    if ($Yes) {
        $argumentList += '-Yes'
    }

    $powerShellPath = (Get-Process -Id $PID).Path
    return Start-Process `
        -FilePath $powerShellPath `
        -ArgumentList $argumentList `
        -Verb RunAs `
        -Wait `
        -PassThru
}

function Write-Step {
    param(
        [Parameter(Mandatory)]
        [string]$Text
    )

    Write-Host ''
    Write-Host $Text -ForegroundColor Cyan
}

function Invoke-W32Time {
    param(
        [Parameter(Mandatory)]
        [string[]]$Arguments,

        [switch]$AllowFailure
    )

    $output = & $script:w32TimePath @Arguments 2>&1
    $exitCode = $LASTEXITCODE
    $outputLines = @($output | ForEach-Object { $_.ToString() })
    $result = [pscustomobject]@{
        ExitCode = $exitCode
        Output = $outputLines
    }

    if (-not $AllowFailure -and $exitCode -ne 0) {
        $details = $outputLines -join [Environment]::NewLine
        throw "$($strings.command_error) $exitCode.`n$details"
    }

    return $result
}

if (-not (Test-IsAdministrator)) {
    try {
        $elevatedProcess = Start-ElevatedScript
        exit $elevatedProcess.ExitCode
    }
    catch {
        Write-Host "$($strings.admin_error) $($_.Exception.Message)" `
            -ForegroundColor Red
        exit 1
    }
}

$exitCode = 0

try {
    Write-Host ''
    Write-Host $strings.title -ForegroundColor Yellow
    Write-Host $strings.description

    if (-not $Yes) {
        Read-Host -Prompt $strings.confirm | Out-Null
    }

    $policyPath = 'HKLM:\SOFTWARE\Policies\Microsoft\W32Time\Parameters'
    if (Test-Path -Path $policyPath) {
        $policy = Get-ItemProperty -Path $policyPath
        $ntpServerPolicy = $policy.PSObject.Properties['NtpServer']
        $typePolicy = $policy.PSObject.Properties['Type']
        if ($null -ne $ntpServerPolicy -or $null -ne $typePolicy) {
            throw $strings.policy_error
        }
    }

    if (-not $AllowDomainMember) {
        $computerSystem = Get-CimInstance `
            -ClassName Win32_ComputerSystem `
            -Property PartOfDomain
        if ($computerSystem.PartOfDomain) {
            throw $strings.domain_error
        }
    }

    $guiServers = [ordered]@{
        '1' = 'pool.ntp.br'
        '2' = 'a.ntp.br'
        '3' = 'b.ntp.br'
        '4' = 'c.ntp.br'
    }
    $ntpServers = @('a.ntp.br', 'b.ntp.br', 'c.ntp.br')
    $manualPeerList = (
        $ntpServers | ForEach-Object { "$_,0x8" }
    ) -join ' '

    Write-Step -Text $strings.registry
    $serverRegistryPath = (
        'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\DateTime\Servers'
    )
    if (-not (Test-Path -Path $serverRegistryPath)) {
        New-Item -Path $serverRegistryPath -Force | Out-Null
    }
    Set-Item -Path $serverRegistryPath -Value '1'
    foreach ($server in $guiServers.GetEnumerator()) {
        New-ItemProperty `
            -Path $serverRegistryPath `
            -Name $server.Key `
            -Value $server.Value `
            -PropertyType String `
            -Force | Out-Null
    }

    Write-Step -Text $strings.service
    $timeService = Get-Service -Name 'w32time'
    if (
        $timeService.StartType -eq
        [System.ServiceProcess.ServiceStartMode]::Disabled
    ) {
        Set-Service -Name 'w32time' -StartupType Manual
    }
    if (
        $timeService.Status -ne
        [System.ServiceProcess.ServiceControllerStatus]::Running
    ) {
        Start-Service -Name 'w32time'
    }

    $script:w32TimePath = Join-Path `
        -Path $env:SystemRoot `
        -ChildPath 'System32\w32tm.exe'

    Write-Step -Text $strings.configure
    Invoke-W32Time -Arguments @(
        '/config'
        "/manualpeerlist:$manualPeerList"
        '/syncfromflags:manual'
        '/update'
    ) | Out-Null

    Restart-Service -Name 'w32time' -Force
    (Get-Service -Name 'w32time').WaitForStatus(
        [System.ServiceProcess.ServiceControllerStatus]::Running,
        [TimeSpan]::FromSeconds(15)
    )
    Start-Sleep -Seconds 2

    Write-Step -Text $strings.synchronize
    $syncResult = $null
    foreach ($attempt in 1..3) {
        $syncResult = Invoke-W32Time `
            -Arguments @('/resync', '/rediscover') `
            -AllowFailure
        if ($syncResult.ExitCode -eq 0) {
            break
        }
        if ($attempt -lt 3) {
            Write-Host "$($strings.retry) ($($attempt + 1)/3)."
            Start-Sleep -Seconds 4
        }
    }
    if ($syncResult.ExitCode -ne 0) {
        $details = $syncResult.Output -join [Environment]::NewLine
        throw "$($strings.command_error) $($syncResult.ExitCode).`n$details"
    }

    $sourceResult = Invoke-W32Time -Arguments @('/query', '/source')
    $source = ($sourceResult.Output -join ' ').Trim()
    if ($source -notmatch '(?i)ntp\.br') {
        throw "$($strings.source_error) $source"
    }

    $statusResult = Invoke-W32Time -Arguments @('/query', '/status')

    Write-Host ''
    Write-Host $strings.complete -ForegroundColor Green
    Write-Host "$($strings.source): $source"
    Write-Host ''
    Write-Host "$($strings.status):"
    $statusResult.Output | ForEach-Object { Write-Host $_ }
}
catch {
    $exitCode = 1
    Write-Host ''
    Write-Host "$($strings.error):" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
}
finally {
    if (-not $NoPause) {
        Write-Host ''
        Read-Host -Prompt $strings.exit | Out-Null
    }
}

exit $exitCode
