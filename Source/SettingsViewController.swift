//
//  SettingsViewController.swift
//  AccessToInsight
//
//  Created by Bill Parousis on 2018-11-02.
//

import UIKit

enum SettingOption {
    case about
    case textSize
    
    var title: String {
        switch self {
        case .about:
            return "About"
        case .textSize:
            return "Text Size"
        }
    }
}

class SettingsViewController: UIViewController {
    private lazy var tableView : UITableView = {
        let tableView = UITableView.makeDecorated()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "SettingsTableCellId")
        return tableView
    }()
    
    private let options: [SettingOption] = [.about, .textSize]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Settings"
        view.addSubview(tableView)
        anchor(to: tableView)
    }
    
    func openURL(_ urlString:String) {
        if let url = URL(string: urlString) {
            UIApplication.shared.open(url, options: [:])
        }
    }
}

extension SettingsViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        guard options.indices.contains(indexPath.row) else {
            return
        }

        switch options[indexPath.row] {
        case .about:
            navigationController?.pushViewController(AboutViewController(), animated: true)
        case .textSize:
            let maxSize = UIDevice.current.userInterfaceIdiom == .pad ? 190 : 160
            let viewModel = TextSizeViewModel(textSizeRange: 50...maxSize)
            navigationController?.pushViewController(TextSizeViewController(viewModel: viewModel),
                                                     animated: true)
        }
    }
}

extension SettingsViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        options.count
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SettingsTableCellId", for: indexPath)
        cell.selectionStyle = .none
        cell.decorateGrouped()
        
        guard options.indices.contains(indexPath.row) else {
            return cell
        }

        let option = options[indexPath.row]
        cell.textLabel?.text = option.title
        cell.accessoryType = .disclosureIndicator
        
        return cell
    }
}
