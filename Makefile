#################################################################
# Author:       Abraham J. Ruiz R. (https://github.com/m4j0rt0m)
# Description:  Missionary - Cannibal Ex. Project Makefile
#################################################################

MKFILE_PATH         = $(abspath $(lastword $(MAKEFILE_LIST)))
TOP_DIR             = $(shell dirname $(MKFILE_PATH))

### DIRECTORIES ###
SOURCE_DIR          = $(TOP_DIR)/rtl
OUTPUT_DIR          = $(TOP_DIR)/build
TESTBENCH_DIR       = $(TOP_DIR)/tb
SCRIPT_DIR          = $(TOP_DIR)/scripts
FPGA_RTL_DIR        = $(TOP_DIR)/fpga/rtl
FPGA_BUILD_DIR      = $(TOP_DIR)/fpga/build

### RTL WILDCARDS ###
PRJ_SRC             = $(wildcard $(shell find $(SOURCE_DIR) -type f \( -iname \*.v -o -iname \*.sv -o -iname \*.vhdl \)))
PRJ_DIRS            = $(wildcard $(shell find $(SOURCE_DIR) -type d))
PRJ_HEADERS         = $(wildcard $(shell find $(SOURCE_DIR) -type f \( -iname \*.h -o -iname \*.vh -o -iname \*.svh \)))
TESTBENCH_SRC       = $(wildcard $(shell find $(TESTBENCH_DIR) -type f \( -iname \*.v \)))
PRJ_INCLUDES        = $(addprefix -I, $(PRJ_DIRS))

### FPGA RTL WILDCARDS ###
FPGA_TOP            = missionary_cannibal
FPGA_RTL_SRC        = $(wildcard $(shell find $(FPGA_RTL_DIR) -type f \( -iname \*.v -o -iname \*.sv -o -iname \*.vhdl \)))
FPGA_RTL_DIRS       = $(wildcard $(shell find $(FPGA_RTL_DIR) -type d))
FPGA_RTL_HEADERS    = $(wildcard $(shell find $(FPGA_RTL_DIR) -type f \( -iname \*.h -o -iname \*.vh -o -iname \*.svh \)))
FPGA_RTL_INCLUDES   = $(addprefix -I, $(FPGA_RTL_DIRS))

### PROJECT ###
PROJECT             = missionary_cannibal
TOP_MODULE          = missionary_cannibal
RTL_SRC             = $(PRJ_SRC) $(FPGA_RTL_SRC)

### LINTER ###
LINT                = verilator
LINT_FLAGS          = --lint-only --top-module $(TOP_MODULE) -Wall $(PRJ_INCLUDES)

### SIMULATION ###
TOP_MODULE_SIM      = missionary_cannibal
NAME_MODULE_SIM     = $(TOP_MODULE_SIM)_tb
SIM                 = iverilog
SIM_FLAGS           = -o $(OUTPUT_DIR)/$(TOP_MODULE).tb -s $(NAME_MODULE_SIM) -DSIMULATION $(PRJ_INCLUDES)
RUN                 = vvp
RUN_FLAGS           =

### FUNCTION DEFINES ###
define set_source_file_tcl
echo "set_global_assignment -name SOURCE_FILE $(1)" >> $(CREATE_PROJECT_TCL);
endef
define set_sdc_file_tcl
echo "set_global_assignment -name SDC_FILE $(1)" >> $(CREATE_PROJECT_TCL);
endef

### ALTERA FPGA COMPILATION ###
CLOCK_PORT          = clock
CLOCK_PERIOD        = 10
CREATE_PROJECT_TCL  = $(SCRIPT_DIR)/create_project.tcl
VIRTUAL_PINS_TCL   ?= $(SCRIPT_DIR)/virtual_pins.tcl
PROJECT_SDC         = $(SCRIPT_DIR)/$(PROJECT).sdc
DEVICE_FAMILY       = "Cyclone IV E"
DEVICE_PART         = "EP4CE22F17C6"
MIN_CORE_TEMP       = 0
MAX_CORE_TEMP       = 85
PACKING_OPTION      = "normal"
VIRTUAL_PINS        = $(shell cat $(VIRTUAL_PINS_TCL))

### QUARTUS CLI ###
QUARTUS_SH          = quartus_sh

### FUNCTIONS ###
define veritedium-command
emacs --batch $(1) -f verilog-auto -f save-buffer;
endef

### RULES ###
all: lint project sim

