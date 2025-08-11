#!/bin/bash

# Exit on error and show commands
set -ex

# Check if running as root
if [ "$(id -u)" -ne 0 ]; then
  echo "This script must be run as root" >&2
  exit 1
fi

# Install dependencies
apt-get update
apt-get install -y bison build-essential ca-certificates curl dh-autoreconf doxygen \
  flex gawk git iputils-ping libcurl4-gnutls-dev libexpat1-dev libgeoip-dev liblmdb-dev \
  libpcre3-dev libssl-dev libtool libxml2 libxml2-dev libyajl-dev locales \
  lua5.3-dev pkg-config wget zlib1g-dev libgd-dev libpcre2-dev libperl-dev libxslt1-dev

# Clone and build ModSecurity
cd /opt
[ -d "ModSecurity" ] || git clone https://github.com/SpiderLabs/ModSecurity
cd ModSecurity
git submodule init
git submodule update
./build.sh
./configure
make
make install

# Get Nginx version
NGINX_VERSION=$(nginx -v 2>&1 | grep -oP '\/\K[0-9]+\.[0-9]+\.[0-9]+')
echo "Detected Nginx version: $NGINX_VERSION"

# Clone connector and download matching Nginx source
cd /opt
[ -d "ModSecurity-nginx" ] || git clone --depth 1 https://github.com/SpiderLabs/ModSecurity-nginx.git
[ -f "nginx-${NGINX_VERSION}.tar.gz" ] || wget http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz
tar -xvzf nginx-${NGINX_VERSION}.tar.gz

# Build dynamic module
cd nginx-${NGINX_VERSION}
NGINX_CONFIG_ARGS=$(nginx -V 2>&1 | grep "configure arguments" | sed 's/.*configure arguments://')
eval set -- $NGINX_CONFIG_ARGS --add-dynamic-module=../ModSecurity-nginx
./configure "$@"
make modules

# Install module
mkdir -p /etc/nginx/modules
cp objs/ngx_http_modsecurity_module.so /etc/nginx/modules/

# Enable module in nginx.conf
if ! grep -q "ngx_http_modsecurity_module.so" /etc/nginx/nginx.conf; then
  sed -i '/pid \/run\/nginx.pid;/a load_module \/etc\/nginx\/modules\/ngx_http_modsecurity_module.so;' /etc/nginx/nginx.conf
fi

# Install OWASP CRS
rm -rf /usr/local/modsecurity-crs
git clone https://github.com/coreruleset/coreruleset /usr/local/modsecurity-crs
cd /usr/local/modsecurity-crs
mv crs-setup.conf.example crs-setup.conf
mv rules/REQUEST-900-EXCLUSION-RULES-BEFORE-CRS.conf.example rules/REQUEST-900-EXCLUSION-RULES-BEFORE-CRS.conf

# Configure ModSecurity
mkdir -p /etc/nginx/modsec
cp /opt/ModSecurity/unicode.mapping /etc/nginx/modsec/
cp /opt/ModSecurity/modsecurity.conf-recommended /etc/nginx/modsec/modsecurity.conf

# Enable rule engine
sed -i 's/SecRuleEngine .*/SecRuleEngine On/' /etc/nginx/modsec/modsecurity.conf

# Create main config
cat <<EOF > /etc/nginx/modsec/main.conf
Include /etc/nginx/modsec/modsecurity.conf
Include /usr/local/modsecurity-crs/crs-setup.conf
Include /usr/local/modsecurity-crs/rules/*.conf
EOF

# Enable ModSecurity in default site
if [ -f /etc/nginx/sites-available/default ]; then
  if ! grep -q "modsecurity on" /etc/nginx/sites-available/default; then
    sed -i '/server_name _;/a \\tmodsecurity on;\n\tmodsecurity_rules_file /etc/nginx/modsec/main.conf;' /etc/nginx/sites-available/default
  fi
fi

# Test configuration before restart
nginx -t

# Restart Nginx
systemctl restart nginx

echo "ModSecurity installation complete!"
echo "Test with: curl http://<server-ip>/index.html?exec=/bin/bash"
