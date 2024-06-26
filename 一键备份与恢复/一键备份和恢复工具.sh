#!/bin/bash

tool_version="2.0.0-beta"
export LANG=en_US.UTF-8

# colors
red="\033[38;5;196m"
blu="\033[38;5;39m"
nco="\033[0m" #no color
num=0

base_dir=/var/mobile/Documents/tweak_tool

mkd(){
    if [ ! -e $1 ]; then
        mkdir -p $1;
    fi;
}

if [[ $EUID -ne 0 ]]; then
	echo
	echo -e ${red}" 权限不足！"
	echo
	echo -e ${red}" 如使用Terminal，请用sudo tweaktool命令执行"
	echo
	exit
fi

checkPremissions(){
	f=$1/$2
	if [ -e $f ]; then
		f_p=`stat -c %a $f`
		if [[ $f_p -ne 555 ]] && [[ $f_p -ne 755 ]] && [[ $f_p -ne 775 ]] && [[ $f_p -ne 777 ]]; then
			chmod 755 $f
		fi
		echo $2
	fi
	echo ""
}

deb_pack(){
	name=$([ ! -z "`dpkg-query -W -f='${Name}' $1`" ] && echo "`dpkg-query -W -f='${Name}_${Version}_${Architecture}' $1`" || echo "`dpkg-query -W -f='${Package}_${Version}_${Architecture}' $1`")
	rootdir="$tweak_dir"/"$name"
	mkdir -p "$rootdir"/DEBIAN
	dpkg-query -s "$1" | grep -v Status>>"$rootdir"/DEBIAN/control
	route=""
	if [ -d /var/jb/Library/dpkg/info ];then
		path=/var/jb/Library/dpkg/info
	else
		path=/var/lib/dpkg/info
	fi
	debian_list=`dpkg-query --control-list $1`
	for i in $debian_list; do
		if [[ "$i" != "md5sums" ]]; then
			ret=`checkPremissions $path "$1"."$i"`
			route="${ret} ${route}"
		fi
	done
	if [ ! -z `echo $route | sed 's/ //g'` ]; then
		(cd $path ;tar cf - $route ) | (cd "$rootdir"/DEBIAN ;tar xf -)
	fi
	for i in $debian_list; do
		if [[ "$i" != "md5sums" ]]; then
			mv -f "$rootdir"/DEBIAN/"$1"."$i" "$rootdir"/DEBIAN/"$i"
		fi
	done

	SAVEIFS=$IFS
	IFS=$'\n'
	files=$(dpkg-query -L "$1"|sed "1 d")
	route=""
	for i in $files; do
		if [ -f "$i" ]; then
			i="."$(echo $i|sed 'y/ /*/')
			route="${i} ${route}"
		fi
	done
	IFS=$SAVEIFS
	if [ ! -z `echo $route | sed 's/ //g'` ]; then
		(cd / ;tar cf - $route ) | (cd "$rootdir" ;tar xf -)
	fi

	dpkg-deb -b "$rootdir" 2>&1
	rm -rf "$rootdir" 2>&1
	unset route
}

