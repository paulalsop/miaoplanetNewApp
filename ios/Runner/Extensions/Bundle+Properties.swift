//
//  Bundle+Properties.swift
//  Runner
//
//  Created by Hiddify on 12/26/23.
//

import Foundation

extension Bundle {
    var serviceIdentifier: String {
        // 直接返回固定值，确保与Flutter代码一致
        return "com.hiddify.app"
    }
    
    var baseBundleIdentifier: String {
        (infoDictionary?["BASE_BUNDLE_IDENTIFIER"] as? String) ?? "app.xingqiu.miao"
    }
}
