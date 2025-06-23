//
//  BasePaymentForm.swift
//  sdk
//
//  Created by Sergey Iskhakov on 16.09.2020.
//  Copyright © 2020 Cloudpayments. All rights reserved.
//

import UIKit
import AVFoundation

public final class PaymentCardForm: PaymentForm {
    
    // MARK: - Private properties
    
    @IBOutlet private weak var cardNumberTextField: TextField!
    @IBOutlet private weak var cardExpDateTextField: TextField!
    @IBOutlet private weak var cardCvvTextField: TextField!
    @IBOutlet private weak var containerCardBottomConstraint: NSLayoutConstraint!
    @IBOutlet private weak var mainCardStackView: UIStackView!
    @IBOutlet private weak var iconCvvCard: UIImageView!
    @IBOutlet private weak var containerHeightConstraint: NSLayoutConstraint!
    @IBOutlet private weak var scanButton: Button!
    @IBOutlet private weak var payButton: Button!
    @IBOutlet private weak var cardTypeIcon: UIImageView!
    @IBOutlet private weak var cardLabel: UILabel!
    @IBOutlet private weak var cardView: View!
    @IBOutlet private weak var expDateView: View!
    @IBOutlet private weak var cvvView: View!
    @IBOutlet private weak var cardPlaceholder: UILabel!
    @IBOutlet private weak var expDatePlaceholder: UILabel!
    @IBOutlet private weak var cvvPlaceholder: UILabel!
    @IBOutlet private weak var stackInpitMainStackView: UIStackView!
    @IBOutlet private weak var eyeOpenButton: Button!
    @IBOutlet private weak var paymentCardLabel: UILabel!
    
    lazy var defaultHeight: CGFloat = self.mainCardStackView.frame.height
    let dismissibleHigh: CGFloat = 400
    let maximumContainerHeight: CGFloat = UIScreen.main.bounds.height - 64
    lazy var currentContainerHeight: CGFloat = mainCardStackView.frame.height
    
    var onPayClicked: ((_ cryptogram: String, _ email: String?) -> ())?
    var cardNumberTimer: Timer?
    
    @discardableResult
    public class func present(with configuration: PaymentConfiguration, from: UIViewController, completion: (() -> ())?) -> PaymentForm? {
        let storyboard = UIStoryboard.init(name: "PaymentForm", bundle: Bundle.mainSdk)
        
        guard let controller = storyboard.instantiateViewController(withIdentifier: "PaymentForm") as? PaymentForm else {
            return nil
        }
        
        controller.configuration = configuration
        controller.show(inViewController: from, completion: completion)
        
        return controller
    }
    
    func updatePayButtonState() {
        let isValid = isValid()
        setButtonsAndContainersEnabled(isEnabled: isValid)
    }
    
    private func setButtonsAndContainersEnabled(isEnabled: Bool) {
        self.payButton.isUserInteractionEnabled = isEnabled
        self.payButton.setAlpha(isEnabled ? 1.0 : 0.3)
    }
    
    @objc private func secureButtonTapped(_ sender: UIButton) {
        cardCvvTextField.becomeFirstResponder()
        let isSelected = sender.isSelected
        sender.isSelected = !isSelected
        cardCvvTextField.isSecureTextEntry = !isSelected
        
        let image = isSelected ? EyeStatus.open.image : EyeStatus.closed.image
        eyeOpenButton.setImage(image, for: .normal)
    }
    
    private func showCvv() {
        guard let isCvvRequired = configuration.paymentData.isCvvRequired else { return }
        
        if isCvvRequired {
            cvvView.isHidden = false
        } else {
            cvvView.isHidden = true
        }
    }
    
    @IBAction func dismissButtonTapped(_ sender: UIButton) {
        self.configuration.paymentUIDelegate.paymentFormWillHide()
        self.dismiss(animated: true) { [weak self] in
            self?.configuration.paymentUIDelegate.paymentFormDidHide()
        }
    }
    
    @objc private func scanButtonTapped() {
        print("🔍 scanButtonTapped: Метод вызван")
        
        guard let scanner = configuration.scanner else { 
            print("❌ scanButtonTapped: configuration.scanner равен nil")
            return 
        }
        
        print("✅ scanButtonTapped: Scanner найден, пытаемся запустить")
        print("🔍 scanButtonTapped: Scanner type: \(type(of: scanner))")
        
        // Проверим доступность камеры
        print("🔍 scanButtonTapped: Проверяем доступность камеры...")
        
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            print("✅ scanButtonTapped: Камера доступна")
        } else {
            print("❌ scanButtonTapped: Камера НЕ доступна (возможно симулятор?)")
        }
        
