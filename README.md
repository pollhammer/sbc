<div align="center">

<img src="./Logo.svg" width="650" alt="ASCII Logo"> <br>  
# Secure Boot Checker <br> v1.2 - Dashboard Edition
**Advanced UEFI certificate auditing and mitigation console for Windows** <br>
by Manuel Pollhammer (2026)
</div>

---

## 🚀 What is SBC?
**SBC** is an terminal-based security diagnostics and remediation dashboard for Windows systems. It is designed to audit, validate, and enforce critical UEFI Secure Boot certificate migrations (Legacy 2011 vs. Modern 2023 Keys) and DBX revocation updates.

### 🌟 New in v1.2: Cyber Dashboard
- **📊 Real-Time Auditing:** Instant identification of global Secure Boot status and legacy restrictions.
- **🛡️ Certificate Scanning:** Deep analysis of the `db` and `KEK` firmware structures for expiring authorities.
- **⚡ Hardware Enforcement:** Force DBX revocation updates directly into NVRAM via native CIM/WMI triggers.
- **🎨 ANSI Interface:** High-contrast, boxed Unicode terminal design for pristine corporate scannability.

### ✨ Core Highlights
- **UNC Safe Pipeline:** Maps temporary drives and auto-elevates UAC to run safely from network shares.
- **Direct Remediation:** Cycle system updates or execute native Microsoft scripts from a single hub.
- **Zero Overhead:** No heavy frameworks required—runs instantly and completely out of the box.

---

## 🛠️ Quick Start
1. Clone or download the repository ensuring `start.bat` and `sbc.ps1` remain in the same folder.
2. Right-click `start.bat` and select **"Run as Administrator"** (required to access live UEFI registers).
3. Use keys **[1-6]** for instant tools or navigating back to the main dashboard framework.

---

## ⚙️ Under the Hood
SBC utilizes a secure split-architecture to bypass command-line execution and environment limitations:
* **`start.bat` (Launcher):** Network-safe launcher script (handles UNC paths and forces UAC Admin elevation).
* **`sbc.ps1` (Engine):** The main PowerShell core engine featuring the modern cyber dashboard menu.

---

## 📸 Screenshots
<p align="center">
  <img src="./Screenshots/sbc_scr01.png" alt="SMT Dashboard" width="800">
  <br>
  <i>Main Dashboard</i>
</p>

---
**Developed by Manuel Pollhammer | Release 2026**
