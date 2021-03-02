//
//  ToDoTableViewController.swift
//  ToDoList
//
//  Created by Gil Jetomo on 2021-01-08.
//

import UIKit
import CoreData

class ToDoTableViewController: FetchedResultsTableViewController, addEditViewControllerDelegate {
    
    let cellId = "ToDo"
    
    //for storing the selected toDo item/s
    var selectedRows: [IndexPath]?
    
    //for observing toDoList core data
    var toDoListIsEmpty: Bool!
    
    //for storing the selected toDo item when detailDisclosureButton in a cell is selected
    var itemForEditIndexPath: IndexPath?
    
    let sections = Priority.allCases

    //Navigation Controller's right rightBarButtonItems
    var deleteButton: UIBarButtonItem!
    var addButton: UIBarButtonItem!
    var container: NSPersistentContainer = AppDelegate.persistentContainer
    static var destinationIndexPath: IndexPath?
    
    lazy var fetchedResultsController: NSFetchedResultsController<ManagedToDo> = {
        let request: NSFetchRequest<ManagedToDo> = ManagedToDo.fetchRequest()
        //should be sorted by priorityNumber first then title
        request.sortDescriptors = [NSSortDescriptor(key: "priorityNumber", ascending: true)]
       
        //  sorted by title works but this messes up when the item is moved/moveRowAt
//          request.sortDescriptors = [NSSortDescriptor(key: "title", ascending: true, selector: #selector(NSString.localizedCaseInsensitiveCompare(_:)))]
        
        let frc = NSFetchedResultsController<ManagedToDo>(
            fetchRequest: request,
            managedObjectContext: container.viewContext,
            sectionNameKeyPath: "priorityNumber",
            cacheName: nil)
        frc.delegate = self
        return frc
    }()
    
