## Sudo Settings

You can't do sudo required commands in your newly created user. In order to do so you will be needed to open the:

```
/etc/sudoers
```

But you open it with:

```
visudo
```

What this does is, it opens the same file but now if you do any syntax mistake it won't let you save the file until you correct the file.
Here under the root user you can define your other user and give it all the permissions.

Here is another way to add your username in the sudo group:

```
sudo usermod -aG sudo {user}
```
-aG: To add group

to check write:

```
groups {user}
```

Here u must see root group along without your group.

To prevent use root user within local using password, there are 2 methods

METHOD 1:

lock the root user by:

```
sudo passwd -l root
```

-l : locks the user
what it does is it adds " ! " at the beginning of the root password. You can check at:

```
sudo cat /etc/shadow
```

To unlock do:

```
sudo passwd -u root
```

METHOD 2:

You can see in the `/etc/passwd` that the users have **/bin/bash** shell and services have **/usr/sbin/nologin** shell, so we are going to check root shell by:

```
sudo chsh root
```
chsh: ch- change sh- shell

Here in the login Shell, type:

```
/usr/sbin/nologin
```

Now to change repeat the same process but now put the following in Login Shell:

```
/bin/bash
```

Or edit and change it in the file directly:

```
sudo nano /etc/passwd
```


---
