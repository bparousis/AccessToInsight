//
//  SettingsViewController.swift
//  AccessToInsight
//
//  Created by Bill Parousis on 2018-11-02.
//

import UIKit

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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Settings"
        view.addSubview(tableView)
        anchor(to: tableView)
    }
    
    @objc func nightModeToggled(_ nightModeSwitch: UISwitch) {
        let nightMode = nightModeSwitch.isOn
        UserDefaults.standard.set(nightMode, forKey: "nightMode")
        UserDefaults.standard.synchronize()
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
            UIApplication.shared.openURL(url)
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
        if #available(iOS 13.0, *) {
            return 2
        } else {
            return 3
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SettingsTableCellId", for: indexPath)
        cell.selectionStyle = .none
        ThemeManager.decorateGroupedTableCell(cell)
        
        if indexPath.row == 0 {
            cell.textLabel?.text = "About"
            cell.accessoryType = .disclosureIndicator
        }
        else if indexPath.row == 1 {
            cell.textLabel?.text = "Text Size"
            cell.accessoryType = .disclosureIndicator
        }
        else if indexPath.row == 2 {
            cell.textLabel?.text = "Night Mode"
            let nightMode = UserDefaults.standard.bool(forKey: "nightMode")
            let nightModeSwitch = UISwitch()
            nightModeSwitch.onTintColor = UIColor(red: 62.0/255.0, green: 164.0/255.0, blue: 242.0/255.0, alpha: 1.0)
            nightModeSwitch.isOn = nightMode
            nightModeSwitch.addTarget(self, action: #selector(nightModeToggled(_:)), for:.valueChanged)
            cell.accessoryView = nightModeSwitch
        }
        
        return cell
    }
}
