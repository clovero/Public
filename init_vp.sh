#!/bin/sh
set -e

cd /root
wget https://github.com/clovero/Public/raw/main/v.zip
sudo apt install -y unzip
unzip -Pshufudi@2021 v.zip
cd vp

sh get-docker.sh

docker pull kylemanna/openvpn
tar -xf openvpn.tar
OVPN_DATA=$PWD/openvpn
runOpenVpn() {
    port=$1
    type=$2
    docker run -v $OVPN_DATA:/etc/openvpn -d \
      -p "$port:1194/$type" \
      --label vpn_type=openvpn \
      --label vpn_port="$port/$type" \
      --restart=always \
      --cap-add=NET_ADMIN \
      kylemanna/openvpn \
      ovpn_run --proto "$type"
}
runOpenVpn 102 tcp
runOpenVpn 443 tcp
runOpenVpn 8080 tcp
runOpenVpn 107 udp
runOpenVpn 110 udp
runOpenVpn 119 udp
runOpenVpn 443 udp
runOpenVpn 800 udp

# docker build -t ikev2 - < ikev2.tar
# docker run -d \
#   --privileged \
#   -p 500:500/udp \
#   -p 4500:4500/udp \
#   --label vpn_type=ikev2 \
#   --label vpn_port="500/udp,4500/udp" \
#   --restart=always \
#   ikev2 \
#   start-vpn


