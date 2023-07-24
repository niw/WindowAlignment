NAME := WindowAlignment

BUNDLE_ID := at.niw.$(NAME)

PROJECT_PATH := Applications/$(NAME).xcodeproj
SOURCES_PATH := Applications/$(NAME)/Sources
RESOURCES_PATH := Applications/$(NAME)/Resources

BUILD_PATH := .build

ARCHIVE_PATH := $(BUILD_PATH)/archive
ARCHIVE_PRODUCT_BUNDLE_PATH := $(ARCHIVE_PATH).xcarchive/Products/Applications/$(NAME).app

RELEASE_ARCHIVE_PATH := $(BUILD_PATH)/$(NAME).zip

.DEFAULT_GOAL = release

.PHONY: clean
clean:
	git clean -dfX

.PHONY: genstrings
genstrings:
	find "$(SOURCES_PATH)" -name "*.swift" -print0 | \
		xargs -0 genstrings -SwiftUI -u -q -o $(RESOURCES_PATH)/Base.lproj
	find "$(RESOURCES_PATH)/Base.lproj" -name "*.strings" -print0 | \
		xargs -0 -n 1 bash -c 'iconv -f UTF-16LE -t UTF-8 "$$@" > "$$@".utf8 && mv "$$@".utf8 "$$@"' -

.PHONY: reset_accessibility_access
reset_accessibility_access:
	tccutil reset Accessibility $(BUNDLE_ID)

$(ARCHIVE_PRODUCT_BUNDLE_PATH):
	xcodebuild \
		-project "$(PROJECT_PATH)" \
		-configuration Release \
		-scheme "$(NAME)" \
		-derivedDataPath "$(BUILD_PATH)" \
		-archivePath "$(ARCHIVE_PATH)" \
		archive

.PHONY: archive
archive: $(ARCHIVE_PRODUCT_BUNDLE_PATH)

$(RELEASE_ARCHIVE_PATH): $(ARCHIVE_PRODUCT_BUNDLE_PATH)
	ditto -c -k --sequesterRsrc --keepParent "$<" "$@"

.PHONY: release
release: $(RELEASE_ARCHIVE_PATH)
