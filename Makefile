TARGET := iphone:clang:latest:15.0
# arm64e 设备兼容 arm64；避免转换工具拆成不可安装的 arm64e 包
ARCHS := arm64

include $(THEOS)/makefiles/common.mk

TWEAK_NAME := RainbowKeyboard
RainbowKeyboard_FILES := Tweak.xm RainbowEffectView.m
RainbowKeyboard_CFLAGS := -fobjc-arc -Wno-deprecated-declarations
RainbowKeyboard_FRAMEWORKS := UIKit QuartzCore

include $(THEOS_MAKE_PATH)/tweak.mk

SUBPROJECTS += RainbowKeyboardPrefs
include $(THEOS_MAKE_PATH)/aggregate.mk

after-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/DEBIAN$(ECHO_END)
	$(ECHO_NOTHING)cp control $(THEOS_STAGING_DIR)/DEBIAN/control$(ECHO_END)

.PHONY: rootless roothide
rootless:
	$(MAKE) THEOS_PACKAGE_SCHEME=rootless package
roothide:
	$(MAKE) THEOS_PACKAGE_SCHEME=roothide package
