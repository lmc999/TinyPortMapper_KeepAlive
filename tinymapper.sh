#! /bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

# =========================================================
# System Request:CentOS 6+ 、Debian 7+、Ubuntu 14+
# Origin Author:Rat's
# Blog: https://www.moerats.com
# Modified by: lmc999
# Dscription: tinyPortMapper一键脚本
# Version: 2.3
# Github:https://github.com/lmc999/TinyPortMapper_KeepAlive
# =========================================================

Green="\033[32m"
Font="\033[0m"
Blue="\033[33m"

rootness(){
    if [[ $EUID -ne 0 ]]; then
       echo "Error:This script must be run as root!" 1>&2
       exit 1
    fi
}

checkos(){
    if [[ -f /etc/redhat-release ]];then
        OS=CentOS
    elif cat /etc/issue | grep -q -E -i "debian";then
        OS=Debian
    elif cat /etc/issue | grep -q -E -i "ubuntu";then
        OS=Ubuntu
    elif cat /etc/issue | grep -q -E -i "centos|red hat|redhat";then
        OS=CentOS
    elif cat /proc/version | grep -q -E -i "debian";then
        OS=Debian
    elif cat /proc/version | grep -q -E -i "ubuntu";then
        OS=Ubuntu
    elif cat /proc/version | grep -q -E -i "centos|red hat|redhat";then
        OS=CentOS
    else
        echo "Not supported OS, Please reinstall OS and try again."
        exit 1
    fi
}

disable_selinux(){
    if [ -s /etc/selinux/config ] && grep 'SELINUX=enforcing' /etc/selinux/config; then
        sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
        setenforce 0
    fi
}

config_ip(){
    echo -e "${Green}请输入tinyPortMapper配置信息！${Font}"
    read -p "请输入本地监听端口:" port1
    read -p "请输入远端转发端口:" port2
    read -p "请输入被转发IP:" TartgetIP
}

config_domain(){
    echo -e "${Green}请输入tinyPortMapper配置信息！${Font}"
    read -p "请输入本地监听端口:" port1
    read -p "请输入远端转发端口:" port2
    read -p "请输入被转发域名:" TartgetDomain
}

#删除转发规则
delete_rule(){
    echo -e "${Green}请输入需要删除的转发规则信息！${Font}"
    read -p "请输入被删除规则的对应本地端口:" port
	
	pid=$(ps -aux | grep ${port} |grep -v grep |awk '!/#/{printf$2"\n"}')
	
	kill -9 ${pid}
    sleep 1
	
	sed -i '/'${port}'/d' /tinyPortMapper/record.txt
	sed -i '/'${port}'/d' /tinyPortMapper/ddns_record.txt
	if [ "${OS}" == 'CentOS' ];then
	    sed -i '/'${port}'/d' /etc/rc.d/rc.local
	else
	    sed -i '/'${port}'/d' /etc/rc.local
	fi
	
	echo -e "${Blue}转发规则删除成功！${Font}"
}
#配置IP转发开机自启动
tinyPortMapper_ip(){
    echo -e "${Green}正在配置tinyPortMapper...${Font}"
    nohup /tinyPortMapper/tinymapper -l 0.0.0.0:${port1} -r ${TartgetIP}:${port2} -t -u > /root/tinymapper.log 2>&1 &
    if [ "${OS}" == 'CentOS' ];then
        sed -i '/exit/d' /etc/rc.d/rc.local
        echo "nohup /tinyPortMapper/tinymapper -l 0.0.0.0:${port1} -r ${TartgetIP}:${port2} -t -u > /root/tinymapper.log 2>&1 & " >> /etc/rc.d/rc.local
        chmod +x /etc/rc.d/rc.local
    elif [ -s /etc/rc.local ]; then
        sed -i '/exit/d' /etc/rc.local
        echo "nohup /tinyPortMapper/tinymapper -l 0.0.0.0:${port1} -r ${TartgetIP}:${port2} -t -u > /root/tinymapper.log 2>&1 & " >> /etc/rc.local
        chmod +x /etc/rc.local
    else
echo -e "${Green}检测到系统无rc.local自启，正在为其配置... ${Font} "
echo "[Unit]
Description=/etc/rc.local
ConditionPathExists=/etc/rc.local
 
[Service]
Type=forking
ExecStart=/etc/rc.local start
TimeoutSec=0
StandardOutput=tty
RemainAfterExit=yes
SysVStartPriority=99
 
[Install]
WantedBy=multi-user.target
" > /etc/systemd/system/rc-local.service
echo "#!/bin/sh -e
#
# rc.local
#
# This script is executed at the end of each multiuser runlevel.
# Make sure that the script will "exit 0" on success or any other
# value on error.
#
# In order to enable or disable this script just change the execution
# bits.
#
# By default this script does nothing.
" > /etc/rc.local
echo "nohup /tinyPortMapper/tinymapper -l 0.0.0.0:${port1} -r ${TartgetIP}:${port2} -t -u > /root/tinymapper.log 2>&1 & " >> /etc/rc.local
chmod +x /etc/rc.local
systemctl enable rc-local >/dev/null 2>&1
systemctl start rc-local >/dev/null 2>&1
    fi
    sleep 3
    echo
    echo -e "${Blue}tinyPortMapper安装并配置成功!${Font}"
    echo -e "${Blue}请使用命令'ps -aux | grep tinymapper'自行查看目前所有转发进程${Font}"    
    exit 0
}

