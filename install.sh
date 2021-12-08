#!/bin/bash
check_root(){
    if [[ "$EUID" -ne '0' ]]; then
		echo -e "\033[31m error: You must run this script as root! \033[0m"
        exit 1
    fi
}

check_system_and_install_deps(){
    if [[ "$(type -P apt)" ]]; then
        apt update
        apt install wget curl unzip ca-certificates -y 
    elif [[ "$(type -P yum)" ]]; then
        yum update -y
        yum install wget curl unzip ca-certificates -y 
    fi
}
install_bin(){
  mkdir -p /opt/xray
  XRAY_FILE="Xray-linux-${arch}.zip"
	echo -e "\033[32m Downloading binary file: ${XRAY_FILE} \033[0m"
  if [ "$mirror" = "github" ]; then
      echo $mirror
      XRAY_BIN_URL="https://github.com/flyzstu/dist/raw/main/${XRAY_FILE}"
  else
      XRAY_BIN_URL="https://cdn.jsdelivr.net/gh/flyzstu/dist/${XRAY_FILE}"
  fi

	wget -qO ${PWD}/Xray.zip $XRAY_BIN_URL --progress=bar:force

    unzip -d /tmp/Xray Xray.zip
    chmod +x /tmp/Xray/xray
    mv /tmp/Xray/xray /opt/xray/
    rm -rf Xray.zip /tmp/Xray


	echo -e "\033[32m ${XRAY_FILE} has been downloaded \033[0m"
}

install_dat(){
	wget -qO /opt/xray/geoip.dat https://cdn.jsdelivr.net/gh/Loyalsoldier/v2ray-rules-dat@release/geoip.dat
	wget -qO /opt/xray/geosite.dat https://cdn.jsdelivr.net/gh/Loyalsoldier/v2ray-rules-dat@release/geosite.dat
	echo -e "\033[32m .dat has been downloaded! \033[0m"
}
install_service(){
  if [ ! -f /etc/systemd/system/xray.service ];then
      cat << EOF > /etc/systemd/system/xray.service
[Unit]
Description=Xray Service
Documentation=https://github.com/xtls
After=network.target nss-lookup.target
[Service]
User=root
ExecStart=/opt/xray/xray
Restart=on-failure
RestartPreventExitStatus=23
LimitNPROC=10000
LimitNOFILE=1000000
[Install]
WantedBy=multi-user.target
EOF
  fi
  echo -e "\033[32m Enable xray service.. \033[0m"
  systemctl enable xray.service
  echo -e "\033[31m Please after install /opt/xray/config.json \033[0m"
  echo -e "\033[31m \"systemctl start xray.service\" \033[0m"

}

func(){
  echo "Usage:"
  echo "install [-m mirror] [-a arch] [-i install] [-u update]"
  echo "Description:"
  echo "-m, --mirror: mirror of github or cloudflare" 
  echo "-a, --arch: amd64, arm64-v8a or anything else"
  echo "-i, --install: install xray"
  echo "-u, --update: update xray"
  exit -1
}

update_xray(){
  echo -e "\033[32m You are updating xray.. \033[0m"
  check_root
  install_bin
  install_dat
  service xray restart
}

install_xray(){
  echo -e "\033[32m You are installing xray.. \033[0m"
  check_root
  check_system_and_install_deps
  install_bin
  install_dat
  install_service
}

while [ -n "$1" ]  
do  
  case "$1" in   
    -m|--mirror)
        mirror=$2
        shift 
        ;;  
    -a|--arch)  
        arch=$2
        shift   
        ;;  
    -i|--install)
      contrl="install"
        ;;  
    -u|--update)
      contrl="update"
        ;;
    -h|--help)
        func
        ;; 
    *)  
        echo -e "\033[32m Please run ./install --help to get some help. \033[0m"
        exit 0  
        ;;  
  esac  
  shift  
done

if [[ -z "$mirror" ]];then
  mirror="github"
fi
if [[ -z "$arch" ]];then
  arch="64"
fi
if [[ -z "$contrl" ]];then
  contrl="install"
fi

if [[ $contrl = "install" ]];then
  install_xray
elif [[ $contrl = "update" ]];then
  update_xray
fi