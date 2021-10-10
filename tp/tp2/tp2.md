# TP2 pt. 1 : Gestion de service

## I. Un premier serveur web

### 1. Installation

J'installe le serveur Apache avec la commande `sudo dnf -y install httpd`

Démarrer le service Apache : 

Pour démarrer le service il faut taper la commande `sudo systemctl start httpd` et pour qu'il démarre automatiquement au démarrage de la machine il faut faire la commande `sudo systemctl enable httpd`.

Pour trouver le port qu'utilise httpd j'utilise la commande `sudo ss -lnpa` et je vois que le port utilisé est le port 80.
```
tcp         LISTEN        0       128       *:80         *:*           
users:(("httpd",pid=23928,fd=4),("httpd",pid=23927,fd=4),("httpd",pid=23926,fd=4),("httpd",pid=23924,fd=4))
```

J'active le port 80 
```
[hugoj@web ~]$ sudo firewall-cmd --add-port=80/tcp --permanent
success
[hugoj@web ~]$ sudo firewall-cmd --reload
success
[hugoj@web ~]$ sudo firewall-cmd --list-all
public (active)
  target: default
  icmp-block-inversion: no
  interfaces: enp0s3 enp0s8
  sources:
  services: cockpit dhcpv6-client ssh
  ports: 80/tcp
  protocols:
  masquerade: no
  forward-ports:
  source-ports:
  icmp-blocks:
  rich rules:
```

TEST : 

Pour vérifier que le serveur est démarré et qu'il est configuré pour démarrer automatiquement on utilise la commande `sudo systemctl status httpd`.
```
[hugoj@web ~]$ sudo systemctl status httpd
[sudo] password for hugoj:
● httpd.service - The Apache HTTP Server
   Loaded: loaded (/usr/lib/systemd/system/httpd.service; enabled; vendor preset: disabled)
```

Avec `curl localhost` on vérifie qu'on joint notre serveur web localement
```
[hugoj@web ~]$ curl localhost
<!doctype html>
<html>
  <head>
    <meta charset='utf-8'>
    <meta name='viewport' content='width=device-width, initial-scale=1'>
    <title>HTTP Server Test Page powered by: Rocky Linux</title>
    <style type="text/css">
      /*<![CDATA[*/

      html {
        height: 100%;
        width: 100%;
      }
        body {
        
        [...]
        
         <footer class="col-sm-12">
      <a href="https://apache.org">Apache&trade;</a> is a registered trademark of <a href="https://apache.org">the Apache Software Foundation</a> in the United States                   and/or other countries.<br />
      <a href="https://nginx.org">NGINX&trade;</a> is a registered trademark of <a href="https://">F5 Networks, Inc.</a>.
      </footer>

  </body>
</html>
```

Pour vérifier que nous pouvons accéder à notre serveur web avec notre navigateur il suffit de taper dans la barre de recherche l'IP de notre VM.

