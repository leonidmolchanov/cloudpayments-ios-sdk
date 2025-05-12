//
//  ProgressTPayPresenter.swift
//  sdk
//
//  Created by Cloudpayments on 15.11.2023.
//  Copyright © 2023 Cloudpayments. All rights reserved.
//

import Foundation

protocol ProgressTPayProtocol: AnyObject {
    func resultPayment(result: PaymentTPayView.PaymentAction, error: String?, transactionId: Int64?)
}

protocol ProgressTPayViewControllerProtocol: AnyObject {
    func resultPayment(result: PaymentTPayView.PaymentAction, error: String?, transaction: PaymentTransactionResponse?)
    func openLinkURL(url: URL)
    func showAlert(message: String?, title: String?)
}

final class ProgressTPayPresenter {
    
    // MARK: - Properties
    
    let configuration: PaymentConfiguration
    private let tpayPollingService: PaymentPollingService
    private var currentPuid: String?
    weak var view: ProgressTPayViewControllerProtocol?
    
    // MARK: - Init
    
    init(configuration: PaymentConfiguration, tpayPollingService: PaymentPollingService = PaymentPollingServiceImpl()) {
        self.configuration = configuration
        self.tpayPollingService = tpayPollingService
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(intentTPayObserverStatus(_:)),
            name: ObserverKeys.intentTpayObserver.key,
            object: nil
        )
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        stopPolling()
    }
    
    // MARK: - Polling
    
    func stopPolling() {
        tpayPollingService.stopPolling()
    }
    
    private func pollStatus() {
        CloudpaymentsApi.getIntentWaitStatus(configuration, type: .tpay) { [weak self] statusCode in
            guard let self = self else { return }
            if statusCode == 200 {
                print("pollStatus: 200 — продолжаем опрос")
            } else {
                self.stopPolling()
                self.view?.showAlert(message: nil, title: .errorWordTitle)
            }
            print("pollStatus вызван — отправка запроса на getIntentWaitStatus c type tpay")
        }
    }
    
    private func startPolling() {
        stopPolling()
        
        tpayPollingService.startPolling(taskName: .tPayTransactionPolling, interval: 3) { [weak self] in
            guard let self = self else { return }
            self.pollStatus()
        }
    }
    
    // MARK: - Intent Status Handling
    
    @objc private func intentTPayObserverStatus(_ notification: NSNotification) {
        guard let statusModel = notification.object as? PaymentTransactionStatusModel else {
            return
        }

        guard let intentStatusRaw = statusModel.status,
              let intentStatus = IntentWaitStatus(rawValue: intentStatusRaw) else {
            print("Статус интента невалиден")
            return
        }

        print("Статус интента при опросе транзакции: \(intentStatus.rawValue)")

        guard let puid = currentPuid,
              let transactions = statusModel.transactions else {
            print("Нет транзакций или puid")
            return
        }

        let matchedTransactions = transactions.filter { $0.puid == puid }

        if matchedTransactions.isEmpty {
            print("Транзакции с текущим puid не найдены")
            return
        }

        for transaction in matchedTransactions {
            guard let transactionStatusRaw = transaction.status,
                  let intentTransactionStatus = IntentTransactionStatus(rawValue: transactionStatusRaw) else {
                print("Транзакция без статуса или с невалидным статусом")
                continue
            }

            print("Обработка транзакции — статус: \(intentTransactionStatus.rawValue)")
            handleIntentTransactionFinalStatus(intentTransactionStatus, transaction: transaction)
        }

        if intentStatus == .succeeded {
            stopPolling()
        }
    }
    
    // MARK: - Transaction Status Handling
    
    private func handleIntentTransactionFinalStatus(_ status: IntentTransactionStatus, transaction: PaymentTransactionResponse) {
        stopPolling()
        
        let transactionId = transaction.transactionId
        let transactionErrorCode = transaction.code
        
        switch status {
        case .authorized, .completed:
            print("Оплата успешна — \(status.rawValue)")
            print("Номер транзакции \(String(describing: transactionId))")
            let paymentIntentTransaction = PaymentTransactionResponse(
                transactionId: transactionId,
                paymentMethod: nil,
                puid: currentPuid,
                status: status.rawValue,
                code: nil
            )
            view?.resultPayment(result: .success, error: nil, transaction: paymentIntentTransaction)
            
        case .declined, .cancelled:
            print("Оплата отклонена — code: \(String(describing: transactionErrorCode))")
            print("Номер транзакции \(String(describing: transactionId))")
            let errorMessage = ApiError.getFullErrorDescriptionIntentApi(from: transactionErrorCode)
            let paymentIntentTransaction = PaymentTransactionResponse(
                transactionId: transactionId,
                paymentMethod: nil,
                puid: currentPuid,
                status: status.rawValue,
                code: transactionErrorCode
            )
            view?.resultPayment(result: .error, error: errorMessage, transaction: paymentIntentTransaction)
        }
    }
}

//MARK: Input

extension ProgressTPayPresenter {
    func getTPayLinkIntentApi() {
        let puid = UUID().uuidString
        currentPuid = puid

        CloudpaymentsApi.getTPayLinkIntentApi(puid: puid, configuration: configuration) { [weak self] statusCode, tPayLink in
            guard let self = self else { return }

            switch statusCode {
            case 200:
                if let link = tPayLink, let url = URL(string: link) {
                    self.view?.openLinkURL(url: url)
                    self.startPolling()
                } else {
                    self.view?.showAlert(message: nil, title: .banksAppNotOpen)
                }
            case 409:
                self.view?.resultPayment(result: .error, error: .orderAlreadyBeenPaid, transaction: nil)
            default:
                self.view?.showAlert(message: nil, title: .errorWordTitle)
            }
        }
    }
}
