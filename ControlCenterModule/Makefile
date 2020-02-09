ARCHS = arm64 arm64e
TARGET = iphone:clang:11.2:11.0
include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = DarkModeToggleCCModule
DarkModeToggleCCModule_FILES = DarkModeToggleCCModule.m
DarkModeToggleCCModule_INSTALL_PATH = /Library/ControlCenter/Bundles
DarkModeToggleCCModule_CFLAGS = -fobjc-arc
DarkModeToggleCCModule_FRAMEWORKS = UIKit
DarkModeToggleCCModule_PRIVATE_FRAMEWORKS = ControlCenterUIKit

include $(THEOS_MAKE_PATH)/bundle.mk
