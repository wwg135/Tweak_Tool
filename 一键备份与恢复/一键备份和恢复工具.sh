#!/bin/bash
PATH=/var/jb/bin:/var/jb/usr/bin:/var/jb/sbin:/var/jb/usr/sbin:$PATH

export LANG=en_US.UTF-8

# colors
red="\033[38;5;196m"
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

checkPremissions(){
	f=$1$2
	if [ -e $f ]; then
		f_p=`stat -c %a $f`
		if [ $f_p != '555' ] && [ $f_p != '755' ] && [ $f_p != '775' ] && [ $f_p != '777' ]; then
			chmod 755 $f
		fi
		echo $2
	fi
	echo ""
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
	tweak2backup
}
	
tweak2backup(){
	yes '' | sed 2q
	echo -e "${nco} 开始进行插件备份！${nco}"
	echo
	echo -e " [1] - ${nco}备份所有插件和依赖${nco}"
	echo -e " [2] - ${nco}备份插件过滤系统依赖${nco}"
	echo
	while true; do
		echo -ne " (1/2): ${nco}"
		read st
		case $st in
			[1]* ) st=1;
			echo;
			echo -e "${nco} 开始备份...${nco}";
			echo;
			break;;
			[2]* ) st=2;
			echo;
			echo -e "${nco} 开始备份...${nco}";
			echo;
			break;;
			* ) echo -e ${red}" 请输入 1 或 2 "${nco};
		esac
	done
	if [ $st = 1 ]; then
		debs="$(dpkg --get-selections | grep -v -E 'deinstall|gsc\.|cy\+|swift-|build-|llvm|clang' | grep -vw 'git' | cut -f1 | awk '{print $1}')"
	elif [ $st = 2 ]; then
		debs="$(dpkg --get-selections | grep -v -E 'deinstall|gsc\.|cy\+|swift-|build-|llvm|clang' | grep -vw 'git' | grep -vwFf /var/jb/usr/local/lib/tweak_exclude_list | cut -f1 | awk '{print $1}')"
	fi

  	thread_num=50
	tempfifo=/var/tmp/$$.fifo
	mkfifo $tempfifo
	exec 5<>${tempfifo}
	rm -rf ${tempfifo}
	for((i=1;i<=$thread_num;i++))
	do
		echo ;
	done >&5
	
	for pkg in $debs; do
	read -u5
	{
		ver=`dpkg-query -s "$pkg" | grep Version | awk '{print $2}'`
		arc=`dpkg-query -s "$pkg" | grep Architecture: | awk '{print $2}'`
  		name=`dpkg-query -s "$pkg" | grep Name | awk '{print $2}'`
		if [ -d /var/jb/xina ] && [ ! -f /var/jb/.installed_xina15 ]; then
			cp /var/lib/dpkg/info/"$pkg".list /var/lib/dpkg/info/"$pkg".list.debra
			cat /var/lib/dpkg/info/"$pkg".list | grep -v "/var" > /var/lib/dpkg/info/"$pkg".list.nonvar
			sed -i -e 's#^#/var/jb#' /var/lib/dpkg/info/"$pkg".list.nonvar
			cat /var/lib/dpkg/info/"$pkg".list | grep "/var" > /var/lib/dpkg/info/"$pkg".list.var
			cat /var/lib/dpkg/info/"$pkg".list.var >> /var/lib/dpkg/info/"$pkg".list.nonvar
			rm -f /var/lib/dpkg/info/"$pkg".list.var
			rm -f /var/lib/dpkg/info/"$pkg".list
			mv -f /var/lib/dpkg/info/"$pkg".list.nonvar /var/lib/dpkg/info/"$pkg".list
		fi
		mkdir -p "$bak_dir"/"$name"_"$ver"_"$arc"/DEBIAN
		dpkg-query -s "$pkg" | grep -v Status>>"$bak_dir"/"$name"_"$ver"_"$arc"/DEBIAN/control
		if [ -d /var/jb/Library/dpkg/info ];then
			path=/var/jb/Library/dpkg/info/
			postinst="$pkg".postinst
	  		ret=`checkPremissions $path $postinst`
	  		route="${ret} ${route}"
			preinst="$pkg".preinst
	  		ret=`checkPremissions $path $preinst`
	  		route="${ret} ${route}"
			postrm="$pkg".postrm
	  		ret=`checkPremissions $path $postrm`
	  		route="${ret} ${route}"
			prerm="$pkg".prerm
	  		ret=`checkPremissions $path $prerm`
	  		route="${ret} ${route}"
			extrainst_="$pkg".extrainst_
	  		ret=`checkPremissions $path $extrainst_`
	  		route="${ret} ${route}"
			extrainst="$pkg".extrainst
	  		ret=`checkPremissions $path $extrainst`
	  		route="${ret} ${route}"
			control="$pkg".control-e
	  		ret=`checkPremissions $path $control`
	  		route="${ret} ${route}"
			triggers="$pkg".triggers
	  		ret=`checkPremissions $path $triggers`
	  		route="${ret} ${route}"
			conffiles="$pkg".conffiles
	  		ret=`checkPremissions $path $conffiles`
	  		route="${ret} ${route}"
			ldid="$pkg".ldid
	  		ret=`checkPremissions $path $ldid`
	  		route="${ret} ${route}"
	  		crash_reporter="$pkg".crash_reporter
	  		ret=`checkPremissions $path $crash_reporter`
	  		route="${ret} ${route}"
		else
			path=/var/lib/dpkg/info/
			postinst="$pkg".postinst
	  		ret=`checkPremissions $path $postinst`
	  		route="${ret} ${route}"
			preinst="$pkg".preinst
	  		ret=`checkPremissions $path $preinst`
	  		route="${ret} ${route}"
			postrm="$pkg".postrm
	  		ret=`checkPremissions $path $postrm`
	  		route="${ret} ${route}"
			prerm="$pkg".prerm
	  		ret=`checkPremissions $path $prerm`
	  		route="${ret} ${route}"
			extrainst_="$pkg".extrainst_
	  		ret=`checkPremissions $path $extrainst_`
	  		route="${ret} ${route}"
			extrainst="$pkg".extrainst
	  		ret=`checkPremissions $path $extrainst`
	  		route="${ret} ${route}"
			control="$pkg".control-e
	  		ret=`checkPremissions $path $control`
	  		route="${ret} ${route}"
			triggers="$pkg".triggers
	  		ret=`checkPremissions $path $triggers`
	  		route="${ret} ${route}"
			conffiles="$pkg".conffiles
	  		ret=`checkPremissions $path $conffiles`
	  		route="${ret} ${route}"
			ldid="$pkg".ldid
	  		ret=`checkPremissions $path $ldid`
	  		route="${ret} ${route}"
	  		crash_reporter="$pkg".crash_reporter
	  		ret=`checkPremissions $path $crash_reporter`
	  		route="${ret} ${route}"
		fi
		(cd $path ;tar cvfp - $route ) | (cd "$bak_dir"/"$name"_"$ver"_"$arc"/DEBIAN ;tar xvfp -)

		cd "$bak_dir"/"$name"_"$ver"_"$arc"/DEBIAN/
		mv -f $postinst postinst >/dev/null 2>&1 || true
		mv -f $preinst preinst >/dev/null 2>&1 || true
		mv -f $postrm postrm >/dev/null 2>&1 || true
		mv -f $prerm prerm >/dev/null 2>&1 || true
		mv -f $extrainst_ extrainst_ >/dev/null 2>&1 || true
		mv -f $extrainst extrainst >/dev/null 2>&1 || true
		mv -f $control control-e >/dev/null 2>&1 || true
		mv -f $triggers triggers >/dev/null 2>&1 || true
		mv -f $conffiles conffiles >/dev/null 2>&1 || true
		mv -f $ldid ldid >/dev/null 2>&1 || true
		mv -f $crash_reporter crash_reporter >/dev/null 2>&1 || true

		SAVEIFS=$IFS
		IFS=$'\n'
		files=$(dpkg-query -L "$pkg"|sed "1 d")
		route=""
		for i in $files; do
			if [ -f "$i" ]; then
				i=`echo ${i##*jb}`
				i=$(echo $i|sed 'y/ /*/')
				route=".${i} ${route}"
			fi
		done
		IFS=$SAVEIFS
		mkdir -p "$bak_dir"/"$name"_"$ver"_"$arc"/var/jb
		(cd /var/jb/ ;tar cvfp - $route ) | (cd "$bak_dir"/"$name"_"$ver"_"$arc"/var/jb ;tar xvfp -)

		rootdir="$bak_dir"/"$name"_"$ver"_"$arc"
		if [ -d /var/jb/xina ] && [ ! -f /var/jb/.installed_xina15 ]; then
			if [ -d "$rootdir"/var/jb ]; then
				mkdir -p "$rootdir"/temp
				mv -f "$rootdir"/var/jb/.* "$rootdir"/var/jb/* "$rootdir"/temp >/dev/null 2>&1 || true
				rm -rf "$rootdir"/var/jb
				[ -d "$rootdir"/var ] && [ "$(ls -A "$rootdir"/var)" ] && : || rm -rf "$rootdir"/var
				mv -f "$rootdir"/temp/.* "$rootdir"/temp/* "$rootdir" >/dev/null 2>&1 || true
				rm -rf "$rootdir"/temp
			fi
			mv -f /var/lib/dpkg/info/"$pkg".list.debra /var/lib/dpkg/info/"$pkg".list
		fi

		echo
		dpkg-deb -b "$bak_dir"/"$name"_"$ver"_"$arc" >/dev/null 2>&1
		rm -rf "$bak_dir"/"$name"_"$ver"_"$arc" 2>&1
		echo
		echo "" >&5
	} &
	done
	wait
	exec 5>&-

 	echo
  	num=0
  	for pkg in $debs; do
    		num=$((num+1))
	done
  	echo -e "已成功备份 ${red}"$num"${nco} 个插件，如下列表："
   	echo
	IFS=$'\n'
	num=0
	for i in $debs; do
		num=$((num+1))
		name=$(dpkg-query -s "$i" | grep "Name:" | cut -d' ' -f2)    
		echo "$num. $name"
	done
	IFS=$SAVEIFS
	echo
	for ((i=5; i>=0; i--)); do
		echo -e "\r${red}$i${nco}秒后进行配置备份...\c"
		sleep 1
	done

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
 	if [[ -f "/var/jb/.installed_dopamine" ]]; then
    		jailbreak="dp"
	elif [[ -f "/var/jb/.installed_xina15" ]]; then
    		jailbreak="x2"
	fi
	new_dir="/var/mobile/${jailbreak}_backup_$(TZ=UTC-8 date +'%Y.%m.%d_%H.%M.%S')"
	mkdir $new_dir
 	for file in /var/mobile/tweak_tool/*; do
     		if [[ $file == "/var/mobile/tweak_tool/一键备份和恢复工具.sh" ]]; then
       			cp "$file" "$new_dir/"
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
