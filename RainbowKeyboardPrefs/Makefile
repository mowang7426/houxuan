include $(THEOS)/makefiles/common.mk

BUNDLE_NAME := RainbowKeyboardPrefs
RainbowKeyboardPrefs_FILES := RKBRootListController.m
RainbowKeyboardPrefs_FRAMEWORKS := UIKit
RainbowKeyboardPrefs_PRIVATE_FRAMEWORKS := Preferences
RainbowKeyboardPrefs_INSTALL_PATH := /Library/PreferenceBundles
RainbowKeyboardPrefs_CFLAGS := -fobjc-arc

include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp Resources/RainbowKeyboardPrefs.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/RainbowKeyboardPrefs.plist$(ECHO_END)
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceBundles/RainbowKeyboardPrefs.bundle/Resources$(ECHO_END)
	$(ECHO_NOTHING)cp Resources/RainbowKeyboard.plist $(THEOS_STAGING_DIR)/Library/PreferenceBundles/RainbowKeyboardPrefs.bundle/Resources/RainbowKeyboard.plist$(ECHO_END)
