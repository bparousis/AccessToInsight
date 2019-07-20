//
//  AboutViewController.swift
//  AccessToInsight
//
//  Created by Bill Parousis on 2018-11-02.
//

import UIKit
import WebKit
import MessageUI

class AboutViewController: UIViewController {
    
    private var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "About"
        tableView = UITableView(frame: .zero, style: .grouped)
        ThemeManager.decorateTableView(tableView)
        tableView.delegate = self
        tableView.dataSource = self
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false

        // Do any additional setup after loading the view.
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
    
    func openURL(_ urlString: String ) {
        if let url = URL(string: urlString) {
            UIApplication.shared.openURL(url)
        }
    }
}

extension AboutViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 1
        }
        else if section == 1 {
            return 3
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
            if let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String {
                cell.textLabel?.text  = "Version \(version)"
            }
            else {
                cell.textLabel?.text  = "Version N/A"
            }
            cell.accessoryType = .none
        }
        else if indexPath.section == 1 {
            if indexPath.row == 0 {
                cell.textLabel?.text = "Access to Insight Website"
            }
            else if indexPath .row == 1 {
                cell.textLabel?.text = "Questions & Feedback"
            }
            else if indexPath.row == 2 {
                cell.textLabel?.text = "Info"
            }
            cell.accessoryType = .disclosureIndicator
        }
        return cell
    }
}

extension AboutViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if (indexPath.section == 1) {
            if indexPath.row == 0 {
                openURL("http://www.accesstoinsight.org/")
            }
            else if indexPath.row == 1 {
                let mailComposer = MFMailComposeViewController()
                mailComposer.mailComposeDelegate = self
                mailComposer.setToRecipients(["accesstoinsightapp@gmail.com"])
                mailComposer.setSubject("Question about ATI \(UIDevice.current.model) App")
                present(mailComposer, animated: true, completion: nil)
            }
            else if indexPath.row == 2 {
                let infoWebView = WKWebView(frame: view.frame)
                infoWebView.navigationDelegate = self
                infoWebView.loadLocalWebContent("about.html")
                
                let webVC = UIViewController()
                webVC.title = "Info"
                webVC.view = infoWebView
                navigationController?.pushViewController(webVC, animated: true)
            }
        }
    }
}

extension AboutViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        webView.applyTheme()
    }
    
    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        webView.fitContentToScreen()
    }
}

extension AboutViewController: MFMailComposeViewControllerDelegate {
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        dismiss(animated: true, completion: nil)
    }
}
