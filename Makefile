.PHONY: project icon build release run clean

project:
	xcodegen generate

icon:
	swift scripts/generate_icon.swift

build: icon project
	xcodebuild -project VPNConnect.xcodeproj -scheme VPNConnect -configuration Debug -derivedDataPath .build build

release: icon project
	xcodebuild -project VPNConnect.xcodeproj -scheme VPNConnect -configuration Release -derivedDataPath .build build

run: build
	open .build/Build/Products/Debug/VPN\ Connect.app

clean:
	rm -rf .build
	rm -rf VPNConnect.xcodeproj
	rm -rf VPNConnect/Resources
