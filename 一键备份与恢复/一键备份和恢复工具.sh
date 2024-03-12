#!/bin/bash
PATH=/var/jb/bin:/var/jb/usr/bin:/var/jb/sbin:/var/jb/usr/sbin:$PATH

# colors
red="\033[38;5;196m"
nco="\033[0m" #no color
num=0

bak_dir=./插件备份
tweaksetting_dir=./插件配置备份
sources_dir=./源地址备份

mkd(){
	if [ ! -e $1 ]; then
        mkdir $1;
    fi;
}

if [[ $EUID -ne 0 ]]; then
	echo
	echo -e ${red}" 权限不足！"
	echo
	echo -e ${red}" 请先执行"1.权限修改"文件"
	echo
	exit
fi
	
tweak2backup(){
	deps="$(dpkg --get-selections | grep -v -E 'deinstall|gsc\.|cy\+|swift-|build-|llvm|clang' | grep -vw 'git' | grep -vwFf ./tweak_exclude_list | cut -f1 | awk '{print $1}')"
   	for pkg in $deps; do
		num=$(($num+1))
		echo -e "${nco} 正在备份第"$num"个插件，请耐心等待...${nco}"
		ver=`dpkg-query -s "$pkg" | grep Version | awk '{print $2}'`
		arc=`dpkg-query -s "$pkg" | grep Architecture: | awk '{print $2}'`
  		name=$(dpkg-deb -f "$(dpkg-query -L "$pkg" | grep -m1 "/DEBIAN/" | sed 's/\/DEBIAN.*$//')" Name)
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
		dpkg-query -s "$pkg" | grep -v Status >>"$bak_dir"/"$name"_"$ver"_"$arc"/DEBIAN/control
		if [ -d /var/jb/Library/dpkg/info ];then
			cp /var/jb/Library/dpkg/info/"$pkg".postinst "$bak_dir"/"$name"_"$ver"_"$arc"/DEBIAN/postinst 2> /dev/null
			cp /var/jb/Library/dpkg/info/"$pkg".preinst "$bak_dir"/"$name"_"$ver"_"$arc"/DEBIAN/preinst 2> /dev/null
			cp /var/jb/Library/dpkg/info/"$pkg".postrm "$bak_dir"/"$name"_"$ver"_"$arc"/DEBIAN/postrm 2> /dev/null
			cp /var/jb/Library/dpkg/info/"$pkg".prerm "$bak_dir"/"$name"_"$ver"_"$arc"/DEBIAN/prerm 2> /dev/null
			cp /var/jb/Library/dpkg/info/"$pkg".extrainst_ "$bak_dir"/"$name"_"$ver"_"$arc"/DEBIAN/extrainst_ 2> /dev/null
			cp /var/jb/Library/dpkg/info/"$pkg".extrainst "$bak_dir"/"$name"_"$ver"_"$arc"/DEBIAN/extrainst 2> /dev/null
			cp /var/jb/Library/dpkg/info/"$pkg".control-e "$bak_dir"/"$name"_"$ver"_"$arc"/DEBIAN/control-e 2> /dev/null
			cp /var/jb/Library/dpkg/info/"$pkg".triggers "$bak_dir"/"$name"_"$ver"_"$arc"/DEBIAN/triggers 2> /dev/null
			cp /var/jb/Library/dpkg/info/"$pkg".conffiles "$bak_dir"/"$name"_"$ver"_"$arc"/DEBIAN/conffiles 2> /dev/null
			cp /var/jb/Library/dpkg/info/"$pkg".ldid "$bak_dir"/"$name"_"$ver"_"$arc"/DEBIAN/ldid 2> /dev/null
			cp /var/jb/Library/dpkg/info/"$pkg".crash_reporter "$bak_dir"/"$name"_"$ver"_"$arc"/DEBIAN/crash_reporter 2> /dev/null
		else
			cp /var/lib/dpkg/info/"$pkg".postinst "$bak_dir"/"$name"_"$ver"_"$arc"/DEBIAN/postinst 2> /dev/null
			cp /var/lib/dpkg/info/"$pkg".preinst "$bak_dir"/"$name"_"$ver"_"$arc"/DEBIAN/preinst 2> /dev/null
			cp /var/lib/dpkg/info/"$pkg".postrm "$bak_dir"/"$name"_"$ver"_"$arc"/DEBIAN/postrm 2> /dev/null
			cp /var/lib/dpkg/info/"$pkg".prerm "$bak_dir"/"$name"_"$ver"_"$arc"/DEBIAN/prerm 2> /dev/null
			cp /var/lib/dpkg/info/"$pkg".extrainst_ "$bak_dir"/"$name"_"$ver"_"$arc"/DEBIAN/extrainst_ 2> /dev/null
			cp /var/lib/dpkg/info/"$pkg".extrainst "$bak_dir"/"$name"_"$ver"_"$arc"/DEBIAN/extrainst 2> /dev/null
			cp /var/lib/dpkg/info/"$pkg".control-e "$bak_dir"/"$name"_"$ver"_"$arc"/DEBIAN/control-e 2> /dev/null
			cp /var/lib/dpkg/info/"$pkg".triggers "$bak_dir"/"$name"_"$ver"_"$arc"/DEBIAN/triggers 2> /dev/null
			cp /var/lib/dpkg/info/"$pkg".conffiles "$bak_dir"/"$name"_"$ver"_"$arc"/DEBIAN/conffiles 2> /dev/null
			cp /var/lib/dpkg/info/"$pkg".ldid "$bak_dir"/"$name"_"$ver"_"$arc"/DEBIAN/ldid 2> /dev/null
			cp /var/lib/dpkg/info/"$pkg".crash_reporter "$bak_dir"/"$name"_"$ver"_"$arc"/DEBIAN/crash_reporter 2> /dev/null
		fi

		SAVEIFS=$IFS
		IFS=$'\n'
		files=$(dpkg-query -L "$pkg"|sed "1 d")
		for i in $files; do
			if [ -d "$i" ]; then
				mkdir -p "$bak_dir"/"$name"_"$ver"_"$arc"/"$i"
			elif [ -f "$i" ]; then
				cp -p "$i" "$bak_dir"/"$name"_"$ver"_"$arc"/"$i"
			fi
		done
		IFS=$SAVEIFS

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
		echo -e "${nco} 已成功备份"$num"个插件${nco}"
		dpkg-deb -b "$bak_dir"/"$name"_"$ver"_"$arc" "$bak_dir"/"$name"_"$ver"_"$arc".deb
		rm -rf "$bak_dir"/"$name"_"$ver"_"$arc"
		echo
	done

	clear
	unset pkg
	yes '' | sed 2q
	echo -e "${nco} DONE！插件备份完成！${nco}"
	echo
}

