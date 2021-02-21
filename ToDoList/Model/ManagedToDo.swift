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
        let request: NSFetchRequest<ManagedToDo> = ManagedToDo.fetchRequest()
        request.predicate = NSPredicate(format: "title = %@", toDo.title)
        
        do {
            let matches = try context.fetch(request)
            if matches.count > 0 {
                // assert 'sanity': if condition false ... then print message and interrupt program
                assert(matches.count == 1, "ManagedToDo.findOrCreateSource -- database inconsistency")
                return matches[0]
            }
        } catch {
            throw error
        }
        // no match, instantiate ManagedArticle
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
