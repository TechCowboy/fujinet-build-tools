###################################################################
# MSDOS
###################################################################
ifeq ($(DEBUG),true)
    $(info >Starting custom-msdos.mk)
endif

# 8.3-friendly basename and suffix for DOS
override PROG_BASENAME := $(PROGRAM)
SUFFIX = .exe

# "Disk file" is just the final EXE
DISK_TASKS += .create-msdos
DISK_FILE  = $(DIST_DIR)/$(PROG_BASENAME)$(SUFFIX)

.create-msdos:
	@echo "MS-DOS target: no disk image created."
	@echo "Final executable: $(DISK_FILE)"
	@if [ ! -f "$(DISK_FILE)" ]; then \
		echo "NOTE: $(DISK_FILE) does not exist yet. Did you run 'make release'?"; \
	fi

# Emulator: prefer dosbox-x, fall back to dosbox
DOSBOX_X   := $(shell which dosbox-x 2>/dev/null)
DOSBOX_BIN := $(if $(DOSBOX_X),$(DOSBOX_X),$(shell which dosbox 2>/dev/null))

# msdos_EMUCMD: sets up DOSBox; program name is passed as EMU_PROG
msdos_EMUCMD   := $(DOSBOX_BIN) \
	-c "mount c $(DIST_DIR)" \
	-c "c:" \
	-c

# EMU_PROG: just the DOS filename (no path)
msdos_EMU_PROG := $(PROG_BASENAME)$(SUFFIX)
