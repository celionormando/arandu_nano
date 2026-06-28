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

# ---------- voz natural (Piper TTS, opcional) ----------
# Sintetiza fala pt-BR offline. Spawn-por-requisicao: so usa RAM enquanto fala.
# Binario + voz em ferramentas\piper\ (nao versionados, baixados a parte).
$script:PIPER_DIR = Join-Path $PSScriptRoot 'piper'

function Piper-Falar([string]$texto) {
    if ([string]::IsNullOrWhiteSpace($texto)) { return $null }
    $exe   = Join-Path $script:PIPER_DIR 'piper.exe'
    $model = Join-Path $script:PIPER_DIR 'pt_BR-faber-medium.onnx'
    if (-not (Test-Path $exe) -or -not (Test-Path $model)) { return $null }
    if ($texto.Length -gt 1500) { $texto = $texto.Substring(0, 1500) }  # limite p/ latencia
    $tmp = Join-Path $env:TEMP ('arandu_voz_' + [guid]::NewGuid().ToString('N') + '.wav')
    try {
        $psi = New-Object System.Diagnostics.ProcessStartInfo
        $psi.FileName  = $exe
        $psi.Arguments = '--model "' + $model + '" --output_file "' + $tmp + '"'
        $psi.WorkingDirectory     = $script:PIPER_DIR
        $psi.UseShellExecute      = $false
        $psi.CreateNoWindow       = $true
        $psi.RedirectStandardInput = $true
        $p = [System.Diagnostics.Process]::Start($psi)
        # envia o texto em UTF-8 (acentos pt-BR) pela entrada padrao
        $inBytes = [System.Text.Encoding]::UTF8.GetBytes($texto + "`n")
        $p.StandardInput.BaseStream.Write($inBytes, 0, $inBytes.Length)
        $p.StandardInput.BaseStream.Flush()
        $p.StandardInput.Close()
        if (-not $p.WaitForExit(30000)) { try { $p.Kill() } catch {}; return $null }
        if (Test-Path $tmp) { return [System.IO.File]::ReadAllBytes($tmp) }
    } catch {
        return $null
    } finally {
        Remove-Item $tmp -Force -ErrorAction SilentlyContinue
    }
    return $null
}

# ---------- OCR de imagens (Tesseract portatil, opcional) ----------
# Mesmo padrao do Piper: binario em ferramentas\tesseract\ (nao versionado, baixado a parte).
# Le imagem (bytes) e devolve o texto. Idiomas via tessdata (por+eng por padrao).
$script:OCR_DIR = Join-Path $PSScriptRoot 'tesseract'
function Ocr-Imagem([byte[]]$bytes, [string]$lang) {
    if ($null -eq $bytes -or $bytes.Length -eq 0) { return $null }
    $exe = Join-Path $script:OCR_DIR 'tesseract.exe'
    if (-not (Test-Path $exe)) { return $null }
    if ($lang -notmatch '^[a-zA-Z]{2,}([+_][a-zA-Z]{2,})*$') { $lang = 'por+eng' }   # sanitiza
    $img = Join-Path $env:TEMP ('arandu_ocr_' + [guid]::NewGuid().ToString('N') + '.png')
    try {
        [System.IO.File]::WriteAllBytes($img, $bytes)
        $psi = New-Object System.Diagnostics.ProcessStartInfo
        $psi.FileName  = $exe
        $psi.Arguments = '"' + $img + '" stdout -l ' + $lang
        $psi.WorkingDirectory      = $script:OCR_DIR
        $psi.UseShellExecute       = $false
        $psi.CreateNoWindow        = $true
        $psi.RedirectStandardOutput = $true
        $psi.RedirectStandardError  = $true
        $psi.StandardOutputEncoding = [System.Text.Encoding]::UTF8
        $tessdata = Join-Path $script:OCR_DIR 'tessdata'
        if (Test-Path $tessdata) { $psi.EnvironmentVariables['TESSDATA_PREFIX'] = $tessdata }
        $p = [System.Diagnostics.Process]::Start($psi)
        $out = $p.StandardOutput.ReadToEnd()
        $null = $p.StandardError.ReadToEnd()
        if (-not $p.WaitForExit(120000)) { try { $p.Kill() } catch {}; return $null }
        return $out
    } catch {
        return $null
    } finally {
        Remove-Item $img -Force -ErrorAction SilentlyContinue
    }
}