#配置域名转发开机自启动
tinyPortMapper_domain(){
    echo -e "${Green}正在配置tinyPortMapper...${Font}"
    nohup /tinyPortMapper/tinymapper -l 0.0.0.0:${port1} -r $(nslookup ${TartgetDomain}|grep Add |awk '!/#/{printf$2"\n"}'):${port2} -t -u > /root/tinymapper.log 2>&1 &
    if [ "${OS}" == 'CentOS' ];then
        sed -i '/exit/d' /etc/rc.d/rc.local
        echo "nohup /tinyPortMapper/tinymapper -l 0.0.0.0:${port1} -r \$(nslookup $TartgetDomain |grep Add |awk '!/#/{printf\$2\"\\n\"}'):${port2} -t -u > /root/tinymapper.log 2>&1 & " >> /etc/rc.d/rc.local
        chmod +x /etc/rc.d/rc.local
    elif [ -s /etc/rc.local ]; then
        sed -i '/exit/d' /etc/rc.local
        echo "nohup /tinyPortMapper/tinymapper -l 0.0.0.0:${port1} -r \$(nslookup $TartgetDomain |grep Add |awk '!/#/{printf\$2\"\\n\"}'):${port2} -t -u > /root/tinymapper.log 2>&1 & " >> /etc/rc.local
        chmod +x /etc/rc.local
    else
echo -e "${Green}检测到系统无rc.local自启，正在为其配置... ${Font} "
echo "[Unit]
Description=/etc/rc.local
ConditionPathExists=/etc/rc.local
 
[Service]
Type=forking
ExecStart=/etc/rc.local start
TimeoutSec=0
StandardOutput=tty
RemainAfterExit=yes
SysVStartPriority=99
 
[Install]
WantedBy=multi-user.target
" > /etc/systemd/system/rc-local.service
echo "#!/bin/sh -e
#
# rc.local
#
# This script is executed at the end of each multiuser runlevel.
# Make sure that the script will "exit 0" on success or any other
# value on error.
#
# In order to enable or disable this script just change the execution
# bits.
#
# By default this script does nothing.
" > /etc/rc.local
echo "nohup /tinyPortMapper/tinymapper -l 0.0.0.0:${port1} -r \$(nslookup $TartgetDomain |grep Add |awk '!/#/{printf\$2\"\\n\"}'):${port2} -t -u > /root/tinymapper.log 2>&1 & " >> /etc/rc.local
chmod +x /etc/rc.local
systemctl enable rc-local >/dev/null 2>&1
systemctl start rc-local >/dev/null 2>&1
    fi
    sleep 3
    echo
    echo -e "${Blue}tinyPortMapper安装并配置成功!${Font}"
    echo -e "${Blue}请使用命令'ps -aux | grep tinymapper'自行查看目前所有转发进程${Font}" 
    exit 0
}

mark_IPRecord(){
echo "${port1} ${port2} ${TartgetIP}" >> /tinyPortMapper/record.txt
}

mark_DomainRecord(){
echo "${port1} ${port2} ${TartgetDomain} $(nslookup ${TartgetDomain}|grep Add |awk '!/#/{printf$2"\n"}')" >> /tinyPortMapper/ddns_record.txt
}

