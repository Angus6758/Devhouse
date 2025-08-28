# CSF (ConfigServer Firewall) — Quick Guide & Reference

> A compact, practical guide to installing, configuring, and managing CSF (ConfigServer Security & Firewall) on Linux servers. Includes config examples, common commands, and troubleshooting tips.


## Table of contents

1. What is CSF?
2. Supported systems & prerequisites
3. Install & initial setup
4. Important file paths
5. Basic commands
6. Key configuration options (with recommended values)
7. Common tasks & examples
8. Managing blocks, whitelist & temporary allows
9. LFD (Login Failure Daemon) overview & key settings
10. Integration notes (cPanel, Plesk, firewalld, SELinux)
11. Troubleshooting & logs
12. Security hardening tips
13. Example `csf.conf` snippets
14. Quick reference cheat-sheet

---

## 1. What is CSF?

CSF (ConfigServer Firewall) is a Stateful Packet Inspection (SPI) firewall, a security suite for Linux servers that provides an easy-to-manage interface for iptables/nftables and includes LFD (Login Failure Daemon) for intrusion detection (failed login tracking, process tracking, etc.). It's popular on web hosting control panels (cPanel, DirectAdmin) and standalone servers.

## 2. Supported systems & prerequisites

- Works on most Linux distributions (Debian/Ubuntu, CentOS/RHEL, Rocky, AlmaLinux, Ubuntu LTS). 
- Requires root access.
- If running `firewalld` or another firewall manager, stop/disable it before using CSF (or follow integration steps).
- Perl is required (CSF is a Perl script suite).

## 3. Install & initial setup

```bash
# Get latest CSF
cd /usr/src
rm -rf csf
wget https://download.configserver.com/csf.tgz
tar -xzf csf.tgz
cd csf
sh install.sh

# After install, test for required features
perl /usr/local/csf/bin/csftest.pl
```

If `csftest.pl` reports missing features, follow its suggestions (often related to iptables/nft support).

Enable CSF (after you edit config):

```bash
# Edit /etc/csf/csf.conf first
csf -r      # restart (apply) after changes
```

> **Important:** Do **not** enable CSF (`csf -e`) until you've allowed SSH (or you may lock yourself out). Confirm SSH port is in `TCP_IN` and `TCP_OUT` or add your IP to `csf.allow` first.

## 4. Important file paths

- Main config: `/etc/csf/csf.conf`
- Allow list: `/etc/csf/csf.allow`
- Deny list: `/etc/csf/csf.deny`
- Temporary allow: `/etc/csf/csf.tempdeny`
- LFD config: same `csf.conf` (LFD parameters) and `/var/log/lfd.log` for logs
- CSF binary scripts: `/usr/sbin/csf` and `/usr/sbin/lfd` (or `/usr/local/csf/bin/` depending on install)

## 5. Basic commands

```bash
# Restart / reload CSF
csf -r    # restart (reload configuration)
csf -s    # stop
csf -e    # enable (start) — only after confirming rules
csf -x    # disable (stop) and flush iptables rules

# Check status & version
csf -v
csf -l    # list all blocked IPs (combined with lfd)

# Block/unblock IPs
csf -d 1.2.3.4        # permanent deny
csf -dr 1.2.3.4       # remove deny
csf -td 1.2.3.4 3600  # temp deny for 3600 seconds
csf -a 1.2.3.4        # add allow
csf -ar 1.2.3.4       # remove allow

# List firewall rules (iptables/nft)
iptables -L -n -v
nft list ruleset

# View LFD status/logs
tail -n 100 /var/log/lfd.log
```
## 6. Key configuration options (with recommended values)

Open `/etc/csf/csf.conf` and review/change the following:

