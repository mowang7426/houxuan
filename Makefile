ARCHS = arm64e
TARGET = iphone:clang::15.0

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = KBGlow
KBGlow_FILES = Tweak.xm KBGlowManager.m KBGlowView.m
KBGlow_CFLAGS = -fobjc-arc
KBGlow_FRAMEWORKS = UIKit QuartzCore

BUNDLE_NAME = KBGlowPrefs
KBGlowPrefs_FILES = KBGlowPrefs/RootListController.m KBGlowPrefs/ColorPickerController.m KBGlowPrefs/AnimationPickerController.m
KBGlowPrefs_INSTALL_PATH = /Library/PreferenceBundles
KBGlowPrefs_FRAMEWORKS = UIKit
KBGlowPrefs_CFLAGS = -fobjc-arc
KBGlowPrefs_LDFLAGS = -undefined dynamic_lookup
KBGlowPrefs_INFO_PLIST = KBGlowPrefs/Info.plist

include $(THEOS_MAKE_PATH)/tweak.mk
include $(THEOS_MAKE_PATH)/bundle.mk

after-stage::
	@mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceBundles/KBGlowPrefs.bundle
	cp KBGlowPrefs/layout/Library/PreferenceBundles/KBGlowPrefs.bundle/icon.png $(THEOS_STAGING_DIR)/Library/PreferenceBundles/KBGlowPrefs.bundle/icon.png
	cp KBGlowPrefs/layout/Library/PreferenceBundles/KBGlowPrefs.bundle/icon@2x.png $(THEOS_STAGING_DIR)/Library/PreferenceBundles/KBGlowPrefs.bundle/icon@2x.png
	mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences
	cp KBGlowPrefs/PreferenceLoader.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/KBGlowPrefs.plist

after-install::
	install.exec "killall -9 SpringBoard"
