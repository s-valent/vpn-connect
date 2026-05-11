import SwiftUI

@main
struct VPNConnectApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    var statusItem: NSStatusItem!
    var vpnManager: VPNManager!
    private weak var renameTextField: NSTextField?
    private weak var renamePopupButton: NSPopUpButton?
    private var renameWindow: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        vpnManager = VPNManager()

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "lock.shield", accessibilityDescription: "VPN")
        }

        updateMenu()

        vpnManager.onStatusChange = { [weak self] in
            self?.updateMenu()
            self?.updateIcon()
        }

        vpnManager.onVPNListChange = { [weak self] in
            self?.updateMenu()
        }
    }

    func updateIcon() {
        guard let button = statusItem.button else { return }

        let imageName = vpnManager.isConnected ? "lock.shield.fill" : "lock.shield"
        button.image = NSImage(systemSymbolName: imageName, accessibilityDescription: "VPN")
    }

    func updateMenu() {
        let menu = NSMenu()

        let statusTitle = vpnManager.isConnected ? "Connected" : "Disconnected"
        let statusItem = NSMenuItem(title: statusTitle, action: nil, keyEquivalent: "")
        statusItem.isEnabled = false
        menu.addItem(statusItem)

        menu.addItem(NSMenuItem.separator())

        let vpnHeader = NSMenuItem(title: "Select VPN:", action: nil, keyEquivalent: "")
        vpnHeader.isEnabled = false
        menu.addItem(vpnHeader)

        for vpn in vpnManager.availableVPNs {
            let vpnItem = NSMenuItem(title: vpnManager.displayName(for: vpn), action: #selector(selectVPN(_:)), keyEquivalent: "")
            vpnItem.target = self
            vpnItem.representedObject = vpn
            vpnItem.state = (vpnManager.selectedVPN?.name == vpn.name) ? .on : .off
            menu.addItem(vpnItem)
        }

        if vpnManager.availableVPNs.isEmpty {
            let noVPNItem = NSMenuItem(title: "No VPNs configured", action: nil, keyEquivalent: "")
            noVPNItem.isEnabled = false
            menu.addItem(noVPNItem)
        }

        menu.addItem(NSMenuItem.separator())

        let connectItem = NSMenuItem(title: vpnManager.isConnected ? "Disconnect" : "Connect", action: #selector(toggleVPN), keyEquivalent: "c")
        connectItem.target = self
        connectItem.isEnabled = vpnManager.selectedVPN != nil
        menu.addItem(connectItem)

        menu.addItem(NSMenuItem.separator())

        let renameItem = NSMenuItem(title: "Rename VPN...", action: #selector(renameVPN), keyEquivalent: "")
        renameItem.target = self
        menu.addItem(renameItem)

        let refreshItem = NSMenuItem(title: "Refresh VPN List", action: #selector(refreshVPNs), keyEquivalent: "r")
        refreshItem.target = self
        menu.addItem(refreshItem)

        menu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        self.statusItem.menu = menu
    }

    @objc func selectVPN(_ sender: NSMenuItem) {
        guard let vpn = sender.representedObject as? VPNConfiguration else { return }
        vpnManager.selectVPN(vpn)
    }

    @objc func toggleVPN() {
        if vpnManager.isConnected {
            vpnManager.disconnect()
        } else {
            vpnManager.connect()
        }
    }

    @objc func refreshVPNs() {
        vpnManager.loadVPNConfigurations()
    }

    @objc func renameVPN() {
        let vpns = vpnManager.availableVPNs
        guard !vpns.isEmpty else { return }

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 340, height: 140),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "Rename VPN"
        window.isReleasedWhenClosed = false
        window.delegate = self
        window.center()

        let contentView = window.contentView!

        let popupButton = NSPopUpButton(frame: NSRect(x: 20, y: 85, width: 300, height: 24))
        for vpn in vpns {
            popupButton.addItem(withTitle: vpn.name)
        }
        if let selected = vpnManager.selectedVPN,
           let index = vpns.firstIndex(where: { $0.name == selected.name }) {
            popupButton.selectItem(at: index)
        }
        renamePopupButton = popupButton

        let textField = NSTextField(frame: NSRect(x: 20, y: 50, width: 300, height: 24))
        if let selected = popupButton.titleOfSelectedItem,
           let vpn = vpns.first(where: { $0.name == selected }) {
            textField.stringValue = vpnManager.displayName(for: vpn)
        }

        renameTextField = textField
        popupButton.target = self
        popupButton.action = #selector(renameSelectionChanged(_:))

        let okButton = NSButton(title: "OK", target: self, action: #selector(renameOKClicked))
        okButton.frame = NSRect(x: 220, y: 12, width: 100, height: 24)
        okButton.keyEquivalent = "\r"

        let cancelButton = NSButton(title: "Cancel", target: self, action: #selector(renameCancelClicked))
        cancelButton.frame = NSRect(x: 110, y: 12, width: 100, height: 24)
        cancelButton.keyEquivalent = "\u{1b}"

        contentView.addSubview(popupButton)
        contentView.addSubview(textField)
        contentView.addSubview(cancelButton)
        contentView.addSubview(okButton)

        window.makeFirstResponder(textField)
        renameWindow = window

        window.makeKeyAndOrderFront(nil)
        NSApplication.shared.activate(ignoringOtherApps: true)
    }

    @objc func renameOKClicked() {
        guard let popupButton = renamePopupButton,
              let textField = renameTextField else {
            renameWindow?.close()
            renameWindow = nil
            return
        }
        let selectedName = popupButton.titleOfSelectedItem ?? ""
        if let vpn = vpnManager.availableVPNs.first(where: { $0.name == selectedName }) {
            let newName = textField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
            vpnManager.setAlias(newName, for: vpn)
        }
        renameWindow?.close()
        renameWindow = nil
    }

    @objc func renameCancelClicked() {
        renameWindow?.close()
        renameWindow = nil
    }

    func windowWillClose(_ notification: Notification) {
        if (notification.object as? NSWindow) == renameWindow {
            renameWindow = nil
            renameTextField = nil
            renamePopupButton = nil
        }
    }

    @objc func renameSelectionChanged(_ sender: NSPopUpButton) {
        let selectedName = sender.titleOfSelectedItem ?? ""
        if let vpn = vpnManager.availableVPNs.first(where: { $0.name == selectedName }) {
            renameTextField?.stringValue = vpnManager.displayName(for: vpn)
        }
    }

    @objc func quitApp() {
        NSApplication.shared.terminate(nil)
    }
}
