TARGET := iphone:clang:latest:15.0
ARCHS ?= arm64

include $(THEOS)/makefiles/common.mk

TWEAK_NAME := RainbowKeyboard
RainbowKeyboard_FILES := Tweak.xm RainbowEffectView.m CandidateGradient.xm CandidateDiagnostics.xm
RainbowKeyboard_CFLAGS := -fobjc-arc -Wno-deprecated-declarations
RainbowKeyboard_FRAMEWORKS := UIKit QuartzCore

include $(THEOS_MAKE_PATH)/tweak.mk

SUBPROJECTS += RainbowKeyboardPrefs
include $(THEOS_MAKE_PATH)/aggregate.mk
