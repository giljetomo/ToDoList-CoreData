//
//  ManagedToDo.swift
//  ToDoList
//
//  Created by Gil Jetomo on 2021-02-20.
//

import Foundation
import CoreData

class ManagedToDo: NSManagedObject {
    class func findOrCreateToDo(matching toDo: ToDo, in context: NSManagedObjectContext) throws -> ManagedToDo {
        let cases = Priority.allCases
        let request: NSFetchRequest<ManagedToDo> = ManagedToDo.fetchRequest()
        let titlePredicate = NSPredicate(format: "title == [c]%@", toDo.title)
        let priorityPredicate = NSPredicate(format: "priorityNumber == %d", cases.firstIndex(of: toDo.priority)!)
        let andPredicate = NSCompoundPredicate(type: .and, subpredicates: [titlePredicate, priorityPredicate])
        request.predicate = andPredicate
        do {
            let matches = try context.fetch(request)
            if matches.count > 0 {
                // assert 'sanity': if condition false ... then print message and interrupt program
                assert(matches.count == 1, "ManagedToDo.findOrCreateSource -- database inconsistency")
                let matchedToDo = matches[0]
                return matchedToDo
            }
        } catch {
            throw error
        }
        // no match, instantiate ManagedToDo
        return try! createToDo(context: context, toDo: toDo)
    }
    
    class func createToDo(context: NSManagedObjectContext, toDo: ToDo) throws -> ManagedToDo {
        let newToDo = ManagedToDo(context: context)
        newToDo.title = toDo.title
        newToDo.isCompleted = toDo.isCompleted
        if let toDoDescription = toDo.todoDescription {
            newToDo.toDoDescription = toDoDescription
        }
        newToDo.priorityNumber = {
            switch toDo.priority {
            case .high: return 0
            case .medium: return 1
            case .low: return 2
            }
        }()
        
        return newToDo
    }
}
