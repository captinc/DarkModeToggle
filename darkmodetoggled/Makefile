ARCHS = arm64 arm64e
TARGET = iphone:clang::11.0
include $(THEOS)/makefiles/common.mk

TOOL_NAME = darkmodetoggled
darkmodetoggled_FILES = main.m
darkmodetoggled_CFLAGS = -fobjc-arc
darkmodetoggled_CODESIGN_FLAGS = -Sent.xml

include $(THEOS_MAKE_PATH)/tool.mk
