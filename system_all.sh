#########################################################################
# File Name: system_all.sh
# Author: Mingo
# mail: keminwu.love@gmail.com
# Created Time: Sun 30 Sep 2018 07:53:19 AM CST
#########################################################################

#!/bin/bash
echo "############################ 内存检查 ############################"
    if [[ $centosVersion < 7 ]];then
        free -mo
    else
        free -h
    fi
    #报表信息
    MemTotal=$(grep MemTotal /proc/meminfo| awk '{print $2}')  #KB
    MemFree=$(grep MemFree /proc/meminfo| awk '{print $2}')    #KB
    let MemUsed=MemTotal-MemFree
    MemPercent=$(awk "BEGIN {if($MemTotal==0){printf 100}else{printf \"%.2f\",$MemUsed*100/$MemTotal}}")
    report_MemTotal="$((MemTotal/1024))""MB"        #内存总容量(MB)
    report_MemFree="$((MemFree/1024))""MB"          #内存剩余(MB)
    report_MemUsedPercent="$(awk "BEGIN {if($MemTotal==0){printf 100}else{printf \"%.2f\",$MemUsed*100/$MemTotal}}")""%" 

echo ""
    echo ""
    echo "############################ 磁盘检查 ############################"
    df -hiP | sed 's/Mounted on/Mounted/'> /tmp/inode
    df -hTP | sed 's/Mounted on/Mounted/'> /tmp/disk 
    join /tmp/disk /tmp/inode | awk '{print $1,$2,"|",$3,$4,$5,$6,"|",$8,$9,$10,$11,"|",$12}'| column -t
    #报表信息
    diskdata=$(df -TP | sed '1d' | awk '$2!="tmpfs"{print}') #KB
    disktotal=$(echo "$diskdata" | awk '{total+=$3}END{print total}') #KB
    diskused=$(echo "$diskdata" | awk '{total+=$4}END{print total}')  #KB
    diskfree=$((disktotal-diskused)) #KB
    diskusedpercent=$(echo $disktotal $diskused | awk '{if($1==0){printf 100}else{printf "%.2f",$2*100/$1}}') 
    inodedata=$(df -iTP | sed '1d' | awk '$2!="tmpfs"{print}')
    inodetotal=$(echo "$inodedata" | awk '{total+=$3}END{print total}')
    inodeused=$(echo "$inodedata" | awk '{total+=$4}END{print total}')
    inodefree=$((inodetotal-inodeused))
    inodeusedpercent=$(echo $inodetotal $inodeused | awk '{if($1==0){printf 100}else{printf "%.2f",$2*100/$1}}')
    report_DiskTotal=$((disktotal/1024/1024))"GB"   #硬盘总容量(GB)
    report_DiskFree=$((diskfree/1024/1024))"GB"     #硬盘剩余(GB)
    report_DiskUsedPercent="$diskusedpercent""%"    #硬盘使用率%
    report_InodeTotal=$((inodetotal/1000))"K"       #Inode总量
    report_InodeFree=$((inodefree/1000))"K"         #Inode剩余
    report_InodeUsedPercent="$inodeusedpercent""%"  #Inode使用率%

echo ""
    echo ""
    echo "############################ 系统检查 ############################"
    if [ -e /etc/sysconfig/i18n ];then
        default_LANG="$(grep "LANG=" /etc/sysconfig/i18n | grep -v "^#" | awk -F '"' '{print $2}')"
    else
        default_LANG=$LANG
    fi
    export LANG="en_US.UTF-8"
    Release=$(cat /etc/redhat-release 2>/dev/null)
    Kernel=$(uname -r)
    OS=$(uname -o)
    Hostname=$(uname -n)
    SELinux=$(/usr/sbin/sestatus | grep "SELinux status: " | awk '{print $3}')
    LastReboot=$(who -b | awk '{print $3,$4}')
    uptime=$(uptime | sed 's/.*up \([^,]*\), .*/\1/')
    echo "     系统：$OS"
    echo " 发行版本：$Release"
    echo "     内核：$Kernel"
    echo "   主机名：$Hostname"
    echo "  SELinux：$SELinux"
    echo "语言/编码：$default_LANG"
    echo " 当前时间：$(date +'%F %T')"
    echo " 最后启动：$LastReboot"
    echo " 运行时间：$uptime"
    #报表信息
    report_DateTime=$(date +"%F %T")  #日期
    report_Hostname="$Hostname"       #主机名
    report_OSRelease="$Release"       #发行版本
    report_Kernel="$Kernel"           #内核
    report_Language="$default_LANG"   #语言/编码
    report_LastReboot="$LastReboot"   #最近启动时间
    report_Uptime="$uptime"           #运行时间（天）
    report_Selinux="$SELinux"
    export LANG="$default_LANG"
 echo ""
    echo ""
    echo "############################ 服务检查 ############################"
    echo ""
    if [[ $centosVersion > 7 ]];then
        conf=$(systemctl list-unit-files --type=service --state=enabled --no-pager | grep "enabled")
        process=$(systemctl list-units --type=service --state=running --no-pager | grep ".service")
        #报表信息
        report_SelfInitiatedService="$(echo "$conf" | wc -l)"       #自启动服务数量
        report_RuningService="$(echo "$process" | wc -l)"           #运行中服务数量
    else
        conf=$(/sbin/chkconfig | grep -E ":on|:启用")
        process=$(/sbin/service --status-all 2>/dev/null | grep -E "is running|正在运行")
        #报表信息
        report_SelfInitiatedService="$(echo "$conf" | wc -l)"       #自启动服务数量
        report_RuningService="$(echo "$process" | wc -l)"           #运行中服务数量
    fi
    echo "服务配置"
    echo "--------"
    echo "$conf"  | column -t
    echo ""
    echo "正在运行的服务"
    echo "--------------"
    echo "$process"
echo ""
    echo ""
    echo "############################ 自启动检查 ##########################"
    conf=$(grep -v "^#" /etc/rc.d/rc.local| sed '/^$/d')
    echo "$conf"
    #报表信息
    report_SelfInitiatedProgram="$(echo $conf | wc -l)"    #自启动程序数量

echo ""
    echo ""
    echo "############################ 登录检查 ############################"
    last | head

 echo ""
    echo ""
    echo "############################ 网络检查 ############################"
    if [[ $centosVersion < 7 ]];then
        /sbin/ifconfig -a | grep -v packets | grep -v collisions | grep -v inet6
    else
        #ip a
        for i in $(ip link | grep BROADCAST | awk -F: '{print $2}');do ip add show $i | grep -E "BROADCAST|global"| awk '{print $2}' | tr '\n' ' ' ;echo "" ;done
    fi
    GATEWAY=$(ip route | grep default | awk '{print $3}')
    DNS=$(grep nameserver /etc/resolv.conf| grep -v "#" | awk '{print $2}' | tr '\n' ',' | sed 's/,$//')
    echo ""
    echo "网关：$GATEWAY "
    echo " DNS：$DNS"
    #报表信息
    IP=$(ip -f inet addr | grep -v 127.0.0.1 |  grep inet | awk '{print $NF,$2}' | tr '\n' ',' | sed 's/,$//')
    MAC=$(ip link | grep -v "LOOPBACK\|loopback" | awk '{print $2}' | sed 'N;s/\n//' | tr '\n' ',' | sed 's/,$//')
    report_IP="$IP"            #IP地址
    report_MAC=$MAC            #MAC地址
    report_Gateway="$GATEWAY"  #默认网关
    report_DNS="$DNS"          #DNS
 echo ""
    echo ""
    echo "############################ 监听检查 ############################"
    TCPListen=$(ss -ntul | column -t)
    echo "$TCPListen"
    #报表信息
    report_Listen="$(echo "$TCPListen"| sed '1d' | awk '/tcp/ {print $5}' | awk -F: '{print $NF}' | sort | uniq | wc -l)"
echo ""
    echo ""
    echo "############################ 计划任务检查 ########################"
    Crontab=0
    for shell in $(grep -v "/sbin/nologin" /etc/shells);do
        for user in $(grep "$shell" /etc/passwd| awk -F: '{print $1}');do
            crontab -l -u $user >/dev/null 2>&1
            status=$?
            if [ $status -eq 0 ];then
                echo "$user"
                echo "--------"
                crontab -l -u $user
                let Crontab=Crontab+$(crontab -l -u $user | wc -l)
                echo ""
            fi
        done
    done
    #计划任务
    find /etc/cron* -type f | xargs -i ls -l {} | column  -t
    let Crontab=Crontab+$(find /etc/cron* -type f | wc -l)
    #报表信息
    report_Crontab="$Crontab"    #计划任务数
 
  echo ""
    echo ""
    echo "############################ 软件检查 ############################"
    rpm -qa --last | head | column -t 

  echo ""
    echo ""
    echo "############################ 进程检查 ############################"
    if [ $(ps -ef | grep defunct | grep -v grep | wc -l) -ge 1 ];then
        echo ""
        echo "僵尸进程";
        echo "--------"
        ps -ef | head -n1
        ps -ef | grep defunct | grep -v grep
    fi
    echo ""
    echo "内存占用TOP10"
    echo "-------------"
    echo -e "PID %MEM RSS COMMAND
    $(ps aux | awk '{print $2, $4, $6, $11}' | sort -k3rn | head -n 10 )"| column -t 
    echo ""
    echo "CPU占用TOP10"
    echo "------------"
    top b -n1 | head -17 | tail -11
    #报表信息
    report_DefunctProsess="$(ps -ef | grep defunct | grep -v grep|wc -l)"
