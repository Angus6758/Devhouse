## Apache Security

See first of all you need to create a promising .htaccess file and apache conf file.

Also install apache-ultis by:
```bash
sudo apt install apache2-utils
```

Then:
```bash
sudo htpasswd -c /etc/apache2/.htpasswd myuser
```
What it does is it creates a password while you access a particular page in the .htaccess file and you could only access that by providing the user and password you store in the .htpasswd file.

And Also you should Use `Modsecurity` on top of the apache to filter out the traffic.
