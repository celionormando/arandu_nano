# Ferramentas do Arandu — Assistente do Sistema

Camada que transforma o Arandu de "só chat" em **assistente que enxerga o seu PC**.
Tudo **100% local, offline e somente leitura**.

## Por que existe uma "ponte"

O chat do Arandu roda no **navegador**, que por segurança não consegue ver RAM,
disco ou arquivos. Então um pequeno **ajudante** roda ao lado, com acesso ao
sistema, e responde por HTTP no `127.0.0.1`. O navegador pergunta, o ajudante mede.

```
  Painel/chat (navegador)  ──HTTP──▶  AJUDANTE (porta 8099, mede o PC)
                           ──HTTP──▶  llamafile / Arandu (porta 8080, narra/analisa)
```

O **frontend é o mesmo em todo SO** (só navegador + `fetch`). O único pedaço por SO
é o ajudante — mas ele mantém o **mesmo contrato HTTP** (mesmas rotas e JSON):

| SO | Ajudante | Runtime |
|----|----------|---------|
| Windows | `saude_sistema.ps1` | PowerShell (vem de fábrica) |
| Linux / macOS | `saude_sistema.py` | Python 3 (stdlib, sem `pip`) |

## Primeira função: Saúde do Sistema

- **`ferramentas/saude_sistema.ps1`** — ajudante em PowerShell puro (sem instalar nada).
  Endpoints (GET, JSON, só `127.0.0.1`):
  - `/saude`   → RAM, discos, CPU, tempo ligado
  - `/limpeza` → arquivos limpáveis com tamanho (TEMP, Windows Update, lixeira, prefetch…)
  - `/agenda`  → próximos 14 dias do **Outlook** (assunto, horário, local)
  - `/email`   → e-mails recentes do **Outlook** (remetente, assunto, horário, não lido)
  - `/ping`    → teste de vida
- **`Painel_Saude.html`** — painel visual (tema do Arandu). Mostra os medidores,
  a limpeza, a **agenda** e os **e-mails**, com botões **"Pedir análise / Resumir
  com Arandu"** que enviam os dados ao modelo e recebem um resumo em português.
- **`Painel_Saude.vbs`** — lançador de 1 clique: sobe o ajudante escondido e abre o painel.
- Há também um **mini painel** fixo no canto superior direito do `chat.html`
  (RAM/CPU/disco), que aparece sozinho quando o ajudante está no ar.

### Como usar

1. Duplo clique em **`Painel_Saude.vbs`** (ou abra o chat: o `IA_Portatil.vbs` já
   sobe o ajudante junto).
2. Para "análise/resumo pela IA", tenha o Arandu rodando (porta 8080).

## Agenda e e-mail (Outlook local)

Lidos do **Outlook clássico** via automação **COM** — 100% local, **sem internet**.
São **sob demanda**: só ao clicar "Carregar". A primeira leitura pode iniciar o
Outlook em segundo plano. Mostramos só metadados (assunto, remetente, horário);
**o conteúdo das mensagens não é aberto**. Requer o Outlook desktop instalado e
um perfil configurado (o "novo Outlook" do Windows não expõe COM).

> Detalhe que custou caro: o `Restrict` do Outlook espera a data no formato da
> **cultura do sistema** (pt-BR = `dd/MM/yyyy`). Usar `InvariantCulture` (MM/dd)
> faz a janela virar vazia. E `IncludeRecurrences` deve ser ligado **depois** do
> `Sort`, senão os eventos recorrentes somem.

## Multiplataforma (Linux e macOS)

- **`ferramentas/saude_sistema.py`** — ajudante equivalente em Python 3 (só stdlib).
  Cobre `/saude` e `/limpeza` em **Linux** (`/proc`, `~/.cache`, `~/.local/share/Trash`,
  `/tmp`) e **macOS** (`sysctl`/`vm_stat`, `~/Library/Caches`, `~/.Trash`). `/agenda` e
  `/email` por enquanto retornam um aviso amigável nesses SOs (o painel trata).
- Os lançadores **`iniciar.sh`** e **`iniciar_rag.sh`** sobem esse ajudante junto com o
  chat (se houver `python3`), igual ao `IA_Portatil.vbs` no Windows. Mesma porta 8099.
- Agenda/e-mail por SO (próximo passo): **macOS** via `osascript` (Calendar.app/Mail.app);
  **Linux** depende do cliente (Thunderbird/Evolution/`.ics`).

> Atenção a quem editar: os `.sh` precisam de fim de linha **LF** (CRLF quebra o
> shebang no Linux). O `.gitattributes` já força `*.sh text eol=lf`.

## Princípio de segurança

> O Arandu **mede e sugere; nunca apaga**. Toda exclusão é decidida e confirmada
> por você. O ajudante só escuta em `127.0.0.1` (invisível para a rede).

## Próximas funções (planejadas)

- **Limpeza assistida** — botão para abrir a Limpeza de Disco do Windows nos itens
  sugeridos (ainda com confirmação manual; o Arandu não apaga sozinho).
- **Ações na agenda/e-mail** — hoje é só leitura/resumo. Criar evento ou rascunho
  de resposta seria um passo seguinte (sempre com confirmação).

## Decisão técnica: por que roteamento de intenção, não "tool-calling"

O modelo é pequeno (1,7B) e gera chamadas de função em JSON de forma pouco
confiável. Então o número vem sempre do **código determinístico** (o ajudante);
o modelo entra só para **explicar/aconselhar** em linguagem natural. Mais robusto
e à prova de alucinação.
