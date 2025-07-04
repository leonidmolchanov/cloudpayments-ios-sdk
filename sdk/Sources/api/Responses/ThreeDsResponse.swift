//
//  ThreeDsResponse.swift
//  sdk
//
//  Created by Sergey Iskhakov on 24.09.2020.
//  Copyright © 2020 Cloudpayments. All rights reserved.
//

import Foundation

public struct ThreeDsResponse {
    public private(set) var success: Bool
    public private(set) var reasonCode: String?
    
    init(success: Bool, reasonCode: String?) {
        self.success = success
        self.reasonCode = reasonCode
    }
}

struct IntentThreeDsResultResponse: Codable {
    let data: IntentThreeDsData?
    let errorMessage: String?
    let success: Bool?
}

struct IntentThreeDsData: Codable {
    let success: Bool?
    let code: String?
}
