//
//  ProgressSbpView.swift
//  sdk
//
//  Created by Cloudpayments on 02.05.2024.
//  Copyright © 2024 Cloudpayments. All rights reserved.
//

import Foundation
import UIKit

protocol CustomSbpViewDelegate: AnyObject {
    func numberOfRow(_ progressSbpView: ProgressSbpView, didChange text: String)
    func searchBarCancelButtonClicked(_ progressSbpView: ProgressSbpView)
    
    func numberOfRow(_ progressSbpView: ProgressSbpView) -> Int
    func progressSbpView(_ progressSbpView: ProgressSbpView, cellFor row: Int) -> Bank
    func progressSbpView(_ progressSbpView: ProgressSbpView, didSelect row: Int)
}

//MARK: - ProgressSbpView

final class ProgressSbpView: UIView {
    
    weak var delegate: CustomSbpViewDelegate?
    
    //MARK: - Private properties
    
    private var notFoundBanksView = UIView(backgroundColor: .white)
    private lazy var sbpTableView: UITableView = {
        let tableView = UITableView(frame: self.bounds, style: .plain)
        tableView.register(ProgressSbpCell.self, forCellReuseIdentifier: ProgressSbpCell.identifier)
        tableView.rowHeight = UITableView.automaticDimension
        tableView.contentInset.bottom = contentInsetBottom
        return tableView
    }()
    
    private var notFoundBanksLabel = UILabel(text: .notFound, textColor: .black, fontSize: 18)
    private var searchBar = UISearchBar()
    private var sbpImageView = UIImageView()
    private var defaultBorderColor: CGColor?
    private var tableViewHeightConstraint: NSLayoutConstraint!
    private let contentInsetBottom = 50.0
    
