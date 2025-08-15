## Nginx Security

First of all in order to remove the nginx version and os off your system when not found page comes, then do:
```bash
sudo nano /etc/ngninx/nginx.conf
```
In this file disable:
```bash
server_tokens off;
```
Also add these line:
```bash
proxy_hide_header X-Powered-By;
add_header X-Frame-Options SAMEORIGIN;
```
### 1. Hiding the `X-Powered-By` Header
```nginx
proxy_hide_header X-Powered-By;
```
The `proxy_hide_header` directive removes the **X-Powered-By header** from server responses.
This helps prevent attackers from knowing which language or framework powers your site.
Example:
Without `proxy_hide_header X-Powered-By`;
```bash
HTTP/1.1 200 OK
Content-Type: text/html
X-Powered-By: PHP/8.2.10
Server: Apache/2.4.57 (Ubuntu)
```

With `proxy_hide_header X-Powered-By`;
```bash
HTTP/1.1 200 OK
Content-Type: text/html
Server: Apache/2.4.57 (Ubuntu)
```

### 2. Preventing Clickjacking

```bash
add_header X-Frame-Options SAMEORIGIN;
```
The `X-Frame-Options: SAMEORIGIN` header prevents your site from being embedded in an `<iframe>`
on another domain, protecting against clickjacking attacks.

✅ Allowed: Pages on the same domain.
❌ Blocked: Pages from other domains.

---

Also Add the `ModSecurity` to nginx to filter out the traffic.

---






