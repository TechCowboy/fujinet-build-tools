###################################################################
# fujinet-lib
###################################################################
ifeq ($(DEBUG),true)
    $(info >Starting fujinet-lib.mk)
endif

$(info >>>> Using FUJINET_LIB_VERSION=$(FUJINET_LIB_VERSION))
# set FN_LIB_VERSION in your local Makefile


FUJINET_LIB             := $(CACHE_DIR)/fujinet-lib
FUJINET_LIB_VERSION_DIR := $(FUJINET_LIB)/$(FUJINET_LIB_VERSION)-$(CURRENT_TARGET)
FUJINET_LIB_PATH        := $(FUJINET_LIB_VERSION_DIR)/fujinet-$(CURRENT_TARGET)-$(FUJINET_LIB_VERSION).lib

# Base URL once, we’ll build the rest in the recipe
FUJINET_LIB_BASE_URL := https://github.com/FujiNetWIFI/fujinet-lib/releases/download/v$(FUJINET_LIB_VERSION)

.get_fujinet_lib:
	@if [ ! -f "$(FUJINET_LIB_PATH)" ]; then \
		if [ -d "$(FUJINET_LIB_VERSION_DIR)" ] && [ ! -f "$(FUJINET_LIB_PATH)" ]; then \
			echo "A directory already exists for $(FUJINET_LIB_VERSION) without a lib – please remove $(FUJINET_LIB_VERSION_DIR) first"; \
			exit 1; \
		fi; \
		BASE_URL="$(FUJINET_LIB_BASE_URL)"; \
		TARGET_ZIP="fujinet-lib-$(CURRENT_TARGET)-$(FUJINET_LIB_VERSION).zip"; \
		PLATFORM_ZIP="fujinet-lib-$(CURRENT_PLATFORM)-$(FUJINET_LIB_VERSION).zip"; \
		TARGET_URL="$$BASE_URL/$$TARGET_ZIP"; \
		PLATFORM_URL="$$BASE_URL/$$PLATFORM_ZIP"; \
		TARGET_FILE="$(FUJINET_LIB)/$$TARGET_ZIP"; \
		PLATFORM_FILE="$(FUJINET_LIB)/$$PLATFORM_ZIP"; \
		CHOSEN_URL="$$TARGET_URL"; \
		CHOSEN_FILE="$$TARGET_FILE"; \
		echo "Checking FujiNet lib for target '$(CURRENT_TARGET)'..."; \
		HTTPSTATUS=$$(curl -Is $$CHOSEN_URL | head -n 1 | awk '{print $$2}'); \
		if [ "$$HTTPSTATUS" = "404" ]; then \
			echo "Target-specific archive not found at $$CHOSEN_URL"; \
			echo "Falling back to platform '$(CURRENT_PLATFORM)'..."; \
			HTTPSTATUS=$$(curl -Is $$PLATFORM_URL | head -n 1 | awk '{print $$2}'); \
			if [ "$$HTTPSTATUS" = "404" ]; then \
				echo "ERROR: Unable to find FujiNet lib for target '$(CURRENT_TARGET)' or platform '$(CURRENT_PLATFORM)'"; \
				echo "Tried:"; \
				echo "  $$TARGET_URL"; \
				echo "  $$PLATFORM_URL"; \
				exit 1; \
			fi; \
			CHOSEN_URL="$$PLATFORM_URL"; \
			CHOSEN_FILE="$$PLATFORM_FILE"; \
		fi; \
		echo "Downloading FujiNet lib from $$CHOSEN_URL"; \
		mkdir -p "$(FUJINET_LIB)"; \
		curl -sL $$CHOSEN_URL -o $$CHOSEN_FILE; \
		echo "Unzipping to $(FUJINET_LIB_VERSION_DIR)"; \
		mkdir -p "$(FUJINET_LIB_VERSION_DIR)"; \
		unzip -o $$CHOSEN_FILE -d "$(FUJINET_LIB_VERSION_DIR)"; \
		# If we fell back to CURRENT_PLATFORM, make sure the expected CURRENT_TARGET lib exists \
		if [ -f "$(FUJINET_LIB_VERSION_DIR)/fujinet-$(CURRENT_PLATFORM)-$(FUJINET_LIB_VERSION).lib" ] && \
		   [ ! -f "$(FUJINET_LIB_PATH)" ]; then \
			cp "$(FUJINET_LIB_VERSION_DIR)/fujinet-$(CURRENT_PLATFORM)-$(FUJINET_LIB_VERSION).lib" \
			   "$(FUJINET_LIB_PATH)"; \
		fi; \
		if [ "$(CURRENT_TARGET)" = "apple2gs" ]; then \
			iix chtyp -t lib "$(FUJINET_LIB_PATH)"; \
		fi; \
		echo "FujiNet lib ready at $(FUJINET_LIB_PATH)"; \
	fi

CFLAGS  += $(INCC_ARG)$(FUJINET_LIB_VERSION_DIR)
ASFLAGS += $(INCS_ARG)$(FUJINET_LIB_VERSION_DIR)

LIBS      += $(FUJINET_LIB_PATH)
ALL_TASKS += .get_fujinet_lib
