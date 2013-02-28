#!/bin/bash
# @parm $1,传递的是工程目前使用的MK文件。
# @parm $2,传递的是工程目前的类型。
mk_name=$1
cpu_select=$3
root_dir=$2
source tools/lib.sh
#update_item_order="VPATH Csources Ssources"
if [  "$1" == ".mk" ] || [ -z "$2" ] || [ -z "$3" ] ;then
	echo "MK配置不对，请重建。"
	exit 1
fi

clear_file()
{
echo "删除更新前生成的.d,.o文件"
local Dependent_tmp
local Object_tmp
if [ "$root_dir" == "." ];then
	find $root_dir  | grep '\.d$' | grep -v "$extend_dir" |  xargs rm -f
	find $root_dir  | grep '\.o$' | grep -v "$extend_dir" |  xargs rm -f
else
	find $root_dir  | grep '\.d$' |  xargs rm -f
	find $root_dir  | grep '\.o$' |  xargs rm -f
fi
}
#item_update() 
#{
##	local update_item=(Csources Ssources VPATH)
	#local row=0
	#touch sed.sh
	#local NoARCH_Csources_row=$(echo `cat $mk_name -n  | sed 's/^[ ]*//g' | grep "Csources" | cut -s -f 1 | head -n1`)
	#local CPU_Csources_row=$(echo `cat $mk_name -n  | sed 's/^[ ]*//g' | grep "Csources" | cut -s -f 1 | tail -n1`)
	#NoARCH_Csources_row=$(expr "$NoARCH_Csources_row" - "1") 
	#CPU_Csources_row=$(expr "$CPU_Csources_row" - "1") 
#case "$configure_type" in
	#"prj_configure" )
	#local OS_Csources_row=$(echo `cat $mk_name -n  | sed 's/^[ ]*//g' | grep "Csources" | cut -s -f 1 | head -n2| tail -n1`)
	#OS_Csources_row=$(expr "$OS_Csources_row" - "2") 
	#echo "${OS_Csources_row}d" >> sed.sh
	#OS_Csources_row=$(expr "$OS_Csources_row" + "1")
	#;;
	#"setting_tools_configure" )
	#local OS_Csources_row=
	#;;
	#*)
	#echo "工程状态有误"
	#exit 1
	#;;
#esac
##	echo "${update_item[2]}"
#for num in $CPU_Csources_row $NoARCH_Csources_row $OS_Csources_row
#do
	#while [ "$row" -lt "5" ]
	#do
		#row=$(expr "$row" + "1")
		#echo "${num}d" >> sed.sh
		#num=$(expr "$num" + "1")
	#done
	#row=0
#done
	##echo "`expr ${row} + 1`i${update_item}${operate}${content}" >> sed.sh
#sed -i -f sed.sh $mk_name
#rm -f sed.sh #删除这个临时文件

#NoARCH_AND_NoOS_Source_Path
#if ! [ -z "$OS_Csources_row" ];then
	#OS_Select
#fi
#Source_Path $CPU
##上面的顺序不能变

#echo "更新的行数为：包括$NoARCH_Csources_row，$CPU_Csources_row，$OS_Csources_row"
#echo "完成！！"
#}
update() 
{
	echo "删除原本MK文件中的源代码文件信息"
	local begin_row=$(echo `cat $mk_name -n  | sed 's/^[ ]*//g' | grep "NoARCH" | cut -s -f 1 | head -n1`)
	echo "${begin_row},\$d" > sed.sh
	sed -i -f sed.sh $mk_name
	rm sed.sh*
	echo "updating......"
	NoARCH_AND_NoOS_Source_Path
	Source_Path $cpu_select
	####################项目是否选用OS###################################
	OS_Select
	####################项目是否选用OS###################################
	#******************项目源码生成*******************************************
	clear
	echo "finish!"
}
clear_file
update
#item_update #"NoARCH"
#item_update "`cat configure.mk | grep "OS=" | sed 's/OS=//g'`"
#item_update "`cat configure.mk | grep "CPU=" | sed 's/CPU=//g'`"
exit 0
