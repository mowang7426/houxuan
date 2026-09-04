ARCHS = arm64e
TARGET = iphone:clang::15.0

include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = KBGlowPrefs
KBGlowPrefs_FILES = RootListController.m ColorPickerController.m
KBGlowPrefs_INSTALL_PATH = /Library/PreferenceBundles
KBGlowPrefs_FRAMEWORKS = UIKit
KBGlowPrefs_CFLAGS = -fobjc-arc
KBGlowPrefs_LDFLAGS = -undefined dynamic_lookup
KBGlowPrefs_INFO_PLIST = Info.plist

include $(THEOS_MAKE_PATH)/bundle.mk

after-stage::
	cp Info.plist $(THEOS_STAGING_DIR)/Library/PreferenceBundles/KBGlowPrefs.bundle/Info.plist
	cp layout/Library/PreferenceBundles/KBGlowPrefs.bundle/Root.plist $(THEOS_STAGING_DIR)/Library/PreferenceBundles/KBGlowPrefs.bundle/Root.plist
	cp layout/Library/PreferenceBundles/KBGlowPrefs.bundle/Animation.plist $(THEOS_STAGING_DIR)/Library/PreferenceBundles/KBGlowPrefs.bundle/Animation.plist
	cp layout/Library/PreferenceBundles/KBGlowPrefs.bundle/Color.plist $(THEOS_STAGING_DIR)/Library/PreferenceBundles/KBGlowPrefs.bundle/Color.plist
	cp layout/Library/PreferenceBundles/KBGlowPrefs.bundle/icon.png $(THEOS_STAGING_DIR)/Library/PreferenceBundles/KBGlowPrefs.bundle/icon.png