    //MARK: - DidMoveToSuperview
    
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        sbpTableView.delegate = self
        sbpTableView.dataSource = self
        searchBar.delegate = self
    }
    
    //MARK: - Init
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .white
        setupConstraintsAndView()
        customizeSearchBar()
        setupImage()
        
        layer.cornerRadius = 20
        layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        clipsToBounds = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //MARK: - Layout subviews
    
    override func layoutSubviews() {
        super.layoutSubviews()
        updateHeightTableViewContent()
    }
    
    //MARK: - Reload table view
    
    func reloadData() {
        sbpTableView.reloadData()
    }
    
    //MARK: - Private methods
    
    private func setupImage() {
        sbpImageView.contentMode = .scaleAspectFit
        sbpImageView.clipsToBounds = true
        sbpImageView.image = UIImage.icn_sbp_logo
        sbpTableView.backgroundColor = .clear
    }
    
    private func updateHeightTableViewContent() {
        let defaultHeightTableViewContent = 350.0
        let height = sbpTableView.contentSize.height == 0 ? 350 : sbpTableView.contentSize.height
        tableViewHeightConstraint.constant = height > defaultHeightTableViewContent ? -(defaultHeightTableViewContent + contentInsetBottom) : -(height + contentInsetBottom)
        self.layoutIfNeeded()
    }
    
    private func customizeSearchBar() {
        searchBar.layer.cornerRadius = 8
        searchBar.clipsToBounds = true
        searchBar.layer.borderWidth = 2
        searchBar.layer.borderColor = UIColor(red: 0.89, green: 0.91, blue: 0.94, alpha: 1).cgColor
        defaultBorderColor = searchBar.layer.borderColor
        
        searchBar.barTintColor = UIColor.white
        searchBar.backgroundColor = UIColor.white
        searchBar.placeholder = .searchBankApp
        notFoundBanksLabel.textColor = UIColor(red: 0.55, green: 0.58, blue: 0.62, alpha: 1)
        
        if let textfield = searchBar.value(forKey: "searchField") as? UITextField {
            textfield.textColor = UIColor(red: 0.15, green: 0.15, blue: 0.27, alpha: 1)
            textfield.backgroundColor = UIColor.white
        }
    }
    
    private func setupConstraintsAndView() {
        let topContentView = UIView()
        let iconView = UIImageView()
        iconView.image = UIImage.icon_not_found_banks
        let defaultLineView = UIView()
        let blackView = UIView()
        
        let leftView = UIView()
        let rightView = UIView()
        let headerStackView = UIStackView(.horizontal, .fill, .fill, 24, [leftView, rightView])
        let stackView = UIStackView(.vertical, .equalSpacing, .fill, 12, [headerStackView, searchBar])
        let label = UILabel(text: .chooseBank, textColor: .black, fontSize: 17)
        label.textAlignment = .left
        label.textColor = UIColor(red: 0.27, green: 0.3, blue: 0.36, alpha: 1)
        
        iconView.contentMode = .scaleAspectFit
        topContentView.backgroundColor = .clear
        blackView.clipsToBounds = true
        blackView.backgroundColor = .black
        blackView.layer.cornerRadius = 2
        
        addSubviews(topContentView, notFoundBanksView, sbpTableView)
        notFoundBanksView.addSubviews(iconView, notFoundBanksLabel)
        topContentView.addSubviews(defaultLineView, stackView)
        defaultLineView.addSubviews(blackView)
        leftView.addSubviews(sbpImageView)
        rightView.addSubviews(label)
        
        sbpTableView.layer.borderColor = UIColor(red: 0.886, green: 0.91, blue: 0.937, alpha: 1).cgColor
        sbpTableView.layer.borderWidth = 1
        
        NSLayoutConstraint.activate([
            
            //top content
            topContentView.topAnchor.constraint(equalTo: self.topAnchor),
            topContentView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            topContentView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            
            //sbpTableView
            sbpTableView.topAnchor.constraint(equalTo: topContentView.bottomAnchor, constant: 8),
            sbpTableView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            sbpTableView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            sbpTableView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            
            //notFoundBanksView
            notFoundBanksView.topAnchor.constraint(equalTo: sbpTableView.topAnchor),
            notFoundBanksView.bottomAnchor.constraint(equalTo: sbpTableView.bottomAnchor),
            notFoundBanksView.leadingAnchor.constraint(equalTo: sbpTableView.leadingAnchor),
            notFoundBanksView.trailingAnchor.constraint(equalTo: sbpTableView.trailingAnchor),
            
            iconView.topAnchor.constraint(equalTo: notFoundBanksView.topAnchor, constant: 100),
            iconView.centerXAnchor.constraint(equalTo: notFoundBanksView.centerXAnchor),
            iconView.heightAnchor.constraint(equalToConstant: 60),
            iconView.widthAnchor.constraint(equalTo: iconView.heightAnchor),
            
            //notFoundBanksLabel
            notFoundBanksLabel.topAnchor.constraint(equalTo: iconView.bottomAnchor, constant: 20),
            notFoundBanksLabel.leadingAnchor.constraint(equalTo: notFoundBanksView.leadingAnchor, constant: 65),
            notFoundBanksLabel.trailingAnchor.constraint(equalTo: notFoundBanksView.trailingAnchor, constant: -65),
            
            //topContentView
            defaultLineView.topAnchor.constraint(equalTo: topContentView.topAnchor),
            defaultLineView.leadingAnchor.constraint(equalTo: topContentView.leadingAnchor),
            defaultLineView.trailingAnchor.constraint(equalTo: topContentView.trailingAnchor),
            defaultLineView.heightAnchor.constraint(equalToConstant: 34),
            
            stackView.topAnchor.constraint(equalTo: defaultLineView.bottomAnchor, constant: 5),
            stackView.leadingAnchor.constraint(equalTo: topContentView.leadingAnchor, constant: 24),
            stackView.trailingAnchor.constraint(equalTo: topContentView.trailingAnchor, constant: -20),
            stackView.bottomAnchor.constraint(equalTo: topContentView.bottomAnchor, constant: -10),
            
            //defaultLineView
            blackView.bottomAnchor.constraint(equalTo: defaultLineView.bottomAnchor, constant: -8),
            blackView.heightAnchor.constraint(equalToConstant: 5),
            blackView.widthAnchor.constraint(equalToConstant: 135),
            blackView.centerXAnchor.constraint(equalTo: defaultLineView.centerXAnchor),
            
            //search bar
            searchBar.heightAnchor.constraint(equalToConstant: 48),
            
            //sbpImageView
            sbpImageView.heightAnchor.constraint(equalToConstant: 46),
            sbpImageView.widthAnchor.constraint(equalToConstant: 78),
            sbpImageView.centerYAnchor.constraint(equalTo: leftView.centerYAnchor),
            sbpImageView.topAnchor.constraint(greaterThanOrEqualTo: leftView.topAnchor),
            sbpImageView.leadingAnchor.constraint(equalTo: leftView.leadingAnchor),
            sbpImageView.trailingAnchor.constraint(equalTo: leftView.trailingAnchor),
            
            //label near sbpImageView
            label.topAnchor.constraint(equalTo: rightView.topAnchor),
            label.leadingAnchor.constraint(equalTo: rightView.leadingAnchor),
            label.trailingAnchor.constraint(lessThanOrEqualTo: rightView.trailingAnchor),
            label.bottomAnchor.constraint(equalTo: rightView.bottomAnchor),
        ])
        
        //dynamic constraint
        tableViewHeightConstraint = sbpTableView.topAnchor.constraint(equalTo: self.bottomAnchor, constant: -500)
        tableViewHeightConstraint?.isActive = true
    }
}

//MARK: - UISearchBarDelegate

extension ProgressSbpView: UISearchBarDelegate {
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        delegate?.numberOfRow(self, didChange: searchText)
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.text = ""
        searchBar.resignFirstResponder()
        delegate?.searchBarCancelButtonClicked(self)
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchBar.layer.borderColor = UIColor(red: 0.18, green: 0.44, blue: 0.99, alpha: 1).cgColor
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        searchBar.layer.borderColor = defaultBorderColor
    }
}

//MARK: - UITableViewDelegate with UITableViewDataSource

extension ProgressSbpView: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let count = delegate?.numberOfRow(self) ?? 0
        notFoundBanksView.isHidden = count > 0
        return count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let value = delegate?.progressSbpView(self, cellFor: indexPath.row),
              let cell = tableView.dequeueReusableCell(withIdentifier: ProgressSbpCell.identifier, for: indexPath) as? ProgressSbpCell
        else {
            return UITableViewCell()
        }
        
        cell.configureCell(model: value)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        delegate?.progressSbpView(self, didSelect: indexPath.row)
    }
}
