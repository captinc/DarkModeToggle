ARCHS = arm64 arm64e
TARGET = iphone:clang::11.0
include $(THEOS)/makefiles/common.mk

TWEAK_NAME = 001_DarkModeToggleTweaksDisabler
001_DarkModeToggleTweaksDisabler_FILES = Tweak.xm
001_DarkModeToggleTweaksDisabler_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk
