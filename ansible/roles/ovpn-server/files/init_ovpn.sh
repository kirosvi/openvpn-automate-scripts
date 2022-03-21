#!/usr/bin/env bash
cd /root/easy-rsa-master/easyrsa3/
./easyrsa init-pki
./easyrsa --batch build-ca nopass
openssl dhparam -out dh.pem 2048
./easyrsa build-server-full server nopass
EASYRSA_CRL_DAYS=3650 ./easyrsa gen-crl
cp pki/ca.crt pki/private/ca.key dh.pem pki/issued/server.crt pki/private/server.key /etc/openvpn/
cp pki/crl.pem /etc/openvpn/
chmod 644 /etc/openvpn/crl.pem
iptables -A INPUT -p tcp -m state --state NEW -m tcp --dport 22 -j ACCEPT
iptables -I INPUT -p tcp --dport 12345 -j ACCEPT
iptables -I FORWARD -s 10.10.20.0/24 -j ACCEPT
iptables -I FORWARD -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables-save > /etc/iptables-save
