//
//  FetchedResultsTableViewController.swift
//  ToDoList
//
//  Created by Gil Jetomo on 2021-02-20.
//

import UIKit
import CoreData

class FetchedResultsTableViewController: UITableViewController, NSFetchedResultsControllerDelegate {
  
    var changeIsUserDriven: Bool? = nil
    
  public func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
    tableView.beginUpdates()
  }
  
  public func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
    switch type {
      case .insert: tableView.insertSections([sectionIndex], with: .fade)
      case .delete: tableView.deleteSections([sectionIndex], with: .fade)
      default: break
    }
  }
  
  func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
    switch type {
      case .insert:
        tableView.insertRows(at: [newIndexPath!], with: .fade)
      case .delete:
        tableView.deleteRows(at: [indexPath!], with: .fade)
      case .move:
        if let changeIsUserDriven = changeIsUserDriven, changeIsUserDriven { break }
        tableView.deleteRows(at: [indexPath!], with: .fade)
        tableView.insertRows(at: [newIndexPath!], with: .fade)
      case .update:
      tableView.reloadRows(at: [indexPath!], with: .fade)
      @unknown default:
        fatalError("FetchedResultsTableViewController -- unknown case found")
    }
  }
  
  func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
    tableView.endUpdates()
    guard let changeIsUserDriven = changeIsUserDriven, changeIsUserDriven else { return }
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
      self.tableView.reloadData()
    }
    self.changeIsUserDriven = nil
  }
  
}

