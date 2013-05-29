###############################################################
#@file mkfile.mod
#@brief 编译以当前目录为根目录的所有代码
#@data 2012-6-22-21:21
###############################################################

SHELL=/bin/bash
proj_name=
proj_name_bin=
root_dir=
exe_dir=
sinclude $(proj_name).mk
ifeq "$($(proj_name)_mk)" "YES" #判断两个配置文件是否存在.
configure_on=YES
else
configure_on=NO
endif

OBJ = $(Csources:.c=.o) $(Ssources:.S=.o)

ifeq "$(configure_on)" "YES"
include_open=$(shell cat ${log_dir}/$(proj_name).log | tail -n1)
endif

Depend_OBJ=$(OBJ:.o=.d)
.PHONY:status allclean update configure all clean distclean install setting dclean change2others
ifeq "$(configure_on)" "YES"
all:
	@echo "include_open" >> ${log_dir}/$(proj_name).log
#	@make $(OBJ)
	@make $(proj_name_bin)
	@echo "工程编译安装完成" | tee -a ${log_dir}/$(proj_name).log
	@date >> ${log_dir}/$(proj_name).log    

$(proj_name_bin):$(OBJ)
ifeq "$(HOST)" "arm"
	${LD} ${LD_FLAGS} -o ${exe_dir}/$(proj_name).elf $^
	@echo "链接完成" | tee -a ${log_dir}/$(proj_name).log
	${OBJCOPY} ${OBJCOPY_FLAGS} ${exe_dir}/$(proj_name).elf ${exe_dir}/$@
	${OBJDUMP} ${OBJDUMP_FLAGS} ${exe_dir}/$(proj_name).elf > ${exe_dir}/$(proj_name).dis
	@echo "$@与反汇编文件生成完毕" | tee -a ${log_dir}/$(proj_name).log
	@echo "elf中间文件删除完毕" | tee -a ${log_dir}/$(proj_name).log
	@date >> ${log_dir}/$(proj_name).log
else
	gcc -o ${exe_dir}/$@ $^
endif
%.d::%.S
	@echo "自动更新$*.S的依赖"
	@echo "$*.o:$*.S" > $@
	@sed -i 's/\.o:/\.d :/g' $@
	@echo "$*.o:$*.S" >> $@
	@sed -i '$$a\\t$$(AS) $$(ASFLAGS) $$< -o $$@ ' $@
	@sed -i '$$a\\t@echo "完成$*.o的生成" >> ${log_dir}/obj.log' $@
	@sed -i '$$a\\t@date >> ${log_dir}/obj.log' $@
	@echo "完成$*.s的依赖的生成" >> ${log_dir}/depend.log;
	@date >> ${log_dir}/depend.log
%.d::%.c
	@echo "自动更新$*.c的依赖"
	@echo "$*.d:\\"> $@
	@$(CC) -MM  $< >> $@
	@echo "$*.temp__:\\">> $@
	@$(CC) -MM  $< >> $@
	@sed -i 's/^.*\.o://g' $@
	@sed -i 's/\.temp__/\.o/g' $@
	@sed -i '$$a\\t$$(CC) $$(CFLAGS) $$< -o $$@ ' $@
	@sed -i '$$a\\t@echo "完成$*.o的生成" >> ${log_dir}/obj.log' $@
	@sed -i '$$a\\t@date >> ${log_dir}/obj.log' $@
	@echo "$*.c的依赖生成完成" >> ${log_dir}/depend.log;
	@date >> ${log_dir}/depend.log
endif #ifeq "$(configure_on)" "YES"
ifeq "$(configure_on)" "YES"
update: #这个目标可以修复因文件变化，却没及时删除前面依赖于这个文件多出的冗余文件。
	@echo "更新目录,文件变化" | tee -a ${log_dir}/$(proj_name).log
	@date >> ${log_dir}/$(proj_name).log 
	@$(root_dir)/tools/update.sh $(root_dir)/$(proj_name).mk $(root_dir) $(CPU)
	
allclean:clean dclean
clean :
	${RM}  ${log_dir}/obj.log ${OBJ} ${exe_dir}/$(proj_name).dis
	${RM}  ${exe_dir}/$(proj_name_bin)
	@echo "清除所有o文件,bin与反汇编文件,日志文件" | tee -a -a ${log_dir}/$(proj_name).log
	@date >> ${log_dir}/$(proj_name).log
dclean :
	${RM} $(Depend_OBJ) ${log_dir}/depend.log
	@echo "清除依赖文件" | tee -a -a ${log_dir}/$(proj_name).log
	@date >> ${log_dir}/$(proj_name).log
distclean:
	@echo "清除所有自动生成的文件" | tee -a ${log_dir}/other.log
	@date >> ${log_dir}/other.log
	@${RM} $(root_dir)/$(proj_name).mk
	${RM} ${log_dir}/${proj_name}.log
	${RM}   ${root_dir}/*.lds
	${RM}   ${root_dir}/Makefile
endif #ifeq "$(configure_on)" "YES"

status:
ifneq "$(configure_on)" "YES"
	@echo "configure文件不存在" && exit 1
endif
ifeq "$(configure_type)" "$(proj_name_bak)"
	@echo "Makefile目前在ARM项目状态中"
	@echo "使用的处理器为$(ARCH)"
endif

#如果使用了下面语句，makefile将自动重建依赖文件
ifeq "$(include_open)" "include_open"
sinclude $(Depend_OBJ)
endif
