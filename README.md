## CloudPayments SDK for iOS 

CloudPayments SDK позволяет интегрировать прием платежей в мобильные приложения для платформы iOS.

### Требования
Для работы CloudPayments SDK необходим iOS версии 13.0 и выше.

### Подключение
Для подключения SDK мы рекомендуем использовать CocoaPods. Добавьте в файл Podfile зависимости:

```
pod 'Cloudpayments', :git =>  "https://gitpub.cloudpayments.ru/integrations/sdk/cloudpayments-ios", :branch => "master"
pod 'CloudpaymentsNetworking', :git =>  "https://gitpub.cloudpayments.ru/integrations/sdk/cloudpayments-ios", :branch => "master"
```

### Структура проекта:

* **demo** - Пример реализации приложения с использованием SDK
* **sdk** - Исходный код SDK

### Возможности CloudPayments SDK:

Вы можете использовать SDK одним из трех способов: 
* использовать стандартную платежную форму Cloudpayments
* реализовать свою платежную форму с использованием функций CloudpaymentsApi без вашего сервера
* реализовать свою платежную форму, сформировать криптограмму и отправить ее на свой сервер

## Инициализация CloudPaymentsSDK

В `AppDelegate.swift` вашего проекта добавьте нотификацию `CloudtipsSDK` о событиях жизненного цикла приложения:

```swift
func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
    return true
}

func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
    return true
}
```

### Использование стандартной платёжной формы от CloudPayments:

1. Cоздайте объект PaymentDataPayer и проинициализируйте его, затем создайте объект PaymentData передайте в него объект PaymentDataPayer, сумму платежа, валюту и дополнительные данные. Если хотите иметь возможность оплаты с помощью Apple Pay, передайте также Apple pay merchant id.

```
//содержимое позиций чека
let item = Receipt.Item(
            label: descript,
            price: 300.0,
            quantity: 3.0,
            amount: 900.0,
            vat: 20,
            method: 0,
            object: 0)
            
//создание объекта чека
let receipt = Receipt(
            items: [item],
            taxationSystem: 0,
            email: email,
            phone: payerPhone,
            isBso: false,
            amounts: Receipt.Amounts(
                electronic: 900.0,
                advancePayment: 0.0,
                credit: 0.0,
                provision: 0.0))
                
//создание объекта подписки
let recurrent = Recurrent(
            interval: "Month",
            period: 1,
            customerReceipt: receipt, 
            amount: 100)

// Доп. поле, куда передается информация о плательщике. Используйте следующие параметры: FirstName, LastName, MiddleName, Birth, Street, Address, City, Country, Phone, Postcode
let payer = PaymentDataPayer(firstName: "Test", lastName: "Testov", middleName: "Testovich", birth: "1955-02-22", address: "home 6", street: "Testovaya", city: "Moscow", country: "RU", phone: "89991234567", postcode: "12345")
    
// Указывайте дополнительные данные если это необходимо
let jsonData: [String: Any] = ["age":27, "name":"Ivan", "phone":"+79998881122"] // Любые другие данные, которые будут связаны с транзакцией, в том числе инструкции для создания подписки или формирования онлайн-чека должны обёртываться в объект cloudpayments. Мы зарезервировали названия следующих параметров и отображаем их содержимое в реестре операций, выгружаемом в Личном Кабинете: name, firstName, middleName, lastName, nick, phone, address, comment, birthDate.

let paymentData = PaymentData() 
    .setAmount(String(totalAmount)) // Cумма платежа в валюте, максимальное количество не нулевых знаков после запятой: 2
    .setCurrency(.ruble) // Валюта
    .setApplePayMerchantId("") // Apple pay merchant id (Необходимо получить у Apple)
    .setDescription("Корзина цветов") // Описание оплаты в свободной форме
    .setAccountId("111") // Обязательный идентификатор пользователя для создания подписки и получения токена
    .setInvoiceId("123") // Номер счета или заказа
    .setEmail("test@cp.ru") // E-mail плательщика, на который будет отправлена квитанция об оплате
    .setPayer(payer) // Информация о плательщике
    .setJsonData(jsonData) // Любые другие данные, которые будут связаны с транзакцией  
    .setReceipt(receipt) // Данные для чека
    .setRecurrent(recurrent) // Данные для подписки           
```

