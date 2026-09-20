TARGET := iphone:clang:latest:15.0
# 默认支持 Rootless；Roothide Workflow 可通过 ARCHS=arm64e 覆盖
ARCHS ?= arm64

include $(THEOS)/makefiles/common.mk

TWEAK_NAME := RainbowKeyboard
RainbowKeyboard_FILES := Tweak.xm RainbowEffectView.m
RainbowKeyboard_CFLAGS := -fobjc-arc -Wno-deprecated-declarations
RainbowKeyboard_FRAMEWORKS := UIKit QuartzCore

include $(THEOS_MAKE_PATH)/tweak.mk

SUBPROJECTS += RainbowKeyboardPrefs
include $(THEOS_MAKE_PATH)/aggregate.mk

.PHONY: rootless roothide
rootless:
	$(MAKE) THEOS_PACKAGE_SCHEME=rootless package
roothide:
	$(MAKE) THEOS_PACKAGE_SCHEME=roothide package
