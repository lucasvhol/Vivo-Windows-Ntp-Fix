**Português (Brasil)** | [English](README.en.md)

# Correção de horário do Windows para clientes Vivo

Alguns clientes da Vivo no Brasil não conseguem sincronizar o relógio do
Windows com o servidor de horário padrão da Microsoft. Este projeto configura o
Windows para usar os servidores públicos do NTP.br.

## Baixar e executar

[Baixar a versão mais recente](https://github.com/lucasvhol/vivo-windows-ntp-fix/releases/latest/download/vivo-windows-ntp-fix.zip)

1. Baixe e extraia o arquivo `vivo-windows-ntp-fix.zip`.
2. Dê dois cliques em `Instalar-Correcao-Horario-Vivo.bat`.
3. Confirme a solicitação de administrador do Windows.
4. Pressione ENTER e aguarde a mensagem de sucesso.

Os dois arquivos do ZIP devem permanecer na mesma pasta. O instalador usa
somente componentes nativos do Windows e não instala um aplicativo em segundo
plano.

O Windows pode exibir um aviso de segurança porque os scripts não possuem
assinatura digital. Baixe versões somente deste repositório.

## Requisitos

- Windows 10 ou Windows 11
- Uma conta com permissão de administrador
- Acesso de rede à porta UDP 123

O instalador é interrompido sem fazer alterações quando o serviço de horário é
controlado por Política de Grupo. Ele também é interrompido em computadores
associados a domínio para não substituir a configuração de uma organização.

## O que será alterado

O instalador:

1. Adiciona os servidores públicos do NTP.br à lista de horários do Windows.
2. Configura `a.ntp.br`, `b.ntp.br` e `c.ntp.br` como fontes ativas.
3. Inicia ou reinicia o serviço Horário do Windows.
4. Tenta sincronizar o relógio até três vezes.
5. Informa sucesso somente quando o Windows confirma uma fonte `ntp.br`.

A execução pode ser repetida sem duplicar a configuração.

## Verificação manual

Abra o PowerShell ou Prompt de Comando como administrador:

```powershell
w32tm /query /source
w32tm /query /peers
w32tm /query /status
```

A fonte exibida deve conter `ntp.br`.

## Solução de problemas

- Extraia o ZIP antes de executar. Não abra o instalador pela visualização do
  arquivo compactado.
- Se nenhuma fonte responder, confira se firewall, roteador ou provedor permite
  tráfego NTP pela porta UDP 123.
- Se uma empresa ou escola administra o computador, procure o responsável de
  TI.
- NTP corrige a hora UTC. Fuso horário e horário de verão são configurações
  separadas do Windows.

## Uso avançado

Administradores podem executar `fix-ntp-vivo.ps1` diretamente. O script aceita
`-Yes`, `-NoPause` e `-AllowDomainMember`. A última opção deve ser usada apenas
por quem conhece a configuração de horário do domínio.

## Referências

- [Guia oficial do NTP.br para Windows](https://ntp.br/guia/windows/)
- [Estrutura oficial dos servidores NTP.br](https://ntp.br/conteudo/estrutura/)
- [Documentação do serviço Horário do Windows](https://learn.microsoft.com/windows-server/networking/windows-time-service/windows-time-service-tools-and-settings)
