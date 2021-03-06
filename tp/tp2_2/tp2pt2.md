# TP2 pt. 2 : Maintien en condition opérationnelle!


## I. Monitoring

### Setup

J'installe Netdata sur toutes mes machines avec la commande `bash <(curl -Ss https://my-netdata.io/kickstart-static64.sh)` en étant en root.

Je paramètre le service netdata pour qu'il démarre au boot de la machine avec `sudo systemctl enable netdata`.

Avec la commande `sudo ss -lantp` je vois que le port où écoute netdata est le port 19999.
Je l'ouvre donc avec la commande `sudo firewall-cmd --add-port=19999/tcp --permanent`.

Sur le naviguateur de mon PC je me rends sur `http://10.102.1.11:19999` et j'ai accès à mon netdata.

![](https://i.imgur.com/oypvwwN.png)

**Setup Alerting**

Pour recevoir des alertes discord de notre netdata, il faut, sur un serveur, créer un webhook. Ensuite dans le fichier `/opt/netdata/etc/netdata/health_alarm_notify.conf`, je mets : 
```
###############################################################################
# sending discord notifications
curl="/opt/netdata/bin/curl -k"
# note: multiple recipients can be given like this:
#                  "CHANNEL1 CHANNEL2 ..."

# enable/disable sending discord notifications
SEND_DISCORD="YES"

# Create a webhook by following the official documentation -
# https://support.discordapp.com/hc/en-us/articles/228383668-Intro-to-Webhooks
DISCORD_WEBHOOK_URL="https://discord.com/api/webhooks/897058731370618891/bzQmxtVdLArN64iPvKndh6ZlTU5tlQFG6py8DJTf4CTZC3cLvc6tVWjzosDRD4hkysPy"

# if a role's recipients are not configured, a notification will be send to
# this discord channel (empty = do not send a notification for unconfigured
# roles):
DEFAULT_RECIPIENT_DISCORD="alarms"
```

Ensuite il faut devenir l'user netdata avec la commande `sudo su -s /bin/bash netdata`.
Il faut ensuite taper les commandes suivantes.
```
export NETDATA_ALARM_NOTIFY_DEBUG=1
/opt/netdata/usr/libexec/netdata/plugins.d/alarm-notify.sh test
```

![](https://i.imgur.com/vWBe5nu.png)

**Config alerting**

Pour recevoir une alerte quand notre RAM est pleine à 50%, on crée le fichier `/opt/netdata/etc/netdata/health.d/ram-usage.conf`.
```
 alarm: ram_usage
    on: system.ram
lookup: average -1m percentage of used
 units: %
 every: 1m
  warn: $this > 50
  crit: $this > 80
  info: The percentage of RAM being used by the system.
```
Ce fichier permet d'envoyer une alerte quand notre est pleine à 50% et une alerte critique quand la RAM est pleine à 80%.

Ensuite il faut installer `stress` avec la commande `sudo dnf -y install stress` et on peut effectuer un stress test sur notre machine.
Ensuite le webhook envoie une alerte sur discord quand notre RAM est pleine à 50%.

![](https://i.imgur.com/BtRH5R9.png)

On fait les mêmes manipulations sur notre machine `db.tp2.linux`.


## II. Backup

Je crée ma machine `backup.tp2.linux` et je la monitore à l'aide des étapes précédentes.

### Partage NFS


**Setup environnement**
Je crée le dossier `/srv/backup/` avec deux sous dossiers qui sont `/srv/backup/web.tp2.linux/` et `/srv/backup/db.tp2.linux/`.

**Setup partage NFS**
Je commence à installer nfs sur ma machine avec la commande `sudo dnf -y install nfs-utils`. Ensuite je me rends sur le fichier `/etc/idmapd.conf` et je change la ligne `#Domain` en `Domain = tp2.linux`.
Après ça je crée le fichier `/etc/exports` et dedans je mets `/srv/backup 10.102.1.0/24(rw,no_root_squash)`.

**Setup points de montage sur `web.tp2.linux`**
Je monte le dossier du serveur NFS avec la commande `sudo mount -t nfs backup.tp2.linux:/srv/backup/web.tp2.linux /srv/backup`.
Je vérifie ensuite avec `sudo mount -l | grep backup`.
```
[hugoj@web ~]$ sudo mount -l | grep backup
backup.tp2.linux:/srv/backup/web.tp2.linux on /srv/backup type nfs4 (rw,relatime,vers=4.2,rsize=131072,wsize=131072,namlen=255,hard,proto=tcp,timeo=600,retrans=2,sec=sys,clientaddr=10.102.1.11,local_lock=none,addr=10.102.1.13)
```
Je regarde maintenant avec `df -h` qu'il reste de la place.
```
[hugoj@web ~]$ df -h
Filesystem                                  Size  Used Avail Use% Mounted on
devtmpfs                                    386M     0  386M   0% /dev
tmpfs                                       405M  316K  405M   1% /dev/shm
tmpfs                                       405M  5.6M  400M   2% /run
tmpfs                                       405M     0  405M   0% /sys/fs/cgroup
/dev/mapper/rl-root                         6.2G  3.4G  2.9G  55% /
/dev/sda1                                  1014M  182M  833M  18% /boot
tmpfs                                        81M     0   81M   0% /run/user/1000
backup.tp2.linux:/srv/backup/web.tp2.linux  6.2G  2.1G  4.1G  34% /srv/backup
```

## III. Reverse Proxy

### Setup

J'installe `epel-release` et `nginx` sur ma machine `front.tp2.linux`.

Je lance le service `nginx` avec la commande `sudo systemctl start nginx.service` et je fais en sorte qu'il démarre quand le système boot avec la commande `sudo systemctl enable nginx.service`.

Avec la commande `sudo ss -lantp` je repère que le port utilisé par `nginx` est le port 80, je l'ouvre donc dans mon firewall.
```
[hugoj@front ~]$ sudo firewall-cmd --add-port=80/tcp --permanent
success
```

Depuis un powershell sur mon PC je fais un curl pour vérifier que je peux joindre NGINX.
```
PS C:\Users\hugoj> curl 10.102.1.14:80                                                                                  

StatusCode        : 200
StatusDescription : OK
Content           : <!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN" "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">

                    <html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en">
                      <head>
                        <title>Test Page for the Nginx...
```


**Explorer la conf par défaut de NGINX**

Je regarde dans la conf de NGINX pour repérer le user utilisé.
```
[hugoj@front ~]$ sudo cat /etc/nginx/nginx.conf
# For more information on configuration, see:
#   * Official English Documentation: http://nginx.org/en/docs/
#   * Official Russian Documentation: http://nginx.org/ru/docs/

user nginx;
```

On voit que le user utilisé est nginx.

je repère le bloc `server {}` dans le fichier de conf principal.
```
 server {
        listen       80 default_server;
        listen       [::]:80 default_server;
        server_name  _;
        root         /usr/share/nginx/html;

        # Load configuration files for the default server block.
        include /etc/nginx/default.d/*.conf;

        location / {
        }

        error_page 404 /404.html;
            location = /40x.html {
        }

        error_page 500 502 503 504 /50x.html;
            location = /50x.html {
        }
```

Je repère les inclusions des autres fichiers de conf.
```
[hugoj@front ~]$ sudo cat /etc/nginx/nginx.conf | grep include
include /usr/share/nginx/modules/*.conf;
    include             /etc/nginx/mime.types;
        include /etc/nginx/default.d/*.conf;
```

**Modifier la conf de NGINX**

Je supprime le bloc serveur dans `/etc/nginx/nginx.conf` et je crée le fichier `/etc/nginx/conf.d/web.tp2.linux.conf` avec le contenu donné dans le tp.


## IV. Firewalling

### Mise en place

