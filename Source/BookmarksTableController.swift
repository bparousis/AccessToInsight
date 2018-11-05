//
//  BookmarksTableController.swift
//  AccessToInsight
//
//  Created by Bill Parousis on 2018-11-03.
//

import UIKit

class BookmarksTableController: UITableViewController {

    private var editBookmarkIndex = 0
    private var doneEditAction: UIAlertAction? = nil

    @objc weak var delegate: BookmarksControllerDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = "Bookmarks"
        self.tableView.backgroundColor = ThemeManager.backgroundColor()
        self.tableView.allowsSelectionDuringEditing = true
        self.navigationItem.rightBarButtonItem = self.editButtonItem
        if UIDevice.current.userInterfaceIdiom == .phone {
            let cancelButtonItem = UIBarButtonItem(title: "Close", style: .done, target: self, action: #selector(cancel(_:)))
            self.navigationItem.leftBarButtonItem = cancelButtonItem
        }
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return BookmarksManager.instance.getCount()
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell = {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "BookmarkCellID") else {
                // Never fails:
                return UITableViewCell(style: .subtitle, reuseIdentifier: "BookmarkCellID")
            }
            return cell
        }()
        
        ThemeManager.decorateTableCell(cell)
        if ThemeManager.isNightMode() {
            cell.backgroundColor = UIColor.clear
        }
        let bookmark = BookmarksManager.instance.bookmarkAtIndex(indexPath.row)
        cell.textLabel?.text = bookmark?.title
        cell.detailTextLabel?.text = bookmark?.note
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        guard let bookmark = BookmarksManager.instance.bookmarkAtIndex(indexPath.row) else {
            return
        }

        if tableView.isEditing {
            self.editBookmarkIndex = indexPath.row
            let alert = UIAlertController(title: "Edit Bookmark", message: "Enter a title for the bookmark", preferredStyle: .alert)
            alert.addTextField {[unowned self] (textField) in
                textField.text = bookmark.title
                textField.addTarget(self, action: #selector(self.textDidChange(_:)), for: .editingChanged)
            }
            self.doneEditAction = UIAlertAction(title: "Done", style: .default, handler: {[unowned self] (action) in
                let bookmark = BookmarksManager.instance.bookmarkAtIndex(self.editBookmarkIndex)
                if let newTitle = alert.textFields?.first?.text {
                    bookmark?.title = newTitle
                    BookmarksManager.instance.save()
                    self.tableView.reloadData()
                }
            })
            alert.addAction(self.doneEditAction!)
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            present(alert, animated: true, completion: nil)
        }
        else {
            self.delegate?.bookmarksController(self, selectedBookmark: bookmark)
        }
    }

    @objc func textDidChange(_ textField: UITextField) {
        if let count = textField.text?.count {
            self.doneEditAction?.isEnabled = count > 0
        }
    }

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */


    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            BookmarksManager.instance.deleteBookmarkAtIndex(indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
    }

    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {
        BookmarksManager.instance.moveBookmarkAtIndex(fromIndexPath.row, toIndex: to.row)
    }

    @objc func cancel(_ cancelItem: UIBarButtonItem) {
        self.delegate?.bookmarksControllerCancel(self)
    }

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