- `TESTING = "0"`  — set to `0` in production (when ready); `1` = testing mode (don't actually block).

- `RESTRICT_SYSLOG = "0"` — usually `0` unless restricting syslog writes.

- `TCP_IN` — allowed incoming TCP ports. Example for web server + ssh:
  ```
  TCP_IN = "22,80,443,3306"
  ```
  If SSH uses a custom port (e.g., 2222) include it here.

- `TCP_OUT` — allowed outgoing TCP ports. Keep minimal, e.g., `20,21,22,25,53,80,443` if server needs outgoing email/DNS.

- `UDP_IN`, `UDP_OUT` — common UDP like `53` for DNS; otherwise leave blank.

- `ICMP_IN` / `ICMP_OUT` — control ping; `"1"` usually allows a basic set.

- `LF_TRIGGER` and `LF_SSHD` — LFD thresholds. Example:
  ```
  LF_TRIGGER = "30"
  LF_SSHD = "5"
  LF_SSHD_PERM = "1"
  ```
  (These control when LFD blocks IPs after failed logins; tune for your environment.)

- `LF_DISTATTACK = "1"` — detect distributed attacks.

- `LF_INCOMING` — block too many incoming connections from same IP. (Enable and tune if you're experiencing connection floods.)

- `PORTFLOOD` — protect services from port flooding: `PORTFLOOD = "22;tcp;5;300"` (example: >5 connections in 300s triggers).

- `CONNLIMIT` / `CONNLIMIT_RATE` — connection rate limiting.

- `SMTP_BLOCK` / `SMTP_ALLOWLOCAL` — control outgoing SMTP; useful to prevent spam from compromised processes.

- `CT_LIMIT` — connection tracking limits; be careful on low-memory systems.

**Always back up `csf.conf` before editing:**

```bash
cp /etc/csf/csf.conf /etc/csf/csf.conf.bak
```

## 7. Common tasks & examples

### Allow your IP (safe way before enabling CSF)
```bash
# Add your IP to allow and restart
echo "x.x.x.x" >> /etc/csf/csf.allow
csf -r
```

### Allow a custom SSH port (e.g., 2222)

Edit `/etc/csf/csf.conf`: add `2222` to `TCP_IN` and `TCP_OUT` if needed, then `csf -r`.

### Allow a range (CIDR)

In `/etc/csf/csf.allow` add `203.0.113.0/24` or use `csf -a 203.0.113.0/24`.

### Temporarily block an IP

```bash
csf -td 198.51.100.2 3600   # block for 1 hour
```

### Permanently deny

```bash
csf -d 198.51.100.2
```

### Whitelist a hostname

Add `# NAME` comments are allowed. Example entry:

```
203.0.113.45 # office static IP - john
```

### Rate limit SSH brute-force attempts (example)

In `csf.conf`:
```
PORTFLOOD = "2222;tcp;5;300"
LF_SSHD = "5"
LF_SSHD_PERM = "1"
```

## 8. Managing blocks, whitelist & temporary allows

- `/etc/csf/csf.allow` — trusted IPs/CIDRs or hostnames. Use for admin IPs.

- `/etc/csf/csf.deny` — permanently blocked IPs (CSF will add to iptables).

- `/etc/csf/csf.tempdeny` — temporary denies.

- `csf -g <ip>` — search for IP in logs and show why it was blocked.

- `csf -tr <ip>` — trace route style diagnostic for why the IP was blocked.

**Note:** CSF will automatically remove expired temp denies when `lfd` runs its cleanup.

## 9. LFD (Login Failure Daemon)

LFD monitors authentication failures, suspicious processes, file changes, and more. Key settings in `csf.conf` include:

- `LF_SSHD` — failed SSH logins before block

- `LF_SSHD_PERM` — whether SSH blocks are permanent

- `LF_APACHE` / `LF_POP3D` / `LF_IMAPD` — limits for web/email services

- `LF_DISTATTACK` — detect distributed attacks

- `LF_SCAN` — detect scanners

- `LF_EMAIL_ALERT` — receive email alerts on blocks

LFD also has features like process tracking (`PT_*` settings), login alerts, and watching suspicious file changes.

## 10. Integration notes

- **cPanel/WHM:** CSF integrates easily; its UI in WHM is under "ConfigServer Security & Firewall".

- **Plesk/DirectAdmin:** supported — follow panel-specific docs.

- **firewalld / ufw:** stop/disable them before enabling CSF or follow advanced integration steps to avoid rule conflicts.

- **SELinux:** CSF doesn't require SELinux changes normally, but if SELinux is enforcing and you run into permission issues, inspect `/var/log/audit/audit.log`.

## 11. Troubleshooting & logs

- CSF/LFD logs: `/var/log/lfd.log` and `/var/log/messages` or `/var/log/syslog` depending on distro.

- Use `csf -g <ip>` to get detailed block reason.

- If you get locked out, use console access (VNC/VM console) to edit `/etc/csf/csf.allow` and add your IP, then `csf -r`.

- If CSF blocks all traffic incorrectly: `csf -x` to disable and flush rules.

## 12. Security hardening tips

- Keep `TESTING = 0` in production.

- Use `csf.allow` for admin IPs and avoid putting all admin IPs in `TCP_IN` (only ports).

- Restrict outgoing SMTP to only necessary services or use `SMTP_BLOCK` to prevent abuse.

- Use `LF_*` settings to detect brute-force attempts; tune thresholds to avoid false positives for legitimate users.

- Regularly review `/etc/csf/csf.deny` and `/etc/csf/csf.allow`.

- Combine CSF with fail2ban or rely on LFD — don’t run both with overlapping rules unless you know how to coordinate them.

## 13. Example `csf.conf` snippets (safe, production-friendly)

**Minimal web server example**

```
TESTING = "0"
TCP_IN = "22,80,443"
TCP_OUT = "20,21,22,25,53,80,443"
UDP_IN = ""
UDP_OUT = "53"
ICMP_IN = "1"
PORTFLOOD = "22;tcp;6;300"
LF_SSHD = "5"
LF_SSHD_PERM = "0"
LF_TRIGGER = "30"
LF_DISTATTACK = "1"
```

**Tighter security (if admin IPs are static)**

```
TESTING = "0"
TCP_IN = "80,443"
# SSH only allowed via csf.allow entries
TCP_OUT = "20,21,22,25,53,80,443"
LF_SSHD = "3"
LF_SSHD_PERM = "1"
SMTP_BLOCK = "1"
```

## 14. Quick reference cheat-sheet

- Install: `sh install.sh` in CSF source dir

- Test: `perl /usr/local/csf/bin/csftest.pl`

- Start/enable: `csf -e`  (only after adding admin IPs)

- Restart: `csf -r`

- Disable/flush: `csf -x`

- Permanent block: `csf -d 1.2.3.4`

- Temporary block: `csf -td 1.2.3.4 3600`

- Allow IP: `csf -a 1.2.3.4`

- View lfd log: `tail -f /var/log/lfd.log`

---

## Final notes

- Always keep a console/VNC out-of-band access method available (cloud console, KVM) when testing firewall rules.

- Back up `csf.conf` before major changes.

- Tune LFD thresholds to your server's usage patterns to avoid false positives.