# ---------- memoria do Arandu (perfil + indice + itens) ----------
# Camada de aprendizado local: tudo gravado em <raiz>\memoria\ no proprio USB.
#   perfil.md     -> essencial do usuario (vai SEMPRE no prompt; curto)
#   indice.json   -> mapa de itens [{id,titulo,resumo,palavras,tipo,atualizado}]
#   itens\<id>.md -> detalhe completo de cada item (hidratado SOB DEMANDA)
# So grava DENTRO de memoria\; ids validados (sem path traversal). Nunca toca em outro lugar.
$script:MEM_DIR    = Join-Path (Split-Path $PSScriptRoot -Parent) 'memoria'
$script:MEM_ITENS  = Join-Path $script:MEM_DIR 'itens'
$script:MEM_PERFIL = Join-Path $script:MEM_DIR 'perfil.md'
$script:MEM_INDICE = Join-Path $script:MEM_DIR 'indice.json'
$script:UTF8NB     = New-Object System.Text.UTF8Encoding($false)   # UTF-8 sem BOM

function Mem-Garantir {
    if (-not (Test-Path $script:MEM_DIR))    { New-Item -ItemType Directory -Path $script:MEM_DIR    -Force | Out-Null }
    if (-not (Test-Path $script:MEM_ITENS))  { New-Item -ItemType Directory -Path $script:MEM_ITENS  -Force | Out-Null }
    if (-not (Test-Path $script:MEM_PERFIL)) { [System.IO.File]::WriteAllText($script:MEM_PERFIL, '', $script:UTF8NB) }
    if (-not (Test-Path $script:MEM_INDICE)) { [System.IO.File]::WriteAllText($script:MEM_INDICE, '[]', $script:UTF8NB) }
}
function Mem-IdValido([string]$id) { return ($id -match '^[A-Za-z]\d{1,6}$') }

function Mem-LerPerfil {
    Mem-Garantir
    try { return [System.IO.File]::ReadAllText($script:MEM_PERFIL, [System.Text.Encoding]::UTF8) } catch { return '' }
}
function Mem-GravarPerfil([string]$txt) {
    Mem-Garantir
    if ($null -eq $txt) { $txt = '' }
    if ($txt.Length -gt 4000) { $txt = $txt.Substring(0, 4000) }   # teto de seguranca
    [System.IO.File]::WriteAllText($script:MEM_PERFIL, $txt, $script:UTF8NB)
}

function Mem-LerIndice {
    Mem-Garantir
    try {
        $raw = [System.IO.File]::ReadAllText($script:MEM_INDICE, [System.Text.Encoding]::UTF8)
        if ([string]::IsNullOrWhiteSpace($raw)) { return @() }
        $arr = $raw | ConvertFrom-Json
        if ($null -eq $arr) { return @() }
        return @($arr)
    } catch { return @() }
}
function Mem-GravarIndice($arr) {
    Mem-Garantir
    $a = @($arr)
    if ($a.Count -eq 0) { $json = '[]' }
    elseif ($a.Count -eq 1) { $json = '[' + ($a[0] | ConvertTo-Json -Depth 6) + ']' }  # forca array p/ 1 item
    else { $json = $a | ConvertTo-Json -Depth 6 }
    [System.IO.File]::WriteAllText($script:MEM_INDICE, $json, $script:UTF8NB)
}

function Mem-NovoId([string]$tipo) {
    if ([string]::IsNullOrWhiteSpace($tipo)) { $tipo = 'M' }
    $pref = ($tipo.Substring(0,1)).ToUpper()
    $max = 0
    foreach ($it in (Mem-LerIndice)) {
        if ($it.id -match ('^' + $pref + '(\d+)$')) {
            $n = [int]$matches[1]; if ($n -gt $max) { $max = $n }
        }
    }
    return ('{0}{1:D3}' -f $pref, ($max + 1))
}