    private func countToDoList() {
        let context = container.viewContext
        guard let count = (try? context.fetch(ManagedToDo.fetchRequest()))?.count else { return }
        toDoListIsEmpty = count > 0 ? false : true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //optional but implemented to customize the tableView's style to insetGrouped
        self.tableView = UITableView(frame: self.tableView.frame, style: .insetGrouped)
        //allows multiple selection during edit mode
        tableView.allowsMultipleSelectionDuringEditing = true
        //register custom ToDoTableViewCell
        tableView.register(ToDoTableViewCell.self, forCellReuseIdentifier: cellId)
        
        //Navigation Controller properties
        title = "Todo Items"
        navigationController?.navigationBar.prefersLargeTitles = true
        addButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addItem))
        deleteButton = UIBarButtonItem(barButtonSystemItem: .trash, target: self, action: #selector(deleteItems))
        
        countToDoList()
        reloadNCBarButtonItems(isListEmpty: toDoListIsEmpty)
        
        do {
            try fetchedResultsController.performFetch()
            tableView.reloadData()
        } catch {
            print("fetch failed")
        }
    }
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        //this is the default setting in order to enter editing mode
        super.setEditing(editing, animated: animated)
        
        if let _ = toDoListIsEmpty {
            countToDoList()
            reloadNCBarButtonItems(isListEmpty: toDoListIsEmpty)
        } else {
            reloadNCBarButtonItems()
        }
    }
    
    func reloadNCBarButtonItems(isListEmpty ToDoListIsEmpty: Bool) {
        if ToDoListIsEmpty {
            navigationItem.leftBarButtonItem = nil
            navigationItem.rightBarButtonItems = [addButton]
            tableView.isEditing.toggle()
        } else if tableView.isEditing && tableView.indexPathsForSelectedRows != nil {
            navigationItem.rightBarButtonItems = [addButton, deleteButton]
        } else {
            navigationItem.leftBarButtonItem = editButtonItem
            navigationItem.rightBarButtonItems = [addButton]
        }
    }
    
    func reloadNCBarButtonItems() {
        navigationItem.rightBarButtonItems = [addButton, deleteButton]
        navigationItem.leftBarButtonItem = editButtonItem
    }
    
    func add(_ todo: ToDo) {
        let context = container.viewContext
        _ = try? ManagedToDo.findOrCreateToDo(matching: todo, in: context)
        try? context.save()
        
        countToDoList()
        reloadNCBarButtonItems(isListEmpty: toDoListIsEmpty )
    }
    
    func edit(_ toDo: ToDo) {
        if let indexPath = itemForEditIndexPath {
            let context = container.viewContext
            context.delete(fetchedResultsController.object(at: indexPath))
            _ = try? ManagedToDo.createToDo(context: context, toDo: toDo)
            try? context.save()
        }
    }
    
    @objc func addItem() {
        let addVC = AddEditViewController()
        addVC.addEditDelegate = self
        
        navigationController?.pushViewController(addVC, animated: true)
    }
    
    override func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
        //unknown bug - after moving cells, this function gets called so !tableView.isEditing guard is added
        guard !tableView.isEditing else { return }
            itemForEditIndexPath = indexPath
            let cases = Priority.allCases
            let toDo = fetchedResultsController.object(at: indexPath)
            let toDoItem = ToDo(title: toDo.title!, todoDescription: toDo.toDoDescription, priority: cases[Int(toDo.priorityNumber)], isCompleted: toDo.isCompleted)
            
            let editVC = AddEditViewController()
            editVC.toDo = toDoItem
            editVC.inEditMode = true
            editVC.addEditDelegate = self
            
            navigationController?.pushViewController(editVC, animated: true)
    }
    
    @objc func deleteItems() {
        guard let selectedRows = tableView.indexPathsForSelectedRows else { return }
        let context = container.viewContext
        
        for indexPath in selectedRows {
            context.delete(fetchedResultsController.object(at: indexPath))
        }
        try? context.save()
        
        countToDoList()
        reloadNCBarButtonItems(isListEmpty: toDoListIsEmpty)
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return fetchedResultsController.sections?.count ?? 1
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        //return sections[section].rawValue
        if let sections = fetchedResultsController.sections, sections.count > 0 {
            let title = Int(sections[section].name)
            return self.sections[title!].rawValue
        } else {
            return nil
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 40
    }
    
    //customizes the section headers
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        let myLabel = UILabel()
        myLabel.frame = CGRect(x: .zero, y: .zero, width: tableView.frame.width, height: 30)
        myLabel.font = UIFont.boldSystemFont(ofSize: 22)
        myLabel.text = self.tableView(tableView, titleForHeaderInSection: section)
        
        let headerView = UIView()
        headerView.addSubview(myLabel)
        
        return headerView
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let sections = fetchedResultsController.sections, sections.count > 0 {
            return sections[section].numberOfObjects
        } else {
            return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath) as! ToDoTableViewCell
        cell.accessoryType = .detailDisclosureButton
        let toDo = fetchedResultsController.object(at: indexPath)
        cell.update(with: toDo)
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if !tableView.isEditing {
            //flip the isCompleted property of the selected toDo item
            let context = container.viewContext
            let toDo = fetchedResultsController.object(at: indexPath)
            toDo.isCompleted.toggle()
            try? context.save()
        } else {
            if let selectedRows = tableView.indexPathsForSelectedRows {
                //get the [IndexPath] of all selected rows during edit mode
                self.selectedRows = selectedRows
                //setEditing(true, animated: false)
                reloadNCBarButtonItems(isListEmpty: false)
            }
        }
    }
    override func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        reloadNCBarButtonItems(isListEmpty: false)
    }
    
    override func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        // nothing happens when moving between rows (todo items with the same priority don't have any property to order)
        guard sourceIndexPath.section != destinationIndexPath.section || sourceIndexPath != destinationIndexPath else { return }
        changeIsUserDriven = true
        
        let toDo = fetchedResultsController.object(at: sourceIndexPath)
        toDo.priorityNumber = Int16(fetchedResultsController.sectionIndexTitles[destinationIndexPath.section])!
        try? fetchedResultsController.managedObjectContext.save()
    }
    //disable reordering in the same section
    override func tableView(_ tableView: UITableView, targetIndexPathForMoveFromRowAt sourceIndexPath: IndexPath, toProposedIndexPath proposedDestinationIndexPath: IndexPath) -> IndexPath {
      if sourceIndexPath.section == proposedDestinationIndexPath.section {
        return sourceIndexPath
      } else {
        return proposedDestinationIndexPath
      }
    }
   //function needed to enable swipe delete
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let context = container.viewContext
            let toDo = fetchedResultsController.object(at: indexPath)
            context.delete(toDo)
            try? context.save()
        }
    }
    //function needed to enable swipe delete
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
}
