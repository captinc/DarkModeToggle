ARCHS = arm64 arm64e
TARGET = iphone:clang::11.0
include $(THEOS)/makefiles/common.mk

TWEAK_NAME = DarkModeToggleSB
DarkModeToggleSB_FILES = $(wildcard *.xm)
DarkModeToggleSB_CFLAGS = -fobjc-arc
DarkModeToggleSB_FRAMEWORKS = UIKit

include $(THEOS_MAKE_PATH)/tweak.mk
