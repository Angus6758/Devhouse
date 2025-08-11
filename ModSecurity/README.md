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
**2. Make the script executable:
```bash
chmod +x modsecurity.sh
```
**3. Run the script as root (or with sudo):
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

