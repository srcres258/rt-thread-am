ARCH ?= native

ifneq ($(findstring $(ARCH),riscv32e-ysyxsoc),)
  ifneq ($(USE_SDRAM),1)
    USE_PSRAM := 1
  endif
endif

AM_APPS_MK = build/${ARCH}/am-apps.mk
FILE_MK = files.mk
FILE_TMP = .tmp.$(FILE_MK)
RTCONFIG_H = rtconfig.h

NAME = rtthread
SRCS = $(shell find src -name "*.c")
CFLAGS += -DHAVE_CCONFIG_H -D__RTTHREAD__
CFLAGS += -Wno-nonnull-compare
-include $(FILE_MK)
-include $(AM_APPS_MK)

include $(AM_HOME)/Makefile

ifeq ($(USE_SDRAM),1)
  LDSCRIPTS := $(abspath ./linker-sdram-rtthread.ld)
else ifeq ($(USE_PSRAM),1)
  LDSCRIPTS := $(abspath ./linker-psram-rtthread.ld)
endif

ifneq ($(or $(USE_SDRAM),$(USE_PSRAM)),1)
  LDFLAGS += -T extra.ld
endif

$(RTCONFIG_H):
	touch $@
	ARCH=$(ARCH) scons --useconfig=.config
	if [ "`sed -n '3p' $@`"x = x ]; then sed -i -e '2a#include "extra.h"' $@; fi

init: $(RTCONFIG_H)
	ARCH=$(ARCH) scons -c
	ARCH=$(ARCH) scons --verbose -n > $(FILE_TMP)
	cat $(FILE_TMP) | grep -o '[^ ]*.c$$' | awk '{print "SRCS += " $$1}' > $(FILE_MK)
	cat $(FILE_TMP) | grep 'gcc ' | head -n 1 | grep -o " -I[^ ]*" | awk '{print "CFLAGS += " $$1}' >> $(FILE_MK)
	rm $(FILE_TMP)

menuconfig:
	ARCH=$(ARCH) scons --menuconfig
	ARCH=$(ARCH) scons --genconfig
	$(MAKE) init

ifneq ($(MAKECMDGOALS),clean)
update: $(AM_APPS_MK)
$(AM_APPS_MK): integrate-am-apps.py
	mkdir -p $(@D)
	python3 $^ ARCH=$(ARCH) CROSS_COMPILE=$(CROSS_COMPILE)
endif

.PHONY: init menuconfig update
