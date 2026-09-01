APP_NAME = SonyConnect
BUILD_DIR = .build/release
APP_BUNDLE = $(APP_NAME).app

.PHONY: all build app run clean

all: app

build:
	swift build -c release

app: build
	rm -rf $(APP_BUNDLE)
	mkdir -p $(APP_BUNDLE)/Contents/MacOS
	mkdir -p $(APP_BUNDLE)/Contents/Resources
	cp $(BUILD_DIR)/$(APP_NAME) $(APP_BUNDLE)/Contents/MacOS/
	cp Resources/Info.plist $(APP_BUNDLE)/Contents/
	cp Resources/AppIcon.icns $(APP_BUNDLE)/Contents/Resources/
	codesign --force --sign - --entitlements /dev/null $(APP_BUNDLE) 2>/dev/null || true
	@echo "Built $(APP_BUNDLE)"

run: app
	-pkill -f "$(APP_BUNDLE)/Contents/MacOS/$(APP_NAME)" 2>/dev/null
	@sleep 0.3
	open $(APP_BUNDLE)

clean:
	rm -rf .build $(APP_BUNDLE)
