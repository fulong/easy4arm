#!/bin/bash
#configure.sh
temp_file=/tmp/cross_configure #暂存文件

####################项目的源码目录汇总###################################
#目录中只包含了没有系统，跟CPU无关的代码目录
OS_dir="/os/"
ARCH_dir="/cortex-m3 /arm920t /cortex-a8" #这个变量表示函数NoARCH_AND_NoOS_Source_Path中消除的文件夹
extend_dir="/tools_src/"
lib_dir="libc/"
#额外的一些项目名字，如果要增加不同项目，只需要在这里增加该项目名字
proj_name_setting="setting---->图形界面配置预定义项目程序编写\n"
proj_name_testarm="testarm---->测试用的arm程序\n"
proj_name_test="test---->测试用的linux程序\n"
#proj_name_other="other---->这个程序扩展端，可以在这个地方增加功能。\n"
proj_name_mkimage4a8="mkimage4a8---->制作a8镜像的程序\n"

proj_name_extern_sum="$proj_name_setting\
$proj_name_testarm\
$proj_name_test\
$proj_name_mkimage4a8\
$proj_name_other"

cpu_relate_local_num=(0 2 4 6)
cpu_relate=(armv7-m cortex-m3 armv4t arm920t armv7-a cortex-a8 x86 x86)
#cpu_relate的索引表，这些数字代表，下面数组中，arch所在的位置，相隔的多少，就是在这个arch里面有多少个减1这么多个cpu内核。
#cpu_relate,如果有新的arch 和cpu内核，需要在这两个数组中登记，cpu_relate_local_num数组负责索引arch位置，cpu_relate的存储方式为arch，cpu，cpu，。。。。

######################全局变量######################################
cross_select= #编译器类型存储
arch_select= #指令集选型
cpu_select= #CPU内核选型
exe_dir= #可执行文件，与反汇编文件所在
LDS_BAK=share/lds #链接脚本备份文件所在的文件夹
sum_dir= #需要用到的代码可能所在的目录。
NoARCH_AND_NoOS_Source_Path()
{
	sum_dir=$(find $root_dir -type d | grep -v '^\./\.')

	local Csources=$(find $root_dir |grep -v '^\./\.' | grep '\.c$') # | sed 's/^\..*\///g')
	local Ssources=$(find $root_dir |grep -v '^\./\.' | grep '\.S$') # | sed 's/^\..*\///g')
if [ "$root_dir" = "." ];then
	for TEMP in $ARCH_dir $OS_dir $extend_dir
	do
		sum_dir=$(echo "$sum_dir" | grep -v "$TEMP")
		Csources=$(echo "$Csources" | grep -v "$TEMP")
		Ssources=$(echo "$Ssources" | grep -v "$TEMP")
	done	
		Csources=$(echo "$Csources" | grep -v "$lib_dir")
		Ssources=$(echo "$Ssources" | grep -v "$lib_dir")	
fi
	echo "#############增加NoARCH相关源文件与目录####################" >>${mk_name}
	Csources=$(echo -n $Csources)
	echo "Csources=$Csources" >>${mk_name}
	Ssources=$(echo -n $Ssources)
	echo "Ssources=$Ssources" >>${mk_name}

	sum_dir=$(echo -n $sum_dir) #将所有行连接在一起，并使他们在同一行
	echo "VPATH=$sum_dir" >> ${mk_name}
	echo "#############增加NoARCH相关源文件与目录####################" >>${mk_name}
#	echo "GPATH=$sum_dir" >> ${mk_name}
}
####################项目的源码目录汇总###################################

