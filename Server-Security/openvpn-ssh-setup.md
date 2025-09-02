# 🔒 Secure SSH Access with OpenVPN

**OpenVPN** is an open-source VPN solution that allows you to create secure, encrypted tunnels between your client and server. By using OpenVPN and restricting SSH to listen only on the VPN interface, you ensure that only users connected via VPN can access your server — blocking all direct SSH attempts from the public internet.

## 🚀 Step 1: Download and Install OpenVPN on Server

Download the OpenVPN installation script:

```
wget https://git.io/vpn -O openvpn-install.sh
```

Make it executable:

```
chmod +x openvpn-install.sh
```

Run the script:

```
sudo ./openvpn-install.sh
```

This will generate a client `.ovpn` configuration file.

## 📄 Step 2: Update Client Configuration

Open the `.ovpn` file generated and add the following lines under the `client` section:

```
route-nopull 
route 10.8.0.0 255.255.255.0
```

This ensures only VPN traffic destined for the internal network (`10.8.0.0/24`) is routed through OpenVPN.

## 🏃 Step 3: Connect to VPN

### 🔹 Option A: If you have another server and want to connect via CLI

Run OpenVPN directly with your `.ovpn` file:

```
sudo openvpn --config /etc/openvpn/client.ovpn --daemon
```
This will connect in the background.

### 🔹 Option B: If you want to install OpenVPN locally (Windows, macOS, Linux)

Download the official OpenVPN client from:

👉 https://openvpn.net/community-downloads/

Then import the `.ovpn` file into the OpenVPN client application and connect.

## 🔧 Step 4: Restrict SSH to VPN

Edit SSH configuration:

```
sudo nano /etc/ssh/sshd_config
```

Add this line:

```
ListenAddress 10.8.0.1
```
Save and exit.

Restart SSH:

```
sudo systemctl stop ssh.socket
sudo systemctl disable ssh.socket
sudo systemctl mask ssh.socket
sudo systemctl restart ssh
```

## ✅ Step 5: Verify SSH Binding

Run:
```
sudo ss -tlnp | grep sshd
```

Expected result:

```
10.8.0.1:22
127.0.0.1:22   (optional)
```

- `ssh ubuntu@<PUBLIC-IP>` → ❌ **Should fail**
- `ssh ubuntu@10.8.0.1` (over VPN) → ✅ **Should work**

## 🛠 Step 6: Fix SSH Key Conflicts (if needed)

If connection issues occur after changes, reset the host key entry:

```
ssh-keygen -R 10.8.0.1
```

## 🎯 Summary

✅ Encrypted VPN tunnel  
✅ SSH restricted to VPN users only  
✅ Protection from brute-force & public SSH attacks

Your server is now **much more secure**. 🔐
