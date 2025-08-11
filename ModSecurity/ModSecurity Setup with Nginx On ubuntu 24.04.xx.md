
### Downloading & Building ModSecurity

While ModSecurity is not officially supported as a module for Nginx, a workaround exists involving the [ModSecurity-nginx connector](https://github.com/SpiderLabs/ModSecurity-nginx). The ModSecurity-nginx connector is the connection point between Nginx and libmodsecurity (ModSecurity v3). Said another way, the ModSecurity-nginx connector provides a communication channel between Nginx and libmodsecurity.

The ModSecurity-nginx connector takes the form of an Nginx module that provides a layer of communication between Nginx and ModSecurity.

To begin the installation process, follow the steps outlined below:

1. Install all the dependencies required for the build and compilation process with the following command:
```
sudo apt-get update
sudo apt-get install bison build-essential ca-certificates curl dh-autoreconf doxygen \  
flex gawk git iputils-ping libcurl4-gnutls-dev libexpat1-dev libgeoip-dev liblmdb-dev \  
libpcre3-dev libssl-dev libtool libxml2 libxml2-dev libyajl-dev locales \  
lua5.3-dev pkg-config wget zlib1g-dev libgd-dev libpcre2-dev libperl-dev
```

2. Ensure that git is installed:
```
sudo apt install git
```

3. Clone the ModSecurity Github repository from the `/opt` directory:
```
cd /opt && sudo git clone https://github.com/SpiderLabs/ModSecurity
```

4. Change your directory to the ModSecurity directory:
```
cd ModSecurity
```

5. Run the following git commands to initialize and update the submodule:
```
sudo git submodule init
sudo git submodule update
```

6. Run the `build.sh` script:
```
sudo ./build.sh
```

7. Run the `configure` file, which is responsible for getting all the dependencies for the build process:
```
sudo ./configure
```

8. Run the `make` command to build ModSecurity:
```
sudo make
```

9. After the build process is complete, install ModSecurity by running the following command:
```
sudo make install
```

### Downloading ModSecurity-Nginx Connector

Before compiling the ModSecurity module, clone the Nginx-connector from the `/opt` directory:
```
cd /opt && sudo git clone --depth 1 https://github.com/SpiderLabs/ModSecurity-nginx.git
```

### Building the ModSecurity Module For Nginx

You can now build the ModSecurity module from a downloaded copy of your Nginx version by following the steps outlined below:

1. Enumerate the version of Nginx you have installed:

```
nginx -v
```
For example, the following output shows that Nginx version 1.14.0 is installed on the system:
```
nginx version: nginx/1.14.0 (Ubuntu)
```

In each of the following commands, replace `1.14.0` with your version of Nginx.

2.Download the exact version of Nginx running on your system into the `/opt` directory:
```
cd /opt && sudo wget http://nginx.org/download/nginx-1.14.0.tar.gz
```

3. Extract the tarball:
```
sudo tar -xvzmf nginx-1.14.0.tar.gz
```

4. Change your directory to the tarball directory you just extracted:
```
cd nginx-1.14.0
```

5. Display the configure arguments used for your version of Nginx:
```
nginx -V
```

Here is an example output for Nginx 1.14.0:
```
nginx version: nginx/1.14.0 (Ubuntu) built with OpenSSL 1.1.1 11 Sep 2018 TLS SNI support enabled configure arguments: --with-cc-opt='-g -O2 -fdebug-prefix-map=/build/nginx-GkiujU/nginx-1.14.0=. -fstack-protector-strong -Wformat -Werror=format-security -fPIC -Wdate-time -D_FORTIFY_SOURCE=2' --with-ld-opt='-Wl,-Bsymbolic-functions -Wl,-z,relro -Wl,-z,now -fPIC' --prefix=/usr/share/nginx...
```

6. To compile the Modsecurity module, copy all of the arguments following `configure arguments:` from your output of the above command and paste them in place of `<Configure Arguments>` in the following command:
```
sudo ./configure --add-dynamic-module=../ModSecurity-nginx <Configure Arguments>
```

7. Build the modules with the following command:
```
sudo make modules
```

8. Create a directory for the Modsecurity module in your system’s Nginx configuration folder:
```
sudo mkdir /etc/nginx/modules
```

9. Copy the compiled Modsecurity module into your Nginx configuration folder:
```
sudo cp objs/ngx_http_modsecurity_module.so /etc/nginx/modules
```

### Loading the ModSecurity Module in Nginx

Open the `/etc/nginx/nginx.conf` file with a text editor such a vim and add the following line:
```
load_module /etc/nginx/modules/ngx_http_modsecurity_module.so;
```

Here is an example portion of an Nginx configuration file that includes the above line:

```
File: /etc/nginx/nginx.conf
1 user www-data;
2 worker_processes auto;
3 pid /run/nginx.pid;
4 include /etc/nginx/modules-enabled/*.conf;
5 load_module /etc/nginx/modules/ngx_http_modsecurity_module.so;
```

### Setting Up OWASP-CRS

The [OWASP ModSecurity Core Rule Set (CRS)](https://github.com/coreruleset/coreruleset) is a set of generic attack detection rules for use with ModSecurity or compatible web application firewalls. The CRS aims to protect web applications from a wide range of attacks, including the OWASP Top Ten, with a minimum of false alerts. The CRS provides protection against many common attack categories, including SQL Injection, Cross Site Scripting, and Local File Inclusion.

To set up the OWASP-CRS, follow the procedures outlined below.

1. First, delete the current rule set that comes prepackaged with ModSecurity by running the following command:
```
sudo rm -rf /usr/share/modsecurity-crs
```

2. Clone the OWASP-CRS GitHub repository into the `/usr/share/modsecurity-crs` directory:
```
sudo git clone https://github.com/coreruleset/coreruleset /usr/local/modsecurity-crs
```

3. Rename the `crs-setup.conf.example` to `crs-setup.conf`:
```
sudo mv /usr/local/modsecurity-crs/crs-setup.conf.example /usr/local/modsecurity-crs/crs-setup.conf
```

4. Rename the default request exclusion rule file:
```
sudo mv /usr/local/modsecurity-crs/rules/REQUEST-900-EXCLUSION-RULES-BEFORE-CRS.conf.example /usr/local/modsecurity-crs/rules/REQUEST-900-EXCLUSION-RULES-BEFORE-CRS.conf
```

You should now have the OWASP-CRS set up and ready to be used in your Nginx configuration.

### Configuring Modsecurity

ModSecurity is a firewall and therefore requires rules to function. This section shows you how to implement the OWASP Core Rule Set. First, you must prepare the ModSecurity configuration file.

1. Start by creating a ModSecurity directory in the `/etc/nginx/` directory:

```
sudo mkdir -p /etc/nginx/modsec
```

2. Copy over the unicode mapping file and the ModSecurity configuration file from your cloned ModSecurity GitHub repository:
```
sudo cp /opt/ModSecurity/unicode.mapping /etc/nginx/modsec 
sudo cp /opt/ModSecurity/modsecurity.conf-recommended /etc/nginx/modsec
```

3. Remove the `-recommended` extension from the ModSecurity configuration filename with the following command:
```
sudo cp /etc/nginx/modsec/modsecurity.conf-recommended /etc/nginx/modsec/modsecurity.conf
```

4. With a text editor such as vim, open `/etc/nginx/modsec/modsecurity.conf` and change the value for `SecRuleEngine` to `On`:
```
File: /etc/nginx/modsec/modsecurity.conf
# -- Rule engine initialization ---------------------------------------------- # Enable ModSecurity, attaching it to every transaction. Use detection # only to start with, because that minimises the chances of post-installation # disruption. 
# 
SecRuleEngine On 
...
```

5. Create a new configuration file called `main.conf` under the `/etc/nginx/modsec` directory:
```
sudo touch /etc/nginx/modsec/main.conf
```

6. Open `/etc/nginx/modsec/main.conf` with a text editor such as vim and specify the rules and the Modsecurity configuration file for Nginx by inserting following lines:
```
Include /etc/nginx/modsec/modsecurity.conf 
Include /usr/local/modsecurity-crs/crs-setup.conf 
Include /usr/local/modsecurity-crs/rules/*.conf
```

### Configuring Nginx

Now that you have configured ModSecurity to work with Nginx, you must enable ModSecurity in your site configuration file.

1. Open the `/etc/nginx/sites-available/default` with a text editor such as vim and insert the following lines in your server block:
```
modsecurity on; 
modsecurity_rules_file /etc/nginx/modsec/main.conf;
```

Here is an example configuration file that includes the above lines:

```
File: /etc/nginx/sites-available/default


server {
		listen 80 default_server;
		listen [::]:80 default_server;
		 
		root /var/www/html; 
		
		modsecurity on;
		modsecurity_rules_file /etc/nginx/modsec/main.conf;
		index index.html index.htm index.nginx-debian.html;
		server_name _;
		location / {
			 try_files $uri $uri/ =404; 
			 } 
}
```

2. Restart the nginx service to apply the configuration:
```
sudo systemctl restart nginx
```

### Testing ModSecurity

Test ModSecurity by performing a simple local file inclusion attack by running the following command:

```
curl http://<SERVER-IP/DOMAIN>/index.html?exec=/bin/bash
```

If ModSecurity has been configured correctly and is actively blocking attacks, the following error is returned:
```
<html>
<head>
<title>403 Forbidden</title>
</head> <body bgcolor="white">
<center><h1>403 Forbidden</h1></center>
<hr><center>nginx/1.14.0 (Ubuntu)</center>
</body>
</html>
```



---
