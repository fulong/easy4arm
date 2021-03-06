#!/bin/bash
##################################################################
# @file : configure.sh
# @brief: 项目代码最初使用的时候必须先运行这个脚本，配置好编译器，体系结构等等
# $1,项目类型。
##################################################################
if ! [ -f "configure_type.mk"  ] ;then
echo "请正确使用configure.sh."
echo "指令：make configure"
exit 1
fi
type=$1
######################全局变量######################################
cross_select= #编译器类型存储
arch_select= #指令集选型
cpu_select= #CPU内核选型
exe_dir= #可执行文件，与反汇编文件所在
LDS_BAK=lds_bak #链接脚本备份文件所在的文件夹
OS= #选择的RT系统
trap 'rm -rf configure_type.mk;exit 1' INT
######################全局变量######################################
source tools/lib.sh
dialog --title "configure" --msgbox "项目代码最初使用的时候运行的一个脚本，配置好编译环境，体系结构等等" 10 30 
#导入项目名字
export `cat configure_type.mk | grep "proj_name="`
export `cat configure_type.mk | grep "proj_name_bak="`
if [ -z "$type" ];then
	type=$proj_name_bak
fi
proj_name_sum="${proj_name_bak}\n${proj_name_extern_sum}"
#cpu_relate的索引表，这些数字代表，下面数组中，arch所在的位置，相隔的多少，就是在这个arch里面有多少个减1这么多个cpu内核。
#cpu_relate,如果有新的arch 和cpu内核，需要在这两个数组中登记，cpu_relate_local_num数组负责索引arch位置，cpu_relate的存储方式为arch，cpu，cpu，。。。。
cpu_relate_local_num=(0 2 4 6)
cpu_relate=(armv7-m cortex-m3 armv4t arm920t armv7-a cortex-a8 x86 x86)
type_select=`echo "$proj_name_sum" | grep $type`
if [ -z "$type_select" ];then
		echo "mk文件的名字有误"
		echo "当前:$type"
		exit 1
else
	if [ "$type" == "$proj_name_bak" ];then
		root_dir=.
	else
		root_dir=tools_src/${type}
	fi
fi
configure_mk=${proj_name}_mk
mk_name=${proj_name}.mk
log_dir=${root_dir}/log #日志文件所保存的文件夹
mkdir -p $log_dir

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
	echo "CROSS_COMPILER=arm-none-eabi-" >> $mk_name
	cross_select=arm-none-eabi-
	elif [ "$cross_select" = "3" ];then
	echo "CROSS_COMPILER=arm-uclinuxeabi-" >> $mk_name
	cross_select=arm-uclinuxeabi-
	elif [ "$cross_select" = "1" ];then
	echo "CROSS_COMPILER=" >> $mk_name
	cross_select=
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
	
	echo "ARCH=$arch_select" >> $mk_name
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
	
	echo "CPU=$cpu_select" >> $mk_name
}
####################CPU内核版本选择####################################
####################生成的bin文件跟反汇编文件所在的路径####################################
#这里所需要的O文件都是中间文件，所以到最后，这些都将在编译成功后删除掉。
dir4exe()
{
	local flag=1 #初始化这个自动变量，使下面的能正确使用这个变量
	while [ "$flag" != "0" ];do
	dialog --title "设置${proj_name}的.o文件输出的路径" --inputbox "请输入${proj_name}的.o文件的链接路径，这路径也是链接脚本所在的位置。最终链接生成的bin文件跟反汇编文件将会移动到这个路径中。格式为:exe_dir" 20 50  2> $temp_file
	exe_dir=$(cat $temp_file)
	if [ -z "$exe_dir" ];then
	dialog --title "再次确认" --yesno "bin文件跟反汇编文件将在根目录上，你确定要这样做吗？" 10 30 
	flag=$?
	if [ "$flag" = "0" ];then
		echo "exe_dir=$root_dir" >> $mk_name
		exe_dir=$root_dir
	fi
	else
	mkdir -p $root_dir/$exe_dir
	echo "exe_dir=$root_dir/$exe_dir" >> $mk_name
	exe_dir=$root_dir/$exe_dir
	flag=0
	fi
	done
}
###################生成的bin文件跟反汇编文件所在的路径####################################
####################编译环境配置###################################
cp /dev/null $mk_name

		CrossCompiler_Select
		ARCH_Select
		CPU_Select "$arch_select"
		dir4exe
		echo "log_dir=$log_dir" >> $mk_name

