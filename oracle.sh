#!/bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH
Green_font="\033[32m" && Red_font="\033[31m" && Font_suffix="\033[0m"
Info="${Green_font}[Info]${Font_suffix}"
Error="${Red_font}[Error]${Font_suffix}"
echo -e "${Green_font}
#======================================
# Project: oracle firewall
# Version: 0.0.1
# 推荐机场:   垃圾场加速器
# 注册地址:   https://lajic.eu/index.php#/register?code=OAM8uBQl
#======================================
${Font_suffix}"

check_root(){
	[[ "`id -u`" != "0" ]] && echo -e "${Error} must be root user !" && exit 1
}

allin(){
	
	cat>/etc/allin.sh<<EOF
#!/usr/bin/env bash
sudo iptables -P INPUT ACCEPT
sudo iptables -P FORWARD ACCEPT
sudo iptables -P OUTPUT ACCEPT
sudo iptables -F
EOF
	chmod +x /etc/allin.sh
}

system(){
	
	echo "[Unit]
Description=Run a Custom Script at Startup
After=default.target
 
[Service]
ExecStart=/etc/allin.sh 
 
[Install]
WantedBy=default.target" > /etc/systemd/system/allin.service

}

startit(){
	
	systemctl daemon-reload
	systemctl enable allin.service
	systemctl restart allin.service
	
}

install(){
	
	allin
	system
	startit
	
}

uninstall(){
	
	systemctl disable allin.service
	systemctl stop allin.service
	rm /etc/systemd/system/allin.service
	rm /etc/allin.sh
	systemctl daemon-reload

}

check_root

echo -e "${Info} 选择你要使用的功能: "
echo -e "1.永久放行全部端口\n2.恢复初始状态"
read -p "输入数字以选择:" function

	while [[ ! "${function}" =~ ^[1-2]$ ]]
		do
			echo -e "${Error} 缺少或无效输入"
			echo -e "${Info} 请重新选择" && read -p "输入数字以选择:" function
		done

	if [[ "${function}" == "1" ]]; then
		install
	elif [[ "${function}" == "2" ]]; then
		uninstall
	else
		echo -e "${Info} 请重新选择" && read -p "输入数字以选择:" function
	fi