function Mem-SalvarItem($dados) {
    Mem-Garantir
    $id   = [string]$dados.id
    $tipo = [string]$dados.tipo; if ([string]::IsNullOrWhiteSpace($tipo)) { $tipo = 'M' }
    $tipo = $tipo.Substring(0,1).ToUpper()
    if ([string]::IsNullOrWhiteSpace($id)) { $id = Mem-NovoId $tipo }
    if (-not (Mem-IdValido $id)) { throw 'id invalido' }

    $conteudo = [string]$dados.conteudo
    [System.IO.File]::WriteAllText((Join-Path $script:MEM_ITENS ($id + '.md')), $conteudo, $script:UTF8NB)

    $palavras = @()
    if ($dados.palavras) { $palavras = @($dados.palavras | ForEach-Object { [string]$_ }) }

    $entrada = [pscustomobject]@{
        id         = $id
        titulo     = [string]$dados.titulo
        resumo     = [string]$dados.resumo
        palavras   = $palavras
        tipo       = $tipo
        atualizado = (Get-Date).ToString('yyyy-MM-dd HH:mm')
    }
    $idx = @(Mem-LerIndice | Where-Object { $_.id -ne $id })
    $idx += $entrada
    Mem-GravarIndice $idx
    return $entrada
}

function Mem-LerItem([string]$id) {
    if (-not (Mem-IdValido $id)) { return $null }
    $p = Join-Path $script:MEM_ITENS ($id + '.md')
    if (-not (Test-Path $p)) { return $null }
    try { return [System.IO.File]::ReadAllText($p, [System.Text.Encoding]::UTF8) } catch { return $null }
}

