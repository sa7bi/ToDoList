//
//  SettingsViewController.swift
//  ToDoList
//
//  Created by Radu Ursache on 25/02/2019.
//  Copyright © 2019 Radu Ursache. All rights reserved.
//

import UIKit
import AcknowList
import MessageUI
import LKAlertController

class SettingsViewController: BaseViewController {

    @IBOutlet weak var tableView: UITableView!
    
    var dataSource = [SettingsItemSection]()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.loadCurrentData()
    }
    
    override func setupUI() {
        super.setupUI()
        
        self.addRightDoneButton()
        
        let tableViewFooter = UIView(frame: CGRect(x: 0, y: 0, width: self.tableView.frame.width, height: 50))
        tableViewFooter.backgroundColor = UIColor.clear
        let version = UILabel(frame: CGRect(x: 0, y: 0, width: self.tableView.frame.width, height: 30))
        version.font = UIFont.systemFont(ofSize: 12)
        version.textColor = UIColor.darkGray
        version.textAlignment = .center
        if let fullName = UserDefaults.standard.string(forKey: Config.UserDefaults.userFullName), Utils().userIsLoggedIniCloud() {
            version.text = "SETTINGS_LOGGED_IN_AS".localized() + "\(fullName)"
        } else {
            version.text = "SETTINGS_NOT_LOGGED_IN".localized()
        }
        tableViewFooter.addSubview(version)
        self.tableView.tableFooterView  = tableViewFooter
    }
    
    func addRightDoneButton() {
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "DONE".localized(), style: .done, target: self, action: #selector(self.closeButtonAction))
    }
    
    override func setupBindings() {
        self.tableView.delegate = self
        self.tableView.dataSource = self
		
		if #available(iOS 13.0, *) {
			self.isModalInPresentation = true
		}
    }
    
    func loadCurrentData() {
        let userDefaults = UserDefaults.standard
        
        let startPageOption = Config.General.startPageTitles[userDefaults.integer(forKey: Config.UserDefaults.startPage)]
        let themeOption = Config.General.themes[userDefaults.integer(forKey: Config.UserDefaults.theme)].name
        let languageOption = Config.General.languages[userDefaults.integer(forKey: Config.UserDefaults.language)].name
        let openLinksOption = Config.General.linksOptions[userDefaults.integer(forKey: Config.UserDefaults.openLinks)]
        let disableAutoReminders = userDefaults.bool(forKey: Config.UserDefaults.disableAutoReminders)
        let helpPrompts = userDefaults.bool(forKey: Config.UserDefaults.helpPrompts)
        
        let mainSection = SettingsItemSection(items: [
            SettingsItemModel(title: "SETTINGS_ITEM_ENTRY_START_PAGE".localized(), icon: "settings_start_page", subtitle: nil, rightTitle: startPageOption),
            SettingsItemModel(title: "SETTINGS_ITEM_ENTRY_THEME".localized(), icon: "settings_theme", subtitle: nil, rightTitle: themeOption),
            SettingsItemModel(title: "SETTINGS_ITEM_ENTRY_LANGUAGE".localized(), icon: "settings_language", subtitle: nil, rightTitle: languageOption),
            SettingsItemModel(title: "SETTINGS_ITEM_ENTRY_OPEN_WEB_LINKS".localized(), icon: "settings_openurl", subtitle: nil, rightTitle: openLinksOption)
                                                        ])
        
        let togglesSection = SettingsItemSection(items: [
            SettingsItemModel(title: "SETTINGS_ITEM_ENTRY_AUTOMATIC_REMINDERS".localized(), icon: "settings_auto_reminders", subtitle: "SETTINGS_ITEM_ENTRY_AUTOMATIC_REMINDERS_DESC".localized(), rightTitle: nil, showSwitch: true, switchIsOn: !disableAutoReminders),
            SettingsItemModel(title: "SETTINGS_ITEM_ENTRY_HELPFUL_PROMPTS".localized(), icon: "settings_help", subtitle: "SETTINGS_ITEM_ENTRY_AUTOMATIC_REMINDERS_DESC".localized(), rightTitle: nil, showSwitch: true, switchIsOn: helpPrompts)
                                                        ])
        
        let aboutSection = SettingsItemSection(items: [
            SettingsItemModel(title: "SETTINGS_ITEM_ENTRY_MANUAL_SYNC".localized(), icon: "settings_sync", subtitle: nil, rightTitle: nil),
            SettingsItemModel(title: "SETTINGS_ITEM_ENTRY_FEEDBACK".localized(), icon: "settings_feedback", subtitle: nil, rightTitle: nil),
            SettingsItemModel(title: "SETTINGS_ITEM_ENTRY_ACKNOW".localized(), icon: "settings_acknowledgments", subtitle: nil, rightTitle: nil),
            SettingsItemModel(title: "SETTINGS_ITEM_ENTRY_ABOUT".localized(), icon: "settings_about", subtitle: nil, rightTitle: nil)
                                                        ])
        
        self.dataSource = [mainSection, togglesSection, aboutSection]
        
        self.tableView.reloadData()
    }
    
    func cellAction(indexPath: IndexPath) {
        // human readable rows and sections
        let row = indexPath.row + 1
        let section = indexPath.section + 1
        
        
        if section == 1 {
           self.createActionSheet(row: row)
        }
        
        if section == 2 {
            
        }
        
        if section == 3 {
            if row == 1 {
                // sync
                Utils().showSuccessToast(viewController: self, message: "SETTINGS_SYNC_START".localized())
                self.navigationItem.rightBarButtonItem = nil
                
                Utils().getSyncEngine()?.pull()
                DispatchQueue.main.asyncAfter(deadline: .now() + 5, execute: {
                    Utils().getSyncEngine()?.pushAll()
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 5, execute: {
                        self.addRightDoneButton()
                        Utils().showSuccessToast(viewController: self, message: "SETTINGS_SYNC_END".localized())
                    })
                })
                
            } else if row == 2 {
                // feedback
                if MFMailComposeViewController.canSendMail() {
                    let mail = MFMailComposeViewController()
                    mail.mailComposeDelegate = self
					mail.setToRecipients([Config.General.contactEmail.replacingOccurrences(of: "[email]", with: "@")]) // not today, github bots
                    self.present(mail, animated: true)
                } else {
                    Utils().showErrorToast(message: "SETTINGS_NO_EMAIL_FAILED".localized())
                }
                
            } else if row == 3 {
                // acknowledgments
                self.navigationController?.pushViewController(AcknowListViewController(), animated: true)
                
            } else if row == 4 {
                // about
				Utils().showAbout()
            }
        }
    }
    
    func createActionSheet(row: Int) {
        let currentItem = self.dataSource.first?.items[row - 1]
        let actionSheet = ActionSheet(title: currentItem?.title, message: nil)
        
        if row == 1 {
            // start page
            var startPageTitles = Config.General.startPageTitles; startPageTitles.removeLast(2)
            
            for option in startPageTitles {
                actionSheet.addAction(option, style: .default) { (action) in
                    UserDefaults.standard.set(Config.General.startPageTitles.firstIndex(of: option), forKey: Config.UserDefaults.startPage)
                    
                    Utils().showSuccessToast(viewController: self, message: "SETTINGS_CONFIRMATION_START_PAGE".localized())
                    self.loadCurrentData()
                }
            }
        } else if row == 2 {
            // themes
            
            for theme in Config.General.themes {
                actionSheet.addAction(theme.name, style: .default) { (action) in
                    UserDefaults.standard.set(Config.General.themes.firstIndex(of: theme), forKey: Config.UserDefaults.theme)
                    
                    NotificationCenter.default.post(name: Config.Notifications.themeUpdated, object: nil)
                    self.setupUI() // this should be called to make sure nav bar color is updated. weird
                    
                    UIApplication.shared.setAlternateIconName(theme.appIcon) { error in
                        if let error = error {
                            print(error.localizedDescription)
                            Utils().showErrorToast(message: error.localizedDescription)
                        } else {
                            Utils().showSuccessToast(viewController: self, message: "SETTINGS_CONFIRMATION_THEME".localized())
                        }
                    }
                    
                    self.loadCurrentData()
                }
            }
        } else if row == 3 {
            // languages
            
            for language in Config.General.languages {
                actionSheet.addAction(language.name, style: .default) { (action) in
                    UserDefaults.standard.set(Config.General.languages.firstIndex(of: language), forKey: Config.UserDefaults.language)
                    
                    UserDefaults.standard.set([language.code], forKey: "AppleLanguages")
                    
                    Utils().showSuccessToast(viewController: self, message: "SETTINGS_CONFIRMATION_LANGUAGE".localized())
                    self.loadCurrentData()
                }
            }
        } else if row == 4 {
            // open links
            
            for option in Config.General.linksOptions {
                actionSheet.addAction(option, style: .default) { (action) in
                    UserDefaults.standard.set(Config.General.linksOptions.firstIndex(of: option), forKey: Config.UserDefaults.openLinks)
                    
                    Utils().showSuccessToast(viewController: self, message: "SETTINGS_CONFIRMATION_LINKS".localized().replacingOccurrences(of: "{replace}", with: option))
                    self.loadCurrentData()
                }
            }
        }
        
        actionSheet.addAction("CANCEL".localized(), style: .cancel)
        
        actionSheet.presentIn(self)
        actionSheet.show()
    }
    
    @objc func cellSwitchAction(_ uiswitch: UISwitch) {
        let switchTag = uiswitch.tag // section row (10 = section 1, row 0)
        
        if switchTag == 10 {
            UserDefaults.standard.set(uiswitch.isOn, forKey: Config.UserDefaults.disableAutoReminders)
        }
        if switchTag == 11 {
            UserDefaults.standard.set(uiswitch.isOn, forKey: Config.UserDefaults.helpPrompts)
        }
    }
    
    @objc func closeButtonAction() {
        self.close()
    }
    
    func close() {
        self.dismiss(animated: true, completion: nil)
    }
}

