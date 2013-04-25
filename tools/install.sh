#!/bin/bash
# @file install.sh
# @brief 安装bin文件到工程中，或者将bin文件烧入到设备中。
# @parm $1,传递的是工程所在的状态。
# @parm $2,传递的是工程所在的处理器架构，从而可以选择不一样的处理bin文件的方式
proj_name=$1
ARCH=$2
proj_name4arm=$3
imagefor210_name=fulong210.bin
echo "安装中........"
if [ -z "$proj_name" ] || [ -z "$ARCH" ];then
	echo "$proj_name"
	echo "$ARCH"
	echo "Error!!Please correct to config this project."
	exit 1
fi
mk_name=${proj_name}.mk
tools_install_dir=./tools
install_dir=$(grep 'exe_dir=' $mk_name)
export $install_dir
if [ -f "${exe_dir}/${proj_name}.bin" ];then
case "$ARCH" in
	"x86")
	echo "安装${proj_name}.bin工具"
	cp ${exe_dir}/${proj_name}.bin ${tools_install_dir}/
	
	;;
	"armv4t")
	sudo usb2ram ${exe_dir}/${proj_name}\.bin
	exit 0
	;;
	"armv7-a")
		echo "制作210镜像。"
		if [ -f "${tools_install_dir}/mkimage4a8.bin" ];then
			if [ -f "${exe_dir}/${proj_name}.bin"  ];then
				./${tools_install_dir}/mkimage4a8.bin ${exe_dir}/${proj_name}.bin ${imagefor210_name}
				echo "镜像制作完成."
			else
				echo "${exe_dir}/${proj_name}.bin不存在。"
				exit 1
			fi
		else
			echo "镜像文件工具不在。"。
			exit 1
		fi
		echo "将210镜像烧写到SD卡中的512字节以后。"
		 install_dev=
		echo "默认是sdb1，请输入设备名字。如sdb2，sdc3等等"
		read install_dev
		if [ -z "$install_dev" ];then
			install_dev=sdb
		fi
		if [ -b "/dev/${install_dev}" ];then
			sudo dd iflag=dsync oflag=dsync if=${imagefor210_name} of=/dev/${install_dev} seek=1
			echo "烧写完成"
		else
			echo "${install_dev}设备文件不存在，不能烧写"
			exit 1
		fi
		exit 0
	;;
		*)
	echo "ARCH有误。"
	exit 1
esac
else
	echo "${proj_name}.bin is not exsit."
	exit 1
fi
