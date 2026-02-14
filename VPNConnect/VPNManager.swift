import Foundation
import NetworkExtension

private let selectedVPNKey = "selectedVPNName"

class VPNManager: ObservableObject {
    private var statusObserver: NSObjectProtocol?
    private var managersByName: [String: NETunnelProviderManager] = [:]
    
    var onStatusChange: (() -> Void)?
    var onVPNListChange: (() -> Void)?
    
    @Published var isConnected: Bool = false
    @Published var availableVPNs: [VPNConfiguration] = []
    @Published var selectedVPN: VPNConfiguration? {
        didSet {
            if let vpn = selectedVPN {
                UserDefaults.standard.set(vpn.name, forKey: selectedVPNKey)
            }
        }
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
                self?.managersByName = managersDict
                self?.availableVPNs = vpnList
                self?.onVPNListChange?()
                
                let savedVPNName = UserDefaults.standard.string(forKey: selectedVPNKey)
                
                if let savedName = savedVPNName, let matchingVPN = vpnList.first(where: { $0.name == savedName }) {
                    self?.selectedVPN = matchingVPN
                    self?.observeVPNStatus(for: matchingVPN.manager)
                } else if self?.selectedVPN == nil, let first = vpnList.first {
                    self?.selectedVPN = first
                    self?.observeVPNStatus(for: first.manager)
                }
                
                if let selected = self?.selectedVPN,
                   let matchingManager = managersDict[selected.name] {
                    self?.observeVPNStatus(for: matchingManager)
                }
            }
        }
    }
    
    func selectVPN(_ vpn: VPNConfiguration) {
        selectedVPN = vpn
        observeVPNStatus(for: vpn.manager)
        onVPNListChange?()
        onStatusChange?()
    }
    
    private func observeVPNStatus(for manager: NETunnelProviderManager) {
        if let existingObserver = statusObserver {
            NotificationCenter.default.removeObserver(existingObserver)
        }
        
        statusObserver = NotificationCenter.default.addObserver(
            forName: .NEVPNStatusDidChange,
            object: manager.connection,
            queue: .main
        ) { [weak self] _ in
            self?.updateStatus(for: manager)
        }
        
        updateStatus(for: manager)
    }
    
    private func updateStatus(for manager: NETunnelProviderManager) {
        isConnected = manager.connection.status == .connected
        onStatusChange?()
    }
    
    func connect() {
        guard let selectedVPN = selectedVPN else {
            print("No VPN selected")
            return
        }
        
        observeVPNStatus(for: selectedVPN.manager)
        
        do {
            try selectedVPN.manager.connection.startVPNTunnel()
        } catch {
            print("Error starting VPN: \(error.localizedDescription)")
        }
    }
    
    func disconnect() {
        guard let selectedVPN = selectedVPN else {
            return
        }
        
        selectedVPN.manager.connection.stopVPNTunnel()
    }
    
    deinit {
        if let observer = statusObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
}

struct VPNConfiguration: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let manager: NETunnelProviderManager
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }
    
    static func == (lhs: VPNConfiguration, rhs: VPNConfiguration) -> Bool {
        lhs.name == rhs.name
    }
}