veritedium:
	$(foreach SRC,$(RTL_SRC),$(call veritedium-command,$(SRC)))
	$(foreach SRC,$(TESTBENCH_SRC),$(call veritedium-command,$(SRC)))
	$(find ./* -name "*~" -delete)

lint: $(PRJ_SRC)
	$(LINT) $(LINT_FLAGS) $^

sim: $(OUTPUT_DIR)/$(TOP_MODULE_SIM).tb
	$(RUN) $(RUN_FLAGS) $<
	@(mv $(TOP_MODULE_SIM).vcd $(OUTPUT_DIR)/$(TOP_MODULE_SIM).vcd)

vcd: $(OUTPUT_DIR)/$(TOP_MODULE_SIM).vcd

gtkwave: $(OUTPUT_DIR)/$(TOP_MODULE_SIM).vcd $(TESTBENCH_SRC)
	@(gtkwave $< > /dev/null 2>&1 &)

run-sim: $(TESTBENCH_SRC) $(PRJ_SRC) $(PRJ_HEADERS)
	mkdir -p $(OUTPUT_DIR)
	$(SIM) $(SIM_FLAGS) $^
	$(RUN) $(RUN_FLAGS) $(OUTPUT_DIR)/$(TOP_MODULE_SIM).tb
	mv $(TOP_MODULE_SIM).vcd $(OUTPUT_DIR)/$(TOP_MODULE_SIM).vcd

project: create-project compile-flow

compile-flow:
	cd $(FPGA_BUILD_DIR); \
	$(QUARTUS_SH) --flow compile $(PROJECT)

create-project: create-project-tcl
	rm -rf $(FPGA_BUILD_DIR)/$(PROJECT).qpf; \
	rm -rf $(FPGA_BUILD_DIR)/$(PROJECT).qsf; \
	mkdir -p $(FPGA_BUILD_DIR); \
	cd $(FPGA_BUILD_DIR); \
	$(QUARTUS_SH) -t $(CREATE_PROJECT_TCL)

create-project-tcl: create-sdc
	rm -rf $(CREATE_PROJECT_TCL)
	@(echo "# Automatically created by Makefile #" > $(CREATE_PROJECT_TCL))
	@(echo "set project_name $(PROJECT)" >> $(CREATE_PROJECT_TCL))
	@(echo "if [catch {project_open $(PROJECT)}] {project_new $(PROJECT)}" >> $(CREATE_PROJECT_TCL))
	@(echo "set_global_assignment -name MIN_CORE_JUNCTION_TEMP $(MIN_CORE_TEMP)" >> $(CREATE_PROJECT_TCL))
	@(echo "set_global_assignment -name MAX_CORE_JUNCTION_TEMP $(MAX_CORE_TEMP)" >> $(CREATE_PROJECT_TCL))
	@(echo "set_global_assignment -name FAMILY \"$(DEVICE_FAMILY)\"" >> $(CREATE_PROJECT_TCL))
	@(echo "set_global_assignment -name TOP_LEVEL_ENTITY $(FPGA_TOP)" >> $(CREATE_PROJECT_TCL))
	@(echo "set_global_assignment -name DEVICE \"$(DEVICE_PART)\"" >> $(CREATE_PROJECT_TCL))
	@(echo "set_global_assignment -name ERROR_CHECK_FREQUENCY_DIVISOR 256" >> $(CREATE_PROJECT_TCL))
	@(echo "set_global_assignment -name SEARCH_PATH $(INCLUDE_DIR)" >> $(CREATE_PROJECT_TCL))
	$(foreach SRC,$(PRJ_SRC),$(call set_source_file_tcl,$(SRC)))
	$(foreach SRC,$(PRJ_HEADERS),$(call set_source_file_tcl,$(SRC)))
	$(foreach SRC,$(FPGA_RTL_SRC),$(call set_source_file_tcl,$(SRC)))
	$(foreach SRC,$(FPGA_RTL_HEADERS),$(call set_source_file_tcl,$(SRC)))
	@(echo "set_global_assignment -name SDC_FILE $(PROJECT_SDC)" >> $(CREATE_PROJECT_TCL))
	@(echo "project_close" >> $(CREATE_PROJECT_TCL))
	@(echo "qexit -success" >> $(CREATE_PROJECT_TCL))

create-sdc:
	rm -rf $(PROJECT_SDC)
	@(echo "create_clock -name $(CLOCK_PORT) -period $(CLOCK_PERIOD) [get_ports {$(CLOCK_PORT)}]" > $(PROJECT_SDC))
	@(echo "derive_clock_uncertainty" >> $(PROJECT_SDC))

del-bak:
	find ./* -name "*~" -delete
	find ./* -name "*.bak" -delete

clean: del-bak
	rm -rf ./build/*.tb
	rm -rf ./build/*.vcd
	rm -rf ./fpga/build/*
	rm -rf ./scripts/create_project.tcl

$(OUTPUT_DIR)/$(TOP_MODULE_SIM).tb: $(TESTBENCH_SRC) $(PRJ_SRC) $(PRJ_HEADERS)
	@(mkdir -p $(OUTPUT_DIR))
	$(SIM) $(SIM_FLAGS) $^

$(OUTPUT_DIR)/$(TOP_MODULE_SIM).vcd: $(OUTPUT_DIR)/$(TOP_MODULE_SIM).tb $(PRJ_SRC) $(PRJ_HEADERS)
	$(RUN) $(RUN_FLAGS) $<
	@(mv $(TOP_MODULE_SIM).vcd $(OUTPUT_DIR)/$(TOP_MODULE_SIM).vcd)

.PHONY: all lint sim clean project compile-flow set-pinout connect scan flash-fpga create-project create-project-tcl del-bak create-sdc
