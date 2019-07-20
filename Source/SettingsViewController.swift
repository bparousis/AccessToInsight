//
//  SettingsViewController.swift
//  AccessToInsight
//
//  Created by Bill Parousis on 2018-11-02.
//

import UIKit

class SettingsViewController: UIViewController {
    private var tableView : UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Settings"
        tableView = UITableView(frame: .zero, style: .grouped)
        tableView.delegate = self
        tableView.dataSource = self
        ThemeManager.decorateTableView(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        
        if #available(iOS 11, *) {
            let guide = view.safeAreaLayoutGuide
            NSLayoutConstraint.activate([
                tableView.topAnchor.constraint(equalTo: guide.topAnchor),
                tableView.leadingAnchor.constraint(equalTo: guide.leadingAnchor),
                tableView.trailingAnchor.constraint(equalTo: guide.trailingAnchor),
                tableView.bottomAnchor.constraint(equalTo: guide.bottomAnchor),
                ])
        } else {
            let margins = view.layoutMarginsGuide
            NSLayoutConstraint.activate([
                tableView.topAnchor.constraint(equalTo: margins.topAnchor),
                tableView.leadingAnchor.constraint(equalTo: margins.leadingAnchor),
                tableView.trailingAnchor.constraint(equalTo: margins.trailingAnchor),
                tableView.bottomAnchor.constraint(equalTo: margins.bottomAnchor),
                ])
        }
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "SettingsTableCellId")
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
        if indexPath.section == 0 {
            if indexPath.row == 0 {
                let aboutVC = AboutViewController()
                navigationController?.pushViewController(aboutVC, animated: true)
            }
        }
        if indexPath.section == 1 {
            if indexPath.row == 0 {
                let textSizeVC = TextSizeViewController()
                navigationController?.pushViewController(textSizeVC, animated: true)
            }
        }
    }
}

extension SettingsViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 1
        }
        else if section == 1 {
            return 2
        }
        return 0
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SettingsTableCellId", for: indexPath)
        cell.selectionStyle = .none
        ThemeManager.decorateGroupedTableCell(cell)
        
        if indexPath.section == 0 {
            cell.textLabel?.text = "About"
            cell.accessoryType = .disclosureIndicator
        }
        else if indexPath.section == 1 {
            if indexPath.row == 0 {
                cell.textLabel?.text = "Text Size"
                cell.accessoryType = .disclosureIndicator
            }
            else if indexPath.row == 1 {
                cell.textLabel?.text = "Night Mode"
                let nightMode = UserDefaults.standard.bool(forKey: "nightMode")
                let nightModeSwitch = UISwitch()
                nightModeSwitch.onTintColor = UIColor(red: 62.0/255.0, green: 164.0/255.0, blue: 242.0/255.0, alpha: 1.0)
                nightModeSwitch.isOn = nightMode
                nightModeSwitch.addTarget(self, action: #selector(nightModeToggled(_:)), for:.valueChanged)
                cell.accessoryView = nightModeSwitch
            }
        }
        
        return cell
    }
}
