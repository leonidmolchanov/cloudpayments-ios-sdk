//
//  NewSbpViewController.swift
//  Cloudpayments
//
//  Created by Cloudpayments on 02.05.2024.
//

import UIKit

protocol ProgressSbpPresenterProtocol: AnyObject {
    func resultPayment(_ result: PaymentSbpView.PaymentAction, error: String?, transactionId: Int64?)
}

final class ProgressSbpViewController: BaseViewController {
    
    //MARK: - Private Properties
    
    private let presenter: ProgressSbpPresenter
    weak var delegate: ProgressSbpPresenterProtocol?
    private var contentView: ProgressSbpView = ProgressSbpView()
    private let loaderView = LoaderView()
    private var closedConstraint: NSLayoutConstraint!
    private var tableViewHeightConstraint: NSLayoutConstraint!
    
    private lazy var currentContainerHeight: CGFloat = contentView.bounds.height
    private var isCloused = false
    private var heightPresentView: CGFloat { return contentView.bounds.height }
    
    private lazy var tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapAction))
    
    override var isKeyboardShowing: Bool {
        didSet {
            tapGestureRecognizer.cancelsTouchesInView = isKeyboardShowing
        }
    }
    
    var loading: Bool = false {
        didSet {
            loaderView.isHidden = !loading
        }
    }
    
    //MARK: - Init
    
    init(presenter: ProgressSbpPresenter) {
        self.presenter = presenter
        super.init(nibName: nil, bundle: .mainSdk)
        modalPresentationStyle = .overFullScreen
        modalTransitionStyle = .crossDissolve
        view.isOpaque = false
        view.backgroundColor = .clear
        view.backgroundColor = UIColor.black.withAlphaComponent(0.6)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //MARK: - Present flow on standart form
    
    public class func present(with configuration: PaymentConfiguration, from: UIViewController) {
        let presenter = ProgressSbpPresenter(configuration: configuration)
        let controller = ProgressSbpViewController(presenter: presenter)
        presenter.view = controller
        controller.modalPresentationStyle = .overFullScreen
        controller.modalTransitionStyle = .crossDissolve
        controller.view.isOpaque = false
        from.present(controller, animated: false)
    }
    
    //MARK: - LifeCycle
    
    override func loadView() {
        super.loadView()
        setupConstraintsAndView()
        
        view.addSubview(loaderView)
        loaderView.frame = view.bounds
        loaderView.fullConstraint()
        loaderView.layoutSubviews()
        
        loaderView.startAnimated(LoaderType.loadingBanks.toString())
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        contentView.delegate = self
        view.backgroundColor = .init(red: 1, green: 1, blue: 1, alpha: 0.0)
        presenter.viewDidLoad()
        addGesture()
        
        view.addGestureRecognizer(tapGestureRecognizer)
        tapGestureRecognizer.cancelsTouchesInView = false
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        presentesionView(true) {}
        
        LoggerService.shared.startLogging(publicId: presenter.configuration.publicId)
    }
    
    //MARK: - Private methods
    
    private func setupConstraintsAndView() {
        
        view.addSubviews(contentView)
        
        NSLayoutConstraint.activate([
            //contentView
            contentView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
        
        closedConstraint = contentView.topAnchor.constraint(equalTo: view.bottomAnchor, constant: 0)
        closedConstraint.isActive = true
        
        let contentBottomConstraint = contentView.bottomAnchor.constraint(greaterThanOrEqualTo: view.bottomAnchor)
        contentBottomConstraint.priority = .init(900)
        contentBottomConstraint.isActive = true
    }
    
    @objc private func tapAction() {
        view.endEditing(true)
    }
    
    private func addGesture() {
        let panGesture = UIPanGestureRecognizer()
        panGesture.delaysTouchesBegan = false
        panGesture.delaysTouchesEnded = false
        panGesture.addTarget(self, action: #selector(handlePanGesture(_:)))
        contentView.addGestureRecognizer(panGesture)
    }
    
    // MARK: Pan gesture handler
    
    @objc func handlePanGesture(_ gesture: UIPanGestureRecognizer) {
        
        let y = gesture.translation(in: view).y
        let newHeight = currentContainerHeight - y
        
        let procent = 30.0
        let defaultHeight = heightPresentView - ((heightPresentView * procent) / 100)
        
        switch gesture.state {
        case .changed:
            if heightPresentView < newHeight {
                closedConstraint.constant = -heightPresentView
                currentContainerHeight = heightPresentView
                view.layoutIfNeeded()
                return
            }
            
            self.closedConstraint.constant = -newHeight
            self.view.layoutIfNeeded()
            
        case .ended, .cancelled:
            
            if newHeight < defaultHeight {
                currentContainerHeight = newHeight
                presentesionView(false) {
                    
                    if let delegate = self.delegate {
                        guard let _ = self.presentingViewController else {return}
                        self.dismiss(animated: false) {
                            delegate.resultPayment(.close, error: nil, transactionId: nil)
                        }
                        return
                    }
                    
                    guard let parent = self.presentingViewController else {return}
                    self.dismiss(animated: false)
                    PaymentForm.present(with: self.presenter.configuration, from: parent)
                }
            } else {
                closedConstraint.constant = -heightPresentView
                currentContainerHeight = heightPresentView
                UIView.animate(withDuration: 0.35, delay: 0, options: .curveEaseInOut) {
                    self.view.layoutIfNeeded()
                }
            }
            
        default:
            break
        }
    }
    
    private func presentesionView(_ isPresent: Bool, completion: @escaping () -> Void) {
        
        if isCloused { return }
        isCloused = !isPresent
        let alpha = isPresent ? 0.6 : 0
        self.currentContainerHeight = heightPresentView
        
        UIView.animate(withDuration: 0.35, delay: 0, options: .curveEaseInOut) {
            self.closedConstraint.constant = isPresent ?  -self.heightPresentView :  0
            self.view.backgroundColor = .init(red: 1, green: 1, blue: 1, alpha: alpha)
            self.view.layoutIfNeeded()
        } completion: { _ in
            completion()
        }
    }
    
}

//MARK: - CustomSbpViewDelegate

extension ProgressSbpViewController: CustomSbpViewDelegate {
    
    func numberOfRow(_ progressSbpView: ProgressSbpView, didChange text: String) {
        let trimmedSearchText = text.trimmingCharacters(in: .whitespaces)
        presenter.editingSearchBar(trimmedSearchText)
    }
    
    func searchBarCancelButtonClicked(_ progressSbpView: ProgressSbpView) {
        presenter.editingSearchBar("")
    }
    
    func numberOfRow(_ progressSbpView: ProgressSbpView) -> Int {
        return presenter.filteredBanks.count
    }
    
    func progressSbpView(_ progressSbpView: ProgressSbpView, didSelect row: Int) {
        presenter.removePayObserver()
        presenter.didSelectRow(row)
    }
    
    func progressSbpView(_ progressSbpView: ProgressSbpView, cellFor row: Int) -> SbpData {
        return presenter.filteredBanks[row]
    }
}

//MARK: - ProgressSbpViewControllerProtocol

extension ProgressSbpViewController: ProgressSbpViewControllerProtocol {
    
    func showAlert(message: String?, title: String?) {
        showAlert(title: title, message: message)
    }
    
    func presentError(_ error: String? = nil) {
        
        guard let parent = self.presentingViewController else { return }
        
        if let safariViewController = UIApplication.topViewController() as? SafariViewController {
            safariViewController.dismiss(animated: false)
        }
        
        if let delegate = delegate {
            
            if presenter.configuration.showResultScreen {
                self.dismiss(animated: false) {
                    PaymentProcessForm.present(with: self.presenter.configuration, cryptogram: nil, email: nil, state: .failed(nil), from: parent)
                }
            }
            
            delegate.resultPayment(.error, error: error, transactionId: nil)
            
            return
        }
        
        presentesionView(false) {
            self.dismiss(animated: false) {
                PaymentProcessForm.present(with: self.presenter.configuration, cryptogram: nil, email: nil, state: .failed(nil),from: parent)
            }
        }
    }
    
    func openSafariViewController(_ url: URL) {
        
        let safariViewController = SafariViewController(url: url)
        
        if let viewController = UIApplication.topViewController() {
            viewController.present(safariViewController, animated: true)
        }
        
    }
    
    func openBanksApp(_ url: URL) {
        
        UIApplication.shared.open(url) { success in
            if success {
                self.presenter.checkTransactionId()
            } else {
                self.showAlert(title: nil, message: .noBankApps)
            }
        }
        
    }
    
    func resultPayment(result: PaymentSbpView.PaymentAction, error: String?, transactionId: Transaction?) {
        
        guard let parent = self.presentingViewController else { return }
        
        if let safariViewController = UIApplication.topViewController() as? SafariViewController {
            safariViewController.dismiss(animated: false)
        }
        
        if let delegate = delegate {
            
            if presenter.configuration.showResultScreen {
                self.dismiss(animated: false) {
                    self.openResultScreens(result, error, transactionId, parent)
                }
            }
            
            delegate.resultPayment(result, error: error, transactionId: transactionId?.transactionId)
            return
        }
        
        presentesionView(false) {
            self.dismiss(animated: false) {
                self.openResultScreens(result, error, transactionId, parent)
            }
        }
    }
    
    func openResultScreens(_ result: PaymentSbpView.PaymentAction,  _ error: String?,  _ transactionId: Transaction?, _ parent: UIViewController) {
        
        switch result {
        case .success:
            guard let transactionId = transactionId else { return }
            PaymentProcessForm.present(with: self.presenter.configuration, cryptogram: nil, email: nil, state: .succeeded(transactionId),from: parent)
        case .error:
            PaymentProcessForm.present(with: self.presenter.configuration, cryptogram: nil, email: nil, state: .failed(nil),from: parent)
        case .close:
            PaymentOptionsForm.present(with: self.presenter.configuration, from: parent)
        }
        
    }
    
    func tableViewReloadData() {
        contentView.reloadData()
    }
}
