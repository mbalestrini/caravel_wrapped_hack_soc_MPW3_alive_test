# SPDX-FileCopyrightText: 2020 Efabless Corporation
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# SPDX-License-Identifier: Apache-2.0

## Caravel Pointers
CARAVEL_ROOT ?= ../../../caravel
CARAVEL_PATH ?= $(CARAVEL_ROOT)
CARAVEL_FIRMWARE_PATH = $(CARAVEL_PATH)/verilog/dv/caravel
CARAVEL_VERILOG_PATH  = $(CARAVEL_PATH)/verilog
CARAVEL_RTL_PATH = $(CARAVEL_VERILOG_PATH)/rtl
CARAVEL_BEHAVIOURAL_MODELS = $(CARAVEL_VERILOG_PATH)/dv/caravel

## User Project Pointers
UPRJ_VERILOG_PATH ?= ../../../verilog
UPRJ_RTL_PATH = $(UPRJ_VERILOG_PATH)/rtl
UPRJ_BEHAVIOURAL_MODELS = ../

WRAPPED_HACK_SOC_PATH = ../../rtl/wrapped_hack_soc
HACK_SOC_PATH = $(WRAPPED_HACK_SOC_PATH)/hack_soc

DUMP_TRACE = 

## RISCV GCC 
GCC_PATH?=/ef/apps/bin
GCC_PREFIX?=riscv32-unknown-elf
PDK_PATH?=/ef/tech/SW/sky130A

## Simulation mode: RTL/GL
SIM?=RTL

# include the modules that cocotb needs for test
#export PYTHONPATH := $(UPRJ_RTL_PATH)/wrapped_hack_soc/frequency_counter/test
export COCOTB_REDUCED_LOG_FMT=1
export LIBPYTHON_LOC=$(shell cocotb-config --libpython)


.SUFFIXES:

PATTERN = wrapped_hack_soc_test_2

all: coco_test # ${PATTERN:=.vcd}

hex:  ${PATTERN:=.hex}

coco_test_with_trace:
	make coco_test DUMP_TRACE=-DDUMP_TRACE
	


coco_test: ${PATTERN}.hex
	rm -rf sim_build/
	mkdir sim_build/
	iverilog -o sim_build/sim.vvp -s $(PATTERN)_tb $(PATTERN)_tb.v -DSIM -DFUNCTIONAL $(DUMP_TRACE) \
	-I $(PDK_PATH) \
	-I $(CARAVEL_BEHAVIOURAL_MODELS) -I $(CARAVEL_RTL_PATH) \
	-I $(HACK_SOC_PATH)/src  
	
	MODULE=$(PATTERN) vvp -M $$(cocotb-config --prefix)/cocotb/libs -m libcocotbvpi_icarus sim_build/sim.vvp
	! grep failure results.xml


%.vcd: %.vvp
	vvp $<

%.elf: %.c caravel_test_hack_program.c $(CARAVEL_FIRMWARE_PATH)/sections.lds $(CARAVEL_FIRMWARE_PATH)/start.s
	${GCC_PATH}/${GCC_PREFIX}-gcc -O3 -I $(CARAVEL_PATH) -march=rv32imc -mabi=ilp32 -Wl,-Bstatic,-T,$(CARAVEL_FIRMWARE_PATH)/sections.lds,--strip-debug -ffreestanding -nostdlib -o $@ $(CARAVEL_FIRMWARE_PATH)/start.s $<

%.hex: %.elf
	${GCC_PATH}/${GCC_PREFIX}-objcopy -O verilog $< $@ 
	# to fix flash base address
	sed -i 's/@10000000/@00000000/g' $@

%.bin: %.elf
	${GCC_PATH}/${GCC_PREFIX}-objcopy -O binary $< /dev/stdout | tail -c +1048577 > $@

# ---- Clean ----

clean:
	rm -f *.elf *.hex *.bin *.vvp *.vcd *.log results.xml

.PHONY: clean hex all
