//
//  ProgressSberPayViewController.swift
//  sdk
//
//  Created by Cloudpayments on 20.05.2024.
//  Copyright © 2024 Cloudpayments. All rights reserved.
//

import UIKit

final class ProgressSberPayViewController: UIViewController {
    weak var delegate: ProgressSberPayProtocol?
    private let customView = ProgressSberPayView()
    private let presenter: ProgressSberPayPresenter
    private let defaultOpen: Bool
    
    //MARK: - Init
    
    init(presenter: ProgressSberPayPresenter, _ defaultOpen: Bool = false) {
        self.presenter = presenter
        self.defaultOpen = defaultOpen
        super.init(nibName: nil, bundle: .mainSdk)
        modalPresentationStyle = .overFullScreen
        modalTransitionStyle = .crossDissolve
        view.isOpaque = false
        view.backgroundColor = .clear
        view.backgroundColor = UIColor.black.withAlphaComponent(0.6)
    }
    
    public class func present(with configuration: PaymentConfiguration, from: UIViewController, defaultOpen: Bool = false) {
        let presenter = ProgressSberPayPresenter(configuration: configuration)
        let controller = ProgressSberPayViewController(presenter: presenter, defaultOpen)
        presenter.view = controller
        controller.modalPresentationStyle = .overFullScreen
        controller.modalTransitionStyle = .crossDissolve
        controller.view.isOpaque = false
        from.present(controller, animated: false)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //MARK: - LifeCycle
    
    override func loadView() {
        super.loadView()
        view = customView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        customView.delegate = self
        presenter.getSberPayLinkIntentApi()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        presenter.stopPolling()
    }
}

//MARK: - Progress SberPay ViewController

extension ProgressSberPayViewController: CustomSberPayViewDelegate {
    func closePaymentButton() {
        
        if defaultOpen {
            resultPayment(result: .close, error: nil, transaction: nil)
            return
        }
        
        dismiss(animated: true) {
            self.delegate?.resultPayment(result: .close, error: nil, transactionId: nil)
        }
    }
}

//MARK: Presenter Delegate

extension ProgressSberPayViewController: ProgressSberPayViewControllerProtocol {
    
    func showAlert(message: String?, title: String?) {
        showAlert(title: title, message: message)
    }
    
    func openLinkUrls(urls: [URL]) {
        let dispatchGroup = DispatchGroup()
        var successFound = false
        
        for url in urls {
            dispatchGroup.enter()
            UIApplication.shared.open(url, options: [:]) { success in
                if success {
                    successFound = true
                }
                dispatchGroup.leave()
            }
            if successFound {
                break
            }
        }
        
        dispatchGroup.notify(queue: .main) {
            if !successFound {
                self.showAlert(title: nil, message: .banksAppNotOpen)
            }
        }
    }
    
    func resultPayment(result: PaymentSberPayView.PaymentAction, error: String?, transaction: PaymentTransactionResponse?) {
        
        guard let parent = self.presentingViewController else { return }
        
        if let delegate = delegate {
            
            if presenter.configuration.showResultScreen {
                self.dismiss(animated: false) {
                    self.openResultScreens(result, error, transaction, parent)
                }
            }
            
            delegate.resultPayment(result: result, error: error, transactionId: transaction?.transactionId)
            return
        }
        
        self.dismiss(animated: false) {
            self.openResultScreens(result, error, transaction, parent)
        }
    }
    
    func openResultScreens(_ result: PaymentSberPayView.PaymentAction,  _ error: String?, _ transaction: PaymentTransactionResponse?, _ parent: UIViewController) {
        
        switch result {
        case .success:
            PaymentProcessForm.present(with: self.presenter.configuration, cryptogram: nil, email: nil, state: .completed(transaction), from: parent)
        case .error:
            PaymentProcessForm.present(with: self.presenter.configuration, cryptogram: nil, email: nil, state: .declined(error), from: parent)
        case .close:
            PaymentOptionsForm.present(with: self.presenter.configuration, from: parent)
        }
        
    }
}
