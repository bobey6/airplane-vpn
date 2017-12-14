#!/bin/bash


cd /etc/openvpn/easy-rsa

read -p "Please type a name for the new config:" VPN_USER

[ -z ${VPN_USER} ] && { echo "Cannot be empty"; exit 1; }

[ -f keys/${VPN_USER}.crt ] && { echo "Certificate keys/${VPN_USER}.crt already exists"; exit 2; }

source ./vars

/etc/openvpn/easy-rsa/pkitool ${VPN_USER}

cp /etc/openvpn/client.ovpn.tmp /tmp/$VPN_USER.ovpn

echo -e "<ca>" >> /tmp/$VPN_USER.ovpn
cat //etc/openvpn/easy-rsa/keys/ca.crt >> /tmp/$VPN_USER.ovpn
echo -e "</ca>" >> /tmp/$VPN_USER.ovpn

echo -e "<cert>" >> /tmp/$VPN_USER.ovpn
cat /etc/openvpn/easy-rsa/keys/${VPN_USER}.crt | tail -n 31 >> /tmp/$VPN_USER.ovpn
echo -e "</cert>" >> /tmp/$VPN_USER.ovpn

echo -e "<key>" >> /tmp/$VPN_USER.ovpn
cat /etc/openvpn/easy-rsa/keys/${VPN_USER}.key >> /tmp/$VPN_USER.ovpn
echo -e "</key>" >> /tmp/$VPN_USER.ovpn

echo -e "<tls-auth>" >> /tmp/$VPN_USER.ovpn
cat /etc/openvpn/easy-rsa/keys/ta.key >> /tmp/$VPN_USER.ovpn
echo -e "</tls-auth>" >> /tmp/$VPN_USER.ovpn >> /tmp/$VPN_USER.ovpn

echo "Your OpenVPN client configuration is located at /tmp/$VPN_USER"

