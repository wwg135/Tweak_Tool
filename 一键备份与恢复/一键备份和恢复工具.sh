#!/bin/bash
PATH=/var/jb/bin:/var/jb/usr/bin:/var/jb/sbin:/var/jb/usr/sbin:$PATH

export LANG=en_US.UTF-8

# colors
red="\033[38;5;196m"
blu="\033[38;5;39m"
nco="\033[0m" #no color
num=0

base_dir=/var/mobile

mkd(){
    if [ ! -e $1 ]; then
        mkdir -p $1;
    fi;
}

if [[ $EUID -ne 0 ]]; then
	echo
	echo -e ${red}" 权限不足！"
	echo
	echo -e ${red}" 如使用Terminal，请用sudo TweakTool命令执行"
	echo
	exit
fi

check_premissions(){
    if [ -e $1 ]; then
		f_p=`stat -c %a $1`
		if [ $f_p != '555' ] && [ $f_p != '755' ] && [ $f_p != '775' ] && [ $f_p != '777' ]; then
			chmod 755 $1
		fi
    fi
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

deb_pack(){
	if [ -z "$total_time" ]; then
    		total_time=0
  	fi
	start_time=$(date +%s)
	num=$(($num+1))
	ver=`dpkg-query -s "$1" | grep Version | awk '{print $2}'`
	arc=`dpkg-query -s "$1" | grep Architecture: | awk '{print $2}'`
 	name=`dpkg-query -s "$1" | grep Name | awk '{print $2}'`
    	echo -e "${nco} 正在备份第"$num"个插件：${red}"$name"${nco}，请耐心等待...${nco}"
	if [ -d /var/jb/xina ] && [ ! -f /var/jb/.installed_xina15 ]; then
		cp /var/lib/dpkg/info/"$1".list /var/lib/dpkg/info/"$1".list.debra
		cat /var/lib/dpkg/info/"$1".list | grep -v "/var" > /var/lib/dpkg/info/"$1".list.nonvar
		sed -i -e 's#^#/var/jb#' /var/lib/dpkg/info/"$1".list.nonvar
		cat /var/lib/dpkg/info/"$1".list | grep "/var" > /var/lib/dpkg/info/"$1".list.var
		cat /var/lib/dpkg/info/"$1".list.var >> /var/lib/dpkg/info/"$1".list.nonvar
		rm -f /var/lib/dpkg/info/"$1".list.var
		rm -f /var/lib/dpkg/info/"$1".list
		mv -f /var/lib/dpkg/info/"$1".list.nonvar /var/lib/dpkg/info/"$1".list
	fi
	rootdir="$tweak_dir"/"$name"_"$ver"_"$arc"
	mkdir -p "$rootdir"/DEBIAN
	dpkg-query -s "$1" | grep -v Status>>"$rootdir"/DEBIAN/control
	if [ -d /var/jb/Library/dpkg/info ];then
		postinst=/var/jb/Library/dpkg/info/"$1".postinst
		preinst=/var/jb/Library/dpkg/info/"$1".preinst
		postrm=/var/jb/Library/dpkg/info/"$1".postrm
		prerm=/var/jb/Library/dpkg/info/"$1".prerm
		extrainst_=/var/jb/Library/dpkg/info/"$1".extrainst_
		extrainst=/var/jb/Library/dpkg/info/"$1".extrainst
		control=/var/jb/Library/dpkg/info/"$1".control-e
		triggers=/var/jb/Library/dpkg/info/"$1".triggers
		conffiles=/var/jb/Library/dpkg/info/"$1".conffiles
		ldid=/var/jb/Library/dpkg/info/"$1".ldid
		crash_reporter=/var/jb/Library/dpkg/info/"$1".crash_reporter
	else
		postinst=/var/lib/dpkg/info/"$1".postinst
		preinst=/var/lib/dpkg/info/"$1".preinst
		postrm=/var/lib/dpkg/info/"$1".postrm
		prerm=/var/lib/dpkg/info/"$1".prerm
		extrainst_=/var/lib/dpkg/info/"$1".extrainst_
		extrainst=/var/lib/dpkg/info/"$1".extrainst
		control=/var/lib/dpkg/info/"$1".control-e
		triggers=/var/lib/dpkg/info/"$1".triggers
		conffiles=/var/lib/dpkg/info/"$1".conffiles
		ldid=/var/lib/dpkg/info/"$1".ldid
		crash_reporter=/var/lib/dpkg/info/"$1".crash_reporter
	fi
	check_premissions "$postinst"
	check_premissions "$preinst"
	check_premissions "$postrm"
	check_premissions "$prerm"
	check_premissions "$extrainst_"
	check_premissions "$extrainst"
	check_premissions "$control"
	check_premissions "$triggers"
	check_premissions "$conffiles"
	check_premissions "$ldid"
	check_premissions "$crash_reporter"
	cp "$postinst" "$rootdir"/DEBIAN/postinst 2> /dev/null
	cp "$preinst" "$rootdir"/DEBIAN/preinst 2> /dev/null
	cp "$postrm" "$rootdir"/DEBIAN/postrm 2> /dev/null
	cp "$prerm" "$rootdir"/DEBIAN/prerm 2> /dev/null
	cp "$extrainst_" "$rootdir"/DEBIAN/extrainst_ 2> /dev/null
	cp "$extrainst" "$rootdir"/DEBIAN/extrainst 2> /dev/null
	cp "$control" "$rootdir"/DEBIAN/control-e 2> /dev/null
	cp "$triggers" "$rootdir"/DEBIAN/triggers 2> /dev/null
	cp "$conffiles" "$rootdir"/DEBIAN/conffiles 2> /dev/null
	cp "$ldid" "$rootdir"/DEBIAN/ldid 2> /dev/null
	cp "$crash_reporter" "$rootdir"/DEBIAN/crash_reporter 2> /dev/null

	SAVEIFS=$IFS
	IFS=$'\n'
	files=$(dpkg-query -L "$1"|sed "1 d")
	for i in $files; do
		if [ -d "$i" ]; then
			mkdir -p "$rootdir"/"$i"
		elif [ -f "$i" ]; then
			cp -p "$i" "$rootdir"/"$i"
		fi
	done
	IFS=$SAVEIFS

	if [ -d /var/jb/xina ] && [ ! -f /var/jb/.installed_xina15 ]; then
		if [ -d "$rootdir"/var/jb ]; then
			mkdir -p "$rootdir"/temp
			mv -f "$rootdir"/var/jb/.* "$rootdir"/var/jb/* "$rootdir"/temp >/dev/null 2>&1 || true
			rm -rf "$rootdir"/var/jb
			[ -d "$rootdir"/var ] && [ "$(ls -A "$rootdir"/var)" ] && : || rm -rf "$rootdir"/var
			mv -f "$rootdir"/temp/.* "$rootdir"/temp/* "$rootdir" >/dev/null 2>&1 || true
			rm -rf "$rootdir"/temp
		fi
		mv -f /var/lib/dpkg/info/"$1".list.debra /var/lib/dpkg/info/"$1".list
	fi

	echo
	dpkg-deb -b "$rootdir" >/dev/null 2>&1
	rm -rf "$rootdir" 2>&1
	total_time=$((total_time + $(date +%s) - start_time))
	if [ $total_time -lt 60 ]; then
		echo -e "已成功备份 ${red}"$num"${nco} 个插件，耗时：${red}"$total_time" ${nco}秒"
	else
		minutes=$((total_time/60))
		seconds=$((total_time%60))
		echo -e "已成功备份 ${red}"$num"${nco} 个插件，耗时：${red}"$minutes" ${nco}分 ${red}${seconds} ${nco}秒"
	fi
	echo
}

tweak_backup(){
	yes '' | sed 2q
	echo -e "${nco} 开始进行插件备份！${nco}"
	echo
	echo -e " [1] - ${nco}备份所有插件和依赖${nco}"
	echo -e " [2] - ${nco}备份所有插件(过滤系统依赖)${nco}"
	echo -e " [3] - ${nco}选择性备份插件${nco}"
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
	tweaksetting_dir="$bak_dir"/插件配置备份
	sources_dir="$bak_dir"/源地址备份
	mkd $tweak_dir
	mkd $tweaksetting_dir
	mkd $sources_dir
	chown -R 501:501 $bak_dir 2> /dev/null
 
	if [ $st = 3 ]; then
		clear
		yes '' | sed 2q
		pkgendnumber=`j=1;for i in $(dpkg --get-selections | grep -v -E 'deinstall|gsc\.|cy\+|swift-|build-|llvm|clang' | grep -vw 'git' | grep -vwFf /var/jb/usr/local/lib/tweak_exclude_list | awk '{print $1}');do echo -e $j:$i;j=$[j+1];done|tail -1|awk -F ":" '{print $1}'`
		printf  " ${nco}已安装的插件数量: %-24s\n" "$pkgendnumber"
		j=1;for i in $(dpkg --get-selections | grep -v -E 'deinstall|gsc\.|cy\+|swift-|build-|llvm|clang' | grep -vw 'git' | grep -vwFf /var/jb/usr/local/lib/tweak_exclude_list | awk '{print $1}');do echo -e "$(printf " ${nco}%-59s${nco}" "${blu}$j${nco}: ${nco}$i")";j=$[j+1];done
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
				debs=""
				for pkgNum in ${pkgNums[@]}; do
					if [[ "$pkgNum" -gt "$pkgendnumber" ]]; then
						echo -e ${red}" 所有插件序号必须在 [1-$pkgendnumber] 之间！"${nco}
						continue 2
					else
						pkg=`j=1;for i in $(dpkg --get-selections | grep -v -E 'deinstall|gsc\.|cy\+|swift-|build-|llvm|clang' | grep -vw 'git' | grep -vwFf /var/jb/usr/local/lib/tweak_exclude_list | awk '{print $1}');do echo $j:$i;j=$[j+1];done | grep -e "$pkgNum:" | head -1 |awk -F ":" '{print $2}'`
						debs[${#debs[@]}]=$pkg
					fi
				done
				break
				;;
			esac
		done
		echo;
		echo -e "${nco} 开始备份...${nco}";
		echo;
		for pkg in ${debs[@]}; do
			deb_pack $pkg
		done
	else
		if [ $st = 1 ]; then
			debs="$(dpkg --get-selections | grep -v -E 'deinstall|gsc\.|cy\+|swift-|build-|llvm|clang' | grep -vw 'git' | cut -f1 | awk '{print $1}')"
		elif [ $st = 2 ]; then
			debs="$(dpkg --get-selections | grep -v -E 'deinstall|gsc\.|cy\+|swift-|build-|llvm|clang' | grep -vw 'git' | grep -vwFf /var/jb/usr/local/lib/tweak_exclude_list | cut -f1 | awk '{print $1}')"
		fi
		echo;
		echo -e "${nco} 开始备份...${nco}";
		echo;
		for pkg in $debs; do
			deb_pack $pkg
		done
	fi

	clear
	unset pkg
	yes '' | sed 2q
	echo -e "${nco} DONE！插件备份完成！${nco}"
	echo
}

setting_backup(){
	echo -e "${nco} 正在进行配置备份，请耐心等待...${nco}"
	cp -a /var/jb/User/Library "$tweaksetting_dir"/ 2> /dev/null
	cp -a /var/jb/etc/apt/sources.list.d "$sources_dir"/ 2> /dev/null
	
	clear
	yes '' | sed 2q
	echo -e "${nco} DONE！配置备份完成！${nco}"
	echo
}

backup() {
	start_time=$(date +%s)
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
		start_time_plugins=$(date +%s)
		echo
		dpkg_fill
		end_time_plugins=$(date +%s)
		plugins_time=$((end_time_plugins-start_time_plugins))
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
			tweaksetting_dir="$bak_dir"/插件配置备份
			sources_dir="$bak_dir"/源地址备份
			mkd $tweak_dir
			mkd $tweaksetting_dir
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

	end_time=$(date +%s)
	total_time_initial=$((end_time-start_time))
	total_time_total=$((total_time_initial + plugins_time + settings_time))
	if ((total_time_total >= 60)); then
		minutes=$((total_time_total / 60))
		seconds=$((total_time_total % 60))
		echo -e "${nco} 备份流程已结束，耗时：${red}$minutes ${nco}分 ${red}$seconds ${nco}秒，感谢耐心等待！${nco}"
	else
		echo -e "${nco} 备份流程已结束，耗时：${red}$total_time_total ${nco}秒，感谢耐心等待！${nco}"
	fi
 	echo
	echo -e "${nco} 点击左上角 \"完成\" 退出终端${nco}"
	echo
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
		bakendnumber=`j=1;for i in $(ls -l /var/mobile/ | grep -E "(Xina)|(Dopamine)|(\s)备份_[0-9]{4}-[0-9]{2}-[0-9]{2}_[0-9]{2}:[0-9]{2}:[0-9]{2}" |awk '/^d/ {print $NF}');do echo -e $j: $i;j=$[j+1];done|tail -1|awk -F ": " '{print $1}'`
		if [ $bakendnumber > 0 ]; then
			echo -e "${nco} 请选择需要恢复的备份！${nco}"
			echo
			j=1;for i in $(ls -l /var/mobile/ | grep -E "(Xina)|(Dopamine)|(\s)备份_[0-9]{4}-[0-9]{2}-[0-9]{2}_[0-9]{2}:[0-9]{2}:[0-9]{2}" |awk '/^d/ {print $NF}');do echo -e "$(printf " ${nco}%-59s${nco}" "${blu}$j${nco}: ${nco}$i")";j=$[j+1];done
			while true; do
				echo -e "${nco} 请输入备份对应的序号 ${blu}[1-$bakendnumber]${blu}${nco} :${nco} \c"
				read bakNum
				case $bakNum in
					''|*[!0-9]*)
					echo -e ${red}" 请勿输入除数字以外的字符！"${nco}
					;;
					*)
					bakendnumber=`j=1;for i in $(ls -l /var/mobile/ | grep -E "(Xina)|(Dopamine)|(\s)备份_[0-9]{4}-[0-9]{2}-[0-9]{2}_[0-9]{2}:[0-9]{2}:[0-9]{2}" |awk '/^d/ {print $NF}');do echo -e $j:$i;j=$[j+1];done|tail -1|awk -F ":" '{print $1}'`
					if [[ "$bakNum" -gt "$bakendnumber" ]]; then
						echo -e ${red}" 备份序号必须在 [1-$bakendnumber] 之间！"${nco}
						continue
					else
						bak=`j=1;for i in $(ls -l /var/mobile/ | grep -E "(Xina)|(Dopamine)|(\s)备份_[0-9]{4}-[0-9]{2}-[0-9]{2}_[0-9]{2}:[0-9]{2}:[0-9]{2}" |awk '/^d/ {print $NF}');do echo $j: $i;j=$[j+1];done | grep -e "$bakNum:" | head -1 |awk -F ": " '{print $2}'`
					fi
					break
					;;
				esac	
			done
  			bak_dir="$base_dir"/"$bak"
			tweak_dir="$bak_dir"/插件备份
			tweaksetting_dir="$bak_dir"/插件配置备份
			sources_dir="$bak_dir"/源地址备份
		
			yes '' | sed 2q
			echo -e "${nco} 开始进行恢复，请勿退出！${nco}"
			sleep 1s
			echo
			echo -e "${nco} 准备中，开始安装插件${nco}"
			echo
			if [ -d $tweak_dir -a "`ls -A $tweak_dir`" != "" ]; then
				echo -e "${nco} 正在安装插件，请耐心等待...${nco}"
				sleep 1s
				dpkg -i $tweak_dir/*.deb
				echo
				echo -e "${nco} 插件安装完成${nco}"
			else
				echo -e "${nco} 没有找到备份的插件，即将跳过...${nco}"
			fi

 			sleep 2s
			echo
			echo -e "${nco} 开始恢复插件配置${nco}"
			cp -a "$tweaksetting_dir"/* /var/jb/User/ 2> /dev/null
			chown -R 501:501 /var/jb/User/Library/
			chmod -R 0755 /var/jb/User/Library/
			cp -a "$sources_dir"/* /var/jb/etc/apt/ 2> /dev/null
			chown -R 0:0 /var/jb/etc/apt/sources.list.d/
			chmod -R 0755 /var/jb/etc/apt/sources.list.d/
			echo -e "${nco} 插件配置恢复成功${nco}"

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
				sleep 1s
				killall -9 backboardd
			elif [ $st = 2 ]; then
				sleep 1s
				launchctl reboot userspace
			else
				clear
				yes '' | sed 2q
				echo -e "${nco} 点击左上角 \"完成\" 退出终端${nco}"
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
		echo -e "${nco} 点击左上角 \"完成\" 退出终端${nco}"
		echo
		exit
	fi
}

fixupPermissions(){
	if [ -e "/var/tmp" ]; then
		if [ "$(stat -c "%U:%G" /var/tmp)" != "root:root" ]; then
			chown 0:0 /var/tmp
			if [ $? -eq 0 ]; then
				echo "修改/var/tmp的所有者成功!"
			else
				echo "修改/var/tmp的所有者失败"
			fi
		else
			echo "权限正确，无需修改/var/tmp的所有者权限"
		fi

		if [ "$(stat -c "%a" /var/tmp)" != "777" ]; then
			chmod 777 /var/tmp
			if [ $? -eq 0 ]; then
				echo "修改/var/tmp的权限成功!"
			else
				echo "修改/var/tmp的权限失败"
			fi
		else
			echo "权限正确，无需修改/var/tmp的权限"
		fi
	else
		echo "/var/tmp不存在"
	fi

	if [ -e "/var/tmp/com.apple.appstored" ]; then
		if [ "$(stat -c "%U:%G" /var/tmp/com.apple.appstored)" != "501:root" ]; then
			chown 501:0 /var/tmp/com.apple.appstored
			if [ $? -eq 0 ]; then
				echo "修改/var/tmp/com.apple.appstored的所有者成功!"
			else
				echo "修改/var/tmp/com.apple.appstored的所有者失败"
			fi
		else
			echo "权限正确，无需修改/var/tmp/com.apple.appstored的权限"
		fi

		if [ "$(stat -c "%a" /var/tmp/com.apple.appstored)" != "700" ]; then
			chmod 700 /var/tmp/com.apple.appstored
			if [ $? -eq 0 ]; then
				echo "修改/var/tmp/com.apple.appstored的权限成功!"
			else
				echo "修改/var/tmp/com.apple.appstored的权限失败"
			fi
		else
			echo "权限正确，无需修改/var/tmp/com.apple.appstored的权限"
		fi
	else
		echo "/var/tmp/com.apple.appstored不存在"
	fi

	echo
  	echo -e "${nco} 已成功修复商店无法下载的问题,感谢耐心等待!${nco}"
  	echo

  	clear
	yes '' | sed 2q
	echo -e "${nco} 点击左上角 \"完成\" 退出终端${nco}"
	echo
	exit
}

echo
echo -e "${nco} 欢迎使用一键备份和恢复工具${nco}"
echo -e "${nco} 本工具由预言小猫优化整合，由M哥修改${nco}"
echo -e "${nco} 鸣谢：菠萝 & 建哥${nco}"
echo
echo -e "${nco} 请选择对应功能${nco}"
echo -e " [1] - ${nco}备份${nco}"
echo -e " [2] - ${nco}恢复${nco}"
echo -e " [3] - ${nco}修复（商店无法下载应用）${nco}"
echo -e " [q] - ${nco}退出${nco}"
echo
while true; do
	echo -ne " (1/2/3/q): ${nco}"
	read st
	case $st in
		[1] ) st=1;
		break;;
		[2] ) st=2;
		break;;
  		[3] ) st=3;
    		break;;
		[Qq] ) st=q;
		break;;
		* ) echo -e ${red}" 请输入 1 或 2 或3 或 q ！"${nco};
	esac
done

if [ $st = 1 ]; then
	clear
	backup
elif [ $st = 2 ]; then
	clear
	recover
elif [ $st = 3 ]; then
	clear
	fixupPermissions
else
	clear
	yes '' | sed 2q
	echo -e "${nco} 点击左上角 \"完成\" 退出终端${nco}"
	echo
	exit
fi
