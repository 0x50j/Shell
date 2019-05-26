#########################################################################
# File Name: system_cat.sh
# Author: Mingo
# mail: keminwu.love@gmail.com
# Created Time: Sun 30 Sep 2018 07:53:19 AM CST
#########################################################################

#!/bin/bash
Running=`ps -ef | wc -l`
Users=`who | wc -l`
Filesystem=`df -Th | grep "/dev/vda1" | awk '{print $6}'`
Filedata=`df -Th | grep "/dev/vdb1" | awk '{print $6}'`
MenTotal=`free | grep "Mem" | awk '{print $2}'`
MenUsed=`free | grep "Mem" | awk '{print $3}'`
Mem=`echo "scale=2; $MenUsed / $MenTotal * 100" | bc | awk -F . '{print $1}'`
#用户空间占用CPU百分比
us=`top -b -n 1 | grep "Cpu(s):" | awk '{print $2}' | awk -F % '{print $1}' | sed s/[[:space:]]//g`
#内核空间占用CPU百分比
sy=`top -b -n 1 | grep "Cpu(s):" | awk -F , '{print $2}' | awk -F % '{print $1}' | sed s/[[:space:]]//g`
#用户进程空间内改变过优先级的进程占用CPU百分比
ni=`top -b -n 1 | grep "Cpu(s):" | awk -F , '{print $3}' | awk -F % '{print $1}' | sed s/[[:space:]]//g`
#等待输入输出的CPU时间百分比
wa=`top -b -n 1 | grep "Cpu(s):" | awk -F , '{print $5}' | awk -F % '{print $1}' | sed s/[[:space:]]//g`
CPU=`echo "scale=0; $us + $sy + $ni + $wa" | bc | awk -F . '{print $1}'`

if [[ $CPU -gt 80 ]]; then
	echo -e "\033[41;30m CPU:$CPU%     \c \033[0m"
else
	echo -e "\033[42;30m CPU:$CPU%     \c \033[0m"
fi

if [[ $Mem -gt 80 ]]; then
	echo -e "\033[41;30m Men:$Mem%     \c \033[0m"
else
	echo -e "\033[42;30m Men:$Mem%     \c \033[0m"
fi

if [[ $Filesystem > "80%" ]]; then
	echo -e "\033[41;30m File:$Filesystem $Filedata \033[0m"
else
	echo -e "\033[42;30m File:$Filesystem $Filedata \033[0m"
fi

if [[ $Running -gt 250 ]]; then
echo -e "\033[41;30m Running Proceses: $Running     \c \033[0m"
else
echo -e "\033[42;30m Running Proceses: $Running     \c \033[0m"
fi

if [[ $Users -gt 1 ]]; then
	echo -e "\033[41;30m Login Users: $Users user \033[0m"
else
	echo -e "\033[42;30m Login Users: $Users user \033[0m"
fi

echo ""
