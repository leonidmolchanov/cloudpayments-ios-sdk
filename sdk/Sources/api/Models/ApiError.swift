//
//  ApiErrors.swift
//  sdk
//
//  Created by a.ignatov on 01.12.2022.
//  Copyright © 2022 Cloudpayments. All rights reserved.
//

import Foundation
public class ApiError {
    
    static let errors = [
        "3001": "Неверный номер заказа",
        "3002": "Некорректный идентификатор плательщика",
        "3003": "Неверная сумма",
        "3004": "Платеж просрочен",
        "3005": "Платеж не может быть принят",
        "3006": "Сервис недоступен",
        "3007": "Ошибка соединения",
        "3008": "Платеж не может быть принят",
        "5001": "Отказ эмитента проводить онлайн операцию",
        "5005": "Операция отклонена эмитентом",
        "5006": "Отказ сети проводить операцию или неправильный CVV код",
        "5012": "Карта не предназначена для онлайн платежей",
        "5013": "Слишком маленькая или слишком большая сумма операции",
        "5030": "Ошибка на стороне эквайера",
        "5031": "Неизвестный эмитент карты",
        "5034": "Отказ эмитента",
        "5041": "Карта потеряна",
        "5043": "Карта украдена",
        "5051": "Недостаточно средств на карте",
        "5054": "Карта просрочена или неверно указан срок действия",
        "5057": "Ограничение на карте",
        "5061": "Не удалось выполнить оплату: превышен лимит по карте",
        "5065": "Превышен лимит операций по карте",
        "5082": "Неверный CVV код",
        "5091": "Эмитент недоступен",
        "5092": "Эмитент недоступен",
        "5096": "Ошибка банка-эквайера или сети",
        "5204": "Операция не может быть обработана",
        "5206": "3-D Secure авторизация не пройдена",
        "5207": "3-D Secure авторизация недоступна",
        "5300": "Лимиты эквайера на проведение операций",
        "3001_extra": "Платеж будет отклонен",
        "3002_extra": "Платеж будет отклонен",
        "3003_extra": "Обратитесь в поддержку сайта",
        "3004_extra": "Обратитесь в поддержку сайта",
        "3005_extra": "Платеж будет отклонен",
        "3006_extra": "Платеж будет отклонен. Попробуйте позже",
        "3007_extra": "Платеж будет отклонен. Попробуйте позже",
        "3008_extra": "Платеж будет отклонен",
        "5001_extra": "Свяжитесь с вашим банком или воспользуйтесь другой картой",
        "5005_extra": "Свяжитесь с вашим банком или воспользуйтесь другой картой",
        "5006_extra": "Проверьте правильность введенных данных карты или воспользуйтесь другой картой",
        "5012_extra": "Воспользуйтесь другой картой или свяжитесь с банком, выпустившим карту",
        "5013_extra": "Проверьте корректность суммы",
        "5030_extra": "Повторите попытку позже",
        "5031_extra": "Воспользуйтесь другой картой",
        "5034_extra": "Свяжитесь с вашим банком или воспользуйтесь другой картой",
        "5041_extra": "Свяжитесь с вашим банком или воспользуйтесь другой картой",
        "5043_extra": "Свяжитесь с вашим банком или воспользуйтесь другой картой",
        "5051_extra": "",
        "5054_extra": "Проверьте правильность введенных данных карты или воспользуйтесь другой картой",
        "5057_extra": "Свяжитесь с вашим банком или воспользуйтесь другой картой",
        "5061_extra": "Превышение лимита оплаты по карте. Измените настройки лимита или оплатите другой картой",
        "5065_extra": "Свяжитесь с вашим банком или воспользуйтесь другой картой",
        "5082_extra": "Проверьте правильность введенных данных карты или воспользуйтесь другой картой",
        "5091_extra": "Повторите попытку позже или воспользуйтесь другой картой",
        "5092_extra": "Повторите попытку позже или воспользуйтесь другой картой",
        "5096_extra": "Повторите попытку позже",
        "5204_extra": "Свяжитесь с вашим банком или воспользуйтесь другой картой",
        "5206_extra": "Свяжитесь с вашим банком или воспользуйтесь другой картой",
        "5207_extra": "Свяжитесь с вашим банком или воспользуйтесь другой картой",
        "5300_extra": "Свяжитесь с вашим банком или воспользуйтесь другой картой"
    ]
    
    public static func getFullErrorDescription(code: String) -> String {
        
        let error = "\(getErrorDescription(code: code))#\(getErrorDescriptionExtra(code: code))"
        
        return error
    }
    
    static func getErrorDescription(code: String) -> String {
        
        let description: String = errors[code] ?? "Операция не может быть обработана"
        return description
    }
    
    static func getErrorDescriptionExtra(code: String) -> String {
        
        let description: String = errors[code + "_extra"] ?? "Свяжитесь с вашим банком или воспользуйтесь другой картой"
        return description
    }
    
    static func getErrorDescription(error: Error?) -> String {
        guard let error = error else {
            return "Операция не может быть обработана"
        }
        
//        let code = String(error._code)
//
//        let description = errors[code + "_extra"]
        return error.localizedDescription
    }
}


extension ApiError {
    public static func getFullErrorDescriptionIntentApi(from code: String?) -> String {
        guard let code = code else { return "Операция не может быть обработана" }

        let trimmedCode = code.hasPrefix("R") ? String(code.dropFirst()) : code

        let base = getErrorDescription(code: trimmedCode)
        let extra = getErrorDescriptionExtra(code: trimmedCode)

        return [base, extra].joined(separator: base.isEmpty || extra.isEmpty ? "" : "#")
    }
}