setting2backup(){
	echo -e "${nco} 正在进行配置备份，请耐心等待...${nco}"
	cp -a /var/jb/User/Library ./"$tweaksetting_dir"/ 2> /dev/null
	cp -a /var/jb/etc/apt/sources.list.d ./"$sources_dir"/ 2> /dev/null
	
	clear
	yes '' | sed 2q
	echo -e "${nco} DONE！配置备份完成！${nco}"
	echo
}

backup(){
	mkd $bak_dir
	mkd $tweaksetting_dir
	mkd $others_dir
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
		echo -e "${nco} 开始进行插件备份！${nco}"
		echo
		tweak2backup
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
		echo
		setting2backup
	else
		clear
		yes '' | sed 2q
		echo -e "${nco} 已跳过配置备份！${nco}"
		echo
	fi

	echo -e "${nco} 备份流程已结束，感谢耐心等待！${nco}"
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
		if [ -d ./"$bak_dir" -a "`ls -A ./"$bak_dir"`" != "" ]; then
			echo -e "${nco} 正在安装插件，请耐心等待...${nco}"
			sleep 4s
			dpkg -i ./"$bak_dir"/*.deb
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
		cp -a ./"$tweaksetting_dir"/* /var/jb/User/
		cp -a ./"$sources_dir"/sileo.sources /var/jb/etc/apt/sources.list.d/
		chown mobile:staff /var/jb/User/Library/Preferences
		echo -e "${nco} 插件设置恢复成功${nco}"

		sleep 2s
		echo
		echo -e "${nco} 恢复流程已结束，即将注销生效，请稍等...${nco}"
		sleep 1s
		killall -9 backboardd
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

echo
echo -e "${nco} 欢迎使用一键备份和恢复工具${nco}"
echo -e "${nco} 本工具由预言小猫优化整合，由M哥修改${nco}"
echo -e "${nco} 鸣谢：菠萝 & 建哥${nco}"
echo
echo -e "${nco} 请选择对应功能${nco}"
echo -e " [1] - ${nco}一键备份所有插件和配置${nco}"
echo -e " [2] - ${nco}一键安装所有插件并恢复配置${nco}"
echo -e " [q] - ${nco}退出工具${nco}"
echo
while true; do
	echo -ne " (1/2/q): ${nco}"
	read st
	case $st in
		[1]* ) st=1;
		break;;
		[2]* ) st=2;
		break;;
		[Qq]* ) st=q;
		break;;
		* ) echo -e ${red}" 请输入 1 或 2 或 q ！"${nco};
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
	echo -e "${nco} 点击左上角 \"完成\" 退出终端${nco}"
	echo
	exit
fi                                                                
