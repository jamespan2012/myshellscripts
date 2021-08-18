#!/usr/bin/env bash
#
# Description: Auto system info & I/O test & network to China script
#

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
SKYBLUE='\033[0;36m'
PLAIN='\033[0m'

about() {
	echo ""
	echo " ========================================================= "
	echo " \                 Superbench.sh  Script                 / "
	echo " \       Basic system info, I/O test and speedtest       / "
	echo " \                   v1.3.0 (2021-05-26)                 / "
	echo " ========================================================= "
	echo ""
	echo ""
}

cancel() {
	echo ""
	next;
	echo " Abort ..."
	echo " Cleanup ..."
	cleanup;
	echo " Done"
	exit
}

trap cancel SIGINT

benchinit() {
	if [ -f /etc/redhat-release ]; then
	    release="centos"
	elif cat /etc/issue | grep -Eqi "debian"; then
	    release="debian"
	elif cat /etc/issue | grep -Eqi "ubuntu"; then
	    release="ubuntu"
	elif cat /etc/issue | grep -Eqi "centos|red hat|redhat"; then
	    release="centos"
	elif cat /proc/version | grep -Eqi "debian"; then
	    release="debian"
	elif cat /proc/version | grep -Eqi "ubuntu"; then
	    release="ubuntu"
	elif cat /proc/version | grep -Eqi "centos|red hat|redhat"; then
	    release="centos"
	fi

	[[ $EUID -ne 0 ]] && echo -e "${RED}Error:${PLAIN} This script must be run as root!" && exit 1

	if  [ ! -e '/usr/bin/python' ]; then
		echo " Installing Python ..."
		if [ "${release}" == "centos" ]; then
			#yum update > /dev/null 2>&1
			os_version=$(cat /etc/redhat-release | awk -F'.' '{print $1}' | awk -F' ' '{print $4}')
			if [ "${os_version}" == "8" ]; then
				if  [ ! -e '/bin/python2' ]; then
					yum -y install python2 > /dev/null 2>&1
				fi
				ln -s /bin/python2 /bin/python
			else
				yum -y install python > /dev/null 2>&1
			fi
		else
			apt-get update > /dev/null 2>&1
			apt-get -y install python > /dev/null 2>&1
		fi
	fi

	if  [ ! -e '/usr/bin/curl' ]; then
		echo " Installing Curl ..."
		if [ "${release}" == "centos" ]; then
			yum update > /dev/null 2>&1
			yum -y install curl > /dev/null 2>&1
		else
			apt-get update > /dev/null 2>&1
			apt-get -y install curl > /dev/null 2>&1
		fi
	fi

	if  [ ! -e '/usr/bin/tar' ]; then
		echo " Installing Tar ..."
		if [ "${release}" == "centos" ]; then
			yum -y install tar > /dev/null 2>&1
		else
			apt-get update > /dev/null 2>&1
			apt-get -y install tar > /dev/null 2>&1
		fi
	fi
	
	if  [ ! -e '/usr/bin/wget' ]; then
		echo " Installing Wget ..."
		if [ "${release}" == "centos" ]; then
			yum update > /dev/null 2>&1
			yum -y install wget > /dev/null 2>&1
		else
			apt-get update > /dev/null 2>&1
			apt-get -y install wget > /dev/null 2>&1
		fi
	fi
	
	if  [ ! -e '/usr/bin/unzip' ]; then
		echo " Installing UnZip ..."
		if [ "${release}" == "centos" ]; then
#			yum update > /dev/null 2>&1
			yum -y install unzip > /dev/null 2>&1
		else
			apt-get update > /dev/null 2>&1
			apt-get -y install unzip > /dev/null 2>&1
		fi
	fi

	if  [ ! -e './speedtest-cli/speedtest' ]; then
		echo " Installing Speedtest-cli ..."
		wget --no-check-certificate -qO speedtest.tgz https://bintray.com/ookla/download/download_file?file_path=ookla-speedtest-1.0.0-$(uname -m)-linux.tgz > /dev/null 2>&1
		if [[ $? -ne '0' ]]; then
			wget --no-check-certificate -qO speedtest.tgz https://down.vpsaff.net/linux/speedtest/ookla-speedtest/ookla-speedtest-1.0.0-$(uname -m)-linux.tgz > /dev/null 2>&1
		fi
	fi
	mkdir -p speedtest-cli && tar zxvf speedtest.tgz -C ./speedtest-cli/ > /dev/null 2>&1 && chmod a+rx ./speedtest-cli/speedtest
	
	if [ ! -e './besttrace4/besttrace' ]; then
		echo " Installing Best Trace..."
		wget --no-check-certificate -qO besttrace4linux.zip https://cdn.ipip.net/17mon/besttrace4linux.zip > /dev/null 2>&1
		if [[ $? -ne '0' ]]; then
			wget --no-check-certificate -qO besttrace4linux.zip https://down.vpsaff.net/linux/besttrace4linux.zip > /dev/null 2>&1
		fi
		unzip besttrace4linux.zip -d besttrace4 > /dev/null 2>&1
	fi
	chmod +x ./besttrace4/besttrace

	if  [ ! -e 'tools.py' ]; then
		echo " Installing tools.py ..."
		wget --no-check-certificate https://down.vpsaff.net/linux/speedtest/tools.py > /dev/null 2>&1
	fi
	chmod a+rx tools.py

	if  [ ! -e 'fast_com.py' ]; then
		echo " Installing Fast.com-cli ..."
		wget --no-check-certificate https://down.vpsaff.net/linux/speedtest/fast_com.py > /dev/null 2>&1
		wget --no-check-certificate https://down.vpsaff.net/linux/speedtest/fast_com_example_usage.py > /dev/null 2>&1
	fi
	chmod a+rx fast_com.py
	chmod a+rx fast_com_example_usage.py

	sleep 5

	start=$(date +%s) 
}