function Mem-RemoverItem([string]$id) {
    if (-not (Mem-IdValido $id)) { return $false }
    Remove-Item (Join-Path $script:MEM_ITENS ($id + '.md')) -Force -ErrorAction SilentlyContinue
    Mem-GravarIndice (@(Mem-LerIndice | Where-Object { $_.id -ne $id }))
    return $true
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
            # preflight CORS: necessario p/ POST application/json (memoria) vindo de file:// ou outra origem
            $res.Headers.Add('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
            $res.Headers.Add('Access-Control-Allow-Headers', 'Content-Type')
            $res.StatusCode = 204
            $res.Close()
            continue
        }

        $rota = $req.Url.AbsolutePath.ToLower()

        # /falar: POST com o texto no corpo -> devolve WAV (audio binario, nao JSON)
        if ($rota -eq '/falar') {
            $texto = ''
            try {
                $sr = New-Object System.IO.StreamReader($req.InputStream, [System.Text.Encoding]::UTF8)
                $texto = $sr.ReadToEnd(); $sr.Close()
            } catch {}
            $wav = Piper-Falar $texto
            if ($wav) {
                $res.ContentType = 'audio/wav'
                $res.ContentLength64 = $wav.Length
                $res.OutputStream.Write($wav, 0, $wav.Length)
            } else {
                $res.StatusCode = 503
                $b = [System.Text.Encoding]::UTF8.GetBytes('{"erro":"voz indisponivel (piper ausente?)"}')
                $res.ContentType = 'application/json; charset=utf-8'
                $res.OutputStream.Write($b, 0, $b.Length)
            }
            $res.Close()
            continue
        }

        # /ocr: POST com a imagem (bytes) no corpo -> JSON {ok, texto}. 503 se o Tesseract nao estiver instalado.
        if ($rota -eq '/ocr') {
            $bytes = $null
            try {
                $ms = New-Object System.IO.MemoryStream
                $req.InputStream.CopyTo($ms)
                $bytes = $ms.ToArray(); $ms.Close()
            } catch {}
            $texto = Ocr-Imagem $bytes ([string]$req.QueryString['lang'])
            if ($null -ne $texto) {
                $jb = [System.Text.Encoding]::UTF8.GetBytes(([pscustomobject]@{ ok = $true; texto = $texto } | ConvertTo-Json -Depth 4))
            } else {
                $res.StatusCode = 503
                $jb = [System.Text.Encoding]::UTF8.GetBytes(([pscustomobject]@{ ok = $false; erro = 'OCR indisponivel - instale o Tesseract em ferramentas\tesseract\ (tesseract.exe + tessdata)' } | ConvertTo-Json))
            }
            $res.ContentType = 'application/json; charset=utf-8'
            $res.ContentLength64 = $jb.Length
            $res.OutputStream.Write($jb, 0, $jb.Length)
            $res.Close()
            continue
        }

        # /memoria*: perfil + indice + itens (GET le, POST grava). Sempre JSON.
        if ($rota -like '/memoria*') {
            $corpo = ''
            if ($req.HttpMethod -eq 'POST') {
                try {
                    $sr = New-Object System.IO.StreamReader($req.InputStream, [System.Text.Encoding]::UTF8)
                    $corpo = $sr.ReadToEnd(); $sr.Close()
                } catch {}
            }
            $resp = $null
            try {
                if ($rota -eq '/memoria' -and $req.HttpMethod -eq 'GET') {
                    $resp = [pscustomobject]@{ ok = $true; perfil = (Mem-LerPerfil); indice = @(Mem-LerIndice) }
                }
                elseif ($rota -eq '/memoria/item' -and $req.HttpMethod -eq 'GET') {
                    $id = [string]$req.QueryString['id']
                    $c  = Mem-LerItem $id
                    if ($null -eq $c) { $res.StatusCode = 404; $resp = [pscustomobject]@{ ok = $false; erro = 'item nao encontrado' } }
                    else { $resp = [pscustomobject]@{ ok = $true; id = $id; conteudo = $c } }
                }
                elseif ($rota -eq '/memoria/perfil' -and $req.HttpMethod -eq 'POST') {
                    Mem-GravarPerfil $corpo
                    $resp = [pscustomobject]@{ ok = $true; perfil = (Mem-LerPerfil) }
                }
                elseif ($rota -eq '/memoria/item' -and $req.HttpMethod -eq 'POST') {
                    $resp = [pscustomobject]@{ ok = $true; item = (Mem-SalvarItem ($corpo | ConvertFrom-Json)) }
                }
                elseif ($rota -eq '/memoria/remover' -and $req.HttpMethod -eq 'POST') {
                    $d = $corpo | ConvertFrom-Json
                    $resp = [pscustomobject]@{ ok = (Mem-RemoverItem ([string]$d.id)) }
                }
                else {
                    $res.StatusCode = 404
                    $resp = [pscustomobject]@{ ok = $false; erro = 'rota de memoria desconhecida' }
                }
            } catch {
                $res.StatusCode = 500
                $resp = [pscustomobject]@{ ok = $false; erro = ([string]$_.Exception.Message) }
            }
            $jb = [System.Text.Encoding]::UTF8.GetBytes(($resp | ConvertTo-Json -Depth 6))
            $res.ContentType = 'application/json; charset=utf-8'
            $res.ContentLength64 = $jb.Length
            $res.OutputStream.Write($jb, 0, $jb.Length)
            $res.Close()
            continue
        }

        $obj = $null
        switch ($rota) {
            '/saude'   { $obj = Get-Saude }
            '/limpeza' { $obj = Get-Limpeza }
            '/agenda'  { $obj = Get-Agenda }
            '/email'   { $obj = Get-Email }
            '/ping'    { $obj = [pscustomobject]@{ ok = $true; servico = 'arandu-saude'; porta = $PORTA } }
            default    {
                $res.StatusCode = 404
                $obj = [pscustomobject]@{ erro = 'rota desconhecida'; rotas = @('/saude','/limpeza','/agenda','/email','/falar','/ocr','/memoria','/memoria/item','/memoria/perfil','/memoria/remover','/ping') }
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
