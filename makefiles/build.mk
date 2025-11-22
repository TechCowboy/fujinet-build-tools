# generic c/s/asm build script.
#
# This makefile is responsible for compiling the asm/s/c files for a particular target, passed in as CURRENT_TARGET
# The build understands that each target belongs to a platform, e.g. apple2enh target is part of the apple2 platform.
#
# You should not normally need to update this file unless you are making enhancements or bug fixes to it.
# For compiling the library, it does not need changes for simple additions of new files etc.
#
# It will RECURSIVELY add to the sources to be built everything that is under the folders
# - <SRCDIR>/common/*.c
# - <SRCDIR>/<CURRENT_PLATFORM>/*.[c,s,asm]
# The following uses a sub-folder to allow the current TARGET to have its own specific code not shared by other
# targets in the common platform, e.g. if you want to split source for apple2 and apple2enh, you'd use this:
# - <SRCDIR>/current-target/<CURRENT_TARGET>/
#
# The following path is not searched recursively, if you simply want a single folder with just *.c and *.h files, you can:
# - <SRCDIR>/*.c
#
# This means that the makefile does not have to be updated to add new folders, or if you restructure your code.
#
# Platform specific paths are defined in os.mk, and allow a particular target within a platform (e.g. apple2gs) to
# add its own folders that are not included for other targets of that platform.
# e.g. for apple2 and apple2enh it includes "apple2/apple2-6502", whereas the apple2gs target adds "apple2/apple2gs"
#
# code is compiled into the obj/ folder including the full paths of the src file to ensure similarly named files
# from different folders do not clash
#
# Include files are added for the top level folders only:
# - <SRCDIR>
# - <SRCDIR>/common
# - <SRCDIR>/include
# - <SRCDIR>/$(CURRENT_PLATFORM)
# - <SRCDIR>/$(CURRENT_PLATFORM)/include
# - <SRCDIR>/current-target/$(CURRENT_TARGET)
#
# You can use anything relative to these when including other files.
# As always, for simplicity, you can simply dump them all in the <SRCDIR> and they will be found.


ifeq ($(DEBUG),true)
    $(info >Starting build.mk)
endif


# Ensure WSL2 Ubuntu and other linuxes use bash by default instead of /bin/sh, which does not always like the shell commands.
SHELL      := /usr/bin/env bash
ALL_TASKS  :=
DISK_TASKS :=
OBJEXT      = .o

-include __PARENT_RELATIVE_DIR__/makefiles/os.mk
-include __PARENT_RELATIVE_DIR__/makefiles/compiler.mk

SRCDIR      := src
BUILD_DIR   := build
OBJDIR      := obj
DIST_DIR    := dist
CACHE_DIR   := __PARENT_RELATIVE_DIR__/_cache

PLATFORM_SRC_DIR := $(SRCDIR)/$(CURRENT_PLATFORM)
TARGET_SRC_DIR   := $(SRCDIR)/current-target/$(CURRENT_TARGET)

# After PROGRAM / CURRENT_TARGET are known:
PROGRAM_TGT     := $(PROGRAM).$(CURRENT_TARGET)

# This causes the output file to have the TARGET in the name, e.g. foo.atari.com
# Set to 0 for "foo.com" instead, but note this will fail for devices that have multiple targets (like apple2 and apple2enh) that would share same name and overwrite each other.
APPEND_TARGET := 1

ifeq ($(APPEND_TARGET),1)
PROG_BASENAME   := $(PROGRAM_TGT)
else
PROG_BASENAME   := $(PROGRAM)
endif


$(info PLATFORM_SRC_DIR = $(PLATFORM_SRC_DIR))
$(info TARGET_SRC_DIR   = $(TARGET_SRC_DIR))
$(info PROGRAM_TGT      = $(PROGRAM_TGT))
$(info PROG_BASENAME    = $(PROG_BASENAME))

# This allows src to be nested within sub-directories.
rwildcard=$(wildcard $(1)$(2))$(foreach d,$(wildcard $1*), $(call rwildcard,$d/,$2))

# ----------------------------------------------------------------------
# Sources
# ----------------------------------------------------------------------