####################项目的自定义源码目录###################################
#
#brief:根据需要来增添相应的源码目录跟相应源码
#
#parm:目前有
#		1.cortex-m3,增添cortex-m3源码目录跟cortex-m3源码
#		2.OS,增添OS源码目录跟OS源码
#		3.自定义添加文件,目录
#note:只支持一个参数，这个函数不能单独使用，因为参数不能为空
Source_Path()
{
	sum_dir_temp=$(find $root_dir -type d | grep -v '^\./\.' | grep "$1")
	local Csources=$(find $root_dir | grep -v '^\./\.' | grep '\.c$' | grep "$1" ) # | sed 's/^\..*\///g')
	local Ssources=$(find $root_dir | grep -v '^\./\.' | grep '\.S$' | grep "$1" ) # | sed 's/^\..*\///g')
	Csources=$(echo -n $Csources)
	Ssources=$(echo -n $Ssources)
	echo "#############增加$1相关源文件与目录####################" >>${mk_name}
	echo "Csources+=$Csources" >>${mk_name}
	echo "Ssources+=$Ssources" >>${mk_name}

	sum_dir_temp=$(echo -n $sum_dir_temp) #将所有行连接在一起，并使他们在同一行
	echo "VPATH+=$sum_dir_temp" >> ${mk_name}
#	echo "GPATH+=$sum_dir_temp" >> ${mk_name}
	sum_dir="$sum_dir $sum_dir_temp"
	echo "#############增加$1相关源文件与目录####################" >>${mk_name}
}
#configure.sh
######################定义项目名称######################################
ProjectName() 
{
	local flag=1 #初始化这个自动变量，使下面的能正确使用这个变量
	while [ "$flag" != "0"  ];do
	dialog --clear
	dialog --title "项目名称" --inputbox "请输入你当前使用项目名称。第一次配置时，这个为空时，会为默认.刚配置是默认为Myarm.\n" 20 50  2> $temp_file
	
	proj_name=$(cat $temp_file)
	flag=0
	if [ -z "$proj_name" ];then
	dialog --title "再次确认" --yesno "你将会使用默认的项目名称，你确定要这样做吗？" 10 30
	flag=$?
	fi
	done
}
######################定义项目名称######################################
####################项目是否选用OS###################################
lib_Select()
{
	local OS_VAR='ucos-ii\nRT-Thread\nuFL-os\n' #可供选择的指令集
	local flag=1 #初始化这个自动变量，使下面的能正确使用这个变量
	local libc
		while [ "$flag" != "0" ];do
	dialog --clear
	dialog --title "OS版本选择" --inputbox "请输入你当前使用的OS名称。你可以选择的OS(目前支持).\n$OS_VAR" 20 50  2> $temp_file
	
	OS_choice=$(cat $temp_file)
	flag=0
	if [ -z "$OS_choice" ];then
		dialog --title "再次确认" --yesno "你将不使用OS，你确定要这样做吗？" 10 30
		flag=$?
		if [ "$flag" = "0" ];then
			OS=""
		fi
	elif [ "$OS_choice" != "ucos-ii" ] && [ "$OS_choice" != "RT-Thread" ]  && [ "$OS_choice" != "uFL-os" ] ;then
		dialog --title "你可以选择的OS(目前支持),请输入正确的OS名称"  --msgbox "$OS_VAR" 20 50
		flag=1
	fi
	done
	#	echo "OS=$OS">> ${mk_name}
	dialog --title "使用libc库吗？" --yesno "要使用libc库吗？" 10 30
	flag=$?
	if [ "$flag" = "0" ];then
		libc="YES"
	else 
		libc=""
	fi
	if ! [ "$OS" = "" ];then
		echo "OS=${OS_choice}">> ${mk_name}
		echo "LIBA+=os/${OS_choice}.a" >> ${mk_name}
	else
		echo "OS=${OS}">> ${mk_name}
	fi	
	echo "libc=${libc}">> ${mk_name}
	if ! [ "$libc" = "" ];then
		echo "LIBA+=lib.a" >> ${mk_name}
	fi		
}
####################项目是否选用lib###################################
#################交叉编译器版本选择#####################################
CrossCompiler_Select()
{
	local cross_item_num=2
	local cross_item='1 none 2 arm-uclinuxeabi 3 arm-none-eabi'
	
	local flag=1 #初始化这个自动变量，使下面的能正确使用这个变量
    #判断选择的是哪个编译器版本。
	while [ "$flag" != "0" ];do
	dialog --clear
dialog --title "交叉编译器版本" --menu "你将会选择哪个版本？" 10 30 ${cross_item_num} ${cross_item} --title "再次确认" --yesno "你确定要这样做吗？" 10 30 2> $temp_file
	flag=$?
	done
	
	cross_select=$(cat $temp_file)
	
	if [ "$cross_select" = "2" ];then
	echo "CROSS_COMPILER=arm-none-eabi-" >> ${mk_name}
	cross_select=arm-none-eabi-
	elif [ "$cross_select" = "3" ];then
	echo "CROSS_COMPILER=arm-uclinuxeabi-" >> ${mk_name}
	cross_select=arm-uclinuxeabi-
	elif [ "$cross_select" = "1" ];then
		if [ "$proj_name" = "$proj_name_bak" ] || [ "$proj_name" = "testarm" ];then
			echo "CROSS_COMPILER=arm-none-eabi-" >> ${mk_name}
			cross_select=arm-none-eabi-
		else
			echo "CROSS_COMPILER=" >> ${mk_name}
			cross_select=
		fi	
	fi
}
#################交叉编译器版本选择#####################################
####################指令集版本选择####################################
#Permissible names are: `armv2', `armv2a', `armv3', `armv3m', 
#`armv4', `armv4t', `armv5', `armv5t', `armv5e', `armv5te', `armv6', `armv6j', `armv6t2', `armv6z', `armv6zk', `armv6-m',
#`armv7', `armv7-a', `armv7-r', `armv7-m', `iwmmxt', `iwmmxt2', `ep9312'.
#输入指令集版本选择。
ARCH_Select()
{
	local arch_temp
	local i=0
	local ARCH_sum
	while [ "$i" -lt "${#cpu_relate_local_num[*]}" ];do
		ARCH_sum="${cpu_relate[${cpu_relate_local_num[i]}]}\n$ARCH_sum"
		i=`expr $i + 1`
	done
	local flag=1 #初始化这个自动变量，使下面的能正确使用这个变量
	while [ "$flag" != "0" ];do
	dialog --clear
	dialog --title "指令集版本选择" --inputbox "请输入你当前使用的指令集名称。你可以选择的指令集(目前支持).\n$ARCH_sum" 20 50  2> $temp_file
	
	arch_select=$(cat $temp_file)
	flag=0
	if [ -z "$arch_select" ];then
	dialog --title "再次确认" --yesno "你将会使用GCC默认的指令集，你确定要这样做吗？" 10 30
	flag=$?
	arch_select=armv4t
	else
		arch_temp=`echo $ARCH_sum | grep $arch_select`
		if [ -z "$arch_temp" ] ;then
		dialog --title "你可以选择的指令集(目前支持),请输入正确的指令集名称"  --msgbox "$ARCH_sum" 20 50
		flag=1
		fi
	fi
	done
	
	echo "ARCH=$arch_select" >> ${mk_name}
}
####################指令集版本选择####################################
####################CPU内核版本选择####################################
#Permissible names are: `arm2', `arm250', `arm3', `arm6', `arm60', `arm600', `arm610', `arm620', `arm7', `arm7m', `arm7d', `arm7dm', `arm7di', `arm7dmi', `arm70', `arm700', `arm700i', `arm710', `arm710c', `arm7100', `arm720', `arm7500', `arm7500fe', `arm7tdmi', `arm7tdmi-s', `arm710t', `arm720t', `arm740t', `strongarm', `strongarm110', `strongarm1100', `strongarm1110', `arm8', `arm810', `arm9', `arm9e', `arm920', 
#`arm920t', `arm922t', `arm946e-s', `arm966e-s', `arm968e-s', `arm926ej-s', `arm940t', `arm9tdmi', `arm10tdmi', `arm1020t', `arm1026ej-s', `arm10e', `arm1020e', `arm1022e', `arm1136j-s', `arm1136jf-s', `mpcore', `mpcorenovfp', `arm1156t2-s', `arm1156t2f-s', `arm1176jz-s', `arm1176jzf-s', `cortex-a5', `cortex-a7', 
#`cortex-a8', `cortex-a9', `cortex-a15', `cortex-r4', `cortex-r4f', `cortex-r5', `cortex-m4', `
#cortex-m3', `cortex-m1', `cortex-m0', `xscale', `iwmmxt', `iwmmxt2', `ep9312', `fa526', `fa626', `fa606te', `fa626te', `fmp626', `fa726te'.
#输入CPU内核版本选择。
#$1,系统选择的指令集合
CPU_Select()
{
	local cpu_temp
	local cpu_index
	local arch_temp=$1
	local i=0
	local k=0
	local ARCH_sum
	local CPU_sum
	while [ "$i" -lt "${#cpu_relate_local_num[*]}" ];do
		ARCH_sum="${cpu_relate[${cpu_relate_local_num[i]}]}"
		if [ "$arch_temp" == $ARCH_sum ];then
			cpu_index=${cpu_relate_local_num[i]}
			i=`expr $i + 1`
			break
		fi
		i=`expr $i + 1`
	done
	if [ "$i" -eq "${#cpu_relate_local_num[*]}" ];then
		i=${#cpu_relate[*]}
		i=`expr ${i} - ${cpu_index}`
		i=`expr  ${i} - 1`
	else
		i=`expr ${cpu_relate_local_num[i]} - ${cpu_index}`
		i=`expr ${i} - 1`
	fi
	while [ "$i" -gt "0" ];do
		k=`expr ${cpu_index} + ${i}`
		CPU_sum="${cpu_relate[${k}]}\n$CPU_sum"
		i=`expr $i - 1`
	done	
		
	local flag=1 #初始化这个自动变量，使下面的能正确使用这个变量
	while [ "$flag" != "0" ];do
	dialog --clear
	dialog --title "CPU内核版本" --inputbox "请输入你当前使用的CPU内核版本名称。你可以选择的CPU内核版本(目前支持).\n$CPU_sum" 20 50  2> $temp_file
	
	cpu_select=$(cat $temp_file)
	flag=0
	if [ -z "$cpu_select" ];then
	if [ "$i" == "0" ];then #如果不是唯一的选项，空文本将会无效，那时一定要有输入文本才行
	dialog --title "再次确认" --yesno "你将会使用GCC默认的CPU内核版本，你确定要这样做吗？" 10 30
	flag=$?
	cpu_select=${cpu_relate[${k}]}
	fi
	else
	cpu_temp=`echo $CPU_sum | grep $cpu_select`
		if [ -z "$cpu_temp" ] ;then
			dialog --title "你可以选择的CPU内核版本(目前支持),请输入正确的CPU内核版本名称"  --msgbox "$CPU_sum" 20 50
			flag=1
		fi
	fi
	done
	
	echo "CPU=$cpu_select" >> ${mk_name}
}
####################CPU内核版本选择####################################
####################生成的bin文件跟反汇编文件所在的路径####################################
#这里所需要的O文件都是中间文件，所以到最后，这些都将在编译成功后删除掉。
dir4exe()
{
	local flag=1 #初始化这个自动变量，使下面的能正确使用这个变量
	local exe_bak_temp
	exe_bak_temp=$(echo "$exe_dir_bak_var" | sed 's/^.*=//g')
	#	echo "$exe_bak_temp"
	#read
	if [ -z "$exe_bak_temp" ];then
	while [ "$flag" != "0" ];do
		dialog --title "设置${proj_name}的.o文件输出的路径" --inputbox "请输入${proj_name}的.o文件的链接路径，这路径也是链接脚本所在的位置。最终链接生成的bin文件跟反汇编文件将会移动到这个路径中。格式为:exe_dir" 20 50  2> $temp_file
		exe_dir=$(cat $temp_file)
		if [ -z "$exe_dir" ];then
			dialog --title "再次确认" --yesno "bin文件跟反汇编文件将在根目录上，你确定要这样做吗？" 10 30 
			flag=$?
			if [ "$flag" = "0" ];then
				echo "exe_dir=$root_dir" >> ${mk_name}
				exe_dir=$root_dir
			fi
		else
			mkdir -p $root_dir/$exe_dir
			echo "exe_dir=$root_dir/$exe_dir" >> ${mk_name}
			exe_dir=$root_dir/$exe_dir
			flag=0
		fi
			echo "2a\\${proj_name}_exe_dir_bak=$exe_dir" > sed.sh
			sed -i -f sed.sh configure_type.mk
			rm sed.sh*	
	done
	else
		echo "exe_dir=$exe_bak_temp" >> ${mk_name}
		exe_dir=$exe_bak_temp
	fi
}
###################生成的bin文件跟反汇编文件所在的路径####################################

