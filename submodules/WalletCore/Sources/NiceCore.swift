//
//  NiceCore.swift
//  WalletCore
//
//  Created by Sergey Akentev on 06.11.2019.
//  Copyright Nicegram 220
//
import SwiftSignalKit
import Foundation

public var isTestnet = false

public func checkIsTestnetId(_ blockchainId: String) -> Void {
    if blockchainId.lowercased() == "testnet" || blockchainId.lowercased() == "testnet2" {
        isTestnet = true
        return
    }
    if blockchainId.lowercased().starts(with: "test") || blockchainId.lowercased().starts(with: "testnet") {
        isTestnet = true
        return
    }
    isTestnet = false
}

public enum ConnectionError {
    case network
    case data
}

public func httpPOST(url: URL, dict: [String: Any]) -> Signal<Data?, ConnectionError> {
    return Signal { subscriber in
        let completed = Atomic<Bool>(value: false)
        var request : URLRequest = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Application/json", forHTTPHeaderField: "Content-Type")

        do {
            let jsonData = try JSONSerialization.data(withJSONObject: dict, options: [])
            request.httpBody = jsonData
        } catch {
            print(error.localizedDescription)
             subscriber.putError(.data)
        }
        let dataTask = URLSession.shared.downloadTask(with: request, completionHandler: { data, response, error in
            let _ = completed.swap(true)
            if let response = response as? HTTPURLResponse {
                if response.statusCode == 200 {
                    subscriber.putNext(nil)
                    subscriber.putCompletion()
                } else {
                    subscriber.putError(.network)
                }
            } else {
                subscriber.putError(.network)
            }
        })
        dataTask.resume()
        
        return ActionDisposable {
            if !completed.with({ $0 }) {
                dataTask.cancel()
            }
        }
    }
}

public class NiceSettings {
    let UD = UserDefaults()

    public init() {}

    public var notificationToken: Data? {
        get {
            return UD.data(forKey: "notificationToken") ?? nil
        }
        set {
            if let strongNewValue = newValue {
                UD.set(strongNewValue, forKey: "notificationToken")
            }
        }
    }
}

public func hexString(_ data: Data) -> String {
    let hexString = NSMutableString()
    data.withUnsafeBytes { (bytes: UnsafePointer<UInt8>) -> Void in
        for i in 0 ..< data.count {
            hexString.appendFormat("%02x", UInt(bytes.advanced(by: i).pointee))
        }
    }
    
    return hexString as String
}

let API_URL = "https://api.wallet.nicegram.app/v1/"

public func registerNotificationToken(token: Data, addresses: [String], sandbox: Bool) -> Signal<Never, NoError> {
    return httpPOST(url: URL(string: API_URL + "registerDevice")!, dict: ["token": hexString(token), "addresses" : addresses, "sandbox": sandbox])
        |> retry(1.0, maxDelay: 5.0, onQueue: Queue.concurrentDefaultQueue())
        |> ignoreValues
}

public func unregisterNotificationToken(token: Data, sandbox: Bool) -> Signal<Never, NoError> {
    return httpPOST(url: URL(string: API_URL + "unregisterDevice")!, dict: ["token": hexString(token), "sandbox": sandbox])
        |> retry(1.0, maxDelay: 5.0, onQueue: Queue.concurrentDefaultQueue())
        |> ignoreValues
}


public func updateNotificationTokensRegistration(notificationToken: Data, address: String?) {
    let sandbox: Bool
    #if DEBUG
    sandbox = true
    #else
    sandbox = false
    #endif
    
    
    print("Unregistering Notifications")
    unregisterNotificationToken(token: notificationToken, sandbox: sandbox).start(completed: {
        print("Registering notifications")
        if let address = address {
            registerNotificationToken(token: notificationToken, addresses: [address], sandbox: sandbox).start(completed: {
                print("Notifications registered!")
            })
        }
    })
    
}