get_opsy() {
    [ -f /etc/redhat-release ] && awk '{print ($1,$3~/^[0-9]/?$3:$4)}' /etc/redhat-release && return
    [ -f /etc/os-release ] && awk -F'[= "]' '/PRETTY_NAME/{print $3,$4,$5}' /etc/os-release && return
    [ -f /etc/lsb-release ] && awk -F'[="]+' '/DESCRIPTION/{print $2}' /etc/lsb-release && return
}

next() {
    printf "%-70s\n" "-" | sed 's/\s/-/g' | tee -a $log
}

speed_test(){
	if [[ $1 == '' ]]; then
		speedtest-cli/speedtest -p no --accept-license > $speedLog 2>&1
		is_upload=$(cat $speedLog | grep 'Upload')
		result_speed=$(cat $speedLog | awk -F ' ' '/Result/{print $3}')
		if [[ ${is_upload} ]]; then
	        local REDownload=$(cat $speedLog | awk -F ' ' '/Download/{print $3}')
	        local reupload=$(cat $speedLog | awk -F ' ' '/Upload/{print $3}')
	        local relatency=$(cat $speedLog | awk -F ' ' '/Latency/{print $2}')

	        temp=$(echo "$relatency" | awk -F '.' '{print $1}')
        	if [[ ${temp} -gt 50 ]]; then
            	relatency="(*)"${relatency}
        	fi
	        local nodeName=$2

	        temp=$(echo "${REDownload}" | awk -F ' ' '{print $1}')
	        if [[ $(awk -v num1=${temp} -v num2=0 'BEGIN{print(num1>num2)?"1":"0"}') -eq 1 ]]; then
	        	printf "${YELLOW}%-18s${GREEN}%-18s${RED}%-20s${SKYBLUE}%-12s${PLAIN}\n" " ${nodeName}" "${reupload} Mbit/s" "${REDownload} Mbit/s" "${relatency} ms" | tee -a $log
	        fi
		else
	        local cerror="ERROR"
		fi
	else
		speedtest-cli/speedtest -p no -s $1 --accept-license > $speedLog 2>&1
		is_upload=$(cat $speedLog | grep 'Upload')
		if [[ ${is_upload} ]]; then
	        local REDownload=$(cat $speedLog | awk -F ' ' '/Download/{print $3}')
	        local reupload=$(cat $speedLog | awk -F ' ' '/Upload/{print $3}')
	        local relatency=$(cat $speedLog | awk -F ' ' '/Latency/{print $2}')
	        local nodeName=$2

	        temp=$(echo "${REDownload}" | awk -F ' ' '{print $1}')
	        if [[ $(awk -v num1=${temp} -v num2=0 'BEGIN{print(num1>num2)?"1":"0"}') -eq 1 ]]; then
	        	printf "${YELLOW}%-18s${GREEN}%-18s${RED}%-20s${SKYBLUE}%-12s${PLAIN}\n" " ${nodeName}" "${reupload} Mbit/s" "${REDownload} Mbit/s" "${relatency} ms" | tee -a $log
			fi
		else
	        local cerror="ERROR"
		fi
	fi
}

