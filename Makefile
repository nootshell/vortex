#
#	Configurable variables
#

CC = gcc
LD = gcc

PROFILE = drebug

CFLAGS = -fPIC -Wall
CFLAGS_DEBUG = -g -DDEBUG=1
CFLAGS_RELEASE = -O3 -DRELEASE=1

OBJS =
OUT_DIR = bin

VORTEX_QT_MAKEFILE = app.mk




GetObjFiles = $(patsubst %.c, %.o, $(shell find "$1" -type f -name '*.c'))




#
#	Computed variables
#

PROFILE_SANE = $(shell echo "$(PROFILE)" | sed 's/[[:space:]\-]/_/g' | tr [:lower:] [:upper:] | sed 's/[^A-Za-z0-9_]//g')

CFLAGS_PROFILE = $(CFLAGS_$(PROFILE_SANE))
LFLAGS_PROFILE = $(LFLAGS_$(PROFILE_SANE))




.PHONY: all libvortex vortex-cli mostlyclean clean rebuild

all: libvortex vortex-cli vortex-qt

libvortex: $(OUT_DIR)/libvortex.so
vortex-cli: $(OUT_DIR)/vortex-cli
vortex-qt: $(OUT_DIR)/vortex-qt




mostlyclean: OBJS = $(call GetObjFiles,src)
mostlyclean:
	rm -f $(OBJS);
	if [ -f src/vortex-qt/$(VORTEX_QT_MAKEFILE) ]; then $(MAKE) -C src/vortex-qt -f $(VORTEX_QT_MAKEFILE) clean; fi
	rm -f src/vortex-qt/$(VORTEX_QT_MAKEFILE)
	rm -f src/vortex-qt/app.out


clean: mostlyclean
	rm -rf $(OUT_DIR)


rebuild: clean all




# Wildcard target for object files
%.o: %.c
	$(CC) -o $@ $(CFLAGS) $(CFLAGS_PROFILE) -c $^




# Vortex library target
$(OUT_DIR)/libvortex.so: $(call GetObjFiles,src/libvortex)
	@mkdir -p $(dir $@)
	$(LD) -o $@ --shared -fPIC $(LFLAGS) $^
ifeq (release,$(PROFILE))
	strip --strip-unneeded $@
endif


$(OUT_DIR)/vortex-cli: CFLAGS += -Isrc
$(OUT_DIR)/vortex-cli: LFLAGS += $(OUT_DIR)/libvortex.so
$(OUT_DIR)/vortex-cli: $(call GetObjFiles,src/vortex-cli)
	@mkdir -p $(dir $@)
	$(LD) -o $@ -fPIE $(LFLAGS) $^
ifeq (release,$(PROFILE))
	strip --strip-unneeded $@
endif


$(OUT_DIR)/vortex-qt:
	@mkdir -p $(dir $@)
	qmake -makefile -o src/vortex-qt/$(VORTEX_QT_MAKEFILE) src/vortex-qt/vortex-qt.pro
	$(MAKE) -C src/vortex-qt -f $(VORTEX_QT_MAKEFILE) TARGET=app.out
	cp src/vortex-qt/app.out $@
