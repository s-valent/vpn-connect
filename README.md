# VPN Connect

A simple macOS menu bar app to connect/disconnect VPN.

## Features

- Menu bar app (no dock icon)
- Shows shield icon in menu bar:
  - Outlined shield (`lock.shield`) when disconnected
  - Filled shield (`lock.shield.fill`) when connected
- Click to connect/disconnect VPN

## Requirements

- macOS 13.0+
- Xcode 15.0+

## Building

1. Generate the Xcode project:
   ```bash
   make project
   ```

2. Build the project:
   ```bash
   make build
   ```

3. The built app will be at:
   ```
   .build/Build/Products/Debug/VPN Connect.app
   ```

## Running

- Double-click the app in Finder or use:
  ```bash
  make run
  ```

- Or open the project in Xcode and run from there:
  ```bash
  open VPNConnect.xcodeproj
  ```

## Usage

1. The app appears as a shield icon in the menu bar
2. Click the icon to see status and options
3. Click "Connect" to connect to your VPN (requires VPN configuration in System Settings)
4. When connected, the icon changes to a filled shield
5. Click "Disconnect" to disconnect

## VPN Configuration

Before connecting, you need to set up a VPN in System Settings:

1. Open **System Settings** > **VPN**
2. Add a new VPN configuration or use an existing one
3. The app will connect to your default/existing VPN configuration

## Project Structure

- `VPNConnect/VPNConnectApp.swift` - App entry point and menu bar UI
- `VPNConnect/VPNManager.swift` - VPN connection management using NetworkExtension
- `project.yml` - XcodeGen configuration
