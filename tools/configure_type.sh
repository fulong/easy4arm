#!/bin/bash
#用来生成configure_type.mk
#$2,表示可以删除的目录。只有在distclean目标中才会有值。
#$3,表示当前arm项目的名字。
#$1,说明configure_type.mk存不存在。
#configure_type，表示项目目前所在的项目属性。
#1.proj，这里代表的是arm项目。
#2.setting，这里代表项目是关于setting的，因为项目有编写setting这个程序的源代码，所以要分开来管理。
#3.mkimage4a8，这里代表项目是关于mkimage4a8的
source tools/lib.sh

configure_exist=$1
temp_item=
temp_item_var="$2"
temp4prj_name=$3
if [ -z "$temp4prj_name" ];then
	temp4prj_name=proj
fi
proj_name_sum="${temp4prj_name}---->主程序\n${proj_name_extern_sum}"
#exit 1
proj_name= #项目的名字
project=
prj_check()
{
	local check_proj_mk_temp
	local check_proj_name_temp
if ! [ -z "$temp_item_var" ];then
for temp in $temp_item_var
do
#检查项目名字是否存在。
	check_proj_name_temp=`echo "$temp" | sed 's/\..*$//g'`
	check_proj_mk_temp=`echo "$proj_name_sum" | grep "$check_proj_name_temp"`
	if [ -z "$check_proj_mk_temp" ];then
			echo "unknown:$temp"
			echo "工程不会生成这个mk文件。"
	else		
			temp_item="$check_proj_name_temp--->$temp\n$temp_item"
	fi
done
else
	temp_item="$proj_name_sum"
fi
}
#$1,可供选择的项目类型
proj_Select()
{
	local proj_VAR="$1"
	local temp_information="请输入转换的项目名称。你可以选择的项目名称(目前支持的)如下.\n"
	local flag=1 #初始化这个自动变量，使下面的能正确使用这个变量
	local proj_select=
	local check_proj_temp
	while [ "$flag" != "0" ];do
	dialog --clear
if [ "$configure_exist" == "YES" ];then
	dialog --title "项目类型选择" --inputbox "${temp_information}${proj_VAR}" 20 50  2> $temp_file
	proj_select=$(cat $temp_file)
fi
	if [ -z "$proj_select" ];then 
		project= 
	else
		check_proj_temp=`echo "$proj_name_sum" | grep "$proj_select"`
		if ! [ -z "$check_proj_temp" ];then
			project=${proj_select}
		else
			echo "项目类型选择有错。"
			project=pro_error
		fi 
	fi
	flag=0
	if [ -z "$project" ];then
		if [ "$configure_exist" == "YES" ];then
			dialog --title "再次确认" --yesno "你将会使用默认的项目名称，你确定要这样做吗？" 10 30
		fi
		flag=$?
		project=${temp4prj_name}
	elif [ "$project" == "pro_error" ]  ;then
	dialog --title "你可以选择的项目名称(目前支持),请输入正确的项目名称"  --msgbox "$proj_VAR" 20 50
	flag=1
	fi
	done
}

		prj_check
		proj_Select $temp_item
if ! [ "$configure_exist" == "YES" ];then
		#设置项目名称,proj_name。
		ProjectName
		if [ -z "$proj_name" ];then 
			proj_name=Myarm
		fi
		echo 'configure_type_mk=YES' > configure_type.mk
		echo "root_dir=." >> configure_type.mk
		echo "configure_type=$proj_name" >> configure_type.mk
		echo 'HOST=arm' >> configure_type.mk
		echo "proj_name_bak=$proj_name" >> configure_type.mk
		echo "proj_name=$proj_name" >> configure_type.mk
else
		proj_name=$project
		case "$proj_name" in
		"$temp4prj_name" )
			root_dir=.
			HOST=arm
			;;
		#		"other" )
			#	root_dir=__other
			#	;;
		* )
			root_dir=tools_src\\/${proj_name}
			;;
		esac
		echo "\$d" > sed.sh
		echo "s/^configure_type=.*$/configure_type=$project/g" >> sed.sh
		echo "s/^HOST=.*$/HOST=$HOST/g" >> sed.sh
		echo "s/^root_dir=.*$/root_dir=$root_dir/g" >> sed.sh
		sed -i -f sed.sh configure_type.mk
		echo "proj_name=$proj_name" >> configure_type.mk
		rm sed.sh -fr
fi
exit 0