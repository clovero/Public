#!/bin/sh
set -e

cd /root

# clean all
rm -f init_vp.sh
rm -f v.zip
rm -rf vp
rm -rf openvpn

wget https://github.com/clovero/Public/raw/main/v.zip
sudo apt install -y unzip
unzip -Pshufudi@2021 v.zip
cd vp
tar -xf openvpn.tar

if ! command -v docker > /dev/null; then
    echo "docker not exist! start install..."
    sh get-docker.sh
fi

docker pull kylemanna/openvpn

OVPN_DATA=$PWD/openvpn
runOpenVpn() {
    port=$1
    type=$2
    container_name="openvpn_$type$port"
    docker start $container_name 2>/dev/null || docker run --name $container_name \
      -v $OVPN_DATA:/etc/openvpn -d \
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

cd /root
cat > 'config.json' << 'EOF'
{
  "log": {
    "loglevel": "warning",
    "access": "/dev/null",
    "error": "/dev/null"
  },
  "inbounds": [
    {
      "port": 51888,
      "protocol": "shadowsocks",
      "settings": {
        "method": "aes-256-gcm",
        "password": "UHDFU#231skfnEE$",
        "network": "tcp,udp",
        "level": 0
      }
    }
  ],
  "outbounds": [
    {
      "protocol": "freedom",
      "settings": {},
      "tag": "allowed"
    },
    {
      "protocol": "blackhole",
      "settings": {},
      "tag": "blocked"
    }
  ],
  "routing": {
    "rules": [
      {
        "domain": [
          "google.com",
          "apple.com",
          "oppomobile.com"
        ],
        "type": "field",
        "outboundTag": "allowed"
      },
      {
        "type": "field",
        "ip": [
          "geoip:private"
        ],
        "outboundTag": "blocked"
      }
    ]
  }
}
EOF

docker start v2ray 2>/dev/null || docker run -d --name v2ray \
  --restart=always \
  -v /root/config.json:/etc/v2ray/config.json \
  -p 51888:51888 v2fly/v2fly-core run \
  -c /etc/v2ray/config.json


