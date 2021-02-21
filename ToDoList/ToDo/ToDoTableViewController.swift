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
    
    //for observing toDoList contents
    var toDoListIsEmpty: Bool!
    
    //for storing the selected toDo item when detailDisclosureButton in a cell is selected
    var itemForEditIndexPath: IndexPath?
    
    let sections = Priority.allCases
    var toDoList: [Category] = [
        Category(group: .high, toDos: [ToDo(title: "House chore", todoDescription: "Wash the dishes", priority: .high, isCompleted: false)]),
        
        Category(group: .medium, toDos: [ToDo(title: "Exercise", todoDescription: "Walk", priority: .medium, isCompleted: true)]),
        
        Category(group: .low, toDos: [ToDo(title: "House chore", todoDescription: "Do the laundry", priority: .low, isCompleted: true), ToDo(title: "Grooming", todoDescription: "Get a haircut", priority: .low, isCompleted: true)])
    ] {
        didSet {
            //get status of the list if it is empty or not
            toDoListIsEmpty = toDoList[0].toDos.isEmpty && toDoList[1].toDos.isEmpty && toDoList[2].toDos.isEmpty
        }
    }
    //Navigation Controller's right rightBarButtonItems
    var deleteButton: UIBarButtonItem!
    var addButton: UIBarButtonItem!
    var container: NSPersistentContainer = AppDelegate.persistentContainer
    
    lazy var fetchedResultsController: NSFetchedResultsController<ManagedToDo> = {
        let request: NSFetchRequest<ManagedToDo> = ManagedToDo.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "title", ascending: true, selector: #selector(NSString.localizedCaseInsensitiveCompare(_:)))]
        request.sortDescriptors = [NSSortDescriptor(key: "priorityNumber", ascending: true)]
        
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
        deleteButton = UIBarButtonItem(barButtonSystemItem: .trash, target: self, action: #selector(deleteItem))
        
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
        DispatchQueue.main.async { [weak self] in
            context.perform {
                _ = try? ManagedToDo.findOrCreateToDo(matching: todo, in: context)
                try? context.save()
                
                self?.countToDoList()
                self?.reloadNCBarButtonItems(isListEmpty: self!.toDoListIsEmpty )
            }
        }
    }
    
    func edit(_ toDo: ToDo) {
        if let indexPath = itemForEditIndexPath {
            toDoList[indexPath.section].toDos.remove(at: indexPath.row)
            toDoList[indexPath.section].toDos.insert(toDo, at: indexPath.row)
            tableView.reloadRows(at: [indexPath], with: .automatic)
        }
    }
    
    @objc func addItem() {
        let addVC = AddEditViewController()
        addVC.addEditDelegate = self
        addVC.toDoList = toDoList
        
        navigationController?.pushViewController(addVC, animated: true)
    }
    
    override func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
        //get the selected toDo item when the cell's accessory button is tapped for editing
        let toDoItem = toDoList[indexPath.section].toDos[indexPath.row]
        //get the toDo item's indexPath to be used later for saving the updated toDo item in its proper location
        itemForEditIndexPath = indexPath
        
        let editVC = AddEditViewController()
        editVC.toDo = toDoItem
        editVC.toDoList = toDoList
        editVC.inEditMode = true
        editVC.addEditDelegate = self
        
        navigationController?.pushViewController(editVC, animated: true)
    }
    
    @objc func deleteItem() {
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
        
        //if a cell has been deselected, selectedRows need to be updated
//        if let selectedRows = tableView.indexPathsForSelectedRows {
//            //get the [IndexPath] of all selected rows during edit mode
//            self.selectedRows = selectedRows
//        }
        
        reloadNCBarButtonItems(isListEmpty: false)
    }
    
    override func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        
        //if any item is currently selected and has been moved, its respective IndexPath will be collected
        if let selectedRows = tableView.indexPathsForSelectedRows {
            //get the [IndexPath] of all selected rows during edit mode
            self.selectedRows = selectedRows
            print(selectedRows)
        }
        //get and remove the selected todo item from the list (model)
        var selected = toDoList[sourceIndexPath.section].toDos.remove(at: sourceIndexPath.row)
        
        //change the priority property of the todo item when moving to another section
        switch destinationIndexPath.section {
        case 0 : selected.priority = .high
        case 1 : selected.priority = .medium
        case 2 : selected.priority = .low
        default: fatalError()
        }
        //insert the modified todo item to the destination to update the 'model'
        toDoList[destinationIndexPath.section].toDos.insert(selected, at: destinationIndexPath.row)
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
