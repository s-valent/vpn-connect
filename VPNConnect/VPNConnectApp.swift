import SwiftUI
import NetworkExtension

@main
struct VPNConnectApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var vpnManager: VPNManager!

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
        let vpnName = vpnManager.selectedVPN?.name ?? "No VPN"
        let statusItem = NSMenuItem(title: statusTitle, action: nil, keyEquivalent: "")
        statusItem.isEnabled = false
        menu.addItem(statusItem)

        menu.addItem(NSMenuItem.separator())

        let vpnHeader = NSMenuItem(title: "Select VPN:", action: nil, keyEquivalent: "")
        vpnHeader.isEnabled = false
        menu.addItem(vpnHeader)

        for vpn in vpnManager.availableVPNs {
            let vpnItem = NSMenuItem(title: vpn.name, action: #selector(selectVPN(_:)), keyEquivalent: "")
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

    @objc func quitApp() {
        NSApplication.shared.terminate(nil)
    }
}
