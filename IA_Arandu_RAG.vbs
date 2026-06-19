' ============================================================
'  Arandu IA - MODO RAG (com base de conhecimento)
'  Sobe 2 servidores ocultos: chat (8080) + embedding bge-m3 (8091)
'  e abre a interface. A indexacao/busca acontece no chat.html.
' ============================================================
Option Explicit
Dim fso, sh, base, exe, modelo, embed, chatUrl, i, http

Set fso = CreateObject("Scripting.FileSystemObject")
Set sh  = CreateObject("WScript.Shell")
base = fso.GetParentFolderName(WScript.ScriptFullName)
exe  = base & "\llamafile.exe"

' modelo de chat (modelo.txt) + modelo de embedding
Dim nomeModelo
nomeModelo = "Llama-3.2-1B-Instruct-Q4_K_M.gguf"
If fso.FileExists(base & "\modelo.txt") Then
    Dim l : l = Trim(fso.OpenTextFile(base & "\modelo.txt", 1).ReadLine())
    If l <> "" Then nomeModelo = l
End If
modelo = base & "\" & nomeModelo
embed  = base & "\rag\bge-m3-Q4_K_M.gguf"

sh.CurrentDirectory = base

' 1) servidor de CHAT (8080)
If Not PortaNoAr(8080) Then
    sh.Run """" & exe & """ --server -m """ & modelo & """ --host 127.0.0.1 --port 8080 " & _
           "-c 2048 -t 3 -fa on -ctk q8_0 -ctv q8_0 -ub 256 -b 512 --gpu disable", 0, False
End If

' 2) servidor de EMBEDDING (8091)
If Not PortaNoAr(8091) Then
    If fso.FileExists(embed) Then
        sh.Run """" & exe & """ --server --embedding -m """ & embed & """ --host 127.0.0.1 --port 8091 " & _
               "-c 2048 -t 3 --gpu disable", 0, False
    Else
        MsgBox "Modelo de embedding nao encontrado:" & vbCrLf & embed, vbExclamation, "Arandu IA - RAG"
    End If
End If

' espera os dois subirem (ate ~60s)
Dim okChat, okEmb
okChat = False : okEmb = False
For i = 1 To 60
    WScript.Sleep 1000
    If Not okChat Then okChat = PortaNoAr(8080)
    If Not okEmb  Then okEmb  = PortaNoAr(8091)
    If okChat And okEmb Then Exit For
Next
If Not okChat Then
    MsgBox "Servidor de chat nao subiu.", vbExclamation, "Arandu IA - RAG"
    WScript.Quit
End If

' abre a interface em janela minima
chatUrl = "file:///" & Replace(base, "\", "/") & "/chat.html"
Dim navExe
navExe = CaminhoNavegador("msedge.exe")
If navExe = "" Then navExe = CaminhoNavegador("chrome.exe")
If navExe <> "" Then
    sh.Run """" & navExe & """ --app=""" & chatUrl & """ --window-size=460,780 " & _
           "--user-data-dir=""" & base & "\.appprofile"" --no-first-run --no-default-browser-check", 1, False
Else
    sh.Run chatUrl, 1, False
End If

' ---------- funcoes ----------
Function PortaNoAr(porta)
    PortaNoAr = False
    On Error Resume Next
    Set http = CreateObject("MSXML2.XMLHTTP")
    http.open "GET", "http://127.0.0.1:" & porta & "/health", False
    http.send
    If Err.Number = 0 Then
        If http.status = 200 Then PortaNoAr = True
    End If
    On Error GoTo 0
End Function

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
