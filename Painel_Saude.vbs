' ============================================================
'  Arandu - Painel de Saude do Sistema - lancador "1 clique"
'  - Sobe o AJUDANTE (PowerShell) SEM janela de console (escondido)
'  - Abre o painel no navegador padrao do sistema
'  - O ajudante so LE dados do PC (RAM, disco, arquivos limpaveis);
'    NUNCA apaga nada.
'  Obs.: a "analise pela IA" precisa do Arandu normal rodando (porta 8080).
' ============================================================
Option Explicit
Dim fso, sh, base, ps1, painelUrl, cmd, i, ok, http

Set fso = CreateObject("Scripting.FileSystemObject")
Set sh  = CreateObject("WScript.Shell")

' pasta onde este .vbs esta (independe da letra do drive)
base = fso.GetParentFolderName(WScript.ScriptFullName)
ps1  = base & "\ferramentas\saude_sistema.ps1"

If Not fso.FileExists(ps1) Then
    MsgBox "Nao encontrei o ajudante:" & vbCrLf & ps1, vbExclamation, "Arandu - Saude"
    WScript.Quit
End If

' se o ajudante ja estiver no ar, so abre o painel
If Not AjudanteNoAr() Then
    cmd = "powershell -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File """ & ps1 & """"
    sh.CurrentDirectory = base
    ' 0 = janela oculta (sem console preto); False = nao espera
    sh.Run cmd, 0, False

    ' espera o ajudante subir (ate ~15s), checando a porta
    ok = False
    For i = 1 To 15
        WScript.Sleep 1000
        If AjudanteNoAr() Then ok = True : Exit For
    Next
    If Not ok Then
        MsgBox "Nao consegui iniciar o ajudante de saude." & vbCrLf & _
               "Verifique se o PowerShell esta liberado.", vbExclamation, "Arandu - Saude"
        WScript.Quit
    End If
End If

' URL local do painel (modo arquivo)
painelUrl = "file:///" & Replace(base, "\", "/") & "/Painel_Saude.html"

' abre no navegador padrao configurado no sistema
sh.Run painelUrl, 1, False

' ---------- funcoes ----------
Function AjudanteNoAr()
    AjudanteNoAr = False
    On Error Resume Next
    Set http = CreateObject("MSXML2.XMLHTTP")
    http.open "GET", "http://127.0.0.1:8099/ping", False
    http.send
    If Err.Number = 0 Then
        If http.status = 200 Then AjudanteNoAr = True
    End If
    On Error GoTo 0
End Function
