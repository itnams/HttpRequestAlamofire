//
//  File.swift
//  
//
//  Created by ERM on 20/04/2022.
//

import Alamofire

// MARK: Check network connection

public typealias NetworkSignalTrigger = (Bool) -> Void
public class NetworkMonitor {
    public static let shared = NetworkMonitor()
    fileprivate var _reachabilityManager: NetworkReachabilityManager!
    fileprivate var reachabilityManager: NetworkReachabilityManager! {
        if _reachabilityManager == nil {
            _reachabilityManager = NetworkReachabilityManager()
        }
        return _reachabilityManager
    }

    /**
     Check a network connection whether is reachable or not.
     */
    static var isReachable: Bool {
        return shared.reachabilityManager.isReachable
    }

    /**
     register a obserable to monitor connection signal.
     - Parameter handler: a trigger action to capture connection signal
     */
    public func startNetworkReachabilityObserver(handler: @escaping NetworkSignalTrigger) {
        reachabilityManager.startListening { status in
            switch status {
            case .notReachable:
                handler(false)
                debugPrint("The network is not reachable")

            case .unknown:
                handler(false)
                debugPrint("It is unknown whether the network is reachable")

            case .reachable(.ethernetOrWiFi):
                handler(true)
                debugPrint("The network is reachable over the WiFi connection")

            case .reachable(.cellular):
                handler(true)
                debugPrint("The network is reachable over the WWAN connection")
            }
        }
    }

    static func startNetworkReachabilityObserver(handler: @escaping NetworkSignalTrigger) {
        shared.startNetworkReachabilityObserver(handler: handler)
    }
}
