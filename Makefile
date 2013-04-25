###############################################################
#@file Makefile
#@brief 编译整个项目
#@data 2012-6-22-21:21
###############################################################
#configure_type：项目类型，目前有setting，arm，这个向脚本传递的信息。

SHELL=/bin/bash
sinclude configure_type.mk

sinclude $(proj_name).mk

ifeq "$(configure_type_mk)$($(proj_name)_mk)" "YESYES" #判断两个配置文件是否存在.
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
	@make $(proj_name).bin
	@echo "工程编译安装完成" | tee -a ${log_dir}/$(proj_name).log
	@date >> ${log_dir}/$(proj_name).log    

$(proj_name).bin:$(OBJ)
ifeq "$(HOST)" "arm"
	${LD} ${LD_FLAGS} -o ${exe_dir}/$(proj_name).elf $^
	@echo "链接完成" | tee -a ${log_dir}/$(proj_name).log
	${OBJCOPY} ${OBJCOPY_FLAGS} ${exe_dir}/$(proj_name).elf ${exe_dir}/$(proj_name).bin
	${OBJDUMP} ${OBJDUMP_FLAGS} ${exe_dir}/$(proj_name).elf > ${exe_dir}/$(proj_name).dis
	@echo "$(proj_name).bin与反汇编文件生成完毕" | tee -a ${log_dir}/$(proj_name).log
	@echo "elf中间文件删除完毕" | tee -a ${log_dir}/$(proj_name).log
	@date >> ${log_dir}/$(proj_name).log
else
	gcc -o ${exe_dir}/$(proj_name).bin $^
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
configure:
ifeq "$($(proj_name)_mk)" ""
	@./tools/configure_type.sh
	@./tools/configure.sh 
endif
install:
	@./tools/install.sh $(proj_name) "$(ARCH)" $(proj_name_bak)
	@echo "安装完成" | tee -a ${log_dir}/$(proj_name).log
	@date >> ${log_dir}/$(proj_name).log
ifeq "$(configure_on)" "YES"
update: #这个目标可以修复因文件变化，却没及时删除前面依赖于这个文件多出的冗余文件。
	@echo "更新目录,文件变化" | tee -a ${log_dir}/$(proj_name).log
	@date >> ${log_dir}/$(proj_name).log 
	@./tools/update.sh $(proj_name).mk $(root_dir) $(CPU)
setting:
	@./tools/setting.bin
change2others:
	@cp configure_type.mk type.bak
	@./tools/configure_type.sh "$(configure_type_mk)" "" $(proj_name_bak)
	@export `cat configure_type.mk | grep "proj_name="`;if [ -f "$${proj_name}.mk" ];then \
	rm type.bak;echo "成功改变。";\
	else mv type.bak configure_type.mk;echo "$${proj_name}.mk文件不存在,改变失败。";\
	fi
compilingx:
	@./tools/configure_type.sh "$(configure_type_mk)" "" $(proj_name_bak)
	@export `cat configure_type.mk | grep "configure_type="`;./tools/configure.sh $$configure_type
allclean:clean dclean
clean :
	${RM}  ${log_dir}/obj.log ${OBJ} ${exe_dir}/$(proj_name).dis
	${RM}  ${exe_dir}/$(proj_name).bin
	@echo "清除所有o文件,bin与反汇编文件,日志文件" | tee -a -a ${log_dir}/$(proj_name).log
	@date >> ${log_dir}/$(proj_name).log
dclean :
	${RM} $(Depend_OBJ) ${log_dir}/depend.log
	@echo "清除依赖文件" | tee -a -a ${log_dir}/$(proj_name).log
	@date >> ${log_dir}/$(proj_name).log
distclean:
	@echo "清除所有自动生成的文件" | tee -a ${log_dir}/other.log
	@date >> ${log_dir}/other.log
	@make allclean
	@cp $(proj_name).mk $(proj_name).bak;
	 ${RM} $(proj_name).mk
	@mktmp=$$(echo -n `ls *.mk | sed  s/configure_type.mk//g`);if ! [ -z "$$mktmp" ];then \
	cp configure_type.mk configure_type.bak;./tools/configure_type.sh "YES" "$$mktmp" $(proj_name_bak);\
	export `cat configure_type.mk | grep "proj_name="`;if [ -f "$${proj_name}.mk" ];then \
	${RM} $(proj_name).bak;${RM} configure_type.bak;echo "成功删除$(proj_name)项目。";\
	else mv configure_type.bak configure_type.mk;mv $(proj_name).bak $(proj_name).mk;echo "$${proj_name}.mk文件不存在,删除$(proj_name)项目失败。";exit 1;\
	fi;\
	 else 	 ${RM} *.mk;${RM} $(proj_name).bak;${RM} ./tools/*.bin;\
	 fi
	${RM} ${log_dir}/${proj_name}.log
	-@if [ "${exe_dir}" != "${root_dir}" ];then \
	${RM} ${exe_dir};\
	fi
ifeq "$(configure_type)" "$(proj_name_bak)"
	${RM}   *.lds *.bin
endif
endif #ifeq "$(configure_on)" "YES"

status:
ifneq "$(configure_on)" "YES"
	@echo "configure文件不存在" && exit 1
endif
ifeq "$(configure_type)" "$(proj_name_bak)"
	@echo "Makefile目前在ARM项目状态中"
	@echo "使用的处理器为$(ARCH)"
endif
ifeq "$(configure_type)" "setting"
	@echo "Makefile目前在编译linux工具项目状态中(setting.bin)"
endif
ifeq "$(configure_type)" "mkimage4a8"
	@echo "Makefile目前在编译linux工具项目状态中(mkimage4a8.bin)"
endif

#如果使用了下面语句，makefile将自动重建依赖文件
ifeq "$(include_open)" "include_open"
sinclude $(Depend_OBJ)
endif
