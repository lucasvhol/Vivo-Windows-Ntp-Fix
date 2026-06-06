[Português (Brasil)](README.md) | **English**

# Vivo Windows Clock Sync Fix

Some Vivo customers in Brazil cannot synchronize the Windows clock with
Microsoft's default time server. This project configures Windows to use the
public NTP.br servers instead.

## Download and run

[Download the latest version](https://github.com/lucasvhol/vivo-windows-ntp-fix/releases/latest/download/vivo-windows-ntp-fix.zip)

1. Download and extract `vivo-windows-ntp-fix.zip`.
2. Double-click `Instalar-Correcao-Horario-Vivo.bat`.
3. Accept the Windows administrator prompt.
4. Press ENTER and wait for the success message.

The two files from the ZIP must remain in the same folder. The installer uses
only built-in Windows components and does not install a background application.

Windows may show a security warning because the scripts are not digitally
signed. Download releases only from this repository.

## Requirements

- Windows 10 or Windows 11
- An account with administrator permission
- Network access to UDP port 123

The installer stops without making changes when Windows Time is controlled by
Group Policy. It also stops on domain-joined computers to avoid replacing an
organization's configuration.

## What changes

The installer:

1. Adds the public NTP.br servers to the Windows time server list.
2. Configures `a.ntp.br`, `b.ntp.br`, and `c.ntp.br` as active time sources.
3. Starts or restarts the Windows Time service.
4. Tries synchronization up to three times.
5. Reports success only when Windows confirms an `ntp.br` source.

Running it more than once does not duplicate the configuration.

## Manual verification

Open PowerShell or Command Prompt as administrator:

```powershell
w32tm /query /source
w32tm /query /peers
w32tm /query /status
```

The displayed source should contain `ntp.br`.

## Troubleshooting

- Extract the ZIP before running the installer. Do not run it from the ZIP
  preview.
- If no source responds, check whether the firewall, router, or ISP permits NTP
  traffic over UDP port 123.
- If a company or school manages the computer, contact its administrator.
- NTP corrects UTC time. Time zone and daylight-saving settings are separate
  Windows settings.

## Advanced use

System administrators can run `fix-ntp-vivo.ps1` directly. It supports
`-Yes`, `-NoPause`, and `-AllowDomainMember`. The last option should be used
only by an administrator who understands the domain time configuration.

## References

- [Official NTP.br Windows guide](https://ntp.br/guia/windows/)
- [Official NTP.br server structure](https://ntp.br/conteudo/estrutura/)
- [Windows Time service documentation](https://learn.microsoft.com/windows-server/networking/windows-time-service/windows-time-service-tools-and-settings)
