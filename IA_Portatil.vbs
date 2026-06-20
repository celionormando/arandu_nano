' ============================================================
'  IA Portatil - lancador "1 clique"
'  - Sobe o servidor llamafile SEM janela de console (escondido)
'  - Abre a IA no navegador padrao do sistema
'  - Funciona em QUALQUER letra de drive (usa a propria pasta)
' ============================================================
Option Explicit
Dim fso, sh, base, modelo, exe, chatUrl, cmd, i, ok, http

Set fso = CreateObject("Scripting.FileSystemObject")
Set sh  = CreateObject("WScript.Shell")

' pasta onde este .vbs esta (independe da letra do drive)
base   = fso.GetParentFolderName(WScript.ScriptFullName)
exe    = base & "\llamafile.exe"

' modelo ativo: lido de modelo.txt (troque o modelo editando esse arquivo,
' ou rode Usar_1B_Rapido.bat / Usar_3B_Qualidade.bat). Padrao: 1B rapido.
Dim nomeModelo, cfgFile
nomeModelo = "Llama-3.2-1B-Instruct-Q4_K_M.gguf"
cfgFile = base & "\modelo.txt"
If fso.FileExists(cfgFile) Then
    Dim linha
    linha = Trim(fso.OpenTextFile(cfgFile, 1).ReadLine())
    If linha <> "" Then nomeModelo = linha
End If
modelo = base & "\" & nomeModelo

' se ja houver servidor respondendo, so abre a janela
If Not ServidorNoAr() Then
    cmd = """" & exe & """ --server -m """ & modelo & """" & _
          " --host 127.0.0.1 --port 8080 -c 2048 -t 3 -fa on" & _
          " -ctk q8_0 -ctv q8_0 -ub 256 -b 512 --gpu disable"
    sh.CurrentDirectory = base
    ' 0 = janela oculta (sem console preto); False = nao espera
    sh.Run cmd, 0, False

    ' espera o modelo carregar (ate ~40s), checando a porta
    ok = False
    For i = 1 To 40
        WScript.Sleep 1000
        If ServidorNoAr() Then ok = True : Exit For
    Next
    If Not ok Then
        MsgBox "Nao consegui iniciar o servidor da IA." & vbCrLf & _
               "Verifique se os arquivos estao na pasta.", vbExclamation, "Arandu IA"
        WScript.Quit
    End If
End If

' URL local da interface (modo arquivo)
chatUrl = "file:///" & Replace(base, "\", "/") & "/chat.html"

' abre no navegador padrao configurado no sistema
sh.Run chatUrl, 1, False

' ---------- funcoes ----------
Function ServidorNoAr()
    ServidorNoAr = False
    On Error Resume Next
    Set http = CreateObject("MSXML2.XMLHTTP")
    http.open "GET", "http://127.0.0.1:8080/props", False
    http.send
    If Err.Number = 0 Then
        If http.status = 200 Then ServidorNoAr = True
    End If
    On Error GoTo 0
End Function
