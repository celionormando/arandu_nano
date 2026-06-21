' ============================================================
'  Arandu - Iniciar com escolha de VERSAO
'  Mostra um menu, grava o modelo escolhido em modelo.txt e abre a IA.
'  So reinicia o servidor se a versao mudar (economiza tempo e RAM).
' ============================================================
Option Explicit
Dim fso, sh, base, escolha, modeloArq, atual, cfgFile, ts
Set fso = CreateObject("Scripting.FileSystemObject")
Set sh  = CreateObject("WScript.Shell")
base = fso.GetParentFolderName(WScript.ScriptFullName)
cfgFile = base & "\modelo.txt"

atual = ""
If fso.FileExists(cfgFile) Then atual = Trim(fso.OpenTextFile(cfgFile, 1).ReadLine())

escolha = InputBox( _
  "Escolha a versao do Arandu:" & vbCrLf & vbCrLf & _
  "1 = Arandu Nano 1.1  (melhor qualidade) [padrao]" & vbCrLf & _
  "2 = Arandu Nano 1.0  (mais rapido e leve)" & vbCrLf & _
  "3 = Llama 3B  (base, mais qualidade, mais lento)" & vbCrLf & vbCrLf & _
  "Digite o numero e clique OK:", _
  "Arandu - Escolher versao", "1")

If escolha = "" Then WScript.Quit

Select Case Trim(escolha)
  Case "1" : modeloArq = "Qwen_Qwen3-1.7B-Q4_K_M.gguf"
  Case "2" : modeloArq = "arandu-nano-1.0-Q4_K_M.gguf"
  Case "3" : modeloArq = "Llama-3.2-3B-Instruct-Q4_K_M.gguf"
  Case Else : modeloArq = "Qwen_Qwen3-1.7B-Q4_K_M.gguf"
End Select

If Not fso.FileExists(base & "\" & modeloArq) Then
  MsgBox "Modelo nao encontrado:" & vbCrLf & modeloArq & vbCrLf & vbCrLf & _
         "Baixe o .gguf e coloque na pasta Arandu-nano.", vbExclamation, "Arandu"
  WScript.Quit
End If

If LCase(modeloArq) <> LCase(atual) Then
  Set ts = fso.OpenTextFile(cfgFile, 2, True)
  ts.WriteLine modeloArq
  ts.Close
  sh.Run "taskkill /IM llamafile.exe /F", 0, True
  WScript.Sleep 1500
End If

sh.Run "wscript.exe """ & base & "\IA_Portatil.vbs""", 0, False
