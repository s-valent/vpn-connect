.PHONY: build release install run clean

APP_NAME := VPN Connect
APP_BUNDLE := .build/$(APP_NAME).app

build:
	swift build
	@mkdir -p "$(APP_BUNDLE)/Contents/MacOS"
	@mkdir -p "$(APP_BUNDLE)/Contents/Resources"
	swift scripts/generate_icon.swift "$(APP_BUNDLE)/Contents/Resources"
	cp ".build/debug/VPN Connect" "$(APP_BUNDLE)/Contents/MacOS/"
	cp "Info.plist" "$(APP_BUNDLE)/Contents/"
	touch "$(APP_BUNDLE)"

release:
	swift build -c release
	@mkdir -p "$(APP_BUNDLE)/Contents/MacOS"
	@mkdir -p "$(APP_BUNDLE)/Contents/Resources"
	swift scripts/generate_icon.swift "$(APP_BUNDLE)/Contents/Resources"
	cp ".build/release/VPN Connect" "$(APP_BUNDLE)/Contents/MacOS/"
	cp "Info.plist" "$(APP_BUNDLE)/Contents/"
	touch "$(APP_BUNDLE)"

install: release
	sudo cp -r "$(APP_BUNDLE)" /Applications/Utilities/

run: build
	killall "$(APP_NAME)" || true
	open "$(APP_BUNDLE)"

clean:
	rm -rf .build
