:: ============================================================
:: SBC v1.1 – Network & UNC Secure Starter Script
:: GitHub: https://github.com/pollhammer/sbc
:: Author: Manuel Pollhammer
:: ============================================================

@echo off
setlocal EnableDelayedExpansion

:: Self-Elevation: Force UAC prompt to acquire Administrator privileges
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [*] Requesting Administrator privileges...
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

:: Handle network path (UNC): Temporarily mounts a free drive letter if run from a share
pushd "%~dp0"

:: Name of your PowerShell script file (Ensure it matches exactly)
set "PS_SCRIPT=sbc.ps1"

:: Execute the main PowerShell application
if exist "!PS_SCRIPT!" (
    powershell -NoProfile -ExecutionPolicy Bypass -File "!PS_SCRIPT!"
) else (
    color 0C
    echo =======================================================================
    echo  [-] ERROR: The target file "!PS_SCRIPT!" could not be found.
    echo  Current lookup directory: %CD%
    echo =======================================================================
    pause
)

:: Release the temporary network drive resource mapping
popd
