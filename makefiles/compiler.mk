# sets the compiler and C args according to the target

ifeq ($(CURRENT_TARGET),coco)

-include __PARENT_RELATIVE_DIR__/makefiles/compiler-cmoc.mk

else ifeq ($(CURRENT_TARGET),apple2gs)

-include __PARENT_RELATIVE_DIR__/makefiles/compiler-orca.mk

else ifeq ($(CURRENT_TARGET),pmd85)

-include __PARENT_RELATIVE_DIR__/makefiles/compiler-pmd85.mk

else ifeq ($(CURRENT_TARGET),msdos)

-include __PARENT_RELATIVE_DIR__/makefiles/compiler-msdos.mk

else ifeq ($(CURRENT_TARGET),adam)

-include __PARENT_RELATIVE_DIR__/makefiles/compiler-adam.mk

else

-include __PARENT_RELATIVE_DIR__/makefiles/compiler-cc65.mk

endif