echo "编译环境配置开始"
sleep 1
echo "#*******************工具配置*************************************" >> $mk_name
echo 'CC=$(CROSS_COMPILER)gcc' >> $mk_name
echo 'LD=$(CROSS_COMPILER)ld' >> $mk_name
echo 'OBJCOPY=$(CROSS_COMPILER)objcopy' >> $mk_name
echo 'OBJDUMP=$(CROSS_COMPILER)objdump' >> $mk_name
echo 'AS=$(CROSS_COMPILER)gcc' >> $mk_name
echo "#*******************工具配置*************************************" >> $mk_name
#*******************工具选项配置******************************************
echo "配置工具的选项"
sleep 1
CFLAGS='-c -Wall -ffunction-sections '
ASFLAGS='-c -Wall -ffunction-sections'
LD_FLAGS='--gc-sections '
echo 'CFLAGS = -c -Wall -ffunction-sections' >> $mk_name
echo 'ASFLAGS = -c -Wall -ffunction-sections' >> $mk_name
echo 'LD_FLAGS = --gc-sections ' >> $mk_name

if ! [ "$arch_select" = "x86" ];then
OBJCOPY_FLAGS='-O binary -S'
OBJDUMP_FLAGS='-D -m arm'
CFLAGS="${CFLAGS} -nostdlib"
ASFLAGS="${ASFLAGS} -nostdlib"
echo 'OBJCOPY_FLAGS = -O binary -S' >> $mk_name
echo 'OBJDUMP_FLAGS = -D -m arm' >> $mk_name
fi
#有些时候编译不通过，加上O选项的话
if [ "$cross_select" = "arm-uclinuxeabi-" ] || [ "$cpu_select" != "cortex-m3" ];then
echo '#好像GCC不太支持CM3' >> $mk_name
echo 'CFLAGS += -O2' >> $mk_name
echo 'ASFLAGS += -O2' >> $mk_name
echo '#好像GCC不太支持CM3' >> $mk_name
CFLAGS="$CFLAGS -O2"
ASFLAGS="$ASFLAGS -O2"
fi
#根据CPU型号加上相应的编译选项
if [ "$arch_select" = "armv7-m" ];then
case "$cpu_select" in
  "cortex-m3" )
	echo "#添加$cpu_select相关标志" >> $mk_name
    echo 'CFLAGS += -march=$(ARCH) -mthumb -mcpu=$(CPU) ' >> $mk_name
    echo 'ASFLAGS += -march=$(ARCH) -mthumb -mcpu=$(CPU) ' >> $mk_name
	echo 'LD_FLAGS += -T$(exe_dir)/$(CPU).lds' >> $mk_name
	echo "#添加$cpu_select相关标志" >> $mk_name
    CFLAGS="$CFLAGS -march=$arch_select -mthumb -mcpu=$cpu_select"
    ASFLAGS="$ASFLAGS -march=$arch_select -mthumb -mcpu=$cpu_select"
    LD_FLAGS="$LD_FLAGS -T$exe_dir/$cpu_select.lds"
    cp -rf $LDS_BAK/$cpu_select.lds.bak.txt $exe_dir/$cpu_select.lds
      ;;
  *) 
    echo "cpu选型有误，与指令集版本不匹配，请重新配置一次。"
    rm $mk_name
    exit 0
    ;;
