#!/bin/bash

<<COMENTARIO
Fazer esse procedimento nos 2 servidores, antes de realizar o procedimento abaixo.
Formatar o segundo HD, formatar com xfs e mapear no fstab

# Criando diretorio para o cluster, fazer no 2 servidores

mkdir -p /dados/cluster

formatando particao

fdisk -l
fdisk /dev/sdb
digita n  -> ENTER, confirme nas demais opçoes até chegar em -> Comando (m para ajuda):
digita w -> Para gravar alterações.

formtar particao no formatado xfs
mkfs.xfs /dev/sdb1

echo "
/dev/sdb1 /dados/cluster xfs defaults 0 0
" >> /etc/fstab

mount -a

# Adicionar no servidor secundário

mkdir -p /dados/cluster

mkfs.xfs /dev/sdb1

echo "
/dev/sdb1 /dados/cluster xfs defaults 0 0
" >> /etc/fstab

mount -a

echo "node2:/VOL /mnt/replica glusterfs defaults,_netdev,x-systemd.automount 0 0" >> /etc/fstab

COMENTARIO

IP=$1
REP=/mnt/replica

if test -n "$IP"; then

# Instalando sistemas de arquivos distribuidos - Ambos servers


apt-get install glusterfs-server attr -y 

mkdir -p /dados/cluster/brick
mkdir -p ${REP}


ssh -t suporte@${IP} 'sudo apt-get install glusterfs-server attr -y'

ssh -t suporte@${IP} 'sudo mkdir -p /dados/cluster/brick'

ssh -t suporte@${IP} 'sudo mkdir -p /mnt/replica'


# Configurando os Peer

gluster peer probe node2

# Criando volume

gluster vol create VOL replica 2 node1:/dados/cluster/brick node2:/dados/cluster/brick

gluster vol start VOL



# Em /etc/fstab - Servidor Principal

echo "node1:/VOL ${REP} glusterfs defaults,_netdev,x-systemd.automount 0 0" >> /etc/fstab

mount -a


ssh -t suporte@${IP} 'sudo mount -a'



# segunda etapa

systemctl stop postgresql
systemctl stop freeswitch 
systemctl stop vocallsocket
systemctl stop vocallhtml5
systemctl stop vocallintegration

systemctl disable postgresql
systemctl disable freeswitch 
systemctl disable vocallsocket
systemctl disable vocallhtml5
systemctl disable vocallintegration


# Criando Diretorios

mkdir -p ${REP}/{DB,CONFS}


# Replicando Base de Dados
mv /var/lib/postgresql/9.5/main/pg_* ${REP}/DB/

rsync -ravz --progress /var/lib/postgresql/9.5/main/{global,base} ${REP}/DB/


rm -Rf /var/lib/postgresql/9.5/main/global
rm -Rf /var/lib/postgresql/9.5/main/base

ln -s ${REP}/DB/pg_* /var/lib/postgresql/9.5/main/.
ln -s ${REP}/DB/{global,base}  /var/lib/postgresql/9.5/main/.


chown postgres. ${REP}/DB/ -Rf
### Fim  replica base de dados

# Sincronizando o diretorio /var/eox 

rsync -rav --progress /var/eox  ${REP}/CONFS/var/
rm -rf  /var/eox
ln -s ${REP}/CONFS/var/eox   /var/eox

# Sincronizando o diretorio de configurações do Freeswitch

rsync -rav --progress /usr/local/eox/programas/freeswitch/etc   ${REP}/CONFS/etc
rm -rf /usr/local/eox/programas/freeswitch/etc/freeswitch
ln -s ${REP}/CONFS/etc/etc/freeswitch  /usr/local/eox/programas/freeswitch/etc/freeswitch


rsync -rav --progress ${HOME}/Gremoto.sh suporte@${IP}:.

ssh -t suporte@${IP} 'sudo mount -a'

ssh -t suporte@${IP} 'sudo sh Gremoto.sh'


systemctl restart postgresql

systemctl restart vocallsocket

systemctl restart vocallhtml5

systemctl restart vocallintegration



else

echo "Coloque o IP remoto";

fi
