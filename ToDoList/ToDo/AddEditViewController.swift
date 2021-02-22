//
//  AddEditViewController.swift
//  ToDoList
//
//  Created by Macbook Pro on 2021-01-11.
//

import UIKit
import CoreData

protocol addEditViewControllerDelegate: class {
    func add(_ todo: ToDo)
    func edit(_ toDo: ToDo)
}

class AddEditViewController: UIViewController {
    
    let saveButton = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(saveItem))
    
    //this UIViewController will delegate the edit task to ToDoTableViewController
    weak var addEditDelegate: addEditViewControllerDelegate?
    
    var inEditMode: Bool?
    
    //this will hold the current toDo item being edited or added
    var toDo: ToDo?
    
    let mainView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    let toDoItemTitle: UITextField = {
       let tf = UITextField()
        tf.borderStyle = .roundedRect
        tf.placeholder = "I need to..."
        tf.font = .systemFont(ofSize: 20)
        tf.heightAnchor.constraint(equalToConstant: 45).isActive = true
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()
    
    let toDoItemDetails: UITextField = {
       let tf = UITextField()
        tf.borderStyle = .roundedRect
        tf.placeholder = "Details"
        tf.font = .systemFont(ofSize: 18)
        tf.heightAnchor.constraint(equalToConstant: 45).isActive = true
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()
    
    let prioritySegmentedControl: UISegmentedControl = {
        let items = Priority.allCases
        let sc = UISegmentedControl(items: items.map{ $0.rawValue.replacingOccurrences(of: " Priority", with: "") })
        sc.selectedSegmentIndex = 1
        let font = UIFont.systemFont(ofSize: 15)
        sc.setTitleTextAttributes([NSAttributedString.Key.font: font], for: .normal)
        return sc
    }()
    
    var container: NSPersistentContainer = AppDelegate.persistentContainer
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        navigationItem.rightBarButtonItem = saveButton
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(dismissView))
        view.addSubview(mainView)
        toDoItemTitle.becomeFirstResponder()
        
        toDoItemTitle.addTarget(self, action: #selector(textEditingChanged(_:)), for: .editingChanged)
        toDoItemDetails.addTarget(self, action: #selector(textEditingChanged(_:)), for: .editingChanged)
        
        setupLayout()
        
        if toDo == nil {
            title = "Add Todo Item"
           // updateSaveButtonState()
        } else {
            title = "Edit Todo Item"
            //text fields can be outside else clause
            toDoItemTitle.text = toDo?.title
            toDoItemDetails.text = toDo?.todoDescription
            if let priority = toDo?.priority {
                let p = Priority.allCases
                guard let index = p.firstIndex(of: priority) else { return }
                prioritySegmentedControl.selectedSegmentIndex = index
            }
        }
        updateSaveButtonState()
    }
    
    @objc func textEditingChanged(_ sender: UITextField) {
        updateSaveButtonState()
    }
    
    func updateSaveButtonState() {
        let newToDoItemText = toDoItemTitle.text ?? ""
        saveButton.isEnabled = !newToDoItemText.isEmpty
        
        
        //Save button will be disabled if the toDo item being added already exists
        guard let title = toDoItemTitle.text, title != "" else { return }
        //if guard passes, create a newToDo item
//        toDo = ToDo(title: toDoItemTitle.text!, todoDescription: toDoItemDetails.text, priority: .medium, isCompleted: false)
        
        let context = container.viewContext
        let request: NSFetchRequest<ManagedToDo> = ManagedToDo.fetchRequest()
        request.predicate = NSPredicate(format: "title == [c]%@", title)
        guard let item = try? context.fetch(request) else { return }
        saveButton.isEnabled = item.count == 0 ? true : false
    }
    
    @objc func dismissView() {
        navigationController?.popToRootViewController(animated: true)
    }
    
    @objc func saveItem() {
        
        let selected = prioritySegmentedControl.titleForSegment(at: prioritySegmentedControl.selectedSegmentIndex)
        let priority = Priority(rawValue: "\(selected!) Priority")
        
        if let _ = inEditMode {
            let toDoItem = ToDo(title: toDoItemTitle.text!, todoDescription: toDoItemDetails.text!, priority: priority!, isCompleted: toDo!.isCompleted)
            addEditDelegate?.edit(toDoItem)
            navigationController?.popToRootViewController(animated: true)
        } else {
            toDo = ToDo(title: toDoItemTitle.text!, todoDescription: toDoItemDetails.text, priority: priority!, isCompleted: false)
            addEditDelegate?.add(toDo!)
            navigationController?.popToRootViewController(animated: true)
        }
    }
    
    func setupLayout() {
        mainView.heightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.heightAnchor, multiplier: 1).isActive = true
        mainView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 0).isActive = true
        mainView.widthAnchor.constraint(equalTo: view.safeAreaLayoutGuide.widthAnchor, multiplier: 1).isActive = true
        
        let vStackView = UIStackView(arrangedSubviews: [toDoItemTitle, toDoItemDetails, prioritySegmentedControl])
        vStackView.translatesAutoresizingMaskIntoConstraints = false
        vStackView.alignment = .fill
        vStackView.distribution = .fill
        vStackView.spacing = 8
        vStackView.axis = .vertical

        mainView.addSubview(vStackView)

        vStackView.widthAnchor.constraint(equalTo: mainView.widthAnchor, multiplier: 0.95).isActive = true
        vStackView.topAnchor.constraint(equalTo: mainView.topAnchor, constant: 10).isActive = true
        vStackView.centerXAnchor.constraint(equalTo: mainView.centerXAnchor).isActive = true
    }
    

}
