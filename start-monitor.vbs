Set objShell = CreateObject("WScript.Shell")
Set objFSO = CreateObject("Scripting.FileSystemObject")
scriptDir = objFSO.GetParentFolderName(WScript.ScriptFullName)
psCmd = "pwsh.exe -ExecutionPolicy Bypass -File """ & scriptDir & "\github-monitor.ps1"""

On Error Resume Next
objShell.Run psCmd, 0, False
If Err.Number <> 0 Then
    psCmd = """" & objShell.ExpandEnvironmentStrings("%ProgramFiles%") & "\PowerShell\7\pwsh.exe"" -ExecutionPolicy Bypass -File """ & scriptDir & "\github-monitor.ps1"""
    objShell.Run psCmd, 0, False
End If
On Error Goto 0
