TARGET := iphone:clang:16.5:14.0
ARCHS := arm64
INSTALL_TARGET_PROCESSES = RedSquareHUD

include $(THEOS)/makefiles/common.mk

APPLICATION_NAME = RedSquareHUD

RedSquareHUD_FILES = HUDApp.mm \
	HUD/HUDRootViewController.mm \
	HUD/HUDMainWindow.mm \
	HUD/HUDMainApplicationDelegate.mm \
	HUD/HUDMainApplication.mm \
	Launcher/RootViewController.mm \
	Launcher/MainApplicationDelegate.mm \
	UI/MainButton.mm \
	UI/TSSettingsIndex.swift \
	UI/TSSettingsController.swift \
	UI/SPLarkController/SPLarkController.swift \
	UI/SPLarkController/SPLarkControllerExtension.swift \
	UI/SPLarkController/SPLarkDismissingAnimationController.swift \
	UI/SPLarkController/SPLarkPresentationController.swift \
	UI/SPLarkController/SPLarkPresentingAnimationController.swift \
	UI/SPLarkController/SPLarkSettingsCloseButton.swift \
	UI/SPLarkController/SPLarkSettingsCollectionView.swift \
	UI/SPLarkController/SPLarkSettingsCollectionViewCell.swift \
	UI/SPLarkController/SPLarkSettingsController.swift \
	UI/SPLarkController/SPLarkTransitioningDelegate.swift \
	Utils/HUDHelper.mm \
	Utils/TSEventFetcher.mm \
	KIF/UITouch-KIFAdditions.m \
	KIF/IOHIDEvent+KIF.m
RedSquareHUD_CFLAGS += -fobjc-arc -Iheaders -IHUD -ILauncher -IUI -IUtils -IKIF -include RedSquareHUD-Prefix.pch
RedSquareHUD_SWIFT_BRIDGING_HEADER += SimpleTS-Bridging-Header.h

RedSquareHUD_FRAMEWORKS = CoreGraphics CoreServices QuartzCore IOKit UIKit Foundation
RedSquareHUD_PRIVATE_FRAMEWORKS = BackBoardServices GraphicsServices SpringBoardServices AccessibilityUtilities

RedSquareHUD_CODESIGN_FLAGS = -S$(PWD)/entitlements.plist

include $(THEOS_MAKE_PATH)/application.mk

# Add .tipa packaging steps
after-package::
	$(ECHO_NOTHING)mkdir -p packages $(THEOS_STAGING_DIR)/Payload$(ECHO_END)
	$(ECHO_NOTHING)cp -rp $(THEOS_STAGING_DIR)$(THEOS_PACKAGE_INSTALL_PREFIX)/Applications/$(APPLICATION_NAME).app $(THEOS_STAGING_DIR)/Payload/$(ECHO_END)
	$(ECHO_NOTHING)cd $(THEOS_STAGING_DIR); zip -qr $(APPLICATION_NAME).tipa Payload; cd -;$(ECHO_END)
	$(ECHO_NOTHING)mv $(THEOS_STAGING_DIR)/$(APPLICATION_NAME).tipa packages/$(APPLICATION_NAME).tipa$(ECHO_END)
	@echo "Packaged .tipa to packages/$(APPLICATION_NAME).tipa"