tweak_backup(){
	yes '' | sed 2q
	echo -e "${nco} 开始进行插件备份！${nco}"
	echo
	echo -e " [1] - ${nco}备份所有插件${nco}"
	echo -e " [2] - ${nco}选择性备份插件${nco}"
	echo
	while true; do
		echo -ne " (1/2): ${nco}"
		read st
		case $st in
			[1] ) st=1;
			break;;
			[2] ) st=2;
			break;;
			* ) echo -e ${red}" 请输入 1 或 2 ！"${nco};
		esac
	done
	if [ -f /var/jb/.installed_dopamine ]; then
		jailbreak="Dopamine"
	elif [ -d /var/jb/xina ] || [ -f /var/jb/.installed_xina15 ]; then
		jailbreak="Xina"
	else
		jailbreak=""
	fi
	current_time=$(date "+%Y-%m-%d_%H:%M:%S")
	bak_dir="$base_dir"/"$jailbreak""备份_""$current_time"
	tweak_dir="$bak_dir"/插件备份
	snowboard_dir="$bak_dir"/滑雪板主题
	nice_dir="$bak_dir"/NiceBarX
	callassist_dir="$bak_dir"/电话助手主题
	tweaksetting_dir="$bak_dir"/插件配置备份
	sources_dir="$bak_dir"/源地址备份
	mkd $tweak_dir
	mkd $snowboard_dir
	mkd $nice_dir
	mkd $callassist_dir
	mkd $tweaksetting_dir
	mkd $others_dir
	mkd $sources_dir
	chown -R 501:501 $bak_dir 2> /dev/null
	
	thread_num=10
	tempfifo=$base_dir/$$.fifo
	mkfifo $tempfifo
	exec 5<>${tempfifo}
	rm -rf ${tempfifo}
	for((i=1;i<=$thread_num;i++))
	do
		echo ;
	done >&5
	
	if [ $st = 2 ]; then
		clear
		yes '' | sed 1q
		pkgendnumber=`j=1;for i in $(dpkg --get-selections | grep -v -E 'deinstall|gsc\.|cy\+|swift-|build-|llvm|clang' | grep -vw 'git' | grep -vwFf /var/jb/usr/local/lib/tweak_exclude_list | awk '{print $1}');do echo -e $j:$i;j=$[j+1];done|tail -1|awk -F ":" '{print $1}'`
		printf " ${nco}已安装的插件数量: %-24s\n" "$pkgendnumber"
		j=1;for i in $(dpkg --get-selections | grep -v -E 'deinstall|gsc\.|cy\+|swift-|build-|llvm|clang' | grep -vw 'git' | grep -vwFf /var/jb/usr/local/lib/tweak_exclude_list | awk '{print $1}');do name=$([ ! -z "`dpkg-query -W -f='${Name}' $i`" ] && echo "`dpkg-query -W -f='${Name}_${Version}_${Architecture}' $i`" || echo "`dpkg-query -W -f='${Package}_${Version}_${Architecture}' $i`");echo -e "$(printf " ${nco}%-59s${nco}" "${blu}$j${nco}: ${nco}$name")";j=$[j+1];done
		while true; do
			echo -e "${nco} 请输入插件对应的序号 ${blu}[1-$pkgendnumber]${blu}${nco} 以空格分隔，按回车键结束输入:${nco} \c"
			read pkgNums
			case `echo $pkgNums | sed 's/ //g'` in
				''|*[!0-9]*)
				echo -e ${red}" 请勿输入数字和空格以外的字符！"${nco}
				;;
				*)
				pkgendnumber=`j=1;for i in $(dpkg --get-selections | grep -v -E 'deinstall|gsc\.|cy\+|swift-|build-|llvm|clang' | grep -vw 'git' | grep -vwFf /var/jb/usr/local/lib/tweak_exclude_list | awk '{print $1}');do echo -e $j:$i;j=$[j+1];done|tail -1|awk -F ":" '{print $1}'`
				pkgNums=(${pkgNums// / })
				deps=""
				for pkgNum in ${pkgNums[@]}; do
					if [[ "$pkgNum" -gt "$pkgendnumber" ]]; then
						echo -e ${red}" 所有插件序号必须在 [1-$pkgendnumber] 之间！"${nco}
						continue 2
					else
						pkg=`j=1;for i in $(dpkg --get-selections | grep -v -E 'deinstall|gsc\.|cy\+|swift-|build-|llvm|clang' | grep -vw 'git' | grep -vwFf /var/jb/usr/local/lib/tweak_exclude_list | awk '{print $1}');do echo $j:$i;j=$[j+1];done | grep -e "$pkgNum:" | head -1 |awk -F ":" '{print $2}'`
						deps[${#deps[@]}]=$pkg
					fi
				done
				break
				;;
			esac
		done
		echo;
		echo -e "${nco} 开始备份...${nco}";
		echo;
		for pkg in ${deps[@]}
		do
		{
			read -u5
			{
				deb_pack $pkg
				echo "" >&5
			} &
		}
		done
	else
		deps="$(dpkg --get-selections | grep -v -E 'deinstall|gsc\.|cy\+|swift-|build-|llvm|clang' | grep -vw 'git' | grep -vwFf /var/jb/usr/local/lib/tweak_exclude_list | cut -f1 | awk '{print $1}')"
		echo;
		echo -e "${nco} 开始备份...${nco}";
		echo;
		for pkg in $deps
		do
		{
			read -u5
			{
				deb_pack $pkg
				echo "" >&5
			} &
		}
		done
	fi
	wait
	exec 5>&-

	clear
	unset pkg
	yes '' | sed 2q
	echo -e "${nco} DONE！插件备份完成！${nco}"
	echo
}

check_dpkg_run(){
	wait=1
	while [ '1' -le '2' ]; do
		check="$(ps -ef | grep dpkg | grep -v grep | grep -v "$$" | grep -v "sudo ${0##*/}" | wc -l)"
		if [ "${check}" -ge '1' ]; then
			wait="$((wait+1))"
			sleep 1
		else
			break
		fi
	done
	unset check wait
}

run(){
	if [ -n "${package_row}" ]; then
		case "${lack}" in
			description)
				fill="Description: An awesome MobileSubstrate tweak"\!
			;;
			maintainer)
				fill="Maintainer: someone"
			;;
			*)
				break
			;;
		esac
		if [ -n "${fill}" ]; then
			sed -i.tmp "${package_row}a ${fill}" "${stash_file}"
		fi
	fi
	unset package package_row lack fill
}

dpkg_fill(){
	command="${0##*/}"
	shopt -s expand_aliases 2>>/dev/null
	if which lecho 2>>/dev/null 1>>/dev/null; then
		if [ -n "${LANG}" ]; then
			alias lecho="lecho -c ${0##*/} -l ${LANG}"
		else
			alias lecho="lecho -c ${0##*/}"
		fi
	fi
	unset check

	check_dpkg_run
	i='0'
	i_max="$(dpkg -S / 2>&1 | grep -E 'escription|aintainer' | wc -l)"
	if [ "${i_max}" -eq '0' ]; then
		echo -e "${nco} 没有发现错误${nco}";
	else
		stash_file_0="$(dpkg -S / 2>&1)"
		stash_file_0="${stash_file_0#*\'}"
		stash_file_0="${stash_file_0%%\'*}"
		if [ -z "$(echo "${stash_file_0}" | grep '/')" ]; then
			stash_file='/var/lib/dpkg/status'
		else
			stash_file="${stash_file_0}"
		fi
		unset stash_file_0
		while [ "${i}" -le "${i_max}" ]; do
			case "$(dpkg -S / 2>&1 | grep -E 'warning|escription|aintainer' | sed -n 2p)" in
				*escription*)
					lack='description'
					;;
				*aintainer*)
					lack='maintainer'
					;;
				*)
					break
					;;
			esac
			package="$(dpkg -S / 2>&1 | grep -E 'warning|escription|aintainer' | sed -n 1p)"
			package="${package%\'*}"
			package="${package##*\'}"
			package_row="$(sed -n "/^Package: ${package}$/=" "${stash_file}")"
			check_dpkg_run
			run
			i="$((i+1))"
		done
		echo -e "${nco} 已修补包缺失信息${nco}";
	fi
	rm -f "${stash_file}.tmp"
	rm -rf "/tmp/dpkg-fill"
	tweak_backup
}

