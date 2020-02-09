ARCHS = arm64 arm64e
TARGET = iphone:clang::11.0
include $(THEOS)/makefiles/common.mk

TWEAK_NAME = DarkModeToggle
DarkModeToggle_CFLAGS = -fobjc-arc

SUBPROJECTS += ControlCenterAlert ControlCenterModule darkmodetoggled Preferences TweaksDisabler
include $(THEOS_MAKE_PATH)/aggregate.mk

before-stage::
	find . -name ".DS_Store" -type f -delete