extension SettingsViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return self.dataSource.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.dataSource[section].items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: SettingsTableViewCell.getIdentifier(), for: indexPath) as! SettingsTableViewCell
        
        let currentItem = self.dataSource[indexPath.section].items[indexPath.row]
        
        cell.titleLabel.text = currentItem.title
        cell.iconImageView.image = currentItem.icon
        
        if let subtitle = currentItem.subtitle {
            cell.subtitleLabel.isHidden = false
            cell.subtitleLabel.text = subtitle
        } else {
            cell.subtitleLabel.isHidden = true
        }
        
        if let rightTitle = currentItem.rightTitle {
            cell.rightLabel.isHidden = false
            cell.rightLabel.text = rightTitle
        } else {
            cell.rightLabel.isHidden = true
        }
        
        cell.rightSwitch.superview?.isHidden = !currentItem.showSwitch
        
        if currentItem.showSwitch {
            cell.accessoryType = .none
            
            cell.rightSwitch.addTarget(self, action: #selector(self.cellSwitchAction(_:)), for: .valueChanged)
            cell.rightSwitch.tag = Int("\(indexPath.section)\(indexPath.row)")!
            cell.rightSwitch.setOn(currentItem.switchIsOn, animated: true)
        }
        
        cell.updateUI()
        
        cell.layoutIfNeeded()
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        self.cellAction(indexPath: indexPath)
    }
    
    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        let currentItem = self.dataSource[indexPath.section].items[indexPath.row]
        
        if currentItem.showSwitch {
            return nil
        }
        
        return indexPath
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 55
    }
}

extension SettingsViewController: MFMailComposeViewControllerDelegate {
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true)
    }
}
