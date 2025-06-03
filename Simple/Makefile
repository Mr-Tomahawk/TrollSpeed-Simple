TARGET := iphone:clang:16.5:14.0
ARCHS := arm64
INSTALL_TARGET_PROCESSES = RedSquareHUD

include $(THEOS)/makefiles/common.mk

APPLICATION_NAME = RedSquareHUD

RedSquareHUD_FILES = main.mm \
	HUD/HUDRootViewController.mm \
	HUD/HUDMainWindow.mm \
	HUD/HUDMainApplicationDelegate.mm \
	HUD/HUDMainApplication.mm \
	Launcher/RootViewController.mm \
	Launcher/MainApplicationDelegate.mm \
	UI/MainButton.mm \
	Utils/HUDHelper.mm
RedSquareHUD_CFLAGS += -fobjc-arc -Iheaders -IHUD -ILauncher -IUI -IUtils -include RedSquareHUD-Prefix.pch

RedSquareHUD_FRAMEWORKS = CoreGraphics CoreServices QuartzCore IOKit UIKit Foundation
RedSquareHUD_PRIVATE_FRAMEWORKS = BackBoardServices GraphicsServices SpringBoardServices AccessibilityUtilities # Add others if needed

RedSquareHUD_CODESIGN_FLAGS = -S$(PWD)/entitlements.plist

include $(THEOS_MAKE_PATH)/application.mk

# Add .tipa packaging steps
after-package::
	$(ECHO_NOTHING)mkdir -p packages $(THEOS_STAGING_DIR)/Payload$(ECHO_END)
	$(ECHO_NOTHING)cp -rp $(THEOS_STAGING_DIR)$(THEOS_PACKAGE_INSTALL_PREFIX)/Applications/$(APPLICATION_NAME).app $(THEOS_STAGING_DIR)/Payload/$(ECHO_END)
	$(ECHO_NOTHING)cd $(THEOS_STAGING_DIR); zip -qr $(APPLICATION_NAME).tipa Payload; cd -;$(ECHO_END)
	$(ECHO_NOTHING)mv $(THEOS_STAGING_DIR)/$(APPLICATION_NAME).tipa packages/$(APPLICATION_NAME).tipa$(ECHO_END)
	@echo "Packaged .tipa to packages/$(APPLICATION_NAME).tipa"
