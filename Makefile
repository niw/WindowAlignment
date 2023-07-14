NAME := WindowAlignment

BUNDLE_ID := at.niw.$(NAME)
PROJECT_PATH := Applications/$(NAME).xcodeproj
BUILD_PATH := .build

.PHONY: reset_accessibility_access
reset_accessibility_access:
	tccutil reset Accessibility $(BUNDLE_ID)

.PHONY: archive
archive:
	xcodebuild \
		-project "$(PROJECT_PATH)" \
		-configuration Release \
		-scheme "$(NAME)" \
		-derivedDataPath "$(BUILD_PATH)" \
		-archivePath "$(BUILD_PATH)/$(NAME)" \
		archive
