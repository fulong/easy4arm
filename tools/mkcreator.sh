#!/bin/bash
# $1,lib源码的根目录，.a文件将会在这里生成。
# $2,lib的名字
# $3,扩展功能，目前通过这个可以得到某些目标需要的扩展功能。例如，libc目标，用来选择库文件编译的路径
root_dir="$1"
name="$2"

./tools/configure.sh "$root_dir" "$name" "$0"
cp share/mkfile.mod ${root_dir}/Makefile
sed_root_dir=$(echo "$root_dir" | sed 's/\//\\\//g')
sed_pre_dir=$(echo "${HOME}/workspace-arm/easy4arm/" | sed 's/\//\\\//g')
echo "s/${sed_root_dir}/\./g" > sed.sh
sed -i -f sed.sh ${root_dir}/${name}.mk
echo "s/proj_name=/proj_name=${name}/g" > sed.sh
echo "s/proj_name_bin=/proj_name_bin=${name}\.a/g" >> sed.sh
echo "s/root_dir=/root_dir=${sed_pre_dir}${sed_root_dir}/g" >> sed.sh
echo "s/exe_dir=.*$/exe_dir=\.\./g" >> sed.sh
sed -i -f sed.sh ${root_dir}/Makefile
rm -rf sed.sh
echo "配置好$name，可以编译$name了"
exit 0