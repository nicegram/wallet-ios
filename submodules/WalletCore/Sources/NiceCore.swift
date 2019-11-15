//
//  NiceCore.swift
//  WalletCore
//
//  Created by Sergey Akentev on 06.11.2019.
//  Copyright NiceGram Wallet 2019
//

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
