//
//  ProgressSberPayPresenter.swift
//  sdk
//
//  Created by Cloudpayments on 20.05.2024.
//  Copyright © 2024 Cloudpayments. All rights reserved.
//

import Foundation

protocol ProgressSberPayProtocol: AnyObject {
    func resultPayment(result: PaymentSberPayView.PaymentAction, error: String?, transactionId: Int64?)
}

protocol ProgressSberPayViewControllerProtocol: AnyObject {
    func resultPayment(result: PaymentSberPayView.PaymentAction, error: String?, transactionId: Transaction?)
    func openLinkURL(url: URL)
    var isTest: Bool? { get }
}

final class ProgressSberPayPresenter {
    
    //MARK: - Properties
    
    let configuration: PaymentConfiguration
    private var transactionId: Int64?
    weak var view: ProgressSberPayViewControllerProtocol?
    
    //MARK: - Init
    
    init(configuration: PaymentConfiguration) {
        self.configuration = configuration
    }
    
    //MARK: - Private Methods
    
    private func checkTransactionId() {
        let publicId = configuration.publicId
        guard let transactionId = transactionId else { return }
    
        NotificationCenter.default.removeObserver(self, name: ObserverKeys.generalObserver.key, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(observerStatus(_:)),
                                               name: ObserverKeys.generalObserver.key, object: nil)
        CloudpaymentsApi.getWaitStatus(configuration, transactionId, publicId)
    }

    fileprivate func statusCodeNotification(_ status: StatusPay, _ notification: NSNotification) {
        switch status {
        case .created, .pending:
            checkTransactionId()
            
        case .authorized, .completed, .cancelled:
            let transaction = Transaction(transactionId: transactionId)
            transactionId = nil
            NotificationCenter.default.removeObserver(self, name: ObserverKeys.generalObserver.key, object: nil)
            self.view?.resultPayment(result: .success, error: nil, transactionId: transaction)
            
        case .declined:
            transactionId = nil
            let error = notification.object as? Error
            let code = error?._code
            let string = code == nil ? "" : String(code!)
            let descriptionError = ApiError.getFullErrorDescription(code: string)
            view?.resultPayment(result: .error, error: descriptionError, transactionId: nil)
        }
    }
    
    @objc private func observerStatus(_ notification: NSNotification) {
        
        guard let transactionStatus = notification.object as? TransactionStatusResponse else {
            
            if let error = notification.object as? Error {
                let code = error._code < 0 ? -error._code : error._code
                if code > 1000 {checkTransactionId(); return }
                let string = String(code)
                let description = ApiError.getFullErrorDescription(code: string)
                view?.resultPayment(result: .error, error: description, transactionId: nil)
                return
            }
            
            checkTransactionId()
            return
            
        }
        
        guard let rawValue = transactionStatus.model?.status,
              let status = StatusPay(rawValue: rawValue)
        else {
            
            if let statusCode = transactionStatus.model?.statusCode, let statusPay = StatusPay(rawValue: statusCode) {
                statusCodeNotification(statusPay, notification)
                return
            }
            return
        }
        
        statusCodeNotification(status, notification)
    }
}

//MARK: Input

extension ProgressSberPayPresenter {
    func getLink() {
        CloudpaymentsApi.getSberPayLink(with: configuration) { [weak self] result in
            guard let self = self, let transactionId = result?.transactionId, let qrURL = result?.qrURL, let url = URL(string: qrURL) else {
                self?.view?.resultPayment(result: .error, error: result?.message, transactionId: nil)
                return
            }
            
            let message = result?.message
            self.transactionId = transactionId
            
            var status: StatusPay {
                guard let message = message, let value = StatusPay(rawValue: message) else { return .declined }
                return value
            }
            
            switch status {
            case .created, .pending:
                self.checkTransactionId()
            default:
                self.checkTransactionId()
            }
            
            self.view?.openLinkURL(url: url)
        }
    }
}
