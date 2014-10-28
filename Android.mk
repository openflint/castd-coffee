LOCAL_PATH:= $(call my-dir)
include $(CLEAR_VARS)
CASTD_PATH := $(LOCAL_PATH)

.phony: castd
castd:
	#cd $(CASTD_PATH); npm install --production; cd $(ANDROID_BUILD_TOP)
	mkdir -p $(TARGET_OUT)/usr/lib/node_modules/castd
	rm -rf $(TARGET_OUT)/usr/lib/node_modules/castd/*
	cp -rf $(CASTD_PATH)/bin $(TARGET_OUT)/usr/lib/node_modules/castd/
	cp -rf $(CASTD_PATH)/lib $(TARGET_OUT)/usr/lib/node_modules/castd/
	cp -rf $(CASTD_PATH)/node_modules $(TARGET_OUT)/usr/lib/node_modules/castd/
	mkdir -p $(TARGET_OUT)/bin
	rm -rf $(TARGET_OUT)/bin/castd
	ln -sf ../usr/lib/node_modules/castd/bin/castd $(TARGET_OUT)/bin/castd
	chmod a+x $(TARGET_OUT)/bin/castd

ALL_MODULES += castd
ALL_MODULES.castd.INSTALLED := castd
