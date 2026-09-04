THEOS_PACKAGE_SCHEME = rootless
ARCHS = arm64 arm64e
TARGET = iphone:clang:latest:15.0

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = GradientCandidates
GradientCandidates_FILES = Tweak.xm
GradientCandidates_CFLAGS = -fobjc-arc
GradientCandidates_FRAMEWORKS = UIKit CoreGraphics
GradientCandidates_PRIVATE_FRAMEWORKS = UIKit

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard || true"
