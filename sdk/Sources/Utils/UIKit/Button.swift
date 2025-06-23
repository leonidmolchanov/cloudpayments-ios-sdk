//
//  Button.swift
//  sdk
//
//  Created by Sergey Iskhakov on 17.09.2020.
//  Copyright © 2020 Cloudpayments. All rights reserved.
//

import UIKit

class Button: UIButton {
    private var _onAction: (()->())?
    
    var onAction: (()->())? {
        get { return _onAction }
        set {
            // Сначала удаляем старый target
            self.removeTarget(self, action: #selector(handleAction(_:)), for: .touchUpInside)
            
            // Сохраняем новое действие
            _onAction = newValue
            
            // Добавляем target только если есть действие
            if newValue != nil {
                self.addTarget(self, action: #selector(handleAction(_:)), for: .touchUpInside)
            }
        }
    }
    
    @IBInspectable var borderWidth : CGFloat = 0.0 {
        didSet {
            layer.borderWidth = borderWidth;
        }
    }
    @IBInspectable var borderColor : UIColor = UIColor.clear {
        didSet {
            layer.borderColor = borderColor.cgColor
        }
    }
    @IBInspectable var cornerRadius : CGFloat = 0.0 {
        didSet {
            layer.cornerRadius = cornerRadius
            layer.masksToBounds = cornerRadius > 0
        }
    }
    
    func setAlpha(_ alpha: CGFloat) {
        self.alpha = alpha
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    @objc func handleAction(_ sender: Any) {
        guard let action = self.onAction else { return }
        action()
    }
    
    deinit {
        // Удаляем target перед очисткой
        self.removeTarget(self, action: #selector(handleAction(_:)), for: .touchUpInside)
        _onAction = nil
    }
}

extension UIButton {
    
    convenience init(_ color: UIColor,
                     _ cornerRadius: CGFloat,
                     _ borderWidth: CGFloat,
                     _ buttonText: String,
                     _ textColor: UIColor) {
        self.init()
        self.layer.borderColor = color.cgColor
        self.layer.cornerRadius = cornerRadius
        self.layer.borderWidth = borderWidth
        self.setTitle(buttonText, for: .normal)
        self.setTitleColor(textColor, for: .normal)
    }
}
