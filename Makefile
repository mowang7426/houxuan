TARGET := iphone:clang:latest:15.0
ARCHS := arm64 arm64e

include $(THEOS)/makefiles/common.mk

TWEAK_NAME := RainbowKeyboard
RainbowKeyboard_FILES := Tweak.xm RainbowEffectView.m RKPreferences.m
RainbowKeyboard_CFLAGS := -fobjc-arc -Wno-deprecated-declarations
RainbowKeyboard_FRAMEWORKS := UIKit QuartzCore
RainbowKeyboard_PRIVATE_FRAMEWORKS := Preferences
RainbowKeyboard_EXTRA_FRAMEWORKS := Cephei

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