print_china_speedtest() {
	printf "%-18s%-18s%-20s%-12s\n" " Node Name" "Upload Speed" "Download Speed" "Latency" | tee -a $log
    speed_test '' 'Speedtest.net'
    speed_fast_com
    speed_test '3633'  'Shanghai     CT'
	speed_test '27594' 'Guangzhou 5G CT'
    speed_test '26352' 'Nanjing 5G   CT'
    speed_test '34115' 'TianJin 5G   CT'
    speed_test '7509'  'Hangzhou     CT'
#	speed_test '23844' 'Wuhan        CT'
	speed_test '5145'  'Beijing      CU'
	speed_test '24447' 'Shanghai 5G  CU'
	speed_test '26678' 'Guangzhou 5G CU'
	speed_test '16192' 'ShenZhen     CU'
	speed_test '9484'  'Changchun    CU'
	speed_test '13704' 'Nanjing      CU'
#	speed_test '37235' 'Shenyang     CU'
#	speed_test '41009' 'Wuhan 5G     CU'
	speed_test '25637' 'Shanghai 5G  CM'
	speed_test '26656' 'Harbin       CM'
	speed_test '26940' 'Yinchuan     CM'
	speed_test '27249' 'Nanjing 5G   CM'
	speed_test '40131' 'Suzhou 5G    CM'
	speed_test '5505'  'Beijing      BN'
}

print_global_speedtest() {
	printf "%-18s%-18s%-20s%-12s\n" " Node Name" "Upload Speed" "Download Speed" "Latency" | tee -a $log
    speed_test '1536'  'Hong Kong    CN'
    speed_test '33250' 'Macau        CN'
	speed_test '29106' 'Taiwan       CN'
	speed_test '40508' 'Singapore    SG'
#	speed_test '4956'  'Kuala Lumpur MY'
#	speed_test '38134' 'Fukuoka      JP'
	speed_test '28910' 'Tokyo        JP'
	speed_test '6527'  'Seoul        KR'
    speed_test '18229' 'Los Angeles  US'
#	speed_test '15786' 'San Jose     US'
	speed_test '41248' 'London       UK'
	speed_test '10010' 'Frankfurt    DE'
	speed_test '21268' 'France       FR'
}

print_speedtest_fast() {
	printf "%-18s%-18s%-20s%-12s\n" " Node Name" "Upload Speed" "Download Speed" "Latency" | tee -a $log
    speed_test '' 'Speedtest.net'
    speed_fast_com
    speed_test '3633'  'Shanghai     CT'
    speed_test '27594' 'Guangzhou 5G CT'
	speed_test '24447' 'ShangHai 5G  CU'
	speed_test '26678' 'Guangzhou 5G CU'
	speed_test '25637' 'Shanghai 5G  CM'
	speed_test '27249' 'Nanjing 5G   CM'
	 
	rm -rf speedtest*
}

