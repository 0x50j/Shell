#########################################################################
# File Name: CC_Attack.sh
# Author: Mingo
# mail: keminwu.love@gmail.com
# Created Time: Sun 30 Sep 2018 07:53:19 AM CST
#########################################################################

#!/bin/bash

#定义访问日志的路径
Log_Path=/var/log/nginx/access.log

#定义临时存放一分钟之前的日志文件路径
Tmp_Log=/tmp/tmp_last_min.log
#定义一个存放一分钟访问量高于10次的IP地址临时文件
Tmp_IP=/tmp/tmp_ip

#定义防御攻击脚本的日志
Attack_Log=/var/log/nginx/attack.log



################################
#统计一分钟之前的日志相关信息的方法
################################
AccessLog()
{
	
	#将一分钟之前的日志输出到一个临时的文件中
	egrep "$OneMinAgo:[0-5]+" $Log_Path > $Tmp_Log
	#将这一分钟的日志输出到一个临时的文件中
	egrep "$NowTime:[0-5]+" $Log_Path >> $Tmp_Log

}



####################################################
#将一分钟内访问次数超过10次的IP转发到另外的一个页面的方法
####################################################
Block_IP()
{

	#把一分钟内访问超过10次的IP地址统计到一个临时文件中
	awk '{print $1,$6}' $Tmp_Log | awk -F'requesthost:"|";' '{print $1,$2}' | sort -n | uniq -c | awk '$1>10 {print $2,$3}' > $Tmp_IP
	#重写Tmp_IP文件格式
	sed -i 's/[ ][ ]*/,/g' $Tmp_IP
	#统计将要转发的IP个数
	count=`wc -l $Tmp_IP | awk '{ print $1 }'`

	#判断IP数量是否大于0
	if [ $count -ne 0 ]
	then
		for recording in `cat $Tmp_IP`
		do
			ip=`echo $recording | awk -F',' '{print $1}'`
			domain=`echo $recording | awk -F',' '{print $2}'`
			#添加规则将请求转发到其他服务器上的80和443端口
			iptables -I FORWARD -s $ip  -j ACCEPT
			iptables -t nat -I POSTROUTING -s $ip -j SNAT --to-source 172.31.243.145
			iptables -t nat -I PREROUTING -i eth0 -p tcp -s $ip --dport 80 -j DNAT --to-destination 112.74.169.181:80
			iptables -t nat -I PREROUTING -i eth0 -p tcp -s $ip --dport 443 -j DNAT --to-destination 112.74.169.181:443
			#将IP记录到日志文件当中
			echo "`date` [INFO] $ip -- $domain Too many requests Forward Warning Page !" >> $Attack_Log
		done
	fi

}



#########################
#解封一分钟之前的IP地址方法
#########################
UnBlock_IP()
{

	#统计之前被转发的IP个数
	count=`wc -l $Tmp_IP | awk '{ print $1 }'`

	#判断IP数量是否大于0
	if [ $count -ne 0 ]
	then
		for ip in `cat $Tmp_IP | awk -F',' '{ print $1 }'`
		do
			#将请求转发到警告服务器上的80和443端口的规则移除
			iptables -D FORWARD -s $ip  -j ACCEPT
			iptables -t nat -D POSTROUTING -s $ip -j SNAT --to-source 172.31.243.145
			iptables -t nat -D PREROUTING -i eth0 -p tcp -s $ip --dport 80 -j DNAT --to-destination 112.74.169.181:80
			iptables -t nat -D PREROUTING -i eth0 -p tcp -s $ip --dport 443 -j DNAT --to-destination 112.74.169.181:443
			#将IP记录到日志文件当中
			echo "`date` [INFO] $ip -- Delimitation time !" >> $Attack_Log
		done
	fi

}



#########
#程序主体
#########
while true

	#定义一分钟之前的时间
	OneMinAgo=`date -d "-1 min" +%Y:%H:%M`
	#定义目前的时间
	NowTime=`date +%Y:%H:%M`

	#执行解除转发规则方法
	UnBlock_IP
	sleep 3s
	
	#执行统计方法
	AccessLog
	sleep 5s

	#执行转发规则方法
	Block_IP
	#统计将要转发的IP个数
	if [ `wc -l $Tmp_IP | awk '{ print $1 }'` -ne 0 ]
	then
		sleep 50s
	else
		sleep 2s
	done

done	