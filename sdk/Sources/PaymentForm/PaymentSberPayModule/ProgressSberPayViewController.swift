//
//  ProgressSberPayViewController.swift
//  sdk
//
//  Created by Cloudpayments on 20.05.2024.
//  Copyright © 2024 Cloudpayments. All rights reserved.
//

import UIKit

final class ProgressSberPayViewController: BaseViewController {
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
        presenter.getLink()
        
        LoggerService.shared.startLogging(publicId: presenter.configuration.publicId)
    }
}

//MARK: - Progress SberPay ViewController

extension ProgressSberPayViewController: CustomSberPayViewDelegate {
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

extension ProgressSberPayViewController: ProgressSberPayViewControllerProtocol {
    
    var isTest: Bool? {
        presenter.configuration.paymentData.isTest
    }
    
    func openLinkURL(url path: URL) {
        
        if isTest ?? false {
            UIApplication.shared.open(path, options: [:]) { success in
                if !success {
                    print("Failed to open test URL")
                    self.showAlert(title: nil, message: .banksAppNotOpen)
                }
            }
            return
        }
        
        let sberDeeplinks = [
            "ios-app-smartonline",
            "btripsexpenses",
            "sbolpay",
            "budgetonline-ios"
        ]
        
        let urlString = path.absoluteString
        guard let urlComponents = URLComponents(string: urlString) else {
            showAlert(title: nil, message: .banksAppNotOpen)
            return
        }
        
        var foundValidLink = false
        
        let dispatchGroup = DispatchGroup()
        
        for scheme in sberDeeplinks {
            var sberComponents = urlComponents
            sberComponents.scheme = scheme
            
            if scheme == "ios-app-smartonline" || scheme == "btripsexpenses" || scheme == "budgetonline-ios" {
                let originalHost = sberComponents.host ?? ""
                let originalPath = sberComponents.path
                sberComponents.host = "sbolpay"
                sberComponents.path = "/" + originalHost + originalPath
            }
            
            guard let generatedLink = sberComponents.url else { continue }
            
            dispatchGroup.enter()
            UIApplication.shared.open(generatedLink, options: [:]) { success in
                if success {
                    foundValidLink = true
                } else {
                    print("Failed to open URL: \(generatedLink.absoluteString)")
                }
                dispatchGroup.leave()
            }
            
            if foundValidLink {
                break
            }
        }
        
        if !foundValidLink {
            dispatchGroup.enter()
            UIApplication.shared.open(path, options: [:]) { success in
                if success {
                    foundValidLink = true
                } else {
                    print("Failed to open URL original URL")
                }
                dispatchGroup.leave()
            }
        }
        
        dispatchGroup.notify(queue: .main) {
            if !foundValidLink {
                self.showAlert(title: nil, message: .banksAppNotOpen)
            }
        }
    }
    
    func resultPayment(result: PaymentSberPayView.PaymentAction, error: String?, transactionId: Transaction?) {
        
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
    
    func openResultScreens(_ result: PaymentSberPayView.PaymentAction,  _ error: String?, _ transactionId: Transaction?, _ parent: UIViewController) {
        
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
