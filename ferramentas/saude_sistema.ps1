# =====================================================================
#  Arandu - Ajudante de Saude do Sistema (somente leitura)
# ---------------------------------------------------------------------
#  Servidor HTTP local em PowerShell PURO (sem instalar nada).
#  Expoe dados de RAM, disco, CPU e arquivos limpaveis para o painel.
#
#  ENDPOINTS (todos GET, JSON, apenas 127.0.0.1):
#     /saude    -> RAM, discos, CPU, uptime
#     /limpeza  -> lista de locais limpaveis com tamanho (NAO apaga nada)
#     /ping     -> teste de vida
#
#  SEGURANCA: escuta SO em 127.0.0.1 (nao acessivel pela rede).
#             NUNCA apaga arquivos. So mede e relata.
#
#  Uso:  powershell -ExecutionPolicy Bypass -File saude_sistema.ps1
#        (o Painel_Saude.vbs faz isso escondido por voce)
# =====================================================================

$ErrorActionPreference = 'SilentlyContinue'
$PORTA = 8099

# ---------- utilidades ----------
function Get-FolderSizeMB([string]$caminho) {
    if (-not (Test-Path -LiteralPath $caminho)) { return 0 }
    try {
        $sum = (Get-ChildItem -LiteralPath $caminho -Recurse -File -Force -ErrorAction SilentlyContinue |
                Measure-Object -Property Length -Sum).Sum
        if (-not $sum) { return 0 }
        return [math]::Round($sum / 1MB, 1)
    } catch { return 0 }
}

function Get-Saude {
    $os = Get-CimInstance Win32_OperatingSystem
    $totalRAM = [math]::Round($os.TotalVisibleMemorySize / 1MB, 2)
    $freeRAM  = [math]::Round($os.FreePhysicalMemory / 1MB, 2)
    $usedRAM  = [math]::Round($totalRAM - $freeRAM, 2)
    $pctRAM   = if ($totalRAM -gt 0) { [math]::Round(($usedRAM / $totalRAM) * 100, 1) } else { 0 }

    $discos = @()
    Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3" | ForEach-Object {
        $tot  = [math]::Round($_.Size / 1GB, 1)
        $free = [math]::Round($_.FreeSpace / 1GB, 1)
        $used = [math]::Round($tot - $free, 1)
        $pct  = if ($tot -gt 0) { [math]::Round(($used / $tot) * 100, 1) } else { 0 }
        $discos += [pscustomobject]@{
            unidade   = $_.DeviceID
            total_gb  = $tot
            livre_gb  = $free
            usado_gb  = $used
            usado_pct = $pct
        }
    }

    $cpu = (Get-CimInstance Win32_Processor | Measure-Object -Property LoadPercentage -Average).Average
    $cpu = [math]::Round($cpu, 0)

    $boot = $os.LastBootUpTime
    $uptimeH = [math]::Round(((Get-Date) - $boot).TotalHours, 1)

    return [pscustomobject]@{
        hostname     = $env:COMPUTERNAME
        coletado_em  = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
        ram          = [pscustomobject]@{
            total_gb  = $totalRAM
            livre_gb  = $freeRAM
            usado_gb  = $usedRAM
            usado_pct = $pctRAM
        }
        discos       = $discos
        cpu_pct      = $cpu
        uptime_horas = $uptimeH
    }
}

