//
//  PollingService.swift
//  sdk
//
//  Created by Cloudpayments on 28.04.2025.
//  Copyright © 2025 Cloudpayments. All rights reserved.
//

import UIKit
import Foundation

protocol PaymentPollingService {
    func startPolling(taskName: String, interval: TimeInterval, handler: @escaping () -> Void)
    func stopPolling()
}

final class PaymentPollingServiceImpl: PaymentPollingService {
    private var backgroundTask: UIBackgroundTaskIdentifier = .invalid
    private var timer: DispatchSourceTimer?
    
    init() {}
    
    func startPolling(taskName: String, interval: TimeInterval, handler: @escaping () -> Void) {
        stopPolling()
        
        backgroundTask = UIApplication.shared.beginBackgroundTask(withName: taskName) {
            UIApplication.shared.endBackgroundTask(self.backgroundTask)
            self.backgroundTask = .invalid
        }
        
        let timerSource = DispatchSource.makeTimerSource(queue: .main)
        timerSource.schedule(deadline: .now(), repeating: interval)
        timerSource.setEventHandler(handler: handler)
        timerSource.resume()
        timer = timerSource
    }
    
    func stopPolling() {
        timer?.cancel()
        timer = nil
        
        if backgroundTask != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTask)
            backgroundTask = .invalid
        }
    }
}