esac
fi
if [ "$arch_select" = "armv7-a" ];then
case "$cpu_select" in
  "cortex-a8" )
	echo "#添加$cpu_select相关标志" >> $mk_name
    echo 'CFLAGS += -march=$(ARCH) -mthumb -mcpu=$(CPU) ' >> $mk_name
    echo 'ASFLAGS += -march=$(ARCH) -mthumb -mcpu=$(CPU) ' >> $mk_name
    echo 'LD_FLAGS += -T$(exe_dir)//$(CPU).lds' >> $mk_name
	echo "#添加$cpu_select相关标志" >> $mk_name
    CFLAGS="$CFLAGS -march=$arch_select -mthumb -mcpu=$cpu_select"
	ASFLAGS="$ASFLAGS -march=$arch_select -mthumb -mcpu=$cpu_select"
    LD_FLAGS="$LD_FLAGS -T$exe_dir/$cpu_select.lds"
    cp -rf $LDS_BAK/$cpu_select.lds.bak.txt $exe_dir/$cpu_select.lds
    ;;
  *) 
    echo "cpu选型有误，与指令集版本不匹配，请重新配置一次。"
    rm $mk_name
    exit 0
    ;;
esac
fi
if [ "$arch_select" = "armv4t" ];then
case "$cpu_select" in
  "arm920t" )
	echo "#添加$cpu_select相关标志" >> $mk_name
      echo 'CFLAGS += -march=$(ARCH) -mcpu=$(CPU)' >> $mk_name
      echo 'ASFLAGS += -march=$(ARCH) -mcpu=$(CPU)' >> $mk_name
      echo 'LD_FLAGS += -T$(exe_dir)/$(CPU).lds' >> $mk_name
	echo "#添加$cpu_select相关标志" >> $mk_name
      CFLAGS="$CFLAGS -march=$arch_select -mcpu=$cpu_select"
      ASFLAGS="$ASFLAGS -march=$arch_select -mcpu=$cpu_select"
      LD_FLAGS="$LD_FLAGS -T$exe_dir/$cpu_select.lds"
      cp -rf $LDS_BAK/$cpu_select.lds.bak.txt $exe_dir/$cpu_select.lds
      ;;
  *) 
    echo "cpu选型有误，与指令集版本不匹配，请重新配置一次。"
    rm $mk_name
    exit 0
    ;;
esac
fi
if [ "$arch_select" = "x86" ];then
	echo "~~~还未有其他的FLAGS项。~~~~"
fi
#*******************工具选项配置******************************************

#configure文件标志设置，表示文件生成成功。
echo "$configure_mk=YES" >> $mk_name
############创建工程的日志文件。############
touch $log_dir/obj.log $log_dir/depend.log
if ! [ -f "$log_dir/${proj_name}.log" ];then 
touch $log_dir/${proj_name}.log
fi
########################################
echo "RM=rm -rf">> $mk_name
echo "root_dir=$root_dir">> $mk_name
#*******************项目源码生成******************************************
#源码的位置不能改变，因为update目标依赖着这个位置
NoARCH_AND_NoOS_Source_Path
Source_Path $cpu_select
####################项目是否选用OS###################################
OS_Select
####################项目是否选用OS###################################
#******************项目源码生成*******************************************
#*******************项目源码生成******************************************
clear
echo "配置完成。"
echo "项目名称：$proj_name"
echo "指令集:$arch_select"
echo "CPU内核版本:$cpu_select"
echo "CC工具为${cross_select}gcc "
echo "LD工具为${cross_select}ld "
echo "OBJCOPY工具为${cross_select}objcopy "
echo "OBJDUMP工具为${cross_select}objdump "
echo "AS工具为${cross_select}gcc "
echo "CC的选项为$CFLAGS"
echo "AS的选项为$ASFLAGS"
echo "LD的选项为$LD_FLAGS"
echo "OBJCOPY的选项为$OBJCOPY_FLAGS"
echo "OBJDUMP的选项为$OBJDUMP_FLAGS"
echo "bin文件跟反汇编文件将在$exe_dir/目录中"
echo "自动生成的日志文件文件在$log_dir/目录上"
echo "项目的所有目录(VPATH的值) ： $sum_dir"
#*******************工具选项配置******************************************
####################编译环境配置###################################
exit 0