        // Проверим разрешения
        let authStatus = AVCaptureDevice.authorizationStatus(for: .video)
        print("🔍 scanButtonTapped: Camera authorization status: \(authStatus.rawValue)")
        
        switch authStatus {
        case .authorized:
            print("✅ scanButtonTapped: Разрешение на камеру ЕСТЬ")
        case .denied, .restricted:
            print("❌ scanButtonTapped: Разрешение на камеру ОТКЛОНЕНО")
        case .notDetermined:
            print("⚠️ scanButtonTapped: Разрешение на камеру НЕ ЗАПРОШЕНО")
        @unknown default:
            print("❓ scanButtonTapped: Неизвестный статус разрешения")
        }
        
        // Пытаемся запустить сканер
        startScanner()
    }
    
    func setupEyeButton() {
        eyeOpenButton.addTarget(self, action: #selector(secureButtonTapped), for: .touchUpInside)
        eyeOpenButton.setImage(UIImage(named: EyeStatus.closed.toString()), for: .normal)
        eyeOpenButton.tintColor = .clear
        eyeOpenButton.isSelected = true
        cardCvvTextField.isSecureTextEntry = true
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        setupEyeButton()
        setupPanGesture()
        containerHeightConstraint.constant = mainCardStackView.frame.height
        showCvv()
        cardNumberTextField.delegate = self
        
        let paymentData = self.configuration.paymentData
        
        self.payButton.setTitle("Оплатить \(paymentData.amount) \(Currency.getCurrencySign(code: paymentData.currency))", for: .normal)
        
        self.payButton.onAction = { [weak self] in
            guard let self = self else {
                return
            }
            
            guard let pem = paymentData.pem else {
                print("Ошибка: Public key (Pem) не найден.")
                return
            }
            
            guard let version = paymentData.version else {
                print("Ошибка: Key version не найден.")
                return
            }
            
            guard self.isValid(), let cryptogram = Card.makeCardCryptogramPacket(cardNumber: self.cardNumberTextField.text!, expDate: self.cardExpDateTextField.cardExpText!, cvv: self.cardCvvTextField.text!, merchantPublicID: self.configuration.publicId, publicKey: pem, keyVersion: version)
            else {
                self.showAlert(title: .errorWord, message: String.errorCreatingCryptoPacket)
                return
            }
            
            DispatchQueue.main.async {
                self.dismiss(animated: true) { [weak self] in
                    guard let self = self else {
                        return
                    }
                    self.onPayClicked?(cryptogram, paymentData.email)
                }
            }
        }
        
        if configuration.scanner == nil {
            print("🔍 viewDidLoad: Scanner равен nil, скрываем кнопку")
            scanButton.isHidden = true
        } else {
            print("🔍 viewDidLoad: Scanner найден, настраиваем кнопку")
            guard let scanButton = self.scanButton else {
                print("❌ viewDidLoad: scanButton равен nil")
                return
            }
            print("✅ viewDidLoad: scanButton найден, добавляем target")
            scanButton.addTarget(self, action: #selector(scanButtonTapped), for: .touchUpInside)
            print("✅ viewDidLoad: Target добавлен для scanButton")
            
            // Также попробуем добавить еще одно действие для отладки
            scanButton.addTarget(self, action: #selector(debugButtonTapped), for: .touchUpInside)
            
            // Проверяем состояние кнопки
            print("🔍 viewDidLoad: scanButton.isHidden = \(scanButton.isHidden)")
            print("🔍 viewDidLoad: scanButton.isUserInteractionEnabled = \(scanButton.isUserInteractionEnabled)")
            print("🔍 viewDidLoad: scanButton.alpha = \(scanButton.alpha)")
            print("🔍 viewDidLoad: scanButton.frame = \(scanButton.frame)")
            
            // Проверяем targets
            print("🔍 viewDidLoad: scanButton targets = \(scanButton.allTargets)")
            print("🔍 viewDidLoad: scanButton actions = \(scanButton.actions(forTarget: self, forControlEvent: .touchUpInside) ?? [])")
        }
        configureTextFields()
        hideKeyboardWhenTappedAround()
        setButtonsAndContainersEnabled(isEnabled: false)
        paymentCardLabel.textColor = .mainText
        
        cardNumberTextField.textColor = .mainText
        cardExpDateTextField.textColor = .mainText
        cardCvvTextField.textColor = .mainText
        
        cardLabel.textColor = .colorProgressText
        expDatePlaceholder.textColor = .colorProgressText
        cvvPlaceholder.textColor = .colorProgressText
    }
    
    func setupPanGesture() {
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(self.handlePanGesture(gesture:)))
        panGesture.delaysTouchesBegan = false
        panGesture.delaysTouchesEnded = false
        view.addGestureRecognizer(panGesture)
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        animatePresentContainer()
        containerHeightConstraint.constant = defaultHeight
        
        // Проверяем состояние кнопки сканера после появления view
        print("🔍 viewDidAppear: Проверяем состояние scanButton")
        print("🔍 viewDidAppear: scanButton.isHidden = \(scanButton.isHidden)")
        print("🔍 viewDidAppear: scanButton.isUserInteractionEnabled = \(scanButton.isUserInteractionEnabled)")
        print("🔍 viewDidAppear: configuration.scanner = \(configuration.scanner != nil ? "не nil" : "nil")")
    }
    
    // MARK: Pan gesture handler
    
    @objc func handlePanGesture(gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: view)
        
        let isDraggingDown = translation.y > 0
        
        let newHeight = currentContainerHeight - translation.y
        
        switch gesture.state {
        case .changed:
            if newHeight < maximumContainerHeight {
                containerHeightConstraint?.constant = newHeight
                view.layoutIfNeeded()
            }
            
            if newHeight > defaultHeight && !isDraggingDown  {
                UIView.animate(withDuration: 0.9) {
                    self.containerHeightConstraint?.constant = self.defaultHeight
                }
            }
        case .ended:
            if newHeight < dismissibleHigh {
                self.animateDismissView()
                let parent = self.presentingViewController
                // Это переход назад к PaymentOptionsForm, а НЕ закрытие всей формы
                self.dismiss(animated: true) {
                    if let parent = parent {
                        if !self.configuration.disableApplePay {
                            PaymentForm.present(with: self.configuration, from: parent)
                        } else {
                            PaymentForm.present(with: self.configuration, from: parent)
                        }
                    }
                }
                
            }
            else if newHeight < defaultHeight {
                animateContainerHeight(defaultHeight)
            }
            else if newHeight < maximumContainerHeight && isDraggingDown {
                animateContainerHeight(defaultHeight)
            }
        default:
            break
        }
    }
    
    func animateContainerHeight(_ height: CGFloat) {
        UIView.animate(withDuration: 0.4) {
            self.containerCardBottomConstraint?.constant = height
            self.view.layoutIfNeeded()
        }
        currentContainerHeight = height
    }
    
    func animatePresentContainer() {
        UIView.animate(withDuration: 0.3) {
            self.containerCardBottomConstraint?.constant = 0
            self.view.layoutIfNeeded()
        }
    }
    
    func animateDismissView() {
        self.dismiss(animated: false)
        UIView.animate(withDuration: 0.3) {
            self.containerCardBottomConstraint?.constant = self.defaultHeight
            self.view.layoutIfNeeded()
        }
    }
    
    func setInputFieldValues(fieldType: InputFieldType, placeholderColor: UIColor, placeholderText: String, borderViewColor: UIColor, textFieldColor: UIColor? = .mainText ) {
        switch fieldType {
        case .card:
            self.cardPlaceholder.textColor = placeholderColor
            self.cardPlaceholder.text = placeholderText
            self.cardView.layer.borderColor = borderViewColor.cgColor
            self.cardNumberTextField.textColor = textFieldColor
        case .expDate:
            self.expDatePlaceholder.textColor = placeholderColor
            self.expDatePlaceholder.text = placeholderText
            self.expDateView.layer.borderColor = borderViewColor.cgColor
            self.cardExpDateTextField.textColor = textFieldColor
        case .cvv:
            self.cvvPlaceholder.textColor = placeholderColor
            self.cvvPlaceholder.text = placeholderText
            self.cvvView.layer.borderColor = borderViewColor.cgColor
            self.cardCvvTextField.textColor = textFieldColor
        }
    }
    
    private func configureTextFields() {
        [cardNumberTextField, cardExpDateTextField, cardCvvTextField].forEach { textField in
            textField?.addTarget(self, action: #selector(didChange(_:)), for: .editingChanged)
            textField?.addTarget(self, action: #selector(didBeginEditing(_:)), for: .editingDidBegin)
            textField?.addTarget(self, action: #selector(didEndEditing(_:)), for: .editingDidEnd)
            textField?.addTarget(self, action: #selector(shouldReturn(_:)), for: .editingDidEndOnExit)
        }
    }
    
    private func isValid() -> Bool {
        let cardNumberIsValid = Card.isCardNumberValid(self.cardNumberTextField.text?.formattedCardNumber())
        let cardExpIsValid = Card.isExpDateValid(self.cardExpDateTextField.cardExpText?.formattedCardExp())
        
        let cardCvvIsValid = Card.isValidCvv(cvv: self.cardCvvTextField.text?.formattedCardCVV(), isCvvRequired: !cvvView.isHidden)
        
        self.validateAndErrorCardNumber()
        self.validateAndErrorCardExp()
        self.validateAndErrorCardCVV()
        
        return cardNumberIsValid && cardExpIsValid && cardCvvIsValid
    }
    
    private func validateAndErrorCardNumber(){
        if let cardNumber = self.cardNumberTextField.text?.formattedCardNumber() {
            self.cardNumberTextField.isErrorMode = !Card.isCardNumberValid(cardNumber)
        }
    }
    
    private func validateAndErrorCardExp(){
        if let cardExp = self.cardExpDateTextField.cardExpText?.formattedCardExp() {
            let text = cardExp.replacingOccurrences(of: " ", with: "")
            self.cardExpDateTextField.isErrorMode = !Card.isExpDateValid(text)
        }
    }
    
    private func validateAndErrorCardCVV(){
        self.cardCvvTextField.isErrorMode = !Card.isValidCvv(cvv: self.cardCvvTextField.text, isCvvRequired: !cvvView.isHidden)
    }
    
    private func updatePaymentSystemIcon(cardNumber: String?){
        print("🔍 updatePaymentSystemIcon: вызван с cardNumber = \(cardNumber ?? "nil")")
        
        if let number = cardNumber {
            let cardType = Card.cardType(from: number)
            if cardType != .unknown {
                print("✅ updatePaymentSystemIcon: Тип карты определен, скрываем scanButton")
                self.cardTypeIcon.image = cardType.getIcon()
                self.cardTypeIcon.isHidden = false
                self.scanButton.isHidden = true
            } else {
                print("🔍 updatePaymentSystemIcon: Тип карты не определен")
                self.cardTypeIcon.isHidden = true
                self.scanButton.isHidden = self.configuration.scanner == nil
                print("🔍 updatePaymentSystemIcon: scanButton.isHidden = \(self.scanButton.isHidden)")
            }
        } else {
            print("🔍 updatePaymentSystemIcon: cardNumber равен nil")
            self.cardTypeIcon.isHidden = true
            self.scanButton.isHidden = self.configuration.scanner == nil
            print("🔍 updatePaymentSystemIcon: scanButton.isHidden = \(self.scanButton.isHidden)")
        }
    }
    
    @objc internal override func onKeyboardWillShow(_ notification: Notification) {
        super.onKeyboardWillShow(notification)
        
        self.containerCardBottomConstraint.constant = self.keyboardFrame.height
        
        self.view.setNeedsLayout()
        self.view.layoutIfNeeded()
    }
    
    @objc internal override func onKeyboardWillHide(_ notification: Notification) {
        super.onKeyboardWillHide(notification)
        
        self.containerCardBottomConstraint.constant = 0
        
        self.view.setNeedsLayout()
        self.view.layoutIfNeeded()
    }
    
    deinit {
        // Очищаем onAction closures для предотвращения retain cycles
        payButton?.onAction = nil
        
        // Удаляем target для scanButton
        scanButton?.removeTarget(self, action: #selector(scanButtonTapped), for: .touchUpInside)
        
        // Инвалидируем таймер
        cardNumberTimer?.invalidate()
        cardNumberTimer = nil
    }
    
    @objc private func debugButtonTapped() {
        print("🎯 debugButtonTapped: ОТЛАДКА - кнопка была нажата!")
        print("🎯 debugButtonTapped: Это означает, что target-action работает")
    }
    
    private func showScannerErrorAlert() {
        let authStatus = AVCaptureDevice.authorizationStatus(for: .video)
        
        if !UIImagePickerController.isSourceTypeAvailable(.camera) {
            // Камера недоступна
            showAlert(title: "Сканер карты", message: "Камера недоступна на этом устройстве. Введите данные карты вручную.")
            return
        }
        
        switch authStatus {
        case .notDetermined:
            // Разрешение не запрошено - показываем alert с возможностью запросить
            showPermissionRequestAlert()
        case .denied, .restricted:
            // Разрешение отклонено - показываем alert с инструкцией
            showAlert(title: "Сканер карты", message: "Для сканирования карты необходимо разрешение на использование камеры. Проверьте настройки приложения.")
        default:
            // Разрешение есть, но сканер все равно не работает
            showAlert(title: "Сканер карты", message: "Не удалось запустить сканер карты. Введите данные карты вручную.")
        }
    }
    
    private func showPermissionRequestAlert() {
        let alert = UIAlertController(
            title: "Сканер карты",
            message: "Необходимо запросить разрешение на использование камеры.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Разрешить", style: .default) { [weak self] _ in
            self?.requestCameraPermission()
        })
        
        alert.addAction(UIAlertAction(title: "Отмена", style: .cancel, handler: nil))
        
        present(alert, animated: true, completion: nil)
    }
    
    private func requestCameraPermission() {
        AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
            DispatchQueue.main.async {
                if granted {
                    print("✅ requestCameraPermission: Разрешение получено, пытаемся запустить сканер снова")
                    self?.startScanner()
                } else {
                    print("❌ requestCameraPermission: Разрешение отклонено")
                    self?.showAlert(title: "Сканер карты", message: "Без разрешения на камеру сканирование невозможно. Введите данные карты вручную.")
                }
            }
        }
    }
    
    private func startScanner() {
        guard let scanner = configuration.scanner else { 
            print("❌ startScanner: configuration.scanner равен nil")
            return 
        }
        
        if let controller = scanner.startScanner(completion: { [weak self] number, month, year, cvv in
            print("🎯 startScanner: Completion вызван")
            
            guard let self = self else { 
                print("❌ startScanner: self равен nil в completion")
                return 
            }
            
            self.cardNumberTextField.text = number?.formattedCardNumber()
            if let month = month, let year = year {
                let y = year % 100
                self.cardExpDateTextField.cardExpText = String(format: "%02d/%02d", month, y)
            }
            self.cardCvvTextField.text = cvv
            
            self.updatePaymentSystemIcon(cardNumber: number)
            print("✅ startScanner: Поля заполнены")
        }) {
            print("✅ startScanner: Controller получен, показываем")
            self.present(controller, animated: true, completion: nil)
        } else {
            print("❌ startScanner: scanner.startScanner вернул nil")
            print("❓ startScanner: Показываем alert с обработкой разрешений")
            
            // Показываем alert с обработкой разрешений
            DispatchQueue.main.async { [weak self] in
                self?.showScannerErrorAlert()
            }
        }
    }
}

//MARK: - Delegates for TextField

extension PaymentCardForm: UITextFieldDelegate {
    
    public func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if let currentText = textField.text, let range = Range(range, in: currentText) {
            let newCardNumber = currentText.replacingCharacters(in: range, with: string)
            let cleanCard = Card.cleanCreditCardNo(newCardNumber)
            
            if cleanCard.count < 6 {
                cvvView.isHidden = isHiddenCvv
                return true
            }
        }
        cardNumberTimer?.invalidate()
        cardNumberTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.sendRequest), userInfo: nil, repeats: false)
        
        return true
    }
    
    @objc private func sendRequest() {
        
        cardNumberTimer?.invalidate()
        
        if let cardNumber = cardNumberTextField.text, cardNumber.count >= 6 {
            let cleanCardNumber = Card.cleanCreditCardNo(cardNumber)
                        
            CloudpaymentsApi.getBinInfoWithIntentId(cleanCardNumber: cleanCardNumber, with: configuration) { [weak self] model, success in
                
                guard let self = self else { return }
                guard let success = success else { return }
                
                guard success else {
                    return
                }
                
                let hideCvvInput = model?.hideCvvInput ?? false
                self.cvvView.isHidden = hideCvvInput
                
                if let currency = model?.currency, let amount = model?.convertedAmount {
                    self.payButton.setTitle("Оплатить \(amount) \(Currency.getCurrencySign(code: currency))", for: .normal)
                }
            }
        }
    }
}

