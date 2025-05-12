//
//  ProgressSbpPresenter.swift
//  sdk
//
//  Created by Cloudpayments on 02.05.2024.
//  Copyright © 2024 Cloudpayments. All rights reserved.
//

import Foundation

protocol ProgressSbpViewControllerProtocol: AnyObject {
    func resultPayment(result: PaymentSbpView.PaymentAction, error: String?, transaction: PaymentTransactionResponse?)
    func tableViewReloadData()
    func openBanksApp(_ url: URL)
    func openSafariViewController(_ url: URL)
    func presentError(_ error: String?)
    func showAlert(message: String?, title: String?)
}

final class ProgressSbpPresenter {
    
    //MARK: - Properties
    
    private(set) var configuration: PaymentConfiguration
    private let sbpPollingService: PaymentPollingService
    private(set) var filteredBanks: [Bank] = []
    private var currentPuid: String?
    weak var view: ProgressSbpViewControllerProtocol?
    
    //MARK: - Init
    
    init(configuration: PaymentConfiguration, sbpPollingService: PaymentPollingService = PaymentPollingServiceImpl()) {
        self.configuration = configuration
        self.sbpPollingService = sbpPollingService
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(intentSbpObserverStatus(_:)),
            name: ObserverKeys.intentSbpObserver.key,
            object: nil
        )
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: ObserverKeys.intentSbpObserver.key, object: nil)
        stopPolling()
    }
    
    // MARK: - Polling
    
    func stopPolling() {
        sbpPollingService.stopPolling()
    }
    
    func startPolling() {
        stopPolling()
        
        sbpPollingService.startPolling(taskName: .sbpTransactionPolling, interval: 3) { [weak self] in
            guard let self = self else { return }
            self.pollStatus()
        }
    }
    
    //MARK: - Private Methods
    
    private func pollStatus() {
        CloudpaymentsApi.getIntentWaitStatus(configuration, type: .sbp) { [weak self] statusCode in
            guard let self = self else { return }
            if statusCode == 200 {
                print("pollStatus: 200 — продолжаем опрос")
            } else {
                self.stopPolling()
                self.view?.showAlert(message: nil, title: .errorWordTitle)
            }
            print("pollStatus вызван — отправка запроса на getIntentWaitStatus c type sbp")
        }
    }
    
    // MARK: - Intent Status Handling
    
    @objc private func intentSbpObserverStatus(_ notification: NSNotification) {
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
    
    func getBanks() {
        
        guard let banks = configuration.paymentData.sbpBanks, !banks.isEmpty else {
            view?.showAlert(message: .banksNotLoaded, title: .errorWord)
            return
        }
        
        print("Банки загружены: \(banks.count)")
        
        filteredBanks = banks
        view?.tableViewReloadData()
    }
        
    private func generateLink(with value: Bank) {
        let puid = UUID().uuidString
        currentPuid = puid
        
        enum WebClientFlag {
            static let active = "true"
        }
        
        let isWebClient = value.isWebClientActive == WebClientFlag.active
        
        guard let schemeToUse = isWebClient ? value.webClientUrl : value.schema else {
            view?.showAlert(message: nil, title: .schemeMissing)
            return
        }
        
        CloudpaymentsApi.getSbpLinkIntentApi(puid: puid, schema: schemeToUse, configuration: configuration) { [weak self] statusCode, intentSbpLink in
            guard let self = self else { return }
            switch statusCode {
            case 200:
                guard let sbpLink = intentSbpLink else {
                    self.view?.showAlert(message: nil, title: .anotherPaymentMethod)
                    return
                }
                if isWebClient {
                    print("Открытие web-клиента: \(sbpLink)")
                    self.openSafariViewController(sbpLink)
                } else {
                    print("Открытие приложения по схеме: \(sbpLink)")
                    self.openBanksApp(sbpLink)
                }
            case 409:
                self.view?.resultPayment(result: .error, error: .orderAlreadyBeenPaid, transaction: nil)
            default:
                self.view?.showAlert(message: nil, title: .banksAppNotOpen)
            }
        }
    }
    
    private func openBanksApp(_ url: String) {
        guard let finalURL = URL(string: url) else {
            view?.showAlert(message: nil, title: .banksAppNotOpen)
            return
        }
        view?.openBanksApp(finalURL)
    }
    
    private func openSafariViewController(_ string: String) {
        guard let finalURL = URL(string: string) else {
            view?.showAlert(message: nil, title: .banksAppNotOpen)
            return
        }
        view?.openSafariViewController(finalURL)
        startPolling()
    }
}

//MARK: Input

extension ProgressSbpPresenter {
    
    func viewDidLoad() {
        getBanks()
    }
    
    func didSelectRow(_ row: Int) {
        let value = filteredBanks[row]
        generateLink(with: value)
    }
    
    func editingSearchBar(_ text: String) {
        guard let sbpBanks = configuration.paymentData.sbpBanks else {
            filteredBanks = []
            view?.tableViewReloadData()
            return
        }
        
        if text.isEmpty {
            filteredBanks = sbpBanks
        } else {
            filteredBanks = sbpBanks.filter { bank in
                guard let name = bank.bankName else { return false }
                return name.lowercased().contains(text.lowercased())
            }
        }
        
        view?.tableViewReloadData()
    }
}