function Get-Limpeza {
    $itens = @()

    # 1) TEMP do usuario
    $itens += [pscustomobject]@{
        nome       = 'Arquivos temporarios (usuario)'
        caminho    = $env:TEMP
        tamanho_mb = (Get-FolderSizeMB $env:TEMP)
        seguro     = $true
        descricao  = 'Cache temporario de programas. Seguro de limpar.'
    }

    # 2) TEMP do Windows
    $winTmp = Join-Path $env:SystemRoot 'Temp'
    $itens += [pscustomobject]@{
        nome       = 'Arquivos temporarios (Windows)'
        caminho    = $winTmp
        tamanho_mb = (Get-FolderSizeMB $winTmp)
        seguro     = $true
        descricao  = 'Temporarios do sistema. Seguro de limpar.'
    }

    # 3) Cache do Windows Update
    $wu = Join-Path $env:SystemRoot 'SoftwareDistribution\Download'
    $itens += [pscustomobject]@{
        nome       = 'Cache do Windows Update'
        caminho    = $wu
        tamanho_mb = (Get-FolderSizeMB $wu)
        seguro     = $true
        descricao  = 'Instaladores ja aplicados. Seguro de limpar.'
    }

    # 4) Lixeira
    $rb = Join-Path $env:SystemDrive '$Recycle.Bin'
    $itens += [pscustomobject]@{
        nome       = 'Lixeira'
        caminho    = $rb
        tamanho_mb = (Get-FolderSizeMB $rb)
        seguro     = $true
        descricao  = 'Arquivos ja enviados para a lixeira. Confira antes de esvaziar.'
    }

    # 5) Prefetch
    $pf = Join-Path $env:SystemRoot 'Prefetch'
    $itens += [pscustomobject]@{
        nome       = 'Prefetch'
        caminho    = $pf
        tamanho_mb = (Get-FolderSizeMB $pf)
        seguro     = $true
        descricao  = 'Cache de inicializacao. O Windows recria sozinho.'
    }

    # 6) Downloads antigos (> 90 dias) - apenas alerta, NUNCA limpar automatico
    $dl = Join-Path $env:USERPROFILE 'Downloads'
    $dlOldMB = 0
    if (Test-Path -LiteralPath $dl) {
        $corte = (Get-Date).AddDays(-90)
        $dlOldMB = [math]::Round((((Get-ChildItem -LiteralPath $dl -Recurse -File -Force -ErrorAction SilentlyContinue |
                     Where-Object { $_.LastWriteTime -lt $corte }) |
                     Measure-Object -Property Length -Sum).Sum) / 1MB, 1)
        if (-not $dlOldMB) { $dlOldMB = 0 }
    }
    $itens += [pscustomobject]@{
        nome       = 'Downloads com mais de 90 dias'
        caminho    = $dl
        tamanho_mb = $dlOldMB
        seguro     = $false
        descricao  = 'Pode conter arquivos pessoais. Revise um a um antes de apagar.'
    }

    $total = [math]::Round((($itens | Measure-Object -Property tamanho_mb -Sum).Sum), 1)
    $segMB = [math]::Round((($itens | Where-Object { $_.seguro } | Measure-Object -Property tamanho_mb -Sum).Sum), 1)

    return [pscustomobject]@{
        coletado_em        = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
        itens              = $itens
        total_mb           = $total
        total_seguro_mb    = $segMB
        observacao         = 'Nada foi apagado. Esta e apenas uma analise de leitura.'
    }
}

# ---------- Outlook local (COM) : agenda + e-mail, somente leitura ----------
$script:OL = $null

function Get-Outlook {
    # reutiliza a instancia em cache; recria se cair
    if ($script:OL -ne $null) {
        try { $null = $script:OL.GetNamespace('MAPI'); return $script:OL }
        catch { $script:OL = $null }
    }
    # tenta anexar a um Outlook ja aberto; so inicia um novo se preciso
    try { $script:OL = [Runtime.InteropServices.Marshal]::GetActiveObject('Outlook.Application') }
    catch { $script:OL = New-Object -ComObject Outlook.Application }
    return $script:OL
}

function Get-Agenda {
    try {
        $ol  = Get-Outlook
        $ns  = $ol.GetNamespace('MAPI')
        $cal = $ns.GetDefaultFolder(9)              # 9 = Calendario
        $items = $cal.Items
        $items.Sort('[Start]')            # ORDEM IMPORTA: Sort primeiro...
        $items.IncludeRecurrences = $true # ...e SO entao IncludeRecurrences (senao o Sort reseta e some os recorrentes)
        # IMPORTANTE: o Outlook Restrict espera a data no formato da CULTURA DO SISTEMA
        # (pt-BR => dd/MM/yyyy). Usar InvariantCulture (MM/dd) faz o filtro virar uma
        # janela vazia em maquinas pt-BR. ToString('g') usa a cultura local = correto.
        $ini = (Get-Date)
        $fim = $ini.AddDays(14)
        $filtro = "[Start] >= '" + $ini.ToString('g') + "' AND [Start] <= '" + $fim.ToString('g') + "'"
        $rest = $items.Restrict($filtro)
        $eventos = @()
        $it = $rest.GetFirst()
        $n = 0
        while ($it -ne $null -and $n -lt 25) {
            try {
                $eventos += [pscustomobject]@{
                    assunto  = [string]$it.Subject
                    inicio   = $it.Start.ToString('yyyy-MM-dd HH:mm')
                    fim      = $it.End.ToString('yyyy-MM-dd HH:mm')
                    local    = [string]$it.Location
                    dia_todo = [bool]$it.AllDayEvent
                }
                $n++
            } catch {}
            $it = $rest.GetNext()
        }
        return [pscustomobject]@{
            coletado_em = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
            janela_dias = 14
            total       = $eventos.Count
            eventos     = $eventos
        }
    } catch {
        return [pscustomobject]@{
            erro = 'Nao consegui ler a agenda do Outlook.'
            dica = 'Tenha o Outlook CLASSICO instalado e configurado. Detalhe: ' + $_.Exception.Message
        }
    }
}

