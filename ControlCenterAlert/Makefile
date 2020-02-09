ARCHS = arm64 arm64e
TARGET = iphone:clang::11.0
include $(THEOS)/makefiles/common.mk

TWEAK_NAME = DarkModeToggleCCAlert
DarkModeToggleCCAlert_FILES = $(wildcard *.xm)
DarkModeToggleCCAlert_CFLAGS = -fobjc-arc
DarkModeToggleCCAlert_FRAMEWORKS = UIKit

include $(THEOS_MAKE_PATH)/tweak.mk