speed_fast_com() {
	temp=$(python fast_com_example_usage.py 2>&1)
	is_down=$(echo "$temp" | grep 'Result') 
		if [[ ${is_down} ]]; then
	        temp1=$(echo "$temp" | awk -F ':' '/Result/{print $2}')
	        temp2=$(echo "$temp1" | awk -F ' ' '/Mbps/{print $1}')
	        local REDownload="$temp2 Mbit/s"
	        local reupload="0.00 Mbit/s"
	        local relatency="-"
	        local nodeName="Fast.com"

	        printf "${YELLOW}%-18s${GREEN}%-18s${RED}%-20s${SKYBLUE}%-12s${PLAIN}\n" " ${nodeName}" "${reupload}" "${REDownload}" "${relatency}" | tee -a $log
		else
	        local cerror="ERROR"
		fi
	rm -rf fast_com_example_usage.py
	rm -rf fast_com.py

}

io_test() {
    (LANG=C dd if=/dev/zero of=test_file_$$ bs=512K count=$1 conv=fdatasync && rm -f test_file_$$ ) 2>&1 | awk -F, '{io=$NF} END { print io}' | sed 's/^[ \t]*//;s/[ \t]*$//'
}

calc_disk() {
    local total_size=0
    local array=$@
    for size in ${array[@]}
    do
        [ "${size}" == "0" ] && size_t=0 || size_t=`echo ${size:0:${#size}-1}`
        [ "`echo ${size:(-1)}`" == "K" ] && size=0
        [ "`echo ${size:(-1)}`" == "M" ] && size=$( awk 'BEGIN{printf "%.1f", '$size_t' / 1024}' )
        [ "`echo ${size:(-1)}`" == "T" ] && size=$( awk 'BEGIN{printf "%.1f", '$size_t' * 1024}' )
        [ "`echo ${size:(-1)}`" == "G" ] && size=${size_t}
        total_size=$( awk 'BEGIN{printf "%.1f", '$total_size' + '$size'}' )
    done
    echo ${total_size}
}

power_time() {

	result=$(smartctl -a $(result=$(cat /proc/mounts) && echo $(echo "$result" | awk '/data=ordered/{print $1}') | awk '{print $1}') 2>&1) && power_time=$(echo "$result" | awk '/Power_On/{print $10}') && echo "$power_time"
}

install_smart() {
	if  [ ! -e '/usr/sbin/smartctl' ]; then
		echo "Installing Smartctl ..."
	    if [ "${release}" == "centos" ]; then
	    	yum update > /dev/null 2>&1
	        yum -y install smartmontools > /dev/null 2>&1
	    else
	    	apt-get update > /dev/null 2>&1
	        apt-get -y install smartmontools > /dev/null 2>&1
	    fi      
	fi
}

