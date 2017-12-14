#!/bin/bash

INTERFACE=$(ifconfig | cut -d" " -f1|head -n1)
SERVERIP=$(curl -s https://api.ipify.org)
#SERVERIP=$(ifconfig $INTERFACE | grep "inet addr" | cut -d":" -f2 | cut -d" " -f1)
export DEBIAN_FRONTEND=noninteractive

apt-get update
apt-get upgrade -y
apt-get install -y openvpn easy-rsa iptables-persistent
sed -i s/"#net.ipv4.ip_forward=1"/"net.ipv4.ip_forward=1"/g /etc/sysctl.conf
sysctl -p /etc/sysctl.conf
adduser --system --shell /usr/sbin/nologin --no-create-home openvpn
make-cadir /etc/openvpn/easy-rsa
cd /etc/openvpn/easy-rsa
ln -s /etc/openvpn/easy-rsa/openssl-1.0.0.cnf /etc/openvpn/easy-rsa/openssl.cnf
mkdir /etc/openvpn/easy-rsa/keys
source ./vars
./clean-all
/etc/openvpn/easy-rsa/pkitool --initca $*
/etc/openvpn/easy-rsa/pkitool --server server
openvpn --genkey --secret /etc/openvpn/easy-rsa/keys/ta.key
openssl dhparam -dsaparam 4096 > /etc/openvpn/easy-rsa/keys/dh4096.pem
iptables -t nat -A POSTROUTING -s 10.145.10.0/24 -o $INTERFACE -j SNAT --to $SERVERIP
systemctl enable openvpn.service
systemctl start openvpn.service

# Copy Generic Server Config

cat > /etc/openvpn/server.conf << SERVER_CONFIG
port 3128
proto udp
dev tun
push "redirect-gateway def1"
push "dhcp-option DNS 8.8.8.8"
push "comp-lzo parameter"
ca /etc/openvpn/easy-rsa/keys/ca.crt
cert /etc/openvpn/easy-rsa/keys/server.crt
key /etc/openvpn/easy-rsa/keys/server.key
dh /etc/openvpn/easy-rsa/keys/dh4096.pem
tls-auth /etc/openvpn/easy-rsa/keys/ta.key 0
server 10.145.10.0 255.255.255.0
ifconfig-pool-linear 
ifconfig-pool-persist ipp.txt
keepalive 10 120
cipher AES-256-CBC
comp-lzo
comp-noadapt
user openvpn
group nogroup
persist-key
persist-tun
status openvpn-status.log
verb 3
mode server
tls-server
auth SHA512
tls-cipher TLS-DHE-RSA-WITH-AES-256-GCM-SHA384:TLS-DHE-RSA-WITH-AES-128-GCM-SHA256:TLS-DHE-RSA-WITH-AES-256-CBC-SHA:TLS-DHE-RSA-WITH-CAMELLIA-256-CBC-SHA:TLS-DHE-RSA-WITH-AES-128-CBC-SHA:TLS-DHE-RSA-WITH-CAMELLIA-128-CBC-SHA
SERVER_CONFIG

# Copy Generic Client Config

cat > /etc/openvpn/client.ovpn.tmp << CLIENT_CONFIG
remote $SERVERIP 3128 udp
nobind 
dev tun
persist-tun 
persist-key 
pull 
tls-client 
key-direction 1
auth SHA512
tls-cipher TLS-DHE-RSA-WITH-AES-256-GCM-SHA384:TLS-DHE-RSA-WITH-AES-128-GCM-SHA256:TLS-DHE-RSA-WITH-AES-256-CBC-SHA:TLS-DHE-RSA-WITH-CAMELLIA-256-CBC-SHA:TLS-DHE-RSA-WITH-AES-128-CBC-SHA:TL$
cipher AES-256-CBC
comp-lzo
comp-noadapt
CLIENT_CONFIG

wget https://raw.githubusercontent.com/bobey6/airplane-vpn/master/vpn_usergen.sh
chmod +x vpn_usergen.sh
