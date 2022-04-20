//
//  File.swift
//  
//
//  Created by ERM on 20/04/2022.
//

#if !os(macOS)
import Alamofire
import UIKit

public class InfoHelper {
    static let shared = InfoHelper()

    // MARK: - Get identifierForVendor
    var identifierForVendor: String {
        return UIDevice.current.identifierForVendor?.description ?? ""
    }
    var ipAddress: String {
        return getIPAddress() ?? ""
    }
    var deviceToken: String = ""
    // MARK: - Get Device Name

    var deviceName: String {
        return UIDevice.current.name
    }

    // MARK: - Get Device Model

    var deviceModel: String {
        return UIDevice.current.model
    }

    // MARK: - Get Device OS

    var deviceOS: String {
        return UIDevice.current.systemName + " " + UIDevice.current.systemVersion
    }

    // MARK: - Get App Name

    var appName: String {
        guard let dictionary = Bundle.main.infoDictionary else { return "" }
        if let name = dictionary["CFBundleName"] as? String { return name }
        return ""
    }

    // MARK: - Get App Version

    var appVersion: String {
        guard let dictionary = Bundle.main.infoDictionary else { return "" }
        if let version = dictionary["CFBundleShortVersionString"] as? String { return version }
        return ""
    }

    // MARK: - Get Build Version

    var buildVersion: String {
        guard let dictionary = Bundle.main.infoDictionary else { return "" }
        if let version = dictionary["CFBundleVersion"] as? String { return version }
        return ""
    }

    // MARK: - Get Display Version

    var displayVersion: String {
        return appName + " " + appVersion + " (\(buildVersion))"
    }
    // MARK: - Get app url
    
    func getAppURL() -> String{
        let url = "https://apps.apple.com/%@/app/%@/id%@"
        let locale = Locale.current.regionCode
        let appName = SharedInfoHelper.appName
        let link = String(format: url, locale ?? "", appName, "1511450688" )
        return link
    }
    // MARK: - Get app version
    
    func getAppVersion() -> String {
        var appVersion = ""
        appVersion += "\(self.appVersion)."
        appVersion += self.buildVersion
        return appVersion
    }
    // MARK: - Get Submit User Agent
    
    func getSubmitUserAgent() -> String {
        var result = ""
        result += appName + " "
        result += appVersion + ", "
        result += deviceName + ", "
        result += deviceModel + " "
        result += deviceOS
        return result
    }
}

public let SharedInfoHelper = InfoHelper.shared
func getIPAddress() -> String? {
    
    var address: String?
    var ifaddr: UnsafeMutablePointer<ifaddrs>?
    
    if getifaddrs(&ifaddr) == 0 {
        
        var ptr = ifaddr
        while ptr != nil {
            defer { ptr = ptr?.pointee.ifa_next }
            guard let interface = ptr?.pointee else {
                return nil
            }
            let addrFamily = interface.ifa_addr.pointee.sa_family
            if addrFamily == UInt8(AF_INET) || addrFamily == UInt8(AF_INET6) {
                
                guard let ifa_name = interface.ifa_name else {
                    return nil
                }
                let name: String = String(cString: ifa_name)
                
                if name == "en0" {
                    var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                    getnameinfo(interface.ifa_addr, socklen_t((interface.ifa_addr.pointee.sa_len)), &hostname, socklen_t(hostname.count), nil, socklen_t(0), NI_NUMERICHOST)
                    address = String(cString: hostname)
                }
                
            }
        }
        freeifaddrs(ifaddr)
    }
    return address
}

extension Int{
    func intToNull() -> Int? {
        if self < 0 {
            return nil
        }
        return self
    }
}
#endif
