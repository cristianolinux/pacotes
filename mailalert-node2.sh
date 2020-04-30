#!/bin/bash

# Executar script no node2 - Servidor Slave

# Vars

user=$1
pass=$2
emp=$3

if test -z "$1" && test -z "$2" && test -z "$3";
then
        echo "Preencha o endereço de e-mail, Senha do E-mail e Nome da Empresa";

elif test -z "$1";
then
        echo "Faltou preencher o endereço de e-mail";
elif test -z "$2";
then
        echo "Faltou digitar a senha do e-mail";
elif test -z "$3";
then
        echo "Faltou digitar o nome da empresa";
else

apt install ssmtp mailutils -y

cp /etc/ssmtp/ssmtp.conf /etc/ssmtp/ssmtp.conf-bkp

>  /etc/ssmtp/ssmtp.conf

echo "
mailhub=smtp.gmail.com:465
FromLineOverride=YES
AuthUser=${user}
AuthPass=${pass}
UseTLS=yes
" > /etc/ssmtp/ssmtp.conf

echo "
echo 'O Node1 está Parado, Favor Verificar!' | mail -s 'VocallCenter Node1 - ${emp}' cristiano.h@eox.com.br cristianolinux@gmail.com
" >> /usr/local/bin/eox.sh
fi
