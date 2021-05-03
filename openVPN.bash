#!/bin/bash

IP=`hostname -I | awk '{print $1}'`
pass_openvpn=$1            # openvpn user


#Function to create Random Password
function randpass() {
cat /dev/urandom | tr -cd _A-Z-a-z-0-9 | head -c 15
echo
}
#Get Random Password to rootnewpass variable

if [ -z $pass_openvpn ]
then
  echo "Missing argument...Using generate password"
  #echo "Example: ./openvpn.sh <Password root>"
  pass_openvpn=`randpass`
fi


#Change password admin
echo -e "$pass_openvpn\n$pass_openvpn" | passwd openvpn

#Export Info OpenVPN
cat > /root/OpenVPN.txt << EOT
#ADMIN
IP: https://$IP:943/admin
User: openvpn
Pass: $pass_openvpn

#CLIENT
IP: https://$IP:943
User: openvpn
Pass: $pass_openvpn
EOT

#rebuild network hostname
echo -e "DELETE\nyes\n\n1\n\n\n\n\n\nno\n\n" | /usr/local/openvpn_as/bin/ovpn-init

rm -f /root/OpenVPN.sh
