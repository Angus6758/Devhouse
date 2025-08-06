
### Type of replication:

| Type          | Description                                                                       |
| ------------- | --------------------------------------------------------------------------------- |
| Master-Slave  | One-way sync. Master handles wrtites, slave does read-only.                       |
| Master-Master | Two-way sync. Both servers can read/write (More Complex)                          |
| Synchronous   | slaves get updates immediately. Safer but slower.                                 |
| Asynchronous  | Master doesn't wait for slaves. Faster, but might loss latest data if it crashes. |

---

### Master — Salve

#### Step1: Install MariaDB (if not already)

```
sudo apt update
sudo apt install mariadb-server -y
```

#### Step2: Master: Configure MariaDB

```
sudo nano /etc/mysql/mariadb.conf.d/50-server.cnf
```
Add the following under `[mysqld]`:

```
[mysqld]
server-id=1
log_bin=/var/log/mysql/mariadb-bin.log
binlog_do_db=testdb
bind-address=0.0.0.0
```

Create the required binlog directory if not present:
```
sudo mkdir -p /var/log/mysql
sudo chown mysql:mysql /var/log/mysql
```

Restart MariaDB:
```
sudo systemctl restart mariadb
```
#### Step3: Master: Create Replication User

**Master:** **/etc/mysql/mariadb.conf.d/50-server.cnf**

```
sudo mysql -u root -p
```
```
CREATE USER 'repl'@'%' IDENTIFIED BY 'yourpassword';
GRANT REPLICATION SLAVE ON *.* TO 'repl'@'%';
FLUSH PRIVILEGES;
```

#### Step4: Master: Get Binlog File & Position

```
FLUSH TABLES WITH READ LOCK;
SHOW MASTER STATUS;
```
You’ll get output like:

+------------------+----------+--------------+------------------+
| File             | Position | Binlog_Do_DB | Binlog_Ignore_DB|
+------------------+----------+--------------+------------------+
| mysql-bin.000001 |      123 |              |                  |
+------------------+----------+--------------+------------------+

#### Step5: Slave: Configure MariaDB

```
sudo nano /etc/mysql/mariadb.conf.d/50-server.cnf
```

Add the following under `[mysqld]`:
```
[mysqld]
server-id=2
relay_log=/var/log/mysql/mariadb-relay-bin
log_bin=/var/log/mysql/mariadb-bin-slave.log
read_only=ON
```

Create the required log directory:
```
sudo mkdir -p /var/log/mysql
sudo chown mysql:mysql /var/log/mysql
```

Restart MariaDB:
```
sudo systemctl restart mariadb
```

#### Step6 : Slave: Connect to Master

```
mysql -u root -p
```
```
STOP SLAVE;

CHANGE MASTER TO
    MASTER_HOST='[MASTER_PUBLIC_IP]',
    MASTER_USER='repl',
    MASTER_PASSWORD='yourpassword',
    MASTER_LOG_FILE='mariadb-bin.000001',
    MASTER_LOG_POS=917,
    MASTER_PORT=3306;

START SLAVE;
```

Replace `[MASTER_PUBLIC_IP]` with the actual IP address and log file/position from Master’s `SHOW MASTER STATUS`.

#### Step7: Configure the Slave

Back in Master terminal (still locked):

```
UNLOCK TABLES;
```

#### Step 8: Slave: Check Replication Status

```
SHOW SLAVE STATUS\G
```

You should see:

Slave_IO_Running: Yes
Slave_SQL_Running: Yes

---