extension PaymentCardForm {
    
    private var isHiddenCvv: Bool {
        return !(configuration.paymentData.isCvvRequired ?? true)
    }
    
    /// Did Begin Editings
    /// - Parameter textField:
    @objc private func didBeginEditing(_ textField: UITextField) {
        
        switch textField {
            
        case cardNumberTextField:
            if let cardNumber = cardNumberTextField.text?.formattedCardNumber() {
                cardNumberTextField.text = cardNumber
                
                if !cardNumber.isEmpty || !Card.isCardNumberValid(cardNumber) {
                    setInputFieldValues(fieldType: .card, placeholderColor: ValidState.border.color, placeholderText: PlaceholderType.correctCard.toString(), borderViewColor: ValidState.normal.color, textFieldColor: ValidState.text.color)
                }
            }
            
        case cardExpDateTextField:
            if let cardExp = cardExpDateTextField.cardExpText?.formattedCardExp() {
                cardExpDateTextField.cardExpText = cardExp
                
                if !cardExp.isEmpty || !Card.isExpDateValid(cardExp) {
                    setInputFieldValues(fieldType: .expDate, placeholderColor: ValidState.border.color, placeholderText: PlaceholderType.correctExpDate.toString(), borderViewColor: ValidState.normal.color, textFieldColor: ValidState.text.color)
                }
            }
            
        case cardCvvTextField:
            if let text = cardCvvTextField.text?.formattedCardCVV() {
                cardCvvTextField.text = text
                
                if !cardCvvTextField.isEmpty || !Card.isValidCvv(cvv: text, isCvvRequired: !cvvView.isHidden) {
                    setInputFieldValues(fieldType: .cvv, placeholderColor: ValidState.border.color, placeholderText: PlaceholderType.correctCvv.toString(), borderViewColor: ValidState.normal.color, textFieldColor: ValidState.text.color)
                }
            }
        default: break
        }
    }
    
