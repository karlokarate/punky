@echo off
REM === Windows Wrapper für codex_dev.sh ===

REM Aktuelles Verzeichnis merken
setlocal
cd /d %~dp0

REM Bash-Skript ausführen (erfordert Git Bash, WSL oder bash.exe im PATH)
echo Starte Codex-Dev Setup...
bash codex_dev.sh

pause
