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
    private var bookmarksManager: BookmarksManager

    weak var delegate: BookmarksControllerDelegate?
    
    init(bookmarksManager: BookmarksManager) {
        self.bookmarksManager = bookmarksManager
        super.init(style: .plain)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Bookmarks"
        ThemeManager.decorateTableView(tableView)
        tableView.tableFooterView = UIView()
        tableView.allowsSelectionDuringEditing = true
        navigationItem.rightBarButtonItem = editButtonItem
        if UIDevice.current.userInterfaceIdiom == .phone {
            let cancelButtonItem = UIBarButtonItem(title: "Close", style: .done, target: self, action: #selector(cancel(_:)))
            navigationItem.leftBarButtonItem = cancelButtonItem
        }
    }
}

private extension BookmarksTableController {
    @objc func textDidChange(_ textField: UITextField) {
        if let count = textField.text?.count {
            doneEditAction?.isEnabled = count > 0
        }
    }
    
    @objc func cancel(_ cancelItem: UIBarButtonItem) {
        delegate?.bookmarksControllerCancel(self)
    }
}

// MARK: - Table view delegates
internal extension BookmarksTableController {

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return bookmarksManager.getCount()
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
        let bookmark = bookmarksManager.bookmarkAtIndex(indexPath.row)
        cell.textLabel?.text = bookmark?.title
        cell.detailTextLabel?.text = bookmark?.note
        return cell
    }
    
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            bookmarksManager.deleteBookmarkAtIndex(indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
    }
    
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {
        bookmarksManager.moveBookmark(from: fromIndexPath.row, to: to.row)
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let bookmark = bookmarksManager.bookmarkAtIndex(indexPath.row) else {
            return
        }
        
        if tableView.isEditing {
            editBookmarkIndex = indexPath.row
            let alert = UIAlertController(title: "Edit Bookmark", message: "Enter a title for the bookmark", preferredStyle: .alert)
            alert.addTextField {(textField) in
                textField.text = bookmark.title
                textField.addTarget(self, action: #selector(self.textDidChange(_:)), for: .editingChanged)
            }
            doneEditAction = UIAlertAction(title: "Done", style: .default, handler: {[unowned self] (action) in
                let bookmark = self.bookmarksManager.bookmarkAtIndex(self.editBookmarkIndex)
                if let newTitle = alert.textFields?.first?.text {
                    bookmark?.title = newTitle
                    self.bookmarksManager.save()
                    self.tableView.reloadData()
                }
            })
            alert.addAction(self.doneEditAction!)
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            present(alert, animated: true, completion: nil)
        }
        else {
            delegate?.bookmarksController(self, selectedBookmark: bookmark)
        }
    }
}
