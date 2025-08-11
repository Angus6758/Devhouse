# ModSecurity + Nginx Installation Guide

## 📌 Overview
**ModSecurity** is an open-source **Web Application Firewall (WAF)** that helps protect your web applications from a wide range of attacks, including:

- SQL Injection (SQLi)
- Cross-Site Scripting (XSS)
- Local File Inclusion (LFI)
- Remote Code Execution (RCE)
- And other OWASP Top 10 vulnerabilities

Originally, ModSecurity was **developed for the Apache HTTP Server** in 2002 by Ivan Ristić.  
Later, it was rewritten as **libmodsecurity (ModSecurity v3)**, making it possible to integrate with **other web servers** such as **Nginx** and **IIS**.

This repository provides **two ways** to install and configure ModSecurity with Nginx:
1. **Manual Installation** — follow the step-by-step instructions in `manual.md`.
2. **Automated Installation** — run the included shell script to install ModSecurity with a single command.

---

## ⚙️ Requirements
- Ubuntu 20.04 / 22.04 or compatible Debian-based system
- Nginx installed and running
- Root or `sudo` privileges
- Internet access (for downloading source code and dependencies)

---

## 📂 Contents
- `manual.md` — Detailed manual installation guide  
- `install_modsecurity.sh` — Automated installation script  

---

## 🚀 Quick Installation (Automated)
If you want to install ModSecurity quickly, you can run the provided script.

**1. Clone this repository:**
```bash
git clone https://github.com/your-repo/modsecurity-nginx-setup.git
cd modsecurity-nginx-setup
```
**2. Make the script executable:**
```bash
chmod +x modsecurity.sh
```
**3. Run the script as root (or with sudo):**
```bash
sudo ./modsecurity.sh
```
The script will:
- Install all required dependencies
- Build and install libmodsecurity
- Build and install the ModSecurity-Nginx connector
- Download your exact Nginx source and compile the dynamic module
- Set up the OWASP Core Rule Set (CRS)  
- Enable ModSecurity in the default Nginx configuration

---

📖 Manual Installation
If you prefer to understand each step and customize the installation, follow:
```bash
cat manual.md
```
This guide explains every command and lets you configure ModSecurity manually.
---
🛠 Configuration Files
- Main ModSecurity config: /etc/nginx/modsec/modsecurity.conf
- Unicode mapping file: /etc/nginx/modsec/unicode.mapping
- Custom rules file: /etc/nginx/modsec/main.conf
- OWASP CRS: /usr/local/modsecurity-crs
---
🔍 Testing the WAF
Once installed, you can test ModSecurity by sending a malicious request:
```bash
curl http://<SERVER-IP>/index.html?exec=/bin/bash
```
If working correctly, Nginx should return:

**403 Forbidden**
---

⚠️ Notes & Warnings
- Always test ModSecurity in DetectionOnly mode before switching to On in production.
- Some rules may cause false positives and block legitimate requests.
- You can disable specific rules by editing the CRS configuration.
- Compiling modules for Nginx requires the exact version of Nginx source code.
---

📜 License
ModSecurity is released under the Apache License 2.0.
OWASP CRS is released under the Apache License 2.0.
---

**"A locked door is better than a burglar alarm."**
