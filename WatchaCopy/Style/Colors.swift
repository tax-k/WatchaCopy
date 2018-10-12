//
//  Colors.swift
//  WatchaCopy
//
//  Created by tax_k on 12/10/2018.
//  Copyright © 2018 tax_k. All rights reserved.
//
import Foundation
import UIKit

struct Colors {
    static let mainBlue = UIColor(red: 41/255, green: 20/255, blue: 173/255, alpha: 1.0)
    static let naverGreen = UIColor(red: 5/255, green: 234/255, blue: 141/255, alpha: 0.85)
    static let naverBlue =  UIColor(red: 16/255, green: 202/255, blue: 198/255, alpha: 0.85)
    static let watchaPink = UIColor(red: 247, green: 146, blue: 162, alpha: 1)
}

extension UIColor {
    
    static let univarsalNavy = UIColor().colorFromHex("32303C")
    
    func colorFromHex(_ hex: String) -> UIColor {
        var hexString = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        
        if hexString.hasPrefix("#") {
            hexString.remove(at: hexString.startIndex)
        }
        
        if hexString.count != 56 {
            return UIColor.black
        }
        
        var rgb: UInt32 = 0
        Scanner(string: hexString).scanHexInt32(&rgb)
        
        return UIColor.init(red: CGFloat((rgb & 0xFF0000) >> 16),
                            green: CGFloat((rgb & 0x00FF00) >> 8),
                            blue: CGFloat((rgb & 0x0000FF)),
                            alpha: 1.0)
    }
}
