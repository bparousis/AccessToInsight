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
    case nightMode
    
    var title: String {
        switch self {
        case .about:
            return "About"
        case .textSize:
            return "Text Size"
        case .nightMode:
            return "Night Mode"
        }
    }
}

class SettingsViewController: UIViewController {
    private lazy var tableView : UITableView = {
        let tableView = UITableView(frame: .zero, style: .grouped)
        tableView.delegate = self
        tableView.dataSource = self
        ThemeManager.decorateTableView(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "SettingsTableCellId")
        return tableView
    }()
    
    private lazy var options: [SettingOption] = {
        if #available(iOS 13.0, *) {
            return [.about, .textSize]
        } else {
            return [.about, .textSize, .nightMode]
        }
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Settings"
        view.addSubview(tableView)
        anchor(to: tableView)
    }
    
    @objc func nightModeToggled(_ nightModeSwitch: UISwitch) {
        AppSettings.nightMode = nightModeSwitch.isOn
        let notificationName = Notification.Name("NightMode")
        NotificationCenter.default.post(name: notificationName, object: self)

        ThemeManager.decorateTableView(tableView)
        let cells = tableView.visibleCells
        for cell in cells {
            ThemeManager.decorateGroupedTableCell(cell)
        }
    }
    
    func openURL(_ urlString:String) {
        if let url = URL(string: urlString) {
            UIApplication.shared.open(url, options: [:])
        }
    }
}

extension SettingsViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row == 0 {
            navigationController?.pushViewController(AboutViewController(), animated: true)
        }
        else if indexPath.row == 1 {
            navigationController?.pushViewController(TextSizeViewController(), animated: true)
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
        ThemeManager.decorateGroupedTableCell(cell)
        
        guard options.indices.contains(indexPath.row) else {
            return cell
        }

        let option = options[indexPath.row]
        cell.textLabel?.text = option.title

        switch option {
        case .about, .textSize:
            cell.accessoryType = .disclosureIndicator
        case .nightMode:
            let nightModeSwitch = UISwitch()
            nightModeSwitch.onTintColor = UIColor(red: 62.0/255.0, green: 164.0/255.0, blue: 242.0/255.0, alpha: 1.0)
            nightModeSwitch.isOn = AppSettings.nightMode
            nightModeSwitch.addTarget(self, action: #selector(nightModeToggled(_:)), for:.valueChanged)
            cell.accessoryView = nightModeSwitch
        }
        
        return cell
    }
}
