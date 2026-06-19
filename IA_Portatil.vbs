' ============================================================
'  IA Portatil - lancador "1 clique"
'  - Sobe o servidor llamafile SEM janela de console (escondido)
'  - Abre a IA numa JANELA MINIMA (modo app: sem abas/barra)
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

' abre numa JANELA MINIMA via modo app (Edge -> Chrome -> navegador padrao)
Dim navExe
navExe = CaminhoNavegador("msedge.exe")
If navExe = "" Then navExe = CaminhoNavegador("chrome.exe")

If navExe <> "" Then
    ' --user-data-dir (perfil proprio na USB) forca uma janela APP isolada,
    ' mesmo com o Edge/Chrome ja aberto. Mantem tudo portatil.
    Dim perfil
    perfil = base & "\.appprofile"
    sh.Run """" & navExe & """ --app=""" & chatUrl & """" & _
           " --window-size=460,780 --user-data-dir=""" & perfil & """" & _
           " --no-first-run --no-default-browser-check", 1, False
Else
    sh.Run chatUrl, 1, False   ' fallback: navegador padrao (com abas)
End If

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

' descobre o caminho completo do navegador pelo registro (App Paths)
Function CaminhoNavegador(exeName)
    Dim p
    CaminhoNavegador = ""
    On Error Resume Next
    p = sh.RegRead("HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\" & exeName & "\")
    If p = "" Then p = sh.RegRead("HKLM\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\App Paths\" & exeName & "\")
    On Error GoTo 0
    If Not IsNull(p) Then
        If fso.FileExists(p) Then CaminhoNavegador = p
    End If
End Function
