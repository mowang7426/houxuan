ARCHS = arm64e
TARGET = iphone:clang:17.0:15.0

include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = KBGlowPrefs
KBGlowPrefs_FILES = RootListController.m ColorPickerController.m
KBGlowPrefs_INSTALL_PATH = /Library/PreferenceBundles
KBGlowPrefs_FRAMEWORKS = UIKit
KBGlowPrefs_PRIVATE_FRAMEWORKS = Preferences
KBGlowPrefs_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/bundle.mk
