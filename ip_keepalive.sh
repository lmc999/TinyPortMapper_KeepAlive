#!/bin/bash

file=/tinyPortMapper/record.txt


#转发记录格式:本地端口+远程端口+IP
#例子:
#65535 65535 11.22.33.44

#检查转发记录是否存在
check_txt(){
if [ -f ${file} ]; then
    sleep 1
else
    echo -e "转发记录不存在，即将退出脚本..."
        exit 1
fi
}

check_alive(){
while read -r line || [[ -n $line ]];do
    port1=$(echo $line | awk '!/#/{printf$1"\n"}')
	port2=$(echo $line | awk '!/#/{printf$2"\n"}')
    ip=$(echo $line | awk '!/#/{printf$3"\n"}')
    pid=$(ps -aux | grep '${port1)' |grep -v grep |awk '!/#/{printf$2"\n"}')
if [ -n "${pid}" ]
then
    echo -e "转发记录正常"

else
    echo -e "转发记录不存在，正在添加中..."
    nohup /tinyPortMapper/tinymapper -l 0.0.0.0:${port1} -r ${ip}:${port2} -t -u > /root/tinymapper.log 2>&1 &


fi

done < ${file}
}





check_txt
check_alive
