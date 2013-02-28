/**
 *  \file       start.S
 *  \brief    cortex-A8中的BL1,完成clk、dram、nand、MMU、串口等基本的初始化，并将完整的u-boot复制到dram中。
 *
 *  \version:   1.0\n
 *  compiler:GCC\n
 *  \date   Feb 3, 2013 5:37:56 AM
 * \note  Copyright (C) 
 * 2013 -  fulong - fulong.mo@gmail.com
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 * 
 */
.globl _start

_start:
	// 设置GPC0CON的bit[0:15]，配置GPC0_3/4引脚为输出功能
	ldr r1, =0xE0200060
	ldr r0, =0x00011000
	str r0, [r1]
	ldr r2,=0xFFFF00
star
led_blink:
	// 设置GPC0DAT的bit[3:4]，使GPC0_3/4引脚输出低电平，LED亮
	ldr r1, =0xE0200064
	mov r0, #0x18
	str r0, [r1]

	bl delay
	ldr r1, =0xE0200064
	mov r0, #0x00
	str r0, [r1]
	bl delay
	b led_blink

delay:
	sub r2,r2,#1
	cmp r2,#0
	bne delay
	ldr r2,=0xFFFF00
	mov pc,lr
halt:
	b halt