@echo off
cd /d "%~dp0"

start "" pwsh.exe -WindowStyle Hidden -ExecutionPolicy Bypass -File "%~dp0github-monitor.ps1"
