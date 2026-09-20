include $(THEOS)/makefiles/common.mk

BUNDLE_NAME := RainbowKeyboardPrefs
RainbowKeyboardPrefs_FILES := RKBRootListController.m
RainbowKeyboardPrefs_FRAMEWORKS := UIKit
RainbowKeyboardPrefs_INSTALL_PATH := /Library/PreferenceBundles
RainbowKeyboardPrefs_CFLAGS := -fobjc-arc -Wno-deprecated-declarations
RainbowKeyboardPrefs_PLIST := Resources/Info.plist
RainbowKeyboardPrefs_RESOURCE_DIRS := Resources
RainbowKeyboardPrefs_LDFLAGS := -Wl,-undefined,dynamic_lookup

include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp Resources/RainbowKeyboardPrefs.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/com.minis.rainbowkeyboard.prefs.plist$(ECHO_END)
