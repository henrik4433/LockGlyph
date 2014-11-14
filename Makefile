include $(THEOS)/makefiles/common.mk

ARCHS = armv7 armv7s arm64

TARGET = iphone:clang:latest:8.0

TWEAK_NAME = LockGlyph
LockGlyph_FILES = Tweak.xm
LockGlyph_FRAMEWORKS = UIKit CoreGraphics AudioToolbox AVFoundation QuartzCore

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 backboardd"
SUBPROJECTS += lockglyphprefs
include $(THEOS_MAKE_PATH)/aggregate.mk
