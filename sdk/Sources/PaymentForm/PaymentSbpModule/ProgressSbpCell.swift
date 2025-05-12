//
//  ProgressSbpCell.swift
//  sdk
//
//  Created by Cloudpayments on 02.05.2024.
//  Copyright © 2024 Cloudpayments. All rights reserved.
//

import Foundation
import UIKit

final class ProgressSbpCell: UITableViewCell {
    
    //MARK: - Private Properties
    
    private lazy var customImageView: UIImageView = {
        let imageView = UIImageView()
        return imageView
    }()
    
    private lazy var customLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 17)
        return label
    }()
    
    //MARK: - Prepare For Reuse
    
    override func prepareForReuse() {
        super.prepareForReuse()
        customImageView.image = nil
    }
    
    //MARK: - Init
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .white
        setupCellLayout()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    //MARK: - Private methods
    
    private func setupCellLayout() {
        customImageView.contentMode = .scaleAspectFit
        customImageView.backgroundColor = .clear
        selectionStyle = .none
        separatorInset = .init(top: 0, left: 36, bottom: 0, right: 20)
        
        let view = UIView()
        view.backgroundColor = .clear
        contentView.addSubviews(view)
        view.addSubviews(customImageView, customLabel)
        
        NSLayoutConstraint.activate([
            view.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            view.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            view.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 36),
            view.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            customImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            customImageView.topAnchor.constraint(greaterThanOrEqualTo: view.topAnchor, constant: 15),
            customImageView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            customImageView.heightAnchor.constraint(equalToConstant: 28),
            customImageView.widthAnchor.constraint(equalToConstant: 38),
            
            customLabel.topAnchor.constraint(equalTo: view.topAnchor),
            customLabel.leadingAnchor.constraint(equalTo: customImageView.trailingAnchor, constant: 16),
            customLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            customLabel.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    func configureCell(model: Bank) {
        customLabel.text = model.bankName
        guard let logoUrl = model.logoUrl else { return }
        loadImage(url: logoUrl) { [weak self] image in
            DispatchQueue.main.async {
                self?.customImageView.image = image
            }
        }
    }
    
    fileprivate func loadImage(url string: String, completion handler: @escaping (UIImage?) -> Void) {
        CloudpaymentsApi.loadImage(url: string) { [weak self] result in
            guard let _ = self else { return }
            handler(result)
        }
    }
}