ip_info4(){
	ip_date=$(curl -4 -s http://api.ip.la/en?json)
	echo $ip_date > ip_json.json
	isp=$(python tools.py geoip isp)
	as_tmp=$(python tools.py geoip as)
	asn=$(echo $as_tmp | awk -F ' ' '{print $1}')
	org=$(python tools.py geoip org)
	if [ -z "ip_date" ]; then
		echo $ip_date
		echo "hala"
		country=$(python tools.py ipip country_name)
		city=$(python tools.py ipip city)
		countryCode=$(python tools.py ipip country_code)
		region=$(python tools.py ipip province)
	else
		country=$(python tools.py geoip country)
		city=$(python tools.py geoip city)
		countryCode=$(python tools.py geoip countryCode)
		region=$(python tools.py geoip regionName)	
	fi
	if [ -z "$city" ]; then
		city=${region}
	fi

	echo -e " ASN & ISP            : ${SKYBLUE}$asn, $isp${PLAIN}" | tee -a $log
	echo -e " Organization         : ${YELLOW}$org${PLAIN}" | tee -a $log
	echo -e " Location             : ${SKYBLUE}$city, ${YELLOW}$country / $countryCode${PLAIN}" | tee -a $log
	echo -e " Region               : ${SKYBLUE}$region${PLAIN}" | tee -a $log

	rm -rf tools.py
	rm -rf ip_json.json
}

virt_check(){
	if hash ifconfig 2>/dev/null; then
		eth=$(ifconfig)
	fi

	virtualx=$(dmesg) 2>/dev/null

    if  [ $(which dmidecode) ]; then
		sys_manu=$(dmidecode -s system-manufacturer) 2>/dev/null
		sys_product=$(dmidecode -s system-product-name) 2>/dev/null
		sys_ver=$(dmidecode -s system-version) 2>/dev/null
	else
		sys_manu=""
		sys_product=""
		sys_ver=""
	fi
	
	if grep docker /proc/1/cgroup -qa; then
	    virtual="Docker"
	elif grep lxc /proc/1/cgroup -qa; then
		virtual="Lxc"
	elif grep -qa container=lxc /proc/1/environ; then
		virtual="Lxc"
	elif [[ -f /proc/user_beancounters ]]; then
		virtual="OpenVZ"
	elif [[ "$virtualx" == *kvm-clock* ]]; then
		virtual="KVM"
	elif [[ "$cname" == *KVM* ]]; then
		virtual="KVM"
	elif [[ "$cname" == *QEMU* ]]; then
		virtual="KVM"
	elif [[ "$virtualx" == *"VMware Virtual Platform"* ]]; then
		virtual="VMware"
	elif [[ "$virtualx" == *"Parallels Software International"* ]]; then
		virtual="Parallels"
	elif [[ "$virtualx" == *VirtualBox* ]]; then
		virtual="VirtualBox"
	elif [[ -e /proc/xen ]]; then
		virtual="Xen"
	elif [[ "$sys_manu" == *"Microsoft Corporation"* ]]; then
		if [[ "$sys_product" == *"Virtual Machine"* ]]; then
			if [[ "$sys_ver" == *"7.0"* || "$sys_ver" == *"Hyper-V" ]]; then
				virtual="Hyper-V"
			else
				virtual="Microsoft Virtual Machine"
			fi
		fi
	else
		virtual="Dedicated"
	fi
}

power_time_check(){
	echo -ne " Power time of disk   : "
	install_smart
	ptime=$(power_time)
	echo -e "${SKYBLUE}$ptime Hours${PLAIN}"
}

freedisk() {
	freespace=$( df -m . | awk 'NR==2 {print $4}' )
	if [[ $freespace == "" ]]; then
		$freespace=$( df -m . | awk 'NR==3 {print $3}' )
	fi
	if [[ $freespace -gt 1024 ]]; then
		printf "%s" $((1024*2))
	elif [[ $freespace -gt 512 ]]; then
		printf "%s" $((512*2))
	elif [[ $freespace -gt 256 ]]; then
		printf "%s" $((256*2))
	elif [[ $freespace -gt 128 ]]; then
		printf "%s" $((128*2))
	else
		printf "1"
	fi
}

print_io() {
	if [[ $1 == "fast" ]]; then
		writemb=$((128*2))
	else
		writemb=$(freedisk)
	fi
	
	writemb_size="$(( writemb / 2 ))MB"
	if [[ $writemb_size == "1024MB" ]]; then
		writemb_size="1.0GB"
	fi

	if [[ $writemb != "1" ]]; then
		echo -n " I/O Speed( $writemb_size )   : " | tee -a $log
		io1=$( io_test $writemb )
		echo -e "${YELLOW}$io1${PLAIN}" | tee -a $log
		echo -n " I/O Speed( $writemb_size )   : " | tee -a $log
		io2=$( io_test $writemb )
		echo -e "${YELLOW}$io2${PLAIN}" | tee -a $log
		echo -n " I/O Speed( $writemb_size )   : " | tee -a $log
		io3=$( io_test $writemb )
		echo -e "${YELLOW}$io3${PLAIN}" | tee -a $log
		ioraw1=$( echo $io1 | awk 'NR==1 {print $1}' )
		[ "`echo $io1 | awk 'NR==1 {print $2}'`" == "GB/s" ] && ioraw1=$( awk 'BEGIN{print '$ioraw1' * 1024}' )
		ioraw2=$( echo $io2 | awk 'NR==1 {print $1}' )
		[ "`echo $io2 | awk 'NR==1 {print $2}'`" == "GB/s" ] && ioraw2=$( awk 'BEGIN{print '$ioraw2' * 1024}' )
		ioraw3=$( echo $io3 | awk 'NR==1 {print $1}' )
		[ "`echo $io3 | awk 'NR==1 {print $2}'`" == "GB/s" ] && ioraw3=$( awk 'BEGIN{print '$ioraw3' * 1024}' )
		ioall=$( awk 'BEGIN{print '$ioraw1' + '$ioraw2' + '$ioraw3'}' )
		ioavg=$( awk 'BEGIN{printf "%.1f", '$ioall' / 3}' )
		echo -e " Average I/O Speed    : ${YELLOW}$ioavg MB/s${PLAIN}" | tee -a $log
	else
		echo -e " ${RED}Not enough space!${PLAIN}"
	fi
}

print_system_info() {
	echo -e " CPU Model            : ${SKYBLUE}$cname${PLAIN}" | tee -a $log
	echo -e " CPU Cores            : ${YELLOW}$cores Cores ${SKYBLUE}$freq MHz $arch${PLAIN}" | tee -a $log
	echo -e " CPU Cache            : ${SKYBLUE}$corescache ${PLAIN}" | tee -a $log
	echo -e " OS                   : ${SKYBLUE}$opsy ($lbit Bit) ${YELLOW}$virtual${PLAIN}" | tee -a $log
	echo -e " Kernel               : ${SKYBLUE}$kern${PLAIN}" | tee -a $log
	echo -e " Total Space          : ${SKYBLUE}$disk_used_size GB / ${YELLOW}$disk_total_size GB ${PLAIN}" | tee -a $log
	echo -e " Total RAM            : ${SKYBLUE}$uram MB / ${YELLOW}$tram MB ${SKYBLUE}($bram MB Buff)${PLAIN}" | tee -a $log
	echo -e " Total SWAP           : ${SKYBLUE}$uswap MB / $swap MB${PLAIN}" | tee -a $log
	echo -e " Uptime               : ${SKYBLUE}$up${PLAIN}" | tee -a $log
	echo -e " Load Average         : ${SKYBLUE}$load${PLAIN}" | tee -a $log
	echo -e " TCP CC               : ${YELLOW}$tcpctrl${PLAIN}" | tee -a $log
}

print_end_time() {
	end=$(date +%s) 
	time=$(( $end - $start ))
	if [[ $time -gt 60 ]]; then
		min=$(expr $time / 60)
		sec=$(expr $time % 60)
		echo -ne " Finished in  : ${min} min ${sec} sec" | tee -a $log
	else
		echo -ne " Finished in  : ${time} sec" | tee -a $log
	fi

	printf '\n' | tee -a $log

	bj_time=$(curl -s http://cgi.im.qq.com/cgi-bin/cgi_svrtime)

	if [[ $(echo $bj_time | grep "html") ]]; then
		bj_time=$(date -u +%Y-%m-%d" "%H:%M:%S -d '+8 hours')
	fi
	echo " Timestamp    : $bj_time GMT+8" | tee -a $log
	echo " Results      : $log"
}

get_system_info() {
	cname=$( awk -F: '/model name/ {name=$2} END {print name}' /proc/cpuinfo | sed 's/^[ \t]*//;s/[ \t]*$//' )
	cores=$( awk -F: '/model name/ {core++} END {print core}' /proc/cpuinfo )
	freq=$( awk -F: '/cpu MHz/ {freq=$2} END {print freq}' /proc/cpuinfo | sed 's/^[ \t]*//;s/[ \t]*$//' )
	corescache=$( awk -F: '/cache size/ {cache=$2} END {print cache}' /proc/cpuinfo | sed 's/^[ \t]*//;s/[ \t]*$//' )
	tram=$( free -m | awk '/Mem/ {print $2}' )
	uram=$( free -m | awk '/Mem/ {print $3}' )
	bram=$( free -m | awk '/Mem/ {print $6}' )
	swap=$( free -m | awk '/Swap/ {print $2}' )
	uswap=$( free -m | awk '/Swap/ {print $3}' )
	up=$( awk '{a=$1/86400;b=($1%86400)/3600;c=($1%3600)/60} {printf("%d days %d hour %d min\n",a,b,c)}' /proc/uptime )
	load=$( w | head -1 | awk -F'load average:' '{print $2}' | sed 's/^[ \t]*//;s/[ \t]*$//' )
	opsy=$( get_opsy )
	arch=$( uname -m )
	lbit=$( getconf LONG_BIT )
	kern=$( uname -r )

	disk_size1=$( LANG=C df -hPl | grep -wvE '\-|none|tmpfs|overlay|shm|udev|devtmpfs|by-uuid|chroot|Filesystem' | awk '{print $2}' )
	disk_size2=$( LANG=C df -hPl | grep -wvE '\-|none|tmpfs|overlay|shm|udev|devtmpfs|by-uuid|chroot|Filesystem' | awk '{print $3}' )
	disk_total_size=$( calc_disk ${disk_size1[@]} )
	disk_used_size=$( calc_disk ${disk_size2[@]} )

	tcpctrl=$( sysctl net.ipv4.tcp_congestion_control | awk -F ' ' '{print $3}' )

	virt_check
}

besttrace_test() {
    if [ "$2" = "tcp" ] || [ "$2" = "TCP" ]; then
        echo -e "\nTraceroute to $4 (TCP Mode, Max $3 Hop)" | tee -a $log
        echo -e "============================================================" | tee -a $log
        ./besttrace4/besttrace -g en -q 1 -n -T -m $3 $1 | tee -a $log
    else
        echo -e "\nTracecroute to $4 (ICMP Mode, Max $3 Hop)" | tee -a $log
        echo -e "============================================================" | tee -a $log
        ./besttrace4/besttrace -g en -q 1 -n -m $3 $1 | tee -a $log
    fi
}

print_besttrace_test(){
	besttrace_test "113.108.209.1" "TCP" "30" "China, Guangzhou CT"
	besttrace_test "180.153.28.5" "TCP" "30" "China, Shanghai CT"
    besttrace_test "180.149.128.9" "TCP" "30" "China, Beijing CT"
	besttrace_test "210.21.4.130" "TCP" "30" "China, Guangzhou CU"
	besttrace_test "58.247.8.158" "TCP" "30" "China, Shanghai CU"
	besttrace_test "123.125.99.1" "TCP" "30" "China, Beijing CU"
	besttrace_test "120.196.212.25" "TCP" "30" "China, Guangzhou CM"
    besttrace_test "221.183.55.22" "TCP" "30" "China, Shanghai CM"
	besttrace_test "211.136.25.153" "TCP" "30" "China, Beijing CM"
	besttrace_test "211.167.230.100" "TCP"  "30" "China, Beijing Dr.Peng Network IDC Network"	
}

print_intro() {
	printf ' Superbench.sh -- https://www.idcoffer.com/archives/4764\n' | tee -a $log
	printf " Mode  : \e${GREEN}%s\e${PLAIN}    Version : \e${GREEN}%s${PLAIN}\n" $mode_name 1.3.0 | tee -a $log
	printf ' Usage : wget -qO- down.vpsaff.net/linux/speedtest/superbench.sh | bash\n' | tee -a $log
}

sharetest() {
	echo " Share result:" | tee -a $log
	echo " · $result_speed" | tee -a $log
	log_preupload
	case $1 in
	'ubuntu')
		share_link="https://paste.ubuntu.com"$( curl -v --data-urlencode "content@$log_up" -d "poster=superbench.sh" -d "syntax=text" "https://paste.ubuntu.com" 2>&1 | \
			grep "Location" | awk '{print $3}' );;
	'haste' )
		share_link=$( curl -X POST -s -d "$(cat $log)" https://hastebin.com/documents | awk -F '"' '{print "https://hastebin.com/"$4}' );;
	'clbin' )
		share_link=$( curl -sF 'clbin=<-' https://clbin.com < $log );;
	'ptpb' )
		share_link=$( curl -sF c=@- https://ptpb.pw/?u=1 < $log );;
	esac

	echo " · $share_link" | tee -a $log
	next
	echo ""
	rm -f $log_up

}

log_preupload() {
	log_up="$HOME/superbench_upload.log"
	true > $log_up
	$(cat superbench.log 2>&1 | sed -r "s/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[m|K]//g" > $log_up)
}

cleanup() {
	rm -f test_file_*
	rm -rf speedtest*
	rm -f fast_com*
	rm -f tools.py
	rm -f ip_json.json
	rm -rf besttrace4*
}

bench_all(){
	mode_name="Standard"
	about;
	benchinit;
	clear
	next;
	print_intro;
	next;
	get_system_info;
	print_system_info;
	ip_info4;
	next;
	print_io;
	next;
	print_china_speedtest;
	next;
	print_global_speedtest;
	next;
	print_besttrace_test;
	next;
	print_end_time;
	next;
	cleanup;
	sharetest ubuntu;
}

fast_bench(){
	mode_name="Fast"
	about;
	benchinit;
	clear
	next;
	print_intro;
	next;
	get_system_info;
	print_system_info;
	ip_info4;
	next;
	print_io fast;
	next;
	print_speedtest_fast;
	next;
	print_end_time;
	next;
	cleanup;
}

log="./superbench.log"
true > $log
speedLog="./speedtest.log"
true > $speedLog

case $1 in
	'info'|'-i'|'--i'|'-info'|'--info' )
		about;sleep 3;next;get_system_info;print_system_info;next;;
    'version'|'-v'|'--v'|'-version'|'--version')
		next;about;next;;
   	'io'|'-io'|'--io'|'-drivespeed'|'--drivespeed' )
		next;print_io;next;;
	'speed'|'-speed'|'--speed'|'-speedtest'|'--speedtest'|'-speedcheck'|'--speedcheck' )
		about;benchinit;next;print_china_speedtest;next;cleanup;;
	'ip'|'-ip'|'--ip'|'geoip'|'-geoip'|'--geoip' )
		about;benchinit;next;ip_info4;next;cleanup;;
	'bench'|'-a'|'--a'|'-all'|'--all'|'-bench'|'--bench' )
		bench_all;;
	'besttrace'|'-b'|'--b'|'--besttrace' )
		print_besttrace_test;;
	'about'|'-about'|'--about' )
		about;;
	'fast'|'-f'|'--f'|'-fast'|'--fast' )
		fast_bench;;
	'share'|'-s'|'--s'|'-share'|'--share' )
		bench_all;
		is_share="share"
		if [[ $2 == "" ]]; then
			sharetest ubuntu;
		else
			sharetest $2;
		fi
		;;
	'debug'|'-d'|'--d'|'-debug'|'--debug' )
		get_ip_whois_org_name;;
*)
    bench_all;;
esac

if [[  ! $is_share == "share" ]]; then
	case $2 in
		'share'|'-s'|'--s'|'-share'|'--share' )
			if [[ $3 == '' ]]; then
				sharetest ubuntu;
			else
				sharetest $3;
			fi
			;;
	esac
fi