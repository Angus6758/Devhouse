
> This guide walks through installing and configuring HAProxy on **Ubuntu**, including logging and email alerting if backend servers fail.

---

## 🚀 Step 1: Install HAProxy

```
sudo apt update && sudo apt install -y haproxy rsyslog mailutils
```

---

## 🔒 Step 2: Enable and Configure Logging

1. Edit HAProxy config to log to syslog:
    

```
sudo nano /etc/haproxy/haproxy.cfg
```

Make sure `global` section contains:

```
global
    log /dev/log local0
    maxconn 2048
    daemon
```

Add a new rsyslog config for HAProxy:

```
echo 'local0.* /var/log/haproxy.log' | sudo tee /etc/rsyslog.d/49-haproxy.conf
```

Then restart rsyslog:

```
sudo systemctl restart rsyslog
```

---

## ⚙️ Step 3: HAProxy Config for Web + MariaDB

```
sudo nano /etc/haproxy/haproxy.cfg
```

Paste this full configuration:

```
#===========================#
#     HAProxy Full Config   #
#===========================#

#---------------------------#
#       GLOBAL SETTINGS     #
#---------------------------#
global
    log /dev/log local0 info
    log /dev/log local1 notice
    chroot /var/lib/haproxy
    stats socket /run/haproxy/admin.sock mode 660 level admin expose-fd listeners
    stats timeout 30s
    user haproxy
    group haproxy
    daemon
    maxconn 4096
    tune.ssl.default-dh-param 2048

#---------------------------#
#       DEFAULT SETTINGS    #
#---------------------------#
defaults
    log     global
    mode    http
    option  httplog
    option  dontlognull
    option  redispatch
    option  http-server-close
    option  log-separate-errors              # Separate 4xx/5xx logs
    log-format "%ci:%cp [%t] %ft %b/%s %ST %B %CC %CS %tsc %ac/%fc/%bc/%sc/%rc %sq/%bq"
    retries 3
    timeout connect 5s
    timeout client  50s
    timeout server  50s
    timeout http-request 10s
    timeout queue 1m

#---------------------------#
#       FRONTEND HTTPS      #
#---------------------------#
frontend https_front
    bind *:443 ssl crt /etc/ssl/private/haproxy.pem
    mode http
    option httpchk GET /health
    default_backend web_backends


#---------------------------#
#       FRONTEND HTTP       #
#---------------------------#
frontend http_front
    bind *:80
    redirect scheme https code 301 if !{ ssl_fc }

#---------------------------#
#       BACKEND WEB         #
#---------------------------#
backend web_backends
    balance roundrobin
    option httpchk GET /health
    http-check expect status 200
    server web1 192.168.1.101:80 check
    server web2 192.168.1.102:80 check


#---------------------------#
#       BACKEND DB          #
#---------------------------#
backend db_backends
    mode tcp
    balance roundrobin
    option mysql-check user haproxy_check_user
    server db1 192.168.1.201:3306 check inter 5s rise 2 fall 3
    server db2 192.168.1.202:3306 check inter 5s rise 2 fall 3

#---------------------------#
#       STATS PAGE          #
#---------------------------#
listen stats
    bind 192.168.1.100:8404
    mode http
    stats enable
    stats uri /haproxy_stats
    stats realm Haproxy\ Statistics
    stats auth admin:strongpassword
    stats refresh 10s
    acl allowed_stats src 192.168.1.0/24
    http-request deny if !allowed_stats

```

Setup MySQL check user:

```
CREATE USER 'haproxy_check'@'%' IDENTIFIED BY 'password';
GRANT USAGE ON *.* TO 'haproxy_check'@'%';
```
---

## 🔎 Step 4: Validate and Start HAProxy

```
sudo haproxy -c -f /etc/haproxy/haproxy.cfg
sudo systemctl enable haproxy
sudo systemctl restart haproxy
```

---

## 📢 Step 5: Setup Email Alerts for Backend Failures

Install `swatch`:

```
sudo apt install swatch
```

Create swatch config:

```
echo 'watchfor /Server.*DOWN/\n  mail addresses=admin@example.com,subject=HAProxy Alert: Backend Down' | sudo tee /etc/swatchrc
```

Run swatch as a background process:

```
sudo swatch --config-file=/etc/swatchrc --tail-file=/var/log/haproxy.log --daemon
```

Test logging:

```
echo "Aug 1 13:00:00 localhost haproxy[12345]: Server web1 is DOWN" | sudo tee -a /var/log/haproxy.log
```

You should receive an email alert!

---

## 🔍 Verify All Services

```
sudo systemctl status haproxy
sudo systemctl status rsyslog
sudo ss -tulnp | grep haproxy
```

---

Access stats at `http://<ip>:8404/haproxy_stats`