    /// Did Change
    /// - Parameter textField:
    @objc private func didChange(_ textField: UITextField) {
        
        switch textField {
            
        case cardNumberTextField:
            updatePayButtonState()
            
            if let cardNumber = cardNumberTextField.text?.formattedCardNumber() {
                cardNumberTextField.text = cardNumber
                
                updatePaymentSystemIcon(cardNumber: cardNumber)
                
                if cardNumber.isEmpty {
                    setInputFieldValues(fieldType: .card, placeholderColor: ValidState.border.color, placeholderText: PlaceholderType.correctCard.toString(), borderViewColor: ValidState.normal.color)
                    return
                }
                
                if Card.isCardNumberValid(cardNumber) {
                    setInputFieldValues(fieldType: .card, placeholderColor: ValidState.border.color, placeholderText: PlaceholderType.correctCard.toString(), borderViewColor: ValidState.normal.color)
                }
                
                let _ = cardNumber.clearCardNumber()
                
                //MAX CARD NUMBER LENGHT
                cardNumberTextField.isErrorMode = false
            }
            
        case cardExpDateTextField:
            updatePayButtonState()
            
            if let cardExp = cardExpDateTextField.cardExpText?.formattedCardExp() {
                cardExpDateTextField.cardExpText = cardExp
                cardExpDateTextField.isErrorMode = false
                
                if cardExp.isEmpty {
                    setInputFieldValues(fieldType: .expDate, placeholderColor: ValidState.border.color, placeholderText: PlaceholderType.correctExpDate.toString(), borderViewColor: ValidState.normal.color)
                    return
                }
                
                if Card.isExpDateValid(cardExp) {
                    setInputFieldValues(fieldType: .expDate, placeholderColor: ValidState.border.color, placeholderText: PlaceholderType.correctExpDate.toString(), borderViewColor: ValidState.normal.color)
                }
            }
            
        case cardCvvTextField:
            updatePayButtonState()
            
            if let text = cardCvvTextField.text?.formattedCardCVV() {
                cardCvvTextField.text = text
                
                iconCvvCard.isHidden = !cardCvvTextField.isEmpty
                eyeOpenButton.isHidden = cardCvvTextField.isEmpty
                cardCvvTextField.isErrorMode = false
                
                if text.isEmpty {
                    setInputFieldValues(fieldType: .cvv, placeholderColor: ValidState.border.color, placeholderText: PlaceholderType.correctCvv.toString(), borderViewColor: ValidState.normal.color)
                    iconCvvCard.isHidden = false
                    return
                }
                
                if Card.isValidCvv(cvv: text, isCvvRequired: !cvvView.isHidden) {
                    setInputFieldValues(fieldType: .cvv, placeholderColor: ValidState.border.color, placeholderText: PlaceholderType.correctCvv.toString(), borderViewColor: ValidState.normal.color)
                }
                
                if text.count == 4 {
                    cardCvvTextField.resignFirstResponder()
                }
            }
        default: break
        }
    }
    
