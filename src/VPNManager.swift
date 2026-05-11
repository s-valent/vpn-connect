import Foundation
import NetworkExtension

private let selectedVPNKey = "selectedVPNName"
private let vpnAliasesKey = "VPNAliases"

class VPNManager {
    private var statusObservers: [String: NSObjectProtocol] = [:]
    private var managersByName: [String: NETunnelProviderManager] = [:]

    var onStatusChange: (() -> Void)?
    var onVPNListChange: (() -> Void)?

    var isConnected: Bool = false
    var availableVPNs: [VPNConfiguration] = []
    var selectedVPN: VPNConfiguration? {
        didSet {
            if let vpn = selectedVPN {
                UserDefaults.standard.set(vpn.name, forKey: selectedVPNKey)
            }
        }
    }

    private var aliases: [String: String] {
        get { UserDefaults.standard.dictionary(forKey: vpnAliasesKey) as? [String: String] ?? [:] }
        set { UserDefaults.standard.set(newValue, forKey: vpnAliasesKey) }
    }

    func displayName(for vpn: VPNConfiguration) -> String {
        aliases[vpn.name] ?? vpn.name
    }

    func setAlias(_ alias: String, for vpn: VPNConfiguration) {
        var current = aliases
        if alias.isEmpty || alias == vpn.name {
            current.removeValue(forKey: vpn.name)
        } else {
            current[vpn.name] = alias
        }
        aliases = current
        onVPNListChange?()
    }

    init() {
        loadVPNConfigurations()
    }

    func loadVPNConfigurations() {
        NETunnelProviderManager.loadAllFromPreferences { [weak self] managers, error in
            if let error = error {
                print("Error loading VPN configurations: \(error.localizedDescription)")
                return
            }

            guard let managers = managers else { return }

            var vpnList: [VPNConfiguration] = []
            var managersDict: [String: NETunnelProviderManager] = [:]

            for manager in managers {
                let name = manager.localizedDescription ?? "Unknown VPN"
                managersDict[name] = manager
                vpnList.append(VPNConfiguration(name: name, manager: manager))
            }

            DispatchQueue.main.async {
                guard let self = self else { return }

                self.statusObservers.values.forEach { NotificationCenter.default.removeObserver($0) }
                self.statusObservers.removeAll()

                self.managersByName = managersDict
                self.availableVPNs = vpnList

                if let connectedVPN = vpnList.first(where: { $0.manager.connection.status == .connected }) {
                    self.selectedVPN = connectedVPN
                } else {
                    let savedName = UserDefaults.standard.string(forKey: selectedVPNKey)
                    if let savedName = savedName, let vpn = vpnList.first(where: { $0.name == savedName }) {
                        self.selectedVPN = vpn
                    } else if let first = vpnList.first {
                        self.selectedVPN = first
                    }
                }

                for (_, manager) in managersDict {
                    self.observeVPNStatus(for: manager)
                }

                self.onVPNListChange?()
                self.onStatusChange?()
            }
        }
    }

    func selectVPN(_ vpn: VPNConfiguration) {
        let wasConnected = isConnected

        selectedVPN = vpn

        if wasConnected {
            for (_, manager) in managersByName {
                let status = manager.connection.status
                if status == .connected || status == .connecting {
                    manager.connection.stopVPNTunnel()
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                guard let self = self, self.selectedVPN?.name == vpn.name else { return }
                do {
                    try vpn.manager.connection.startVPNTunnel()
                } catch {
                    print("Error starting VPN: \(error.localizedDescription)")
                }
            }
        }

        onVPNListChange?()
        onStatusChange?()
    }

    private func observeVPNStatus(for manager: NETunnelProviderManager) {
        let key = manager.localizedDescription ?? UUID().uuidString
        if let existing = statusObservers[key] {
            NotificationCenter.default.removeObserver(existing)
        }
        let observer = NotificationCenter.default.addObserver(
            forName: .NEVPNStatusDidChange,
            object: manager.connection,
            queue: .main
        ) { [weak self] _ in
            self?.updateStatus(for: manager)
        }
        statusObservers[key] = observer
        updateStatus(for: manager)
    }

    private func updateStatus(for manager: NETunnelProviderManager) {
        if manager.connection.status == .connected,
           let vpn = availableVPNs.first(where: { $0.manager == manager }),
           vpn.name != selectedVPN?.name {
            selectedVPN = vpn
        }

        if let selected = selectedVPN {
            isConnected = selected.manager.connection.status == .connected
        } else {
            isConnected = false
        }

        onStatusChange?()
    }

    func connect() {
        guard let selectedVPN = selectedVPN else {
            print("No VPN selected")
            return
        }

        for (name, manager) in managersByName {
            if name != selectedVPN.name {
                let status = manager.connection.status
                if status == .connected || status == .connecting {
                    manager.connection.stopVPNTunnel()
                }
            }
        }

        do {
            try selectedVPN.manager.connection.startVPNTunnel()
        } catch {
            print("Error starting VPN: \(error.localizedDescription)")
        }
    }

    func disconnect() {
        guard let selectedVPN = selectedVPN else { return }
        selectedVPN.manager.connection.stopVPNTunnel()
    }

    deinit {
        statusObservers.values.forEach { NotificationCenter.default.removeObserver($0) }
    }
}

struct VPNConfiguration: Hashable {
    let name: String
    let manager: NETunnelProviderManager

    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }

    static func == (lhs: VPNConfiguration, rhs: VPNConfiguration) -> Bool {
        lhs.name == rhs.name
    }
}
