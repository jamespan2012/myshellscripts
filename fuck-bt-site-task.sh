#!/bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH
Green_font="\033[32m" && Red_font="\033[31m" && Font_suffix="\033[0m"
Info="${Green_font}[Info]${Font_suffix}"
Error="${Red_font}[Error]${Font_suffix}"
echo -e "${Green_font}
#======================================
# Project: fuck-bt-site-task
# Version: 0.0.1
# Blog:    https://vpsxb.net/2126/
#======================================
${Font_suffix}"

check_root(){
	[[ "`id -u`" != "0" ]] && echo -e "${Error} must be root user !" && exit 1
}

install(){
	cp /www/server/panel/script/site_task.py /www/server/panel/script/fuck-btst
	chmod 400 /www/server/panel/script/fuck-btst
	chattr +i /www/server/panel/script/fuck-btst
	echo "" > /www/server/panel/script/site_task.py
	chattr +i /www/server/panel/script/site_task.py
	rm -rf /www/server/panel/logs/request/*
	chattr +i -R /www/server/panel/logs/request
	
}

uninstall(){
	
	chattr -i /www/server/panel/script/fuck-btst /www/server/panel/script/site_task.py
	rm -f /www/server/panel/script/site_task.py
	mv /www/server/panel/script/fuck-btst /www/server/panel/script/site_task.py
	chmod 700 /www/server/panel/script/site_task.py
	chattr -i -R /www/server/panel/logs/request

}

check_root

echo -e "${Info} 选择功能(退出脚本:Ctrl+c): "
echo -e "1.启用并备份\n2.恢复初始状态"
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
