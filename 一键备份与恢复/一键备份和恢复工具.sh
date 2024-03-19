#!/bin/bash
PATH=/var/jb/bin:/var/jb/usr/bin:/var/jb/sbin:/var/jb/usr/sbin:$PATH

export LANG=en_US.UTF-8

# colors
red="\033[38;5;196m"
blu="\033[38;5;39m"
nco="\033[0m" #no color
num=0

bak_dir=/var/mobile/tweak_tool/插件备份
tweaksetting_dir=/var/mobile/tweak_tool/插件配置备份
sources_dir=/var/mobile/tweak_tool/源地址备份

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

_check_dpkg_run(){
	_wait=1
	while [ '1' -le '2' ]; do
		_check="$(ps -ef | grep dpkg | grep -v grep | grep -v "$$" | grep -v "sudo ${0##*/}" | wc -l)"
		if [ "${_check}" -ge '1' ]; then
			_wait="$((_wait+1))"
			sleep 1
		else
			break
		fi
	done
	unset _check _wait
}

_run(){
	if [ -n "${_package_row}" ]; then
		case "${_lack}" in
			description)
				_fill="Description: An awesome MobileSubstrate tweak"\!
			;;
			maintainer)
				_fill="Maintainer: someone"
			;;
			*)
				break
			;;
		esac
		if [ -n "${_fill}" ]; then
			sed -i.tmp "${_package_row}a ${_fill}" "${_stash_file}"
		fi
	fi
	unset _package _package_row _lack _fill
}

dpkgfill(){
	_command="${0##*/}"
	shopt -s expand_aliases 2>>/dev/null
	if which lecho 2>>/dev/null 1>>/dev/null; then
		if [ -n "${LANG}" ]; then
			alias lecho="lecho -c ${0##*/} -l ${LANG}"
		else
			alias lecho="lecho -c ${0##*/}"
		fi
	fi
	unset _check

	_check_dpkg_run
	i='0'
	i_max="$(dpkg -S / 2>&1 | grep -E 'escription|aintainer' | wc -l)"
	if [ "${i_max}" -eq '0' ]; then
		echo -e "${nco} 没有发现错误${nco}";
	else
		_stash_file_0="$(dpkg -S / 2>&1)"
		_stash_file_0="${_stash_file_0#*\'}"
		_stash_file_0="${_stash_file_0%%\'*}"
		if [ -z "$(echo "${_stash_file_0}" | grep '/')" ]; then
			_stash_file='/var/lib/dpkg/status'
		else
			_stash_file="${_stash_file_0}"
		fi
		unset _stash_file_0
		while [ "${i}" -le "${i_max}" ]; do
			case "$(dpkg -S / 2>&1 | grep -E 'warning|escription|aintainer' | sed -n 2p)" in
				*escription*)
					_lack='description'
					;;
				*aintainer*)
					_lack='maintainer'
					;;
				*)
					break
					;;
			esac
			_package="$(dpkg -S / 2>&1 | grep -E 'warning|escription|aintainer' | sed -n 1p)"
			_package="${_package%\'*}"
			_package="${_package##*\'}"
			_package_row="$(sed -n "/^Package: ${_package}$/=" "${_stash_file}")"
			_check_dpkg_run
			_run
			i="$((i+1))"
		done
		echo -e "${nco} 已修补包缺失信息${nco}";
	fi
	rm -f "${_stash_file}.tmp"
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
	rootdir="$bak_dir"/"$name"_"$ver"_"$arc"
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
	
	if [ $st = 3 ]; then
		clear
		yes '' | sed 2q
		pkgendnumber=`j=1;for i in $(dpkg --get-selections | grep -v -E 'deinstall|gsc\.|cy\+|swift-|build-|llvm|clang' | grep -vw 'git' | grep -vwFf /var/jb/usr/local/lib/tweak_exclude_list | awk '{print $1}');do echo -e $j:$i;j=$[j+1];done|tail -1|awk -F ":" '{print $1}'`
		printf  " ${nco}已安装的插件数量: %-24s\n" "$pkgendnumber"
		j=1;for i in $(dpkg --get-selections | grep -v -E 'deinstall|gsc\.|cy\+|swift-|build-|llvm|clang' | grep -vw 'git' | grep -vwFf /var/jb/usr/local/lib/tweak_exclude_list | awk '{print $1}');do name=`dpkg-query -s "$i" | grep Name | awk '{print $2}'` echo -e "$(printf " ${nco}%-59s${nco}" "${blu}$j${nco}: ${nco}$name")";j=$[j+1];done
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

