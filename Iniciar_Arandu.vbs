' ============================================================
'  Arandu - Iniciar (Arandu Nano 1.1 por padrao)
'  Sem menu: garante o modelo Nano 1.1 em modelo.txt e abre a IA.
'  So reinicia o servidor se a versao estiver diferente (poupa tempo e RAM).
'  (Para trocar de modelo manualmente, use os .bat Usar_Nano_1.0 / etc.)
' ============================================================
Option Explicit
Dim fso, sh, base, modeloArq, atual, cfgFile, ts
Set fso = CreateObject("Scripting.FileSystemObject")
Set sh  = CreateObject("WScript.Shell")
base = fso.GetParentFolderName(WScript.ScriptFullName)
cfgFile = base & "\modelo.txt"

' Modelo PADRAO: Arandu Nano 1.1 (Qwen3-1.7B)
modeloArq = "Qwen_Qwen3-1.7B-Q4_K_M.gguf"

atual = ""
If fso.FileExists(cfgFile) Then atual = Trim(fso.OpenTextFile(cfgFile, 1).ReadLine())

If Not fso.FileExists(base & "\" & modeloArq) Then
  MsgBox "Modelo nao encontrado:" & vbCrLf & modeloArq & vbCrLf & vbCrLf & _
         "Baixe o .gguf e coloque na pasta Arandu-nano.", vbExclamation, "Arandu"
  WScript.Quit
End If

' Se modelo.txt estiver diferente, ajusta para o 1.1 e reinicia o servidor.
If LCase(modeloArq) <> LCase(atual) Then
  Set ts = fso.OpenTextFile(cfgFile, 2, True)
  ts.WriteLine modeloArq
  ts.Close
  sh.Run "taskkill /IM llamafile.exe /F", 0, True
  WScript.Sleep 1500
End If

' Abre a IA (sobe o servidor oculto + ajudante de voz/saude + navegador padrao).
sh.Run "wscript.exe """ & base & "\IA_Portatil.vbs""", 0, False
