# Guia rápido do testador — Arandu Mirim 1.1

Obrigado por testar a **Rendeia**! É um assistente de IA que roda **100% no seu
computador**, sem internet, sem instalar nada e sem enviar seus dados para
lugar nenhum. Tudo acontece dentro da pasta que você baixou.

---

## 1. O que você precisa

- **Windows 10 ou 11** (há também lançadores para Linux/macOS, veja o fim)
- **~2 GB de memória RAM livre**
- **~1,5 GB de espaço em disco** (o pacote já vem com tudo)
- Um navegador (Chrome, Edge, Firefox — qualquer um)

> Não precisa de placa de vídeo. Roda no processador (CPU).

---

## 2. Como instalar (é só extrair)

1. **Extraia** o arquivo `Arandu-Nano-1.1.zip` para uma pasta qualquer
   (ex.: a Área de Trabalho ou um pendrive).
2. Abra a pasta extraída. Você verá o arquivo **`IA_Portatil.vbs`** — é por ele
   que se inicia o Arandu.

Não há instalação. Para remover depois, basta apagar a pasta.

---

## 3. Primeiro uso — liberar o aviso do Windows ⚠️ (importante)

Como o Arandu vem da internet, na **primeira vez** o Windows pode mostrar um
aviso de segurança (SmartScreen) ou o antivírus pode pedir confirmação. **Isso é
normal** — o programa não é assinado com um certificado pago, mas é seguro e
funciona offline. Faça assim:

**Se aparecer "O Windows protegeu o seu computador":**
1. Clique em **"Mais informações"**
2. Clique em **"Executar assim mesmo"**

**Dica para evitar o aviso de uma vez (opcional):** antes de abrir, clique com o
**botão direito** no `llamafile.exe` → **Propriedades** → marque
**"Desbloquear"** (canto inferior) → **OK**. Repita nos arquivos `.vbs` se
necessário.

> Se o antivírus bloquear o `llamafile.exe`, adicione a pasta do Arandu como
> exceção. O `llamafile` é um projeto de código aberto da Mozilla; alguns
> antivírus o sinalizam por excesso de zelo.

---

## 4. Usar o Arandu

1. Dê **dois cliques** em **`IA_Portatil.vbs`**.
2. Aguarde de **10 a 40 segundos** (o modelo está sendo carregado na memória —
   só demora na primeira vez de cada sessão). Nenhuma janela preta vai aparecer;
   isso é proposital.
3. O **navegador abre sozinho** com a tela do chat.
4. Digite sua pergunta e converse normalmente. 🎉

Coisas para testar: fazer perguntas gerais, pedir um resumo, uma redação, uma
tradução, tirar uma dúvida do dia a dia. Tudo em português.

---

## 5. Desligar

Quando terminar, dê dois cliques em **`Desligar_IA.bat`**. Isso encerra o
programa e libera a memória. (Fechar só o navegador **não** desliga o motor.)

> **Economia automática de memória:** mesmo sem desligar, depois de **3 minutos
> sem uso** o Arandu entra em modo de descanso e libera boa parte da memória
> sozinho. A próxima mensagem o reativa em ~2 segundos. Ou seja: se você fechar
> o navegador e esquecer, ele para de consumir RAM ativa por conta própria.

---

## 6. Problemas comuns

| Sintoma | Solução |
|---|---|
| O navegador não abriu | Aguarde até 40s. Se não abrir, abra o `chat.html` manualmente (dois cliques). |
| "Não consegui iniciar o servidor" | Veja se o `llamafile.exe` foi desbloqueado (passo 3). |
| O chat diz que não conecta | O motor ainda está carregando — espere alguns segundos e recarregue a página. |
| Está lento | Normal em PCs mais antigos. A 1ª resposta é a mais lenta; as seguintes melhoram. |
| 1ª resposta após uma pausa demora ~2s a mais | Normal: o Arandu "cochila" após 3 min parado para poupar memória e acorda sozinho. |
| Antivírus bloqueou | Adicione a pasta do Arandu como exceção (passo 3). |

---

## 7. Como dar seu feedback

Conte o que achou: a qualidade das respostas, a velocidade, se travou em algo,
se alguma resposta veio errada ou sem sentido. Tudo ajuda a melhorar o Arandu.

---

## Linux / macOS

No terminal, dentro da pasta:

```sh
chmod +x iniciar.sh desligar.sh
./iniciar.sh      # sobe o motor e abre o navegador
./desligar.sh     # encerra
```

---

*O Arandu é software livre (Apache-2.0). Funciona totalmente offline — nada do
que você digitar sai do seu computador.*
