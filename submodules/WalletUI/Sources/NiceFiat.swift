//
//  NiceFiat.swift
//  WalletUI
//
//  Created by Sergey Akentev on 05.11.2019.
//  Copyright NiceGram Wallet 2019
//

import Foundation
import AppBundle
import WalletCore

public func getCurrencyData() -> [String:Any]? {
    if let path = getAppBundle().path(forResource: "currencies", ofType: "json") {
        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
            let jsonResult = try JSONSerialization.jsonObject(with: data, options: .mutableLeaves)
            return jsonResult as! [String : Any]
        } catch {
            // handle error
        }
    }
    return nil
}

let CURRENCIES = getCurrencyData()
let TOKENPRICE: Double = 3.5 // $3.5 for 1 GRAM


public func getLocaleAndPrice() -> (Locale, Double) {
    let languageCode = Bundle.main.preferredLocalizations[0]
    var regionCode = Locale.current.regionCode
    var currencyCode = Locale.current.currencyCode
    
    if var strongRegionCode = regionCode {
        regionCode = "-\(strongRegionCode)"
    } else {
        regionCode = ""
    }
    
    if var strongCurrencyCode = currencyCode {
    } else {
        currencyCode = "USD"
    }
    
    var localPrice = 0.0
    
    if let currencies = CURRENCIES {
        if let currencyData = currencies[currencyCode!] as? [String: Any] {
            if let minAmount = currencyData["min_amount"] as? String {
                if let strongMinAmount = Double(minAmount) {
                    localPrice = strongMinAmount / 100 * 1.0 * TOKENPRICE
                }
            }
        }
    }
    
    
    var localeWRegion = languageCode + regionCode!
    localPrice = 0 // Null token price
    if localPrice == 0 {
        localPrice = TOKENPRICE
        localeWRegion = "en_US"
    }
    
    return (Locale(identifier: localeWRegion), localPrice)
}


public func gramToFiatStr(_ gram: Int64?, _ approx: Bool = true, _ bagSpace: String = "") -> String {
    if let gram = gram {
        let (currLocale, fiatPrice) = getLocaleAndPrice()
        if fiatPrice == 0 {
            return ""
        }
        var humanGram = Double(gram) / 1000000000.0
        var fiatValue = fiatPrice * humanGram
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = currLocale
        if let formattedAmount = formatter.string(from: fiatValue as NSNumber) {
            var result = ""
            if approx {
                result = "~\(formattedAmount)"
            } else {
                result = "💰\(bagSpace)\(formattedAmount)"
            }
            if !result.isEmpty && isTestnet {
                var zeroAmountStr = ""
                if let zeroAmount = formatter.string(from: 0 as NSNumber) {
                    zeroAmountStr = " (\(zeroAmount))"
                }
                // result = "\(result) " + "| ⚠️ Testnet" + zeroAmountStr
            }
            return result
        }
    }
    return ""
}

public func getWarningText() -> String {
    return ""
    if isTestnet {
        return "⚠️ Testnet GRAMS DOES NOT cost any real money!\n⚠️ Тестовые GRAM НЕ СТОЯТ реальных денег! @notoscam\n\n"
    } else {
        return ""
    }
}

public func getWarningTextCount() -> Int {
    return (getWarningText().data(using: .utf8, allowLossyConversion: true)?.count ?? 0)
}

public func checkTestComment(_ exisitngComment: String) -> String {
    if !isTestnet {
        return exisitngComment
    }
    if exisitngComment.isEmpty {
        return getWarningText().trimmingCharacters(in: .whitespacesAndNewlines)
    } else {
        return "\(getWarningText())\(exisitngComment)"
    }
}


extension String {
    /*
     Truncates the string to the specified length number of characters and appends an optional trailing string if longer.
     - Parameter length: Desired maximum lengths of a string
     - Parameter trailing: A 'String' that will be appended after the truncation.
     
     - Returns: 'String' object.
     */
    func trunc(_ length: Int, trailing: String = "…") -> String {
        return (self.count > length) ? self.prefix(length) + trailing : self
    }
}
