Def:
Transfer from one server to another
(Its not bidirectional)

---
### Installation:

```
apt install rsync
```

Check:
```
command -v rsync
```

---
### Syntax:


rsync [options] source destination

### Usage:

```
rsync  -rv —dry-run dir/file username@ipaddr:/path
```

—dry-run    :  Demo run. It tries to connect to the server. And explain what it could have done.
-r                 : Recursive
-v                 : Verbose

```
rsync -rv username@ipaddr:/path /local/path
```

It copies file from the remote and copies in specified dir

```
rsync -rv  —delete username@ipaddr:/path /local/path
```

— delete : delete anything not the target that is not in the source

```
rsync -rva  —delete username@ipaddr:/path /local/path
```

a   : archive mode to keep the metadata same

```
rsync -rvaz  —delete username@ipaddr:/path /local/path
```

z   : compression (use in case so slower connection)

```
rsync -rva  —remove-source-files username@ipaddr:/path /local/path
```

—remove-source-files : Deletes the data from primary server

```
rsync -rvaP username@ipaddr:/path /local/path
```

P  : Shows Progress

---



Note:
if you are using SSH key then must add it.