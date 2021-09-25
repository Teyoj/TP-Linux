# TP1 : (re)Familiaration avec un système GNU/Linux

### 0. Préparation de la machine

* un accès internet : 

En faisant un `ip a` sur nos deux machines on voit qu'elles ont une carte NAT et une carte Ethernet.

Ensuite avec la NAT on ping le DNS de google et on ping aussi google.com.

![](https://i.imgur.com/1NeCjoB.png)

![](https://i.imgur.com/Weq3ZXN.png)

On fait la même chose avec notre deuxième machine.

![](https://i.imgur.com/rwbOtWS.png)

![](https://i.imgur.com/9x9fayT.png)

* un accès à un réseau local

Pour vérifier qu'on possède un réseau local, on effectue un ping d'une machine à l'autre.

```
[hugoj@node1 ~]$ ping 10.101.1.12
PING 10.101.1.12 (10.101.1.12) 56(84) bytes of data.
64 bytes from 10.101.1.12: icmp_seq=1 ttl=64 time=0.432 ms
64 bytes from 10.101.1.12: icmp_seq=2 ttl=64 time=1.29 ms
64 bytes from 10.101.1.12: icmp_seq=3 ttl=64 time=1.11 ms
64 bytes from 10.101.1.12: icmp_seq=4 ttl=64 time=1.20 ms
```

```
[hugoj@node2 ~]$ ping 10.101.1.11
PING 10.101.1.11 (10.101.1.11) 56(84) bytes of data.
64 bytes from 10.101.1.11: icmp_seq=1 ttl=64 time=0.329 ms
64 bytes from 10.101.1.11: icmp_seq=2 ttl=64 time=1.39 ms
64 bytes from 10.101.1.11: icmp_seq=3 ttl=64 time=1.20 ms
64 bytes from 10.101.1.11: icmp_seq=4 ttl=64 time=1.22 ms
```

* les machines doivent avoir un nom

Pour donner un nom à nos machines on fait 
`echo 'node1.tp1.b2' | sudo tee /etc/hostname`

Ensuite on regarde avec `hostname` si la modification a bien été faite.

```
[hugoj@node1 ~]$ hostname
node1.tp1.b2
```

```
[hugoj@node2 ~]$ hostname
node2.tp1.b2
```

* utiliser 1.1.1.1 comme serveur DNS

```
[hugoj@node2 ~]$ dig ynov.com

; <<>> DiG 9.11.26-RedHat-9.11.26-4.el8_4 <<>> ynov.com
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 31767
;; flags: qr rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 0, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 4000
;; QUESTION SECTION:
;ynov.com.                      IN      A

;; ANSWER SECTION:
ynov.com.               3518    IN      A       92.243.16.143

;; Query time: 2 msec
;; SERVER: 10.33.10.2#53(10.33.10.2)
;; WHEN: Wed Sep 22 12:19:43 CEST 2021
;; MSG SIZE  rcvd: 53
```

On cherche donc l'IP qui correspond à ynov.com.
`ynov.com.               3518    IN      A       92.243.16.143`

Ensuite on cherche l'IP du serveur qui nous a répondu.
`SERVER: 10.33.10.2#53(10.33.10.2)`

* les machines doivent pouvoir se joindre par leurs noms respectifs

Après avoir ajouté l'IP et le nom de node2 dans le fichier /etc/hosts on peut le ping et on fait la même chose avec l'autre machine.

```
[hugoj@node1 ~]$ ping node2
PING node2 (10.101.1.12) 56(84) bytes of data.
64 bytes from node2 (10.101.1.12): icmp_seq=1 ttl=64 time=0.629 ms
64 bytes from node2 (10.101.1.12): icmp_seq=2 ttl=64 time=1.19 ms
64 bytes from node2 (10.101.1.12): icmp_seq=3 ttl=64 time=1.16 ms
64 bytes from node2 (10.101.1.12): icmp_seq=4 ttl=64 time=1.09 ms
```

```
[hugoj@node2 ~]$ ping node1
PING node1 (10.101.1.11) 56(84) bytes of data.
64 bytes from node1 (10.101.1.11): icmp_seq=1 ttl=64 time=0.538 ms
64 bytes from node1 (10.101.1.11): icmp_seq=2 ttl=64 time=1.26 ms
64 bytes from node1 (10.101.1.11): icmp_seq=3 ttl=64 time=1.15 ms
64 bytes from node1 (10.101.1.11): icmp_seq=4 ttl=64 time=1.16 ms
```

## I. Utilisateurs

### 1. Création et configuration

Création de l'utilisateur : 
`[hugoj@node1 ~]$ sudo useradd joyet -d /home/joyet -s /bin/bash`

Création du groupe : 
`[hugoj@node1 ~]$ sudo groupadd admins`

Modification du fichier `/etc/sudoers` : 

```
## Allows people in group admins to run all commands
%admins ALL=(ALL)       ALL
```

Ajout de notre utilisateur au groupe admins : 
`[hugoj@node1 ~]$ sudo usermod -aG admins joyet`

### 2.SSH

J'ai généré une paire de clés SSH sur mon PC avec la commande `ssh-keygen -t rsa -b 4096`.

J'ai ensuite récupérer le contenu de ma clé publique et je l'ai déposé sur ma VM dans le fichier `/home/joyet/.ssh/authorized_keys` que j'ai créé.

```
PS C:\Users\hugoj> ssh hugoj@10.101.1.11
Enter passphrase for key 'C:\Users\hugoj/.ssh/id_rsa':
Activate the web console with: systemctl enable --now cockpit.socket

Last login: Fri Sep 24 17:00:57 2021 from 10.101.1.1
[hugoj@node1 ~]$
```

On remarque ici que le mot de passe de notre machine n'est plus demandé, on nous demande seulement le mot de passe de notre clé si pendant la génération de notre paire nous en avons mis un.


## II. Partitionnement

### 1. Préparation de la VM

J'ajoute deux disques durs de 3Go chacun à `node1` en allant dans la configuration de la machine.

### 2. Partitionnement

Pour agréger les deux disques en un seul *volume group* il faut d'abord créer le *volume group*.

```
[hugoj@node1 ~]$ sudo vgcreate data /dev/sdb
  Physical volume "/dev/sdb" successfully created.
  Volume group "data" successfully created
```

Ensuite il faut ajouter notre deuxième disque dur dans le *volume group*.
```
[hugoj@node1 ~]$ sudo vgextend data /dev/sdc
  Physical volume "/dev/sdc" successfully created.
  Volume group "data" successfully extended
```

Création des 3 *logical volumes* : 
```
[hugoj@node1 ~]$ sudo lvcreate -L 1G data -n lv_data1
[sudo] password for hugoj:
  Logical volume "lv_data1" created.
[hugoj@node1 ~]$ sudo lvcreate -L 1G data -n lv_data2
  Logical volume "lv_data2" created.
[hugoj@node1 ~]$ sudo lvcreate -L 1G data -n lv_data3
  Logical volume "lv_data3" created.
```

Formatages des *LV* : 
```
[hugoj@node1 ~]$ sudo mkfs -t ext4 /dev/data/lv_data3
mke2fs 1.45.6 (20-Mar-2020)
Creating filesystem with 262144 4k blocks and 65536 inodes
Filesystem UUID: d5d906ab-9e18-4a3e-bf4e-fd235a272fd2
Superblock backups stored on blocks:
        32768, 98304, 163840, 229376

Allocating group tables: done
Writing inode tables: done
Creating journal (8192 blocks): done
Writing superblocks and filesystem accounting information: done
```

On fait la même commande avec les autres *logical volumes*.

Monter les partitions : 
```
[hugoj@node1 ~]$ sudo mkdir /mnt/part1
[hugoj@node1 ~]$ sudo mount /dev/data/lv_data1 /mnt/part1
[hugoj@node1 ~]$ sudo mkdir /mnt/part2
[hugoj@node1 ~]$ sudo mount /dev/data/lv_data2 /mnt/part2
[hugoj@node1 ~]$ sudo mkdir /mnt/part3
[hugoj@node1 ~]$ sudo mount /dev/data/lv_data3 /mnt/part3
```

Dans le fichier `/etc/fstab` on ajoute cette ligne `/dev/data/lv_data1 /mnt/part1 ext4 defaults 0 0` pour que la partition soit montée automatiquement au lancement de la VM.


## III. Gestion de services

### 1. Interaction avec un service existant

```
[hugoj@node1 ~]$ systemctl is-active firewalld
active
[hugoj@node1 ~]$ systemctl is-enabled firewalld
enabled
```
On voit que l'unité est démarée et qu'elle est activée.

### 2. Création de service

#### A. Unité simpliste

Je créé le fichier dans `/etc/systemd/system`, ensuite j'active le server web et je regarde si il fonctionne avec un curl.
```
[hugoj@node1 ~]$ curl 10.101.1.11:8888
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8">
<title>Directory listing for /</title>
</head>
<body>
<h1>Directory listing for /</h1>
<hr>
<ul>
<li><a href="bin/">bin@</a></li>
<li><a href="boot/">boot/</a></li>
<li><a href="dev/">dev/</a></li>
<li><a href="etc/">etc/</a></li>
<li><a href="home/">home/</a></li>
<li><a href="lib/">lib@</a></li>
<li><a href="lib64/">lib64@</a></li>
<li><a href="media/">media/</a></li>
<li><a href="mnt/">mnt/</a></li>
<li><a href="opt/">opt/</a></li>
<li><a href="proc/">proc/</a></li>
<li><a href="root/">root/</a></li>
<li><a href="run/">run/</a></li>
<li><a href="sbin/">sbin@</a></li>
<li><a href="srv/">srv/</a></li>
<li><a href="sys/">sys/</a></li>
<li><a href="tmp/">tmp/</a></li>
<li><a href="usr/">usr/</a></li>
<li><a href="var/">var/</a></li>
</ul>
<hr>
</body>
</html>
```

On voit que le serveur web marche bien.

#### B. Modification de l'unité 

Tout d'abord, je crée l'utilisateur `web` : 
`[hugoj@node1 ~]$ sudo useradd web`

Je retourne dans le fichier web.server pour le modifier.
J'ajoute les lignes `User=web` et `WorkingDirectory=/srv/serv_web` dans la section `[Service]`.

Je crée un fichier nommé `file` dans `/srv/serv_web`.

Pour donner les droits d'appartenance d'un dossier ou d'un fichier il faut utiliser la commande `chown`.

```
[hugoj@node1 ~]$ sudo chown -R web /srv/serv_web
[hugoj@node1 ~]$ cd /srv/
[hugoj@node1 srv]$ ls -l
total 0
drwxr-xr-x. 2 web root 18 Sep 25 12:28 serv_web
```

On voit bien que mon dossier `/serv_web` appartient maintenant à l'utilisateur `web`.

On va maintenant refaire un `curl` pour voir si le serveur web fonctionne.

```
[hugoj@node1 srv]$ curl 10.101.1.11:8888
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8">
<title>Directory listing for /</title>
</head>
<body>
<h1>Directory listing for /</h1>
<hr>
<ul>
<li><a href="bin/">bin@</a></li>
<li><a href="boot/">boot/</a></li>
<li><a href="dev/">dev/</a></li>
<li><a href="etc/">etc/</a></li>
<li><a href="home/">home/</a></li>
<li><a href="lib/">lib@</a></li>
<li><a href="lib64/">lib64@</a></li>
<li><a href="media/">media/</a></li>
<li><a href="mnt/">mnt/</a></li>
<li><a href="opt/">opt/</a></li>
<li><a href="proc/">proc/</a></li>
<li><a href="root/">root/</a></li>
<li><a href="run/">run/</a></li>
<li><a href="sbin/">sbin@</a></li>
<li><a href="srv/">srv/</a></li>
<li><a href="sys/">sys/</a></li>
<li><a href="tmp/">tmp/</a></li>
<li><a href="usr/">usr/</a></li>
<li><a href="var/">var/</a></li>
</ul>
<hr>
</body>
</html>
```