# Top-level C sources (non-recursive)
SOURCES    := $(wildcard $(SRCDIR)/*.c)

# src/common (recursive)
SOURCES    += $(call rwildcard,$(SRCDIR)/common/,*.c)

SOURCES    += $(call rwildcard,$(PLATFORM_SRC_DIR)/,*.c)
SOURCES    += $(call rwildcard,$(PLATFORM_SRC_DIR)/,*.s)
SOURCES    += $(call rwildcard,$(PLATFORM_SRC_DIR)/,*.asm)

SOURCES    += $(call rwildcard,$(TARGET_SRC_DIR)/,*.c)
SOURCES    += $(call rwildcard,$(TARGET_SRC_DIR)/,*.s)
SOURCES    += $(call rwildcard,$(TARGET_SRC_DIR)/,*.asm)

# trim spaces
SOURCES    := $(strip $(SOURCES))
$(info SOURCES     = $(SOURCES))

# ----------------------------------------------------------------------
# Objects
# ----------------------------------------------------------------------

OBJ1    := $(SOURCES:.c=$(OBJEXT))
OBJ1    := $(OBJ1:.s=$(OBJEXT))
OBJ1    := $(OBJ1:.asm=$(OBJEXT))
OBJECTS := $(OBJ1)

$(info OBJ1        = $(OBJ1))
$(info OBJECTS     = $(OBJECTS))

OBJECTS_ARC := $(OBJECTS)
-include __PARENT_RELATIVE_DIR__/makefiles/objects-$(CURRENT_TARGET).mk

OBJECTS    := $(OBJECTS:$(SRCDIR)/%=$(OBJDIR)/$(CURRENT_TARGET)/%)
$(info OBJECTS     = $(OBJECTS))

OBJECTS_ARC := $(OBJECTS_ARC:$(SRCDIR)/%=$(OBJDIR)/$(CURRENT_TARGET)/%)

DEPENDS := $(OBJECTS:$(OBJEXT)=.d)
$(info DEPENDS     = $(DEPENDS))

# Logical include root dirs
INCLUDE_DIRS := \
  $(SRCDIR) \
  $(SRCDIR)/common \
  $(SRCDIR)/include \
  $(PLATFORM_SRC_DIR) \
  $(PLATFORM_SRC_DIR)/include \
  $(TARGET_SRC_DIR) \
  $(TARGET_SRC_DIR)/include \
  .

# Add to CFLAGS
CFLAGS += $(foreach d,$(INCLUDE_DIRS),$(INCC_ARG)$(d))

# only include ASFLAGS if not wcc or iix
ifneq ($(filter $(CC),wcc iix),$(CC))
ASFLAGS += $(foreach d,$(INCLUDE_DIRS),$(INCS_ARG)$(d))
endif

ifeq ($(DEBUG),true)
    $(info >>load common.mk)
endif
-include __PARENT_RELATIVE_DIR__/makefiles/common.mk


ifeq ($(DEBUG),true)
    $(info >>load custom-$(CURRENT_PLATFORM).mk)
endif

-include __PARENT_RELATIVE_DIR__/makefiles/custom-$(CURRENT_PLATFORM).mk


ifeq ($(DEBUG),true)
    $(info >>load application.mk)
endif

# allow for application specific config
-include ./application.mk

.SUFFIXES:
.PHONY: all clean release $(DISK_TASKS) $(BUILD_TASKS) $(PROGRAM_TGT) $(ALL_TASKS)

all: $(ALL_TASKS) $(PROGRAM_TGT)

-include $(DEPENDS)

$(OBJDIR):
	$(call MKDIR,$@)

$(BUILD_DIR):
	$(call MKDIR,$@)

$(DIST_DIR):
	$(call MKDIR,$@)

SRC_INC_DIRS := \
  $(SRCDIR) \
  $(SRCDIR)/common \
  $(PLATFORM_SRC_DIR) \
  $(TARGET_SRC_DIR)

# Not strictly needed as we added all the object mappings above anyway
vpath %.c   $(SRC_INC_DIRS)
vpath %.s   $(SRC_INC_DIRS)
vpath %.asm $(SRC_INC_DIRS)

$(info SOURCES: $(SOURCES))
$(info OBJECTS: $(OBJECTS))
$(info OBJECTS_ARC: $(OBJECTS_ARC))
$(info SRC_INC_DIRS: $(SRC_INC_DIRS))

$(OBJDIR)/$(CURRENT_TARGET)/%$(OBJEXT): %.c $(VERSION_FILE) | $(OBJDIR)
	@$(call MKDIR,$(dir $@))
ifeq ($(CC),cl65)
	$(CC) -t $(CURRENT_TARGET) -c --create-dep $(@:$(OBJEXT)=.d) $(CFLAGS) --listing $(@:$(OBJEXT)=.lst) -o $@ $<
else ifeq ($(CC),wcl)
	$(CC) $(CFLAGS) -c -fo=$@ $<
else ifeq ($(CC),iix compile)
	$(CC) $(CFLAGS) $< keep=$(subst .root,,$@)
else ifeq ($(CC),zcc)
	# zcc: use +<target> to select the machine (zx, cpm, etc)
	$(CC) +$(CURRENT_TARGET) -c $(CFLAGS) -o $@ $<
else
	@echo "THIS PROBABLY WILL NOT WORK - USING GENERIC CC"
	$(CC) -c --deps $(CFLAGS) -o $@ $<
endif

$(OBJDIR)/$(CURRENT_TARGET)/%$(OBJEXT): %.s $(VERSION_FILE) | $(OBJDIR)
	@$(call MKDIR,$(dir $@))
ifeq ($(CC),cl65)
	$(CC) -t $(CURRENT_TARGET) -c --create-dep $(@:$(OBJEXT)=.d) $(ASFLAGS) --listing $(@:$(OBJEXT)=.lst) -o $@ $<
else ifeq ($(CC),wcl)
	@echo "ERROR: wcc toolchain does not assemble standalone .s files via wcc; please use C sources or configure an assembler (e.g. wasm)." ; \
	exit 1
else ifeq ($(CC),iix compile)
	# I didnt think iix had ASFLAGS...?
	$(CC) $(ASFLAGS) $< keep=$(subst .root,,$@)
	@OUT_NAME="$@"; CAP_NAME=$${OUT_NAME//.root}.ROOT; if [ -f "$$CAP_NAME" ]; then mv $$CAP_NAME $@; fi
else ifeq ($(CC),zcc)
	# zcc also goes via the driver, with +<target>
	$(CC) +$(CURRENT_TARGET) -c $(ASFLAGS) -o $@ $<
else
	@echo "THIS PROBABLY WILL NOT WORK - USING GENERIC CC"
	$(CC) -c --deps $(@:$(OBJEXT)=.d) $(ASFLAGS) -o $@ $<
endif

$(OBJDIR)/$(CURRENT_TARGET)/%$(OBJEXT): %.asm $(VERSION_FILE) | $(OBJDIR)
	@$(call MKDIR,$(dir $@))
ifeq ($(CC),cl65)
	$(CC) -t $(CURRENT_TARGET) -c --create-dep $(@:$(OBJEXT)=.d) $(ASFLAGS) --listing $(@:$(OBJEXT)=.lst) -o $@ $<
else ifeq ($(CC),wcl)
	@echo "ERROR: wcl toolchain does not assemble standalone .asm files via wcc; please use C sources or configure an assembler (e.g. wasm)." ; \
	exit 1
else ifeq ($(CC),iix compile)
	# I didnt think iix had ASFLAGS...?
	$(CC) $(ASFLAGS) $< keep=$(subst .root,,$@)
	@OUT_NAME="$@"; CAP_NAME=$${OUT_NAME//.root}.ROOT; if [ -f "$$CAP_NAME" ]; then mv $$CAP_NAME $@; fi
else ifeq ($(CC),zcc)
	$(CC) +$(CURRENT_TARGET) -c $(ASFLAGS) -o $@ $<
else
	@echo "THIS PROBABLY WILL NOT WORK - USING GENERIC CC"
	$(CC) -c --deps $(@:$(OBJEXT)=.d) $(ASFLAGS) -o $@ $<
endif

$(BUILD_DIR)/$(PROGRAM_TGT): $(OBJECTS) $(LIBS) | $(BUILD_DIR)
ifeq ($(CC),cl65)
	$(CC) -t $(CURRENT_TARGET) $(LDFLAGS) --mapfile $@.map -Ln $@.lbl -o $@ $^
else ifeq ($(CC),iix compile)
	@echo "TODO: What is the compile command for the application on apple2gs"
	# $(CC) $(CFLAGS) $< keep=$(subst .root,,$@)
else ifeq ($(CC),zcc)
	$(CC) +$(CURRENT_TARGET) $(LDFLAGS) -o $@ $^
else ifeq ($(CC),wcl)
	# wcl will both compile (if needed) and link, but here we just link objects/libs:
	$(CC) $(CFLAGS) $(LDFLAGS) -fe=$@ $^
else
	@echo "THIS PROBABLY WILL NOT WORK - USING GENERIC LINK"
	$(CC) $(LDFLAGS) -o $@ $^
endif



$(PROGRAM_TGT): $(BUILD_DIR)/$(PROGRAM_TGT) | $(BUILD_DIR)


ifeq ($(DEBUG),true)
    $(info PROGRAM_TGT is set to: $(PROGRAM_TGT) )
    $(info BUILD_DIR is set to: $(BUILD_DIR) )
    $(info CURRENT_TARGET is set to: $(CURRENT_TARGET) )
    $(info ........................... )
endif

EMU_PROG ?= $(BUILD_DIR)/$(PROGRAM_TGT)

test: $(PROGRAM_TGT)
	$(PREEMUCMD)
	$(EMUCMD) $(EMU_PROG)
	$(POSTEMUCMD)

# Use "./" in front of all dirs being removed as a simple safety guard to
# ensure deleting from current dir, and not something like root "/".
clean:
	@for d in $(BUILD_DIR) $(OBJDIR) $(DIST_DIR); do \
      if [ -d "./$$d" ]; then \
	    echo "Removing $$d"; \
        rm -rf ./$$d; \
      fi; \
    done

release: all | $(BUILD_DIR) $(DIST_DIR)
	cp $(BUILD_DIR)/$(PROGRAM_TGT) $(DIST_DIR)/$(PROG_BASENAME)$(SUFFIX)


disk: release $(DISK_TASKS)