function Get-Email {
    try {
        $ol    = Get-Outlook
        $ns    = $ol.GetNamespace('MAPI')
        $inbox = $ns.GetDefaultFolder(6)            # 6 = Caixa de Entrada
        $items = $inbox.Items
        $items.Sort('[ReceivedTime]', $true)        # mais recentes primeiro
        $msgs = @()
        $m = $items.GetFirst()
        $n = 0
        while ($m -ne $null -and $n -lt 15) {
            try {
                if ($m.Class -eq 43) {              # 43 = item de e-mail (olMail)
                    $msgs += [pscustomobject]@{
                        de       = [string]$m.SenderName
                        assunto  = [string]$m.Subject
                        recebido = $m.ReceivedTime.ToString('yyyy-MM-dd HH:mm')
                        nao_lido = [bool]$m.UnRead
                    }
                    $n++
                }
            } catch {}
            $m = $items.GetNext()
        }
        $naoLidos = 0
        try { $naoLidos = ($inbox.Items.Restrict('[UnRead] = true')).Count } catch {}
        return [pscustomobject]@{
            coletado_em = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
            caixa       = [string]$inbox.Name
            total_caixa = $inbox.Items.Count
            nao_lidos   = $naoLidos
            mensagens   = $msgs
        }
    } catch {
        return [pscustomobject]@{
            erro = 'Nao consegui ler os e-mails do Outlook.'
            dica = 'Tenha o Outlook CLASSICO instalado e configurado. Detalhe: ' + $_.Exception.Message
        }
    }
}

# ---------- servidor HTTP ----------
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://127.0.0.1:$PORTA/")
try {
    $listener.Start()
} catch {
    Write-Host "Nao foi possivel abrir a porta $PORTA. Ja esta em uso? $_"
    exit 1
}
Write-Host "Ajudante de saude do Arandu rodando em http://127.0.0.1:$PORTA/  (Ctrl+C para sair)"

while ($listener.IsListening) {
    try {
        $ctx = $listener.GetContext()
        $req = $ctx.Request
        $res = $ctx.Response

        # CORS (o painel abre como file:// -> origin 'null')
        $res.Headers.Add('Access-Control-Allow-Origin', '*')
        $res.Headers.Add('Cache-Control', 'no-store')

        if ($req.HttpMethod -eq 'OPTIONS') {
            $res.StatusCode = 204
            $res.Close()
            continue
        }

        $rota = $req.Url.AbsolutePath.ToLower()
        $obj = $null
        switch ($rota) {
            '/saude'   { $obj = Get-Saude }
            '/limpeza' { $obj = Get-Limpeza }
            '/agenda'  { $obj = Get-Agenda }
            '/email'   { $obj = Get-Email }
            '/ping'    { $obj = [pscustomobject]@{ ok = $true; servico = 'arandu-saude'; porta = $PORTA } }
            default    {
                $res.StatusCode = 404
                $obj = [pscustomobject]@{ erro = 'rota desconhecida'; rotas = @('/saude','/limpeza','/agenda','/email','/ping') }
            }
        }

        $json  = $obj | ConvertTo-Json -Depth 6
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($json)
        $res.ContentType = 'application/json; charset=utf-8'
        $res.ContentLength64 = $bytes.Length
        $res.OutputStream.Write($bytes, 0, $bytes.Length)
        $res.Close()
    } catch {
        try { $res.StatusCode = 500; $res.Close() } catch {}
    }
}
