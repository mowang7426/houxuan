include $(THEOS)/makefiles/common.mk

BUNDLE_NAME := RainbowKeyboardPrefs
RainbowKeyboardPrefs_FILES := RKBRootListController.m
RainbowKeyboardPrefs_FRAMEWORKS := UIKit
RainbowKeyboardPrefs_INSTALL_PATH := /Library/PreferenceBundles
RainbowKeyboardPrefs_CFLAGS := -fobjc-arc
RainbowKeyboardPrefs_PLIST := Resources/Info.plist
# PSListController 由设备上的 Preferences.framework 在运行时提供
RainbowKeyboardPrefs_LDFLAGS := -Wl,-undefined,dynamic_lookup

include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp Resources/RainbowKeyboardPrefs.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/RainbowKeyboardPrefs.plist$(ECHO_END)
	$(ECHO_NOTHING)cp Resources/RainbowKeyboardPrefs.plist $(THEOS_STAGING_DIR)/Library/PreferenceBundles/RainbowKeyboardPrefs.bundle/RainbowKeyboardPrefs.plist$(ECHO_END)
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceBundles/RainbowKeyboardPrefs.bundle/Resources$(ECHO_END)
	$(ECHO_NOTHING)cp Resources/RainbowKeyboard.plist $(THEOS_STAGING_DIR)/Library/PreferenceBundles/RainbowKeyboardPrefs.bundle/Resources/RainbowKeyboard.plist$(ECHO_END)
