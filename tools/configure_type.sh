#!/bin/bash
#用来生成configure_type.mk
#$2,表示可以删除的目录。只有在distclean目标中才会有值。
#$3,表示当前arm项目的名字。只有在distclean目标中才会有值。
#configure_type，表示项目目前所在的项目属性。
#1.prj_configure，这里代表的是arm项目。
#2.setting_tools_configure，这里代表项目是关于setting的，因为项目有编写setting这个程序的源代码，所以要分开来管理。
#3.mkimage4a8_configure，这里代表项目是关于mkimage4a8的
#HOST，代表编译出来的目标文件是什么指令系统的。
#1.arm
#2.x86
temp_file=/tmp/cross_configure #暂存文件
temp_item=
temp4prj_name=$3
if ! [ -z "$2" ];then
for temp in $2
do
	if [ "$temp" == "${temp4prj_name}.mk" ];then
			temp_item="proj  --->$temp\n$temp_item"
	elif [ "$temp" == "setting.mk" ];then
			temp_item="setting  --->$temp\n$temp_item"
	elif [ "$temp" == "mkimage4a8.mk" ];then
			temp_item="mkimage4a8  --->$temp\n$temp_item"
	else
			echo "unkonw:$temp"
			echo "工程不会生成这个mk文件。"
	fi	
done
fi
#exit 1
proj_name= #项目的名字
source tools/lib.sh
project=
proj_Select()
{
if [ -z "$temp_item" ];then
	local proj_VAR='proj\nsetting\nmkimage4a8\n' #可供选择的项目类型
	temp_information="请输入使用的项目名称。你可以选择的项目名称(目前支持的)如下.\n"
else
	local proj_VAR=$temp_item;
	temp_information="请输入转换的项目名称。你可以选择的项目名称(目前支持的)如下.\n"
fi
	local flag=1 #初始化这个自动变量，使下面的能正确使用这个变量
	local proj_select=
	while [ "$flag" != "0" ];do
	dialog --clear
if [ "$1" == "YES" ];then
	dialog --title "项目类型选择" --inputbox "${temp_information}${proj_VAR}" 20 50  2> $temp_file
	proj_select=$(cat $temp_file)
fi
	case $proj_select in
		"proj" )
			project=prj_configure
			;;
		"setting")
			project=setting_tools_configure
			;;
		"mkimage4a8")
			project=mkimage4a8_configure
			;;
			*)
				if [ -z "$proj_select" ];then 
					project= 
				else 
					echo "项目类型选择有错。"
					project=pro_error 
				fi
			;;
esac
	flag=0
	if [ -z "$project" ];then
		if [ "$1" == "YES" ];then
			dialog --title "再次确认" --yesno "你将会使用默认的项目名称，你确定要这样做吗？" 10 30
		fi
		flag=$?
		project=prj_configure
	elif [ "$project" != "prj_configure" ] && [ "$project" != "setting_tools_configure" ] && [ "$project" != "mkimage4a8_configure" ] ;then
	dialog --title "你可以选择的项目名称(目前支持),请输入正确的项目名称"  --msgbox "$proj_VAR" 20 50
	flag=1
	fi
	done
}
if ! [ "$1" == "YES" ];then
		proj_Select $1
		ProjectName
		echo 'configure_type_mk=YES' > configure_type.mk
		echo "configure_type=$project" >> configure_type.mk
		echo 'HOST=arm' >> configure_type.mk
		echo "proj_name_bak=$proj_name" >> configure_type.mk
		echo "proj_name=$proj_name" >> configure_type.mk
else
		proj_Select $1
case "$project" in
	"prj_configure") 		
		export `cat configure_type.mk | grep "proj_name_bak="`
		sed -i '$d' configure_type.mk
		echo "proj_name=$proj_name_bak" >> configure_type.mk
		unset proj_name_bak
		sed -i 's/^configure_type=.*$/configure_type=prj_configure/g' configure_type.mk
		sed -i 's/^HOST=.*$/HOST=arm/g' configure_type.mk
		echo "转到arm项目"
	;;
	"setting_tools_configure")
		sed -i '$d' configure_type.mk
		echo "proj_name=setting" >> configure_type.mk
		sed -i 's/^configure_type=.*$/configure_type=setting_tools_configure/g' configure_type.mk
		sed -i 's/^HOST=.*$/HOST=x86/g' configure_type.mk	
		echo "转到x86项目"
		;;
	"mkimage4a8_configure")
		sed -i '$d' configure_type.mk
		echo "proj_name=mkimage4a8" >> configure_type.mk
		sed -i 's/^configure_type=.*$/configure_type=mkimage4a8_configure/g' configure_type.mk
		sed -i 's/^HOST=.*$/HOST=x86/g' configure_type.mk	
		echo "转到x86项目"
		;;
		*)
		echo "项目类型有误。"
		exit 1
	;;
esac
fi
sleep 1
exit 0