#安装依赖
Install_dependencies(){
    if [[ "${OS}" == 'CentOS' ]]
then
    echo -e "${Blue}正在安装相关依赖...${Font}"
	yum install -y bind-utils curl vixie-cron
	systemctl stop firewalld.service >/dev/null 2>&1
    systemctl disable firewalld.service >/dev/null 2>&1
else
    echo -e "${Blue}正在安装相关依赖...${Font}"
	apt-get install -y cron curl dnsutils
fi

}
	

set_forwardmethod(){
    echo -e "${Green}选择脚本功能！${Font}"
	echo -e "${Blue}1. 添加IP转发！${Font}"
	echo -e "${Blue}2. 添加域名转发！(支持DDNS)${Font}"	
	echo -e "${Blue}3. 删除转发规则！${Font}"
	echo -e "${Blue}4. 退出脚本${Font}"		
	echo 
	read -p "Please enter a number:" num
	case "$num" in
    1)
	checkos
    config_ip
    mark_IPRecord
    tinyPortMapper_ip
    ;;
    2)
	checkos
    config_domain
    mark_DomainRecord
    tinyPortMapper_domain
    ;;
	 3)
	checkos
    delete_rule
    ;;
    4)
    exit 1
    ;;
    *)
    clear
    Blue "Please enter the correct number!"
    sleep 1
    set_forwardmethod
    ;;
    esac
}
	


Install_tinyPortMapper(){
echo -e "${Green}即将安装tinyPortMapper...${Font}"
#获取最新版本号
#tinyPortMapper_ver=$(wget --no-check-certificate -qO- https://api.github.com/repos/wangyu-/tinyPortMapper/releases | grep -o '"tag_name": ".*"' |head -n 1| sed 's/"//g' | sed 's/tag_name: //g') && echo ${tinyPortMapper_ver}
#下载tinyPortMapper
#wget -N --no-check-certificate "https://github.com/wangyu-/tinyPortMapper/releases/download/${tinyPortMapper_ver}/tinymapper_binaries.tar.gz"
wget -N --no-check-certificate "https://github.com/wangyu-/tinyPortMapper/releases/download/20180224.0/tinymapper_binaries.tar.gz"
#解压tinyPortMapper
tar -xzf tinymapper_binaries.tar.gz
mkdir /tinyPortMapper
KernelBit="$(getconf LONG_BIT)"
    if [[ "$KernelBit" == '32' ]];then
        mv tinymapper_x86 /tinyPortMapper/tinymapper
    elif [[ "$KernelBit" == '64' ]];then
        mv tinymapper_amd64 /tinyPortMapper/tinymapper
    fi
    if [ -f /tinyPortMapper/tinymapper ]; then
    echo -e "${Green}tinyPortMapper安装成功！${Font}"
    else
    echo -e "${Green}tinyPortMapper安装失败！${Font}"
    exit 1
    fi
#授可执行权
chmod +x /tinyPortMapper/tinymapper
#删除无用文件
rm -rf version.txt
rm -rf tinymapper_*
}

status_tinyPortMapper(){
    if [ -f /tinyPortMapper/tinymapper ]; then
    echo -e "${Green}检测到tinyPortMapper已存在，并跳过安装步骤！${Font}"
	rootness
    check_sh
	set_forwardmethod
    else
	rootness
	checkos
	disable_selinux
    Install_dependencies
    Install_tinyPortMapper
	check_sh
	set_cronjob
    set_forwardmethod
		
    fi
}

#下载保活脚本
check_sh(){
if [ -f "/tinyPortMapper/ip_keepalive.sh" -a -f "/tinyPortMapper/domain_keepalive.sh" ]; then
    echo -e "${Green}检测到保活脚本已存在，跳过下载步骤！${Font}"
else
    echo -e "${Green}正在下载保活脚本！${Font}"
    wget -O /tinyPortMapper/ip_keepalive.sh https://raw.githubusercontent.com/lmc999/TinyPortMapper_KeepAlive/master/ip_keepalive.sh
    wget -O /tinyPortMapper/domain_keepalive.sh https://raw.githubusercontent.com/lmc999/TinyPortMapper_KeepAlive/master/domain_keepalive.sh
	
fi
}

#创建定时任务，保活转发规则并检查DDNS IP更新
set_cronjob(){
echo "*/5 * * * * root bash /tinyPortMapper/ip_keepalive.sh" >> /etc/crontab
echo "*/2 * * * * root bash /tinyPortMapper/domain_keepalive.sh" >> /etc/crontab

}

status_tinyPortMapper