    /// Did End Editing
    /// - Parameter textField:
    @objc private func didEndEditing(_ textField: UITextField) {
        
        switch textField {
            
        case cardNumberTextField:
            if let cardNumber = cardNumberTextField.text?.formattedCardNumber() {
                cardNumberTextField.text = cardNumber
                
                if !Card.isCardNumberValid(cardNumber) {
                    setInputFieldValues(fieldType: .card, placeholderColor: ValidState.error.color, placeholderText: PlaceholderType.incorrectCard.toString(), borderViewColor: ValidState.error.color)
                    
                    if cardNumber.isEmpty {
                        setInputFieldValues(fieldType: .card, placeholderColor: ValidState.error.color, placeholderText: PlaceholderType.correctCard.toString(), borderViewColor: ValidState.error.color)
                    }
                }
                else {
                    cardView.layer.borderColor = ValidState.border.color.cgColor
                }
                validateAndErrorCardNumber()
            }
            
        case cardExpDateTextField:
            if let cardExp = cardExpDateTextField.cardExpText?.formattedCardExp() {
                cardExpDateTextField.cardExpText = cardExp
                
                if !Card.isExpDateValid(cardExp) {
                    setInputFieldValues(fieldType: .expDate, placeholderColor: ValidState.error.color, placeholderText: PlaceholderType.incorrectExpDate.toString(), borderViewColor: ValidState.error.color)
                    
                    if cardExp.isEmpty {
                        setInputFieldValues(fieldType: .expDate, placeholderColor: ValidState.error.color, placeholderText: PlaceholderType.correctExpDate.toString(), borderViewColor: ValidState.error.color)
                    }
                }
                else {
                    expDateView.layer.borderColor = ValidState.border.color.cgColor
                }
                validateAndErrorCardExp()
            }
            
        case cardCvvTextField:
            if let cardCvv = cardCvvTextField.text?.formattedCardCVV() {
                cardCvvTextField.text = cardCvv
                
                if !Card.isValidCvv(cvv: cardCvv, isCvvRequired: !cvvView.isHidden) {
                    setInputFieldValues(fieldType: .cvv, placeholderColor: ValidState.error.color, placeholderText: PlaceholderType.incorrectCvv.toString(), borderViewColor: ValidState.error.color)
                    
                    if cardCvv.isEmpty {
                        setInputFieldValues(fieldType: .cvv, placeholderColor: ValidState.error.color, placeholderText: PlaceholderType.correctCvv.toString(), borderViewColor: ValidState.error.color)
                    }
                }
                else {
                    cvvView.layer.borderColor = ValidState.border.color.cgColor
                    cvvPlaceholder.textColor = ValidState.border.color
                    
                }
                validateAndErrorCardCVV()
            }
        default: break
        }
    }
    
    /// Should Return
    /// - Parameter textField:
    @objc private func shouldReturn(_ textField: UITextField) {
        
        switch textField {
            
        case cardNumberTextField:
            
            if let cardNumber = self.cardNumberTextField.text?.formattedCardNumber() {
                self.cardNumberTextField.resignFirstResponder()
                if Card.isCardNumberValid(cardNumber) {
                    self.cardExpDateTextField.becomeFirstResponder()
                }
            }
        case cardExpDateTextField:
            
            if let cardExp = self.cardExpDateTextField.text?.formattedCardExp() {
                if cardExp.count == 5 {
                    self.cardCvvTextField.becomeFirstResponder()
                }
            }
            
        case cardCvvTextField:
            
            if let text = self.cardCvvTextField.text?.formattedCardCVV() {
                if text.count == 3 || text.count == 4 {
                    self.cardCvvTextField.resignFirstResponder()
                }
            }
        default: break
        }
    }
}
