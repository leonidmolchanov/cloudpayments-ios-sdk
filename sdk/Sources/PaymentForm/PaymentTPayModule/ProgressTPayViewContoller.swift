//
//  ProgressTPayViewController.swift
//  sdk
//
//  Created by Cloudpayments on 15.11.2023.
//  Copyright © 2023 Cloudpayments. All rights reserved.
//

import UIKit

final class ProgressTPayViewController: BaseViewController {
    
    weak var delegate: ProgressTPayProtocol?
    private let customView = ProgressTPayView()
    private let presenter: ProgressTPayPresenter
    private let defaultOpen: Bool
    
    //MARK: - Init
    
    init(presenter: ProgressTPayPresenter, _ defaultOpen: Bool = false) {
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
        let presenter = ProgressTPayPresenter(configuration: configuration)
        let controller = ProgressTPayViewController(presenter: presenter, defaultOpen)
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
        presenter.getLink()
        
        LoggerService.shared.startLogging(publicId: presenter.configuration.publicId)
    }
}

//MARK: - Progress TPay View Controller

extension ProgressTPayViewController: CustomTPayViewDelegate {
    
    func closePaymentButton() {
        
        if defaultOpen {
            resultPayment(result: .close, error: nil, transactionId: nil)
            return
        }
        
        dismiss(animated: true) {
            self.delegate?.resultPayment(result: .close, error: nil, transactionId: nil)
        }
    }
}

//MARK: Presenter Delegate

extension ProgressTPayViewController: ProgressTPayViewControllerProtocol {
    
    func openLinkURL(url: URL) {
        UIApplication.shared.open(url) { success in
            if !success {
                self.showAlert(title: nil, message: .banksAppNotOpen)
            }
        }
    }
    
    func resultPayment(result: PaymentTPayView.PaymentAction, error: String?, transactionId: Transaction?) {
        
        guard let parent = self.presentingViewController else { return }
        
        if let delegate = delegate {
            
            if presenter.configuration.showResultScreen {
                self.dismiss(animated: false) {
                    self.openResultScreens(result, error, transactionId, parent)
                }
            }
            
            delegate.resultPayment(result: result, error: error, transactionId: transactionId?.transactionId)
            return
        }
        
        self.dismiss(animated: false) {
            self.openResultScreens(result, error, transactionId, parent)
        }
    }
    
    func openResultScreens(_ result: PaymentTPayView.PaymentAction,  _ error: String?, _ transactionId: Transaction?, _ parent: UIViewController) {
        
        switch result {
        case .success:
            PaymentProcessForm.present(with: self.presenter.configuration, cryptogram: nil, email: nil, state: .succeeded(transactionId), from: parent)
        case .error:
            PaymentProcessForm.present(with: self.presenter.configuration, cryptogram: nil, email: nil, state: .failed(error), from: parent)
        case .close:
            PaymentOptionsForm.present(with: self.presenter.configuration, from: parent)
        }
        
    }
}