setting2backup(){
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
	if [ -d "$bak_dir" ] || [ -d "$tweaksetting_dir" ] || [ -d "$sources_dir" ]; then
    		rm -rf "$bak_dir" "$tweaksetting_dir" "$sources_dir"
	fi

	mkd $bak_dir
	mkd $tweaksetting_dir
	mkd $sources_dir
	
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
			[1]* ) st=1;
			break;;
			[2]* ) st=2;
			break;;
			* ) echo -e ${red}" 请输入 1 或 2 ！"${nco};
		esac
	done

	if [ $st = 1 ]; then
		yes '' | sed 2q
		echo -e "${nco} 开始检查包完整性！${nco}"
		start_time_plugins=$(date +%s)
		echo
		dpkgfill
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
			[1]* ) st=1;
			break;;
			[2]* ) st=2;
			break;;
			* ) echo -e ${red}" 请输入 1 或 2 ！"${nco};
		esac
	done

	if [ $st = 1 ]; then
		yes '' | sed 2q
		echo -e "${nco} 开始进行配置备份！${nco}"
		start_time_settings=$(date +%s)
		echo
		setting2backup
		end_time_settings=$(date +%s)
		settings_time=$((end_time_settings-start_time_settings))
	else
		clear
		yes '' | sed 2q
		echo -e "${nco} 已跳过配置备份！${nco}"
		echo
	fi

	echo
 	if [[ -f /var/jb/.installed_dopamine ]]; then
    		jailbreak="dp"
	elif [[ -f /var/jb/.installed_xina15 ]]; then
    		jailbreak="x2"
	fi
	new_dir="/var/mobile/${jailbreak}_backup_$(TZ=UTC-8 date +'%Y.%m.%d_%H.%M.%S')"
	mkdir $new_dir
 	for file in /var/mobile/tweak_tool/*; do
     		if [[ $file == "/var/mobile/tweak_tool/一键备份和恢复工具.sh" ]]; then
       			continue
     		else
       			mv "$file" "$new_dir/"
     		fi
   	done
   	echo -e "${nco}新备份文件：${red}$new_dir"
	echo

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
			[1]* ) st=1;
			break;;
			[2]* ) st=2;
			break;;
			* ) echo -e ${red}" 请输入 1 或 2 ！"${nco};
		esac
	done

	if [ $st = 1 ]; then
		yes '' | sed 2q
		echo -e "${nco} 开始进行恢复！${nco}"
		sleep 1s
		echo
		echo -e "${nco} 准备中,开始安装插件${nco}"
		echo
		if [ -d "$bak_dir" -a "`ls -A "$bak_dir"`" != "" ]; then
			echo -e "${nco} 正在安装插件，请耐心等待...${nco}"
			sleep 4s
			dpkg -i "$bak_dir"/*.deb
			echo -e "${nco} 插件安装完成${nco}"
		else
			echo -e "${nco} 没有找到备份的插件，即将跳过...${nco}"
		fi

		sleep 2s
		echo
		echo -e "${nco} 开始创建插件目录${nco}"
		mkd /var/jb/User/Library/Preferences
		echo -e "${nco} 目录创建成功${nco}"

		sleep 2s
		echo
		echo -e "${nco} 开始恢复插件设置${nco}"
		cp -a "$tweaksetting_dir"/* /var/jb/User/
		cp -a "$sources_dir"/* /var/jb/etc/apt/
		chown mobile:staff /var/jb/User/Library/Preferences
		echo -e "${nco} 插件设置恢复成功${nco}"

		sleep 2s
		echo
		echo -e "${nco} 恢复流程已结束，即将注销生效，请稍等...${nco}"
		sleep 1s
		killall -9 backboardd
		killall -9 SpringBoard
		EOF
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
  	for ((i=5; i>=0; i--)); do
  	echo -e "\r${red}$i${nco}秒后自动返回开始菜单...\c"
  		sleep 1
  	done

   	clear
  	main
}

main(){
	echo
	echo -e "${nco} 欢迎使用一键备份和恢复工具${nco}"
	echo -e "${nco} 本工具由预言小猫优化整合，由M哥修改${nco}"
	echo -e "${nco} 鸣谢：菠萝 & 建哥${nco}"
	echo
	echo -e "${nco} 请选择对应功能${nco}"
	echo -e " [1] - ${nco}一键备份所有插件和配置${nco}"
	echo -e " [2] - ${nco}一键安装所有插件并恢复配置${nco}"
	echo -e " [3] - ${nco}一键修复App Store无法下载${nco}"
	echo -e " [q] - ${nco}退出工具${nco}"
	echo
	while true; do
		echo -ne " (1/2/3/q): ${nco}"
		read st
		case $st in
			[1]* ) st=1;
			break;;
			[2]* ) st=2;
			break;;
  			[3]* ) st=3;
    			break;;
			[Qq]* ) st=q;
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
}


echo
echo -e "${nco} 欢迎使用一键备份和恢复工具${nco}"
echo -e "${nco} 本工具由预言小猫优化整合，由M哥修改${nco}"
echo -e "${nco} 鸣谢：菠萝 & 建哥${nco}"
echo
echo -e "${nco} 请选择对应功能${nco}"
echo -e " [1] - ${nco}一键备份所有插件和配置${nco}"
echo -e " [2] - ${nco}一键安装所有插件并恢复配置${nco}"
echo -e " [3] - ${nco}修复App Store无法下载${nco}"
echo -e " [q] - ${nco}退出工具${nco}"
echo
while true; do
	echo -ne " (1/2/3/q): ${nco}"
	read st
	case $st in
		[1]* ) st=1;
		break;;
		[2]* ) st=2;
		break;;
  		[3]* ) st=3;
    		break;;
		[Qq]* ) st=q;
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