2. Создайте объект PaymentConfiguration, передайте в него объект PaymentData и ваш **Public_id** из [личного кабинета Cloudpayments](https://merchant.cloudpayments.ru/). Реализуйте протокол PaymentDelegate, чтобы узнать о завершении платежа

```
let configuration = PaymentConfiguration.init(
    publicId: "", // Ваш Public_id из личного кабинета
    paymentData: paymentData, // Информация о платеже
    delegate: self, // Вывод информации о завершении платежа
    uiDelegate: self, // Вывод информации о UI 
    scanner: nil, // Сканер банковских карт
    requireEmail: true, // Обязательный email, (по умолчанию false)
    useDualMessagePayment: true, // Использовать двухстадийную схему проведения платежа, (по умолчанию используется одностадийная схема)
    disableApplePay: false, // Выключить Apple Pay, (по умолчанию Apple Pay включен)
    successRedirectUrl: "", // Ваш deeplink для редиректа из приложения банка после успешной оплаты, (если ничего не передано, по умолчанию используется URL адрес вашего сайта)
    failRedirectUrl: "" //  Ваш deeplink для редиректа из приложения банка после неуспешной оплаты, (если ничего не передано, по умолчанию используется URL адрес вашего сайта)
```
2.1. Для передачи deeplink при использовании CБП,TPay,SberPay нужно использовать Universal Links:

2.2. Документация от Apple: [Universal Links](https://developer.apple.com/documentation/xcode/supporting-universal-links-in-your-app)

2.3. В вашем приложении реализуйте метод application(_:continue:restorationHandler:) в классе вашего AppDelegate для обработки Universal Links

### Использование TPay в стандартной платёжной форме:

1. Включить TPay в [личном кабинете Cloudpayments](https://merchant.cloudpayments.ru/).

### Использование отдельной кнопки TPay:

1. Включить TPay в [личном кабинете Cloudpayments](https://merchant.cloudpayments.ru/).

2.Создайте объект PaymentTPayView и разместите его

   ``` 
    private lazy var tPayView = PaymentTPayView() 
    
    private func setupViews() {
    
    // делегат
    tPayView.delegate = self 

    view.addSubview(tPayView)

    tPayView.backgroundColor = .black
    tPayView.layer.cornerRadius = 8

    tPayView.translatesAutoresizingMaskIntoConstraints = false

    NSLayoutConstraint.activate([
    tPayView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
    tPayView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
    tPayView.heightAnchor.constraint(equalToConstant: 50),
    tPayView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
    ])
    }
   ```
3.Создайте метод с конфигурацией  

    private func addConfiguration() {

    let jsonObject: [String: Any?] = [:]

    func JSONStringify(value: [String: Any?], prettyPrinted:Bool = false) -> String {
    let options = prettyPrinted ? JSONSerialization.WritingOptions.prettyPrinted : JSONSerialization.WritingOptions(rawValue: 0)
    if JSONSerialization.isValidJSONObject(value) {
    do {
    let data = try JSONSerialization.data(withJSONObject: value, options: options)
    if let string = NSString(data: data, encoding: NSUTF8StringEncoding) {
    return string as String
    }
    } catch {

    print("parsing error")
        }
    }
    return ""
    }

    let dataString = JSONStringify(value: jsonObject) 

    let paymentData = PaymentData()
    .setAmount("10")
    .setCurrency("RUB")
    .setDescription("Корзина цветов")
    .setAccountId("111")
    .setInvoiceId("123")
    .setEmail("test@cp.ru")
    .setJsonData(dataString)

    let configuration = PaymentConfiguration(
    publicId: "", // // Ваш Public_id из личного кабинета
    paymentData: paymentData, // Информация о платеже
    successRedirectUrl: "" // Ваш deeplink для редиректа из приложения банка после успешной оплаты, (если ничего не передано, по умолчанию используется URL адрес вашего сайта)
    failRedirectUrl: "" // Ваш deeplink для редиректа из приложения банка после неуспешной оплаты, (если ничего не передано, по умолчанию используется URL адрес вашего сайта)
    useDualMessagePayment: true, // Использовать двухстадийную схему проведения платежа, (по умолчанию используется одностадийная схема)
    saveCardMode: false, // Передача сохранения карты (только для отдельной кнопки)
    showResultScreen: true)// Для включения экранов успеха и неуспеха для отдельных кнопок (по умолчанию false)

    tPayView.configuration = configuration // передайте конфигурацию в объект PaymentTPayView
    }
    
4.Создайте метод для проверки доступности TPay  
    
    private func checkButtons() {
    tPayView.getMerchantConfiguration(publicId: merchantPublicId) { [ weak self ] result in
    guard let self = self, let result = result else { return }
    // проверка доступности TPay и её отображение 
    self.tPayView.isHidden = !result.isOnTPayButton
        }
    }

5.Подпишитесь на протокол PaymentTPayDelegate и обработайте результаты

    extension TestSinglePaymentMethodsController: PaymentTPayDelegate {
    func resultPayment(_ tPay: Cloudpayments.PaymentTPayView, result: Cloudpayments.PaymentTPayView.PaymentAction, error: String?, transactionId: Int64?) {
        switch result {
        case .success:
            print("Оплата прошла успешно c транзакцией \(String(describing: transactionId))")
        case .error:
            print("Операция отклонена")
        case .close:
            print("Пользователь закрыл платёжную форму TPay")
        }
    } }
    
### Использование отдельной кнопки СБП:

Включить СБП через вашего курирующего менеджера.

1.Создайте объект PaymentSbpView и разместите его

   ``` 
    private lazy var sbpView = PaymentSbpView()
    
    private func setupViews() {
    
    // делегат
    sbpView.delegate = self 

    view.addSubview(sbpView)

    sbpView.backgroundColor = .blue
    sbpView.layer.cornerRadius = 8

    sbpView.translatesAutoresizingMaskIntoConstraints = false

    NSLayoutConstraint.activate([
    sbpView.topAnchor.constraint(equalTo: tPayView.bottomAnchor, constant: 20),
    sbpView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
    sbpView.heightAnchor.constraint(equalToConstant: 50),
    sbpView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
    sbpView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
    ])
    }
   ```
2.Создайте метод с конфигурацией  

    private func addConfiguration() {

    let jsonObject: [String: Any?] = [:]

    func JSONStringify(value: [String: Any?], prettyPrinted:Bool = false) -> String {
    let options = prettyPrinted ? JSONSerialization.WritingOptions.prettyPrinted : JSONSerialization.WritingOptions(rawValue: 0)
    if JSONSerialization.isValidJSONObject(value) {
    do {
    let data = try JSONSerialization.data(withJSONObject: value, options: options)
    if let string = NSString(data: data, encoding: NSUTF8StringEncoding) {
    return string as String
    }
    } catch {

    print("parsing error")
        }
    }
    return ""
    }

    let dataString = JSONStringify(value: jsonObject) 

    let paymentData = PaymentData()
    .setAmount("10")
    .setCurrency("RUB")
    .setDescription("Корзина цветов")
    .setAccountId("111")
    .setInvoiceId("123")
    .setEmail("test@cp.ru")
    .setJsonData(dataString)

    let configuration = PaymentConfiguration(
    publicId: "", // // Ваш Public_id из личного кабинета
    paymentData: paymentData, // Информация о платеже
    useDualMessagePayment: false, // Использовать двухстадийную схему проведения платежа, (Для СБП используется одностадийная схема)
    saveCardForSinglePaymentMode: false, // Галочка для сохранения или не сохранения карты (по умолчанию nil)
    showResultScreen: true) // Для включения экранов успеха и неуспеха для отдельных кнопок (по умолчанию false)

    sbpView.configuration = configuration // передайте конфигурацию в объект PaymentSbpView
    }
    
3.Создайте метод для проверки доступности СБП  
    
    private func checkButtons() {
    tpayView.getMerchantConfiguration(publicId: merchantPublicId) { [ weak self ] result in
    guard let self = self, let result = result else { return }
    // проверка доступности CБП и её отображение
    self.sbpView.isHidden = !result.isOnSbpButton
        }
    }

4.Подпишитесь на протокол PaymentSbpDelegate и обработайте результаты

    extension TestSinglePaymentMethodsController: PaymentSbpDelegate {
    func resultPayment(_ sbp: Cloudpayments.PaymentSbpView, result: Cloudpayments.PaymentSbpView.PaymentAction, error: String?, transactionId: Int64?) {
        switch result {
        case .success:
            print("Оплата прошла успешно c транзакцией \(String(describing: transactionId))")
        case .error:
            print("Операция отклонена")
        case .close:
            print("Пользователь закрыл платежную форму со списком банков")
        }
    } }
    
### Использование СБП в стандартной платёжной форме: 

Включить СБП через вашего курирующего менеджера.

### Использование отдельной кнопки SberPay:

1. Включить SberPay через вашего курирующего менеджера.

2. Создайте объект PaymentSberPayView и разместите его

3. Создайте метод для проверки доступности SberPay  
    ```
    private func checkButtons() {
    tPayView.getMerchantConfiguration(publicId: merchantPublicId) { [ weak self ] result in
    guard let self = self, let result = result else { return }
    // проверка доступности SberPay и её отображение
    self.sberPayView.isHidden = !result.isOnSberPayButton
        } 
    }
    ```

4. Подпишитесь на протокол PaymentSberPayDelegate и обработайте результаты

### Использование SberPay в стандартной платёжной форме: 

Включить SberPay через вашего курирующего менеджера.

3. Вызовите форму оплаты внутри своего контроллера (Для стандартной формы)

```
PaymentForm.present(with: configuration, from: self)
```

4. Сканер карт

Вы можете подключить любой сканер карт. Для этого нужно реализовать протокол PaymentCardScanner и передать объект, реализующий протокол, при создании PaymentConfiguration. Если протокол не будет реализован, то кнопка сканирования не будет показана

Пример со сканером [CardIO](https://github.com/card-io/card.io-iOS-SDK)

* Создайте контроллер со сканером и верните его в функции протокола PaymentCardScanner
```
extension CartViewController: PaymentCardScanner {
    func startScanner(completion: @escaping (String?, UInt?, UInt?, String?) -> Void) -> UIViewController? {
        self.scannerCompletion = completion
        
        let scanController = CardIOPaymentViewController.init(paymentDelegate: self)
        return scanController
    }
}
```
* После завершения сканирования вызовите замыкание и передайте данные карты
```
extension CartViewController: CardIOPaymentViewControllerDelegate {
    func userDidCancel(_ paymentViewController: CardIOPaymentViewController!) {
        paymentViewController.dismiss(animated: true, completion: nil)
    }
    
    func userDidProvide(_ cardInfo: CardIOCreditCardInfo!, in paymentViewController: CardIOPaymentViewController!) {
        self.scannerCompletion?(cardInfo.cardNumber, cardInfo.expiryMonth, cardInfo.expiryYear, cardInfo.cvv)
        paymentViewController.dismiss(animated: true, completion: nil)
    }
}
```


### Использование вашей платежной формы с использованием функций CloudPaymentsApi:

* **Для использования нового формата криптограммы:**

1. Получите **publicKey** и **keyVersion** с данного [API](https://api.cloudpayments.ru/payments/publickey)
2. Полученные **publicKey** и **keyVersion** передайте в метод создания криптограммы.

3. Cоздайте криптограмму карточных данных

```
// Обязательно проверяйте входящие данные карты (номер, срок действия и cvc код) на корректность, иначе метод создания криптограммы вернет nil.
let cardCryptogramPacket = Card.makeCardCryptogramPacket(cardNumber: cardNumber, expDate: expDate, cvv: cvv, merchantPublicID: "Ваш Public_id", publicKey: "Полученный публичный ключ", keyVersion: "Полученная версия ключа")
```

4. Выполните запрос на проведения платежа. Создайте объект CloudpaymentApi и вызовите метод charge для одностадийного платежа или auth для двухстадийного. Укажите email, на который будет выслана квитанция об оплате.

```
let api = CloudpaymentsApi.init(publicId: Constants.merchantPulicId)
api.auth(cardCryptogramPacket: cardCryptogramPacket, cardHolderName: cardHolderName, email: nil, amount: String(total)) { [weak self] (response, error) in
    if let response = response {
        self?.checkTransactionResponse(transactionResponse: response, completion: completion)
    } else if let error = error {
        completion?(false, error.localizedDescription)
    }
}
```

5. Если необходимо, покажите 3DS форму для подтверждения платежа

```
let data = ThreeDsData.init(transactionId: transactionId, paReq: paReq, acsUrl: acsUrl)
let threeDsProcessor = ThreeDsProcessor()
threeDsProcessor.make3DSPayment(with: data, delegate: self)
```

6. Для получения формы 3DS и получения результатов прохождения 3DS аутентификации реализуйте протокол ThreeDsDelegate.

```
extension CheckoutViewController: ThreeDsDelegate {
    // Вы получаете объект WKWebView, который сами показываете нужным вам способом и в нужном вам месте
    func willPresentWebView(_ webView: WKWebView) {
        self.showThreeDsForm(webView)
    }

    // Для завершения оплаты в выполните метод post3ds CloudpaymentsApi. 
    // threeDsCallbackId - идентификатор, полученный в ответ на запрос на проведение платежа
    func onAuthotizationCompleted(with md: String, paRes: String) {
        hideThreeDs()
        post3ds(transactionId: md, paRes: paRes, threeDsCallbackId: threeDsCallbackId)
    }

    func onAuthorizationFailed(with html: String) {
        hideThreeDs()
        print("error: \(html)")
    }

}
```

#### Оплата с помощью Apple Pay с CloudPaymentsApi

[Об Apple Pay](https://developers.cloudpayments.ru/#apple-pay)

1. Создайте массив объектов PKPaymentSummaryItem используя информацию о товарах выбранных вашим клиентом
```
var paymentItems: [PKPaymentSummaryItem] = []
for product in CartManager.shared.products {
    let paymentItem = PKPaymentSummaryItem.init(label: product.name, amount: NSDecimalNumber(value: Int(product.price)!))
    paymentItems.append(paymentItem)
}
```
2. Укажите ваш Apple Pay ID и допустимые платежные системы
```
let applePayMerchantID = "merchant.com.YOURDOMAIN" // Ваш ID для Apple Pay
let paymentNetworks = [PKPaymentNetwork.visa, PKPaymentNetwork.masterCard] // Платежные системы для Apple Pay
```
3. Проверьте, доступны ли пользователю эти платежные системы
```
buttonApplePay.isHidden = !PKPaymentAuthorizationViewController.canMakePayments(usingNetworks: paymentNetworks) // Скройте кнопку Apple Pay если пользователю недоступны указанные вами платежные системы
```
4. Создайте и выполните запрос к Apple Pay
```
let request = PKPaymentRequest()
request.merchantIdentifier = applePayMerchantID
request.supportedNetworks = paymentNetworks
request.merchantCapabilities = PKMerchantCapability.capability3DS // Возможно использование 3DS
request.countryCode = "RU" // Код страны
request.currencyCode = "RUB" // Код валюты
request.paymentSummaryItems = paymentItems
let applePayController = PKPaymentAuthorizationViewController(paymentRequest: request)
applePayController?.delegate = self
self.present(applePayController!, animated: true, completion: nil)
```
5. Обрабатываем ответ от Apple Pay
```
extension CheckoutViewController: PKPaymentAuthorizationViewControllerDelegate {
    func paymentAuthorizationViewController(_ controller: PKPaymentAuthorizationViewController, didAuthorizePayment payment: PKPayment, completion: @escaping ((PKPaymentAuthorizationStatus) -> Void)) {
        completion(PKPaymentAuthorizationStatus.success)
        
        // Конвертируйте объект PKPayment в строку криптограммы
        guard let cryptogram = payment.convertToString() else {
            return
        }
               
        // Используйте методы API для выполнения оплаты по криптограмме
        // (charge (для одностадийного платежа) или auth (для двухстадийного))
        //charge(cardCryptogramPacket: cryptogram, cardHolderName: "")
        auth(cardCryptogramPacket: cryptogram, cardHolderName: "")
      
    }
    
    func paymentAuthorizationViewControllerDidFinish(_ controller: PKPaymentAuthorizationViewController) {
        controller.dismiss(animated: true, completion: nil)
    }
}
```

#### ВАЖНО:

При обработке успешного ответа от Apple Pay, обязательно выполните преобразование объекта PKPayment в криптограмму для передачи в платежное API CloudPayments

```
let cryptogram = payment.convertToString() 
```
После успешного преобразования криптограмму можно использовать для проведения оплаты.

### Другие функции

* Проверка карточного номера на корректность

```
Card.isCardNumberValid(cardNumber)

```

* Проверка срока действия карты

```
Card.isExpDateValid(expDate) // expDate в формате MM/yy

```

* Определение типа платежной системы

```
let cardType: CardType = Card.cardType(from: cardNumberString)
```

* Определение банка эмитента

```
CloudpaymentsApi.getBankInfo(cardNumber: cardNumber) { (info, error) in
    if let error = error {
        print("error: \(error.message)")
    } else {
        if let bankName = info?.bankName {
            print("BankName: \(bankName)")
        } else {
            print("BankName is empty")
        }
        
        if let logoUrl = info?.logoUrl {
            print("LogoUrl: \(logoUrl)")
        } else {
            print("LogoUrl is empty")
        }
    }
}
```

* Шифрование карточных данных и создание криптограммы для отправки на сервер

```
let cardCryptogramPacket = Card.makeCardCryptogramPacket(with: cardNumber, expDate: expDate, cvv: cvv, merchantPublicID: Constants.merchantPulicId)
```

* Шифрование cvv при оплате сохраненной картой и создание криптограммы для отправки на сервер

```
let cvvCryptogramPacket = Card.makeCardCryptogramPacket(with: cvv)
```

* Преобразование PKPayment в строку-криптограмму для отправки на сервер

```
let payment: PKPayment
let cryptogram = payment.convertToString()
```

* Отображение 3DS формы и получении результата 3DS аутентификации

```
let data = ThreeDsData.init(transactionId: transactionId, paReq: paReq, acsUrl: acsUrl)
let threeDsProcessor = ThreeDsProcessor()
threeDsProcessor.make3DSPayment(with: data, delegate: self)

public protocol ThreeDsDelegate: class {
    func willPresentWebView(_ webView: WKWebView)
    func onAuthotizationCompleted(with md: String, paRes: String)
    func onAuthorizationFailed(with html: String)
}
```

### История обновлений:

#### 1.5.15
* Добавлены объекты для создания чека и подписки

#### 1.5.14
* Исправлена проблема с логотипом TPay

#### 1.5.13
* Выполнена доработка для SberPay

#### 1.5.12
* Повышена надежность

#### 1.5.11
* Удален параметр ipAddress

#### 1.5.10
* Исправлена проблема при оплате по Tpay и открытие приложения Т-банк

#### 1.5.9
* Исправлена проблема при оплате по СБП

#### 1.5.8
* Исправлена проблема при оплате по Tpay и SberPay

#### 1.5.7
* Обновлен дизайн TPay
* Добавлен параметр showResultScreen

#### 1.5.6
* Добавлен режим запуска SDK SberPay
* Добавлен Privacy Manifest

#### 1.5.5
* Добавлен режим запуска SDK СБП

#### 1.5.4
* Добавлен поиск по списку банков при оплате по СБП

* Добавлена расшифрока некоторых причин отказа в проведении платежа

* Повышена надежность


#### 1.5.2
* Улучшена валидация

* Повышена надежность

#### 1.5.1
* Добавлен режим запуска SDK TPay

* Добавлена возможность педедать deeplink для перехода из приложения T-банк после оплаты

* Отключен YandexPay

#### 1.5.0
* Повышена надежность

#### 1.4.2
* Обновлен YandexPay SDK

* Исправлена передача email при оплате через YandexPay 

#### 1.4.1
* Исправлена передача accountId при оплате через СБП
 
* Отключена переадресация на сайт эквайера из приложения банка после оплаты через СБП

#### 1.4.0
* Добавлен новый способ оплаты: оплата через СБП (см. документацию для получения более подробной информации: https://gitpub.cloudpayments.ru/integrations/sdk/cloudpayments-ios/-/blob/master/README.md)

* Оптимизировано получение параметров шлюза и проверка доступности способов оплаты: теперь экран способов оплаты появляется сразу со всеми подключенными и доступными способами оплаты

* Оптимизирован интерфейс окна Выбор способов оплаты, теперь он работает плавнее

* Добавлена проверка интерент соединения во время запука SDK, теперь пользователь не пройдет дальше по сценарию оплаты если сервер не доступен

* Внесено значительное количество небольших исправлений и улучшений


### Поддержка

По возникающим вопросам технического характера обращайтесь на support@cp.ru
