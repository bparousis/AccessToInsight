//
//  SettingsViewController.swift
//  AccessToInsight
//
//  Created by Bill Parousis on 2018-11-02.
//

import UIKit

class SettingsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    private var tableView : UITableView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Settings"
        self.tableView = UITableView(frame: .zero, style: .grouped)
        self.tableView?.delegate = self
        self.tableView?.dataSource = self
        ThemeManager.decorateTableView(self.tableView)
        self.tableView?.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(self.tableView!)
        // Do any additional setup after loading the view.
        if #available(iOS 11, *) {
            let guide = view.safeAreaLayoutGuide
            NSLayoutConstraint.activate([
                tableView!.topAnchor.constraint(equalTo: guide.topAnchor),
                tableView!.leadingAnchor.constraint(equalTo: guide.leadingAnchor),
                tableView!.trailingAnchor.constraint(equalTo: guide.trailingAnchor),
                tableView!.bottomAnchor.constraint(equalTo: guide.bottomAnchor),
                ])
        } else {
            let margins = view.layoutMarginsGuide
            NSLayoutConstraint.activate([
                tableView!.topAnchor.constraint(equalTo: margins.topAnchor),
                tableView!.leadingAnchor.constraint(equalTo: margins.leadingAnchor),
                tableView!.trailingAnchor.constraint(equalTo: margins.trailingAnchor),
                tableView!.bottomAnchor.constraint(equalTo: margins.bottomAnchor),
                ])
        }
        tableView?.register(UITableViewCell.self, forCellReuseIdentifier: "SettingsTableCellId")
    }
    
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
        ThemeManager.decorateTableCell(cell)
        
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
    
    @objc func nightModeToggled(_ nightModeSwitch: UISwitch) {
        let nightMode = nightModeSwitch.isOn
        UserDefaults.standard.set(nightMode, forKey: "nightMode")
        UserDefaults.standard.synchronize()
        let notificationName = Notification.Name("NightMode")
        NotificationCenter.default.post(name: notificationName, object: self)

        ThemeManager.decorateTableView(self.tableView)
        if let cells = self.tableView?.visibleCells {
            for cell in cells {
                ThemeManager.decorateTableCell(cell)
            }
        }
    }
    
    func openURL(_ urlString:String) {
        if let url = URL(string: urlString) {
            UIApplication.shared.openURL(url)
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 0 {
            if indexPath.row == 0 {
                let aboutVC = AboutViewController()
                self.navigationController?.pushViewController(aboutVC, animated: true)
            }
        }
        if indexPath.section == 1 {
            if indexPath.row == 0 {
                let textSizeVC = TextSizeViewController()
                self.navigationController?.pushViewController(textSizeVC, animated: true)
            }
        }
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
