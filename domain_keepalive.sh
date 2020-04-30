#!/bin/bash

file='/tinyPortMapper/ddns_record.txt'

#转发记录格式:本地端口+远程端口+域名+IP缓存
#例子:
#65535 65535 abc.com 11.22.33.44

#检查转发记录是否存在
check_txt(){
if [ -f ${file} ]; then
    sleep 1
else
    echo -e "转发记录不存在，即将退出脚本..."
exit 1

fi
}

run_record(){
while read -r line || [[ -n $line ]];do
port1=$(echo $line | awk '!/#/{printf$1"\n"}')
port2=$(echo $line | awk '!/#/{printf$2"\n"}')
domain=$(echo $line | awk '!/#/{printf$3"\n"}')
ip_old=$(echo $line | awk '!/#/{printf$4"\n"}')
ip_new=$(nslookup ${domain}|grep Add |awk '!/#/{printf$2"\n"}')
pid=$(ps -aux | grep ${port1} |grep -v grep |awk '!/#/{printf$2"\n"}')
	
keep_alive
	
done < ${file}
}

keep_alive(){
if [ $ip_new = $ip_old ]
then
    check_alive

else
    echo -e "转发记录IP已更新，正在重新配置转发"
    kill -9 ${pid}
    sleep 1
    nohup /tinyPortMapper/tinymapper -l 0.0.0.0:${port1} -r ${ip_new}:${port2} -t -u > /root/tinymapper.log 2>&1 &
    sed -i 's/'$ip_old'/'$ip_new'/g' ${file} #用新解析IP替换旧的记录

	
fi
}

check_alive(){
if [ -n "${pid}" ]
then
    echo -e "转发记录正常"
	
else
    echo -e "转发记录不存在，正在重新配置转发"
    nohup /tinyPortMapper/tinymapper -l 0.0.0.0:${port1} -r ${ip_new}:${port2} -t -u > /root/tinymapper.log 2>&1 &
    sed -i 's/'$ip_old'/'$ip_new'/g' ${file} #用新解析IP替换旧的记录
fi
}


check_txt
run_record




