#!/bin/bash
##################################################################
# @file : configure.sh
# @brief: 项目代码最初使用的时候必须先运行这个脚本，配置好编译器，体系结构等等
# $1,root_dir 源码根目录
# $2,proj_name 项目的名字
# $3,表示，由其他脚本调用，用作其他功能
##################################################################
if ! [ -f "configure_type.mk"  ] ;then
echo "请正确使用configure.sh."
echo "指令：make configure"
exit 1
fi
other=$3
trap 'rm -rf configure_type.mk;exit 1' INT
######################全局变量######################################
source tools/lib.sh
#dialog --title "configure" --msgbox "项目代码最初使用的时候运行的一个脚本，配置好编译环境，体系结构等等" 10 30 
#导入项目名字
root_dir=$1
proj_name=$2
if [ -z "$root_dir" ] || [ -z "$proj_name" ] ;then
export `cat configure_type.mk | grep "proj_name="`
export `cat configure_type.mk | grep "root_dir="`
export `cat configure_type.mk | grep "proj_name_bak="`
exe_dir_bak_var=`cat configure_type.mk | grep "${proj_name}_exe_dir_bak="`
fi
#echo "$exe_dir_bak_var"
#read
# $1,源码的根目录。

configure_mk=${proj_name}_mk
mk_name=${root_dir}/${proj_name}.mk
log_dir=${root_dir}/log #日志文件所保存的文件夹
mkdir -p $log_dir

####################编译环境配置###################################
cp /dev/null $mk_name

		CrossCompiler_Select
		ARCH_Select
		CPU_Select "$arch_select"
if [ -z "$other" ];then
		dir4exe
fi
		echo "log_dir=$log_dir" >> $mk_name
echo "编译环境配置开始"
echo "#*******************工具配置*************************************" >> $mk_name
echo 'CC=$(CROSS_COMPILER)gcc' >> $mk_name
echo 'LD=$(CROSS_COMPILER)ld' >> $mk_name
echo 'OBJCOPY=$(CROSS_COMPILER)objcopy' >> $mk_name
echo 'OBJDUMP=$(CROSS_COMPILER)objdump' >> $mk_name
echo 'AS=$(CROSS_COMPILER)gcc' >> $mk_name
echo "#*******************工具配置*************************************" >> $mk_name
#*******************工具选项配置******************************************
echo "配置工具的选项"
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
    exit 1
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
    exit 1
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
    exit 1
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
#*******************项目源码生成******************************************
#源码生成的位置不能改变，因为update目标依赖着这个位置
NoARCH_AND_NoOS_Source_Path
Source_Path $cpu_select
#******************项目源码生成*******************************************
if [ -z "$other" ];then
####################项目是否选用lib###################################
lib_Select
####################项目是否选用lib###################################
fi
if [ -z "$cross_select" ];then
	HOST=x86
else
	HOST=arm
fi
if [ -z "$other" ];then
echo "s/^HOST=.*$/HOST=$HOST/g" > sed.sh
sed -i -f sed.sh configure_type.mk
rm sed.sh -fr
fi

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