![](https://i.imgur.com/K15m8a8.png)


### 2. Avancer vers la maîtrise du service

**Le service Apache**

La commande qui permet d'activer le service Apache automatiquement au démarrage de la machine est `sudo systemctl enable httpd`.

Pour prouver qu'actuellement le service est paramétré pour démarrer quand la machine s'allume j'utilise la commande `systemctl status httpd`.
```
[hugoj@web ~]$ sudo systemctl status httpd
● httpd.service - The Apache HTTP Server
   Loaded: loaded (/usr/lib/systemd/system/httpd.service; enabled; vendor preset: disabled)
```

Pour afficher le contenu du fichier `httpd.service` je tape la commande `cat /usr/lib/systemd/system/httpd.service`.
```
[hugoj@web ~]$ cat /usr/lib/systemd/system/httpd.service
[Unit]
Description=The Apache HTTP Server
Wants=httpd-init.service
After=network.target remote-fs.target nss-lookup.target httpd-init.service
Documentation=man:httpd.service(8)

[Service]
Type=notify
Environment=LANG=C

ExecStart=/usr/sbin/httpd $OPTIONS -DFOREGROUND
ExecReload=/usr/sbin/httpd $OPTIONS -k graceful
# Send SIGWINCH for graceful stop
KillSignal=SIGWINCH
KillMode=mixed
PrivateTmp=true

[Install]
WantedBy=multi-user.target
```

**Déterminer sous quel utilisateur tourne le processus Apache**

```
[hugoj@web ~]$ cat /etc/httpd/conf/httpd.conf | grep User
User apache
```

```
[hugoj@web ~]$ ps -ef | grep apache
apache       854     829  0 09:49 ?        00:00:00 /usr/sbin/httpd -DFOREGROUND
apache       855     829  0 09:49 ?        00:00:00 /usr/sbin/httpd -DFOREGROUND
apache       856     829  0 09:49 ?        00:00:00 /usr/sbin/httpd -DFOREGROUND
apache       857     829  0 09:49 ?        00:00:00 /usr/sbin/httpd -DFOREGROUND
```

```
[hugoj@web www]$ ls -al
total 4
drwxr-xr-x.  4 root root   33 Sep 29 12:08 .
drwxr-xr-x. 22 root root 4096 Sep 29 12:08 ..
drwxr-xr-x.  2 root root    6 Jun 11 17:35 cgi-bin
drwxr-xr-x.  2 root root    6 Jun 11 17:35 html
```

On voit que le fichier est exécutable par les autres utilisateurs (donc apache) et donc il est accessible.

**Changer l'utilisateur utilisé par Apache**

Création du nouvel utilisateur : 

```
[hugoj@web ~]$ sudo useradd -d /usr/share/httpd siou
[hugoj@web ~]$ sudo usermod siou --shell=/sbin/nologin
```

Je modifie la configuration Apache et je change l'utilisateur par siou.

Je redémarre le service apache et avec la commande `ps -U siou` je vérifie que le changement a eu lieu.
```
[hugoj@web ~]$ ps -U siou
    PID TTY          TIME CMD
    858 ?        00:00:00 httpd
    859 ?        00:00:00 httpd
    860 ?        00:00:00 httpd
    861 ?        00:00:00 httpd
```

**Faites en sorte que Apache tourne sur un autre port**

J'ai modifié la configuration d'Apache pour qu'il écoute sur le port 5000.

J'ouvre le port 5000 et je ferme le 80.
```
[hugoj@web ~]$ sudo firewall-cmd --add-port=5000/tcp --permanent
success
[hugoj@web ~]$ sudo firewall-cmd --remove-port=80/tcp --permanent
success[hugoj@web ~]$ curl 10.102.1.11:5000
<!doctype html>
<html>
[...]
</html>
```

Je regarde avec la commande `sudo ss -lnpa` que Apache tourne bien sur le port 5000.
```
tcp         LISTEN        0         128         *:5000               *:*            
users:(("httpd",pid=1772,fd=4),("httpd",pid=1771,fd=4),("httpd",pid=1770,fd=4),("httpd",pid=1768,fd=4))
```

Avec un `curl` je vérifie que le serveur fonctionne sur le nouveau port.
```
[hugoj@web ~]$ curl localhost:5000
<!doctype html>
<html>
[...]
</html>
```


## II. Une stack web plus avancée

### Setup

#### A. Serveur Web et NextCloud

Commandes réalisées pour l'installation du serveur web et de NextCloud : 

```
dnf -y install epel-release
dnf -y install https://rpms.remirepo.net/enterprise/remi-release-8.rpm
dnf -y module enable php:remi-7.4
dnf -y install vim wget zip unzip libxml2 openssl php74-php php74-php-ctype php74-php-curl php74-php-gd php74-php-iconv php74-php-json php74-php-libxml php74-php-mbstring php74-php-openssl php74-php-posix php74-php-session php74-php-xml php74-php-zip php74-php-zlib php74-php-pdo php74-php-mysqlnd php74-php-intl php74-php-bcmath php74-php-gmp
mkdir /etc/httpd/sites-available
mkdir /etc/httpd/sites-enabled
systemctl enable httpd
vi /etc/httpd/sites-available/web.tp2.linux
ln -s /etc/httpd/sites-available/web.tp2.linux /etc/httpd/sites-enabled/
mkdir -p /var/www/sub-domains/web.tp2.linux/html
cd /usr/share/zoneinfo
vi /etc/opt/remi/php74/php.ini
```
Dans le fichier `/etc/httpd/sites-available/web.tp2.linux` je mets : 
```
<VirtualHost *:80>
  DocumentRoot /var/www/sub-domains/web.tp2.linux/html/
  ServerName  web.tp2.linux

  <Directory /var/www/sub-domains/web.tp2.linux/html/>
    Require all granted
    AllowOverride All
    Options FollowSymLinks MultiViews

    <IfModule mod_dav.c>
      Dav off
    </IfModule>
  </Directory>
</VirtualHost>
```
Dans le fichier `php.ini` je cherche la ligne `date.timezone =`. Je modifie cette ligne en `date.timezone = "Europe/Paris"`.

Ensuite j'installe NextCloud.
```
wget https://download.nextcloud.com/server/releases/nextcloud-22.2.0.zip
unzip nextcloud-22.2.0.zip
```

```
cd nextcloud
sudo cp -Rf * /var/www/sub-domains/web.tp2.linux/html/
chown -Rf apache.apache /var/www/sub-domains/web.tp2.linux/html
mv /var/www/sub-domains/web.tp2.linux/html/data /var/www/sub-domains/web.tp2.linux/
```

![](https://i.imgur.com/mFBC0iY.png)

#### B. Base de données

Commandes réalisées : 
```
sudo dnf -y install mariadb-server
sudo systemctl enable mariadb
sudo systemctl start mariadb
mysql_secure_installation
```

Avec la commande `ss -antpl` je repère que mysql utilise le port 3306.

**Exploration de la base de données**
```
[hugoj@web ~]$ mysql -u nextcloud -h 10.102.1.12 -p
Enter password:
Welcome to the MariaDB monitor.  Commands end with ; or \g.
Your MariaDB connection id is 18
Server version: 10.3.28-MariaDB MariaDB Server

Copyright (c) 2000, 2018, Oracle, MariaDB Corporation Ab and others.

Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

MariaDB [(none)]>
```

#### C. Finaliser l'installation de NextCloud

Je modifie mon fichier hosts qui se trouve dans `C:\Windows\System32\drivers\etc` et j'ajoute `10.102.1.11 web.tp2.linux`.

| Machine         | IP            | Service                 | Port ouvert | IP autorisées |
|-----------------|---------------|-------------------------|-------------|---------------|
| `web.tp2.linux` | `10.102.1.11` | Serveur Web             | 80          | toutes        |
| `db.tp2.linux`  | `10.102.1.12` | Serveur Base de Données | 3306        | 10.102.1.11   |

