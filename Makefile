NAME := WindowAlignment

BUNDLE_ID := at.niw.$(NAME)
PROJECT_PATH := Applications/$(NAME).xcodeproj
SOURCES_PATH := Applications/$(NAME)/Sources
RESOURCES_PATH := Applications/$(NAME)/Resources
BUILD_PATH := .build

.PHONY: reset_accessibility_access
reset_accessibility_access:
	tccutil reset Accessibility $(BUNDLE_ID)

.PHONY: genstrings
genstrings:
	find "$(SOURCES_PATH)" -name "*.swift" -print0 | \
		xargs -0 genstrings -SwiftUI -u -q -o $(RESOURCES_PATH)/Base.lproj
	find "$(RESOURCES_PATH)/Base.lproj" -name "*.strings" -print0 | \
		xargs -0 -n 1 bash -c 'iconv -f UTF-16LE -t UTF-8 "$$@" > "$$@".utf8 && mv "$$@".utf8 "$$@"' -

.PHONY: archive
archive:
	xcodebuild \
		-project "$(PROJECT_PATH)" \
		-configuration Release \
		-scheme "$(NAME)" \
		-derivedDataPath "$(BUILD_PATH)" \
		-archivePath "$(BUILD_PATH)/$(NAME)" \
		archive