setting_backup(){
	echo -e "${nco} 正在进行配置备份，请耐心等待...${nco}"
	
	cp -a /var/jb/Library/Themes/* "$snowboard_dir"/ 2> /dev/null
	cp -a /var/mobile/Library/NiceiOS/NiceBarX/* "$nice_dir"/ 2> /dev/null
	cp -a /var/jb/Library/CallAssist/theme/* "$callassist_dir"/ 2> /dev/null
	cp -a /var/jb/User/NiceiOS "$tweaksetting_dir"/ 2> /dev/null
	cp -a /var/jb/User/Library "$tweaksetting_dir"/ 2> /dev/null
	cp -a /var/jb/etc/apt/sources.list.d/* "$sources_dir"/ 2> /dev/null
	
	clear
	yes '' | sed 2q
	echo -e "${nco} DONE！配置备份完成！${nco}"
	echo
}

backup(){
	echo
	echo -e "${nco} 根据数据大小，备份可能需要5-10分钟甚至更久，请预留充足时间...${nco}"
	echo -e "${nco} 开始备份后请耐心等待，保持界面不要退出！${nco}"
	echo
	echo -e " [1] ${red}是 ${nco}- 进行插件备份${nco}"
	echo -e " [2] ${red}否 ${nco}- 跳过插件备份${nco}"
	echo
	while true; do
		echo -ne " (1/2): ${nco}"
		read st
		case $st in
			[1] ) st=1;
			break;;
			[2] ) st=2;
			break;;
			* ) echo -e ${red}" 请输入 1 或 2 ！"${nco};
		esac
	done

	if [ $st = 1 ]; then
		yes '' | sed 2q
		echo -e "${nco} 开始检查包完整性！${nco}"
		echo
		dpkg_fill
	else
		clear
		yes '' | sed 2q
		echo -e "${nco} 已跳过插件备份！${nco}"
		echo
	fi

	echo -e " [1] ${red}是 ${nco}- 进行配置备份${nco}"
	echo -e " [2] ${red}否 ${nco}- 跳过配置备份${nco}"
	echo
	while true; do
		echo -ne " (1/2): ${nco}"
		read st
		case $st in
			[1] ) st=1;
			break;;
			[2] ) st=2;
			break;;
			* ) echo -e ${red}" 请输入 1 或 2 ！"${nco};
		esac
	done

	if [ $st = 1 ]; then
		yes '' | sed 2q
		echo -e "${nco} 开始进行配置备份！${nco}"
		echo
		if [ -z $bak_dir ]; then
			if [ -f /var/jb/.installed_dopamine ]; then
				jailbreak="Dopamine"
			elif [ -d /var/jb/xina ] || [ -f /var/jb/.installed_xina15 ]; then
				jailbreak="Xina"
			else
				jailbreak=""
			fi
			current_time=$(date "+%Y-%m-%d_%H:%M:%S")
			bak_dir="$base_dir"/"$jailbreak""备份_""$current_time"
			tweak_dir="$bak_dir"/插件备份
			snowboard_dir="$bak_dir"/滑雪板主题
			nice_dir="$bak_dir"/NiceBarX
			callassist_dir="$bak_dir"/电话助手主题
			tweaksetting_dir="$bak_dir"/插件配置备份
			sources_dir="$bak_dir"/源地址备份
			mkd $tweak_dir
			mkd $snowboard_dir
			mkd $nice_dir
			mkd $callassist_dir
			mkd $tweaksetting_dir
			mkd $others_dir
			mkd $sources_dir
			chown -R 501:501 $bak_dir 2> /dev/null
		fi
		setting_backup
	else
		clear
		yes '' | sed 2q
		echo -e "${nco} 已跳过配置备份！${nco}"
		echo
	fi

	echo -e "${nco} 备份流程已结束，感谢耐心等待！${nco}"
	echo -e "${nco} 现在可以退出终端${nco}"
	echo
}

recover_tweak(){
	tweak_dir="$bak_dir"/插件备份
	sleep 1s
	echo
	echo -e "${nco} 准备中，开始安装插件${nco}"
	echo
	if [ -d "$tweak_dir" -a "`ls -A "$tweak_dir"`" != "" ]; then
		echo -e "${nco} 正在安装插件，请耐心等待...${nco}"
		sleep 4s
		dpkg -i "$tweak_dir"/*.deb
		echo
		echo -e "${nco} 插件安装完成${nco}"
	else
		echo -e "${nco} 没有找到备份的插件，即将跳过...${nco}"
	fi
}

recover_setting(){
	snowboard_dir="$bak_dir"/滑雪板主题
	nice_dir="$bak_dir"/NiceBarX
	callassist_dir="$bak_dir"/电话助手主题
	tweaksetting_dir="$bak_dir"/插件配置备份
	sources_dir="$bak_dir"/源地址备份
	sleep 2s
	echo
	echo -e "${nco} 开始恢复插件配置${nco}"
	cp -a "$snowboard_dir"/* /var/jb/Library/Themes/ 2> /dev/null
	if [ -d "$nice_dir" -a "`ls -A "$nice_dir"`" != "" ]; then
		mkd /var/mobile/Library/NiceiOS/NiceBarX
		cp -a "$nice_dir"/* /var/mobile/Library/NiceiOS/NiceBarX/
		chown -R 0:0 /var/mobile/Library/NiceiOS/NiceBarX/
		chmod -R 0755 /var/mobile/Library/NiceiOS/NiceBarX/
	fi
	if [ -d "$callassist_dir" -a "`ls -A "$callassist_dir"`" != "" ]; then
		mkd /var/jb/Library/CallAssist/theme
		cp -a "$callassist_dir"/* /var/jb/Library/CallAssist/theme/
		chown -R 0:0 /var/jb/Library/CallAssist/theme/
		chmod -R 0755 /var/jb/Library/CallAssist/theme/
	fi
	cp -a "$tweaksetting_dir"/* /var/jb/User/ 2> /dev/null
	if [ -d "$tweaksetting_dir"/NiceiOS -a "`ls -A "$tweaksetting_dir"/NiceiOS`" != "" ]; then
		chown -R 0:0 /var/jb/User/NiceiOS
		chmod -R 0755 /var/jb/User/NiceiOS
	fi
	chown -R 501:501 /var/jb/User/Library/
	chmod -R 0755 /var/jb/User/Library/
	cp -a "$sources_dir"/* /var/jb/etc/apt/sources.list.d/ 2> /dev/null
	chown -R 0:0 /var/jb/etc/apt/sources.list.d/
	chmod -R 0755 /var/jb/etc/apt/sources.list.d/
	echo -e "${nco} 插件配置恢复成功${nco}"
}

recover(){
	echo
	echo -e " ⚠️ ${red} 注意：${nco}请确认已经进行过备份！${nco}"
	echo -e "${nco} 开始恢复后请耐心等待，保持界面不要退出！${nco}"
	echo
	echo -e " [1] ${red}是 ${nco}- 开始恢复${nco}"
	echo -e " [2] ${red}否 ${nco}- 取消恢复${nco}"
	echo
	while true; do
		echo -ne " (1/2): ${nco}"
		read st
		case $st in
			[1] ) st=1;
			break;;
			[2] ) st=2;
			break;;
			* ) echo -e ${red}" 请输入 1 或 2 ！"${nco};
		esac
	done

	if [ $st = 1 ]; then
		echo
		bakendnumber=`j=1;for i in $(ls -l /var/mobile/Documents/tweak_tool/ | grep -E "(Xina)|(Dopamine)|(\s)备份_[0-9]{4}-[0-9]{2}-[0-9]{2}_[0-9]{2}:[0-9]{2}:[0-9]{2}" |awk '/^d/ {print $NF}');do echo -e $j: $i;j=$[j+1];done|tail -1|awk -F ": " '{print $1}'`
		if [[ $bakendnumber -gt 0 ]]; then
			echo -e "${nco} 请选择需要恢复的备份！${nco}"
			echo
			j=1;for i in $(ls -l /var/mobile/Documents/tweak_tool/ | grep -E "(Xina)|(Dopamine)|(\s)备份_[0-9]{4}-[0-9]{2}-[0-9]{2}_[0-9]{2}:[0-9]{2}:[0-9]{2}" |awk '/^d/ {print $NF}');do echo -e "$(printf " ${nco}%-59s${nco}" "${blu}$j${nco}: ${nco}$i")";j=$[j+1];done
			while true; do
				echo -e "${nco} 请输入备份对应的序号 ${blu}[1-$bakendnumber]${blu}${nco} :${nco} \c"
				read bakNum
				case $bakNum in
					''|*[!0-9]*)
					echo -e ${red}" 请勿输入除数字以外的字符！"${nco}
					;;
					*)
					bakendnumber=`j=1;for i in $(ls -l /var/mobile/Documents/tweak_tool/ | grep -E "(Xina)|(Dopamine)|(\s)备份_[0-9]{4}-[0-9]{2}-[0-9]{2}_[0-9]{2}:[0-9]{2}:[0-9]{2}" |awk '/^d/ {print $NF}');do echo -e $j:$i;j=$[j+1];done|tail -1|awk -F ":" '{print $1}'`
					if [[ "$bakNum" -gt "$bakendnumber" ]]; then
						echo -e ${red}" 备份序号必须在 [1-$bakendnumber] 之间！"${nco}
						continue
					else
						bak=`j=1;for i in $(ls -l /var/mobile/Documents/tweak_tool/ | grep -E "(Xina)|(Dopamine)|(\s)备份_[0-9]{4}-[0-9]{2}-[0-9]{2}_[0-9]{2}:[0-9]{2}:[0-9]{2}" |awk '/^d/ {print $NF}');do echo $j: $i;j=$[j+1];done | grep -e "$bakNum: " | head -1 |awk -F ": " '{print $2}'`
					fi
					break
					;;
				esac	
			done
			
			bak_dir="$base_dir"/"$bak"
			echo
			echo -e " [1] - ${nco}恢复插件及配置${nco}"
			echo -e " [2] - ${nco}仅恢复插件${nco}"
			echo -e " [3] - ${nco}仅恢复配置${nco}"
			echo
			while true; do
				echo -ne " (1/2/3): ${nco}"
				read st
				case $st in
					[1] ) st=1;
					break;;
					[2] ) st=2;
					break;;
					[3] ) st=3;
					break;;
					* ) echo -e ${red}" 请输入 1 或 2 或 3 ！"${nco};
				esac
			done
			yes '' | sed 2q
			echo -e "${nco} 开始进行恢复，请勿退出！${nco}"
			if [ $st = 1 ]; then
				recover_tweak
				recover_setting
			elif [ $st = 2 ]; then
				recover_tweak
			else
				recover_setting
			fi
			
			sleep 5s
			echo
			echo -e "${nco} 恢复流程已结束，部分插件及设置可能需要注销设备或者重启用户空间后生效！${nco}"
			echo
			echo -e " [1] - ${nco}注销设备${nco}"
			echo -e " [2] - ${nco}重启用户空间${nco}"
			echo -e " [3] - ${nco}稍后再说${nco}"
			echo
			while true; do
				echo -ne " (1/2/3): ${nco}"
				read st
				case $st in
					[1] ) st=1;
					break;;
					[2] ) st=2;
					break;;
					[3] ) st=3;
					break;;
					* ) echo -e ${red}" 请输入 1 或 2 或 3 ！"${nco};
				esac
			done
			if [ $st = 1 ]; then
				sleep 2s
				killall -9 backboardd
			elif [ $st = 2 ]; then
				sleep 2s
				launchctl reboot userspace
			else
				clear
				yes '' | sed 2q
				echo -e "${nco} 现在可以退出终端${nco}"
				echo
				exit
			fi
			EOF
		else
			echo -e "${nco} 未找到合法备份，请尝试重新备份或者检查备份文件夹名称是否符合命名规范！${nco}"
			echo
			exit
		fi
	else
		clear
		yes '' | sed 2q
		echo -e "${nco} 已取消恢复！${nco}"
		echo -e "${nco} 现在可以退出终端${nco}"
		echo
		exit
	fi
}

echo
echo -e "${nco} 欢迎使用一键备份和恢复工具${nco}"
echo -e "${nco} 本工具由预言小猫优化整合${nco}"
echo -e "${nco} 鸣谢：菠萝 & 建哥${nco}"
echo
echo -e "${nco} 当前版本：$tool_version${nco}"
echo
echo -e "${nco} 请选择对应功能${nco}"
echo -e " [1] - ${nco}备份${nco}"
echo -e " [2] - ${nco}恢复${nco}"
echo -e " [3] - ${nco}退出${nco}"
echo
while true; do
	echo -ne " (1/2/3): ${nco}"
	read st
	case $st in
		[1] ) st=1;
		break;;
		[2] ) st=2;
		break;;
		[3] ) st=3;
		break;;
		* ) echo -e ${red}" 请输入 1 或 2 或 3 ！"${nco};
	esac
done

if [ $st = 1 ]; then
	clear
	backup
elif [ $st = 2 ]; then
	clear
	recover
else
	clear
	yes '' | sed 2q
	echo -e "${nco} 现在可以退出终端${nco}"
	echo
	exit
fi
