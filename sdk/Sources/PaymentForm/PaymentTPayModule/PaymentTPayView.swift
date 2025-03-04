//
//  PaymentTPayView.swift
//  sdk
//
//  Created by Cloudpayments on 07.11.2023.
//  Copyright © 2023 Cloudpayments. All rights reserved.
//

import UIKit

public protocol PaymentTPayDelegate: AnyObject {
    func resultPayment(_ tPay: PaymentTPayView, result: PaymentTPayView.PaymentAction, error: String?, transactionId: Int64?)
}

//MARK: - PaymentTPayView

public final class PaymentTPayView: UIView {
    
    public weak var delegate: PaymentTPayDelegate?
    private var buttonResult: ButtonConfiguration?
    public var configuration: PaymentConfiguration! = nil
    
    //MARK: - Init
    
    public init(configuration: PaymentConfiguration! = nil) {
        super.init(frame: .infinite)
        self.configuration = configuration
        setupTapGesture()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupTapGesture()
    }
    
    //MARK: - Setup Tap Gesture
    
    private func setupTapGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(touchButton))
        addGestureRecognizer(tapGesture)
    }
    
    //MARK: - Touch Button

    @objc private func touchButton() {
        guard let configuration = configuration,
              let topVC = UIApplication.topViewController()
        else { return }
        
        if let successRedirectUrl = buttonResult?.successRedirectUrl, configuration.successRedirectUrl == nil || configuration.successRedirectUrl == "" {
            configuration.successRedirectUrl = successRedirectUrl
        }
        
        if let failRedirectUrl = buttonResult?.failRedirectUrl, configuration.failRedirectUrl == nil || configuration.failRedirectUrl == "" {
            configuration.failRedirectUrl = failRedirectUrl
        }
        
        let vc = TpayAssembly.createTPayVC(configuration: configuration)
        vc.delegate = self
        topVC.present(vc, animated: true)
    }
}

//MARK: - Callbacks

extension PaymentTPayView {
    public enum PaymentAction {
        case success
        case error
        case close
    }
}

//MARK: - Progress TPay Protocol

extension PaymentTPayView: ProgressTPayProtocol {
    func resultPayment(result: PaymentAction, error: String?, transactionId: Int64?) {
        delegate?.resultPayment(self, result: result, error: error, transactionId: transactionId)
    }
}

//MARK: - Get Merchant Configuration

public extension PaymentTPayView {
    func getMerchantConfiguration(completion: @escaping (ButtonConfiguration?) -> Void) {
        CloudpaymentsApi.getMerchantConfiguration(configuration: configuration) { [weak self] result in
            
            if let isTest = result?.isTest {
                self?.configuration.paymentData.isTest = isTest
            }
            
            guard let self = self else { return }
            self.buttonResult = result
            completion(result)
        }
    }
}
