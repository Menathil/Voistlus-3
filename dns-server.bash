#!/bin/bash
#Kontrollin kas kasutaja on ikka root et ta saaks käivitada seda skripti
if [ "$EUID" -ne 0 ]
  then echo "Palun käivita see skript ROOT õigustega"
  exit
fi

###updates###

apt-get update
apt-get ugprade -y

sed -i -e 's/\r$//' dns-server.bash

###### Küsimused
#Puhastan ekraani
clear
#Küsin kasutajalt küsimuse
echo "Palun sisesta ruuteri IP aadress"
read -r gwAadress
#Puhastan ekraani
clear
#Küsin kasutajalt küsimuse
echo "Palun sisesta täis pikk nimi enda domeenist (Näiteks: eestiasi.ee)"
read -r domNimi
#Puhastan ekraani
clear
#Küsin kasutajalt küsimuse
echo "Palun sisesta selle masina IPv4 aadress"
read -r IP
#Puhastan ekraani
clear
#Küsin kasutajalt küsimuse
echo "Palun sisesta selle masina IPv4 aadress TAGURPIDI (näiteks: 1.168.192)"
read -r TIP
#Peatan skripti 5 sekundiks
sleep 5
#Puhastan ekraani
clear
#Küsin kasutajalt küsimuse
echo "Palun sisesta enda masian IPv4 aadressi viimased numbrid"
read -r Viimane
#Puhastan ekraani
clear
#Annan kasutajale teada
echo "Antud muutujaid ei saa tagasi võtta"
####### Muutujad #######
#random numbrid, seriali jaoks
#Loon funktsiooni mis genereeriks serial numbrid konf faili
r=$(( RANDOM % 10 + 500000 )); echo $r
####### Paketide paigaldus ########
#Paigaldan bind9 paketid
apt-get install -y bind9 bind9utils bind9-doc
#Puhastan ekraani
clear
#Peatan skripti 5 sekundiks
sleep 5
echo "Paketid on paigaldatud"
#Peatan skripti 5 sekundiks
sleep 5
#Puhastan ekraani
clear
#Annan kasutajale teada
echo "Konfigureerimine alustab"
####### Konfiguratsiooni muutmine
#Annan teada skriptile et tuleb minna sinna teekonda
cd /etc/bind || exit
#Lisan forwarderid, kui siin midagi valesti läheb siis peab hakkama otsast peale
sed -i '13s/.*/		forwarders {/' named.conf.options
sed -i '14s/.*/		'"$IP"';/' named.conf.options
sed -i '15s/.*/		};/' named.conf.options
#Peatan skripti 5 sekundiks
sleep 5
echo "named.conf.options on valmis"
#Peatan skripti 5 sekundiks
sleep 5
#Puhastan ekraani
clear
#Annan kasutajale teada
echo "Alustan tsooni loomist"
#################|db.DOMEEN.LAB tsooni tegemine|################## 
#Kopeerin db.local faili enda domeeni tsooni jaoks
cp db.local db."$domNimi"
sed -i '5s/.*/@		IN		SOA		ns.'"$domNimi"'. admin.'"$domNimi"'. (/' db."$domNimi"
sed -i '6s/.*/						"'$r'"		; Serial /' db."$domNimi"
sed -i '12s/.*/@			IN		NS		ns.'"$domNimi"'. /' db."$domNimi"
sed -i '13s/.*/@			IN		A		'"$IP"' /' db."$domNimi"
sed -i '14s/.*/ns			IN		A		'"$IP"' /' db."$domNimi"
sed -i '15s/.*/www			IN		A		'"$IP"' /' db."$domNimi"

echo 'www		IN		A 		'"$IP"'' >> named.conf.local


################# Teenuse taaskäivitamine ja kontroll ###########################
#Annan Kasutajale teada
echo "Tsoon on valmis"
#Peatan skripti 5 sekundiks
sleep 5
#Puhastan ekraani
clear
echo "Alustan dnsi serveri kontrolli ......"
#Peatan skripti 5 sekundiks
sleep 5
#Teen teenusele taaskäivituse
service bind9 restart
#Puhastan ekraani
clear
#Peatan skripti 5 sekundiks
sleep 5
#vaatan kas antud server on ikka DNS
cat /etc/resolv.conf
#kontrollin domeeni nime kirjeid
dig "$domNimi"
#Pingin domeeni nime
ping "$domNimi"
#Peatan skripti 5 sekundiks
sleep 5
#Teavitan kasutajat
echo "Kui PINGIMINE failis siis tuleks vaadata üle konf failid"
#Peatan skripti 5 sekundiks
sleep 5
#Puhastan ekraani
clear

#################named.conf.local tegemine################
sleep 5
echo "alustan named.conf.local faili loomist"
sleep 5

echo 'zone "'$domNimi'"{' >> named.conf.local
echo '		type master;' >> named.conf.local
echo '		file "/etc/bind/db.'$domNimi'";' >> named.conf.local
echo '};' >> named.conf.local

echo 'zone "'$TIP'.in-addr.arpa"{' >> named.conf.local
echo '		type master;' >> named.conf.local
echo '		file "/etc/bind/rev.'$TIP'.in-addr.arpa";' >> named.conf.local
echo '};' >> named.conf.local



#### kontrollin kas skript ikka on samas kausta või ei ole
cd /etc/bind || exit
################# nimeteisenduse loomine #########################################
#sed -i '9s/.*/zone " '"$domNimi"' "{ /' named.conf.local
#sed -i '10s/.*/			type master;/' named.conf.local
#sed -i '11s/.*/			file "/etc/bind/db.'"$domNimi"'";/' named.conf.local
#sed -i '12s/.*/};/' named.conf.local
####Tagurpidi IP Kirjed
#sed -i '14s/.*/zone '"$TIP"'.in-addr.arpa"{/' named.conf.local
#sed -i '15s/.*/			type master;/' named.conf.local
#sed -i '16s/.*/			file "/etc/bind/db.'"$TIP".in-addr.arpa'";/' named.conf.local
#sed -i '17s/.*/};/' named.conf.local
#Loon Tagurpidi IP kirjed
cp db."$domNimi" rev."$TIP".in-addr.arpa
################# in-addr.arpa kirje muutmine #####################################
sed -i '12s/.*/@		IN		NS		ns./' rev."$TIP".in-addr.arpa
sed -i '13s/.*/'"$Viimane"'		IN		PTR		ns.'"$domNimi"'/' rev."$TIP".in-addr.arpa
sed -i '14s/.*/'"$Viimane"'		IN		PTR		'"$domNimi"'/' rev."$TIP".in-addr.arpa
#sed -i '14s/.*//' rev."$TIP".in-addr.arpa

#echo '			'"$Viimane"'		IN		PTR		ns.'"$domNimi"'' >> rev."$TIP".in-addr.arpa
#echo '			'"$Viimane"'		IN		PTR		'"$domNimi"'' >> rev."$TIP".in-addr.arpa

#Puhastan ekraani
clear
#Annan kasutajale teada
echo "PTR kirjed on lisatud"
#Peatan skripti 5 sekundiks
sleep 5
#### Lõpp kontroll ####
host "$IP"
##### Annan teada et lõpp on käes ######
sleep 5
#Puhastan ekraani
clear
#Annan teada kasutajale

sed -i '9s/.*/zone " '$domNimi' "{ /' named.conf.local

service bind9 restart

echo "Valmis"
