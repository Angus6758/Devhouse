## SSH Sesstings

Whenever u create a new Server then must create a separate user for login (e.g Dev, Ops).
```
useradd -m -s /bin/bash {user}
```
-m: For Home Dir
-s: For defining Shell

Then set a password for that user:
```
passwd {user}
```

Then edit:

```
sudo vim /etc/ssh/sshd_config
```

Here change:

```
PermitRootLogin no
```

It will stop to login As root User via SSH.
Then:

```
sudo systemctl restart ssh
```

 Now in your local machine in the terminal write to generate a ssh key

```
ssh-keygen
```

Then if your server is password based write the following command in your local terminal and enter password for that user:

```
ssh-copy-id {user}@ip-addr
```

If you are using the SSH key based server then On your Machine:

```
cat ~/.ssh/id_rsa.pub
```

Copy the whole line, then on the remote server:

```
echo "PASTE_KEY_HERE" >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
```

On the remote server:

```
sudo vim /etc/ssh/sshd_config
```

Make sure you have:

```
PubkeyAuthentication yes
AuthorizedKeysFile .ssh/authorized_keys
```

Also disable the password based login:

```
PasswordAuhentication no
```

Then restart SSH:

```
sudo systemctl restart ssh
```

Now in your Local Machine try:

```
ssh {user}@ip-addr
```
if you are able to login then you just have to share your id_rsa (private-key) to anyone you want to give access to login and you have disables the password based login completely.


---
