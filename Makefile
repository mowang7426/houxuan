ARCHS = arm64e
TARGET = iphone:clang:17.0:15.0

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = KBGlow

KBGlow_FILES = Tweak.xm KBGlowManager.m KBGlowView.m
KBGlow_CFLAGS = -fobjc-arc
KBGlow_FRAMEWORKS = UIKit QuartzCore

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"

SUBPROJECTS += KBGlowPrefs
include $(THEOS_MAKE_PATH)/aggregate.mk
