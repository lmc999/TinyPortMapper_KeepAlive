![]( https://visitor-badge.glitch.me/badge?page_id=lmc999_tiny)
# 用法
    wget https://raw.githubusercontent.com/lmc999/TinyPortMapper_KeepAlive/master/tinymapper.sh && bash tinymapper.sh

#### 如遇到定时保活脚本不自动执行，可手动创建任务
    crontab -e
    */5 *  *  *  * bash /tinyPortMapper/ip_keepalive.sh
    */2 *  *  *  * bash /tinyPortMapper/domain_keepalive.sh
   #每五分钟执行一次IP转发保活脚本 #每两分钟执行一次域名转发保活脚本
